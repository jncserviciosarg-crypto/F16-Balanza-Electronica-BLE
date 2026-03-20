import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
// Repository
// ---------------------------------------------------------------------------

class RecetasRepository {
  final SharedPreferences _prefs;

  static const String _keyPrefix = 'receta_';
  static const String _idsKey = 'recetas_ids';
  static const String _rondasPrefix = 'receta_en_ronda_';

  RecetasRepository(this._prefs);

  // LECTURA ---------------------------------------------------------------

  Future<RecetaConIngredientes?> getById(int recetaId) async {
    final json = _prefs.getString('$_keyPrefix$recetaId');
    if (json == null) return null;
    return _fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<List<RecetaConIngredientes>> getAll() async {
    final ids = _prefs.getStringList(_idsKey) ?? [];
    final results = <RecetaConIngredientes>[];
    for (final idStr in ids) {
      final id = int.tryParse(idStr);
      if (id == null) continue;
      final r = await getById(id);
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

    final enRonda = _prefs.getBool('$_rondasPrefix$recetaId') ?? false;
    if (enRonda) {
      return RecetaOperationResult.failure([
        'No se puede editar una receta que está siendo usada en una ronda.',
      ]);
    }

    final updated = RecetaConIngredientes(
      receta: RecetaRow(
        id: recetaId,
        nombre: input.nombre,
        tipo: input.tipo,
      ),
      tipo: input.tipo,
      ingredientes: input.ingredientes
          .asMap()
          .entries
          .map(
            (e) => RecetaIngredienteRow(
              ingredienteId: e.value.ingredienteId,
              kg: e.value.kg,
              posicion: e.key,
            ),
          )
          .toList(),
    );

    await _prefs.setString(
      '$_keyPrefix$recetaId',
      jsonEncode(_toJson(updated)),
    );

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

    final updatedIngredientes = <RecetaIngredienteRow>[];
    for (int i = 0; i < ingredientesOrdenados.length; i++) {
      final item = ingredientesOrdenados[i];
      final existing = receta.ingredientes.where(
        (ing) => ing.ingredienteId == item.ingredienteId,
      );
      if (existing.isEmpty) {
        return RecetaOperationResult.failure([
          'Ingrediente ${item.ingredienteId} no pertenece a la receta.',
        ]);
      }
      updatedIngredientes.add(
        RecetaIngredienteRow(
          ingredienteId: item.ingredienteId,
          kg: existing.first.kg,
          posicion: i,
        ),
      );
    }

    final updated = RecetaConIngredientes(
      receta: receta.receta,
      tipo: receta.tipo,
      ingredientes: updatedIngredientes,
    );

    await _prefs.setString(
      '$_keyPrefix$recetaId',
      jsonEncode(_toJson(updated)),
    );

    return RecetaOperationResult.success(id: recetaId);
  }

  // Helpers ---------------------------------------------------------------

  RecetaConIngredientes _fromJson(Map<String, dynamic> json) {
    final receta = RecetaRow(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
    );
    final ingredientes = (json['ingredientes'] as List<dynamic>)
        .map(
          (i) => RecetaIngredienteRow(
            ingredienteId: i['ingredienteId'] as int,
            kg: i['kg'] as int,
            posicion: i['posicion'] as int,
          ),
        )
        .toList();
    return RecetaConIngredientes(
      receta: receta,
      tipo: receta.tipo,
      ingredientes: ingredientes,
    );
  }

  Map<String, dynamic> _toJson(RecetaConIngredientes r) {
    return {
      'id': r.receta.id,
      'nombre': r.receta.nombre,
      'tipo': r.tipo,
      'ingredientes': r.ingredientes
          .map(
            (i) => {
              'ingredienteId': i.ingredienteId,
              'kg': i.kg,
              'posicion': i.posicion,
            },
          )
          .toList(),
    };
  }
}
