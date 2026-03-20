import 'package:flutter/foundation.dart';

import '../services/persistence/recetas_repository.dart';

export '../services/persistence/recetas_repository.dart'
    show
        RecetaConIngredientes,
        RecetaInput,
        RecetaIngredienteRow,
        RecetaOperationResult,
        RecetaOperationSuccess,
        RecetaOperationFailure,
        RecetaRow;

class RecetasProvider extends ChangeNotifier {
  final RecetasRepository _repo;

  RecetasProvider() : _repo = RecetasRepository();

  List<String>? _handleResult(RecetaOperationResult result) {
    return switch (result) {
      RecetaOperationSuccess() => null,
      RecetaOperationFailure(:final errors) => errors,
    };
  }

  Future<List<String>?> editar(
    int recetaId,
    RecetaInput input,
  ) async {
    return _handleResult(await _repo.editar(recetaId, input));
  }

  Future<List<String>?> reordenarIngredientes(
    int recetaId,
    List<({int ingredienteId, int kg})> ingredientesOrdenados,
  ) async {
    return _handleResult(
      await _repo.reordenarIngredientes(recetaId, ingredientesOrdenados),
    );
  }
}
