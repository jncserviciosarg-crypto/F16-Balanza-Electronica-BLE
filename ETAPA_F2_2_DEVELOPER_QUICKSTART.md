# 🚀 ETAPA F2.2 — GUÍA RÁPIDA DE DESARROLLO

**Para**: Desarrolladores que necesitan agregar sincronización Bluetooth a nuevas pantallas  
**Tiempo**: 5 minutos  
**Dificultad**: ⭐ Muy Fácil

---

## 📝 Tarea: Agregar Indicador Bluetooth a una Nueva Pantalla

### Paso 1: Importar el servicio

En `lib/screens/mi_pantalla_nueva.dart`, agregar:

```dart
import '../services/bluetooth_service.dart';

class MiPantallaNueva extends StatefulWidget {
  // ...
}

class _MiPantallaNuevaState extends State<MiPantallaNueva> {
  final WeightService _weightService = WeightService();  // Si necesitas acceso a peso
  // ...
}
```

---

### Paso 2: Copiar el método helper

Copiar y pegar este método en tu clase State:

```dart
/// Indicador visual compacto de estado Bluetooth en AppBar
Widget _buildBluetoothStatusBadge() {
  return ValueListenableBuilder<BluetoothStatus>(
    valueListenable: _weightService.bluetoothStatusNotifier,
    builder: (BuildContext context, BluetoothStatus status, Widget? child) {
      IconData icon;
      Color color;

      switch (status) {
        case BluetoothStatus.connected:
          icon = Icons.bluetooth_connected;
          color = Colors.green;
          break;
        case BluetoothStatus.connecting:
          icon = Icons.bluetooth_searching;
          color = Colors.orange;
          break;
        case BluetoothStatus.error:
          icon = Icons.bluetooth_off;
          color = Colors.red;
          break;
        case BluetoothStatus.disconnected:
          icon = Icons.bluetooth_disabled;
          color = Colors.grey;
      }

      return Tooltip(
        message: _getBluetoothStatusText(status),
        child: Icon(icon, color: color, size: 20),
      );
    },
  );
}

String _getBluetoothStatusText(BluetoothStatus status) {
  switch (status) {
    case BluetoothStatus.connected:
      return 'Bluetooth: Conectado';
    case BluetoothStatus.connecting:
      return 'Bluetooth: Conectando...';
    case BluetoothStatus.error:
      return 'Bluetooth: Error';
    case BluetoothStatus.disconnected:
      return 'Bluetooth: Desconectado';
  }
}
```

---

### Paso 3: Agregar a AppBar

En tu método `build()`, modificar el AppBar:

**Opción A: AppBar estándar**
```dart
appBar: AppBar(
  title: const Text('MI PANTALLA'),
  actions: <Widget>[
    // ETAPA F2.2: Indicador de estado Bluetooth
    Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: _buildBluetoothStatusBadge(),
      ),
    ),
    // Otros botones...
  ],
),
```

**Opción B: Stack con Positioned (HomeScreen style)**
```dart
body: Stack(
  children: <Widget>[
    // Contenido principal
    Container(
      // ... tu contenido
    ),
    // ETAPA F2.2: Indicador de estado Bluetooth en esquina
    Positioned(
      top: 8,
      right: 8,
      child: _buildBluetoothStatusIndicator(),  // Versión grande para HomeScreen
    ),
  ],
),
```

---

## ✅ Verificación

Para verificar que todo funciona:

```bash
# 1. Compilar
flutter pub get
flutter build apk --debug

# 2. Ejecutar
flutter run

# 3. Verificar:
#    - Indicador visible en la pantalla
#    - Cambiar estado Bluetooth (conectar/desconectar)
#    - Indicador actualiza en tiempo real
```

---

## 🎨 Variaciones Visuales

### Indicador Compacto (AppBar)
```
[BT] Icon solamente, 20px
```

### Indicador Medio (HomeScreen corners)
```
┌──────────────┐
│  [BT]        │
│  (icono +    │
│   borde)     │
│  24px        │
└──────────────┘
```

### Indicador Grande (Custom)
```
┌─────────────────────┐
│  Bluetooth Status   │
│  ✅ Conectado      │
│  Dispositivo: TX-01 │
│  Señal: 75%         │
└─────────────────────┘
```

---

## 🔧 Personalización

### Cambiar color del icono

```dart
// En _buildBluetoothStatusBadge()
case BluetoothStatus.connected:
  icon = Icons.bluetooth_connected;
  color = Colors.lightGreen;  // ← cambiar aquí
  break;
```

### Cambiar tamaño del icono

```dart
// En _buildBluetoothStatusBadge()
Icon(icon, color: color, size: 24),  // ← cambiar size
```

### Cambiar texto del tooltip

```dart
String _getBluetoothStatusText(BluetoothStatus status) {
  switch (status) {
    case BluetoothStatus.connected:
      return 'BT: OK';  // ← cambiar texto
    // ...
  }
}
```

### Agregar sonido / vibración

```dart
import 'package:vibration/vibration.dart';

// Cuando cambia a conectado
if (status == BluetoothStatus.connected) {
  Vibration.vibrate(duration: 100);
}
```

---

## 🚨 Troubleshooting

### Error: "BluetoothStatus no está definido"

```dart
// ❌ FALLO: Olvidó importar
import '../services/bluetooth_service.dart';  // ← Agregar esta línea
```

### Error: "_weightService is null"

```dart
// ❌ FALLO: No inicializó el servicio
class _MyScreenState extends State<MyScreen> {
  // Falta esto:
  final WeightService _weightService = WeightService();
}
```

### Indicador no actualiza

```dart
// ❌ FALLO: Usando _bluetoothService en lugar de _weightService
ValueListenableBuilder<BluetoothStatus>(
  valueListenable: _weightService.bluetoothStatusNotifier,  // ← Correcto
  // ...
)
```

### Memory leak en dispose

```dart
// ❌ FALLO: No cancelar subscriptions
@override
void dispose() {
  // Falta cancelar si tienes subscriptions directas
  _subscription?.cancel();  // ← Agregar si es necesario
  super.dispose();
}

// ✅ CORRECTO: ValueListenableBuilder no necesita cancel
// (se auto-limpia cuando el widget se destruye)
```

---

## 📊 Ejemplos Completos

### Ejemplo 1: Pantalla Simple

```dart
import '../services/bluetooth_service.dart';

class SimpleScreen extends StatefulWidget {
  @override
  State<SimpleScreen> createState() => _SimpleScreenState();
}

class _SimpleScreenState extends State<SimpleScreen> {
  final WeightService _weightService = WeightService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildBluetoothStatusBadge(),
            ),
          ),
        ],
      ),
      body: Center(
        child: Text('Contenido aquí'),
      ),
    );
  }

  Widget _buildBluetoothStatusBadge() {
    return ValueListenableBuilder<BluetoothStatus>(
      valueListenable: _weightService.bluetoothStatusNotifier,
      builder: (context, status, child) {
        final IconData icon = status == BluetoothStatus.connected
            ? Icons.bluetooth_connected
            : Icons.bluetooth_disabled;
        final Color color = status == BluetoothStatus.connected
            ? Colors.green
            : Colors.grey;

        return Icon(icon, color: color);
      },
    );
  }
}
```

### Ejemplo 2: Pantalla con Lógica Compleja

```dart
class DataScreen extends StatefulWidget {
  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final WeightService _weightService = WeightService();
  late StreamSubscription<WeightState> _weightSubscription;

  @override
  void initState() {
    super.initState();
    _weightSubscription = _weightService.weightStateStream.listen((state) {
      if (mounted) {
        setState(() {
          // Procesar peso
        });
      }
    });
  }

  @override
  void dispose() {
    _weightSubscription.cancel();  // ← Importante: cancelar subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildBluetoothStatusBadge(),
            ),
          ),
        ],
      ),
      body: Center(
        child: ValueListenableBuilder<BluetoothStatus>(
          valueListenable: _weightService.bluetoothStatusNotifier,
          builder: (context, btStatus, child) {
            // Usar btStatus para lógica condicional
            if (btStatus != BluetoothStatus.connected) {
              return Text('Bluetooth no conectado: $btStatus');
            }
            return Text('Bluetooth OK, recibiendo datos');
          },
        ),
      ),
    );
  }

  Widget _buildBluetoothStatusBadge() { /* ... */ }
  String _getBluetoothStatusText(BluetoothStatus status) { /* ... */ }
}
```

---

## 📚 Referencias

### Archivos Originales de Referencia
- `lib/screens/home_screen.dart` — Indicador en Stack/Positioned
- `lib/screens/calibration_screen.dart` — Indicador en AppBar
- `lib/screens/config_screen.dart` — Indicador en AppBar
- `lib/screens/session_pro_screen.dart` — Indicador en AppBar compacto

### Documentación Completa
- `ETAPA_F2_2_SINCRONIZACION_GLOBAL.md` — Detalles técnicos
- `ETAPA_F2_2_VALIDATION_CHECKLIST.md` — Pruebas y validación

---

## ⏱️ Tiempo Estimado

| Tarea | Tiempo |
|---|---|
| Importar | 30s |
| Copiar método | 1min |
| Agregar a AppBar | 1min |
| Probar | 2min |
| **Total** | **~5min** |

---

## ✨ Checklist Final

Antes de hacer commit:

- [ ] `import '../services/bluetooth_service.dart';` agregado
- [ ] Método `_buildBluetoothStatusBadge()` copiado
- [ ] Método `_getBluetoothStatusText()` copiado
- [ ] AppBar actualizado con el indicador
- [ ] Compilación exitosa (`flutter build apk --debug`)
- [ ] Indicador visible en pantalla
- [ ] Tooltip funciona (pausar el cursor)
- [ ] Cambios en Bluetooth se reflejan (conectar/desconectar)

---

## 🎓 Conceptos Clave

### ValueNotifier
- Widget reactivo que notifica cambios
- No necesita StreamSubscription ni cancel
- Auto-limpieza en dispose

### ValueListenableBuilder
- Widget que reconstruye solo cuando valueListenable cambia
- Más eficiente que StreamBuilder para estado simple
- Patrón recomendado por Flutter

### BluetoothStatus (enum)
```dart
enum BluetoothStatus {
  disconnected,  // No hay conexión
  connecting,    // Intentando conectar
  connected,     // Conectado y activo
  error,         // Error de conexión
}
```

---

## 🚀 Propinas Pro

### Pro Tip 1: Acceso Directo a BluetoothService

Si necesitas acceso directo (raro):
```dart
final BluetoothService _btService = BluetoothService();
_btService.statusNotifier  // Acceso directo
```

### Pro Tip 2: Lógica Condicional en build()

```dart
build(BuildContext context) {
  final status = _weightService.bluetoothStatusNotifier.value;
  
  if (status != BluetoothStatus.connected) {
    return Scaffold(
      body: Center(child: Text('Conecta Bluetooth primero')),
    );
  }
  
  // Mostrar interfaz normal si está conectado
  return Scaffold(/* ... */);
}
```

### Pro Tip 3: Respetar Performance

```dart
// ❌ MALO: Rebuild innecesario
ValueListenableBuilder(
  valueListenable: _weight.bluetoothStatusNotifier,
  builder: (context, status, _) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesaje de ${_users.length} usuarios'),  // Rebuild si usuarios cambia
      ),
    );
  },
)

// ✅ BUENO: Separar concernos
ValueListenableBuilder(
  valueListenable: _weight.bluetoothStatusNotifier,
  builder: (context, status, _) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),  // En un método separado
      ),
    );
  },
)
```

---

## 🎯 Misión Cumplida

Siguiendo esta guía, deberías poder:

✅ Agregar sincronización Bluetooth a nuevas pantallas en <5 minutos  
✅ Mantener consistencia de estado en toda la app  
✅ Evitar memory leaks y bugs de sincronización  
✅ Mejorar la experiencia del usuario con indicadores claros  

---

**Guía Rápida - ETAPA F2.2**  
**Versión**: 1.0  
**Última Actualización**: 10 de enero de 2026  
**Dificultad**: ⭐ Muy Fácil  
**Tiempo**: 5 minutos
