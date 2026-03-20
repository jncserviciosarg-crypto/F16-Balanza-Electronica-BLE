import 'package:flutter/material.dart';

import '../../providers/recetas_provider.dart';

class RecetaOrdenScreen extends StatefulWidget {
  final RecetaConIngredientes receta;
  final RecetasProvider provider;

  const RecetaOrdenScreen({
    super.key,
    required this.receta,
    required this.provider,
  });

  @override
  State<RecetaOrdenScreen> createState() => _RecetaOrdenScreenState();
}

class _RecetaOrdenScreenState extends State<RecetaOrdenScreen> {
  late List<RecetaIngredienteRow> _ingredientes;
  late RecetaConIngredientes _receta;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _receta = widget.receta;
    _ingredientes = (List<RecetaIngredienteRow>.from(widget.receta.ingredientes))
      ..sort((a, b) => a.posicion.compareTo(b.posicion));
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    final result = await widget.provider.reordenarIngredientes(
      _receta.receta.id,
      _ingredientes
          .map((i) => (ingredienteId: i.ingredienteId, kg: i.kg))
          .toList(),
    );

    if (!mounted) return;

    setState(() => _guardando = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.join('\n'))),
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orden: ${_receta.receta.nombre}'),
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Guardar orden',
              onPressed: _guardar,
            ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _ingredientes.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _ingredientes.removeAt(oldIndex);
            _ingredientes.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final ing = _ingredientes[index];
          return ListTile(
            key: ValueKey(ing.ingredienteId),
            leading: const Icon(Icons.drag_handle),
            title: Text('Ingrediente ${ing.ingredienteId}'),
            trailing: Text('${ing.kg} kg'),
          );
        },
      ),
    );
  }
}
