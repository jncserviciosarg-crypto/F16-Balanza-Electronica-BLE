import 'dart:async';
import 'dart:typed_data';
import 'package:f16_balanza_electronica/models/weight_state.dart';
import 'package:flutter/material.dart';
import '../models/calibration_model.dart';
import '../services/weight_service.dart';
import '../services/bluetooth_service.dart';
import '../models/load_cell_config.dart';
import '../services/auth_service.dart';
import '../widgets/password_dialog.dart';
import '../utils/screenshot_helper.dart';
import '../utils/constants.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final WeightService _weightService = WeightService();
  final AuthService _authService = AuthService();
  StreamSubscription? _weightSubscription;
  final GlobalKey<State<StatefulWidget>> _screenshotKey = GlobalKey();

  final TextEditingController _offsetController = TextEditingController();
  final TextEditingController _adcReferenciaController =
      TextEditingController();
  final TextEditingController _pesoPatronController = TextEditingController();
  final TextEditingController _factorEscalaController = TextEditingController();
  final TextEditingController _factorCorreccionController =
      TextEditingController();

  int _adcRaw = 0;
  double _adcFiltered = 0.0;
  bool _hasData = false;

  double _offset = 0.0;
  double _adcReferencia = 0.0;
  double _pesoPatron = 10.0;
  double _factorEscala = 1.0;
  double _factorCorreccion = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCalibration();
    _subscribeToWeightStream();
    _loadFactorCorreccion();
  }

  void _loadCurrentCalibration() {
    CalibrationModel current = _weightService.calibration;
    setState(() {
      _offset = current.offset;
      _adcReferencia = current.adcReferencia;
      _pesoPatron = current.pesoPatron;
      _factorEscala = current.factorEscala;

      _offsetController.text = _offset.toStringAsFixed(2);
      _adcReferenciaController.text = _adcReferencia.toStringAsFixed(2);
      _pesoPatronController.text = _pesoPatron.toStringAsFixed(3);
      _factorEscalaController.text = _factorEscala.toStringAsFixed(6);
    });
  }

  void _loadFactorCorreccion() {
    final LoadCellConfig config = _weightService.loadCellConfig;
    setState(() {
      _factorCorreccion = config.factorCorreccion;
      _factorCorreccionController.text =
          (_factorCorreccion * 100).toStringAsFixed(2);
    });
  }

  void _subscribeToWeightStream() {
    _weightSubscription =
        _weightService.weightStateStream.listen((WeightState state) {
      if (mounted) {
        setState(() {
          _adcRaw = state.adcRaw;
          _adcFiltered = state.adcFiltered ?? state.adcRaw.toDouble();
          _hasData = _adcRaw != 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    _offsetController.dispose();
    _adcReferenciaController.dispose();
    _pesoPatronController.dispose();
    _factorEscalaController.dispose();
    _factorCorreccionController.dispose();
    super.dispose();
  }

  Future<bool> _pedirPassFija(int clave) async {
    final int? input = await PasswordDialog.show(
      context,
      mode: PasswordMode.fixed,
      title: 'Contraseña requerida',
      message: 'Ingrese la contraseña técnica',
    );
    if (input == null) return false;
    return await _authService.validateFixed(input, clave);
  }

  Future<bool> _pedirPassDinamicaOMaestra() async {
    final int key = await _authService.generateDynamicKey();
    if (!mounted) return false;
    final int? input = await PasswordDialog.show(
      context,
      mode: PasswordMode.dynamic,
      dynamicKey: key,
      title: 'Contraseña técnica',
      message: 'Ingrese la contraseña dinámica o la clave maestra',
    );
    if (input == null) return false;
    if (await _authService.validateDynamic(input, key)) return true;
    if (await _authService.validateFixed(input, 2200 + 54)) return true;
    return false;
  }

  Future<void> _handleGuardarFactorCorreccion() async {
    if (!await _pedirPassFija(1600 + 16)) {
      _showSnackBar('Contraseña incorrecta', Colors.red);
      return;
    }
    double? valor =
        double.tryParse(_factorCorreccionController.text.replaceAll(',', '.'));
    valor ??= 0.0;
    valor = valor.clamp(-10.0, 10.0);
    double factorDecimal = valor / 100.0;
    if (factorDecimal < -0.10) {
      factorDecimal = -0.10;
    }
    if (factorDecimal > 0.10) {
      factorDecimal = 0.10;
    }

    final LoadCellConfig actual = _weightService.loadCellConfig;
    final LoadCellConfig nuevo =
        actual.copyWith(factorCorreccion: factorDecimal);
    _weightService.setLoadCellConfig(nuevo);

    setState(() {
      _factorCorreccion = factorDecimal;
      _factorCorreccionController.text =
          (factorDecimal * 100).toStringAsFixed(2);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Factor de corrección guardado: ${(factorDecimal * 100).toStringAsFixed(2)}%'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Future<void> _handleGuardarCalibracion() async {
    if (!await _pedirPassFija(2000 - 16)) {
      _showSnackBar('Contraseña incorrecta', Colors.red);
      return;
    }
    _updateValuesFromFields();

    if (_pesoPatron <= 0) {
      _showSnackBar('El peso patrón debe ser mayor a cero', Colors.red);
      return;
    }

    if (_adcReferencia == _offset) {
      _showSnackBar(
          'El ADC de referencia debe ser diferente al offset', Colors.red);
      return;
    }

    if (_factorEscala == 0) {
      _showSnackBar('El factor de escala no puede ser cero', Colors.red);
      return;
    }

    _weightService.applyCalibrationFromReference(_adcReferencia, _pesoPatron);

    _showSnackBar('✅ Calibración guardada exitosamente', Colors.green);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _handleGuardarCalibracionFabrica() async {
    if (!await _pedirPassDinamicaOMaestra()) {
      _showSnackBar('Contraseña incorrecta', Colors.red);
      return;
    }
    await _weightService.saveFactoryCalibration();
    _showSnackBar('Calibración guardada como fábrica', Colors.blueGrey);
  }

  Future<void> _handleRestaurarCalibracionFabrica() async {
    if (!await _pedirPassDinamicaOMaestra()) {
      _showSnackBar('Contraseña incorrecta', Colors.red);
      return;
    }
    await _weightService.restoreFactoryCalibration();
    _showSnackBar('Calibración de fábrica restaurada', Colors.orange);
    _loadCurrentCalibration();
  }

  void _handleTomarCero() {
    if (!_hasData) {
      _showSnackBar('Esperando datos del sensor...', Colors.red);
      return;
    }

    setState(() {
      _offset = _adcFiltered;
      _offsetController.text = _offset.toStringAsFixed(2);
    });
    _weightService.setZeroNow();
    _showSnackBar(
        'Cero establecido: ${_offset.toStringAsFixed(2)}', Colors.orange);
  }

  void _handleTomarPesoCalibrado() {
    if (!_hasData) {
      _showSnackBar('Esperando datos del sensor...', Colors.red);
      return;
    }

    double peso = double.tryParse(_pesoPatronController.text) ?? 0.0;
    if (peso <= 0) {
      _showSnackBar('El peso patrón debe ser mayor a cero', Colors.red);
      return;
    }

    setState(() {
      _pesoPatron = peso;
      _adcReferencia = _adcFiltered;
      _adcReferenciaController.text = _adcReferencia.toStringAsFixed(2);
    });
    _showSnackBar(
        'Peso de referencia capturado: ${_adcReferencia.toStringAsFixed(2)}',
        Colors.blue);
  }

  void _handleRecalcularFactor() {
    if (_offset == 0 && _adcReferencia == 0) {
      _showSnackBar('Primero establezca el cero y tome el peso de referencia',
          Colors.red);
      return;
    }

    if (_offset == 0) {
      _showSnackBar('Primero establezca el cero', Colors.red);
      return;
    }

    if (_adcReferencia == 0) {
      _showSnackBar('Primero tome el peso de referencia', Colors.red);
      return;
    }

    if (_pesoPatron <= 0) {
      _showSnackBar('El peso patrón debe ser mayor a cero', Colors.red);
      return;
    }

    double deltaADC = _adcReferencia - _offset;
    if (deltaADC == 0) {
      _showSnackBar(
          'El ADC de referencia debe ser diferente al offset', Colors.red);
      return;
    }

    setState(() {
      _factorEscala = _pesoPatron / deltaADC;
      _factorEscalaController.text = _factorEscala.toStringAsFixed(6);
    });

    _showSnackBar(
        'Factor calculado: ${_factorEscala.toStringAsFixed(6)}', Colors.green);
  }

  Future<void> _handleRestablecerDefecto() async {
    if (!await _pedirPassFija(2000 - 16)) {
      _showSnackBar('Contraseña incorrecta', Colors.red);
      return;
    }

    // F-16: Diálogo de confirmación
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.grey[900], // F-16: fondo oscuro
        title: const Text(
          'RESTABLECER CALIBRACIÓN', // F-16: MAYÚSCULAS
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: const Text(
          '¿Está seguro de restablecer la calibración a valores por defecto?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCELAR',
              style: TextStyle(color: Colors.grey[400], letterSpacing: 1),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyDefaultCalibration();
            },
            style:
                TextButton.styleFrom(foregroundColor: Colors.red[800]), // F-16
            child: const Text(
              'RESTABLECER',
              style: TextStyle(letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  void _applyDefaultCalibration() {
    CalibrationModel defaultModel = CalibrationModel.defaultModel();
    _weightService.setCalibration(defaultModel);

    setState(() {
      _offset = defaultModel.offset;
      _adcReferencia = defaultModel.adcReferencia;
      _pesoPatron = defaultModel.pesoPatron;
      _factorEscala = defaultModel.factorEscala;

      _offsetController.text = _offset.toStringAsFixed(2);
      _adcReferenciaController.text = _adcReferencia.toStringAsFixed(2);
      _pesoPatronController.text = _pesoPatron.toStringAsFixed(3);
      _factorEscalaController.text = _factorEscala.toStringAsFixed(6);
    });

    _showSnackBar(
        'Calibración restablecida a valores por defecto', Colors.orange);
  }

  void _updateValuesFromFields() {
    _offset = double.tryParse(_offsetController.text) ?? _offset;
    _adcReferencia =
        double.tryParse(_adcReferenciaController.text) ?? _adcReferencia;
    _pesoPatron = double.tryParse(_pesoPatronController.text) ?? _pesoPatron;
    _factorEscala =
        double.tryParse(_factorEscalaController.text) ?? _factorEscala;
  }

  void _showSnackBar(String message, Color color) {
    // F-16: Normalizar colores de SnackBar
    Color bgColor = color;
    if (color == Colors.red) bgColor = Colors.red[800]!;
    if (color == Colors.green) bgColor = Colors.green[700]!;
    if (color == Colors.orange) bgColor = Colors.blueGrey[600]!;
    if (color == Colors.blue) bgColor = Colors.cyan[700]!;
    if (color == Colors.blueGrey) bgColor = Colors.blueGrey[700]!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ETAPA F2.2: Indicador visual compacto de estado Bluetooth en AppBar
  Widget _buildBluetoothStatusBadge() {
    return ValueListenableBuilder<BluetoothStatus>(
      valueListenable: _weightService.bluetoothStatusNotifier,
      builder: (BuildContext context, BluetoothStatus status, Widget? child) {
        IconData icon;
        Color color;

        switch (status) {
          case BluetoothStatus.connected:
            icon = Icons.bluetooth_connected;
            color = Colors.green;
            break;
          case BluetoothStatus.connecting:
            icon = Icons.bluetooth_searching;
            color = Colors.orange;
            break;
          case BluetoothStatus.error:
            icon = Icons.bluetooth_disabled;
            color = Colors.red;
            break;
          case BluetoothStatus.disconnected:
            icon = Icons.bluetooth_disabled;
            color = Colors.grey;
        }

        bool isClickable = status == BluetoothStatus.disconnected ||
            status == BluetoothStatus.error;

        return Tooltip(
          message: _getBluetoothStatusText(status),
          child: GestureDetector(
            onTap: isClickable
                ? () async {
                    debugPrint(
                        '[BLE_MANUAL] Reconexión manual solicitada desde CalibrationScreen');
                    await _weightService.attemptManualReconnect();
                  }
                : null,
            child: Container(
              width: AppConstants.minTapTargetSize,
              height: AppConstants.minTapTargetSize,
              padding: EdgeInsets.all(AppConstants.tapTargetPadding),
              child: Icon(
                icon,
                color: color,
                size: AppConstants.bluetoothIconSize,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getBluetoothStatusText(BluetoothStatus status) {
    switch (status) {
      case BluetoothStatus.connected:
        return 'Bluetooth: Conectado';
      case BluetoothStatus.connecting:
        return 'Bluetooth: Conectando...';
      case BluetoothStatus.error:
        return 'Bluetooth: Error';
      case BluetoothStatus.disconnected:
        return 'Bluetooth: Desconectado';
    }
  }

  // F-16: BUILD METHOD REFACTORIZADO
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _screenshotKey,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: AppBar(
            title: const Text(
              'CALIBRACIÓN', // F-16: MAYÚSCULAS
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.blueGrey[800], // F-16: azul militar
            actions: <Widget>[
              // ETAPA F2.2: Indicador de estado Bluetooth compacto
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildBluetoothStatusBadge(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.grey[400]), // F-16
                onPressed: () async {
                  final Uint8List? bytes =
                      await ScreenshotHelper.captureWidget(_screenshotKey);
                  if (bytes != null) {
                    await ScreenshotHelper.sharePng(bytes,
                        filenamePrefix: 'calibracion');
                  }
                  if (!mounted) return;
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Error al capturar pantalla'),
                      backgroundColor: Colors.red[800], // F-16
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: Container(
          color: Colors.grey[900], // F-16: fondo oscuro
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // F-16: Factor de corrección
                _buildCompactCard(
                  title: 'FACTOR DE CORRECCIÓN (%)',
                  color: Colors.blueGrey[400]!, // F-16: color uniforme
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: _buildCompactTextField(
                            _factorCorreccionController, 'FACTOR %'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleGuardarFactorCorreccion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[700], // F-16
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(4), // F-16: angular
                            ),
                          ),
                          child: const Text(
                            'GUARDAR',
                            style: TextStyle(fontSize: 11, letterSpacing: 1.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // F-16: Proceso de calibración en 3 pasos
                IntrinsicHeight(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildStepCard(
                          step: '1',
                          title: 'CERO',
                          color: Colors.blueGrey[600]!, // F-16: unificado
                          controller: _offsetController,
                          buttonLabel: 'TOMAR',
                          onPressed: _handleTomarCero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStepCard(
                          step: '2',
                          title: 'PESO REF',
                          color: Colors.cyan[700]!, // F-16: cian militar
                          controller: _pesoPatronController,
                          buttonLabel: 'CAPTURAR',
                          onPressed: _handleTomarPesoCalibrado,
                          secondController: _adcReferenciaController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStepCard(
                          step: '3',
                          title: 'FACTOR',
                          color: Colors.green[700]!, // F-16: verde militar
                          controller: _factorEscalaController,
                          buttonLabel: 'CALCULAR',
                          onPressed: _handleRecalcularFactor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // F-16: Botones de acción
                _buildActionsGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // F-16: TARJETA COMPACTA
  Widget _buildCompactCard(
      {required String title, required Color color, required Widget child}) {
    return Card(
      color: Colors.grey[850], // F-16
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6)), // F-16: angular
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5, // F-16
              ),
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }

  // F-16: TARJETA DE PASO
  Widget _buildStepCard({
    required String step,
    required String title,
    required Color color,
    required TextEditingController controller,
    required String buttonLabel,
    required VoidCallback onPressed,
    TextEditingController? secondController,
  }) {
    return Card(
      color: Colors.grey[850], // F-16
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6)), // F-16
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: color,
                  child: Text(
                    step,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // F-16
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[300], // F-16
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2, // F-16
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCompactTextField(controller, title),
            if (secondController != null) ...<Widget>[
              const SizedBox(height: 4),
              _buildCompactTextField(
                  secondController, 'ADC REF'), // F-16: MAYÚSCULAS
            ],
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white, // F-16
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // F-16: angular
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2, // F-16
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // F-16: CAMPO DE TEXTO COMPACTO
  Widget _buildCompactTextField(
      TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[500], // F-16
          fontSize: 10,
          letterSpacing: 1, // F-16
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4), // F-16: angular
          borderSide: BorderSide(color: Colors.blueGrey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.blueGrey[600]!), // F-16
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide:
              BorderSide(color: Colors.blueGrey[500]!, width: 1.5), // F-16
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  // F-16: GRID DE ACCIONES
  Widget _buildActionsGrid() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _compactActionButton(
            label: 'GUARDAR\nCALIBRACIÓN',
            color: Colors.green[700]!, // F-16: verde militar
            icon: Icons.save,
            onTap: _handleGuardarCalibracion,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactActionButton(
            label: 'RESTABLECER\nDEFECTO',
            color: Colors.red[800]!, // F-16: rojo oscuro
            icon: Icons.restore,
            onTap: _handleRestablecerDefecto,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactActionButton(
            label: 'GUARDAR\nFÁBRICA',
            color: Colors.blueGrey[700]!, // F-16: azul militar
            icon: Icons.factory,
            onTap: _handleGuardarCalibracionFabrica,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactActionButton(
            label: 'RESTAURAR\nFÁBRICA',
            color: Colors.blueGrey[600]!, // F-16: azul grisáceo
            icon: Icons.settings_backup_restore,
            onTap: _handleRestaurarCalibracionFabrica,
          ),
        ),
      ],
    );
  }

  // F-16: BOTÓN DE ACCIÓN COMPACTO
  Widget _compactActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 65),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // F-16: angular
        ),
        elevation: 3, // F-16: sombra sutil
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 20), // F-16: icono más compacto
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: 1, // F-16
            ),
          ),
        ],
      ),
    );
  }
}
