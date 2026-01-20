import 'dart:async';
import 'dart:typed_data';
import 'package:f16_balanza_electronica/models/weight_state.dart';
import 'package:flutter/material.dart';
import '../models/load_cell_config.dart';
import '../models/filter_params.dart';
import '../services/weight_service.dart';
import '../services/bluetooth_service.dart';
import 'package:f16_balanza_electronica/widgets/filter_editor.dart';
import '../utils/screenshot_helper.dart';
import '../utils/constants.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final WeightService _weightService = WeightService();
  final GlobalKey<State<StatefulWidget>> _screenshotKey = GlobalKey();

  StreamSubscription? _weightSubscription;
  int _adcRaw = 0;
  double _adcFiltered = 0.0;
  bool _hasData = false;

  late TextEditingController _capacidadController;
  late TextEditingController _sensibilidadController;
  late TextEditingController _excitacionController;
  late TextEditingController _gananciaController;
  late TextEditingController _vRefController;
  late TextEditingController _divisionMinimaController;

  late LoadCellConfig _loadCellConfig;
  late FilterParams _filterParams;
  String _unidadSeleccionada = 'kg';

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
    _subscribeToWeightStream();
  }

  void _loadCurrentConfig() {
    _loadCellConfig = _weightService.loadCellConfig;
    _filterParams = _weightService.filterParams;
    _unidadSeleccionada = _loadCellConfig.unidad;

    _capacidadController =
        TextEditingController(text: _loadCellConfig.capacidadKg.toString());
    _sensibilidadController =
        TextEditingController(text: _loadCellConfig.sensibilidadMvV.toString());
    _excitacionController = TextEditingController(
        text: _loadCellConfig.voltajeExcitacion.toString());
    _gananciaController =
        TextEditingController(text: _loadCellConfig.gananciaHX711.toString());
    _vRefController = TextEditingController(
        text: _loadCellConfig.voltajeReferencia.toString());
    _divisionMinimaController =
        TextEditingController(text: _loadCellConfig.divisionMinima.toString());
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
    _capacidadController.dispose();
    _sensibilidadController.dispose();
    _excitacionController.dispose();
    _gananciaController.dispose();
    _vRefController.dispose();
    _divisionMinimaController.dispose();
    super.dispose();
  }

  void _handleSaveLoadCellConfig() {
    double capacidad = double.tryParse(_capacidadController.text) ??
        _loadCellConfig.capacidadKg;
    double sensibilidad = double.tryParse(_sensibilidadController.text) ??
        _loadCellConfig.sensibilidadMvV;
    double excitacion = double.tryParse(_excitacionController.text) ??
        _loadCellConfig.voltajeExcitacion;
    double ganancia = double.tryParse(_gananciaController.text) ??
        _loadCellConfig.gananciaHX711;
    double vRef = double.tryParse(_vRefController.text) ??
        _loadCellConfig.voltajeReferencia;
    double divisionMinima = double.tryParse(_divisionMinimaController.text) ??
        _loadCellConfig.divisionMinima;

    if (capacidad <= 0) {
      _showError('Capacidad debe ser > 0');
      return;
    }

    if (sensibilidad < 1.0 || sensibilidad > 3.5) {
      _showError('Sensibilidad debe estar entre 1.0 y 3.5 mV/V');
      return;
    }

    if (divisionMinima <= 0) {
      _showError('División mínima debe ser > 0');
      return;
    }

    final LoadCellConfig newConfig = _loadCellConfig.copyWith(
      capacidadKg: capacidad,
      sensibilidadMvV: sensibilidad,
      voltajeExcitacion: excitacion,
      gananciaHX711: ganancia,
      voltajeReferencia: vRef,
      divisionMinima: divisionMinima,
      unidad: _unidadSeleccionada,
    );

    _weightService.setLoadCellConfig(newConfig);
    setState(() {
      _loadCellConfig = newConfig;
    });
    _showSuccess('Configuración de celda guardada');
  }

  void _handleSaveFilterParams(FilterParams params) {
    _weightService.setFilterParams(params);
    setState(() {
      _filterParams = params;
    });
    _showSuccess('Filtros aplicados y guardados');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[800]), // F-16: rojo oscuro
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.green[700]), // F-16: verde militar
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
                        '[BLE_MANUAL] Reconexión manual solicitada desde ConfigScreen');
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
              'CONFIGURACIÓN', // F-16: MAYÚSCULAS
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5, // F-16: espaciado militar
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
                icon: Icon(Icons.camera_alt,
                    color: Colors.grey[400]), // F-16: icono gris
                onPressed: () async {
                  final Uint8List? bytes =
                      await ScreenshotHelper.captureWidget(_screenshotKey);
                  if (bytes != null) {
                    await ScreenshotHelper.sharePng(bytes,
                        filenamePrefix: 'configuracion');
                  } else {
                    if (!mounted) return;
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Error al capturar pantalla'),
                        backgroundColor: Colors.red[800], // F-16
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        body: Container(
          color: Colors.grey[900], // F-16: fondo oscuro
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                bool isWideScreen = constraints.maxWidth > 600;

                if (isWideScreen) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            _buildLoadCellSection(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            _buildMonitoringSection(),
                            const SizedBox(height: 12),
                            _buildFilterSection(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: <Widget>[
                      _buildLoadCellSection(),
                      const SizedBox(height: 12),
                      _buildMonitoringSection(),
                      const SizedBox(height: 12),
                      _buildFilterSection(),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // F-16: SECCIÓN CELDA DE CARGA
  Widget _buildLoadCellSection() {
    return Card(
      color: Colors.grey[850], // F-16: panel oscuro
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6)), // F-16: bordes angulares
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'CELDA DE CARGA', // F-16: sin emoji
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[400], // F-16: color uniforme
                letterSpacing: 1.5, // F-16: espaciado militar
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField(_capacidadController, 'CAPACIDAD (KG)',
                '> 0'), // F-16: MAYÚSCULAS
            const SizedBox(height: 8),
            _buildTextField(
                _sensibilidadController, 'SENSIBILIDAD (MV/V)', '1.0 - 3.5'),
            const SizedBox(height: 8),
            _buildTextField(
                _excitacionController, 'VOLTAJE EXCITACIÓN (V)', ''),
            const SizedBox(height: 8),
            _buildTextField(_gananciaController, 'GANANCIA HX711', ''),
            const SizedBox(height: 8),
            _buildTextField(_vRefController, 'VOLTAJE REFERENCIA (V)', ''),
            const SizedBox(height: 8),
            _buildTextField(
                _divisionMinimaController, 'DIVISIÓN MÍNIMA (KG)', '> 0'),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(
                  'UNIDAD:', // F-16: MAYÚSCULAS
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      letterSpacing: 1.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4), // F-16: angular
                      border: Border.all(
                          color: Colors.blueGrey[600]!), // F-16: borde uniforme
                    ),
                    child: DropdownButton<String>(
                      value: _unidadSeleccionada,
                      isExpanded: true,
                      dropdownColor: Colors.grey[800],
                      underline: const SizedBox(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1), // F-16
                      items: <String>['kg', 'g', 'lb'].map((String unidad) {
                        return DropdownMenuItem(
                          value: unidad,
                          child: Text(unidad.toUpperCase()), // F-16: MAYÚSCULAS
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _unidadSeleccionada = value;
                          });
                          _handleSaveLoadCellConfig();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSaveLoadCellConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700], // F-16: azul militar
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)), // F-16: angular
                  elevation: 3,
                ),
                child: const Text(
                  'GUARDAR CONFIGURACIÓN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5, // F-16
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // F-16: SECCIÓN FILTROS
  Widget _buildFilterSection() {
    return Card(
      color: Colors.grey[850], // F-16
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6)), // F-16: angular
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'FILTROS', // F-16: sin emoji, MAYÚSCULAS
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[400], // F-16: color uniforme
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            FilterEditor(
              initial: _filterParams,
              onSave: _handleSaveFilterParams,
            ),
          ],
        ),
      ),
    );
  }

  // F-16: SECCIÓN MONITOREO
  Widget _buildMonitoringSection() {
    return Card(
      color: Colors.grey[850], // F-16
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6)), // F-16: angular
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'MONITOREO EN TIEMPO REAL', // F-16: sin emoji
              style: TextStyle(
                color: Colors.blueGrey[400], // F-16: color uniforme
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5, // F-16
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ADC RAW:', // F-16: MAYÚSCULAS
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          letterSpacing: 1.2),
                    ),
                    Text(
                      '$_adcRaw',
                      style: const TextStyle(
                        color: Colors.white, // F-16
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'ADC FILTRADO:', // F-16: MAYÚSCULAS
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          letterSpacing: 1.2),
                    ),
                    Text(
                      _adcFiltered.toStringAsFixed(2),
                      style: TextStyle(
                        color: Colors.cyan[700], // F-16: cian militar
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!_hasData)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.warning_amber,
                        color: Colors.grey[500], size: 14), // F-16: gris
                    const SizedBox(width: 6),
                    Text(
                      'ESPERANDO DATOS...', // F-16: MAYÚSCULAS
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // F-16: CAMPO DE TEXTO UNIFICADO (sin parámetro color)
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.blueGrey[400], // F-16: color uniforme
          fontSize: 11,
          letterSpacing: 1, // F-16
        ),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4)), // F-16: angular
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide:
              BorderSide(color: Colors.blueGrey[600]!), // F-16: borde uniforme
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide:
              BorderSide(color: Colors.blueGrey[500]!, width: 1.5), // F-16
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}
