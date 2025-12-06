import 'dart:async';
import 'package:flutter/material.dart';
import '../models/load_cell_config.dart';
import '../models/filter_params.dart';
import '../services/weight_service.dart';
import 'package:f16_balanza_electronica/widgets/filter_editor.dart';
import '../utils/screenshot_helper.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final WeightService _weightService = WeightService();
  final _screenshotKey = GlobalKey();

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
    _weightSubscription = _weightService.weightStateStream.listen((state) {
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

    final newConfig = _loadCellConfig.copyWith(
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

  // F-16: BUILD METHOD REFACTORIZADO
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _screenshotKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'CONFIGURACIÓN', // F-16: MAYÚSCULAS
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5, // F-16: espaciado militar
              fontSize: 14,
            ),
          ),
          backgroundColor: Colors.blueGrey[800], // F-16: azul militar
          actions: [
            IconButton(
              icon: Icon(Icons.camera_alt,
                  color: Colors.grey[400]), // F-16: icono gris
              onPressed: () async {
                final bytes =
                    await ScreenshotHelper.captureWidget(_screenshotKey);
                if (bytes != null) {
                  await ScreenshotHelper.sharePng(bytes,
                      filenamePrefix: 'configuracion');
                } else {
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
        body: Container(
          color: Colors.grey[900], // F-16: fondo oscuro
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 600;

                if (isWideScreen) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildLoadCellSection(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
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
                    children: [
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
          children: [
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
              children: [
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
                      items: ['kg', 'g', 'lb'].map((unidad) {
                        return DropdownMenuItem(
                          value: unidad,
                          child: Text(unidad.toUpperCase()), // F-16: MAYÚSCULAS
                        );
                      }).toList(),
                      onChanged: (value) {
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
          children: [
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
          children: [
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
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  children: [
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
                  children: [
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
