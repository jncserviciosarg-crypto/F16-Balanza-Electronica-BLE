class LoadCellConfig {
  final double capacidadKg;
  final double sensibilidadMvV;
  final double voltajeExcitacion;
  final double gananciaHX711;
  final double voltajeReferencia;
  final double divisionMinima;
  final String unidad;
  final double factorCorreccion; // NUEVO

  LoadCellConfig({
    required this.capacidadKg,
    required this.sensibilidadMvV,
    required this.voltajeExcitacion,
    required this.gananciaHX711,
    required this.voltajeReferencia,
    required this.divisionMinima,
    required this.unidad,
    this.factorCorreccion = 0.0, // NUEVO: default 0.0
  });

  factory LoadCellConfig.defaultConfig() {
    return LoadCellConfig(
      capacidadKg: 20000.0,
      sensibilidadMvV: 2.0,
      voltajeExcitacion: 5.0,
      gananciaHX711: 128.0,
      voltajeReferencia: 3.3,
      divisionMinima: 10.0,
      unidad: 'kg',
      factorCorreccion: 0.0, // NUEVO
    );
  }

  factory LoadCellConfig.fromMap(Map<String, dynamic> map) {
    return LoadCellConfig(
      capacidadKg: (map['capacidadKg'] ?? 200.0).toDouble(),
      sensibilidadMvV: (map['sensibilidadMvV'] ?? 2.0).toDouble(),
      voltajeExcitacion: (map['voltajeExcitacion'] ?? 5.0).toDouble(),
      gananciaHX711: (map['gananciaHX711'] ?? 128.0).toDouble(),
      voltajeReferencia: (map['voltajeReferencia'] ?? 3.3).toDouble(),
      divisionMinima: (map['divisionMinima'] ?? 0.01).toDouble(),
      unidad: map['unidad'] ?? 'kg',
      factorCorreccion: (map['factorCorreccion'] ?? 0.0).toDouble(), // NUEVO
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'capacidadKg': capacidadKg,
      'sensibilidadMvV': sensibilidadMvV,
      'voltajeExcitacion': voltajeExcitacion,
      'gananciaHX711': gananciaHX711,
      'voltajeReferencia': voltajeReferencia,
      'divisionMinima': divisionMinima,
      'unidad': unidad,
      'factorCorreccion': factorCorreccion, // NUEVO
    };
  }

  LoadCellConfig copyWith({
    double? capacidadKg,
    double? sensibilidadMvV,
    double? voltajeExcitacion,
    double? gananciaHX711,
    double? voltajeReferencia,
    double? divisionMinima,
    String? unidad,
    double? factorCorreccion, // NUEVO
  }) {
    return LoadCellConfig(
      capacidadKg: capacidadKg ?? this.capacidadKg,
      sensibilidadMvV: sensibilidadMvV ?? this.sensibilidadMvV,
      voltajeExcitacion: voltajeExcitacion ?? this.voltajeExcitacion,
      gananciaHX711: gananciaHX711 ?? this.gananciaHX711,
      voltajeReferencia: voltajeReferencia ?? this.voltajeReferencia,
      divisionMinima: divisionMinima ?? this.divisionMinima,
      unidad: unidad ?? this.unidad,
      factorCorreccion: factorCorreccion ?? this.factorCorreccion, // NUEVO
    );
  }
}
