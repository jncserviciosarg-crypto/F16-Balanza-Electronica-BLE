import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Interfaz abstracta para adaptador de Bluetooth.
/// Permite cambiar de implementación (flutter_bluetooth_serial, flutter_blue_plus, etc.)
/// sin afectar el resto del código.
abstract class BluetoothAdapter {
  /// Obtener lista de dispositivos emparejados
  Future<List<BluetoothDevice>> getBondedDevices();

  /// Verificar si Bluetooth está habilitado
  Future<bool?> isBluetoothEnabled();

  /// Solicitar que el usuario habilite Bluetooth
  Future<bool?> requestEnable();

  /// Conectar a un dispositivo por dirección MAC
  Future<BluetoothConnection?> connectToAddress(String address);

  /// Stream de estado de Bluetooth
  Stream<bool> get bluetoothStateStream;
}

/// Implementación de adaptador usando flutter_bluetooth_serial
class FlutterBluetoothSerialAdapter implements BluetoothAdapter {
  final FlutterBluetoothSerial _flutterBluetooth =
      FlutterBluetoothSerial.instance;

  @override
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final devices = await _flutterBluetooth.getBondedDevices();
      return devices.cast<BluetoothDevice>();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool?> isBluetoothEnabled() async {
    try {
      return await _flutterBluetooth.isEnabled;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool?> requestEnable() async {
    try {
      return await _flutterBluetooth.requestEnable();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<BluetoothConnection?> connectToAddress(String address) async {
    try {
      return await BluetoothConnection.toAddress(address);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<bool> get bluetoothStateStream {
    // Placeholder para futuros estados de Bluetooth
    return Stream.value(true);
  }
}
