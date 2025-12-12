import 'dart:convert';
import 'package:intl/intl.dart';
import 'session_weight.dart';

/// Modelo para una sesión completa de pesaje (Carga o Descarga)
class SessionModel {
  /// ID de la sesión.
  /// Para sesiones nuevas finalizadas: formato yyyyMMddHHmmss_pesoTotalRedondeado (ej: 20251123232524_29870)
  /// Para sesiones antiguas: se mantiene el ID original basado en timestamp milliseconds
  final String id;
  final String tipo; // 'carga' o 'descarga'
  final DateTime fechaInicio;
  final DateTime? fechaFin;

  // Datos opcionales
  final String? patente;
  final String? producto;
  final String? chofer;
  final String? notas;

  // Lista de pesadas
  final List<SessionWeight> pesadas;

  // Pesos calculados
  final double pesoInicial;
  final double pesoFinal;

  SessionModel({
    required this.id,
    required this.tipo,
    required this.fechaInicio,
    this.fechaFin,
    this.patente,
    this.producto,
    this.chofer,
    this.notas,
    required this.pesadas,
    required this.pesoInicial,
    required this.pesoFinal,
  }) {
    if (!<String>['carga', 'descarga'].contains(tipo)) {
      throw ArgumentError('Tipo de sesión debe ser: carga o descarga');
    }
  }

  /// Calcula el peso total de todas las pesadas
  double get pesoTotal {
    return pesadas.fold(0.0, (double sum, SessionWeight pesada) => sum + pesada.peso);
  }

  /// Calcula el peso neto (diferencia entre peso final e inicial)
  double get pesoNeto {
    return pesoFinal - pesoInicial;
  }

  /// Indica si la sesión está finalizada
  bool get estaFinalizada => fechaFin != null;

  /// Cantidad de pesadas en la sesión
  int get cantidadPesadas => pesadas.length;

  /// Genera un ID determinista para sesión finalizada: yyyyMMddHHmmss_pesoRedondeado
  ///
  /// Parámetros:
  /// - [endDateTime]: Fecha y hora de finalización de la sesión
  /// - [totalWeight]: Peso total de la sesión (se redondea al entero más cercano)
  ///
  /// Ejemplo: 20251123232524_29870
  static String generateSessionId(DateTime endDateTime, double totalWeight) {
    final String timestamp = DateFormat('yyyyMMddHHmmss').format(endDateTime);
    final int weightRounded = totalWeight.round();
    return '${timestamp}_$weightRounded';
  }

  /// Crea una nueva sesión
  factory SessionModel.create({
    required String tipo,
    String? patente,
    String? producto,
    String? chofer,
    String? notas,
    double pesoInicial = 0.0,
  }) {
    return SessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: tipo,
      fechaInicio: DateTime.now(),
      fechaFin: null,
      patente: patente,
      producto: producto,
      chofer: chofer,
      notas: notas,
      pesadas: <SessionWeight>[],
      pesoInicial: pesoInicial,
      pesoFinal: 0.0,
    );
  }

  /// Crea una copia de la sesión con campos modificados
  SessionModel copyWith({
    String? id,
    String? tipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? patente,
    String? producto,
    String? chofer,
    String? notas,
    List<SessionWeight>? pesadas,
    double? pesoInicial,
    double? pesoFinal,
  }) {
    return SessionModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      patente: patente ?? this.patente,
      producto: producto ?? this.producto,
      chofer: chofer ?? this.chofer,
      notas: notas ?? this.notas,
      pesadas: pesadas ?? this.pesadas,
      pesoInicial: pesoInicial ?? this.pesoInicial,
      pesoFinal: pesoFinal ?? this.pesoFinal,
    );
  }

  /// Convierte la sesión a un mapa JSON
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'tipo': tipo,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'patente': patente,
      'producto': producto,
      'chofer': chofer,
      'notas': notas,
      'pesadas': pesadas.map((SessionWeight p) => p.toMap()).toList(),
      'pesoInicial': pesoInicial,
      'pesoFinal': pesoFinal,
    };
  }

  /// Crea una sesión desde un mapa JSON
  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? '',
      tipo: map['tipo'] ?? 'carga',
      fechaInicio: DateTime.parse(
          map['fechaInicio'] ?? DateTime.now().toIso8601String()),
      fechaFin:
          map['fechaFin'] != null ? DateTime.parse(map['fechaFin']) : null,
      patente: map['patente'],
      producto: map['producto'],
      chofer: map['chofer'],
      notas: map['notas'],
      pesadas: (map['pesadas'] as List<dynamic>?)
              ?.map((p) => SessionWeight.fromMap(p as Map<String, dynamic>))
              .toList() ??
          <SessionWeight>[],
      pesoInicial: (map['pesoInicial'] ?? 0.0).toDouble(),
      pesoFinal: (map['pesoFinal'] ?? 0.0).toDouble(),
    );
  }

  /// Convierte la sesión a JSON string
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Crea una sesión desde JSON string
  factory SessionModel.fromJson(String source) {
    return SessionModel.fromMap(jsonDecode(source));
  }

  @override
  String toString() {
    return 'SessionModel(id: $id, tipo: $tipo, pesadas: ${pesadas.length}, pesoTotal: $pesoTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SessionModel &&
        other.id == id &&
        other.tipo == tipo &&
        other.fechaInicio == fechaInicio &&
        other.fechaFin == fechaFin;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tipo.hashCode ^
        fechaInicio.hashCode ^
        fechaFin.hashCode;
  }
}
