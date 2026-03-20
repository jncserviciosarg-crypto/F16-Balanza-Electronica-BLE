import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

class RecetaRow {
  final int id;
  final String nombre;
  final String tipo;

  const RecetaRow({
    required this.id,
    required this.nombre,
    required this.tipo,
  });
}

class RecetaIngredienteRow {
  final int ingredienteId;
  final int kg;
  final int posicion;

  const RecetaIngredienteRow({
    required this.ingredienteId,
    required this.kg,
    required this.posicion,
  });
}

class RecetaConIngredientes {
  final RecetaRow receta;
  final String tipo;
  final List<RecetaIngredienteRow> ingredientes;

  const RecetaConIngredientes({
    required this.receta,
    required this.tipo,
    required this.ingredientes,
  });
}

class RecetaInput {
  final String nombre;
  final String tipo;
  final List<({int ingredienteId, int kg})> ingredientes;

  const RecetaInput({
    required this.nombre,
    required this.tipo,
    required this.ingredientes,
  });
}

sealed class RecetaOperationResult {
  const RecetaOperationResult();

  factory RecetaOperationResult.success({required int id}) =
      RecetaOperationSuccess;

  factory RecetaOperationResult.failure(List<String> errors) =
      RecetaOperationFailure;
}

final class RecetaOperationSuccess extends RecetaOperationResult {
  final int id;
  const RecetaOperationSuccess({required this.id});
}

final class RecetaOperationFailure extends RecetaOperationResult {
  final List<String> errors;
  const RecetaOperationFailure(this.errors);
}

// ---------------------------------------------------------------------------
// Database helper
// ---------------------------------------------------------------------------

class _AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint('[RecetasRepository] Could not get documents directory: $e');
      dir = Directory.systemTemp;
    }
    final path = '${dir.path}/recetas.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('''
          CREATE TABLE recetas (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre  TEXT    NOT NULL,
            tipo    TEXT    NOT NULL,
            en_ronda INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE receta_ingredientes (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            receta_id      INTEGER NOT NULL REFERENCES recetas(id),
            ingrediente_id INTEGER NOT NULL,
            kg             INTEGER NOT NULL,
            posicion       INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class RecetasRepository {
  // LECTURA ---------------------------------------------------------------

  Future<RecetaConIngredientes?> getById(int recetaId) async {
    final db = await _AppDatabase.instance;
    final rows = await db.query(
      'recetas',
      where: 'id = ?',
      whereArgs: [recetaId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final ingredientes = await db.query(
      'receta_ingredientes',
      where: 'receta_id = ?',
      whereArgs: [recetaId],
      orderBy: 'posicion ASC',
    );
    return RecetaConIngredientes(
      receta: RecetaRow(
        id: row['id']! as int,
        nombre: row['nombre']! as String,
        tipo: row['tipo']! as String,
      ),
      tipo: row['tipo']! as String,
      ingredientes: ingredientes
          .map(
            (i) => RecetaIngredienteRow(
              ingredienteId: i['ingrediente_id']! as int,
              kg: i['kg']! as int,
              posicion: i['posicion']! as int,
            ),
          )
          .toList(),
    );
  }

  Future<List<RecetaConIngredientes>> getAll() async {
    final db = await _AppDatabase.instance;
    final rows = await db.query('recetas');
    final results = <RecetaConIngredientes>[];
    for (final row in rows) {
      final r = await getById(row['id']! as int);
      if (r != null) results.add(r);
    }
    return results;
  }

  // ESCRITURA -------------------------------------------------------------

  Future<RecetaOperationResult> editar(
    int recetaId,
    RecetaInput input,
  ) async {
    final receta = await getById(recetaId);
    if (receta == null) {
      return RecetaOperationResult.failure(['Receta no encontrada.']);
    }

    final db = await _AppDatabase.instance;
    final rows = await db.query(
      'recetas',
      columns: ['en_ronda'],
      where: 'id = ?',
      whereArgs: [recetaId],
    );
    final enRonda = (rows.first['en_ronda']! as int) != 0;
    if (enRonda) {
      return RecetaOperationResult.failure([
        'No se puede editar una receta que está siendo usada en una ronda.',
      ]);
    }

    await db.transaction((txn) async {
      await txn.update(
        'recetas',
        {'nombre': input.nombre, 'tipo': input.tipo},
        where: 'id = ?',
        whereArgs: [recetaId],
      );
      await txn.delete(
        'receta_ingredientes',
        where: 'receta_id = ?',
        whereArgs: [recetaId],
      );
      for (int i = 0; i < input.ingredientes.length; i++) {
        final item = input.ingredientes[i];
        await txn.insert('receta_ingredientes', {
          'receta_id': recetaId,
          'ingrediente_id': item.ingredienteId,
          'kg': item.kg,
          'posicion': i,
        });
      }
    });

    return RecetaOperationResult.success(id: recetaId);
  }

  /// Actualiza solo el orden (posicion) de los ingredientes de una receta.
  /// Permitido incluso si la receta está siendo usada en rondas.
  Future<RecetaOperationResult> reordenarIngredientes(
    int recetaId,
    List<({int ingredienteId, int kg})> ingredientesOrdenados,
  ) async {
    final receta = await getById(recetaId);
    if (receta == null) {
      return RecetaOperationResult.failure(['Receta no encontrada.']);
    }

    // Validate all provided ingredienteIds belong to this recipe.
    final existingIds =
        receta.ingredientes.map((ing) => ing.ingredienteId).toSet();
    for (final item in ingredientesOrdenados) {
      if (!existingIds.contains(item.ingredienteId)) {
        return RecetaOperationResult.failure([
          'Ingrediente ${item.ingredienteId} no pertenece a la receta.',
        ]);
      }
    }

    final db = await _AppDatabase.instance;
    await db.transaction((txn) async {
      for (int i = 0; i < ingredientesOrdenados.length; i++) {
        final item = ingredientesOrdenados[i];
        await txn.update(
          'receta_ingredientes',
          {'posicion': i},
          where: 'receta_id = ? AND ingrediente_id = ?',
          whereArgs: [recetaId, item.ingredienteId],
        );
      }
    });

    return RecetaOperationResult.success(id: recetaId);
  }
}
