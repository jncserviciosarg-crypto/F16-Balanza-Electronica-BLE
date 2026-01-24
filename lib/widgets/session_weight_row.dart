import 'package:flutter/material.dart';
import '../models/session_weight.dart';
import '../services/weight_service.dart';
import '../utils/weight_formatter.dart' as weight_formatter;

/// Widget para mostrar una fila de pesada en formato tabla industrial
class SessionWeightRow extends StatelessWidget {
  final int numero;
  final SessionWeight pesada;
  final VoidCallback? onDelete;

  // Acceso a división mínima para formateo dinámico
  static final WeightService _weightService = WeightService();

  const SessionWeightRow({
    super.key,
    required this.numero,
    required this.pesada,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String fecha = _formatFecha(pesada.fechaHora);
    final String hora = _formatHora(pesada.fechaHora);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          children: <Widget>[
            // Número
            SizedBox(
              width: 16,
              child: Text(
                '$numero',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 4),
            // Fecha
            Expanded(
              flex: 16,
              child: Text(
                fecha,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            // Hora
            Expanded(
              flex: 12,
              child: Text(
                hora,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            // Peso
            Expanded(
              flex: 13,
              child: Text(
                _formatWeight(pesada.peso),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // Botón eliminar (opcional)
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                iconSize: 25,
                onPressed: onDelete,
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              )
            else
              const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatHora(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatWeight(double value) {
    double division = _weightService.loadCellConfig.divisionMinima;
    return weight_formatter.formatWeight(value, division);
  }
}
