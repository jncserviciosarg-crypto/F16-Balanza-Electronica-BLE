import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'bluetooth_adapter.dart';
import 'flutter_blue_plus_adapter.dart';

/// Estados de conexión Bluetooth unificados
enum BluetoothStatus {
  /// Sin conexión activa
  disconnected,

  /// Proceso de conexión en progreso
  connecting,

  /// Conectado y recibiendo datos
  connected,

  /// Error en conexión (conexión fallida, se perdió, etc.)
  error,
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  dynamic _connection;
  final BluetoothAdapter _adapter = FlutterBluePlusAdapter();
  fbp.BluetoothCharacteristic? _bleCharacteristic;

  // Gestión de desconexiones y auto-reconnect
  fbp.BluetoothDevice? _lastDevice;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionStateSubscription;
  bool _manualDisconnect = false;

  // UUIDs para el servicio y característica BLE
  static const String _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String _characteristicUuid =
      'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  final StreamController<int> _adcController =
      StreamController<int>.broadcast();

  /// Estado unificado de Bluetooth (ValueNotifier para reactividad)
  final ValueNotifier<BluetoothStatus> _statusNotifier =
      ValueNotifier<BluetoothStatus>(BluetoothStatus.disconnected);

  Stream<int> get adcStream => _adcController.stream;

  /// Stream de estado Bluetooth unificado (compatibilidad)
  // Stream<BluetoothStatus> get statusStream => _statusNotifier.stream;

  /// Notifier del estado actual para ValueListenableBuilder
  ValueNotifier<BluetoothStatus> get statusNotifier => _statusNotifier;

  /// Stream booleano legacy para compatibilidad con código existente
  /// true = connected, false = disconnected/error

  int _ultimoADC = 0;
  int get ultimoADC => _ultimoADC;

  /// Retorna true solo si estado es connected
  bool get isConnected => _statusNotifier.value == BluetoothStatus.connected;

  /// Acceso directo al estado actual
  BluetoothStatus get status => _statusNotifier.value;

  /// Verifica y solicita permisos de Bluetooth según la versión de Android
  /// Retorna true si todos los permisos están concedidos, false en caso contrario
  Future<bool> checkAndRequestPermissions() async {
    try {
      // Solo aplicar en Android
      if (!Platform.isAndroid) {
        return true;
      }

      // Obtener versión de Android
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;

      List<Permission> permissionsToRequest = <Permission>[];

      if (sdkInt >= 31) {
        // Android 12+ (API 31+)
        permissionsToRequest = <Permission>[
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];
      } else {
        // Android 11 o inferior
        permissionsToRequest = <Permission>[
          Permission.bluetooth,
          Permission.location,
        ];
      }

      // Verificar si ya están concedidos
      bool allGranted = true;
      for (Permission permission in permissionsToRequest) {
        if (!await permission.isGranted) {
          allGranted = false;
          break;
        }
      }

      if (allGranted) {
        return true;
      }

      // Solicitar permisos
      Map<Permission, PermissionStatus> statuses =
          <Permission, PermissionStatus>{};
      for (Permission permission in permissionsToRequest) {
        statuses[permission] = await permission.request();
      }

      // Verificar resultados
      for (PermissionStatus status in statuses.values) {
        if (!status.isGranted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error verificando/solicitando permisos: $e');
      return false;
    }
  }

  // Obtener dispositivos emparejados
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final List<BluetoothDevice> devices = await _adapter.getBondedDevices();
      return devices;
    } catch (e) {
      debugPrint('Error obteniendo dispositivos emparejados: $e');
      return <BluetoothDevice>[];
    }
  }

  // Verificar si Bluetooth está habilitado
  Future<bool?> isBluetoothEnabled() async {
    try {
      return await _adapter.isBluetoothEnabled();
    } catch (e) {
      debugPrint('Error verificando Bluetooth: $e');
      return false;
    }
  }

  // Solicitar habilitar Bluetooth
  Future<bool?> requestEnable() async {
    try {
      return await _adapter.requestEnable();
    } catch (e) {
      debugPrint('Error solicitando habilitar Bluetooth: $e');
      return false;
    }
  }

  // Conectar a dispositivo usando ScanResult
  Future<bool> connect(fbp.ScanResult scanResult) async {
    try {
      if (status != BluetoothStatus.disconnected) {
        await disconnect();
      }

      /// Marcar estado como conectando
      _statusNotifier.value = BluetoothStatus.connecting;

      // Usar directamente el dispositivo BLE del ScanResult
      final fbp.BluetoothDevice bleDevice = scanResult.device;

      // Conectar al dispositivo BLE (v2.1+)
      // license es requerido en v2.1.0
      await bleDevice.connect(
        license: fbp.License.free,
        timeout: const Duration(seconds: 15),
        mtu: 512,
        autoConnect: false,
      );

      // Descubrir servicios
      final List<fbp.BluetoothService> services =
          await bleDevice.discoverServices();
      fbp.BluetoothService? targetService;
      for (var service in services) {
        if (service.uuid.str == _serviceUuid) {
          targetService = service;
          break;
        }
      }

      if (targetService == null) {
        await bleDevice.disconnect();
        _statusNotifier.value = BluetoothStatus.error;
        debugPrint('Error: Servicio $_serviceUuid no encontrado');
        return false;
      }

      // Buscar la característica
      fbp.BluetoothCharacteristic? targetCharacteristic;
      for (var characteristic in targetService.characteristics) {
        if (characteristic.uuid.str == _characteristicUuid) {
          targetCharacteristic = characteristic;
          break;
        }
      }

      if (targetCharacteristic == null) {
        await bleDevice.disconnect();
        _statusNotifier.value = BluetoothStatus.error;
        debugPrint('Error: Característica $_characteristicUuid no encontrada');
        return false;
      }

      _bleCharacteristic = targetCharacteristic;
      _statusNotifier.value = BluetoothStatus.connected;

      // Guardar dispositivo para posible reconexión
      _lastDevice = bleDevice;
      _manualDisconnect = false;

      // Escuchar cambios de estado de conexión (desconexiones reales)
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = bleDevice.connectionState.listen(
        _onConnectionStateChanged,
      );

      // Activar notificaciones para recibir datos cada 50ms
      await _bleCharacteristic!.setNotifyValue(true);

      // Escuchar cambios en la característica (datos binarios)
      _bleCharacteristic!.onValueReceived.listen(
        _onBinaryDataReceived,
        onError: (error) {
          debugPrint('Error recibiendo datos BLE: $error');
          _handleDisconnection();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error conectando: $e');
      _statusNotifier.value = BluetoothStatus.error;
      return false;
    }
  }

  // Escuchar cambios de estado de conexión BLE
  void _onConnectionStateChanged(fbp.BluetoothConnectionState state) {
    if (state == fbp.BluetoothConnectionState.disconnected) {
      debugPrint('Dispositivo BLE desconectado (estado real)');
      
      // Cancelar suscripción de estado para evitar loops
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
      
      // Limpiar recursos
      _handleDisconnection();
      
      // Auto-reconnect SOLO si la desconexión NO fue manual
      if (!_manualDisconnect && _lastDevice != null) {
        _attemptAutoReconnect();
      }
    }
  }

  // Intentar auto-reconexión una sola vez
  void _attemptAutoReconnect() {
    debugPrint('Intentando auto-reconexión en 2 segundos...');
    
    Future.delayed(const Duration(seconds: 2), () async {
      if (_lastDevice == null || _manualDisconnect) {
        return;
      }
      
      try {
        debugPrint('Auto-reconectando a dispositivo...');
        await _lastDevice!.connect(
          license: fbp.License.free,
          timeout: const Duration(seconds: 15),
          mtu: 512,
          autoConnect: false,
        );
        
        debugPrint('Auto-reconexión exitosa');
        _statusNotifier.value = BluetoothStatus.connected;
        
        // Re-suscribirse a cambios de estado
        _connectionStateSubscription?.cancel();
        _connectionStateSubscription = _lastDevice!.connectionState.listen(
          _onConnectionStateChanged,
        );
      } catch (e) {
        debugPrint('Auto-reconexión falló: $e');
        _statusNotifier.value = BluetoothStatus.error;
      }
    });
  }

  // Procesar datos binarios recibidos de BLE (paquete de 10 bytes)
  void _onBinaryDataReceived(List<int> data) {
    try {
      // Verificar que tenemos al menos 4 bytes para extraer el ADC
      if (data.length < 4) {
        debugPrint(
            'Advertencia: Paquete BLE incompleto (${data.length} bytes)');
        return;
      }

      // Extraer los primeros 4 bytes
      final Uint8List rawBytes = Uint8List.fromList(data.sublist(0, 4));

      // Convertir a entero de 32 bits (Little Endian)
      final ByteData byteData = ByteData.view(rawBytes.buffer);
      final int adcValue = byteData.getInt32(0, Endian.little);

      // Actualizar el último ADC y emitir al stream
      _ultimoADC = adcValue;
      _adcController.add(adcValue);
    } catch (e) {
      debugPrint('Error procesando datos binarios BLE: $e');
    }
  }

  // Manejar desconexión
  void _handleDisconnection() {
    _statusNotifier.value = BluetoothStatus.disconnected;
    _bleCharacteristic = null;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _connection?.dispose();
    _connection = null;
  }

  // Desconectar
  Future<void> disconnect() async {
    try {
      _manualDisconnect = true;
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
      await _connection?.close();
      _handleDisconnection();
      // Desconectado correctamente (log suprimido)
    } catch (e) {
      debugPrint('Error desconectando: $e');
      _handleDisconnection();
    }
  }

  // Limpiar recursos
  void dispose() {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    disconnect();
    _adcController.close();
    _statusNotifier.dispose();
  }
}
