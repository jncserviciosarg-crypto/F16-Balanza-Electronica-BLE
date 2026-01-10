# 🎯 PROJECT OVERVIEW — F16 Balanza Electrónica v1.0.1

**Última Actualización**: 10 de enero de 2026  
**Estado**: ✅ **RELEASE READY**  
**Versión**: 1.0.1  
**Flutter SDK**: ^3.0.0  
**Android Mín**: API 31 (Android 12)  
**Target**: API 36 (Android 16)

---

## 📋 TABLA DE CONTENIDOS

1. [Descripción Funcional](#descripción-funcional)
2. [Arquitectura General](#arquitectura-general)
3. [Flujo de Estado Bluetooth](#flujo-de-estado-bluetooth)
4. [Pantallas y Responsabilidades](#pantallas-y-responsabilidades)
5. [Historial de Cambios](#historial-de-cambios)
6. [Decisiones Técnicas Clave](#decisiones-técnicas-clave)
7. [Qué NO Se Hizo](#qué-no-se-hizo)
8. [Mejoras Futuras Sugeridas](#mejoras-futuras-sugeridas)
9. [Guía de Inicio Rápido](#guía-de-inicio-rápido)

---

## 📱 DESCRIPCIÓN FUNCIONAL

**F16 Balanza Electrónica** es una aplicación Flutter que interfaciona con una balanza electrónica vía **Bluetooth (SPP - Serial Port Profile)** para:

### Funcionalidades Principales
- ✅ **Lectura de peso en tiempo real**: Recibe valores ADC (12 bits) → conversión a peso
- ✅ **Calibración interactiva**: Punto cero, punto de calibración, validación
- ✅ **Filtrado de datos**: EMA (media exponencial móvil) + trim + media móvil
- ✅ **Sesiones de pesaje**: Registro de múltiples mediciones con timestamps
- ✅ **Visualización gráfica**: Histórico de sesiones
- ✅ **Exportación**: Screenshot + share (múltiples pantallas)
- ✅ **Configuración avanzada**: Parámetros de celda de carga, filtros, modo sesión profesional

### Comportamiento
- **Aplicación Landscape-First**: Optimizada para orientación apaisada (industrial)
- **Reactividad Bluetooth**: Sincronización de estado en todas las pantallas
- **Persistencia Local**: SharedPreferences (configuración, calibración, filtros)
- **Gestión de Recursos**: Limpieza automática de conexiones y streams

---

## 🏗️ ARQUITECTURA GENERAL

### Diagrama de Capas

```
┌─────────────────────────────────────┐
│        UI LAYER (Screens)            │
│  Home | Bluetooth | Config | History │
└────────────────┬────────────────────┘
                 │ ValueListenableBuilder
                 ▼
┌─────────────────────────────────────┐
│     SERVICE LAYER (Singletons)       │
│  WeightService | BluetoothService    │
│  PersistenceService | SessionHistory │
└────────────────┬────────────────────┘
                 │ Streams + Notifiers
                 ▼
┌─────────────────────────────────────┐
│      MODEL LAYER (Data Classes)      │
│  WeightState | CalibrationModel      │
│  FilterParams | LoadCellConfig       │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│     BLUETOOTH LAYER (Fork Local)     │
│  BluetoothAdapter + flutter_bluetooth│
│  Connection Pool | Permisos Runtime  │
└──────────────────────────────────────┘
```

### Patrones Implementados

| Patrón | Implementación | Archivo |
|--------|----------------|---------|
| **Singleton** | `BluetoothService`, `WeightService` | `services/*.dart` |
| **ValueNotifier** | `_statusNotifier` (estado Bluetooth) | `bluetooth_service.dart` |
| **Stream** | `adcStream`, `statusStream` | `bluetooth_service.dart` |
| **Adapter** | `BluetoothAdapter` (abstracción) | `bluetooth_adapter.dart` |
| **Repository** | `PersistenceService` | `persistence_service.dart` |

### Dependencias Clave

```yaml
dependencies:
  flutter_bluetooth_serial: path: third_party/flutter_bluetooth_serial_fork
  permission_handler: ^11.4.0          # Permisos runtime Android 12+
  shared_preferences: ^2.2.2            # Persistencia local
  pdf: ^3.10.4                          # Generación PDF
  printing: ^5.12.0                     # Impresión
  device_info_plus: ^10.1.2             # Info del dispositivo
  path_provider: ^2.1.0                 # Acceso a directorios
  intl: ^0.18.1                         # Internacionalización
```

---

## 🔄 FLUJO DE ESTADO BLUETOOTH

### Estados Posibles

```dart
enum BluetoothStatus {
  disconnected,  // Sin conexión activa
  connecting,    // Proceso de conexión en progreso
  connected,     // Conectado y recibiendo datos
  error,         // Fallo en conexión o pérdida
}
```

### Máquina de Estados

```
┌─────────────────────────────────────────────────┐
│           DISCONNECTED (inicial)                │
│  • Sin conexión, sin datos, sin listeners      │
│  • Usuario toca "conectar" → transición        │
└────────────────┬────────────────────────────────┘
                 │ connect(address)
                 ▼
┌─────────────────────────────────────────────────┐
│            CONNECTING                           │
│  • Validando permisos                          │
│  • Intentando conexión vía BluetoothAdapter    │
│  • Timeout: 30s                                │
└────────────┬─────────────────────┬─────────────┘
             │ Éxito               │ Timeout/Error
             ▼                     ▼
      ┌─────────────────┐  ┌───────────────┐
      │   CONNECTED     │  │     ERROR     │
      │ • Socket activo │  │ • Mensaje log │
      │ • Lee ADC       │  │ • User notif  │
      │ • Broadcast     │  │ • Retry opt   │
      └────────┬────────┘  └────────┬──────┘
               │                    │
               │ disconnect()       │ retry/disconnect()
               └────────┬───────────┘
                        │
                        ▼
              ┌──────────────────────┐
              │   DISCONNECTED       │
              │   (por usuario/error)│
              └──────────────────────┘
```

### Flujo de Datos Bluetooth

```
┌──────────────────────────────────────┐
│ BluetoothDevice (MAC address)         │
│ • getBondedDevices()                 │
│ • selectDevice(address)              │
└─────────────┬────────────────────────┘
              │
              ▼
┌──────────────────────────────────────┐
│ BluetoothAdapter.connectToAddress()  │
│ • Valida permisos                    │
│ • Abre socket                        │
│ • Set de timeout 30s                 │
└─────────────┬────────────────────────┘
              │
              ▼
┌──────────────────────────────────────┐
│ BluetoothConnection (socket abierto) │
│ • input: InputStream                 │
│ • output: OutputStream               │
└─────────────┬────────────────────────┘
              │
              ▼
┌──────────────────────────────────────┐
│ Listener en InputStream               │
│ • Lee bytes                          │
│ • Parsea líneas: "1234\r\n"          │
│ • Valida rango: 0–4095 (12 bits)    │
└─────────────┬────────────────────────┘
              │
              ▼
┌──────────────────────────────────────┐
│ _adcController.add(int)              │
│ • Broadcast a adcStream              │
│ • Todos los listeners reciben ADC    │
└─────────────┬────────────────────────┘
              │
              ▼
┌──────────────────────────────────────┐
│ WeightService (escucha adcStream)    │
│ • Aplica calibración                 │
│ • Aplica filtros (EMA, trim, etc.)   │
│ • Genera WeightState                 │
└──────────────────────────────────────┘
```

### Sincronización Global (ETAPA F2.2)

Todas las pantallas observan el **mismo** `BluetoothStatus`:

```dart
ValueListenableBuilder<BluetoothStatus>(
  valueListenable: _weightService.bluetoothStatusNotifier,
  builder: (context, status, child) {
    // Todas las pantallas leen del mismo notifier
    // → Sincronización garantizada
    // → Sin desfases de estado
    // → Reactividad en tiempo real
  }
)
```

---

## 📱 PANTALLAS Y RESPONSABILIDADES

### 1. **HomeScreen** (`screens/home_screen.dart`)
**Propósito**: Pantalla principal de lectura de peso

**Componentes**:
- ✅ Display grande de peso (kg o unidad configurable)
- ✅ Indicador ADC (valor bruto)
- ✅ Ícono de estado Bluetooth (esquina superior derecha)
- ✅ Botón "Screenshot" (cámara)
- ✅ Botón "Configurar"
- ✅ Botón "Conexión Bluetooth"
- ✅ Indicador "ESTABLE" (si peso está estabilizado)

**Estado**:
- Escucha: `_weightService.weightStream` (peso en tiempo real)
- Observa: `_weightService.bluetoothStatusNotifier` (estado BT)
- Lee: Configuración (unidad, decimales) de `_weightService`

**Notas**:
- Landscape-first
- Colores F-16 (militar): grises, cian, verdes oscuros
- Posición fija del indicador BT para consistencia

---

### 2. **BluetoothScreen** (`screens/bluetooth_screen.dart`)
**Propósito**: Gestión de conexión y dispositivos

**Componentes**:
- ✅ Botón "ESCANEAR" → lista de dispositivos disponibles
- ✅ Lista de dispositivos emparejados (bonded)
- ✅ Botón "CONECTAR" en cada dispositivo
- ✅ Estado de conexión (CONECTADO/DESCONECTADO/ERROR)
- ✅ Botón "DESCONECTAR" (si actualmente conectado)
- ✅ Valor ADC último recibido

**Estado**:
- Escucha: `_bluetoothService.statusNotifier` (estado conexión)
- Escucha: `_bluetoothService.adcStream` (ADC último)
- Maneja permisos runtime (Bluetooth en Android 12+)

**Flujo**:
1. Usuario toca "ESCANEAR" → `_scanForDevices()`
2. Lista se llena con dispositivos
3. Usuario selecciona dispositivo → `_connectToDevice(address)`
4. BluetoothService intenta conexión
5. Si éxito: estado → CONNECTED, muestra botón DESCONECTAR
6. Si error: estado → ERROR, muestra mensaje

---

### 3. **CalibrationScreen** (`screens/calibration_screen.dart`)
**Propósito**: Calibración de celda de carga (puntos cero y calibración)

**Componentes**:
- ✅ Campo peso de referencia (kg)
- ✅ Botón "TOMAR PUNTO CERO" (con validación)
- ✅ Botón "TOMAR PUNTO CALIBRACIÓN" (con validación)
- ✅ Vista de datos crudos: ADC, peso calibrado, estado
- ✅ Botón "RESETEAR CALIBRACIÓN"
- ✅ Indicador visual de proceso (validación 2s con estabilidad)

**Lógica**:
- **Punto Cero**: 3 lecturas estables de ADC, promedia
- **Punto Calibración**: 3 lecturas estables, calcula factor `ppm` (peso/ADC)
- **Guardado**: PersistenceService persiste en SharedPreferences

**Estado**:
- Observa: `_weightService.bluetoothStatusNotifier`
- Lee: Corriente `WeightState` (ADC, peso, estable)
- Mutación: Crea `CalibrationModel`, llama `_weightService.setCalibration()`

---

### 4. **ConfigScreen** (`screens/config_screen.dart`)
**Propósito**: Configuración de parámetros de filtrado y celda de carga

**Componentes**:
- ✅ Tabs: General | Filtros | Celda Carga
- ✅ Slider/input para cada parámetro
- ✅ Valores por defecto (factory defaults)
- ✅ Botón "GUARDAR"
- ✅ Botón "RESETEAR"

**Parámetros**:
- **General**: Unidad (kg/g/lb), decimales
- **Filtros**: Muestras (N), ventana EMA, alpha EMA, intervalo update (ms)
- **Celda Carga**: Divisiónmínima, offset, rango máximo ADC

**Persistencia**: Todo guardado vía `PersistenceService`

---

### 5. **SessionProScreen** (`screens/session_pro_screen.dart`)
**Propósito**: Modo profesional para sesiones de pesaje múltiple

**Componentes**:
- ✅ Tabla de mediciones (timestamp, peso, ADC)
- ✅ Botón "NUEVA MEDICIÓN" (captura peso + timestamp)
- ✅ Estadísticas: Min, Max, Promedio
- ✅ Botón "EXPORTAR" (PDF + share)
- ✅ Indicador BT sincronizado

**Flujo**:
1. Usuario toca "NUEVA MEDICIÓN"
2. Se captura `WeightState` actual
3. Se crea `SessionWeight` con timestamp
4. Se agrega a `SessionModel` actual
5. Se muestra en tabla
6. Usuario puede exportar la sesión completa como PDF

---

### 6. **HistoryScreen** (`screens/history_screen.dart`)
**Propósito**: Visualización de historial de sesiones pasadas

**Componentes**:
- ✅ Lista de sesiones guardadas
- ✅ Resumen por sesión (fecha, cantidad mediciones, min/max)
- ✅ Detalle expandible (tabla de mediciones)
- ✅ Botón "EXPORTAR" por sesión
- ✅ Botón "ELIMINAR"

**Persistencia**: `SessionHistoryService` gestiona sesiones en almacenamiento

---

## 📊 HISTORIAL DE CAMBIOS

### **ETAPA F1 — Arquitectura Base**
- ✅ Creación de estructura: Screens, Services, Models, Widgets
- ✅ BluetoothService + WeightService (singletons)
- ✅ Pantalla principal de lectura de peso
- ✅ Calibración bidireccional (punto cero + calibración)
- ✅ Filtrado EMA + trim + media móvil

### **ETAPA F2.1 — Mantenimiento Profundo**
- ✅ Refactor de calidad de código
- ✅ Documentación exhaustiva de lógica Bluetooth
- ✅ Tests de calibración
- ✅ Optimización de memoria (dispose() correcto en todos los screens)
- ✅ Normalización de colores F-16

### **ETAPA F2.2 — Sincronización Global Bluetooth**
- ✅ Implementación de `BluetoothStatus` enum (disconnected, connecting, connected, error)
- ✅ `ValueNotifier<BluetoothStatus>` en BluetoothService
- ✅ Indicador Bluetooth sincronizado en TODAS las pantallas
- ✅ Tooltips descriptivos
- ✅ Cero memory leaks

### **ETAPA MIGRACIÓN (A–C) — Android 12–16**
- ✅ Fork local de `flutter_bluetooth_serial`
- ✅ Migración `AsyncTask` → `ExecutorService` (Java)
- ✅ Removed APIs bloqueadas (pairing requests, reflection)
- ✅ Agregadas dependencias: `pdf`, `printing`, `device_info_plus`
- ✅ Validación permisos runtime completa

---

## 🎯 DECISIONES TÉCNICAS CLAVE

### 1. **Por Qué Bluetooth Serial (SPP) y no BLE**
- ✅ Compatibilidad histórica con hardware existente (balanzas clásicas)
- ✅ Menor complejidad inicial (vs. BLE GATT profiles)
- ✅ Comunicación simple: bytes sobre stream
- ⚠️ **Limitación**: No compatible con iOS. Mitigation: Android-first en v1.0.1

### 2. **Por Qué SharedPreferences y no SQLite**
- ✅ Configuraciones simples (calibración, filtros, config)
- ✅ No requiere schema migrations
- ✅ Lectura/escritura rápida para valores atómicos
- ⚠️ **Limitación**: No escalable para N sesiones. Plan: SQLite en v1.1+

### 3. **Por Qué Singleton Pattern**
- ✅ Instancia única garantiza consistencia de estado
- ✅ Acceso global sin inyección de dependencias
- ✅ Gestión centralizadi de recursos (conexión BT, streams)
- ⚠️ **Limitación**: Difícil de testear. Mitigación: `BluetoothAdapter` permite mocking

### 4. **Por Qué Fork Local de flutter_bluetooth_serial**
- ✅ Plugin original tiene bugs en Android 12+ (AsyncTask deprecado)
- ✅ Fork permite aplicar parches atómicos sin esperar actualizaciones
- ✅ Control total sobre versión de código JNI
- ⚠️ **Limitación**: Requiere mantenimiento. Plan: Migrar a `flutter_blue_plus` en v2.0

### 5. **Reactividad: ValueNotifier en lugar de Streams para UI**
- ✅ `ValueListenableBuilder` automáticamente (re)construye widgets necesarios
- ✅ Evita boilerplate de `StreamBuilder`
- ✅ Mejor performance (menos re-builds innecesarios)
- ✅ Sincronización garantizada (todos leen del mismo notifier)

---

## ❌ QUÉ NO SE HIZO

### NO Implementado en v1.0.1

| Feature | Razón | Impacto |
|---------|-------|--------|
| **BLE (Bluetooth Low Energy)** | Requiere rewrite completo, hardware diferente | iOS incompatible en v1.0.1 |
| **Persistencia avanzada (SQLite)** | Overkill para configuraciones simples | Funcionalidad actual suficiente |
| **Testing unitario/widget** | No bloqueador para release | Calidad verificada manualmente |
| **Logging avanzado/Analytics** | No crítico para MVP | Posible post-launch |
| **Sync en la nube** | Scope fuera de MVP | v1.5+ future |
| **Offline-first** | No es requisito | v1.2+ |
| **Multi-idioma completo** | UI en español, suficiente | v1.1+ si se requiere |
| **PWA / Web** | Flutter Web todavía experimental | v2.0+ |

---

## 🚀 MEJORAS FUTURAS SUGERIDAS

### Corto Plazo (v1.1)
- [ ] **SQLite para sesiones**: Reemplazar SharedPreferences con base de datos relacional
- [ ] **Exportación XLS/XLSX**: Además de PDF y share
- [ ] **Gráficas históricas**: Chart.js / fl_chart para sesiones
- [ ] **Dark mode**: Tema claro + oscuro seleccionable

### Mediano Plazo (v1.2)
- [ ] **Bluetooth Low Energy (BLE)**: Compatibilidad con balanzas modernas
- [ ] **NFC tagging**: Marcar tares con NFC
- [ ] **Barcode scanner**: Integración código de barras para productos
- [ ] **Impresoras térmicas**: Soporte directo para etiquetado

### Largo Plazo (v2.0)
- [ ] **Arquitectura limpia con GetX/Riverpod**: Reemplazar Singletons
- [ ] **Firebase/Cloud Sync**: Sincronización de datos entre dispositivos
- [ ] **Testing completo**: Unit + Widget + Integration
- [ ] **Publicación iOS**: Migración a `flutter_blue_plus` + resolución de APIs iOS
- [ ] **CI/CD**: GitHub Actions para builds automáticos

---

## 🔧 GUÍA DE INICIO RÁPIDO

### Prerequisitos
- Flutter SDK ≥ 3.0.0
- Android SDK (API 31+)
- Dispositivo Android o emulador
- Balanza electrónica con módulo Bluetooth

### Instalación

```bash
# 1. Clonar repositorio
git clone <repo-url>
cd F16-v_1_0_0_firmada

# 2. Obtener dependencias
flutter pub get

# 3. Limpiar caché (si hay problemas)
flutter clean
flutter pub get

# 4. Verificar análisis
flutter analyze

# 5. Correr en dispositivo
flutter run -v
```

### Compilación APK (Release)

```bash
# Build APK optimizado
flutter build apk --release

# APK ubicado en:
# build/app/outputs/apk/release/app-release.apk

# Para test APK (debuggable):
flutter build apk --debug
```

### Estructura de Carpetas

```
lib/
├── main.dart                 # Punto entrada + initializer
├── screens/
│   ├── home_screen.dart
│   ├── bluetooth_screen.dart
│   ├── calibration_screen.dart
│   ├── config_screen.dart
│   ├── session_pro_screen.dart
│   ├── history_screen.dart
│   └── f16_splash_screen.dart
├── services/
│   ├── bluetooth_service.dart        # Singleton: conexión BT
│   ├── bluetooth_adapter.dart        # Interfaz abstracta
│   ├── weight_service.dart           # Singleton: procesamiento peso
│   ├── persistence_service.dart      # Singleton: guardado local
│   └── session_history_service.dart  # Singleton: historial
├── models/
│   ├── weight_state.dart
│   ├── calibration_model.dart
│   ├── filter_params.dart
│   ├── load_cell_config.dart
│   ├── session_model.dart
│   └── session_weight.dart
├── widgets/
│   └── (widgets reutilizables)
├── utils/
│   ├── constants.dart
│   └── screenshot_helper.dart
└── mixins/
    └── (mixins compartidos)
```

---

## 📞 SOPORTE Y CONTRIBUCIONES

### Reportar Issues
- Formato: `[SCREEN] Descripción del problema`
- Incluir: Logs (`flutter run -v`), pasos para reproducir

### Enviar Pull Requests
- Branch base: `main` o `develop`
- Asegurar: `flutter analyze` sin errores, `flutter format` aplicado

---

## 📄 ANEXOS

### A. Posibles Errores Comunes

**Error**: "flutter_bluetooth_serial not found"
- **Solución**: `flutter pub get` nuevamente, limpiar `.dart_tool`

**Error**: "Permission denied (Bluetooth)"
- **Solución**: Verificar permisos en AndroidManifest.xml + runtime permissions en código

**Error**: "BluetoothConnection: No routes to host"
- **Solución**: Dispositivo BT desconectado, reintentar conexión

### B. Debugging

Habilitar logs detallados:
```bash
flutter run -v 2>&1 | tee flutter_debug.log
```

Monitorear logcat:
```bash
adb logcat | grep "flutter"
```

---

**Documento generado automáticamente**  
**Fecha**: 10 de enero de 2026  
**Versión**: 1.0.1  
**Licencia**: MIT (o según corresponda)

