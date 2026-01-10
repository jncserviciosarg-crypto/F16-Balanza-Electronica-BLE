# Guía de Uso: Estado Bluetooth Unificado (ETAPA F2.1)

---

## Acceso al Estado

### Opción 1: ValueListenableBuilder (Recomendado para UI)

Reacciona automáticamente a cambios sin necesidad de `setState()`:

```dart
ValueListenableBuilder<BluetoothStatus>(
  valueListenable: _bluetoothService.statusNotifier,
  builder: (BuildContext context, BluetoothStatus status, Widget? child) {
    return Column(
      children: [
        if (status == BluetoothStatus.connected)
          Text('✅ Conectado y recibiendo datos')
        else if (status == BluetoothStatus.connecting)
          Text('⏳ Conectando...')
        else if (status == BluetoothStatus.error)
          Text('❌ Error en conexión')
        else
          Text('⚫ Desconectado'),
      ],
    );
  },
)
```

### Opción 2: Stream Listener (Legacy, sigue funcionando)

```dart
_bluetoothService.statusStream.listen((BluetoothStatus status) {
  debugPrint('Estado cambió a: $status');
});

// O el legacy bool stream:
_bluetoothService.connectionStream.listen((bool connected) {
  debugPrint('Conectado: $connected');
});
```

### Opción 3: Getter Directo (Para consultas puntuales)

```dart
if (_bluetoothService.isConnected) {
  print('Dispositivo conectado');
}

// O acceder al estado enum directamente:
BluetoothStatus estado = _bluetoothService.status;
debugPrint('Estado actual: $estado');
```

---

## Cambios de Estado (Para Desarrolladores)

El servicio maneja automáticamente los cambios, pero para referencia:

### Ciclo de Conexión

```
disconnected
    ↓
    connect() llamado
    ↓
connecting
    ↓
  ✓ Conexión exitosa
    ↓
connected
    ↓
  × Dispositivo se desconecta / error
    ↓
disconnected


  ✗ Falla en conexión
    ↓
  error
    ↓
disconnect() llamado
    ↓
disconnected
```

### Casos de Transición de Estado

```dart
// 1. Conexión exitosa
connecting → connected
// Ocurre cuando: BluetoothConnection.toAddress() retorna válido
// y se inicializa input stream

// 2. Fallo en conexión
connecting → error
// Ocurre cuando: BluetoothConnection.toAddress() retorna null
// o lanza excepción

// 3. Desconexión detectada
connected → disconnected
// Ocurre cuando: input stream cierra (onDone)
// o hay error (onError)

// 4. Desconexión manual
connected → disconnected
// Ocurre cuando: usuario llama a disconnect()
```

---

## Ejemplos Prácticos

### Ejemplo 1: Mostrar diferentes UI según estado

```dart
@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<BluetoothStatus>(
    valueListenable: bluetoothService.statusNotifier,
    builder: (context, status, _) {
      return Scaffold(
        body: Center(
          child: switch (status) {
            BluetoothStatus.disconnected => 
              _buildDisconnectedUI(),
            BluetoothStatus.connecting => 
              _buildConnectingUI(),
            BluetoothStatus.connected => 
              _buildConnectedUI(),
            BluetoothStatus.error => 
              _buildErrorUI(),
          },
        ),
      );
    },
  );
}

Widget _buildConnectingUI() => Column(
  children: [
    CircularProgressIndicator(),
    SizedBox(height: 16),
    Text('Conectando al dispositivo...'),
  ],
);

Widget _buildConnectedUI() => Column(
  children: [
    Icon(Icons.bluetooth_connected, color: Colors.green),
    Text('Conectado correctamente'),
  ],
);
```

### Ejemplo 2: Habilitar/Deshabilitar botones según estado

```dart
ElevatedButton(
  onPressed: bluetoothService.isConnected ? null : () {
    // Conectar
    bluetoothService.connect(deviceAddress);
  },
  child: const Text('CONECTAR'),
)
```

### Ejemplo 3: Mostrar indicador de carga durante conexión

```dart
ValueListenableBuilder<BluetoothStatus>(
  valueListenable: bluetoothService.statusNotifier,
  builder: (context, status, _) {
    final isConnecting = status == BluetoothStatus.connecting;
    
    return Row(
      children: [
        if (isConnecting)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            status == BluetoothStatus.connected 
              ? Icons.check_circle 
              : Icons.close,
          ),
        SizedBox(width: 8),
        Text(_getStatusText(status)),
      ],
    );
  },
)
```

### Ejemplo 4: Logging de cambios de estado

```dart
// En initState
@override
void initState() {
  super.initState();
  
  bluetoothService.statusStream.listen((status) {
    debugPrint('[BT] Estado: $status');
  });
}
```

### Ejemplo 5: Integración con WeightService (sin cambios necesarios)

```dart
// WeightService ya funciona sin cambios
// Sigue usando adcStream como antes
_adcSubscription = _bluetoothService.adcStream.listen((int adc) {
  _ultimoADC = adc;
  // Procesar ADC normalmente
});
```

---

## Migrando Código Existente

### Patrón Antiguo (aún funciona)

```dart
// Antes - usando StreamController<bool>
_bluetoothService.connectionStream.listen((bool connected) {
  setState(() {
    _isConnected = connected;
  });
});
```

### Patrón Nuevo (Recomendado)

```dart
// Después - usando ValueListenableBuilder
// ✅ Sin setState(), sin duplicación de estado
ValueListenableBuilder<BluetoothStatus>(
  valueListenable: _bluetoothService.statusNotifier,
  builder: (context, status, child) {
    final isConnected = status == BluetoothStatus.connected;
    // Usar isConnected directamente
    return Text(isConnected ? 'Conectado' : 'Desconectado');
  },
)
```

---

## Performance Tips

### ✅ Recomendado

```dart
// 1. Usar ValueListenableBuilder para UI declarativa
ValueListenableBuilder<BluetoothStatus>(
  valueListenable: bluetoothService.statusNotifier,
  builder: (context, status, child) { ... }
)

// 2. Guardar subscripciones y cancelarlas
StreamSubscription? _sub;

@override
void initState() {
  _sub = bluetoothService.statusStream.listen((_) { ... });
}

@override
void dispose() {
  _sub?.cancel();
  super.dispose();
}

// 3. Usar `child` parameter para evitar rebuilds innecesarios
ValueListenableBuilder<BluetoothStatus>(
  valueListenable: bluetoothService.statusNotifier,
  child: const ExpensiveWidget(),  // ← No se reconstruye
  builder: (context, status, child) {
    return Column(
      children: [
        Text(status.toString()),
        child,  // ← Reutilizado
      ],
    );
  },
)
```

### ❌ No Recomendado

```dart
// No usar setState() dentro de listeners
bluetoothService.statusStream.listen((status) {
  setState(() { _isConnected = status == BluetoothStatus.connected; });
  // ← Causa reconstrucción innecesaria de todo el widget
});

// No acceder al notifier dentro de build() sin ValueListenableBuilder
build() {
  return Text(bluetoothService.statusNotifier.value.toString());
  // ← No reacciona a cambios automáticamente
}
```

---

## Estados Disponibles

```dart
enum BluetoothStatus {
  disconnected,  // UI: "DESCONECTADO", Color: gris
  connecting,    // UI: "CONECTANDO...", Color: gris con animación
  connected,     // UI: "CONECTADO", Color: verde
  error,         // UI: "ERROR DE CONEXIÓN", Color: rojo
}
```

### Colores Sugeridos

```dart
final statusColor = switch (status) {
  BluetoothStatus.disconnected => Colors.grey[600],
  BluetoothStatus.connecting => Colors.yellow[700],
  BluetoothStatus.connected => Colors.green[700],
  BluetoothStatus.error => Colors.red[800],
};

final statusIcon = switch (status) {
  BluetoothStatus.disconnected => Icons.bluetooth_disabled,
  BluetoothStatus.connecting => Icons.hourglass_empty,
  BluetoothStatus.connected => Icons.bluetooth_connected,
  BluetoothStatus.error => Icons.bluetooth_disabled,
};
```

---

## Testing

### Simular Cambios de Estado

```dart
void testBluetoothStateChanges() {
  final service = BluetoothService();
  
  // Verificar estado inicial
  expect(service.status, equals(BluetoothStatus.disconnected));
  
  // Conectar (el estado cambia a connecting → connected)
  service.connect('AA:BB:CC:DD:EE:FF');
  
  // Escuchar cambios
  var states = <BluetoothStatus>[];
  service.statusStream.listen((status) => states.add(status));
  
  // Verificar que el notifier emite eventos
  expect(service.statusNotifier.value, isNotNull);
}
```

### Widget Test

```dart
testWidgets('Status indicator updates on connection', (WidgetTester tester) {
  final mockService = MockBluetoothService();
  
  await tester.pumpWidget(
    MaterialApp(
      home: MyBluetoothWidget(service: mockService),
    ),
  );
  
  expect(find.text('DESCONECTADO'), findsOneWidget);
  
  mockService.updateStatus(BluetoothStatus.connecting);
  await tester.pump();
  
  expect(find.text('CONECTANDO...'), findsOneWidget);
  
  mockService.updateStatus(BluetoothStatus.connected);
  await tester.pump();
  
  expect(find.text('CONECTADO'), findsOneWidget);
});
```

---

## Debugging

### Habilitar Logging de Estado

```dart
// En BluetoothService o en initState de la pantalla
bluetoothService.statusStream.listen((status) {
  debugPrint('[BT_STATE] $status at ${DateTime.now()}');
});
```

### Verificar Estado Actual

```dart
debugPrint('Estado actual: ${bluetoothService.status}');
debugPrint('¿Conectado? ${bluetoothService.isConnected}');
debugPrint('Notifier value: ${bluetoothService.statusNotifier.value}');
```

### Monitorear Cambios de Estado

```dart
@override
void initState() {
  super.initState();
  bluetoothService.statusStream.listen((status) {
    print('>>> Estado BT: $status');
  });
}
```

---

## Compatibilidad Hacia Atrás

### Métodos que siguen siendo válidos

```dart
// Estos getters siguen funcionando
bool isConnected = bluetoothService.isConnected;

// Este stream sigue siendo válido (mapea a bool automáticamente)
Stream<bool> stream = bluetoothService.connectionStream;

// Acceso directo al enum
BluetoothStatus status = bluetoothService.status;

// Para ValueListenableBuilder
ValueNotifier<BluetoothStatus> notifier = bluetoothService.statusNotifier;
```

---

## FAQ

**P: ¿Necesito cambiar WeightService?**  
R: No, sigue usando `adcStream` como antes.

**P: ¿Que pasa si sigo usando `connectionStream`?**  
R: Funciona, pero se recomienda migrar a `statusStream` para aprovechar más información.

**P: ¿Cómo muestro "Conectando" mientras se intenta conectar?**  
R: Usa el estado `BluetoothStatus.connecting` dentro de ValueListenableBuilder.

**P: ¿Se puede cancelar una conexión que está conectando?**  
R: Sí, llama a `disconnect()` en cualquier momento.

**P: ¿Qué diferencia hay entre `error` y `disconnected`?**  
R: `error` indica que hubo un problema en la conexión, `disconnected` es estado normal sin conexión.

---

**Documentación de uso completada para ETAPA F2.1**
