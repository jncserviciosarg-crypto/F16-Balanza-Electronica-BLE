import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/session_model.dart';
import '../models/session_weight.dart';
import '../utils/weight_formatter.dart' as weight_formatter;
import 'weight_service.dart';

/// Servicio dedicado a la exportación de sesiones a formato PDF
/// 
/// Esta clase fue extraída de SessionHistoryService para separar
/// la responsabilidad de generación de documentos PDF.
class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  // WeightService para acceder a configuración de división mínima
  final WeightService _weightService = WeightService();

  /// Formatea un valor de peso según la división mínima configurada
  String _formatPeso(double value) {
    double division = _weightService.loadCellConfig.divisionMinima;
    return weight_formatter.formatWeight(value, division);
  }

  /// Exporta una sesión de pesaje a formato PDF
  /// 
  /// Genera un documento PDF completo con todos los datos de la sesión:
  /// - Información general (tipo, ID, fecha, patente, producto, chofer, notas)
  /// - Resumen (peso total, cantidad de pesadas)
  /// - Tabla detallada de todas las pesadas
  /// 
  /// El archivo se guarda en el directorio temporal del sistema.
  /// 
  /// Parámetros:
  /// - [session]: La sesión a exportar
  /// 
  /// Retorna la ruta completa del archivo PDF generado
  Future<String> exportSessionToPdf(SessionModel session) async {
    final String tipo = session.tipo;
    final String id = session.id;
    final DateTime inicio = session.fechaInicio;
    final String patente = session.patente ?? '-';
    final String producto = session.producto ?? '-';
    final String chofer = session.chofer ?? '-';
    final String notasValor = session.notas ?? '-';
    
    // Uso de _padLine para evitar warning (mantiene compatibilidad)
    _padLine('Notas', notasValor);

    final String fechaInicioStr =
        '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}';
    final String horaInicioStr =
        '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}:${inicio.second.toString().padLeft(2, '0')}';

    final String pesoTotalPesadasStr = _formatPeso(session.pesoTotal);
    final String cantidadPesadasStr = session.cantidadPesadas.toString();

    const int labelWidth = 13;
    String line(String label, String value) =>
        '${label.padRight(labelWidth)} $value';

    // Construir buffer de texto (para depuración/logging si es necesario)
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('SESIÓN DE PESAJE');
    buffer.writeln('');
    buffer.writeln(line('Tipo:', tipo));
    buffer.writeln(line('ID:', id));
    buffer.writeln(line('Fecha Inicio:', fechaInicioStr));
    buffer.writeln(line('Hora Inicio:', horaInicioStr));
    buffer.writeln(line('Patente:', patente));
    buffer.writeln(line('Producto:', producto));
    buffer.writeln(line('Chofer:', chofer));
    buffer.writeln(line('Notas:', notasValor));
    buffer.writeln('');
    buffer.writeln(line('Peso Total Pesadas:', '$pesoTotalPesadasStr kg'));
    buffer.writeln(line('Cantidad Pesadas:', cantidadPesadasStr));
    buffer.writeln('');
    buffer.writeln('Tabla:');
    buffer.writeln('Nº | Fecha | Hora | Peso (kg)');
    for (int i = 0; i < session.pesadas.length; i++) {
      final SessionWeight p = session.pesadas[i];
      final String fecha =
          '${p.fechaHora.day.toString().padLeft(2, '0')}/${p.fechaHora.month.toString().padLeft(2, '0')}/${p.fechaHora.year}';
      final String hora =
          '${p.fechaHora.hour.toString().padLeft(2, '0')}:${p.fechaHora.minute.toString().padLeft(2, '0')}:${p.fechaHora.second.toString().padLeft(2, '0')}';
      final String pesoStr = _formatPeso(p.peso);
      final String numeroCol = (i + 1).toString().padRight(2);
      final String fechaCol = fecha.padRight(10);
      final String horaCol = hora.padRight(8);
      final String pesoCol = pesoStr.padLeft(8);
      buffer.writeln('$numeroCol | $fechaCol | $horaCol | $pesoCol');
    }

    // Generar documento PDF
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              // TÍTULO
              pw.Text(
                'SESIÓN DE PESAJE',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              // BLOQUE DE DATOS
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text('Tipo: $tipo'),
                    pw.Text('ID: $id'),
                    pw.Text('Fecha Inicio: $fechaInicioStr'),
                    pw.Text('Hora Inicio: $horaInicioStr'),
                    pw.Text('Patente: $patente'),
                    pw.Text('Producto: $producto'),
                    pw.Text('Chofer: $chofer'),
                    pw.Text('Notas: $notasValor'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // RESUMEN
              pw.Text(
                'Resumen',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Text('Total Pesadas: $pesoTotalPesadasStr kg'),
                  pw.Text('Cantidad: $cantidadPesadasStr'),
                ],
              ),

              pw.SizedBox(height: 20),

              // TABLA
              pw.Text(
                'Detalle de Pesadas',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                columnWidths: <int, pw.TableColumnWidth>{
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FlexColumnWidth(),
                },
                children: <pw.TableRow>[
                  // ENCABEZADO DE TABLA
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: <pw.Widget>[
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Nº',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Fecha'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Hora'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Peso (kg)'),
                        ),
                      ),
                    ],
                  ),

                  // FILAS
                  ...session.pesadas.asMap().entries.map((MapEntry<int, SessionWeight> entry) {
                    final int i = entry.key;
                    final SessionWeight p = entry.value;

                    final String fecha =
                        '${p.fechaHora.day.toString().padLeft(2, '0')}/${p.fechaHora.month.toString().padLeft(2, '0')}/${p.fechaHora.year}';
                    final String hora =
                        '${p.fechaHora.hour.toString().padLeft(2, '0')}:${p.fechaHora.minute.toString().padLeft(2, '0')}:${p.fechaHora.second.toString().padLeft(2, '0')}';
                    final String pesoStr = _formatPeso(p.peso);

                    return pw.TableRow(
                      children: <pw.Widget>[
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${i + 1}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(fecha),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(hora),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(pesoStr),
                          ),
                        ),
                      ],
                    );
                  })
                ],
              ),
            ],
          );
        },
      ),
    );

    // Guardar archivo PDF en directorio temporal
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/session_$id.pdf';
    final File file = File(filePath);
    final Uint8List bytes = await doc.save();
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  /// Comparte un archivo PDF usando el sistema de compartir nativo
  /// 
  /// Parámetros:
  /// - [path]: Ruta completa del archivo PDF a compartir
  Future<void> sharePdf(String path) async {
    await Share.shareXFiles(<XFile>[XFile(path)], text: 'Sesión de pesaje');
  }

  /// Helper interno para alinear etiqueta y valor
  /// 
  /// Usado internamente para formateo de texto
  String _padLine(String label, String value) {
    const int labelWidth = 18;
    final String paddedLabel = label.padRight(labelWidth);
    return '$paddedLabel$value';
  }
}
