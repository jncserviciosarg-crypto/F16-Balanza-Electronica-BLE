import 'dart:typed_data';

import 'package:f16_balanza_electronica/models/session_weight.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/session_model.dart';
import '../services/session_history_service.dart';
import '../services/weight_service.dart';
import '../utils/screenshot_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SessionHistoryService _service = SessionHistoryService();
  final WeightService _weightService = WeightService();
  final GlobalKey<State<StatefulWidget>> _screenshotKey = GlobalKey();
  List<SessionModel> _allSessions = <SessionModel>[];
  List<SessionModel> _filteredSessions = <SessionModel>[];
  String? _selectedFilter; // null | 'carga' | 'descarga'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  // ==== Formateo dinámico según división mínima ====
  int _decimalsForDivision(double division) {
    if (division >= 1) return 0;
    // Representar con precisión y eliminar ceros a la derecha
    String s = division.toStringAsFixed(6); // hasta 6 decimales
    if (!s.contains('.')) return 0;
    String frac = s.split('.')[1];
    frac = frac.replaceAll(RegExp(r'0+$'), '');
    return frac.length;
  }

  String _formatWeight(double value) {
    double division = _weightService.loadCellConfig.divisionMinima;
    int dec = _decimalsForDivision(division);
    return value.toStringAsFixed(dec);
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    final List<SessionModel> sessions = await _service.getSessions();

    setState(() {
      _allSessions = sessions;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredSessions = _allSessions;
    } else {
      _filteredSessions =
          _allSessions.where((SessionModel s) => s.tipo == _selectedFilter).toList();
    }
  }

  void _handleFilterChange(String? filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  Future<void> _handleExportXlsx() async {
    try {
      _showSnackBar('Generando XLSX completo...', Colors.blue);

      final String filePath = await _service.exportAllSessionsToXlsx();

      await Share.shareXFiles(<XFile>[XFile(filePath)],
          text: 'Exportación completa de sesiones con detalle de pesadas');

      _showSnackBar('XLSX compartido exitosamente', Colors.green);
    } catch (e) {
      _showSnackBar('Error al exportar XLSX: $e', Colors.red);
    }
  }

  // F-16: DIÁLOGO DE DETALLES DE SESIÓN
  void _viewSessionDetails(SessionModel session) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.grey[900], // F-16: fondo oscuro
        title: Text(
          '${session.tipo.toUpperCase()} - SESIÓN ${session.id}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5, // F-16
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildDetailRow('Tipo', session.tipo.toUpperCase()),
              _buildDetailRow('Fecha Inicio',
                  '${session.fechaInicio.day.toString().padLeft(2, '0')}/${session.fechaInicio.month.toString().padLeft(2, '0')}/${session.fechaInicio.year}'),
              _buildDetailRow('Hora Inicio',
                  '${session.fechaInicio.hour.toString().padLeft(2, '0')}:${session.fechaInicio.minute.toString().padLeft(2, '0')}:${session.fechaInicio.second.toString().padLeft(2, '0')}'),
              if (session.patente != null)
                _buildDetailRow('Patente', session.patente!),
              if (session.producto != null)
                _buildDetailRow('Producto', session.producto!),
              if (session.chofer != null)
                _buildDetailRow('Chofer', session.chofer!),
              Divider(color: Colors.blueGrey[700]), // F-16
              _buildDetailRow(
                  'Cantidad Pesadas', session.cantidadPesadas.toString()),
              _buildDetailRow(
                  'Peso Total', '${_formatWeight(session.pesoTotal)} kg'),
              if (session.notas != null && session.notas!.isNotEmpty)
                _buildDetailRow('Notas', session.notas!),
              const SizedBox(height: 16),
              Text(
                'PESADAS:', // F-16: MAYÚSCULAS
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[400],
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              ...session.pesadas.asMap().entries.map((MapEntry<int, SessionWeight> entry) {
                final int index = entry.key + 1;
                final SessionWeight pesada = entry.value;
                final String fecha =
                    '${pesada.fechaHora.day.toString().padLeft(2, '0')}/${pesada.fechaHora.month.toString().padLeft(2, '0')} ${pesada.fechaHora.hour.toString().padLeft(2, '0')}:${pesada.fechaHora.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$index. ${_formatWeight(pesada.peso)} kg - $fecha',
                    style: TextStyle(color: Colors.grey[300]), // F-16
                  ),
                );
              }) //.toList(),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CERRAR',
              style: TextStyle(
                color: Colors.blueGrey[400],
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // F-16: FILA DE DETALLE
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[400], // F-16
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[300]), // F-16
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSingleSessionToPdf(SessionModel session) async {
    try {
      final String filePath = await _service.exportSessionToPdf(session);
      final XFile file = XFile(filePath);
      await Share.shareXFiles(<XFile>[file], text: 'Sesión ${session.id}');
      _showSnackBar('PDF compartido', Colors.green);
    } catch (e) {
      _showSnackBar('Error al exportar PDF: $e', Colors.red);
    }
  }

  // F-16: DIÁLOGO DE CONFIRMACIÓN BORRAR TODO
  Future<void> _handleClearAll() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.grey[900], // F-16
        title: const Text(
          'CONFIRMAR ELIMINACIÓN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          '¿Está seguro de eliminar todos los registros?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCELAR',
              style: TextStyle(
                color: Colors.grey[400],
                letterSpacing: 1.2,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.red[800]), // F-16
            child: const Text(
              'ELIMINAR TODO',
              style: TextStyle(letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteAllSessions();
      _showSnackBar('Todas las sesiones eliminadas', Colors.orange);
      _loadSessions();
    }
  }

  // F-16: DIÁLOGO DE CONFIRMACIÓN ELIMINAR SESIÓN
  Future<void> _handleDeleteSession(String id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.grey[900], // F-16
        title: const Text(
          'CONFIRMAR ELIMINACIÓN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          '¿Eliminar esta sesión?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCELAR',
              style: TextStyle(
                color: Colors.grey[400],
                letterSpacing: 1.2,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.red[800]), // F-16
            child: const Text(
              'ELIMINAR',
              style: TextStyle(letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteSession(id);
      _showSnackBar('Sesión eliminada', Colors.orange);
      _loadSessions();
    }
  }

  // F-16: SNACKBAR CON COLORES NORMALIZADOS
  void _showSnackBar(String message, Color color) {
    // Normalizar colores a paleta F-16
    Color bgColor = color;
    if (color == Colors.blue) bgColor = Colors.cyan[700]!;
    if (color == Colors.green) bgColor = Colors.green[700]!;
    if (color == Colors.red) bgColor = Colors.red[800]!;
    if (color == Colors.orange) bgColor = Colors.blueGrey[600]!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // F-16: BUILD METHOD REFACTORIZADO
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: _screenshotKey,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'HISTORIAL', // F-16: MAYÚSCULAS
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.blueGrey[800], // F-16: azul militar
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.grey[400]), // F-16
                onPressed: _loadSessions,
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.grey[400]), // F-16
                onPressed: () async {
                  final Uint8List? bytes =
                      await ScreenshotHelper.captureWidget(_screenshotKey);
                  if (bytes != null) {
                    await ScreenshotHelper.sharePng(bytes,
                        filenamePrefix: 'historial');
                  } else {
                    _showSnackBar('Error al capturar pantalla', Colors.red);
                  }
                },
              ),
            ],
          ),
          body: Container(
            color: Colors.grey[900], // F-16
            child: Column(
              children: <Widget>[
                _buildFilterSection(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.cyan[700], // F-16
                          ),
                        )
                      : _filteredSessions.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: Colors.cyan[700], // F-16
                              onRefresh: _loadSessions,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _filteredSessions.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final SessionModel session = _filteredSessions[index];
                                  final String fecha =
                                      '${session.fechaInicio.day.toString().padLeft(2, '0')}/${session.fechaInicio.month.toString().padLeft(2, '0')}/${session.fechaInicio.year}';
                                  final String hora =
                                      '${session.fechaInicio.hour.toString().padLeft(2, '0')}:${session.fechaInicio.minute.toString().padLeft(2, '0')}:${session.fechaInicio.second.toString().padLeft(2, '0')}';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850], // F-16: uniforme
                                      borderRadius: BorderRadius.circular(
                                          6), // F-16: angular
                                      border: Border.all(
                                          color: Colors.blueGrey[700]!,
                                          width: 1),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      leading: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors
                                              .grey[800], // F-16: uniforme
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.blueGrey[600]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            session.tipo
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color:
                                                  Colors.blueGrey[300], // F-16
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        '${session.tipo.toUpperCase()} • ${session.cantidadPesadas} PESADAS',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 1, // F-16
                                        ),
                                      ),
                                      subtitle: Text(
                                        '$fecha $hora'
                                        '${session.patente != null ? ' • ${session.patente}' : ''}'
                                        '${session.producto != null ? ' • ${session.producto}' : ''}',
                                        style: TextStyle(
                                          color: Colors.grey[500], // F-16
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            '${_formatWeight(session.pesoTotal)} kg',
                                            style: TextStyle(
                                              color: Colors.green[
                                                  700], // F-16: verde militar
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.visibility_outlined,
                                              color: Colors.cyan[
                                                  700], // F-16: cian militar
                                              size: 20,
                                            ),
                                            tooltip: 'Ver sesión',
                                            onPressed: () =>
                                                _viewSessionDetails(session),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.picture_as_pdf_outlined,
                                              color: Colors.green[
                                                  700], // F-16: verde militar
                                              size: 20,
                                            ),
                                            tooltip: 'Exportar PDF',
                                            onPressed: () =>
                                                _exportSingleSessionToPdf(
                                                    session),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red[
                                                  800], // F-16: rojo oscuro
                                              size: 20,
                                            ),
                                            tooltip: 'Eliminar',
                                            onPressed: () =>
                                                _handleDeleteSession(
                                                    session.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ));
  }

  // F-16: SECCIÓN DE FILTROS
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850], // F-16
        border: Border(
          bottom: BorderSide(color: Colors.blueGrey[700]!, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            Text(
              '${_filteredSessions.length} SESIONES', // F-16: MAYÚSCULAS
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            _buildFilterChip('TODO', null),
            const SizedBox(width: 8),
            _buildFilterChip('CARGAS', 'carga'),
            const SizedBox(width: 8),
            _buildFilterChip('DESCARGAS', 'descarga'),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _handleExportXlsx,
              icon: const Icon(Icons.table_chart, size: 16),
              label: const Text(
                'EXPORTAR XLSX',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700], // F-16: azul militar
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // F-16: angular
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _handleClearAll,
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text(
                'BORRAR TODO',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800], // F-16: rojo oscuro
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // F-16: CHIP DE FILTRO
  Widget _buildFilterChip(String label, String? filterValue) {
    final bool isSelected = _selectedFilter == filterValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) =>
          _handleFilterChange(selected ? filterValue : null),
      backgroundColor: Colors.grey[800], // F-16
      selectedColor: Colors.blueGrey[700], // F-16: azul militar
      side: BorderSide(
        color: isSelected ? Colors.blueGrey[500]! : Colors.grey[700]!,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4), // F-16: angular
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[400],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
        letterSpacing: 1,
      ),
    );
  }

  // F-16: ESTADO VACÍO
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.inbox, size: 80, color: Colors.grey[600]), // F-16
          const SizedBox(height: 16),
          Text(
            'SIN SESIONES', // F-16: MAYÚSCULAS
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las sesiones aparecerán aquí',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
