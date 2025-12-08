import 'dart:async';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothConnection? _connection;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  final StreamController<int> _adcController =
      StreamController<int>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<int> get adcStream => _adcController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  int _ultimoADC = 0;
  int get ultimoADC => _ultimoADC;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

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
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      List<Permission> permissionsToRequest = [];

      if (sdkInt >= 31) {
        // Android 12+ (API 31+)
        permissionsToRequest = [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];
      } else {
        // Android 11 o inferior
        permissionsToRequest = [
          Permission.bluetooth,
          Permission.location,
        ];
      }

      // Verificar si ya están concedidos
      bool allGranted = true;
      for (var permission in permissionsToRequest) {
        if (!await permission.isGranted) {
          allGranted = false;
          break;
        }
      }

      if (allGranted) {
        return true;
      }

      // Solicitar permisos
      Map<Permission, PermissionStatus> statuses = {};
      for (var permission in permissionsToRequest) {
        statuses[permission] = await permission.request();
      }

      // Verificar resultados
      for (var status in statuses.values) {
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
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      return devices;
    } catch (e) {
      debugPrint('Error obteniendo dispositivos emparejados: $e');
      return [];
    }
  }

  // Verificar si Bluetooth está habilitado
  Future<bool?> isBluetoothEnabled() async {
    try {
      return await _bluetooth.isEnabled;
    } catch (e) {
      debugPrint('Error verificando Bluetooth: $e');
      return false;
    }
  }

  // Solicitar habilitar Bluetooth
  Future<bool?> requestEnable() async {
    try {
      return await _bluetooth.requestEnable();
    } catch (e) {
      debugPrint('Error solicitando habilitar Bluetooth: $e');
      return false;
    }
  }

  // Conectar a dispositivo por dirección MAC
  Future<bool> connect(String address) async {
    try {
      if (_isConnected) {
        await disconnect();
      }

      _connection = await BluetoothConnection.toAddress(address);
      _isConnected = true;
      _connectionController.add(true);

      debugPrint('Conectado a $address');

      // Iniciar lectura del stream
      _connection!.input!.listen(
        _onDataReceived,
        onDone: () {
          debugPrint('Conexión cerrada');
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
      _isConnected = false;
      _connectionController.add(false);
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
    _isConnected = false;
    _connectionController.add(false);
    _connection?.dispose();
    _connection = null;
    _buffer = '';
  }

  // Desconectar
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _handleDisconnection();
      debugPrint('Desconectado correctamente');
    } catch (e) {
      debugPrint('Error desconectando: $e');
      _handleDisconnection();
    }
  }

  // Limpiar recursos
  void dispose() {
    disconnect();
    _adcController.close();
    _connectionController.close();
  }
}
