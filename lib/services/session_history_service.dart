import 'dart:convert';
import 'dart:io';
import 'package:f16_balanza_electronica/models/session_weight.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/session_model.dart';
import 'weight_service.dart';
import 'pdf_export_service.dart';
import '../utils/weight_formatter.dart' as weight_formatter;

/// Servicio para gestionar sesiones de pesaje (Carga/Descarga)
/// Usa persistencia local separada para no interferir con history_service existente
class SessionHistoryService {
  static final SessionHistoryService _instance =
      SessionHistoryService._internal();
  factory SessionHistoryService() => _instance;
  SessionHistoryService._internal();

  // Namespace separado para no interferir con persistencia existente
  static const String _keySessionsPrefix = 'session_history_';
  static const String _keySessionsList = 'session_history_list';
  static const int _maxSessions = 500;

  // WeightService para acceder a configuración de división mínima
  final WeightService _weightService = WeightService();
  
  // PdfExportService para delegación de exportación PDF
  final PdfExportService _pdfExportService = PdfExportService();

  // ==== Formateo dinámico de pesos según división mínima ====
  String _formatPeso(double value) {
    double division = _weightService.loadCellConfig.divisionMinima;
    return weight_formatter.formatWeight(value, division);
  }

  /// Obtiene todas las sesiones guardadas
  Future<List<SessionModel>> getSessions() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> sessionIds = await _loadSessionIdsList();
      final List<SessionModel> sessions = <SessionModel>[];

      for (String id in sessionIds) {
        final String? jsonString = prefs.getString('$_keySessionsPrefix$id');
        if (jsonString != null && jsonString.isNotEmpty) {
          try {
            final SessionModel session = SessionModel.fromJson(jsonString);
            sessions.add(session);
          } catch (e) {
            debugPrint('Error cargando sesión $id: $e');
          }
        }
      }

      // Ordenar por fecha de inicio (más recientes primero)
      sessions.sort((SessionModel a, SessionModel b) => b.fechaInicio.compareTo(a.fechaInicio));

      return sessions;
    } catch (e) {
      debugPrint('Error obteniendo sesiones: $e');
      return <SessionModel>[];
    }
  }

  /// Obtiene una sesión por su ID
  Future<SessionModel?> getSessionById(String id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('$_keySessionsPrefix$id');

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      return SessionModel.fromJson(jsonString);
    } catch (e) {
      debugPrint('Error obteniendo sesión $id: $e');
      return null;
    }
  }

  /// Guarda una sesión (crear nueva o actualizar existente)
  Future<void> saveSession(SessionModel session) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = session.toJson();

      // Guardar la sesión
      await prefs.setString('$_keySessionsPrefix${session.id}', jsonString);

      // Actualizar lista de IDs
      List<String> sessionIds = await _loadSessionIdsList();
      if (!sessionIds.contains(session.id)) {
        sessionIds.insert(0, session.id);

        // Limitar cantidad de sesiones
        if (sessionIds.length > _maxSessions) {
          // Eliminar las más antiguas
          final List<String> idsToRemove = sessionIds.sublist(_maxSessions);
          for (String oldId in idsToRemove) {
            await prefs.remove('$_keySessionsPrefix$oldId');
          }
          sessionIds = sessionIds.sublist(0, _maxSessions);
        }

        await prefs.setString(_keySessionsList, jsonEncode(sessionIds));
      }
    } catch (e) {
      debugPrint('Error guardando sesión: $e');
      throw Exception('No se pudo guardar la sesión: $e');
    }
  }

  /// Elimina una sesión por su ID
  Future<void> deleteSession(String id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Eliminar la sesión
      await prefs.remove('$_keySessionsPrefix$id');

      // Actualizar lista de IDs
      List<String> sessionIds = await _loadSessionIdsList();
      sessionIds.remove(id);
      await prefs.setString(_keySessionsList, jsonEncode(sessionIds));
    } catch (e) {
      debugPrint('Error eliminando sesión: $e');
      throw Exception('No se pudo eliminar la sesión: $e');
    }
  }

  /// Elimina todas las sesiones
  Future<void> deleteAllSessions() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> sessionIds = await _loadSessionIdsList();

      // Eliminar cada sesión
      for (String id in sessionIds) {
        await prefs.remove('$_keySessionsPrefix$id');
      }

      // Limpiar lista de IDs
      await prefs.remove(_keySessionsList);
    } catch (e) {
      debugPrint('Error eliminando todas las sesiones: $e');
      throw Exception('No se pudieron eliminar las sesiones: $e');
    }
  }

  /// Obtiene sesiones filtradas por tipo
  Future<List<SessionModel>> getSessionsByTipo(String tipo) async {
    final List<SessionModel> allSessions = await getSessions();
    return allSessions.where((SessionModel s) => s.tipo == tipo).toList();
  }

  /// Obtiene sesiones filtradas por rango de fechas
  Future<List<SessionModel>> getSessionsByDateRange(
      DateTime inicio, DateTime fin) async {
    final List<SessionModel> allSessions = await getSessions();
    return allSessions.where((SessionModel s) {
      return s.fechaInicio.isAfter(inicio) && s.fechaInicio.isBefore(fin);
    }).toList();
  }

  /// Obtiene estadísticas de las sesiones
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final List<SessionModel> sessions = await getSessions();

      if (sessions.isEmpty) {
        return <String, dynamic>{
          'totalSesiones': 0,
          'totalCargas': 0,
          'totalDescargas': 0,
          'pesoTotalCargas': 0.0,
          'pesoTotalDescargas': 0.0,
        };
      }

      int totalCargas = 0;
      int totalDescargas = 0;
      double pesoTotalCargas = 0.0;
      double pesoTotalDescargas = 0.0;

      for (SessionModel session in sessions) {
        if (session.tipo == 'carga') {
          totalCargas++;
          pesoTotalCargas += session.pesoNeto;
        } else if (session.tipo == 'descarga') {
          totalDescargas++;
          pesoTotalDescargas += session.pesoNeto;
        }
      }

      return <String, dynamic>{
        'totalSesiones': sessions.length,
        'totalCargas': totalCargas,
        'totalDescargas': totalDescargas,
        'pesoTotalCargas': pesoTotalCargas,
        'pesoTotalDescargas': pesoTotalDescargas,
        'pesoNeto': pesoTotalCargas - pesoTotalDescargas,
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas: $e');
      return <String, dynamic>{};
    }
  }

  /// Exporta una sesión a formato CSV
  String exportSessionToCsv(SessionModel session) {
    try {
      StringBuffer csv = StringBuffer();

      // Encabezados de sesión
      csv.writeln('SESIÓN DE ${session.tipo.toUpperCase()}');
      csv.writeln('ID,${session.id}');
      csv.writeln(
          'Fecha Inicio,${session.fechaInicio.toIso8601String().split('T')[0]}');
      csv.writeln(
          'Hora Inicio,${session.fechaInicio.toIso8601String().split('T')[1].split('.')[0]}');
      if (session.fechaFin != null) {
        csv.writeln(
            'Fecha Fin,${session.fechaFin!.toIso8601String().split('T')[0]}');
        csv.writeln(
            'Hora Fin,${session.fechaFin!.toIso8601String().split('T')[1].split('.')[0]}');
      }
      if (session.patente != null) csv.writeln('Patente,${session.patente}');
      if (session.producto != null) csv.writeln('Producto,${session.producto}');
      if (session.chofer != null) csv.writeln('Chofer,${session.chofer}');
      if (session.notas != null) csv.writeln('Notas,${session.notas}');

      csv.writeln('');
      csv.writeln('PESOS');
      csv.writeln('Peso Inicial,${_formatPeso(session.pesoInicial)} kg');
      csv.writeln('Peso Final,${_formatPeso(session.pesoFinal)} kg');
      csv.writeln('Peso Neto,${_formatPeso(session.pesoNeto)} kg');
      csv.writeln('Peso Total Pesadas,${_formatPeso(session.pesoTotal)} kg');

      csv.writeln('');
      csv.writeln('PESADAS');
      csv.writeln('Número,Fecha,Hora,Peso (kg)');

      int contador = 1;
      for (SessionWeight pesada in session.pesadas) {
        final String fecha = pesada.fechaHora.toIso8601String().split('T')[0];
        final String hora =
            pesada.fechaHora.toIso8601String().split('T')[1].split('.')[0];
        csv.writeln('$contador,$fecha,$hora,${_formatPeso(pesada.peso)}');
        contador++;
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Error exportando sesión a CSV: $e');
      return '';
    }
  }

  /// Exporta todas las sesiones a formato CSV
  Future<String> exportAllSessionsToCsv() async {
    try {
      final List<SessionModel> sessions = await getSessions();
      StringBuffer csv = StringBuffer();

      csv.writeln('HISTORIAL DE SESIONES');
      csv.writeln('');
      csv.writeln(
          'ID,Tipo,Fecha Inicio,Hora Inicio,Fecha Fin,Hora Fin,Patente,Producto,Chofer,Peso Inicial (kg),Peso Final (kg),Peso Neto (kg),Cantidad Pesadas');

      for (SessionModel session in sessions) {
        final String fechaInicio = session.fechaInicio.toIso8601String().split('T')[0];
        final String horaInicio =
            session.fechaInicio.toIso8601String().split('T')[1].split('.')[0];
        final String fechaFin = session.fechaFin != null
            ? session.fechaFin!.toIso8601String().split('T')[0]
            : '';
        final String horaFin = session.fechaFin != null
            ? session.fechaFin!.toIso8601String().split('T')[1].split('.')[0]
            : '';

        csv.writeln(
            '${session.id},${session.tipo},$fechaInicio,$horaInicio,$fechaFin,$horaFin,${session.patente ?? ''},${session.producto ?? ''},${session.chofer ?? ''},${_formatPeso(session.pesoInicial)},${_formatPeso(session.pesoFinal)},${_formatPeso(session.pesoNeto)},${session.cantidadPesadas}');
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Error exportando todas las sesiones: $e');
      return '';
    }
  }

  /// Carga la lista de IDs de sesiones
  Future<List<String>> _loadSessionIdsList() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keySessionsList);

      if (jsonString == null || jsonString.isEmpty) {
        return <String>[];
      }

      return List<String>.from(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('Error cargando lista de IDs de sesiones: $e');
      return <String>[];
    }
  }

  /// Exporta una sesión a formato XLSX (archivo real)
  /// Retorna la ruta completa del archivo generado
  Future<String> exportSessionToXlsx(SessionModel session) async {
    try {
      // Crear workbook
      final Excel excel = Excel.createExcel();
      // Eliminar hoja inicial vacía (Sheet1 u hoja por defecto)
      try {
        final String? defaultSheet = excel.getDefaultSheet();
        if (defaultSheet != null && defaultSheet != 'Sesion') {
          excel.delete(defaultSheet);
        }
      } catch (_) {
        // Silencioso: si la API difiere, ignorar
      }
      final Sheet sheet = excel['Sesion'];

      // ═══════════════════════════════════════════════════════════
      // INFORMACIÓN GENERAL (Filas 1-10)
      // ═══════════════════════════════════════════════════════════
      int currentRow = 0;

      // Título principal
      Data titleCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      titleCell.value = 'SESIÓN DE PESAJE';
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
      );
      currentRow += 2;

      // Tipo de sesión
      _addDataRow(sheet, currentRow++, 'Tipo:', session.tipo.toUpperCase());

      // ID
      _addDataRow(sheet, currentRow++, 'ID:', session.id);

      // Fecha y hora de inicio
      final String fechaInicio =
          '${session.fechaInicio.day.toString().padLeft(2, '0')}/${session.fechaInicio.month.toString().padLeft(2, '0')}/${session.fechaInicio.year}';
      final String horaInicio =
          '${session.fechaInicio.hour.toString().padLeft(2, '0')}:${session.fechaInicio.minute.toString().padLeft(2, '0')}:${session.fechaInicio.second.toString().padLeft(2, '0')}';
      _addDataRow(sheet, currentRow++, 'Fecha Inicio:', fechaInicio);
      _addDataRow(sheet, currentRow++, 'Hora Inicio:', horaInicio);

      // Fecha y hora de fin (si existe)
      if (session.fechaFin != null) {
        final String fechaFin =
            '${session.fechaFin!.day.toString().padLeft(2, '0')}/${session.fechaFin!.month.toString().padLeft(2, '0')}/${session.fechaFin!.year}';
        final String horaFin =
            '${session.fechaFin!.hour.toString().padLeft(2, '0')}:${session.fechaFin!.minute.toString().padLeft(2, '0')}:${session.fechaFin!.second.toString().padLeft(2, '0')}';
        _addDataRow(sheet, currentRow++, 'Fecha Fin:', fechaFin);
        _addDataRow(sheet, currentRow++, 'Hora Fin:', horaFin);
      }

      // Datos opcionales
      if (session.patente != null) {
        _addDataRow(sheet, currentRow++, 'Patente:', session.patente!);
      }
      if (session.producto != null) {
        _addDataRow(sheet, currentRow++, 'Producto:', session.producto!);
      }
      if (session.chofer != null) {
        _addDataRow(sheet, currentRow++, 'Chofer:', session.chofer!);
      }
      if (session.notas != null) {
        _addDataRow(sheet, currentRow++, 'Notas:', session.notas!);
      }

      currentRow += 2; // Espacio

      // ═══════════════════════════════════════════════════════════
      // RESUMEN DE PESOS (sin filas de Peso Inicial / Final / Neto según requerimiento)
      _addDataRow(sheet, currentRow++, 'Peso Total Pesadas:',
          '${_formatPeso(session.pesoTotal)} kg');
      _addDataRow(sheet, currentRow++, 'Cantidad Pesadas:',
          '${session.cantidadPesadas}');

      currentRow += 2; // Espacio antes de la tabla

      // ═══════════════════════════════════════════════════════════
      // TABLA DE PESADAS (desde fila 12 aprox)
      // ═══════════════════════════════════════════════════════════
      final int headerRow = currentRow;

      // Encabezados de tabla
      final List<String> headers = <String>['Nº', 'Fecha', 'Hora', 'Peso (kg)'];
      for (int col = 0; col < headers.length; col++) {
        Data cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
        cell.value = headers[col];
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: '#4CAF50',
          horizontalAlign: HorizontalAlign.Center,
        );
      }
      currentRow++;

      // Datos de pesadas
      for (int i = 0; i < session.pesadas.length; i++) {
        final SessionWeight pesada = session.pesadas[i];
        final String fecha =
            '${pesada.fechaHora.day.toString().padLeft(2, '0')}/${pesada.fechaHora.month.toString().padLeft(2, '0')}/${pesada.fechaHora.year}';
        final String hora =
            '${pesada.fechaHora.hour.toString().padLeft(2, '0')}:${pesada.fechaHora.minute.toString().padLeft(2, '0')}:${pesada.fechaHora.second.toString().padLeft(2, '0')}';

        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: currentRow))
            .value = i + 1;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: currentRow))
            .value = fecha;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 2, rowIndex: currentRow))
            .value = hora;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 3, rowIndex: currentRow))
            .value = _formatPeso(pesada.peso);

        currentRow++;
      }

      // Autoajuste de columnas utilizadas (0..3). Si la API soporta setColAutoFit.
      try {
        for (int col = 0; col <= 3; col++) {
          sheet.setColAutoFit(col);
        }
      } catch (_) {
        // Fallback manual simple si no existe setColAutoFit: calcular ancho aproximado
        try {
          final Map<int, int> maxLen = <int, int>{};
          for (final List<Data?> row in sheet.rows) {
            for (int c = 0; c < row.length && c <= 3; c++) {
              final String val = row[c]?.value?.toString() ?? '';
              maxLen[c] = (maxLen[c] ?? 0).clamp(0, 100);
              if (val.length > (maxLen[c] ?? 0)) {
                maxLen[c] = val.length;
              }
            }
          }
          maxLen.forEach((int col, int len) {
            // Aproximar ancho: cada carácter ~1 unidad (ajustar si la lib requiere otra métrica)
            sheet.setColWidth(col, (len + 2).toDouble());
          });
        } catch (_) {}
      }

      // ═══════════════════════════════════════════════════════════
      // GUARDAR ARCHIVO
      // ═══════════════════════════════════════════════════════════
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/session_${session.id}.xlsx';
      final File file = File(filePath);

      // Codificar y escribir
      final List<int>? bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      } else {
        throw Exception('Error al codificar archivo XLSX');
      }

      // XLSX generado: información suprimida en logs finales
      return filePath;
    } catch (e) {
      debugPrint('Error exportando sesión a XLSX: $e');
      throw Exception('No se pudo exportar a XLSX: $e');
    }
  }

  /// Exporta TODAS las sesiones a un archivo XLSX con 3 hojas:
  /// - "Todas las Sesiones": todas las sesiones
  /// - "Cargas": solo sesiones con tipo == "carga"
  /// - "Descargas": solo sesiones con tipo == "descarga"
  Future<String> exportAllSessionsToXlsxMultiSheet(
      List<SessionModel> sessions) async {
    try {
      final Excel excel = Excel.createExcel();

      // Eliminar hoja por defecto
      try {
        final String? defaultSheet = excel.getDefaultSheet();
        if (defaultSheet != null) {
          excel.delete(defaultSheet);
        }
      } catch (_) {}

      // Separar sesiones por tipo
      final List<SessionModel> cargas =
          sessions.where((SessionModel s) => s.tipo.toLowerCase() == 'carga').toList();
      final List<SessionModel> descargas =
          sessions.where((SessionModel s) => s.tipo.toLowerCase() == 'descarga').toList();

      // Crear las 3 hojas
      _createSessionsSheet(excel, 'Todas las Sesiones', sessions);
      _createSessionsSheet(excel, 'Cargas', cargas);
      _createSessionsSheet(excel, 'Descargas', descargas);

      // Guardar archivo
      final Directory directory = await getTemporaryDirectory();
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final String filePath = '${directory.path}/todas_sesiones_$timestamp.xlsx';
      final File file = File(filePath);

      final List<int>? bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      } else {
        throw Exception('Error al codificar archivo XLSX');
      }

      // XLSX multi-hoja generado: información suprimida
      return filePath;
    } catch (e) {
      debugPrint('Error exportando todas las sesiones a XLSX: $e');
      throw Exception('No se pudo exportar a XLSX: $e');
    }
  }

  /// Exporta TODAS las sesiones a un archivo XLSX con 4 hojas:
  /// - "Sesiones": resumen de todas las sesiones
  /// - "Cargas": solo sesiones tipo CARGA
  /// - "Descargas": solo sesiones tipo DESCARGA
  /// - "Pesadas Detalle": cada pesada como una fila con toda la info de sesión
  Future<String> exportAllSessionsToXlsx() async {
    try {
      // Obtener todas las sesiones
      final List<SessionModel> sessions = await getSessions();

      if (sessions.isEmpty) {
        throw Exception('No hay sesiones para exportar');
      }

      final Excel excel = Excel.createExcel();

      // Eliminar hoja por defecto
      try {
        final String? defaultSheet = excel.getDefaultSheet();
        if (defaultSheet != null) {
          excel.delete(defaultSheet);
        }
      } catch (_) {}

      // Separar sesiones por tipo
      final List<SessionModel> cargas =
          sessions.where((SessionModel s) => s.tipo.toLowerCase() == 'carga').toList();
      final List<SessionModel> descargas =
          sessions.where((SessionModel s) => s.tipo.toLowerCase() == 'descarga').toList();

      // Crear las 4 hojas
      _createSessionsSheet(excel, 'Sesiones', sessions);
      _createSessionsSheet(excel, 'Cargas', cargas);
      _createSessionsSheet(excel, 'Descargas', descargas);
      _createPesadasDetalleSheet(excel, 'Pesadas Detalle', sessions);

      // Guardar archivo
      final Directory directory = await getTemporaryDirectory();
      final DateTime now = DateTime.now();
      final String formatted =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      final String filePath = '${directory.path}/export_completo_$formatted.xlsx';
      final File file = File(filePath);

      final List<int>? bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      } else {
        throw Exception('Error al codificar archivo XLSX');
      }

      // XLSX completo generado: información suprimida
      return filePath;
    } catch (e) {
      debugPrint('Error exportando todas las sesiones a XLSX: $e');
      throw Exception('No se pudo exportar a XLSX: $e');
    }
  }

  /// Helper para crear la hoja de Pesadas Detalle (Ejemplo 3 - Matriz completa)
  void _createPesadasDetalleSheet(
      Excel excel, String sheetName, List<SessionModel> sessions) {
    final Sheet sheet = excel[sheetName];

    // Encabezados
    final List<String> headers = <String>[
      'ID Sesión',
      'Tipo',
      'Patente',
      'Producto',
      'Chofer',
      'Fecha Inicio',
      'Hora Inicio',
      'Nº Pesada',
      'Fecha Pesada',
      'Hora Pesada',
      'Peso (kg)',
      'Nota'
    ];

    for (int col = 0; col < headers.length; col++) {
      Data cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = headers[col];
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#FF9800',
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Datos: cada pesada es una fila con toda la info de sesión repetida
    int currentRow = 1;
    for (final SessionModel session in sessions) {
      final String fechaInicioSesion =
          '${session.fechaInicio.day.toString().padLeft(2, '0')}/${session.fechaInicio.month.toString().padLeft(2, '0')}/${session.fechaInicio.year}';
      final String horaInicioSesion =
          '${session.fechaInicio.hour.toString().padLeft(2, '0')}:${session.fechaInicio.minute.toString().padLeft(2, '0')}:${session.fechaInicio.second.toString().padLeft(2, '0')}';

      for (int i = 0; i < session.pesadas.length; i++) {
        final SessionWeight pesada = session.pesadas[i];

        final String fechaPesada =
            '${pesada.fechaHora.day.toString().padLeft(2, '0')}/${pesada.fechaHora.month.toString().padLeft(2, '0')}/${pesada.fechaHora.year}';
        final String horaPesada =
            '${pesada.fechaHora.hour.toString().padLeft(2, '0')}:${pesada.fechaHora.minute.toString().padLeft(2, '0')}:${pesada.fechaHora.second.toString().padLeft(2, '0')}';

        // Nota: usar nota de sesión (las pesadas no tienen nota individual en el modelo actual)
        final String nota = session.notas ?? '';

        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 0, rowIndex: currentRow))
            .value = session.id;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 1, rowIndex: currentRow))
            .value = session.tipo.toUpperCase();
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 2, rowIndex: currentRow))
            .value = session.patente ?? '';
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 3, rowIndex: currentRow))
            .value = session.producto ?? '';
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 4, rowIndex: currentRow))
            .value = session.chofer ?? '';
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 5, rowIndex: currentRow))
            .value = fechaInicioSesion;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 6, rowIndex: currentRow))
            .value = horaInicioSesion;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 7, rowIndex: currentRow))
            .value = i + 1;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 8, rowIndex: currentRow))
            .value = fechaPesada;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 9, rowIndex: currentRow))
            .value = horaPesada;
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 10, rowIndex: currentRow))
            .value = _formatPeso(pesada.peso);
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: 11, rowIndex: currentRow))
            .value = nota;

        currentRow++;
      }
    }

    // Autoajustar columnas
    try {
      for (int col = 0; col < headers.length; col++) {
        sheet.setColAutoFit(col);
      }
    } catch (_) {
      // Fallback manual
      try {
        for (int col = 0; col < headers.length; col++) {
          sheet.setColWidth(col, 15.0);
        }
      } catch (_) {}
    }
  }

  /// Helper para crear una hoja con el listado de sesiones
  void _createSessionsSheet(
      Excel excel, String sheetName, List<SessionModel> sessions) {
    final Sheet sheet = excel[sheetName];

    // Encabezados
    final List<String> headers = <String>[
      'ID Sesión',
      'Tipo',
      'Patente',
      'Producto',
      'Chofer',
      'Fecha Inicio',
      'Hora Inicio',
      'Peso total',
      'Cantidad pesadas',
      'Notas'
    ];

    for (int col = 0; col < headers.length; col++) {
      Data cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = headers[col];
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: '#2196F3',
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Datos
    for (int i = 0; i < sessions.length; i++) {
      final SessionModel session = sessions[i];
      final int row = i + 1;

      final String fecha =
          '${session.fechaInicio.day.toString().padLeft(2, '0')}/${session.fechaInicio.month.toString().padLeft(2, '0')}/${session.fechaInicio.year}';
      final String hora =
          '${session.fechaInicio.hour.toString().padLeft(2, '0')}:${session.fechaInicio.minute.toString().padLeft(2, '0')}:${session.fechaInicio.second.toString().padLeft(2, '0')}';

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = session.id;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = session.tipo.toUpperCase();
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = session.patente ?? '';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = session.producto ?? '';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = session.chofer ?? '';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = fecha;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = hora;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value = _formatPeso(session.pesoTotal);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value = session.cantidadPesadas;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
          .value = session.notas ?? '';
    }

    // Autoajustar columnas
    try {
      for (int col = 0; col < headers.length; col++) {
        sheet.setColAutoFit(col);
      }
    } catch (_) {
      // Fallback manual
      try {
        for (int col = 0; col < headers.length; col++) {
          sheet.setColWidth(col, 15.0);
        }
      } catch (_) {}
    }
  }

  /// Helper para agregar fila de datos (label + valor)
  void _addDataRow(Sheet sheet, int row, String label, String value,
      {bool bold = false}) {
    Data labelCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    labelCell.value = label;
    labelCell.cellStyle = CellStyle(bold: true);

    Data valueCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    valueCell.value = value;
    if (bold) {
      valueCell.cellStyle = CellStyle(bold: true);
    }
  }

  /// Genera un PDF de una sesión y devuelve la ruta del archivo
  /// 
  /// Este método delega la generación del PDF a [PdfExportService].
  /// 
  /// Parámetros:
  /// - [session]: La sesión a exportar
  /// 
  /// Retorna la ruta completa del archivo PDF generado
  Future<String> exportSessionToPdf(SessionModel session) async {
    return _pdfExportService.exportSessionToPdf(session);
  }

  /// Comparte un archivo PDF usando el sistema de compartir nativo
  /// 
  /// Parámetros:
  /// - [path]: Ruta completa del archivo PDF a compartir
  Future<void> sharePdf(String path) async {
    return _pdfExportService.sharePdf(path);
  }
}
