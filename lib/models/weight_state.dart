class WeightState {
  final int adcRaw;
  final double? adcFiltered;
  final double peso;
  final bool estable;
  final bool overload;

  WeightState({
    required this.adcRaw,
    this.adcFiltered,
    required this.peso,
    required this.estable,
    this.overload = false,
  });

  factory WeightState.initial() {
    return WeightState(
      adcRaw: 0,
      adcFiltered: 0.0,
      peso: 0.0,
      estable: false,
      overload: false,
    );
  }

  WeightState copyWith({
    int? adcRaw,
    double? adcFiltered,
    double? peso,
    bool? estable,
    bool? overload,
  }) {
    return WeightState(
      adcRaw: adcRaw ?? this.adcRaw,
      adcFiltered: adcFiltered ?? this.adcFiltered,
      peso: peso ?? this.peso,
      estable: estable ?? this.estable,
      overload: overload ?? this.overload,
    );
  }
}
