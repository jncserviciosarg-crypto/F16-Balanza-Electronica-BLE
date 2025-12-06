import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/load_cell_config.dart';
import '../models/calibration_model.dart';
import '../models/filter_params.dart';

class PersistenceService {
  static final PersistenceService _instance = PersistenceService._internal();
  factory PersistenceService() => _instance;
  PersistenceService._internal();

  static const String _keyLoadCellConfig = 'load_cell_config';
  static const String _keyCalibration = 'calibration_model';
  static const String _keyFilterParams = 'filter_params';
  static const String _keyFactoryCalibration = 'factory_calibration_json';

  Future<void> saveConfig(LoadCellConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(config.toMap());
      await prefs.setString(_keyLoadCellConfig, jsonString);
    } catch (e) {
      debugPrint('Error guardando configuración: $e');
    }
  }

  Future<LoadCellConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyLoadCellConfig);

      if (jsonString != null) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return LoadCellConfig.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error cargando configuración: $e');
    }

    return LoadCellConfig.defaultConfig();
  }

  Future<void> saveCalibration(CalibrationModel calibration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(calibration.toMap());
      await prefs.setString(_keyCalibration, jsonString);
    } catch (e) {
      debugPrint('Error guardando calibración: $e');
    }
  }

  Future<CalibrationModel> loadCalibration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCalibration);

      if (jsonString != null) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return CalibrationModel.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error cargando calibración: $e');
    }

    return CalibrationModel.defaultModel();
  }

  Future<void> saveFilters(FilterParams filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(filters.toMap());
      await prefs.setString(_keyFilterParams, jsonString);
    } catch (e) {
      debugPrint('Error guardando filtros: $e');
    }
  }

  Future<FilterParams> loadFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFilterParams);

      if (jsonString != null) {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        return FilterParams.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error cargando filtros: $e');
    }

    return FilterParams.defaultParams();
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLoadCellConfig);
      await prefs.remove(_keyCalibration);
      await prefs.remove(_keyFilterParams);
    } catch (e) {
      debugPrint('Error limpiando datos: $e');
    }
  }

  // --------- NUEVO: Calibración de fábrica ---------
  Future<void> saveFactoryCalibration(CalibrationModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(model.toJson());
      await prefs.setString(_keyFactoryCalibration, jsonString);
    } catch (e) {
      debugPrint('Error guardando calibración de fábrica: $e');
    }
  }

  Future<CalibrationModel?> loadFactoryCalibration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFactoryCalibration);
      if (jsonString == null) return null;
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return CalibrationModel.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error cargando calibración de fábrica: $e');
      return null;
    }
  }

  // --------- NUEVO: Persistencia de sesiones (namespace separado) ---------
  static const String _keySessionsPrefix = 'sessions_v1_';
  static const String _keySessionsList = 'sessions_v1_list';

  /// Guarda una sesión en SharedPreferences
  Future<void> saveSessionJson(
      String id, Map<String, dynamic> sessionMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(sessionMap);
      await prefs.setString('$_keySessionsPrefix$id', jsonString);

      // Actualizar lista de IDs de sesiones
      List<String> sessionIds = await _loadSessionIdsList();
      if (!sessionIds.contains(id)) {
        sessionIds.add(id);
        await prefs.setString(_keySessionsList, jsonEncode(sessionIds));
      }
    } catch (e) {
      debugPrint('Error guardando sesión: $e');
    }
  }

  /// Carga todas las sesiones guardadas
  Future<List<Map<String, dynamic>>> loadAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> sessionIds = await _loadSessionIdsList();
      List<Map<String, dynamic>> sessions = [];

      for (String id in sessionIds) {
        final jsonString = prefs.getString('$_keySessionsPrefix$id');
        if (jsonString != null) {
          sessions.add(jsonDecode(jsonString) as Map<String, dynamic>);
        }
      }

      return sessions;
    } catch (e) {
      debugPrint('Error cargando sesiones: $e');
      return [];
    }
  }

  /// Elimina una sesión por ID
  Future<void> removeSession(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keySessionsPrefix$id');

      // Actualizar lista de IDs
      List<String> sessionIds = await _loadSessionIdsList();
      sessionIds.remove(id);
      await prefs.setString(_keySessionsList, jsonEncode(sessionIds));
    } catch (e) {
      debugPrint('Error eliminando sesión: $e');
    }
  }

  /// Carga la lista de IDs de sesiones
  Future<List<String>> _loadSessionIdsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keySessionsList);
      if (jsonString != null) {
        return List<String>.from(jsonDecode(jsonString));
      }
    } catch (e) {
      debugPrint('Error cargando lista de sesiones: $e');
    }
    return [];
  }

  /// Genera CSV a partir de una sesión (devuelve String)
  String exportSessionCsv(Map<String, dynamic> sessionMap) {
    try {
      StringBuffer csv = StringBuffer();

      // Encabezados
      csv.writeln(
          'Fecha,Hora,Tipo,PesoBruto(kg),PesoNeto(kg),Tara(kg),Patente,Producto,Nota');

      // Datos de pesadas
      final pesadas = sessionMap['pesadas'] as List<dynamic>? ?? [];
      for (var pesada in pesadas) {
        final timestamp = DateTime.parse(
            pesada['timestamp'] ?? DateTime.now().toIso8601String());
        final fecha =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        final hora =
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
        final tipo = pesada['tipo'] ?? '';
        final pesoBruto = pesada['pesoBruto'] ?? 0.0;
        final pesoNeto = pesada['pesoNeto'] ?? 0.0;
        final tara = pesada['tara'] ?? 0.0;
        final patente = sessionMap['patente'] ?? '';
        final producto = sessionMap['producto'] ?? '';
        final nota = sessionMap['nota'] ?? '';

        csv.writeln(
            '$fecha,$hora,$tipo,$pesoBruto,$pesoNeto,$tara,$patente,$producto,$nota');
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Error generando CSV: $e');
      return '';
    }
  }
}
