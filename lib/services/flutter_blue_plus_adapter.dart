import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'bluetooth_adapter.dart';

/// Implementación de adaptador usando flutter_blue_plus
/// Mapea los tipos de flutter_blue_plus a los tipos esperados por BluetoothAdapter
class FlutterBluePlusAdapter implements BluetoothAdapter {
  final StreamController<bool> _bluetoothStateController =
      StreamController<bool>.broadcast();

  FlutterBluePlusAdapter() {
    _initializeStateListener();
  }

  /// Inicializa el listener para cambios de estado de Bluetooth
  void _initializeStateListener() {
    fbp.FlutterBluePlus.adapterState.listen((state) {
      _bluetoothStateController.add(state == fbp.BluetoothAdapterState.on);
    });
  }

  @override
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final List<BluetoothDevice> bondedDevices = [];

      // Obtener todos los dispositivos connectable
      final List<fbp.BluetoothDevice> connectedDevices =
          fbp.FlutterBluePlus.connectedDevices;

      for (var device in connectedDevices) {
        // Crear un BluetoothDevice compatible con la interfaz
        bondedDevices.add(
          BluetoothDevice(
            remoteId: DeviceIdentifier(device.remoteId.str),
            platformName: device.platformName,
          ),
        );
      }

      return bondedDevices;
    } catch (e) {
      return <BluetoothDevice>[];
    }
  }

  @override
  Future<bool?> isBluetoothEnabled() async {
    try {
      final state = await fbp.FlutterBluePlus.adapterState.first;
      return state == fbp.BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool?> requestEnable() async {
    try {
      // flutter_blue_plus no tiene método directo para solicitar habilitar Bluetooth
      // Este método requeriría usar platform channels o system intent
      // Por ahora, solo verifica si está habilitado
      await fbp.FlutterBluePlus.turnOn();
      return await isBluetoothEnabled();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<dynamic> connectToAddress(String address) async {
    try {
      // Buscar el dispositivo con la dirección MAC especificada
      final device = await _findDeviceByAddress(address);

      if (device == null) {
        return null;
      }

      // Conectar al dispositivo (v2.1+)
      // license es requerido en v2.1.0
      await device.connect(
        license: fbp.License.free,
        timeout: const Duration(seconds: 15),
        mtu: 512,
        autoConnect: false,
      );

      // Retornar el dispositivo como conexión
      return device;
    } catch (e) {
      return null;
    }
  }

  /// Busca un dispositivo por dirección MAC
  Future<fbp.BluetoothDevice?> _findDeviceByAddress(String address) async {
    try {
      // systemDevices es un getter que retorna una función
      final List<fbp.BluetoothDevice> systemDevices =
          await fbp.FlutterBluePlus.systemDevices([]);
      for (var device in systemDevices) {
        if (device.remoteId.str == address) {
          return device;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<bool> get bluetoothStateStream {
    return _bluetoothStateController.stream;
  }

  /// Método adicional de escaneo para descubrir dispositivos BLE
  /// Este método NO está en la interfaz, es una extensión específica
  Future<List<fbp.ScanResult>> scanForBLEDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final results = <fbp.ScanResult>[];

      // Inicia el escaneo
      await fbp.FlutterBluePlus.startScan(timeout: timeout);

      // Recopila los resultados del escaneo
      fbp.FlutterBluePlus.scanResults.listen((results) {
        // Los resultados se pueden procesar aquí
      });

      // Espera a que el escaneo se complete
      await Future.delayed(timeout);

      // Detiene el escaneo
      await fbp.FlutterBluePlus.stopScan();

      // Retorna los últimos resultados
      results.addAll(await fbp.FlutterBluePlus.scanResults.first);

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Método para obtener servicios de un dispositivo conectado
  Future<List<fbp.BluetoothService>> getDeviceServices(
      String deviceAddress) async {
    try {
      final device = await _findDeviceByAddress(deviceAddress);
      if (device == null) {
        return [];
      }

      return await device.discoverServices();
    } catch (e) {
      return [];
    }
  }

  /// Método para limpiar recursos
  void dispose() {
    _bluetoothStateController.close();
  }
  // 🔧 FIX PARA: lib/services/flutter_blue_plus_adapter.dart
// Agregar este método a la clase FlutterBluePlusAdapter

  /// Detiene el escaneo de dispositivos BLE activo
  @override
  Future<void> stopScan() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
      print('[BLE] Scan detenido correctamente');
    } catch (e) {
      print('[BLE] Error al detener scan: $e');
      // No lanzar error, solo registrar
    }
  }
}
