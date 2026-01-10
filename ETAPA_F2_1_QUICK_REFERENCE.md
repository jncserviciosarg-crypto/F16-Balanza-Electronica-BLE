# ETAPA F2.1 — Referencia Rápida

## Estado Bluetooth Unificado

### Estados Disponibles

```
┌─────────────────┬────────────────────┬─────────┐
│     Estado      │   Descripción      │  Color  │
├─────────────────┼────────────────────┼─────────┤
│ disconnected    │ Sin conexión        │  Gris   │
│ connecting      │ Conectando...       │ Gris    │
│ connected       │ Conectado           │ Verde   │
│ error           │ Error de conexión   │ Rojo    │
└─────────────────┴────────────────────┴─────────┘
```

### APIs Principales

| Método | Tipo | Descripción |
|---|---|---|
| `statusNotifier` | `ValueNotifier<BluetoothStatus>` | Para ValueListenableBuilder (recomendado) |
| `statusStream` | `Stream<BluetoothStatus>` | Stream del nuevo estado enum |
| `connectionStream` | `Stream<bool>` | Stream legacy (sigue funcionando) |
| `status` | `BluetoothStatus` | Getter del estado actual |
| `isConnected` | `bool` | Getter true si estado == connected |
| `connect(address)` | `Future<bool>` | Conectar a dispositivo |
| `disconnect()` | `Future<void>` | Desconectar |

### Uso Recomendado

#### Para UI (Sin setState)

```dart
ValueListenableBuilder<BluetoothStatus>(
  valueListenable: _bluetoothService.statusNotifier,
  builder: (context, status, child) {
    return switch (status) {
      BluetoothStatus.disconnected => _buildDisconnected(),
      BluetoothStatus.connecting => _buildConnecting(),
      BluetoothStatus.connected => _buildConnected(),
      BluetoothStatus.error => _buildError(),
    };
  },
)
```

#### Para Consultas Puntuales

```dart
if (_bluetoothService.isConnected) {
  // Hacer algo
}

BluetoothStatus estado = _bluetoothService.status;
```

#### Para Listeners

```dart
_statusSubscription = _bluetoothService.statusStream.listen((status) {
  debugPrint('Estado: $status');
});

// No olvidar cancelar en dispose()
_statusSubscription.cancel();
```

### Cambios Clave

#### BluetoothService

- ✅ Nuevo enum `BluetoothStatus` con 4 estados
- ✅ `ValueNotifier<BluetoothStatus>` como única fuente de verdad
- ✅ Getters para acceso: `status`, `isConnected`, `statusNotifier`
- ✅ Streams compatibles: `statusStream` (nuevo), `connectionStream` (legacy)

#### BluetoothScreen

- ✅ Eliminada variable duplicada `_isConnected`
- ✅ ValueListenableBuilder para reactividad automática
- ✅ Subscripciones guardadas y canceladas en dispose()
- ✅ Muestra estado "CONECTANDO..." mientras se conecta
- ✅ Sin memory leaks

### Flujo de Conexión

```
disconnected
    ↓
connect() → connecting
    ↓
(conexión exitosa)
    ↓
    connected
    ↓
    (desconexión/error)
    ↓
    disconnected
    
(conexión falla)
    ↓
    error
    ↓
    disconnect()
    ↓
    disconnected
```

### Checklist de Migración (Si necesario)

- [ ] Eliminar variables duplicadas como `bool _isConnected`
- [ ] Reemplazar StreamController listeners con ValueListenableBuilder
- [ ] Guardar subscripciones en variables (`late StreamSubscription`)
- [ ] Cancelar subscripciones en dispose()
- [ ] Usar `_bluetoothService.statusNotifier` en ValueListenableBuilder
- [ ] Cambiar listeners a `statusStream` (no `connectionStream`)
- [ ] Probar todos los estados: disconnected, connecting, connected, error

### Antes vs Después

| Aspecto | Antes | Después |
|---|---|---|
| **Fuente de estado** | bool + StreamController | ValueNotifier<enum> |
| **UI Reactividad** | setState() requerido | Automático |
| **Estados posibles** | true/false (2) | disconnected/connecting/connected/error (4) |
| **Memory Leaks** | Posible | Prevenido |
| **Feedback visual** | No hay estado intermedio | "Conectando..." visible |
| **Compatibilidad** | N/A | 100% backward compatible |

### Ejemplos Rápidos

**Mostrar icon según estado:**
```dart
Icon(
  switch (status) {
    BluetoothStatus.disconnected => Icons.bluetooth_disabled,
    BluetoothStatus.connecting => Icons.hourglass_empty,
    BluetoothStatus.connected => Icons.bluetooth_connected,
    BluetoothStatus.error => Icons.bluetooth_disabled,
  },
  color: switch (status) {
    BluetoothStatus.disconnected => Colors.grey[600],
    BluetoothStatus.connecting => Colors.yellow[700],
    BluetoothStatus.connected => Colors.green[700],
    BluetoothStatus.error => Colors.red[800],
  },
)
```

**Deshabilitar botón si conectado:**
```dart
ElevatedButton(
  onPressed: _bluetoothService.isConnected ? null : _connectar,
  child: const Text('CONECTAR'),
)
```

**Logger de cambios:**
```dart
_bluetoothService.statusStream.listen((status) {
  print('[BT] $status');
});
```

### Archivos Modificados

| Archivo | Líneas | Cambios |
|---|---|---|
| `bluetooth_service.dart` | 1-50, 130-160, 190-200 | Enum, ValueNotifier, getters, lógica |
| `bluetooth_screen.dart` | 1-50, 140-150, 200-320, 440-450 | ValueListenableBuilder, subscripciones |

### Verificación Final

✅ Compilación sin errores  
✅ No hay cambios en lógica de conexión  
✅ No hay cambios en flujos de datos (ADC)  
✅ Backward compatible con código existente  
✅ Memory leaks prevenidos  
✅ Estados visuales mejorados  

---

**Para detalles completos, ver:**
- `ETAPA_F2_1_IMPLEMENTATION.md` — Cambios detallados
- `ETAPA_F2_1_USAGE_GUIDE.md` — Guía completa de uso
