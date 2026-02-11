# 📊 EXTRACCIÓN DE CONOCIMIENTO — Datos BLE y Procesamiento de Peso

**Proyecto**: F16 Balanza Electrónica BLE  
**Versión del Sistema**: 2.0.0  
**Fecha de Extracción**: 11 de febrero de 2026  
**Propósito**: Documentación exhaustiva del sistema actual para reutilización de conocimiento  
**Tipo de Documento**: SOLO LECTURA / SOLO ANÁLISIS

---

## 📋 ÍNDICE

1. [Contexto General del Sistema](#1-contexto-general-del-sistema)
2. [Conectividad Bluetooth BLE](#2-conectividad-bluetooth-ble)
3. [Estructura del JSON/Datos Recibidos](#3-estructura-del-jsondatos-recibidos)
4. [Origen del Dato Numérico Principal](#4-origen-del-dato-numérico-principal)
5. [Flujo de Procesamiento del Dato](#5-flujo-de-procesamiento-del-dato)
6. [Decisiones de Hardware vs Software](#6-decisiones-de-hardware-vs-software)
7. [Supuestos Explícitos del Sistema](#7-supuestos-explícitos-del-sistema)
8. [Límites Conocidos](#8-límites-conocidos)
9. [Dudas Técnicas](#9-dudas-técnicas)

---

## 1. CONTEXTO GENERAL DEL SISTEMA

### 1.1 ¿Qué Hace Este Sistema?

F16 es una **aplicación Flutter para lectura de peso en tiempo real** mediante Bluetooth Low Energy (BLE). El sistema recibe datos crudos de un dispositivo de pesaje (balanza electrónica) vía BLE, procesa esos datos a través de un pipeline de filtrado y calibración, y presenta el peso final al usuario en una interfaz móvil Android.

**Funciones principales:**
- Conexión Bluetooth BLE con dispositivo de pesaje externo
- Recepción continua de datos crudos ADC (Analog-to-Digital Converter)
- Filtrado avanzado de señal para reducir ruido
- Calibración configurable para convertir cuentas ADC a peso real
- Gestión de tara y cero operativo
- Reconexión automática ante desconexiones
- Exportación de sesiones de pesaje a PDF

### 1.2 Rol del BLE en el Flujo

El Bluetooth Low Energy es el **único canal de comunicación** entre el hardware de pesaje y la aplicación móvil. Específicamente:

- **Entrada al sistema**: El hardware de pesaje transmite valores ADC (cuentas crudas del sensor) vía notificaciones BLE cada ~50ms
- **Protocolo**: Datos binarios empaquetados en 4 bytes (Int32 Little Endian)
- **Unidireccional**: Solo recepción de datos (no se envían comandos al hardware desde la app)
- **Crítico**: Sin BLE funcional, no hay datos de peso disponibles

### 1.3 Tipo de Dispositivo que Envía los Datos

**Hardware externo** (no incluido en este repositorio):
- Dispositivo de pesaje con celda de carga (load cell)
- Probablemente basado en ESP32 o similar (inferido por UUIDs personalizados)
- Integra ADC para lectura de celda de carga (posiblemente HX711 u otro amplificador)
- Implementa servidor GATT BLE con servicio y característica personalizados
- Transmite valores ADC sin procesamiento adicional (datos crudos)

**Nota**: El código de este repositorio NO incluye el firmware del hardware. Solo se documenta cómo la aplicación móvil consume los datos que ese hardware provee.

---

## 2. CONECTIVIDAD BLUETOOTH BLE

### 2.1 Establecimiento de Conexión

El proceso de conexión BLE sigue estos pasos implementados en `lib/services/bluetooth_service.dart`:

**Flujo completo:**

```
1. Escaneo de Dispositivos
   ↓
2. Usuario Selecciona Dispositivo
   ↓
3. Solicitud de Conexión (timeout: 15s, MTU: 512)
   ↓
4. Descubrimiento de Servicios GATT
   ↓
5. Búsqueda de Servicio Específico (UUID: 4fafc201-1fb5-459e-8fcc-c5c9c331914b)
   ↓
6. Búsqueda de Característica Específica (UUID: beb5483e-36e1-4688-b7f5-ea07361b26a8)
   ↓
7. Activación de Notificaciones en Característica
   ↓
8. Suscripción a Stream de Datos
   ↓
9. Estado: CONNECTED → Inicio de recepción de datos
```

**Código relevante** (`lib/services/bluetooth_service.dart` líneas 200-286):

```dart
Future<bool> connect(fbp.ScanResult scanResult) async {
  // ... validaciones previas ...
  
  _statusNotifier.value = BluetoothStatus.connecting;
  
  final fbp.BluetoothDevice bleDevice = scanResult.device;
  
  // Conexión con timeout de 15 segundos
  await bleDevice.connect(
    license: fbp.License.free,
    timeout: const Duration(seconds: 15),
    mtu: 512,
    autoConnect: false,
  );
  
  // Descubrir servicios
  final List<fbp.BluetoothService> services = 
      await bleDevice.discoverServices();
      
  // Buscar servicio y característica específicos
  // ... búsqueda por UUID ...
  
  // Activar notificaciones
  await _bleCharacteristic!.setNotifyValue(true);
  
  // Suscribirse a datos
  _bleCharacteristic!.onValueReceived.listen(
    _onBinaryDataReceived,
    onError: (error) {
      debugPrint('Error recibiendo datos BLE: $error');
      _handleDisconnection();
    },
  );
  
  return true;
}
```

### 2.2 UUIDs Utilizados

| Tipo | UUID | Descripción |
|------|------|-------------|
| **Servicio BLE** | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | Servicio personalizado del dispositivo de pesaje |
| **Característica BLE** | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | Característica de notificación para transmitir ADC |

**Ubicación en código**: `lib/services/bluetooth_service.dart` líneas 43-45

```dart
static const String _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
static const String _characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
```

**Notas:**
- UUIDs personalizados (no estándar Bluetooth SIG)
- El UUID del servicio sugiere implementación personalizada en hardware
- No hay documentación del hardware que explique el origen de estos UUIDs

### 2.3 Característica que Entrega el Dato Principal

**Característica única**: `beb5483e-36e1-4688-b7f5-ea07361b26a8`

- **Propiedad**: `notify` (notificaciones del servidor al cliente)
- **Contenido**: Valor ADC crudo del sensor de peso
- **Formato**: Binario (4 bytes mínimos)
- **Tipo de datos**: Int32 Little Endian
- **No requiere lectura manual**: Los datos llegan automáticamente vía notificaciones

**Código de suscripción** (`lib/services/bluetooth_service.dart` líneas 272-278):

```dart
_bleCharacteristic!.onValueReceived.listen(
  _onBinaryDataReceived,
  onError: (error) {
    debugPrint('Error recibiendo datos BLE: $error');
    _handleDisconnection();
  },
);
```

### 2.4 Frecuencia / Modo de Recepción

**Frecuencia observada**: Aproximadamente **50ms** entre notificaciones (inferido del comportamiento del sistema)

**Modo de recepción**: 
- **Push (notificaciones automáticas)**: El hardware envía datos sin que la app los solicite
- **Continuo**: Una vez conectado, el stream de datos es constante mientras haya conexión
- **Asíncrono**: Los datos llegan vía callbacks de `onValueReceived.listen()`

**No hay polling**: La aplicación NO solicita datos activamente, solo espera notificaciones.

**Evidencia en código**: 
- El procesamiento interno opera cada **100ms** (timer en WeightService)
- El hardware envía más rápido (~50ms) para que siempre haya datos frescos
- Ubicación: `lib/services/weight_service.dart` línea 107-110

```dart
_processingTimer = Timer.periodic(
  Duration(milliseconds: _updateIntervalMs), // 100ms por defecto
  (Timer timer) => _processData(),
);
```

### 2.5 Reconexión Automática

El sistema implementa **reconexión automática** ante desconexiones no manuales:

**Parámetros de reconexión**:
- Máximo de intentos: **3**
- Delays progresivos: 
  - Intento 1: 2 segundos
  - Intento 2: 5 segundos
  - Intento 3: 10 segundos
- **No se reintenta** si la desconexión fue manual

**Código relevante** (`lib/services/bluetooth_service.dart` líneas 316-380):

```dart
void _attemptAutoReconnect() {
  debugPrint('[BLE_RECONNECT] Desconexión no manual detectada...');
  
  Future.delayed(const Duration(seconds: 2), () async {
    if (_lastDevice == null || _manualDisconnect) return;
    
    _reconnectAttempts++;
    
    // Delays progresivos en intentos 2 y 3
    if (_reconnectAttempts > 1) {
      final int delaySeconds = _reconnectAttempts == 2 ? 5 : 10;
      await Future.delayed(Duration(seconds: delaySeconds));
    }
    
    // ... lógica de reconexión ...
  });
}
```

---

## 3. ESTRUCTURA DEL JSON/DATOS RECIBIDOS

### 3.1 ⚠️ NO ES JSON

**Importante**: Los datos recibidos **NO son JSON**. Son **datos binarios puros** transmitidos como array de bytes.

### 3.2 Estructura de Datos Binarios

**Formato real**:
- Tipo: `List<int>` (array de bytes sin signo)
- Tamaño mínimo requerido: **4 bytes**
- Tamaño máximo: Hasta MTU negociado (512 bytes configurado)
- Interpretación: Los primeros 4 bytes representan un **Int32 Little Endian**

### 3.3 Ejemplo Real de Payload

**Bytes crudos recibidos** (ejemplo hipotético basado en el código):

```
Paquete BLE: [0xE8, 0x03, 0x00, 0x00, ...]
             │    └─ Byte 1     │    │
             └─ Byte 0           │    │
                      Byte 2 ────┘    │
                      Byte 3 ─────────┘
                      
Bytes adicionales (si existen) son ignorados
```

**Conversión a Int32 Little Endian**:

```
Bytes: [0xE8, 0x03, 0x00, 0x00]

Interpretación Little Endian:
  0x00 00 03 E8 = 1000 (decimal)

Resultado: adcValue = 1000
```

### 3.4 Campos Presentes

El sistema solo procesa **un campo**:

| Campo | Offset | Tamaño | Tipo | Representación | Descripción |
|-------|--------|--------|------|----------------|-------------|
| **ADC Value** | 0 | 4 bytes | Int32 | Little Endian | Valor crudo del convertidor analógico-digital |

**No hay otros campos estructurados**. Si el paquete tiene más de 4 bytes, son ignorados.

### 3.5 Código de Parseo

**Ubicación**: `lib/services/bluetooth_service.dart` líneas 449-475

```dart
void _onBinaryDataReceived(List<int> data) {
  try {
    // Verificar que tenemos al menos 4 bytes para extraer el ADC
    if (data.length < 4) {
      debugPrint('Advertencia: Paquete BLE incompleto (${data.length} bytes)');
      return;
    }

    // Extraer los primeros 4 bytes
    final Uint8List rawBytes = Uint8List.fromList(data.sublist(0, 4));

    // Convertir a entero de 32 bits (Little Endian)
    final ByteData byteData = ByteData.view(rawBytes.buffer);
    final int adcValue = byteData.getInt32(0, Endian.little);

    // Actualizar el último ADC y emitir al stream
    _ultimoADC = adcValue;
    _adcController.add(adcValue);
  } catch (e) {
    debugPrint('Error procesando datos binarios BLE: $e');
  }
}
```

### 3.6 Validación de Datos

**Validaciones implementadas**:
1. **Tamaño mínimo**: `data.length >= 4` (si no, se descarta el paquete)
2. **Manejo de errores**: Cualquier excepción en parseo se captura y loguea
3. **No hay validación de rango**: El Int32 puede ser cualquier valor entre -2,147,483,648 y 2,147,483,647

**No se valida**:
- Valores negativos (el sistema los acepta)
- Valores fuera de rango esperado del ADC (ej: > 4095 si es ADC de 12 bits)
- Integridad del paquete (no hay checksum visible)

---

## 4. ORIGEN DEL DATO NUMÉRICO PRINCIPAL

### 4.1 ¿Qué Representa el Valor Crudo?

El valor crudo es un **valor ADC (Analog-to-Digital Converter)**:

- **Fuente física**: Celda de carga (load cell) que genera voltaje proporcional al peso aplicado
- **Amplificación**: Probable uso de amplificador (ej: HX711) que amplifica la señal de milivoltios de la celda
- **Digitalización**: El ADC convierte el voltaje amplificado en un número entero
- **Representación**: "Cuentas" o "counts" del ADC (sin unidad física directa)

### 4.2 De Dónde Sale en el "JSON"

**Corrección**: No hay JSON. El valor sale directamente de los **primeros 4 bytes del paquete binario** BLE.

**Cadena de origen**:

```
Celda de Carga (sensor físico)
    ↓ (voltaje analógico µV/mV)
Amplificador (ej: HX711)
    ↓ (voltaje amplificado)
ADC (hardware)
    ↓ (valor digital, Int32)
Transmisión BLE
    ↓ (4 bytes, Little Endian)
App Flutter (parseo binario)
    ↓
adcValue (Int32)
```

### 4.3 Unidades

**Unidad técnica**: **"Cuentas ADC"** o **"ADC counts"** (sin dimensión física)

**No tiene unidad física directa**:
- No es kg, gramos, libras, newtons, etc.
- Es un número proporcional al voltaje de entrada del ADC
- La conversión a peso real requiere calibración

### 4.4 Rango Esperado

**No está explícitamente definido en el código de la aplicación**.

**Inferencias posibles**:
- Comentarios mencionan "0 - 4095" en documentación existente, sugiriendo ADC de **12 bits**
- El tipo Int32 soporta hasta 2^31-1 = 2,147,483,647 (mucho más que 12 bits)
- El sistema acepta cualquier valor Int32 (incluso negativos)

**Evidencia en documentación** (`ANALISIS_TECNICO_PESAJE_BLE.md` línea 67):
```
// Rango esperado: 0 - 4095 (12 bits típico de balanza con ADC de 12 bits)
```

**No hay validación de rango en código**: El valor se acepta tal como viene.

---

## 5. FLUJO DE PROCESAMIENTO DEL DATO

### 5.1 Descripción Paso a Paso (Orden Real)

El procesamiento ocurre en `lib/services/weight_service.dart` con un **timer de 100ms**.

#### **PASO 1: Dato Crudo Recibido**

- **Fuente**: Stream `adcStream` de BluetoothService
- **Frecuencia**: ~50ms (desde hardware vía BLE)
- **Almacenamiento**: Variable `_ultimoADC` (int)

```dart
// lib/services/weight_service.dart líneas 101-105
_adcSubscription = _bluetoothService.adcStream.listen((int adc) {
  _ultimoADC = adc;
  _lastAdcTimestamp = DateTime.now();
});
```

#### **PASO 2: Almacenamiento en Buffer Crudo**

- **Objetivo**: Acumular muestras para filtrado posterior
- **Implementación**: Cola FIFO `_rawBuffer` (Queue<int>)
- **Tamaño máximo**: 50 muestras
- **Lógica**: Si se excede el límite, se elimina la muestra más antigua

```dart
// lib/services/weight_service.dart líneas 163-166
_rawBuffer.add(_ultimoADC);
if (_rawBuffer.length > _maxRawBuffer) {
  _rawBuffer.removeFirst();
}
```

#### **PASO 3: Filtro 1 - Trim Mean (Media Podada)**

**Objetivo**: Eliminar valores atípicos (outliers) antes de promediar

**Parámetros configurables**:
- `_trimListSize`: 10 muestras (por defecto)
- `_trimRecortes`: 2 elementos por extremo (fijo en código)

**Algoritmo**:
1. Tomar las últimas 10 muestras del buffer crudo
2. Ordenarlas de menor a mayor
3. Eliminar las 2 mínimas y las 2 máximas
4. Calcular promedio de las 6 restantes

**Código** (`lib/services/weight_service.dart` líneas 227-243):

```dart
double _calculateTrimmedMean() {
  List<int> sorted = List.from(
      _rawBuffer.toList().sublist(_rawBuffer.length - _trimListSize))
    ..sort();

  if (sorted.length <= _trimRecortes * 2) {
    return sorted.reduce((int a, int b) => a + b) / sorted.length;
  }

  List<int> trimmed = sorted.sublist(
    _trimRecortes,
    sorted.length - _trimRecortes,
  );

  if (trimmed.isEmpty) return sorted[sorted.length ~/ 2].toDouble();

  return trimmed.reduce((int a, int b) => a + b) / trimmed.length;
}
```

**Ejemplo numérico**:
```
Muestras crudas (últimas 10): [100, 102, 98, 1050, 103, 99, 101, 97, 104, 100]
Ordenadas: [97, 98, 99, 100, 100, 101, 102, 103, 104, 1050]
Después de trim: [99, 100, 100, 101, 102, 103] (elimina 97, 98, 104, 1050)
Media trimada: (99+100+100+101+102+103) / 6 ≈ 100.83
```

**Salida**: Valor double (ADC promediado y podado)

#### **PASO 4: Almacenamiento en Buffer Trimmed**

```dart
// lib/services/weight_service.dart líneas 172-175
_trimmedBuffer.add(trimmedMean);
if (_trimmedBuffer.length > _maxRawBuffer) {
  _trimmedBuffer.removeFirst();
}
```

#### **PASO 5: Filtro 2 - Moving Average (Ventana Móvil)**

**Objetivo**: Suavizar la señal usando promedios móviles

**Parámetros**:
- `_windowSize`: 5 valores (por defecto, configurable)

**Algoritmo**:
1. Mantener buffer de últimos 5 valores trimmed
2. Calcular promedio aritmético simple de esos 5 valores

**Código** (`lib/services/weight_service.dart` líneas 177-182, 246-250):

```dart
_windowBuffer.add(trimmedMean);
if (_windowBuffer.length > _windowSize) {
  _windowBuffer.removeFirst();
}

double _calculateWindowAverage() {
  if (_windowBuffer.isEmpty) return 0.0;
  double sum = _windowBuffer.reduce((double a, double b) => a + b);
  return sum / _windowBuffer.length;
}
```

**Ejemplo numérico**:
```
Buffer ventana: [100.83, 100.95, 101.10, 100.98, 101.05]
Promedio: (100.83 + 100.95 + 101.10 + 100.98 + 101.05) / 5 = 100.98
```

#### **PASO 6: Filtro 3 - EMA (Exponential Moving Average)**

**Objetivo**: Aplicar filtro exponencial para mayor suavidad y respuesta adaptativa

**Parámetros**:
- `_emaAlpha`: 0.3 (por defecto, configurable)
- Rango válido: 0.0 a 1.0
- Mayor alpha = más peso al valor nuevo (menos suavizado)

**Fórmula**:
```
EMA(t) = alpha × valor_nuevo + (1 - alpha) × EMA(t-1)
```

**Código** (`lib/services/weight_service.dart` líneas 252-261):

```dart
double _applyEMA(double newValue) {
  if (!_emaInitialized) {
    _emaValue = newValue;
    _emaInitialized = true;
    return _emaValue;
  }

  _emaValue = (_emaAlpha * newValue) + ((1 - _emaAlpha) * _emaValue);
  return _emaValue;
}
```

**Ejemplo numérico** (alpha = 0.3):
```
Valor nuevo: 100.98
EMA anterior: 100.50
EMA nuevo: (0.3 × 100.98) + (0.7 × 100.50)
         = 30.294 + 70.35
         = 100.644
```

**Salida**: ADC filtrado final (double)

#### **PASO 7: Calibración - Conversión ADC → Peso Base**

**Objetivo**: Transformar cuentas ADC en kilogramos usando parámetros de calibración

**Parámetros de calibración** (`CalibrationModel`):
- `offset`: Valor ADC cuando no hay peso (cero del sensor)
- `factorEscala`: Factor de conversión ADC → kg

**Fórmula fundamental**:
```
pesoBase (kg) = (ADC_filtrado - offset) × factorEscala
```

**Código** (`lib/services/weight_service.dart` líneas 263-267):

```dart
double _calculateWeight(double adcFiltered) {
  double delta = adcFiltered - _calibration.offset;
  double peso = delta * _calibration.factorEscala;
  return peso;
}
```

**Ejemplo numérico**:
```
ADC filtrado: 1200.5
offset: 500.0
factorEscala: 0.01
pesoBase = (1200.5 - 500.0) × 0.01 = 700.5 × 0.01 = 7.005 kg
```

#### **PASO 8: Corrección - Factor de Corrección**

**Objetivo**: Aplicar factor de ajuste fino para compensar no-linealidades o errores sistemáticos

**Parámetros** (`LoadCellConfig.factorCorreccion`):
- Rango permitido: **-10% a +10%** (-0.10 a 0.10)
- Por defecto: 0.0 (sin corrección)

**Fórmula**:
```
pesoCorregido = pesoBase × (1 + factorCorreccion)
```

**Código** (`lib/services/weight_service.dart` líneas 195-198):

```dart
double factor = _loadCellConfig.factorCorreccion;
if (factor < -0.10) factor = -0.10;
if (factor > 0.10) factor = 0.10;
double pesoCorregido = pesoBase * (1 + factor);
```

**Ejemplo numérico**:
```
pesoBase: 7.005 kg
factorCorreccion: 0.05 (5%)
pesoCorregido = 7.005 × (1 + 0.05) = 7.005 × 1.05 = 7.35525 kg
```

#### **PASO 9: Aplicar Tara**

**Objetivo**: Restar peso de contenedor o tara

**Parámetros**:
- `_tareKg`: Peso de tara en kg (configurable por usuario)

**Fórmula**:
```
pesoNeto = pesoCorregido - tareKg
```

**Código** (`lib/services/weight_service.dart` línea 200):

```dart
double pesoNeto = pesoCorregido - _tareKg;
```

**Ejemplo numérico**:
```
pesoCorregido: 7.355 kg
tareKg: 0.5 kg
pesoNeto = 7.355 - 0.5 = 6.855 kg
```

#### **PASO 10: Aplicar Cero Operativo**

**Objetivo**: Ajuste visual del cero (no persistente, solo para visualización)

**Parámetros**:
- `_zeroOffsetKg`: Offset operativo en kg (no se guarda en persistencia)

**Fórmula**:
```
pesoConZero = pesoNeto - zeroOffsetKg
```

**Código** (`lib/services/weight_service.dart` línea 201):

```dart
double pesoConZero = pesoNeto - _zeroOffsetKg;
```

**Diferencia con offset de calibración**:
- `offset` (calibración): Valor ADC del cero absoluto, persistente
- `_zeroOffsetKg`: Ajuste kg temporal, no persistente

#### **PASO 11: Cuantización a División Mínima**

**Objetivo**: Redondear el peso a la resolución mínima configurable

**Parámetros**:
- `_divisionMinima`: Resolución mínima en kg (ej: 0.01 kg = 10g)

**Fórmula**:
```
pesoFinal = round(pesoConZero / divisionMinima) × divisionMinima
```

**Código** (`lib/services/weight_service.dart` líneas 269-272):

```dart
double _applyDivisionMinima(double peso) {
  if (_divisionMinima <= 0) return peso;
  return (peso / _divisionMinima).round() * _divisionMinima;
}
```

**Ejemplo numérico**:
```
pesoConZero: 6.8567 kg
divisionMinima: 0.01 kg
pesoFinal = round(6.8567 / 0.01) × 0.01
         = round(685.67) × 0.01
         = 686 × 0.01
         = 6.86 kg
```

#### **PASO 12: Detección de Estabilidad**

**Objetivo**: Determinar si el peso es estable (sin oscilaciones)

**Algoritmo**:
1. Mantener buffer de últimos 5 pesos finales
2. Calcular span (diferencia entre máximo y mínimo)
3. Comparar con umbral: `divisionMinima × 0.5`
4. Estable si: `span < umbral`

**Código** (`lib/services/weight_service.dart` líneas 274-285):

```dart
bool _detectStability() {
  if (_pesoWindowBuffer.length < _pesoWindowSize) return false;

  double minPeso = _pesoWindowBuffer.reduce((a, b) => a < b ? a : b);
  double maxPeso = _pesoWindowBuffer.reduce((a, b) => a > b ? a : b);
  double span = (maxPeso - minPeso).abs();

  double threshold = _divisionMinima * 0.5;

  return span < threshold;
}
```

**Ejemplo numérico**:
```
Buffer pesos: [6.86, 6.86, 6.87, 6.86, 6.86]
minPeso: 6.86
maxPeso: 6.87
span: 0.01
threshold: 0.01 × 0.5 = 0.005
span (0.01) >= threshold (0.005) → NO estable
```

#### **PASO 13: Detección de Sobrecarga**

**Objetivo**: Alertar si el peso excede la capacidad de la celda de carga

**Criterio**:
```
overload = (pesoCorregido > capacidadKg)
```

**Nota**: Se usa `pesoCorregido` (antes de tara y cero) para seguridad

**Código** (`lib/services/weight_service.dart` línea 206):

```dart
bool overload = pesoCorregido > _loadCellConfig.capacidadKg;
```

#### **PASO 14: Emisión de Estado Final**

**Salida**: Objeto `WeightState` con todos los datos procesados

**Campos emitidos**:
- `adcRaw`: Último valor ADC recibido (int)
- `adcFiltered`: ADC después de filtros (double)
- `peso`: Peso final en kg (double)
- `estable`: Indicador de estabilidad (bool)
- `overload`: Indicador de sobrecarga (bool)
- `adcActive`: Indicador de timeout (bool)

**Código** (`lib/services/weight_service.dart` líneas 215-224):

```dart
_currentState = WeightState(
  adcRaw: _ultimoADC,
  adcFiltered: emaFiltered,
  peso: pesoFinal,
  estable: estable,
  overload: overload,
  adcActive: _isAdcActive,
);

_weightStateController.add(_currentState);
```

### 5.2 Diagrama de Flujo Completo

```
┌──────────────────────┐
│ BLE Notification     │ Hardware → App (cada ~50ms)
│ 4 bytes (Int32 LE)   │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ adcStream.listen()   │ BluetoothService
│ _ultimoADC = adc     │
└──────────┬───────────┘
           │
           ↓ (Timer 100ms)
┌──────────────────────┐
│ BUFFER CRUDO         │ Queue<int> (max 50)
│ _rawBuffer.add()     │
└──────────┬───────────┘
           │
           ↓ (si >= 10 muestras)
┌──────────────────────┐
│ FILTRO 1: TRIM MEAN  │ Elimina 2 min + 2 max
│ Ordena, poda, promedia│ Salida: double
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ BUFFER TRIMMED       │ Queue<double>
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ FILTRO 2: MOVING AVG │ Promedio últimos 5
│ Ventana: 5 valores   │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ FILTRO 3: EMA        │ alpha=0.3
│ Suavizado exponencial│
└──────────┬───────────┘
           │
           ↓ ADC filtrado
┌──────────────────────┐
│ CALIBRACIÓN          │ peso = (adc - offset) × factor
│ ADC → Peso Base (kg) │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ CORRECCIÓN           │ peso × (1 + corr)
│ Factor ±10%          │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ TARA                 │ peso - tareKg
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ CERO OPERATIVO       │ peso - zeroOffsetKg
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ CUANTIZACIÓN         │ Redondeo a divMin
│ División Mínima      │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ DETECCIÓN ESTABILIDAD│ Span < threshold
│ y SOBRECARGA         │ peso > capacidad
└──────────┬───────────┘
           │
           ↓
┌──────────────────────┐
│ WEIGHT STATE         │ Stream de salida
│ peso final (kg)      │ → UI
└──────────────────────┘
```

### 5.3 Frecuencias de Operación

| Etapa | Frecuencia | Ubicación |
|-------|------------|-----------|
| Recepción BLE | ~50ms | Hardware → BluetoothService |
| Procesamiento completo | 100ms | WeightService timer |
| Emisión de estado | 100ms | weightStateStream |
| Actualización UI | Cuando hay nuevo estado | Listeners en screens |

---

## 6. DECISIONES DE HARDWARE VS SOFTWARE

### 6.1 ¿Qué Depende del Hardware?

**Hardware responsable de**:
1. **Lectura física de celda de carga**
   - Conexión eléctrica a load cell
   - Excitación de puente de Wheatstone
   - Amplificación de señal (probable HX711)

2. **Conversión analógico-digital**
   - ADC integrado que genera las cuentas
   - Resolución del ADC (probablemente 12 bits basado en rango 0-4095)
   - Frecuencia de muestreo del ADC

3. **Transmisión BLE**
   - Implementación del servidor GATT BLE
   - Generación de notificaciones cada ~50ms
   - Empaquetado de Int32 en formato Little Endian

4. **UUIDs personalizados**
   - Definición de servicio y característica
   - Debe coincidir con los UUIDs del código Flutter

**El hardware NO hace**:
- Filtrado de señal (no se observa en datos)
- Calibración (datos son crudos ADC)
- Conversión a unidades de peso
- Detección de estabilidad
- Gestión de tara

### 6.2 ¿Qué es Lógica de Software?

**Software (app Flutter) responsable de**:
1. **Todo el procesamiento de señal**
   - Trim mean
   - Moving average
   - EMA

2. **Calibración completa**
   - Almacenamiento de offset y factor
   - Conversión ADC → kg
   - Factor de corrección

3. **Lógica de negocio**
   - Tara y cero operativo
   - Cuantización
   - Detección de estabilidad
   - Detección de sobrecarga
   - Validación de timeout ADC

4. **Persistencia**
   - Guardar calibración
   - Guardar configuraciones de filtros
   - Historial de sesiones

5. **Interfaz de usuario**
   - Visualización
   - Exportación PDF

### 6.3 ¿Qué NO Debe Cambiarse sin Romper el Sistema?

**Crítico en hardware** (si se cambia, rompe comunicación):
- UUIDs de servicio y característica BLE
- Formato de datos (Int32 Little Endian, 4 bytes)
- MTU acordado (512 bytes configurado)

**Crítico en software** (si se cambia, rompe calibración):
- Fórmula de calibración: `peso = (adc - offset) × factor`
- Orden de operaciones en pipeline (trim → MA → EMA → calibración → corrección → tara)
- Persistencia de parámetros de calibración

**Configurable sin riesgo**:
- Parámetros de filtros (muestras, ventana, alpha)
- Factor de corrección
- División mínima
- Frecuencia de procesamiento (100ms)

---

## 7. SUPUESTOS EXPLÍCITOS DEL SISTEMA

### 7.1 Supuestos de Hardware

1. **El hardware envía datos continuamente** cuando está conectado
   - No requiere comandos de activación desde la app
   - Frecuencia implícita de ~50ms (2x más rápido que procesamiento)

2. **El valor ADC es proporcional al peso**
   - Relación lineal asumida en calibración
   - No se manejan no-linealidades más allá del factor de corrección (±10%)

3. **El hardware usa Int32 Little Endian**
   - Codificado en código de parseo
   - Cambiar esto requiere modificar `_onBinaryDataReceived`

4. **ADC de probablemente 12 bits**
   - Rango 0-4095 mencionado en documentación
   - Pero el código acepta Int32 completo (no valida rango)

### 7.2 Supuestos de Procesamiento

1. **Los filtros requieren suficientes muestras**
   - Trim mean: mínimo 10 muestras en buffer crudo
   - Moving average: mínimo 5 muestras trimmed
   - Si no hay suficientes, no se emite estado

2. **La calibración es válida en todo el rango**
   - Se asume linealidad en todo el rango de peso
   - No hay calibración multi-punto

3. **La estabilidad se detecta con 5 muestras**
   - Hardcoded en tamaño de `_pesoWindowSize`
   - Threshold: 50% de división mínima

4. **El timeout de ADC es 3 segundos**
   - Si no llegan datos por 3s, se marca `adcActive = false`
   - Ubicación: `lib/services/weight_service.dart` línea 44

### 7.3 Supuestos de Conexión BLE

1. **Dispositivo compatible con BLE 4.0+**
   - Tanto hardware como smartphone

2. **Permisos Android concedidos**
   - Android 12+: BLUETOOTH_SCAN, BLUETOOTH_CONNECT
   - Android <12: BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION

3. **Reconexión automática es deseable**
   - Sistema intenta reconectar 3 veces
   - Usuario puede reconectar manualmente si falla

---

## 8. LÍMITES CONOCIDOS

### 8.1 ¿Qué NO Maneja el Sistema?

1. **Validación de rango ADC**
   - No valida si ADC está en rango esperado (0-4095 si es 12 bits)
   - Acepta cualquier Int32, incluso negativos

2. **Calibración multi-punto**
   - Solo calibración de 1 punto (cero) + 1 punto (peso patrón)
   - No corrige no-linealidades complejas

3. **Compensación de temperatura**
   - Celdas de carga derivan con temperatura
   - No hay sensores ni corrección térmica

4. **Detección de errores de hardware**
   - No detecta falla de celda de carga
   - No detecta desconexión física de sensor

5. **Múltiples dispositivos simultáneos**
   - Solo se conecta a 1 dispositivo BLE a la vez

6. **Comunicación bidireccional**
   - Solo recibe datos, no envía comandos al hardware

7. **Histórico de ADC crudo**
   - Solo se guarda peso final en sesiones, no ADC

### 8.2 ¿Qué Pasa si los Datos son Inválidos?

**Paquete BLE incompleto** (`data.length < 4`):
- Se loguea advertencia
- Se descarta el paquete
- No se actualiza `_ultimoADC`
- No afecta stream (no se emite nada)

**Excepción en parseo binario**:
- Se captura en try-catch
- Se loguea error
- Se continúa esperando siguiente paquete

**Valor ADC = 0**:
- Se acepta (puede ser legítimo)
- Pero si persiste, el procesamiento retorna en `if (_ultimoADC == 0) return;`
- No se procesa, no se emite estado

**Timeout de ADC (sin datos por 3s)**:
- Se marca `adcActive = false`
- Se emite `WeightState` con peso 0 y flag de inactividad
- UI puede mostrar advertencia

**Desconexión BLE**:
- Se detiene stream de datos
- Se intenta reconexión automática (3 intentos)
- Si falla, usuario debe reconectar manualmente

### 8.3 Límites de Capacidad

**Capacidad máxima de peso**:
- Definida por `LoadCellConfig.capacidadKg` (default: 20,000 kg)
- Sobrecarga detectada si `peso > capacidad`
- No impide operación, solo alerta

**División mínima**:
- Define resolución de visualización
- Default: 10 kg (configurable)
- No limita precisión interna (siempre double)

---

## 9. DUDAS TÉCNICAS

Durante la extracción de conocimiento, se identificaron las siguientes ambigüedades que requieren confirmación:

### 9.1 ❓ DUDA: Resolución Real del ADC

**Contexto**:
- La documentación menciona "0 - 4095" sugiriendo ADC de 12 bits
- El código usa Int32 que soporta ±2 mil millones
- No hay validación de rango en el código

**Qué no está claro**:
- ¿El hardware realmente envía 12 bits o más?
- ¿Por qué se usa Int32 si el rango es 12 bits?
- ¿Puede el ADC enviar valores negativos? ¿Qué significarían?

**Opciones existentes**:
1. ADC es realmente 12 bits (0-4095), Int32 es oversizing por simplicidad
2. ADC puede ser mayor (16/24 bits), y se usa todo el rango
3. Valores negativos son válidos (sensor bipolar)

**Necesita confirmación**:
- Especificación del hardware real
- Datasheet de ADC usado
- Pruebas con valores extremos

### 9.2 ❓ DUDA: Frecuencia Exacta de Envío BLE

**Contexto**:
- Se infiere "~50ms" de comportamiento observado
- No está documentado en código de la app
- El procesamiento es cada 100ms (2x más lento)

**Qué no está claro**:
- ¿50ms es frecuencia garantizada del hardware?
- ¿Puede variar? ¿Qué tan estable es?
- ¿Hay jitter significativo?

**Opciones existentes**:
1. Hardware envía a frecuencia fija 50ms (20 Hz)
2. Hardware envía cuando hay nuevo ADC disponible (variable)
3. Hardware envía a otra frecuencia y 50ms es aproximación

**Necesita confirmación**:
- Revisar código del firmware del hardware
- Medir tiempos reales entre notificaciones BLE

### 9.3 ❓ DUDA: Significado de Bytes Adicionales

**Contexto**:
- El código solo lee los primeros 4 bytes
- MTU configurado a 512 bytes
- No se documenta si existen bytes adicionales

**Qué no está claro**:
- ¿El hardware envía solo 4 bytes siempre?
- ¿Existen bytes adicionales con otros datos?
- Si existen, ¿qué contienen? (temperatura, batería, checksum, etc.)

**Opciones existentes**:
1. Hardware envía exactamente 4 bytes (ADC únicamente)
2. Hardware envía más datos que la app ignora
3. Hardware envía 4 bytes ahora, pero protocolo permite extensión futura

**Necesita confirmación**:
- Captura real de paquetes BLE (sniffer Bluetooth)
- Documentación del protocolo del hardware

### 9.4 ❓ DUDA: Razón del Orden de Filtros

**Contexto**:
- Pipeline: Trim → Moving Avg → EMA
- Orden específico implementado

**Qué no está claro**:
- ¿Por qué este orden específico?
- ¿Fue resultado de pruebas empíricas?
- ¿Existe fundamento teórico documentado?

**Opciones existentes**:
1. Orden óptimo encontrado experimentalmente
2. Orden basado en teoría de procesamiento de señales
3. Orden arbitrario que funciona suficientemente bien

**Necesita confirmación**:
- Documentación de decisiones de diseño
- Comparación con otros órdenes posibles

### 9.5 ❓ DUDA: Modelo de Celda de Carga

**Contexto**:
- `LoadCellConfig` tiene parámetros de hardware:
  - `capacidadKg`
  - `sensibilidadMvV`
  - `voltajeExcitacion`
  - `gananciaHX711`
  - `voltajeReferencia`
- Estos valores no se usan en cálculos actuales

**Qué no está claro**:
- ¿Son solo metadatos informativos?
- ¿Estaban previstos para cálculos teóricos de calibración?
- ¿Se usarán en futuras versiones?

**Opciones existentes**:
1. Metadatos para documentación solamente
2. Originalmente se usaban, ahora obsoletos
3. Planificados para uso futuro (calibración automática)

**Necesita confirmación**:
- Historial de cambios en código
- Intención original del diseño

---

## 📝 CONCLUSIONES

Este documento ha extraído y descrito exhaustivamente el sistema actual de recepción BLE y procesamiento de peso del proyecto F16 Balanza Electrónica. Se ha documentado:

✅ **Comunicación BLE**: UUIDs, protocolo binario (4 bytes Int32 Little Endian), frecuencia ~50ms  
✅ **Pipeline completo**: 11 pasos desde ADC crudo hasta peso final  
✅ **Filtros**: Trim Mean → Moving Average → EMA (orden y parámetros)  
✅ **Calibración**: Fórmula `peso = (adc - offset) × factor`  
✅ **Correcciones**: Factor ±10%, tara, cero operativo, cuantización  
✅ **Detecciones**: Estabilidad, sobrecarga, timeout  
✅ **Límites**: Qué NO hace el sistema  
✅ **Dudas**: 5 ambigüedades identificadas que requieren confirmación

### Recomendaciones para Reutilización

1. **El pipeline de filtrado es reutilizable tal cual** en otros proyectos de pesaje
2. **Los UUIDs BLE deben coincidir** con el hardware destino
3. **La calibración requiere 2 puntos**: cero y peso patrón
4. **El orden de filtros no debe alterarse** sin re-validar
5. **Las dudas técnicas deben resolverse** antes de cambios sustanciales

---

**Fin del documento de extracción**
