import 'dart:async';
import 'dart:collection';
import '../models/calibration_model.dart';
import '../models/filter_params.dart';
import '../models/weight_state.dart';
import '../models/load_cell_config.dart';
import 'bluetooth_service.dart';
import 'persistence_service.dart';
import 'package:flutter/foundation.dart';

class WeightService {
  static final WeightService _instance = WeightService._internal();
  factory WeightService() => _instance;
  WeightService._internal();

  final BluetoothService _bluetoothService = BluetoothService();
  final PersistenceService _persistenceService = PersistenceService();

  // Exponer persistenceService (legacy SessionScreen eliminado)
  PersistenceService get persistenceService => _persistenceService;

  Timer? _processingTimer;
  StreamSubscription? _adcSubscription;

  final StreamController<WeightState> _weightStateController =
      StreamController<WeightState>.broadcast();
  Stream<WeightState> get weightStateStream => _weightStateController.stream;

  final StreamController<LoadCellConfig> _configController =
      StreamController<LoadCellConfig>.broadcast();
  Stream<LoadCellConfig> get configStream => _configController.stream;

  CalibrationModel _calibration = CalibrationModel.defaultModel();
  FilterParams _filterParams = FilterParams.defaultParams();
  LoadCellConfig _loadCellConfig = LoadCellConfig.defaultConfig();

  int _ultimoADC = 0;
  double _tareKg = 0.0;
  double _divisionMinima = 0.01;
  double _zeroOffsetKg = 0.0; // Cero operativo (no persistente)

  // Bug #3: Detector de timeout ADC (sin datos por 3s)
  DateTime? _lastAdcTimestamp;
  static const Duration _adcTimeout = Duration(seconds: 3);
  Timer? _timeoutCheckTimer;

  final Queue<int> _rawBuffer = Queue<int>();
  final Queue<double> _trimmedBuffer = Queue<double>();
  final Queue<double> _windowBuffer = Queue<double>();

  final Queue<double> _pesoWindowBuffer = Queue<double>();
  int _pesoWindowSize = 5;

  double _emaValue = 0.0;
  bool _emaInitialized = false;

  int _trimListSize = 10;
  final int _trimRecortes = 2;
  int _windowSize = 5;
  double _emaAlpha = 0.3;
  int _updateIntervalMs = 100;
  final int _maxRawBuffer = 50;

  WeightState _currentState = WeightState.initial();

  bool _isRunning = false;

  /// Inicializa el servicio de peso cargando configuraciones persistidas
  /// 
  /// Carga desde [PersistenceService]:
  /// - Modelo de calibración ([CalibrationModel])
  /// - Parámetros de filtros ([FilterParams])
  /// - Configuración de celda de carga ([LoadCellConfig])
  /// 
  /// Aplica las configuraciones cargadas a las variables internas.
  /// Debe llamarse antes de [start].
  Future<void> initialize() async {
    _calibration = await _persistenceService.loadCalibration();
    _filterParams = await _persistenceService.loadFilters();
    _loadCellConfig = await _persistenceService.loadConfig();

    _divisionMinima = _loadCellConfig.divisionMinima;
    _trimListSize = _filterParams.muestras;
    _windowSize = _filterParams.ventana;
    _emaAlpha = _filterParams.emaAlpha;
    _updateIntervalMs = _filterParams.updateIntervalMs;
    _pesoWindowSize = _windowSize;
  }

  /// Obtener estado actual de conexión Bluetooth (para sincronización F2.2)
  BluetoothStatus get bluetoothStatus => _bluetoothService.status;

  /// ValueNotifier de estado Bluetooth (para reactividad en UI)
  ValueNotifier<BluetoothStatus> get bluetoothStatusNotifier =>
      _bluetoothService.statusNotifier;

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _adcSubscription = _bluetoothService.adcStream.listen((int adc) {
      _ultimoADC = adc;
      _lastAdcTimestamp =
          DateTime.now(); // Bug #3: Marcar timestamp de último ADC
    });

    _processingTimer = Timer.periodic(
      Duration(milliseconds: _updateIntervalMs),
      (Timer timer) => _processData(),
    );

    // Bug #3: Iniciar timer de verificación de timeout
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!_isAdcActive) {
        // Emitir estado con ADC inactivo (sin peso, solo advertencia)
        _weightStateController.add(WeightState(
          adcRaw: 0,
          adcFiltered: 0.0,
          peso: 0.0,
          estable: false,
          overload: false,
          adcActive: false, // Marcar como inactivo
        ));
      }
    });
  }

  /// Detiene el procesamiento de datos de peso
  /// 
  /// Cancela:
  /// - Suscripción al stream ADC
  /// - Timer de procesamiento
  /// - Timer de verificación de timeout
  /// 
  /// Deja de emitir estados de peso. Puede reiniciarse con [start].
  void stop() {
    _isRunning = false;
    _adcSubscription?.cancel();
    _processingTimer?.cancel();
    _timeoutCheckTimer?.cancel(); // Bug #3: Cancelar timer de timeout
  }

  // Bug #3: Getter para verificar si ADC está activo (sin timeout)
  bool get _isAdcActive {
    if (_lastAdcTimestamp == null) return false;
    return DateTime.now().difference(_lastAdcTimestamp!) < _adcTimeout;
  }

  /// Libera todos los recursos del servicio de peso
  /// 
  /// Llama a [stop] y cierra todos los streams ([weightStateStream], [configStream]).
  /// Debe llamarse al finalizar el uso del servicio.
  void dispose() {
    stop();
    _weightStateController.close();
    _configController.close();
  }

  void _processData() {
    if (_ultimoADC == 0) return;

    _rawBuffer.add(_ultimoADC);
    if (_rawBuffer.length > _maxRawBuffer) {
      _rawBuffer.removeFirst();
    }

    if (_rawBuffer.length < _trimListSize) return;

    double trimmedMean = _calculateTrimmedMean();

    _trimmedBuffer.add(trimmedMean);
    if (_trimmedBuffer.length > _maxRawBuffer) {
      _trimmedBuffer.removeFirst();
    }

    _windowBuffer.add(trimmedMean);
    if (_windowBuffer.length > _windowSize) {
      _windowBuffer.removeFirst();
    }

    if (_windowBuffer.length < _windowSize) return;

    double windowAverage = _calculateWindowAverage();

    double emaFiltered = _applyEMA(windowAverage);

    // Orden matemático corregido:
    // 1) pesoBase = (adcFiltrado - offset) * factorEscala
    // 2) aplicar factorCorreccion sobre pesoBase
    // 3) aplicar tara y cero operativo
    // 4) cuantizar a divisionMinima al final
    double pesoBase = _calculateWeight(emaFiltered);

    double factor = _loadCellConfig.factorCorreccion;
    if (factor < -0.10) factor = -0.10;
    if (factor > 0.10) factor = 0.10;
    double pesoCorregido = pesoBase * (1 + factor);

    double pesoNeto = pesoCorregido - _tareKg;
    double pesoConZero = pesoNeto - _zeroOffsetKg; // cero operativo visual

    double pesoFinal = _applyDivisionMinima(pesoConZero);

    // Overload basado en peso corregido bruto (antes de tara/cero) para seguridad
    bool overload = pesoCorregido > _loadCellConfig.capacidadKg;

    _pesoWindowBuffer.add(pesoFinal);
    if (_pesoWindowBuffer.length > _pesoWindowSize) {
      _pesoWindowBuffer.removeFirst();
    }

    bool estable = _detectStability();

    _currentState = WeightState(
      adcRaw: _ultimoADC,
      adcFiltered: emaFiltered,
      peso: pesoFinal, // visual final después de corrección y cuantización
      estable: estable,
      overload: overload,
      adcActive: _isAdcActive, // Bug #3: Incluir estado de actividad ADC
    );

    _weightStateController.add(_currentState);
  }

  double _calculateTrimmedMean() {
    List<int> sorted = List.from(
        _rawBuffer.toList().sublist(_rawBuffer.length - _trimListSize))
      ..sort();

    if (sorted.length <= _trimRecortes * 2) {
      return sorted.reduce((int a, int b) => a + b) / sorted.length;
    }

    List<int> trimmed = sorted.sublist(
      _trimRecortes,
      sorted.length - _trimRecortes,
    );

    if (trimmed.isEmpty) return sorted[sorted.length ~/ 2].toDouble();

    return trimmed.reduce((int a, int b) => a + b) / trimmed.length;
  }

  double _calculateWindowAverage() {
    if (_windowBuffer.isEmpty) return 0.0;
    double sum = _windowBuffer.reduce((double a, double b) => a + b);
    return sum / _windowBuffer.length;
  }

  double _applyEMA(double newValue) {
    if (!_emaInitialized) {
      _emaValue = newValue;
      _emaInitialized = true;
      return _emaValue;
    }

    _emaValue = (_emaAlpha * newValue) + ((1 - _emaAlpha) * _emaValue);
    return _emaValue;
  }

  double _calculateWeight(double adcFiltered) {
    double delta = adcFiltered - _calibration.offset;
    double peso = delta * _calibration.factorEscala;
    return peso;
  }

  double _applyDivisionMinima(double peso) {
    if (_divisionMinima <= 0) return peso;
    return (peso / _divisionMinima).round() * _divisionMinima;
  }

  bool _detectStability() {
    if (_pesoWindowBuffer.length < _pesoWindowSize) return false;

    double minPeso =
        _pesoWindowBuffer.reduce((double a, double b) => a < b ? a : b);
    double maxPeso =
        _pesoWindowBuffer.reduce((double a, double b) => a > b ? a : b);
    double span = (maxPeso - minPeso).abs();

    double threshold = _divisionMinima * 0.5;

    return span < threshold;
  }

  /// Establece un nuevo modelo de calibración
  /// 
  /// Guarda la calibración en [PersistenceService] y reinicia los filtros.
  /// Parámetros del modelo afectan la conversión ADC → Peso.
  void setCalibration(CalibrationModel calibration) {
    _calibration = calibration;
    _persistenceService.saveCalibration(calibration);
    _resetFilters();
  }

  /// Establece nuevos parámetros de filtros
  /// 
  /// Actualiza:
  /// - Tamaño de lista trim ([muestras])
  /// - Tamaño de ventana ([ventana])
  /// - Alpha del filtro EMA ([emaAlpha])
  /// - Intervalo de actualización en ms ([updateIntervalMs])
  /// 
  /// Guarda en [PersistenceService], reinicia timer y resetea filtros.
  void setFilterParams(FilterParams params) {
    _filterParams = params;
    _trimListSize = params.muestras;
    _windowSize = params.ventana;
    _emaAlpha = params.emaAlpha;
    _updateIntervalMs = params.updateIntervalMs;
    _pesoWindowSize = _windowSize;

    _persistenceService.saveFilters(params);
    _restartTimer();
    _resetFilters();
  }

  /// Establece nueva configuración de celda de carga
  /// 
  /// Actualiza configuración completa (capacidad, sensibilidad, división mínima, unidad).
  /// Guarda en [PersistenceService] y emite por [configStream].
  void setLoadCellConfig(LoadCellConfig config) {
    _loadCellConfig = config;
    _divisionMinima = config.divisionMinima;
    _persistenceService.saveConfig(config);
    _configController.add(config);
  }

  void setDivisionMinimaKg(double division) {
    _divisionMinima = division;
    _loadCellConfig = _loadCellConfig.copyWith(divisionMinima: division);

    _persistenceService.saveConfig(_loadCellConfig);
    _configController.add(_loadCellConfig);

    _resetFilters();
  }

  void setTareKg(double tare) {
    _tareKg = tare;
  }

  /// Toma el peso actual como nueva tara
  /// 
  /// Suma el peso actual más la tara existente para crear una nueva tara acumulativa.
  /// La tara se aplica en los cálculos de peso subsiguientes.
  void takeTareNow() {
    _tareKg = _currentState.peso + _tareKg;
  }

  /// Establece el cero de calibración en el valor ADC actual
  /// 
  /// Toma el valor EMA actual como nuevo offset de calibración.
  /// Persiste la calibración actualizada y reinicia filtros.
  /// Solo funciona si el filtro EMA está inicializado.
  void setZeroNow() {
    if (_emaInitialized) {
      _calibration = _calibration.copyWith(offset: _emaValue);
      _persistenceService.saveCalibration(_calibration);
      _resetFilters();
    }
  }

  // NUEVO: cero operativo (no persistente, solo visual)
  void setZeroOffset() {
    _zeroOffsetKg = _currentState.peso + _zeroOffsetKg;
  }

  void applyCalibrationFromReference(double adcRef, double pesoPatron) {
    if (adcRef <= 0 || pesoPatron <= 0) return;

    double deltaADC = adcRef - _calibration.offset;
    if (deltaADC == 0) return;

    double nuevoFactor = pesoPatron / deltaADC;

    _calibration = _calibration.copyWith(
      adcReferencia: adcRef,
      pesoPatron: pesoPatron,
      factorEscala: nuevoFactor,
    );

    _persistenceService.saveCalibration(_calibration);
    _resetFilters();
  }

  void _resetFilters() {
    _rawBuffer.clear();
    _trimmedBuffer.clear();
    _windowBuffer.clear();
    _pesoWindowBuffer.clear();
    _emaInitialized = false;
    _emaValue = 0.0;
  }

  void _restartTimer() {
    if (_isRunning) {
      _processingTimer?.cancel();
      _processingTimer = Timer.periodic(
        Duration(milliseconds: _updateIntervalMs),
        (Timer timer) => _processData(),
      );
    }
  }

  // --------- NUEVO: Calibración de fábrica ---------
  Future<void> saveFactoryCalibration() async {
    await _persistenceService.saveFactoryCalibration(_calibration);
  }

  Future<void> restoreFactoryCalibration() async {
    final CalibrationModel? factoryCalibration =
        await _persistenceService.loadFactoryCalibration();
    if (factoryCalibration != null) {
      setCalibration(factoryCalibration);
    }
  }

  /// Proxy para reconexión manual vía Bluetooth
  Future<void> attemptManualReconnect() {
    return _bluetoothService.attemptManualReconnect();
  }

  WeightState get currentState => _currentState;
  CalibrationModel get calibration => _calibration;
  FilterParams get filterParams => _filterParams;
  LoadCellConfig get loadCellConfig => _loadCellConfig;
  double get tareKg => _tareKg;
  double get divisionMinima => _divisionMinima;
}
