import 'package:flutter/material.dart';
import 'package:f16_balanza_electronica/models/filter_params.dart';

class FilterEditor extends StatefulWidget {
  final FilterParams initial;
  final Function(FilterParams) onSave;

  const FilterEditor({
    Key? key,
    required this.initial,
    required this.onSave,
  }) : super(key: key);

  @override
  State<FilterEditor> createState() => _FilterEditorState();
}

class _FilterEditorState extends State<FilterEditor> {
  late TextEditingController _muestrasController;
  late TextEditingController _ventanaController;
  late TextEditingController _emaAlphaController;
  late TextEditingController _updateIntervalMsController;

  @override
  void initState() {
    super.initState();
    _muestrasController =
        TextEditingController(text: widget.initial.muestras.toString());
    _ventanaController =
        TextEditingController(text: widget.initial.ventana.toString());
    _emaAlphaController =
        TextEditingController(text: widget.initial.emaAlpha.toString());
    _updateIntervalMsController =
        TextEditingController(text: widget.initial.updateIntervalMs.toString());
  }

  @override
  void dispose() {
    _muestrasController.dispose();
    _ventanaController.dispose();
    _emaAlphaController.dispose();
    _updateIntervalMsController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final params = FilterParams(
      muestras:
          int.tryParse(_muestrasController.text) ?? widget.initial.muestras,
      ventana: int.tryParse(_ventanaController.text) ?? widget.initial.ventana,
      emaAlpha:
          double.tryParse(_emaAlphaController.text) ?? widget.initial.emaAlpha,
      updateIntervalMs: int.tryParse(_updateIntervalMsController.text) ??
          widget.initial.updateIntervalMs,
      limiteSuperior: widget.initial.limiteSuperior,
      limiteInferior: widget.initial.limiteInferior,
    );
    widget.onSave(params);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _muestrasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Muestras (trimmed mean)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ventanaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bloque de Muestras (moving average)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emaAlphaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'EMA Alpha',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _updateIntervalMsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Intervalo actualización (ms)',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleSave,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
