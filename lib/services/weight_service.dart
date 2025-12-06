import 'dart:async';
import 'dart:collection';
import '../models/calibration_model.dart';
import '../models/filter_params.dart';
import '../models/weight_state.dart';
import '../models/load_cell_config.dart';
import 'bluetooth_service.dart';
import 'persistence_service.dart';

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

  final Queue<int> _rawBuffer = Queue<int>();
  final Queue<double> _trimmedBuffer = Queue<double>();
  final Queue<double> _windowBuffer = Queue<double>();

  final Queue<double> _pesoWindowBuffer = Queue<double>();
  int _pesoWindowSize = 5;

  double _emaValue = 0.0;
  bool _emaInitialized = false;

  int _trimListSize = 10;
  int _trimRecortes = 2;
  int _windowSize = 5;
  double _emaAlpha = 0.3;
  int _updateIntervalMs = 100;
  int _maxRawBuffer = 50;

  WeightState _currentState = WeightState.initial();

  bool _isRunning = false;

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

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _adcSubscription = _bluetoothService.adcStream.listen((adc) {
      _ultimoADC = adc;
    });

    _processingTimer = Timer.periodic(
      Duration(milliseconds: _updateIntervalMs),
      (timer) => _processData(),
    );
  }

  void stop() {
    _isRunning = false;
    _adcSubscription?.cancel();
    _processingTimer?.cancel();
  }

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
    );

    _weightStateController.add(_currentState);
  }

  double _calculateTrimmedMean() {
    List<int> sorted = List.from(
        _rawBuffer.toList().sublist(_rawBuffer.length - _trimListSize))
      ..sort();

    if (sorted.length <= _trimRecortes * 2) {
      return sorted.reduce((a, b) => a + b) / sorted.length;
    }

    List<int> trimmed = sorted.sublist(
      _trimRecortes,
      sorted.length - _trimRecortes,
    );

    if (trimmed.isEmpty) return sorted[sorted.length ~/ 2].toDouble();

    return trimmed.reduce((a, b) => a + b) / trimmed.length;
  }

  double _calculateWindowAverage() {
    if (_windowBuffer.isEmpty) return 0.0;
    double sum = _windowBuffer.reduce((a, b) => a + b);
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

    double minPeso = _pesoWindowBuffer.reduce((a, b) => a < b ? a : b);
    double maxPeso = _pesoWindowBuffer.reduce((a, b) => a > b ? a : b);
    double span = (maxPeso - minPeso).abs();

    double threshold = _divisionMinima * 0.5;

    return span < threshold;
  }

  void setCalibration(CalibrationModel calibration) {
    _calibration = calibration;
    _persistenceService.saveCalibration(calibration);
    _resetFilters();
  }

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

  void takeTareNow() {
    _tareKg = _currentState.peso + _tareKg;
  }

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
        (timer) => _processData(),
      );
    }
  }

  // --------- NUEVO: Calibración de fábrica ---------
  Future<void> saveFactoryCalibration() async {
    await _persistenceService.saveFactoryCalibration(_calibration);
  }

  Future<void> restoreFactoryCalibration() async {
    final factoryCalibration =
        await _persistenceService.loadFactoryCalibration();
    if (factoryCalibration != null) {
      setCalibration(factoryCalibration);
    }
  }

  WeightState get currentState => _currentState;
  CalibrationModel get calibration => _calibration;
  FilterParams get filterParams => _filterParams;
  LoadCellConfig get loadCellConfig => _loadCellConfig;
  double get tareKg => _tareKg;
  double get divisionMinima => _divisionMinima;
}
