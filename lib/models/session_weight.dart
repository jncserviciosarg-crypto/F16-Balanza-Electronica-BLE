import 'dart:convert';

/// Modelo para una pesada individual dentro de una sesión
class SessionWeight {
  final String id;
  final double peso;
  final DateTime fechaHora;

  SessionWeight({
    required this.id,
    required this.peso,
    required this.fechaHora,
  });

  /// Crea una nueva pesada con ID automático
  factory SessionWeight.create({
    required double peso,
  }) {
    return SessionWeight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peso: peso,
      fechaHora: DateTime.now(),
    );
  }

  /// Crea una copia con campos modificados
  SessionWeight copyWith({
    String? id,
    double? peso,
    DateTime? fechaHora,
  }) {
    return SessionWeight(
      id: id ?? this.id,
      peso: peso ?? this.peso,
      fechaHora: fechaHora ?? this.fechaHora,
    );
  }

  /// Convierte la pesada a un mapa JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peso': peso,
      'fechaHora': fechaHora.toIso8601String(),
    };
  }

  /// Crea una pesada desde un mapa JSON
  factory SessionWeight.fromMap(Map<String, dynamic> map) {
    return SessionWeight(
      id: map['id'] ?? '',
      peso: (map['peso'] ?? 0.0).toDouble(),
      fechaHora:
          DateTime.parse(map['fechaHora'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convierte la pesada a JSON string
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Crea una pesada desde JSON string
  factory SessionWeight.fromJson(String source) {
    return SessionWeight.fromMap(jsonDecode(source));
  }

  @override
  String toString() {
    return 'SessionWeight(id: $id, peso: $peso, fechaHora: $fechaHora)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SessionWeight &&
        other.id == id &&
        other.peso == peso &&
        other.fechaHora == fechaHora;
  }

  @override
  int get hashCode {
    return id.hashCode ^ peso.hashCode ^ fechaHora.hashCode;
  }
}
