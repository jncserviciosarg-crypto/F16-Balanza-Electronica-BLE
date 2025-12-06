import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../models/session_model.dart';
import '../models/session_weight.dart';
import '../services/session_history_service.dart';
import '../services/weight_service.dart';
import '../utils/screenshot_helper.dart';
import '../widgets/session_weight_row.dart';

/// Pantalla profesional/industrial para gestionar sesiones de pesaje
/// Lee peso de la UI (NO del weight_service), 100% independiente
class SessionProScreen extends StatefulWidget {
  final String tipo; // 'carga' o 'descarga'
  final double pesoActual;

  const SessionProScreen({
    Key? key,
    required this.tipo,
    required this.pesoActual,
  }) : super(key: key);

  @override
  State<SessionProScreen> createState() => _SessionProScreenState();
}

class _SessionProScreenState extends State<SessionProScreen> {
  late SessionModel _session;
  final _formKey = GlobalKey<FormState>();

  // GlobalKey para captura de screenshot
  final _screenshotKey = GlobalKey();

  // Controladores de formulario
  final _patenteController = TextEditingController();
  final _productoController = TextEditingController();
  final _choferController = TextEditingController();
  final _notasController = TextEditingController();

  static const int _maxPesadas = 100;

  // Peso en tiempo real
  final WeightService _weightService = WeightService();
  StreamSubscription? _weightSubscription;
  double _pesoTiempoReal = 0.0;

  /// Tara parcial que marca el "punto de inicio" del parcial.
  /// Inicializamos a pesoActual en initState para que parcial arranque en 0.
  double _taraParcial = 0.0;

  // ---- Estado para botón "TARA PARCIAL (3s)" ----
  Timer? _taraProgressTimer;
  bool _taraHoldInProgress = false;
  double _taraHoldProgress = 0.0; // 0.0 -> 1.0 progreso visual
  static const int _taraHoldMillis = 3000;

  // Propiedad calculada para peso parcial:
  // - Si es 'carga': parcial = peso actual - taraParcial (kg añadidos)
  // - Si es 'descarga': parcial = taraParcial - peso actual (kg removidos)
  // En ambos casos devolvemos valor >= 0 (clamped).
  double get _pesoParcial {
    if (widget.tipo.toLowerCase() == 'descarga') {
      return (_taraParcial - _pesoTiempoReal).clamp(0.0, double.infinity);
    } else {
      // por defecto 'carga'
      return (_pesoTiempoReal - _taraParcial).clamp(0.0, double.infinity);
    }
  }

  @override
  void initState() {
    super.initState();
    _session = SessionModel.create(
      tipo: widget.tipo,
      pesoInicial: widget.pesoActual,
    );

    // Inicializar peso en pantalla y tara parcial para que parcial == 0 al iniciar.
    _pesoTiempoReal = widget.pesoActual;
    _taraParcial = widget.pesoActual; // <- clave: parcial arranca en cero

    // Escuchar peso en tiempo real
    _weightSubscription = _weightService.weightStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _pesoTiempoReal = state.peso;
        });
      }
    });
  }

  // ==== Formateo dinámico según división mínima ====
  int _decimalsForDivision(double division) {
    if (division >= 1) return 0;
    // Representar con precisión y eliminar ceros a la derecha
    String s = division.toStringAsFixed(6); // hasta 6 decimales
    if (!s.contains('.')) return 0;
    String frac = s.split('.')[1];
    frac = frac.replaceAll(RegExp(r'0+$'), '');
    return frac.length;
  }

  String _formatWeight(double value) {
    double division = _weightService.loadCellConfig.divisionMinima;
    int dec = _decimalsForDivision(division);
    return value.toStringAsFixed(dec);
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    _patenteController.dispose();
    _productoController.dispose();
    _choferController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD: RESPONSIVE + TEMA F-16
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _screenshotKey,
      child: Scaffold(
        backgroundColor: Colors.black, // F-16: fondo negro puro
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: AppBar(
            backgroundColor: Colors.blueGrey[800], // F-16: azul militar AppBar
            title: Text(
              'SESIÓN ${widget.tipo.toUpperCase()}', // F-16: compacto
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 14, // F-16: más compacto
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.camera_alt,
                    size: 20, color: Colors.grey[400]), // F-16: icono gris
                onPressed: () async {
                  final bytes =
                      await ScreenshotHelper.captureWidget(_screenshotKey);
                  if (bytes != null) {
                    await ScreenshotHelper.sharePng(bytes,
                        filenamePrefix: 'session_${widget.tipo}');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Error al capturar pantalla'),
                        backgroundColor: Colors.red[800], // F-16: rojo oscuro
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        // F-16: Layout responsive con LayoutBuilder
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;

              if (isMobile) {
                // MÓVIL: Todo apilado verticalmente
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Display peso (altura fija para móvil)
                      SizedBox(
                        height: constraints.maxHeight * 0.25,
                        child: _buildDisplayPesoCompacto(isMobile: true),
                      ),
                      // Botones + Formulario
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                                flex: 30,
                                child:
                                    _buildBotonAgregarVertical(isMobile: true)),
                            Expanded(
                                flex: 70,
                                child:
                                    _buildFormularioCompacto(isMobile: true)),
                          ],
                        ),
                      ),
                      // Listado
                      SizedBox(
                        height: constraints.maxHeight * 0.3,
                        child: _buildListadoCompacto(isMobile: true),
                      ),
                      // Resumen
                      _buildResumenCompacto(isMobile: true),
                      // Finalizar
                      _buildBotonFinalizarCompacto(isMobile: true),
                    ],
                  ),
                );
              } else {
                // TABLET/DESKTOP: Layout horizontal original
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Panel izquierdo
                    Expanded(
                      flex: 67,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 50,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 30,
                                  child: Column(children: [
                                    Expanded(
                                        flex: 10,
                                        child: _buildBotonAgregarVertical()),
                                    Expanded(
                                      flex: 10,
                                      child: _buildTaraParcialHoldButton(
                                          isMobile: isMobile),
                                    ),
                                  ]),
                                ),
                                Expanded(
                                    flex: 70,
                                    child: _buildFormularioCompacto()),
                              ],
                            ),
                          ),
                          Expanded(
                              flex: 50, child: _buildDisplayPesoCompacto()),
                        ],
                      ),
                    ),
                    // Panel derecho
                    Expanded(
                      flex: 33,
                      child: Column(
                        children: [
                          Expanded(child: _buildListadoCompacto()),
                          _buildResumenCompacto(),
                          _buildBotonFinalizarCompacto(),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1️⃣ DISPLAY PESO F-16 RESPONSIVE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDisplayPesoCompacto({bool isMobile = false}) {
    // F-16: tamaños responsivos
    final fontSize = isMobile ? 60.0 : 100.0;
    final labelSize = isMobile ? 14.0 : 18.0;
    final spacing = isMobile ? 10.0 : 30.0;

    return Container(
      margin: const EdgeInsets.all(4), // F-16: más compacto
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black, // F-16: fondo negro puro
        borderRadius: BorderRadius.circular(4), // F-16: bordes angulares
        border: Border.all(
            color: Colors.blueGrey[600]!, width: 1), // F-16: azul militar fino
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15), // F-16: glow HUD sutil
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PESO ACTUAL
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'ACTUAL',
                        style: TextStyle(
                          color: Colors.grey[500], // F-16: gris claro
                          fontSize: labelSize,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KG',
                        style: TextStyle(
                          color: Colors.green[700], // F-16: verde militar
                          fontSize: labelSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatWeight(_pesoTiempoReal),
                    style: TextStyle(
                      color: Colors.green[700], // F-16: verde militar
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(width: spacing),
              // PESO PARCIAL
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'PARCIAL',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: labelSize,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KG',
                        style: TextStyle(
                          color: Colors.cyan[700], // F-16: cian militar
                          fontSize: labelSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatWeight(_pesoParcial),
                    style: TextStyle(
                      color: Colors.cyan[700], // F-16: cian militar
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2️⃣ BOTONES F-16 RESPONSIVE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBotonAgregarVertical({bool isMobile = false}) {
    final canAdd = _session.pesadas.length < _maxPesadas;

    final iconSize = isMobile ? 24.0 : 28.0; // F-16: iconos grandes
    final fontSize = isMobile ? 10.0 : 11.5;

    return Container(
      margin: const EdgeInsets.all(3),
      //     margin: const EdgeInsets.only(
      //         left: 1, bottom: 1, top: 1, right: 1), // F-16: compacto
      child: Column(
        children: [
          // Botón AGREGAR
          Expanded(
            child: ElevatedButton(
              onPressed: canAdd ? _agregarPesada : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700], // F-16: azul militar
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // F-16: angular
                ),
                elevation: 3, // F-16: sombra sutil
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: iconSize,
                      color: canAdd ? Colors.white : Colors.white30,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canAdd ? 'AGREGAR\nPESADA' : 'LÍMITE\nALCANZADO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2, // F-16: espaciado militar
                        height: 1.0,
                        color: canAdd ? Colors.white : Colors.white30,
                      ),
                    ),
                    SizedBox(
                      height: fontSize + 3, // Altura fija
                      child: canAdd
                          ? Text('${_session.pesadas.length}/$_maxPesadas',
                              style: TextStyle(
                                fontSize: fontSize - 1,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w600,
                              ))
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaraParcialHoldButton({bool isMobile = false}) {
    // F-16: cian militar oscuro
    final baseColor = Colors.cyan[700]!;
    final progressColor =
        Color.lerp(Colors.grey[800], baseColor, _taraHoldProgress) ?? baseColor;
    final iconSize = isMobile ? 24.0 : 28.0;
    final fontSize = isMobile ? 10.0 : 11.5;

    return Container(
      margin: const EdgeInsets.all(3),
      child: GestureDetector(
        onTapDown: (_) => _startTaraHold(),
        onTapUp: (_) => _cancelTaraHoldIfNotCompleted(),
        onTapCancel: _cancelTaraHoldIfNotCompleted,
        behavior: HitTestBehavior.translucent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: BorderRadius.circular(4), // F-16: angular
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.2),
                blurRadius: 6, // F-16: glow sutil
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Barra de progreso
              if (_taraHoldInProgress)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: FractionallySizedBox(
                    widthFactor: _taraHoldProgress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[900]!
                            .withOpacity(0.5), // F-16: progreso oscuro
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _taraHoldProgress >= 1.0
                          ? Icons.check_circle_outline
                          : Icons.timer,
                      size: iconSize,
                      color: Colors.white, // F-16: icono blanco
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TARA PARCIAL\n(3S)', // F-16: MAYÚSCULAS
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTaraHold() {
    if (_taraHoldInProgress) return;
    _taraHoldInProgress = true;
    _taraHoldProgress = 0.0;
    setState(() {});

    int elapsed = 0;
    _taraProgressTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      elapsed += 100;
      _taraHoldProgress = (elapsed / _taraHoldMillis).clamp(0.0, 1.0);
      if (_taraHoldProgress >= 1.0) {
        t.cancel();
        _triggerTaraParcial();
      }
      setState(() {});
    });
  }

  void _cancelTaraHoldIfNotCompleted([TapUpDetails? _]) {
    if (!_taraHoldInProgress) return;
    if (_taraHoldProgress >= 1.0) return; // ya completado
    _taraProgressTimer?.cancel();
    _taraHoldInProgress = false;
    _taraHoldProgress = 0.0;
    setState(() {});
  }

  void _triggerTaraParcial() {
    _taraHoldInProgress = false;
    _taraHoldProgress = 1.0;
    // Aplicar la misma acción de reseteo de parcial utilizada tras agregar pesada
    _taraParcial = _pesoTiempoReal;
    HapticFeedback.mediumImpact();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tara parcial aplicada'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.cyan,
      ),
    );
    // Reset visual luego de breve demora
    Future.delayed(const Duration(milliseconds: 400), () {
      _taraHoldProgress = 0.0;
      setState(() {});
    });
  }

  void _agregarPesada() {
    if (_session.pesadas.length >= _maxPesadas) {
      _mostrarError('Máximo $_maxPesadas pesadas por sesión');
      return;
    }

    if (_pesoParcial == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede agregar una pesada con peso cero.'),
        ),
      );
      return;
    }

    // Vibración ligera
    HapticFeedback.lightImpact();

    // Usar peso parcial (tareado)
    final peso = _pesoParcial;
    final nuevaPesada = SessionWeight.create(peso: peso);

    setState(() {
      _session = _session.copyWith(
        pesadas: [..._session.pesadas, nuevaPesada],
      );
      // Resetear parcial (actualizar taraParcial al peso actual)
      // esto hace que _pesoParcial vuelva a cero inmediatamente después de guardar
      _taraParcial = _pesoTiempoReal;
    });

    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesada agregada: ${_formatWeight(nuevaPesada.peso)} kg'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3️⃣ FORMULARIO F-16
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFormularioCompacto({bool isMobile = false}) {
    final fieldHeight = isMobile ? 38.0 : 42.0;

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blueGrey[800]!, width: 1),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          // 👈 aquí
          child: Column(
            children: [
              SizedBox(
                height: fieldHeight,
                child: _buildTextFieldCompacto(
                  controller: _patenteController,
                  label: 'PATENTE',
                  icon: Icons.local_shipping,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: fieldHeight,
                child: _buildTextFieldCompacto(
                  controller: _productoController,
                  label: 'PRODUCTO',
                  icon: Icons.inventory_2,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: fieldHeight,
                child: _buildTextFieldCompacto(
                  controller: _choferController,
                  label: 'CHOFER',
                  icon: Icons.person,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 200,
                child: _buildTextFieldCompactoNota(
                  controller: _notasController,
                  label: 'NOTAS',
                  icon: Icons.note,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldCompacto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 1,
      maxLength: 30,
      inputFormatters: [LengthLimitingTextInputFormatter(30)],
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Colors.grey[500], fontSize: 10, letterSpacing: 1), // F-16
        prefixIcon:
            Icon(icon, color: Colors.grey[600], size: 18), // F-16: icono gris
        filled: true,
        fillColor: Colors.grey[850], // F-16: fondo oscuro
        contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        isDense: true,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4), // F-16: angular
          borderSide: BorderSide(color: Colors.blueGrey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.blueGrey[700]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
              color: Colors.blueGrey[500]!, width: 1.5), // F-16: foco azul
        ),
      ),
    );
  }

  Widget _buildTextFieldCompactoNota({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 10,
      maxLength: 300,
      inputFormatters: [LengthLimitingTextInputFormatter(300)],
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Colors.grey[500], fontSize: 10, letterSpacing: 1), // F-16
        prefixIcon:
            Icon(icon, color: Colors.grey[600], size: 18), // F-16: icono gris

        filled: true,
        fillColor: Colors.grey[850], // F-16: fondo oscuro
        contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        isDense: true,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4), // F-16: angular
          borderSide: BorderSide(color: Colors.blueGrey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.blueGrey[700]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
              color: Colors.blueGrey[500]!, width: 1.5), // F-16: foco azul
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4️⃣ LISTADO F-16
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildListadoCompacto({bool isMobile = false}) {
    if (_session.pesadas.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[900], // F-16: fondo oscuro
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blueGrey[800]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.scale, size: 40, color: Colors.blueGrey[700]), // F-16
              const SizedBox(height: 8),
              Text(
                'SIN PESADAS', // F-16: MAYÚSCULAS
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'PRESIONA AGREGAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 10, letterSpacing: 1),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[900], // F-16
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blueGrey[800]!),
      ),
      child: Column(
        children: [
          // Encabezado F-16
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800], // F-16: azul militar
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  child: Text(
                    'Nº', // F-16: ya en mayúsculas
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 12,
                  child: Text(
                    'FECHA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 12,
                  child: Text(
                    'HORA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 10,
                  child: Text(
                    'PESO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: ListView.builder(
              itemCount: _session.pesadas.length,
              itemBuilder: (context, index) {
                return SessionWeightRow(
                  numero: index + 1,
                  pesada: _session.pesadas[index],
                  onDelete: () => _eliminarPesada(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _eliminarPesada(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900], // F-16: fondo oscuro
        title: const Text('ELIMINAR PESADA', // F-16: MAYÚSCULAS
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        content: Text(
          '¿Eliminar pesada #${index + 1}?\n${_formatWeight(_session.pesadas[index].peso)} kg',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR',
                style: TextStyle(color: Colors.grey[400], letterSpacing: 1)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final nuevasPesadas =
                    List<SessionWeight>.from(_session.pesadas);
                nuevasPesadas.removeAt(index);
                _session = _session.copyWith(pesadas: nuevasPesadas);
              });
              Navigator.pop(context);
            },
            child: Text('ELIMINAR',
                style: TextStyle(
                    color: Colors.red[800],
                    letterSpacing: 1)), // F-16: rojo oscuro
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5️⃣ RESUMEN F-16
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildResumenCompacto({bool isMobile = false}) {
    final totalPesadas = _session.pesadas.length;
    final totalKg = _session.pesadas.isEmpty
        ? 0.0
        : _session.pesadas.map((p) => p.peso).reduce((a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[900], // F-16: fondo oscuro
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blueGrey[800]!), // F-16
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL PESADAS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5, // F-16
                ),
              ),
              Text(
                '$totalPesadas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Divider(color: Colors.blueGrey[700], height: 8), // F-16
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL KG',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                _formatWeight(totalKg),
                style: TextStyle(
                  color: Colors.green[700], // F-16: verde militar
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6️⃣ BOTÓN FINALIZAR F-16
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBotonFinalizarCompacto({bool isMobile = false}) {
    final canFinalize = _session.pesadas.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: canFinalize ? _finalizarSesion : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey[700], // F-16: azul militar
          disabledBackgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // F-16: angular
          ),
          elevation: 3, // F-16: sombra sutil
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 22, color: Colors.white), // F-16: icono outline
            const SizedBox(width: 8),
            Text(
              canFinalize
                  ? 'FINALIZAR SESIÓN'
                  : 'SIN PESADAS', // F-16: más descriptivo
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2, // F-16: espaciado militar
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finalizarSesion() async {
    if (_session.pesadas.isEmpty) {
      _mostrarError('No hay pesadas para finalizar');
      return;
    }

    // Calcular datos finales
    final fechaFinalizacion = DateTime.now();
    final totalKg = _session.pesadas.map((p) => p.peso).reduce((a, b) => a + b);

    // Generar nuevo ID determinista basado en timestamp + peso
    final nuevoId = SessionModel.generateSessionId(fechaFinalizacion, totalKg);

    // Actualizar datos del formulario
    final sessionFinal = _session.copyWith(
      id: nuevoId,
      fechaFin: fechaFinalizacion,
      pesoFinal: _session.pesadas.last.peso,
      patente: _patenteController.text.isEmpty ? null : _patenteController.text,
      producto:
          _productoController.text.isEmpty ? null : _productoController.text,
      chofer: _choferController.text.isEmpty ? null : _choferController.text,
      notas: _notasController.text.isEmpty ? null : _notasController.text,
    );

    try {
      // Guardar con SessionHistoryService
      await SessionHistoryService().saveSession(sessionFinal);

      // F-16: Diálogo de confirmación
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900], // F-16: fondo oscuro
          title: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.green[700], size: 28), // F-16: verde militar
              const SizedBox(width: 12),
              const Text('SESIÓN GUARDADA', // F-16: MAYÚSCULAS
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TIPO: ${sessionFinal.tipo.toUpperCase()}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('PESADAS: ${sessionFinal.cantidadPesadas}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(
                'TOTAL: ${_formatWeight(totalKg)} KG',
                style: TextStyle(
                  color: Colors.green[700], // F-16: verde militar
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final path = await SessionHistoryService()
                      .exportSessionToXlsx(sessionFinal);
                  await Share.shareXFiles([XFile(path)],
                      text: 'Sesión XLSX - ${sessionFinal.id}');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error al exportar XLSX: $e'),
                          backgroundColor: Colors.red[800]),
                    );
                  }
                }
              },
              child: Text('XLSX',
                  style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 14,
                      letterSpacing: 1)), // F-16
            ),
            TextButton(
              onPressed: () async {
                try {
                  final path = await SessionHistoryService()
                      .exportSessionToPdf(sessionFinal);
                  await Share.shareXFiles([XFile(path)],
                      text: 'Sesión PDF - ${sessionFinal.id}');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error al exportar PDF: $e'),
                          backgroundColor: Colors.red[800]),
                    );
                  }
                }
              },
              child: Text('PDF',
                  style: TextStyle(
                      color: Colors.cyan[700],
                      fontSize: 14,
                      letterSpacing: 1)), // F-16
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('ACEPTAR',
                  style: TextStyle(
                      color: Colors.blueGrey[400],
                      fontSize: 14,
                      letterSpacing: 1.5)), // F-16
            ),
          ],
        ),
      );
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red[800], // F-16: rojo oscuro
      ),
    );
  }
}
