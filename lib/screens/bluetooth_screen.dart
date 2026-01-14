import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../services/bluetooth_service.dart';
import '../services/flutter_blue_plus_adapter.dart';
import '../utils/screenshot_helper.dart';
import 'dart:async';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final FlutterBluePlusAdapter _bleAdapter = FlutterBluePlusAdapter();
  List<fbp.ScanResult> _devices = <fbp.ScanResult>[];
  bool _isScanning = false;
  String? _connectedDeviceName;
  int _ultimoADC = 0;
  final GlobalKey<State<StatefulWidget>> _screenshotKey = GlobalKey();

  /// Subscripciones que se cancelarán en dispose()

  late StreamSubscription<int> _adcSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothAndLoadDevices();
    ValueListenableBuilder<BluetoothStatus>(
      valueListenable: _bluetoothService.statusNotifier,
      builder: (context, status, _) {
        return Text(_getStatusText(status));
      },
    );

/*    // Escuchar cambios de estado de conexión (nuevo sistema unificado)
    _statusSubscription =
        _bluetoothService.statusStream.listen((BluetoothStatus status) {
      if (mounted) {
        setState(() {
          if (status != BluetoothStatus.connected) {
            _connectedDeviceName = null;
          }
        });
      }
    });*/

    // Escuchar valores ADC
    _adcSubscription = _bluetoothService.adcStream.listen((int adc) {
      if (mounted) {
        setState(() {
          _ultimoADC = adc;
        });
      }
    });
  }

  Future<void> _checkBluetoothAndLoadDevices() async {
    // Verificar permisos primero
    final bool hasPermissions =
        await _bluetoothService.checkAndRequestPermissions();
    if (!hasPermissions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Se necesitan permisos de Bluetooth para continuar.'),
            backgroundColor: Colors.red[800], // F-16
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    bool? isEnabled = await _bluetoothService.isBluetoothEnabled();

    if (isEnabled == false) {
      bool? enabled = await _bluetoothService.requestEnable();
      if (enabled == false || enabled == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bluetooth no está habilitado'),
              backgroundColor: Colors.red[800], // F-16
            ),
          );
        }
        return;
      }
    }

    await _loadPairedDevices();
  }

  Future<void> _scanForBLEDevices() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      List<fbp.ScanResult> scanResults = await _bleAdapter.scanForBLEDevices(
        timeout: const Duration(seconds: 10),
      );

      setState(() {
        // Filtrar y ordenar: priorizar 'BalanzaJ&M_BLE'
        _devices = scanResults.where((result) {
          final name = result.device.platformName;
          return name.isNotEmpty;
        }).toList();

        // Ordenar: primero dispositivos con 'BalanzaJ&M_BLE' en el nombre
        _devices.sort((a, b) {
          final aName = a.device.platformName;
          final bName = b.device.platformName;
          final aIsBalanza = aName.contains('BalanzaJ&M_BLE') ? 0 : 1;
          final bIsBalanza = bName.contains('BalanzaJ&M_BLE') ? 0 : 1;
          return aIsBalanza.compareTo(bIsBalanza);
        });

        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error escaneando dispositivos BLE: $e'),
            backgroundColor: Colors.red[800], // F-16
          ),
        );
      }
    }
  }

  Future<void> _loadPairedDevices() async {
    await _scanForBLEDevices();
  }

  /// Helper para mostrar el estado de conexión en texto
  String _getStatusText(BluetoothStatus status) {
    switch (status) {
      case BluetoothStatus.disconnected:
        return 'DESCONECTADO';
      case BluetoothStatus.connecting:
        return 'CONECTANDO...';
      case BluetoothStatus.connected:
        return 'CONECTADO';
      case BluetoothStatus.error:
        return 'ERROR DE CONEXIÓN';
    }
  }

  Future<void> _connectToDevice(fbp.ScanResult scanResult) async {
    // Verificar permisos antes de conectar
    final bool hasPermissions =
        await _bluetoothService.checkAndRequestPermissions();
    if (!hasPermissions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Se necesitan permisos de Bluetooth para continuar.'),
            backgroundColor: Colors.red[800], // F-16
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Usar el ScanResult directamente
    bool connected = await _bluetoothService.connect(scanResult);

    if (!mounted) return;
    if (!context.mounted) return;

    Navigator.pop(context);

    final String deviceName = scanResult.device.platformName;
    if (connected) {
      setState(() {
        _connectedDeviceName = deviceName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conectado a $deviceName'),
          backgroundColor: Colors.green[700], // F-16
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error conectando a $deviceName'),
          backgroundColor: Colors.red[800], // F-16
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await _bluetoothService.disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Desconectado'),
          backgroundColor: Colors.blueGrey[600], // F-16
        ),
      );
    }
  }

  // F-16: BUILD METHOD REFACTORIZADO
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _screenshotKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'CONEXIÓN BLUETOOTH', // F-16: MAYÚSCULAS
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5, // F-16
            ),
          ),
          backgroundColor: Colors.blueGrey[800], // F-16: azul militar
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey[400]), // F-16
              onPressed:
                  _bluetoothService.isConnected ? null : _loadPairedDevices,
            ),
            IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.grey[400]), // F-16
              onPressed: () async {
                final Uint8List? bytes =
                    await ScreenshotHelper.captureWidget(_screenshotKey);
                if (bytes != null) {
                  await ScreenshotHelper.sharePng(bytes,
                      filenamePrefix: 'bluetooth');
                } else {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Error al capturar pantalla'),
                      backgroundColor: Colors.red[800], // F-16
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.grey[900], // F-16: fondo oscuro
          child: Column(
            children: <Widget>[
              // F-16: PANEL DE ESTADO
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[850], // F-16: fondo uniforme
                  border: Border(
                    bottom: BorderSide(color: Colors.blueGrey[700]!, width: 1),
                  ),
                ),
                child: ValueListenableBuilder<BluetoothStatus>(
                  valueListenable: _bluetoothService.statusNotifier,
                  builder: (BuildContext context, BluetoothStatus status,
                      Widget? child) {
                    final bool isConnected =
                        status == BluetoothStatus.connected;

                    return Row(
                      children: <Widget>[
                        Icon(
                          isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: isConnected
                              ? Colors.green[700] // F-16: verde militar
                              : Colors.grey[600], // F-16: gris apagado
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isConnected
                                ? 'CONECTADO: $_connectedDeviceName' // F-16: MAYÚSCULAS
                                : _getStatusText(status),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2, // F-16
                              color: isConnected
                                  ? Colors.green[700]
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                        if (isConnected) ...<Widget>[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius:
                                  BorderRadius.circular(4), // F-16: angular
                              border: Border.all(
                                  color: Colors.cyan[700]!, width: 1),
                            ),
                            child: Text(
                              'ADC: $_ultimoADC',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan[700], // F-16: cian militar
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _disconnect,
                            icon:
                                const Icon(Icons.bluetooth_disabled, size: 18),
                            label: const Text(
                              'DESCONECTAR',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red[800], // F-16: rojo oscuro
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(4), // F-16: angular
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              // F-16: LISTA DE DISPOSITIVOS
              Expanded(
                child: _isScanning
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.cyan[700], // F-16
                        ),
                      )
                    : _devices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.bluetooth_searching,
                                  size: 64,
                                  color: Colors.grey[600], // F-16
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'NO HAY DISPOSITIVOS EMPAREJADOS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500], // F-16
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadPairedDevices,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text(
                                    'ACTUALIZAR',
                                    style: TextStyle(
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.blueGrey[700], // F-16
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _devices.length,
                            itemBuilder: (BuildContext context, int index) {
                              fbp.ScanResult scanResult = _devices[index];
                              final String deviceName =
                                  scanResult.device.platformName;
                              final String deviceAddress =
                                  scanResult.device.remoteId.str;
                              bool isCurrentDevice =
                                  _bluetoothService.isConnected &&
                                      _connectedDeviceName == deviceName;
                              bool isBalanza =
                                  deviceName.contains('BalanzaJ&M_BLE');

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.grey[850], // F-16: uniforme
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(
                                    color: isCurrentDevice
                                        ? Colors.green[
                                            700]! // F-16: borde verde si conectado
                                        : isBalanza
                                            ? Colors.cyan[
                                                700]! // F-16: borde cian para BalanzaJ&M_BLE
                                            : Colors.blueGrey[700]!,
                                    width: isCurrentDevice || isBalanza ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.bluetooth,
                                    color: isCurrentDevice
                                        ? Colors
                                            .green[700] // F-16: verde militar
                                        : isBalanza
                                            ? Colors.cyan[700]
                                            : Colors.blueGrey[
                                                600], // F-16: azul grisáceo
                                    size: 32,
                                  ),
                                  title: Text(
                                    deviceName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentDevice
                                          ? Colors.green[700]
                                          : isBalanza
                                              ? Colors.cyan[700]
                                              : Colors.white,
                                      letterSpacing: 0.5,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    deviceAddress,
                                    style: TextStyle(
                                      color: Colors.grey[500], // F-16
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Icon(
                                    isCurrentDevice
                                        ? Icons.check_circle
                                        : Icons.arrow_forward_ios,
                                    color: isCurrentDevice
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                    size: isCurrentDevice ? 24 : 18,
                                  ),
                                  onTap: _bluetoothService.isConnected
                                      ? null
                                      : () => _connectToDevice(scanResult),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _adcSubscription.cancel();
    super.dispose();
  }
}
