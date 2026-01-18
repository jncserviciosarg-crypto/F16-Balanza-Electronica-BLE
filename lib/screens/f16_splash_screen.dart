import 'package:flutter/material.dart';

/// Pantalla Splash que simula la secuencia de autoprueba (Built-In Test)
/// de una computadora de vuelo F-16. Totalmente autocontenida y sin
/// dependencias de navegación o servicios. Opcionalmente recibe un
/// callback `onComplete` que el consumidor puede usar para continuar.
class F16SplashScreen extends StatefulWidget {
  /// Callback opcional que se invoca cuando la secuencia termina.
  final VoidCallback? onComplete;

  /// Duración total por sistema en milisegundos (aparición + prueba)
  final Duration perSystemDuration;

  /// Retardo final antes de llamar `onComplete` y ocultar la pantalla
  final Duration finalHold;

  const F16SplashScreen({
    super.key,
    this.onComplete,
    this.perSystemDuration = const Duration(milliseconds: 900),
    this.finalHold = const Duration(milliseconds: 1200),
  });

  @override
  _F16SplashScreenState createState() => _F16SplashScreenState();
}

enum _StepState { hidden, testing, ready }

class _F16SplashScreenState extends State<F16SplashScreen>
    with SingleTickerProviderStateMixin {
  // Secuencia de sistemas (en mayúsculas según requerimiento)
  static const List<String> _systems = <String>[
    'SENSOR DE CARGA',
    'COMUNICACIÓN SERIE',
    'CONFIGURACIÓN DE ESCALA',
    'PARÁMETROS DE FILTRO',
    'BASE DE DATOS',
    'VERIFICACIONES FINALES',
  ];

  late List<_StepState> _states;
  bool _showSystemOperating = false;

  @override
  void initState() {
    super.initState();
    _states = List.generate(_systems.length, (_) => _StepState.hidden);
    // Lanzar la secuencia una vez que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startSequence() async {
    final int totalMs = widget.perSystemDuration.inMilliseconds;
    // Dividir la duración en dos fases: testing + transición a ready
    final int testingMs = (totalMs * 0.65).round();
    final int afterMs = totalMs - testingMs;

    for (int i = 0; i < _systems.length; i++) {
      if (!mounted) return;
      setState(() {
        _states[i] = _StepState.testing;
      });

      // Tiempo en estado "EN PRUEBA"
      await Future.delayed(Duration(milliseconds: testingMs));
      if (!mounted) return;

      setState(() {
        _states[i] = _StepState.ready;
      });

      // Pequeña pausa antes del siguiente sistema
      await Future.delayed(Duration(milliseconds: afterMs));
    }

    // Mostrar el mensaje final "SISTEMA OPERATIVO"
    if (!mounted) return;
    setState(() => _showSystemOperating = true);

    // Mantenerlo visible un tiempo y luego terminar
    await Future.delayed(widget.finalHold);
    if (!mounted) return;

    // No realizamos navegación aquí — solo notificamos mediante callback
    widget.onComplete?.call();
  }

  Widget _buildRow(int index, BoxConstraints constraints) {
    final _StepState state = _states[index];
    final String label = _systems[index];

    // Estilos comunes
    const double letterSpacing = 2.6;
    const double borderRadius = 5.0;

    // Color de texto y de estado
    final Color green = Colors.green[700]!;
    final Color white = Colors.white;
    final Color darkPanel = Colors.grey[900]!;

    // Estado visual
    Widget statusWidget;
    if (state == _StepState.hidden) {
      // No mostramos nada (animamos con altura 0)
      statusWidget = const SizedBox.shrink();
      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: SizedBox(height: 0, child: statusWidget),
      );
    } else if (state == _StepState.testing) {
      // EN PRUEBA: texto verde y punto pulsante
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              'EN PRUEBA',
              style: TextStyle(
                color: green,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                letterSpacing: 2.6,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Punto pulsante
          _PulsingDot(color: green),
        ],
      );
    } else {
      // READY / LISTO
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check, color: green, size: 18),
          const SizedBox(width: 8),
          Text(
            'LISTO',
            style: TextStyle(
              color: green,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              letterSpacing: 2.6,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Container(
        key: ValueKey<int>(
            index + (_states[index] == _StepState.hidden ? 0 : 100)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: darkPanel,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.green[700]!, width: 1.2),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: white,
                  fontFamily: 'Courier',
                  fontSize: 14,
                  letterSpacing: letterSpacing,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            statusWidget,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color green = Colors.green[700]!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            final double maxWidth = constraints.maxWidth.clamp(300.0, 900.0);
            return ConstrainedBox(
              constraints: BoxConstraints(minWidth: 300, maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Ventana principal con borde verde
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: green, width: 2.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Cabecera mínima tipo HUD
                        Row(
                          children: <Widget>[
                            const Text(
                              'AUTOPRUEBA',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Courier',
                                fontSize: 18,
                                letterSpacing: 3.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'F-16 BIT',
                                style: TextStyle(
                                  color: green,
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  letterSpacing: 3.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Reloj simple/contador (no funcional) - solo visual
                            Text(
                              _timestampLabel(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'Courier',
                                fontSize: 11,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Panel gris oscuro con lista
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: List.generate(_systems.length,
                                (int i) => _buildRow(i, constraints)),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Indicador inferior
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'ESTADO: ${_showSystemOperating ? 'SISTEMA OPERATIVO' : 'INICIALIZANDO...'}',
                                style: TextStyle(
                                  color: _showSystemOperating
                                      ? green
                                      : Colors.white,
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_showSystemOperating)
                              AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 400),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(color: green),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'SISTEMA OPERATIVO',
                                    style: TextStyle(
                                      color: green,
                                      fontFamily: 'Courier',
                                      fontSize: 13,
                                      letterSpacing: 3.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  String _timestampLabel() {
    final DateTime now = DateTime.now();
    final String h = now.hour.toString().padLeft(2, '0');
    final String m = now.minute.toString().padLeft(2, '0');
    final String s = now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// Pequeño punto pulsante usado para indicar "EN PRUEBA"
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  __PulsingDotState createState() => __PulsingDotState();
}

class __PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutQuad));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
