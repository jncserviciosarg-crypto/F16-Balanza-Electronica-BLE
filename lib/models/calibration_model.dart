class CalibrationModel {
  final double offset;
  final double adcReferencia;
  final double pesoPatron;
  final double factorEscala;

  CalibrationModel({
    required this.offset,
    required this.adcReferencia,
    required this.pesoPatron,
    required this.factorEscala,
  });

  factory CalibrationModel.defaultModel() {
    return CalibrationModel(
      offset: 0.0,
      adcReferencia: 0.0,
      pesoPatron: 0.0,
      factorEscala: 1.0,
    );
  }

  factory CalibrationModel.fromMap(Map<String, dynamic> map) {
    return CalibrationModel(
      offset: (map['offset'] ?? 0.0).toDouble(),
      adcReferencia: (map['adcReferencia'] ?? 0.0).toDouble(),
      pesoPatron: (map['pesoPatron'] ?? 0.0).toDouble(),
      factorEscala: (map['factorEscala'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'offset': offset,
      'adcReferencia': adcReferencia,
      'pesoPatron': pesoPatron,
      'factorEscala': factorEscala,
    };
  }

  CalibrationModel copyWith({
    double? offset,
    double? adcReferencia,
    double? pesoPatron,
    double? factorEscala,
  }) {
    return CalibrationModel(
      offset: offset ?? this.offset,
      adcReferencia: adcReferencia ?? this.adcReferencia,
      pesoPatron: pesoPatron ?? this.pesoPatron,
      factorEscala: factorEscala ?? this.factorEscala,
    );
  }

  // --------- NUEVO: Serialización JSON ---------
  Map<String, dynamic> toJson() => toMap();

  factory CalibrationModel.fromJson(Map<String, dynamic> json) =>
      CalibrationModel.fromMap(json);
}
