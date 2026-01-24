import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/weight_service.dart';
import '../utils/constants.dart';

/// Widget reutilizable para mostrar el estado de la conexión Bluetooth
/// 
/// Este widget fue extraído del código duplicado presente en múltiples pantallas:
/// - ConfigScreen
/// - CalibrationScreen
/// - SessionProScreen
/// 
/// Muestra un badge compacto con:
/// - Icono según el estado (conectado, conectando, error, desconectado)
/// - Color correspondiente al estado
/// - Tooltip con texto descriptivo
/// - Permite reconexión manual al hacer tap cuando está desconectado/error
class BluetoothStatusBadge extends StatelessWidget {
  /// Callback opcional para reconexión manual
  /// Si no se provee, se usa el método por defecto de WeightService
  final Future<void> Function()? onReconnect;

  /// Nombre de la pantalla desde donde se invoca (para logging)
  final String? screenName;

  const BluetoothStatusBadge({
    super.key,
    this.onReconnect,
    this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    final WeightService weightService = WeightService();
    
    return ValueListenableBuilder<BluetoothStatus>(
      valueListenable: weightService.bluetoothStatusNotifier,
      builder: (BuildContext context, BluetoothStatus status, Widget? child) {
        final _BluetoothStatusInfo info = _getStatusInfo(status);
        
        final bool isClickable = status == BluetoothStatus.disconnected ||
            status == BluetoothStatus.error;

        return Tooltip(
          message: info.text,
          child: GestureDetector(
            onTap: isClickable
                ? () async {
                    debugPrint(
                        '[BLE_MANUAL] Reconexión manual solicitada desde ${screenName ?? "BluetoothStatusBadge"}');
                    if (onReconnect != null) {
                      await onReconnect!();
                    } else {
                      await weightService.attemptManualReconnect();
                    }
                  }
                : null,
            child: Container(
              width: AppConstants.minTapTargetSize,
              height: AppConstants.minTapTargetSize,
              padding: EdgeInsets.all(AppConstants.tapTargetPadding),
              child: Icon(
                info.icon,
                color: info.color,
                size: AppConstants.bluetoothIconSize,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Obtiene información del estado Bluetooth (icono, color, texto)
  _BluetoothStatusInfo _getStatusInfo(BluetoothStatus status) {
    switch (status) {
      case BluetoothStatus.connected:
        return _BluetoothStatusInfo(
          icon: Icons.bluetooth_connected,
          color: Colors.green,
          text: 'Bluetooth: Conectado',
        );
      case BluetoothStatus.connecting:
        return _BluetoothStatusInfo(
          icon: Icons.bluetooth_searching,
          color: Colors.orange,
          text: 'Bluetooth: Conectando...',
        );
      case BluetoothStatus.error:
        return _BluetoothStatusInfo(
          icon: Icons.bluetooth_disabled,
          color: Colors.red,
          text: 'Bluetooth: Error',
        );
      case BluetoothStatus.disconnected:
        return _BluetoothStatusInfo(
          icon: Icons.bluetooth_disabled,
          color: Colors.grey,
          text: 'Bluetooth: Desconectado',
        );
    }
  }
}

/// Clase auxiliar privada para encapsular información de estado Bluetooth
class _BluetoothStatusInfo {
  final IconData icon;
  final Color color;
  final String text;

  const _BluetoothStatusInfo({
    required this.icon,
    required this.color,
    required this.text,
  });
}
