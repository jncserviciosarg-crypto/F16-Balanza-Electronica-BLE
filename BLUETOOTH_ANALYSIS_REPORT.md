# Análisis Técnico: Gestión de Conexión Bluetooth en F16 Balanza Electrónica

**Fecha:** 10 de enero de 2026  
**Versión del Proyecto:** v1.0.0 Firmada  
**Estado:** Análisis (SIN Modificaciones)

---

## 1. Arquitectura de Creación y Mantenimiento de Conexión Bluetooth

### 1.1 Estructura de Clases

```
┌─────────────────────────────────────────────────────────────┐
│                     BLUETOOTH SERVICE LAYER                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────┐         ┌──────────────────────┐  │
│  │  BluetoothService    │         │  BluetoothAdapter    │  │
│  │  (Singleton)         │◄────────│  (Interface)         │  │
│  ├──────────────────────┤         ├──────────────────────┤  │
│  │ _connection          │         │ getBondedDevices()   │  │
│  │ _isConnected: bool   │         │ isBluetoothEnabled() │  │
│  │ _buffer: String      │         │ connectToAddress()   │  │
│  │ _ultimoADC: int      │         │ requestEnable()      │  │
│  ├──────────────────────┤         └──────────────────────┘  │
│  │ connect(address)     │                    ▲               │
│  │ disconnect()         │                    │               │
│  │ _onDataReceived()    │         ┌──────────┴──────────┐   │
│  │ _handleDisconnection│         │FlutterBluetoothSerial│   │
│  │ _processData()       │         │     Adapter          │   │
│  └──────────────────────┘         └──────────────────────┘   │
│         ▲                                                      │
│         │ Singleton Pattern                                   │
│         └─────────────────────────────────────────────────┐   │
│                                                           │   │
│  ┌─────────────────────────────────────────────────────┐ │   │
│  │              CONSUMERS (Listeners)                  │ │   │
│  ├─────────────────────────────────────────────────────┤ │   │
│  │ • BluetoothScreen     (UI de conexión)              │ │   │
│  │ • WeightService       (Lectura ADC)                 │ │   │
│  └─────────────────────────────────────────────────────┘ │   │
│                                                           │   │
└───────────────────────────────────────────────────────────┘   │
```

### 1.2 Clases Principales

#### **`BluetoothService` (lib/services/bluetooth_service.dart)**

**Responsabilidades:**
- Singleton que mantiene la única conexión Bluetooth activa
- Gestión del ciclo de vida de la conexión
- Emisión de eventos de conexión/desconexión
- Procesamiento de datos ADC recibidos

**Propiedades clave:**
```dart
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  
  BluetoothConnection? _connection;          // Socket activo
  bool _isConnected = false;                 // Estado actual
  String _buffer = '';                       // Buffer para líneas ADC
  int _ultimoADC = 0;                        // Último valor parseado
  
  final StreamController<bool> _connectionController;      // Estado de conexión
  final StreamController<int> _adcController;              // Valores ADC
}
```

**Métodos públicos:**
- `checkAndRequestPermissions()` → Verifica/pide permisos (Android 12+, 11-)
- `isBluetoothEnabled()` → Consulta si Bluetooth está activo
- `requestEnable()` → Solicita al usuario habilitar Bluetooth
- `getPairedDevices()` → Retorna lista de dispositivos emparejados
- `connect(String address)` → Inicia conexión a dispositivo
- `disconnect()` → Cierra conexión activa
- `get isConnected` → Retorna estado actual
- `get connectionStream` → Stream de eventos `bool` (conectado/desconectado)
- `get adcStream` → Stream de eventos `int` (valores ADC)

#### **`BluetoothAdapter` (lib/services/bluetooth_adapter.dart)**

**Tipo:** Interface abstracta (patrón Adapter)

**Implementación:** `FlutterBluetoothSerialAdapter`

**Propósito:** Desacoplar `BluetoothService` de `flutter_bluetooth_serial` para permitir cambios futuros a `flutter_blue_plus`

---

## 2. Determinación del Estado de Conexión

### 2.1 Mecanismo Actual

El estado de conexión se determina mediante **dos canales diferentes** que pueden diverger:

#### **Canal 1: Variable Local `_isConnected` en BluetoothService**

```dart
// Ubicación: lib/services/bluetooth_service.dart

bool _isConnected = false;
bool get isConnected => _isConnected;

// Se actualiza en:
1. connect() {
   _isConnected = true;                           // Línea 136
   _connectionController.add(true);
}

2. _handleDisconnection() {
   _isConnected = false;                          // Línea 192
   _connectionController.add(false);
}
```

#### **Canal 2: Stream `connectionStream` de Eventos**

```dart
final StreamController<bool> _connectionController = 
    StreamController<bool>.broadcast();

Stream<bool> get connectionStream => _connectionController.stream;

// Emite:
// - true  : cuando _isConnected cambia a true en connect()
// - false : cuando se detecta desconexión en _handleDisconnection()
```

#### **Canal 3: Stream de Entrada (Implícito)**

```dart
// En connect():
_connection?.input?.listen(
  _onDataReceived,
  onDone: () {
    _handleDisconnection();    // Desconexión detectada por cierre de stream
  },
  onError: (error) {
    debugPrint('Error en conexión: $error');
    _handleDisconnection();    // Error detecta desconexión
  },
);
```

### 2.2 Flujo de Cambios de Estado

```
┌─────────────────────────────────────────────────────────────┐
│                    ESTADO: DESCONECTADO                      │
│  _isConnected = false, stream = false                        │
└──────────────┬──────────────────────────────────────────────┘
               │
               │ Usuario toca "Conectar" a dispositivo XXX
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│                    FUNCIÓN: connect()                        │
├─────────────────────────────────────────────────────────────┤
│ 1. Si ya conectado → disconnect() primero                   │
│ 2. conn = BluetoothConnection.toAddress(address)            │
│ 3. _isConnected = true      ◄─── CAMBIO INMEDIATO          │
│ 4. _connectionController.add(true)  ◄─── EMITE EVENTO      │
│ 5. Suscribe a _connection.input.listen()                   │
│    • onData: _onDataReceived()     (parsa ADC)             │
│    • onDone: _handleDisconnection()  (detecta cierre)      │
│    • onError: _handleDisconnection() (detecta error)       │
└──────────────┬──────────────────────────────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
    ▼                     ▼
 FLUJO OK            FLUJO ERROR
    │                     │
    │ Se reciben datos    │ No hay respuesta
    │ _onDataReceived()   │ del dispositivo
    │                     │
    ▼                     ▼
 (Sistema OK)      onError: detecta
                   → _handleDisconnection()
                   _isConnected = false
                   stream = false
```

### 2.3 Determinación de Desconexión

**La desconexión se detecta por:**

1. **Cierre del stream de entrada** (`onDone`)
   ```dart
   _connection?.input?.listen(
     ...,
     onDone: () => _handleDisconnection(),
   );
   ```

2. **Error en el stream de entrada** (`onError`)
   ```dart
   onError: (error) {
     debugPrint('Error en conexión: $error');
     _handleDisconnection();
   }
   ```

3. **Llamada explícita a `disconnect()`**
   ```dart
   Future<void> disconnect() async {
     await _connection?.close();
     _handleDisconnection();
   }
   ```

**NO se detecta automáticamente:**
- ❌ Dispositivo apagado sin cerrar el socket
- ❌ Pérdida de conexión por interferencia de RF
- ❌ Timeout de inactividad
- ❌ Desconexión desde el lado del dispositivo sin cierre de socket

---

## 3. Pantallas que Leen/Modifican el Estado de Conexión

### 3.1 Consumidores Directos

#### **1. BluetoothScreen** (lib/screens/bluetooth_screen.dart) - **PRIMARY**

**Responsabilidad:** Interfaz de usuario para gestionar conexión Bluetooth

**Variable de estado local:**
```dart
class _BluetoothScreenState extends State<BluetoothScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  bool _isConnected = false;              // Copia local del estado
  String? _connectedDeviceName;           // Nombre del dispositivo conectado
}
```

**Listeners establecidos en `initState()`:**
```dart
// Escuchar cambios de conexión
_bluetoothService.connectionStream.listen((bool connected) {
  if (mounted) {
    setState(() {
      _isConnected = connected;
      if (!connected) {
        _connectedDeviceName = null;
      }
    });
  }
});

// Escuchar valores ADC
_bluetoothService.adcStream.listen((int adc) {
  if (mounted) {
    setState(() {
      _ultimoADC = adc;
    });
  }
});
```

**Acciones que modifican estado:**
```dart
// 1. Conectar a dispositivo
Future<void> _connectToDevice(BluetoothDevice device) async {
  bool connected = await _bluetoothService.connect(device.address);
  // ... actualiza _isConnected en BluetoothService
}

// 2. Desconectar
Future<void> _disconnect() async {
  await _bluetoothService.disconnect();
  // ... estado se propaga vía stream
}
```

**Elementos UI que dependen del estado:**
- Icono de conexión (verde si conectado, gris si desconectado)
- Texto "CONECTADO" / "DESCONECTADO"
- Botón "ACTUALIZAR" (deshabilitado si conectado)
- Botón "DESCONECTAR" (visible solo si conectado)
- Panel de ADC (visible solo si conectado)
- Lista de dispositivos (deshabilitada si conectado)

---

#### **2. HomeScreen** (lib/screens/home_screen.dart) - **INDIRECT**

**Responsabilidad:** Pantalla principal de pesaje

**Conexión Bluetooth:** **INDIRECTA** (a través de `WeightService`)

```dart
class _HomeScreenState extends State<HomeScreen> {
  final WeightService _weightService = WeightService();
  
  // NO tiene acceso directo a BluetoothService
  // NO suscribe directamente a connectionStream
  
  // Solo escucha:
  _weightService.weightStateStream  // Estado del peso procesado
  _weightService.configStream       // Configuración de celdas
}
```

**¿Sabe que está desconectado?** 
- ✅ Indirectamente: si recibe valores ADC = 0 → peso = 0
- ❌ No directamente: NO consulta el estado de Bluetooth

**Impacto:** La UI principal no refleja visualmente el estado de Bluetooth

---

#### **3. WeightService** (lib/services/weight_service.dart) - **CONSUMER**

**Responsabilidad:** Procesamiento de valores ADC y cálculo de peso

**Conexión a Bluetooth:**
```dart
class WeightService {
  final BluetoothService _bluetoothService = BluetoothService();
  
  void start() {
    // Suscribe a ADC stream
    _adcSubscription = _bluetoothService.adcStream.listen((int adc) {
      _ultimoADC = adc;
    });
    
    // Inicia timer de procesamiento cada 100ms
    _processingTimer = Timer.periodic(
      Duration(milliseconds: _updateIntervalMs),
      (Timer timer) => _processData(),
    );
  }
}
```

**¿Sabe si está conectado?**
- ❌ NO: No suscribe a `connectionStream`
- ⚠️ Implícitamente: Si `_ultimoADC == 0` → sin datos

**Impacto:** Emite valores de peso pero no diferencia entre "sin conexión" y "dispositivo lectora por escala"

---

### 3.2 Matriz de Dependencias

| Pantalla/Servicio | Lee `connectionStream` | Lee `isConnected` | Lee `adcStream` | Modifica Estado |
|---|:---:|:---:|:---:|:---:|
| **BluetoothScreen** | ✅ | ❌ | ✅ | ✅ |
| **HomeScreen** | ❌ | ❌ | ❌ | ❌ |
| **WeightService** | ❌ | ❌ | ✅ | ❌ |
| **CalibrationScreen** | ? | ? | ? | ? |
| **ConfigScreen** | ? | ? | ? | ? |

---

## 4. Análisis de Problemas Reportados

### Problema 1: UI muestra "DESCONECTADO" estando conectado

#### 4.1.1 Causas Posibles

**A) Desincronización entre Estado Real y UI Local**

```
Estado Real (BluetoothService)         Estado UI Local (BluetoothScreen)
_isConnected = true ✅                 _isConnected = false ❌
Stream emitió: true
                     ↓
                  Widget not mounted?
                  setState() no ejecutado
                  _isConnected permanece false
```

**Localización del problema:**
```dart
// lib/screens/bluetooth_screen.dart, línea 30
_bluetoothService.connectionStream.listen((bool connected) {
  if (mounted) {  // ← Si mounted = false, no se ejecuta
    setState(() {
      _isConnected = connected;  // ← No se actualiza
    });
  }
});
```

**Escenarios:**
1. ✅ Conexión exitosa → `_isConnected = true` en BluetoothService
2. ✅ Stream emite `true`
3. ❌ Si `mounted == false` (widget destruido) → `setState()` no se ejecuta
4. ❌ UI muestra estado anterior: "DESCONECTADO"
5. ⚠️ Si el usuario vuelve a la pantalla Bluetooth → Stream no re-emite (broadcast cacheado)

---

**B) Conexión Exitosa pero Input Stream no Inicializado**

```dart
// lib/services/bluetooth_service.dart, línea 142
final BluetoothConnection? conn = await _adapter.connectToAddress(address);
_connection = conn;
_isConnected = true;  // ← Se marca como conectado
_connectionController.add(true);  // ← Se emite evento

// PERO si conn == null → _connection.input será null
_connection?.input?.listen(
  _onDataReceived,
  onDone: () => _handleDisconnection(),  // Nunca se ejecuta porque input es null
  onError: (error) => _handleDisconnection(),
);
```

**Escenario:**
- Biblioteca `flutter_bluetooth_serial` retorna `BluetoothConnection` válido pero sin stream de entrada
- `_isConnected = true` se marca inmediatamente
- No se reciben eventos de desconexión (onDone/onError)
- Dispositivo apagado → Socket se queda pendiente indefinidamente

---

**C) Dispositivo Desconectado Mientras Widget estaba Destruido**

```
T0: Usuario conectado, BluetoothScreen abierto
    _isConnected = true, UI = "CONECTADO"

T1: Usuario navega a otra pantalla
    BluetoothScreen.dispose() → Cancela subscripciones
    BluetoothScreen._buildcontext ya no es válido

T2: Dispositivo se desconecta
    _handleDisconnection() ejecuta
    _connectionController.add(false)
    ← Pero nadie está escuchando (BluetoothScreen fue destruido)

T3: Usuario vuelve a BluetoothScreen
    initState() suscribe a connectionStream nuevamente
    ← Pero stream NO re-emite false (ya emitió, es histórico)
    UI muestra estado anterior: "CONECTADO"
```

**Raíz:** 
- `StreamController<bool>.broadcast()` emite eventos en tiempo real
- No re-emite eventos anteriores cuando se suscribe nuevamente
- La UI no sincroniza con el estado actual al montar

---

**D) Missing Widget Disposal/Cleanup**

```dart
// lib/screens/bluetooth_screen.dart, línea 439
@override
void dispose() {
  super.dispose();
  // ← NO cancela las subscripciones
  // _bluetoothService.connectionStream.listen() no se cancela
}
```

**Impacto:**
- Memory leaks
- Listeners fantasma activos
- setState() invocados después de dispose()

---

### Problema 2: Reporte de conexión a dispositivos apagados

#### 4.2.1 Causas Posibles

**A) No Hay Verificación de Actividad (Keep-Alive Check)**

```dart
// lib/services/bluetooth_service.dart

Future<bool> connect(String address) async {
  try {
    final BluetoothConnection? conn = await _adapter.connectToAddress(address);
    _connection = conn;
    _isConnected = true;           // ← SE MARCA COMO CONECTADO INMEDIATAMENTE
    _connectionController.add(true);
    
    // ← NO hay ping/keep-alive para verificar que el dispositivo responde
    
    return true;
  } catch (e) {
    _isConnected = false;
    _connectionController.add(false);
    return false;
  }
}
```

**Escenario:**
1. Dispositivo está en lista de emparejados pero **ESTÁ APAGADO**
2. `BluetoothConnection.toAddress()` **NO valida que el dispositivo esté activo**
3. La conexión se "establece" a nivel de socket pero el dispositivo no responde
4. Aplicación marca como `_isConnected = true`
5. Usuario ve "CONECTADO" pero no recibe datos ADC

---

**B) Socket Establece Handshake pero Dispositivo Apagado Después**

**Protocolo SPP (Serial Port Profile):**
- Bluetooth classic (no BLE) es asincrónico
- El socket puede establecer una conexión L2CAP
- Pero el dispositivo puede apagarse DESPUÉS de aceptar la conexión
- El socket no se cierra inmediatamente (sin keep-alive)

```
T0: Dispositivo enciende
    MAC conocido, emparejado
    
T1: App solicita conexión
    BluetoothConnection.toAddress() → conecta
    
T2: Dispositivo se apaga mientras socket está activo
    
T3: App intenta leer
    _connection.input → Stream sigue abierto
    input.listen onError se dispara después de timeout (~30s)
    
T4: Finalmente detecta desconexión
    _handleDisconnection()
    _isConnected = false
```

**Problema:** Entre T2 y T4, la UI muestra "CONECTADO" pero sin datos

---

**C) Flutter Bluetooth Serial Fork: Detección Deficiente de Desconexión**

```dart
// third_party/flutter_bluetooth_serial_fork/lib/BluetoothConnection.dart

class _ConnectionThread extends Thread {
  void run() {
    // Stream de entrada
    while (isConnected) {
      try {
        // Lectura bloqueante desde inputStream
        byte = inputStream.read();  // ← Puede no detectar dispositivo apagado
        // Envía a listeners
      } catch (e) {
        isConnected = false;  // ← Solo se detecta si hay excepción
        onError(e);
      }
    }
  }
}
```

**Limitación:**
- Java InputStream.read() es bloqueante
- Si el socket no envía error explícitamente, el read() se queda esperando
- Algunos dispositivos apagados mantienen el socket abierto sin cerrar
- Se requiere un timeout para detectar inactividad

---

**D) ADC = 0 no Implica Desconexión**

```dart
// lib/services/weight_service.dart

void _processData() {
  if (_ultimoADC == 0) return;  // ← Si el dispositivo envía "0", se ignora
  
  // Procesamiento normal
}
```

**Escenario:**
- Dispositivo apagado pero socket aún activo
- No se reciben datos ADC (o se reciben zeros)
- Sistema no diferencia entre "sin conexión" y "lectora en cero"
- UI no cambia porque _ultimoADC = 0 es un valor válido

---

**E) Falta de Heartbeat/Ping Periódico**

**No existe en código actual:**

```dart
// ❌ NO EXISTE
Future<void> _sendHeartbeat() async {
  _connection?.output.add([0xFF]);  // Ejemplo: ping
}

// ❌ NO EXISTE
Timer? _heartbeatTimer;
```

**Impacto:**
- No hay mecanismo de keep-alive
- No se valida que el dispositivo responda
- Un socket puede estar "conectado" pero inactivo indefinidamente

---

## 5. Matriz de Riesgos

| Factor de Riesgo | Severidad | Causa Probable | Indicador |
|---|---|---|---|
| **Conexión exitosa a dispositivo apagado** | 🔴 CRÍTICA | No hay verify handshake | Socket se abre pero sin datos |
| **UI muestra "Conectado" pero no procesa datos** | 🔴 CRÍTICA | Stream de entrada nunca emite error | Timeout del SO (30s+) |
| **UI no actualiza al volver a la pantalla Bluetooth** | 🟠 ALTA | Stream broadcast no re-emite | Desconexión ocurre con screen destruido |
| **Memory leak en listeners** | 🟠 ALTA | dispose() no cancela streams | Múltiples listeners fantasma |
| **ADC = 0 confunde conexión con peso real** | 🟡 MEDIA | Lógica de negocio no diferencia | Sistema reporta peso = 0 kg cuando desconectado |
| **No se detecta desconexión inmediata** | 🟡 MEDIA | Timeout del SO | Tarda 20-30 segundos en detectarse |

---

## 6. Recomendaciones de Diagnóstico (Sin Cambios)

Para validar las causas, implementar logging:

### 6.1 Puntos de Observación

```dart
// 1. BluetoothService.connect()
debugPrint('BLUETOOTH: Conectando a $address');
debugPrint('BLUETOOTH: Conn resultó null? ${conn == null}');
debugPrint('BLUETOOTH: input stream null? ${conn?.input == null}');

// 2. BluetoothService._onDataReceived()
debugPrint('BLUETOOTH: Datos recibidos: $incoming');

// 3. BluetoothService._handleDisconnection()
debugPrint('BLUETOOTH: DESCONEXIÓN DETECTADA');
debugPrint('BLUETOOTH: Causa: [onDone/onError/manual]');

// 4. BluetoothScreen.initState()
debugPrint('UI: BluetoothScreen montado, estado actual: $_isConnected');

// 5. BluetoothScreen listener
debugPrint('UI: Stream emitió: $connected, mounted=$mounted');
```

### 6.2 Pruebas Recomendadas

1. **Conexión a dispositivo apagado:**
   - Emparejar dispositivo
   - Apagar dispositivo
   - Intentar conectar desde UI
   - ✓ Debería fallar dentro de 5s
   - ✗ Si muestra "CONECTADO", confirma problema

2. **Dispositivo se apaga durante conexión:**
   - Conectar y esperar a recibir datos
   - Apagar dispositivo
   - Medir tiempo hasta "DESCONECTADO" en UI
   - ✓ Debería detectarse < 30s
   - ✗ Si tarda más, confirma timeout del SO

3. **Navegación con dispositivo desconectado:**
   - Conectar
   - Navegar a otra pantalla
   - Desde shell: `adb shell "rfcomm release 0"` (forzar desconexión)
   - Volver a BluetoothScreen
   - ✓ Debería mostrar "DESCONECTADO"
   - ✗ Si muestra "CONECTADO", confirma problema de sync

---

## 7. Estructura de Archivos Afectados

```
lib/
├── services/
│   ├── bluetooth_service.dart          [CORE - Gestión conexión]
│   ├── bluetooth_adapter.dart          [CORE - Interface abstracción]
│   ├── bluetooth_adapter_test_usage.dart   [TEST - No usado]
│   └── weight_service.dart             [CONSUMER - Lectura ADC]
│
├── screens/
│   ├── bluetooth_screen.dart           [UI - Conexión/Desconexión]
│   └── home_screen.dart                [UI - Procesamiento peso]
│
└── main.dart                           [Inicializador app]

third_party/
└── flutter_bluetooth_serial_fork/      [BIBLIOTECA - Capa baja]
    ├── BluetoothConnection.dart
    ├── BluetoothDevice.dart
    └── FlutterBluetoothSerial.dart
```

---

## 8. Resumen Ejecutivo

### Estado Actual

**✅ Funciona correctamente para:**
- Conexión exitosa a dispositivos activos
- Recepción y procesamiento de datos ADC
- Desconexión manual limpia

**❌ Problemas identificados:**

1. **No valida que el dispositivo esté realmente activo** (apagado reportado como conectado)
2. **Sin keep-alive/heartbeat** para mantener socket vivo
3. **Sin sincronización de estado** cuando la UI se destruye/recrea
4. **Memory leaks** en listeners no cancelados
5. **No diferencia entre desconexión y peso = 0**

### Causas Raíz

| Problema | Causa | Ubicación |
|---|---|---|
| Dispositivos apagados reportados como conectados | No hay verificación de handshake después de conectar | `BluetoothService.connect()` |
| UI desfasada del estado real | Stream no re-emite + listeners no sincronizados | `BluetoothScreen.initState()` y `_handleDisconnection()` |
| Detección lenta de desconexión | Timeout del SO (>30s) sin keep-alive | `_connection.input.listen()` |
| Memory leaks | `dispose()` no cancela subscripciones | `BluetoothScreen.dispose()` |

---

## 9. Anexo: Flujo Técnico Completo

```
APLICACIÓN INICIA
    ↓
main.dart → AppInitializer → HomeScreen
    ↓
HomeScreen → WeightService.initialize() + start()
    ↓
WeightService.start()
    ├─ Suscribe a BluetoothService.adcStream
    └─ Inicia timer de procesamiento (100ms)
    ↓
Usuario navega a BluetoothScreen
    ↓
BluetoothScreen._BluetoothScreenState.initState()
    ├─ Suscribe a connectionStream
    ├─ Suscribe a adcStream
    └─ Carga lista de dispositivos emparejados
    ↓
Usuario selecciona dispositivo
    ↓
BluetoothScreen._connectToDevice()
    ↓
BluetoothService.connect(address)
    ├─ BluetoothConnection.toAddress(address)  ← AQUÍ: Podría conectar a apagado
    ├─ _isConnected = true
    ├─ _connectionController.add(true)
    │   ↓ (Broadcast)
    │   BluetoothScreen listener ejecuta setState(_isConnected = true)
    │   HomeScreen NO se enttera (no suscrito)
    │
    ├─ _connection.input.listen(
    │    onData: _onDataReceived,
    │    onDone: _handleDisconnection,
    │    onError: _handleDisconnection
    │  )
    │   ↓ (Si dispositivo está activo)
    │   Recibe bytes → _onDataReceived parsa ADC → _adcController.add()
    │   ↓ (Broadcast)
    │   WeightService escucha → actualiza _ultimoADC
    │   BluetoothScreen escucha → muestra valor
    │
    └─ return true
    ↓
[OPERACIÓN NORMAL]
    ← ADC fluye cada ~10ms del dispositivo
    ← Streams emiten datos
    ← UI actualiza peso
    ↓
[DISPOSITIVO SE DESCONECTA]
    ├─ Opción A: Usuario toca botón DESCONECTAR
    │   ↓
    │   BluetoothService.disconnect()
    │   ├─ _connection.close()
    │   └─ _handleDisconnection()
    │       ├─ _isConnected = false
    │       └─ _connectionController.add(false)
    │           ↓ (Broadcast)
    │           BluetoothScreen listener ejecuta setState(_isConnected = false)
    │
    ├─ Opción B: Dispositivo apagado sin cerrar socket
    │   ↓ (Espera timeout del SO)
    │   _connection.input listener.onError
    │   ↓
    │   _handleDisconnection()
    │   (mismo que Opción A)
    │
    └─ Opción C: Usuario navega away, dispositivo se desconecta, usuario vuelve
        ↓
        Dispositivo desconecta → _handleDisconnection() ejecuta
        ↓ (pero BluetoothScreen ya no existe)
        _connectionController.add(false) → nadie escucha
        ↓
        Usuario vuelve a BluetoothScreen
        ↓
        BluetoothScreen.initState() suscribe a stream nuevamente
        ← Pero stream ya emitió false, es histórico
        UI muestra estado anterior (CONECTADO) ❌
        ↓
        Usuario debe actualizar manualmente
```

---

**Documento generado para análisis técnico.**  
**Última actualización:** 10 de enero de 2026
