// lib/screens/home_screen.dart
import 'dart:typed_data';

import 'package:f16_balanza_electronica/models/load_cell_config.dart';
import 'package:f16_balanza_electronica/models/weight_state.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/weight_service.dart';
import '../services/bluetooth_service.dart';
// Eliminados imports legacy (HistoryService, WeightRecord) al migrar totalmente a sesiones industriales
import '../widgets/weight_display.dart';
import '../utils/screenshot_helper.dart';
import 'bluetooth_screen.dart';
import 'calibration_screen.dart';
import 'config_screen.dart';
import 'package:f16_balanza_electronica/screens/history_screen.dart';
import 'session_pro_screen.dart'; // <- nueva importación para sesiones pro
import '../mixins/weight_stream_mixin.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WeightStreamMixin<HomeScreen> {
  final WeightService _weightService = WeightService();
  StreamSubscription?
      _weightSubscription; // Subscription local para peso, diferente al del mixin
  StreamSubscription? _configSubscription;

  // GlobalKey para captura de screenshot
  final GlobalKey<State<StatefulWidget>> _screenshotKey = GlobalKey();

  double _peso = 0.0;
  double _tara = 0.0;
  double _divisionMinima = 0.01;
  String _unidad = 'kg';

  // --- Indicador de estabilidad UI ---
  double? _lastPeso;
  DateTime? _lastStableTime;
  bool _uiEstable = false;
  static const int _stableDelayMs =
      600; // ms que debe estar quieto para ser estable

  bool _overload = false;
  // Timer para pulsación larga del botón TARA
  Timer? _taraResetTimer;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _weightService.initialize();
    _weightService.start();

    _tara = _weightService.tareKg;
    _divisionMinima = _weightServiceDivisionFallback(_weightService);
    _unidad = _weightService.loadCellConfig.unidad;

    _weightSubscription =
        _weightService.weightStateStream.listen((WeightState state) {
      if (mounted) {
        setState(() {
          _peso = state.peso;
          adcRaw = state.adcRaw;

          final DateTime now = DateTime.now();
          if (_lastPeso == null || (_peso - _lastPeso!).abs() > 0.001) {
            _uiEstable = false;
            _lastStableTime = now;
          } else {
            if (_lastStableTime != null &&
                now.difference(_lastStableTime!).inMilliseconds >=
                    _stableDelayMs) {
              _uiEstable = true;
            }
          }
          _lastPeso = _peso;

          _overload = state.overload;
        });
      }
    });
    _configSubscription =
        _weightService.configStream.listen((LoadCellConfig config) {
      if (mounted) {
        setState(() {
          _divisionMinima = config.divisionMinima;
          _unidad = config.unidad;
        });
      }
    });
  }

  // pequeña función helper para evitar crash si loadCellConfig aún no cargó (defensiva)
  double _weightServiceDivisionFallback(WeightService svc) {
    try {
      return svc.divisionMinima;
    } catch (_) {
      return 0.01;
    }
  }

  @override
  void dispose() {
    _weightService.stop();
    _weightSubscription?.cancel();
    _configSubscription?.cancel();
    super.dispose();
  }

  void _handleTara() {
    _weightService.takeTareNow();
    setState(() {
      _tara = _weightService.tareKg;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tara aplicada'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _handleResetTara() {
    _weightService.setTareKg(0.0);
    setState(() {
      _tara = _weightService.tareKg;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tara reseteada'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _startTaraResetCountdown() {
    _taraResetTimer?.cancel();
    _taraResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _handleResetTara();
      }
    });
  }

  void _cancelTaraResetCountdown() {
    _taraResetTimer?.cancel();
    _taraResetTimer = null;
  }

  void _handleCero() {
    _weightService.setZeroOffset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cero operativo aplicado'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ------------------------------------------------------------
  // NUEVO: Navegación a SessionProScreen (mantengo handlers antiguos comentados)
  // ------------------------------------------------------------
  void _handleCarga() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            SessionProScreen(tipo: 'carga', pesoActual: _peso),
      ),
    );
  }

  void _handleDescarga() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) =>
            SessionProScreen(tipo: 'descarga', pesoActual: _peso),
      ),
    );
  }

  // Eliminada lógica clásica de acumulación (historial simple) al usar solo sesiones industriales

  // ═══════════════════════════════════════════════════════════════════
  // REFACTORIZACIÓN UI: Responsive + Tema F-16 Minimalista
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _screenshotKey,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            // Nuevo: responsive layout
            builder: (BuildContext context, BoxConstraints constraints) {
              final double screenWidth = constraints.maxWidth;
              final bool isMobile = screenWidth < 600;
              final bool isTablet = screenWidth >= 600 && screenWidth < 900;

              return Stack(
                children: <Widget>[
                  Container(
                    color: Colors.grey[850], // F-16: gris metálico oscuro
                    padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                    child: Column(
                      children: <Widget>[
                        // Display de peso (mantiene lógica intacta)
                        Flexible(
                          flex: 6,
                          child: Center(
                            child: WeightDisplay(
                              peso: _peso,
                              estable: _uiEstable,
                              adc: adcRaw,
                              tara: _tara,
                              divisionMinima: _divisionMinima,
                              overload: _overload,
                              unidad: _unidad,
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 4 : 8),

                        // Botones de acción - responsive
                        Flexible(
                          flex: isMobile ? 2 : 1,
                          child: _buildResponsiveButtons(
                              context, isMobile, isTablet),
                        ),
                      ],
                    ),
                  ),
                  // ETAPA F2.2: Indicador de estado Bluetooth en esquina superior derecha
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildBluetoothStatusIndicator(),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final Uint8List? bytes =
                await ScreenshotHelper.captureWidget(_screenshotKey);
            if (bytes != null) {
              await ScreenshotHelper.sharePng(bytes,
                  filenamePrefix: 'home_screen');
            } else {
              if (!mounted) return;
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al capturar pantalla'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          backgroundColor: Colors.grey[800],
          child: const Icon(
            Icons.camera_alt,
            color: Color.fromARGB(160, 145, 117, 117),
            size: 30,
          ),
        ),
      ),
    );
  }

  /// ETAPA F2.2: Indicador visual reactivo de estado Bluetooth
  Widget _buildBluetoothStatusIndicator() {
    return ValueListenableBuilder<BluetoothStatus>(
      valueListenable: _weightService.bluetoothStatusNotifier,
      builder: (BuildContext context, BluetoothStatus status, Widget? child) {
        IconData icon;
        Color color;
        String tooltip;

        switch (status) {
          case BluetoothStatus.connected:
            icon = Icons.bluetooth_connected;
            color = Colors.green;
            tooltip = 'Bluetooth: Conectado';
            break;
          case BluetoothStatus.connecting:
            icon = Icons.bluetooth_searching;
            color = Colors.orange;
            tooltip = 'Bluetooth: Conectando...';
            break;
          case BluetoothStatus.error:
            icon = Icons.bluetooth_disabled;
            color = Colors.red;
            tooltip = 'Bluetooth: Error de conexión';
            break;
          case BluetoothStatus.disconnected:
            icon = Icons.bluetooth_disabled;
            color = Colors.grey;
            tooltip = 'Bluetooth: Desconectado';
        }

        return Tooltip(
          message: tooltip,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[850]!.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveButtons(
      BuildContext context, bool isMobile, bool isTablet) {
    final List<Widget> buttons = <Widget>[
      _buildTaraButton(isMobile, isTablet),
      _buildActionButton(
          'CERO', Icons.clear_all, _handleCero, isMobile, isTablet),
      _buildActionButton(
          'CARGA', Icons.add_circle, _handleCarga, isMobile, isTablet,
          isPositive: true),
      _buildActionButton(
          'DESCARGA', Icons.remove_circle, _handleDescarga, isMobile, isTablet,
          isNegative: true),
      _buildActionButton('CONFIG', Icons.settings,
          () => _navigateTo(const ConfigScreen()), isMobile, isTablet),
      _buildActionButton('CALIBRAR', Icons.tune,
          () => _navigateTo(const CalibrationScreen()), isMobile, isTablet),
      _buildActionButton('BT', Icons.bluetooth,
          () => _navigateTo(const BluetoothScreen()), isMobile, isTablet),
      _buildActionButton('HISTORIAL', Icons.history,
          () => _navigateTo(const HistoryScreen()), isMobile, isTablet),
    ];

    if (isMobile) {
      // Mobile: ScrollView vertical para evitar overflow
      return SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: buttons,
        ),
      );
    } else {
      // Tablet/Desktop: fila horizontal con scroll
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buttons
              .map((Widget btn) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: btn,
                  ))
              .toList(),
        ),
      );
    }
  }

  // Nuevo: Botón de acción estilo F-16 minimalista responsive
  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    bool isMobile,
    bool isTablet, {
    bool isPositive = false,
    bool isNegative = false,
  }) {
    // Tamaño responsivo
    final double buttonSize = isMobile ? 70.0 : (isTablet ? 85.0 : 95.0);
    final double iconSize = isMobile ? 18.0 : 20.0;
    final double fontSize = isMobile ? 9.0 : 10.0;

    // Tema F-16: azul militar base, verde para positivo, rojo para negativo
    Color bgColor = Colors.blueGrey[700]!;
    if (isPositive) bgColor = Colors.green[700]!;
    if (isNegative) bgColor = Colors.red[400]!;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(6),
          elevation: 3, // F-16: sombra sutil para "velocidad"
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // F-16: bordes angulares
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: iconSize),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5, // F-16: espaciado militar
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nuevo: Botón TARA estilo F-16 responsive (mantiene lógica long press)
  Widget _buildTaraButton(bool isMobile, bool isTablet) {
    final double buttonSize = isMobile ? 70.0 : (isTablet ? 85.0 : 95.0);
    final double iconSize = isMobile ? 18.0 : 20.0;
    final double fontSize = isMobile ? 9.0 : 10.0;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: GestureDetector(
        onTap: _handleTara,
        onLongPressStart: (_) => _startTaraResetCountdown(),
        onLongPressEnd: (_) => _cancelTaraResetCountdown(),
        onTapCancel: _cancelTaraResetCountdown,
        child: ElevatedButton(
          onPressed: _handleTara,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.blueGrey[700], // F-16: azul militar unificado
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(6),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.scale, size: iconSize),
              const SizedBox(height: 2),
              Text(
                'TARA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => screen),
    );
  }
}
