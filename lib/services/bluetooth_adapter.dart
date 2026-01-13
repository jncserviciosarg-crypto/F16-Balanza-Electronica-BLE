import 'dart:async';

/// Tipos de datos genéricos para compatibilidad de interfaz
class BluetoothDevice {
  final DeviceIdentifier remoteId;
  final String? platformName;

  BluetoothDevice({
    required this.remoteId,
    this.platformName,
  });
}

class DeviceIdentifier {
  final String str;
  DeviceIdentifier(this.str);
}

enum BluetoothBondState { bonded, bonding, none }

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
  Future<dynamic> connectToAddress(String address);

  /// Stream de estado de Bluetooth
  Stream<bool> get bluetoothStateStream;
}

/// Implementación de adaptador legacy (no usa flutter_bluetooth_serial)
class FlutterBluetoothSerialAdapter implements BluetoothAdapter {
  @override
  Future<List<BluetoothDevice>> getBondedDevices() async {
    return <BluetoothDevice>[];
  }

  @override
  Future<bool?> isBluetoothEnabled() async {
    return false;
  }

  @override
  Future<bool?> requestEnable() async {
    return false;
  }

  @override
  Future<dynamic> connectToAddress(String address) async {
    return null;
  }

  @override
  Stream<bool> get bluetoothStateStream {
    return Stream.value(true);
  }
}
