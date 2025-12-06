import 'package:flutter/material.dart';
import 'dart:math' as math;

class WeightDisplay extends StatefulWidget {
  final double peso;
  final bool estable;
  final int adc;
  final double tara;
  final double divisionMinima;
  final bool overload;
  final String unidad; // NUEVO: unidad visual

  const WeightDisplay({
    Key? key,
    required this.peso,
    required this.estable,
    required this.adc,
    required this.tara,
    required this.divisionMinima,
    this.overload = false,
    required this.unidad, // NUEVO: requerido
  }) : super(key: key);

  @override
  State<WeightDisplay> createState() => _WeightDisplayState();
}

class _WeightDisplayState extends State<WeightDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _fadeAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _decimalsFromDivision(double division) {
    if (division <= 0) return 2;
    if (division >= 1) return 0;
    const int maxDecimals = 6;
    double eps = 1e-9;
    for (int d = 0; d <= maxDecimals; d++) {
      double scaled = division * math.pow(10, d + 1);
      if ((scaled - scaled.round()).abs() < eps) {
        return d + 1;
      }
    }
    return maxDecimals;
  }

  @override
  Widget build(BuildContext context) {
    final decimals = _decimalsFromDivision(widget.divisionMinima);

    final displayPeso = decimals == 0
        ? widget.peso.round().toString()
        : widget.peso.toStringAsFixed(decimals);
    final displayTara = decimals == 0
        ? widget.tara.round().toString()
        : widget.tara.toStringAsFixed(decimals);

    final bool overload = widget.overload;

    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        final borderColor = overload
            ? Colors.red.withOpacity(_fadeAnim.value)
            : (widget.estable ? Colors.green : Colors.grey);
        final boxShadowColor = overload
            ? Colors.red.withOpacity(0.3 * _fadeAnim.value)
            : (widget.estable
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2));
        final bgColor =
            overload ? Colors.black.withOpacity(0.95) : Colors.black87;

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: 6,
            ),
            boxShadow: [
              BoxShadow(
                color: boxShadowColor,
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display principal (peso grande)
              Expanded(
                child: Center(
                  child: Text(
                    overload ? 'EEEE' : displayPeso,
                    style: TextStyle(
                      fontSize: 165,
                      fontWeight: FontWeight.bold,
                      color: overload
                          ? Colors.redAccent
                          : (widget.estable
                              ? Colors.greenAccent
                              : Colors.white),
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),
              // Panel lateral compacto (unidad, indicador y ADC/Tara)
              Column(
                //crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Unidad en extremo (kg / g / lb)
                  Text(
                    widget.unidad, // NUEVO: unidad visual
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: overload
                          ? Colors.redAccent
                          : (widget.estable
                              ? Colors.greenAccent
                              : Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Indicador visual (ESTABLE / PROCESANDO)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: overload
                          ? Colors.red.withOpacity(0.2 * _fadeAnim.value)
                          : (widget.estable
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: overload
                            ? Colors.red
                            : (widget.estable ? Colors.green : Colors.grey),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          overload
                              ? Icons.warning_amber_rounded
                              : (widget.estable
                                  ? Icons.check_circle
                                  : Icons.sync),
                          color: overload
                              ? Colors.redAccent
                              : (widget.estable
                                  ? Colors.greenAccent
                                  : Colors.grey),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          overload
                              ? 'SOBRECARGA'
                              : (widget.estable ? 'ESTABLE' : 'PROCESANDO'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: overload
                                ? Colors.redAccent
                                : (widget.estable
                                    ? Colors.greenAccent
                                    : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
/*                  const SizedBox(height: 16),
                  // ADC (visual)
                  Text(
                    'ADC',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.cyanAccent.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.adc.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),*/
                  const SizedBox(height: 6),
                  // TARA (visual)
                  Text(
                    'TARA',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.green[700]!.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayTara,
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.green[700]!,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
