import 'package:flutter/foundation.dart';
import 'bluetooth_adapter.dart' as btAdapter;

/// Archivo de demostración del uso de BluetoothAdapter.
/// Este archivo NO se usa en producción todavía, solo muestra cómo
/// el adaptador puede abstraer flutter_bluetooth_serial.

void demonstrateBluetoothAdapterUsage() {
  // Demo: ejemplo de uso del adaptador (log suprimido en build final)
  // En el futuro, esto permitirá cambiar entre implementaciones fácilmente:
  // - FlutterBluetoothSerialAdapter (actual)
  // - FlutterBluePlusAdapter (futura migración)
  // - OtherBluetoothAdapter (futuro soporte)

  // Ejemplo de uso futuro:
  // final adapter = btAdapter.FlutterBluetoothSerialAdapter();
  // final devices = await adapter.getBondedDevices();
}
