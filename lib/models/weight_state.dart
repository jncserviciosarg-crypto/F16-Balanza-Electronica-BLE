class WeightState {
  final int adcRaw;
  final double? adcFiltered;
  final double peso;
  final bool estable;
  final bool overload;
  final bool adcActive; // Bug #3: Propiedad para detectar timeout ADC

  WeightState({
    required this.adcRaw,
    this.adcFiltered,
    required this.peso,
    required this.estable,
    this.overload = false,
    this.adcActive = true, // Por defecto activo
  });

  factory WeightState.initial() {
    return WeightState(
      adcRaw: 0,
      adcFiltered: 0.0,
      peso: 0.0,
      estable: false,
      overload: false,
      adcActive: true,
    );
  }

  WeightState copyWith({
    int? adcRaw,
    double? adcFiltered,
    double? peso,
    bool? estable,
    bool? overload,
    bool? adcActive,
  }) {
    return WeightState(
      adcRaw: adcRaw ?? this.adcRaw,
      adcFiltered: adcFiltered ?? this.adcFiltered,
      peso: peso ?? this.peso,
      estable: estable ?? this.estable,
      overload: overload ?? this.overload,
      adcActive: adcActive ?? this.adcActive,
    );
  }
}
