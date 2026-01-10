import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'bluetooth_adapter.dart';

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

  BluetoothConnection? _connection;
  final BluetoothAdapter _adapter = FlutterBluetoothSerialAdapter();

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

  String _buffer = '';

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

  // Conectar a dispositivo por dirección MAC
  Future<bool> connect(String address) async {
    try {
      if (status != BluetoothStatus.disconnected) {
        await disconnect();
      }

      /// Marcar estado como conectando
      _statusNotifier.value = BluetoothStatus.connecting;

      final BluetoothConnection? conn =
          await _adapter.connectToAddress(address);

      if (conn == null) {
        _statusNotifier.value = BluetoothStatus.error;
        debugPrint('Error: Conexión nula');
        return false;
      }

      _connection = conn;
      _statusNotifier.value = BluetoothStatus.connected;

      // Información de conexión: omitida en build final

      // Iniciar lectura del stream si la conexión provee input
      _connection?.input?.listen(
        _onDataReceived,
        onDone: () {
          // La conexión se cerró: manejar internamente
          _handleDisconnection();
        },
        onError: (error) {
          debugPrint('Error en conexión: $error');
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

  // Procesar datos recibidos
  void _onDataReceived(Uint8List data) {
    try {
      String incoming = String.fromCharCodes(data);
      _buffer += incoming;

      // Procesar todas las líneas completas en el buffer
      while (_buffer.contains('\n')) {
        int newlineIndex = _buffer.indexOf('\n');
        String line = _buffer.substring(0, newlineIndex).trim();
        _buffer = _buffer.substring(newlineIndex + 1);

        if (line.isNotEmpty) {
          try {
            int adcValue = int.parse(line);
            _ultimoADC = adcValue;
            _adcController.add(adcValue);
          } catch (e) {
            debugPrint('Error parseando ADC: $line - $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error procesando datos: $e');
    }
  }

  // Manejar desconexión
  void _handleDisconnection() {
    _statusNotifier.value = BluetoothStatus.disconnected;
    _connection?.dispose();
    _connection = null;
    _buffer = '';
  }

  // Desconectar
  Future<void> disconnect() async {
    try {
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
    disconnect();
    _adcController.close();
    _statusNotifier.dispose();
  }
}
