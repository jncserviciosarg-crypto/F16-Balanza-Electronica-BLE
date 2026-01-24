/// Utilidades de formateo de peso según división mínima
/// 
/// Este helper centraliza la lógica de formateo de peso que antes estaba
/// duplicada en múltiples archivos (weight_display, session_weight_row,
/// history_screen, session_history_service).
library;

/// Calcula el número de decimales necesarios según la división mínima
/// 
/// Retorna 0 decimales si la división es >= 1
/// Para divisiones < 1, calcula dinámicamente los decimales necesarios
/// eliminando ceros a la derecha.
/// 
/// Ejemplos:
/// - division = 1.0 → retorna 0
/// - division = 0.1 → retorna 1
/// - division = 0.01 → retorna 2
/// - division = 0.001 → retorna 3
int decimalsFromDivision(double division) {
  if (division >= 1) return 0;
  
  // Representar con precisión y eliminar ceros a la derecha
  String s = division.toStringAsFixed(6); // hasta 6 decimales
  if (!s.contains('.')) return 0;
  
  String frac = s.split('.')[1];
  frac = frac.replaceAll(RegExp(r'0+$'), '');
  return frac.length;
}

/// Formatea un valor de peso según la división mínima especificada
/// 
/// El número de decimales se calcula dinámicamente usando [decimalsFromDivision].
/// 
/// Parámetros:
/// - [value]: Valor del peso a formatear
/// - [divisionMinima]: División mínima de la celda de carga
/// 
/// Retorna el peso formateado como String con los decimales apropiados.
/// 
/// Ejemplos:
/// - formatWeight(123.456, 1.0) → "123"
/// - formatWeight(123.456, 0.01) → "123.46"
/// - formatWeight(123.456, 0.001) → "123.456"
String formatWeight(double value, double divisionMinima) {
  int decimals = decimalsFromDivision(divisionMinima);
  return value.toStringAsFixed(decimals);
}
