class FilterParams {
  final int muestras;
  final int ventana;
  final double emaAlpha;
  final int updateIntervalMs;
  final double limiteSuperior;
  final double limiteInferior;

  FilterParams({
    required this.muestras,
    required this.ventana,
    required this.emaAlpha,
    required this.updateIntervalMs,
    required this.limiteSuperior,
    required this.limiteInferior,
  });

  factory FilterParams.defaultParams() {
    return FilterParams(
      muestras: 10,
      ventana: 5,
      emaAlpha: 0.3,
      updateIntervalMs: 100,
      limiteSuperior: 1000000.0,
      limiteInferior: -1000000.0,
    );
  }

  factory FilterParams.fromMap(Map<String, dynamic> map) {
    return FilterParams(
      muestras: map['muestras'] ?? 10,
      ventana: map['ventana'] ?? 5,
      emaAlpha: (map['emaAlpha'] ?? 0.3).toDouble(),
      updateIntervalMs: map['updateIntervalMs'] ?? 100,
      limiteSuperior: (map['limiteSuperior'] ?? 1000000.0).toDouble(),
      limiteInferior: (map['limiteInferior'] ?? -1000000.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'muestras': muestras,
      'ventana': ventana,
      'emaAlpha': emaAlpha,
      'updateIntervalMs': updateIntervalMs,
      'limiteSuperior': limiteSuperior,
      'limiteInferior': limiteInferior,
    };
  }

  FilterParams copyWith({
    int? muestras,
    int? ventana,
    double? emaAlpha,
    int? updateIntervalMs,
    double? limiteSuperior,
    double? limiteInferior,
  }) {
    return FilterParams(
      muestras: muestras ?? this.muestras,
      ventana: ventana ?? this.ventana,
      emaAlpha: emaAlpha ?? this.emaAlpha,
      updateIntervalMs: updateIntervalMs ?? this.updateIntervalMs,
      limiteSuperior: limiteSuperior ?? this.limiteSuperior,
      limiteInferior: limiteInferior ?? this.limiteInferior,
    );
  }
}
