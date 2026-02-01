# 📊 ANÁLISIS TÉCNICO COMPLETO — Sistema de Pesaje y Bluetooth (F16)
**Documento de Arquitectura para Reutilización en F22**

**Versión**: 2.0.4  
**Generado**: 1 de febrero de 2026  
**Destino**: Equipo de desarrollo F22  
**Propósito**: Documentación técnica para extracción e integración de lógica de pesaje y Bluetooth sin cambios sustanciales

---

## 📋 TABLA DE CONTENIDOS

1. [Comunicación Bluetooth](#1-comunicación-bluetooth)
2. [Flujo: Dato Crudo → Peso Real](#2-flujo-dato-crudo--peso-real)
3. [Tara, Cero y Offset](#3-tara-cero-y-offset)
4. [Filtrado y Estabilidad](#4-filtrado-y-estabilidad)
5. [Reconexión Bluetooth](#5-reconexión-bluetooth)
6. [Calibración](#6-calibración)
7. [Manejo de Errores](#7-manejo-de-errores)
8. [Arquitectura Interna](#8-arquitectura-interna)
9. [Reutilización para F22](#9-reutilización-para-f22)
10. [Conclusión Técnica](#10-conclusión-técnica)

---

## 1. COMUNICACIÓN BLUETOOTH

### 1.1 Tipo de Bluetooth

**Protocolo**: BLE (Bluetooth Low Energy)  
**Especificación**: Bluetooth 4.0+  
**Librería**: `flutter_blue_plus: ^2.1.0`  
**Roles Implementados**: 
- Cliente (aplicación Flutter)
- Cliente de servicios BLE

### 1.2 Estructura de Servicios y Características

| Elemento | UUID | Descripción |
|----------|------|-------------|
| **Servicio BLE** | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | Servicio personalizado para transmisión de datos de peso |
| **Característica BLE** | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | Característica de notificación para recepción de ADC |
| **Propiedades Características** | `notify` | Permite notificaciones desde el servidor (balanza) |

### 1.3 Protocolo de Datos

#### Formato del Mensaje

| Aspecto | Descripción |
|--------|-------------|
| **Tipo de Dato** | Binario (bytes) |
| **Tamaño Mínimo** | 4 bytes (requeridos) |
| **Tamaño Máximo** | MTU 512 (configurado) |
| **Estructura** | Los primeros 4 bytes contienen el valor ADC en formato **Int32 Little Endian** |
| **Validación** | Se valida que los datos tengan al menos 4 bytes |

#### Ejemplo de Payload Recibido

```
Paquete Binario Crudo:
[0xE8, 0x03, 0x00, 0x00, ...bytes adicionales...]

Interpretación:
- Bytes 0-3: [0xE8, 0x03, 0x00, 0x00]
- Conversión Little Endian (Int32): 1000 (0x03E8 en hex)
- ADC Raw Value: 1000
- Rango esperado: 0 - 4095 (12 bits típico de balanza con ADC de 12 bits)
```

#### Procesamiento de Datos en Código

```dart
// Ubicación: lib/services/bluetooth_service.dart → _onBinaryDataReceived()
void _onBinaryDataReceived(List<int> data) {
  try {
    // Validar tamaño mínimo (4 bytes requeridos)
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

### 1.4 Frecuencia de Envío

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| **Intervalo de Notificaciones** | 50 ms | Período configurado en la balanza para enviar datos |
| **Activación** | Automática | Una vez conectado, inicia automáticamente |
| **Paradas** | Al desconectar | Notificaciones se detienen al cerrar conexión BLE |

### 1.5 Flujo de Conexión Bluetooth

```
┌────────────────────────────────┐
│ 1. Usuario selecciona dispositivo
│    (MAC address de balanza BLE)
└────────────────┬───────────────┘
                 │
                 ▼
┌────────────────────────────────┐
│ 2. BluetoothService.connect()
│    - Estado: CONNECTING
│    - Timeout: 15 segundos
└────────────────┬───────────────┘
                 │
                 ▼
┌────────────────────────────────┐
│ 3. Conectar a dispositivo físico
│    (device.connect con license: Free)
│    - MTU: 512
│    - AutoConnect: false
└────────────────┬───────────────┘
                 │
                 ▼
┌────────────────────────────────┐
│ 4. Descubrir servicios BLE
│    (discoverServices())
│    - Buscar UUID del servicio
│    - Validar existencia
└────────────────┬───────────────┘
                 │
                 ▼
┌────────────────────────────────┐
│ 5. Descubrir características
│    - Buscar UUID de característica
│    - Validar propiedades (notify)
└────────────────┬───────────────┘
                 │
                 ▼
┌────────────────────────────────┐
│ 6. Activar notificaciones
│    (setNotifyValue(true))
│    - Habilita recepción de datos
└────────────────┬───────────────┘
                 │
                 ▼
┌────────────────────────────────┐
│ 7. Suscribirse a datos
│    (onValueReceived.listen())
│    - Listener para cada paquete
│    - Callback: _onBinaryDataReceived()
└────────────────┬───────────────┘
                 │
                 ▼
┌────────────────────────────────┐
│ 8. Estado: CONNECTED
│    - ADC stream activo
│    - Recibiendo datos cada ~50ms
└────────────────────────────────┘
```

### 1.6 Manejo de Conexiones Previas

```dart
// Ubicación: lib/services/bluetooth_service.dart → connect()
Future<bool> connect(fbp.ScanResult scanResult) async {
  try {
    // Si hay conexión previa, desconectar primero
    if (status != BluetoothStatus.disconnected) {
      await disconnect();
    }

    _statusNotifier.value = BluetoothStatus.connecting;
    
    // ... resto del flujo de conexión
  }
}
```

---

## 2. FLUJO: DATO CRUDO → PESO REAL

### 2.1 Dato Crudo (ADC)

| Propiedad | Descripción |
|-----------|-------------|
| **Tipo de Dato** | `int` de 32 bits (en Dart) |
| **Origen** | Convertidor ADC (12 bits típicamente) en hardware ESP32 |
| **Rango Esperado** | 0 - 4095 (asumiendo 12 bits) o mayor según configuración |
| **Envío** | Cada ~50 ms vía Bluetooth |
| **Almacenamiento Temporal** | Último valor en `_ultimoADC` |

### 2.2 Pipeline de Procesamiento

#### Diagrama General

```
┌─────────────┐
│ ADC Raw (1)│ 
│  0 - 4095   │
└──────┬──────┘
       │ (Cada 100ms)
       ▼
┌─────────────────────────────────────────────┐
│ 2. Buffer de Muestras Crudas                │
│    - Almacenar últimas 50 muestras         │
│    - Cola FIFO (_rawBuffer)                │
└──────┬──────────────────────────────────────┘
       │ (Cuando tenemos >= 10 muestras)
       ▼
┌─────────────────────────────────────────────┐
│ 3. Trim de Extremos                        │
│    - Ordenar últimas 10 muestras           │
│    - Eliminar 2 máximos y 2 mínimos       │
│    - Promediar restantes                   │
│    - Resultado: valor "podado"            │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ 4. Ventana Móvil (Moving Average)          │
│    - Almacenar últimos 5 valores podados   │
│    - Calcular promedio de ventana          │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ 5. Filtro EMA (Exponential Moving Average) │
│    - Alpha = 0.3 (configurable)            │
│    - EMA = (alpha * nuevo) + (1-alpha)*EMA│
│    - Resultado: ADC filtrado               │
└──────┬──────────────────────────────────────┘
       │ (Valor ADC Filtrado)
       ▼
┌─────────────────────────────────────────────┐
│ 6. Conversión a Peso                       │
│    - Fórmula:                              │
│      pesoBase = (ADC_filtrado - offset)    │
│                  × factorEscala             │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ 7. Factor de Corrección                    │
│    - Rango permitido: -10% a +10%          │
│    - pesoCorregido = pesoBase              │
│      × (1 + factorCorreccion)              │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ 8. Aplicar Tara                            │
│    - pesoNeto = pesoCorregido - tareKg    │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ 9. Aplicar Cero Operativo                  │
│    - pesoFinal = pesoNeto - zeroOffsetKg  │
│    - (Solo visual, no persistente)         │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ 10. Cuantizar a División Mínima             │
│     - Redondear a múltiplo de divMin      │
│     - Ej: 123.456 → 123.46 (divMin=0.01) │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ 11. Peso Final (kg)                         │
│     - Listo para visualización              │
│     - Almacenado en WeightState            │
└─────────────────────────────────────────────┘
```

### 2.3 Fórmulas Matemáticas Exactas

#### 2.3.1 Cálculo de Media Podada (Trimmed Mean)

```dart
double _calculateTrimmedMean() {
  // 1. Tomar últimas N muestras (_trimListSize = 10)
  List<int> rawSamples = _rawBuffer.toList()
    .sublist(_rawBuffer.length - _trimListSize)
    ..sort(); // 2. Ordenar

  // 3. Si hay muy pocas muestras, devolver promedio simple
  if (rawSamples.length <= _trimRecortes * 2) {
    return rawSamples.reduce((a, b) => a + b) / rawSamples.length;
  }

  // 4. Eliminar _trimRecortes elementos de cada extremo
  List<int> trimmed = rawSamples.sublist(
    _trimRecortes,                          // Índice inicial (elimina _trimRecortes mínimos)
    rawSamples.length - _trimRecortes,      // Índice final (elimina _trimRecortes máximos)
  );

  // 5. Si queda vacío, devolver mediana
  if (trimmed.isEmpty) {
    return rawSamples[rawSamples.length ~/ 2].toDouble();
  }

  // 6. Promediar muestras restantes
  return trimmed.reduce((a, b) => a + b) / trimmed.length;
}

// Ejemplo con datos reales:
// Muestras crudas (últimas 10): [100, 102, 98, 1050, 103, 99, 101, 97, 104, 100]
// Ordenadas: [97, 98, 99, 100, 100, 101, 102, 103, 104, 1050]
// Después trim (eliminar 2 menores y 2 mayores): [99, 100, 100, 101, 102, 103, 104]
// Media trimada: (99+100+100+101+102+103+104) / 7 ≈ 101.29
```

#### 2.3.2 Ventana Móvil (Moving Average)

```dart
double _calculateWindowAverage() {
  if (_windowBuffer.isEmpty) return 0.0;
  double sum = _windowBuffer.reduce((a, b) => a + b);
  return sum / _windowBuffer.length;
}

// Ejemplo:
// _windowBuffer (últimos 5 valores podados): [101.29, 100.95, 101.10, 100.98, 101.05]
// Promedio: (101.29 + 100.95 + 101.10 + 100.98 + 101.05) / 5 = 101.07
```

#### 2.3.3 Filtro EMA (Exponential Moving Average)

```dart
double _applyEMA(double newValue) {
  // Primera inicialización
  if (!_emaInitialized) {
    _emaValue = newValue;
    _emaInitialized = true;
    return _emaValue;
  }

  // Fórmula EMA: EMA(t) = alpha * X(t) + (1 - alpha) * EMA(t-1)
  _emaValue = (_emaAlpha * newValue) + ((1 - _emaAlpha) * _emaValue);
  return _emaValue;
}

// Ejemplo con alpha = 0.3:
// Nuevo valor: 101.07
// EMA anterior: 100.50
// EMA nuevo: (0.3 × 101.07) + (0.7 × 100.50)
//          = 30.321 + 70.35
//          = 100.671
```

#### 2.3.4 Conversión ADC → Peso (Calibración)

```dart
double _calculateWeight(double adcFiltered) {
  // Fórmula fundamental:
  // peso = (ADC_filtrado - offset) × factorEscala
  
  double delta = adcFiltered - _calibration.offset;
  double peso = delta * _calibration.factorEscala;
  return peso;
}

// Ejemplo de calibración:
// offset = 500 (cero del sensor)
// factorEscala = 0.01 (cada 100 unidades ADC = 1 kg)
// ADC_filtrado = 1200
// 
// peso = (1200 - 500) × 0.01 = 700 × 0.01 = 7.0 kg
```

#### 2.3.5 Factor de Corrección

```dart
double factor = _loadCellConfig.factorCorreccion;
// Limitar a rango (-10%, +10%)
if (factor < -0.10) factor = -0.10;
if (factor > 0.10) factor = 0.10;

double pesoCorregido = pesoBase * (1 + factor);

// Ejemplo:
// pesoBase = 7.0 kg
// factorCorreccion = 0.05 (5%)
// pesoCorregido = 7.0 × (1 + 0.05) = 7.0 × 1.05 = 7.35 kg
```

#### 2.3.6 Aplicación de Tara

```dart
double pesoNeto = pesoCorregido - _tareKg;

// Ejemplo:
// pesoCorregido = 7.35 kg
// _tareKg = 0.50 kg (peso del recipiente)
// pesoNeto = 7.35 - 0.50 = 6.85 kg
```

#### 2.3.7 Cero Operativo (Visual)

```dart
double pesoConZero = pesoNeto - _zeroOffsetKg;

// _zeroOffsetKg es NO PERSISTENTE (solo para esta sesión)
// Permite "ajustar a cero" visualmente sin cambiar calibración
```

#### 2.3.8 Cuantización a División Mínima

```dart
double _applyDivisionMinima(double peso) {
  if (_divisionMinima <= 0) return peso;
  
  // Redondear al múltiplo más cercano de _divisionMinima
  return (peso / _divisionMinima).round() * _divisionMinima;
}

// Ejemplo con divisionMinima = 0.10 kg:
// peso = 6.8534 kg
// (6.8534 / 0.10).round() = 68.534 → 69
// 69 × 0.10 = 6.90 kg
```

### 2.4 Resumen del Flujo Completo

| Paso | Entrada | Proceso | Salida |
|------|---------|---------|--------|
| 1 | ADC Raw (1200) | - | 1200 |
| 2 | ADC Raw | Buffer → Trim | 1201.29 |
| 3 | Trim | Ventana móvil | 1201.07 |
| 4 | Ventana | EMA (α=0.3) | 1200.67 |
| 5 | EMA | Calibración | 7.0067 kg |
| 6 | Peso Base | Factor +5% | 7.3570 kg |
| 7 | Peso Corregido | Tara -0.5kg | 6.8570 kg |
| 8 | Peso Neto | Cero op. 0 | 6.8570 kg |
| 9 | Peso Final | Cuantizar 0.1 | **6.9 kg** |

---

## 3. TARA, CERO Y OFFSET

### 3.1 Conceptos Diferenciados

| Concepto | Persistencia | Scope | Propósito | Método |
|----------|--------------|-------|----------|--------|
| **Offset (Cero Calibración)** | ✅ Persistente | Global | Calibración inicial del sensor | `setZeroNow()` |
| **Tara** | ❌ No persistente | Sesión | Restar peso recipiente | `setTareKg()` / `takeTareNow()` |
| **Cero Operativo** | ❌ No persistente | Sesión | Ajuste visual sin cambiar calibración | `setZeroOffset()` |

### 3.2 Offset (Cero de Calibración)

```dart
// Ubicación: lib/models/calibration_model.dart
class CalibrationModel {
  final double offset;  // ← Offset es el valor ADC cuando balanza = 0
  final double adcReferencia;
  final double pesoPatron;
  final double factorEscala;
}

// Ubicación: lib/services/weight_service.dart
void setZeroNow() {
  if (_emaInitialized) {
    // Tomar el valor EMA actual como nuevo offset
    _calibration = _calibration.copyWith(offset: _emaValue);
    
    // Persistir en SharedPreferences
    _persistenceService.saveCalibration(_calibration);
    
    // Reiniciar filtros para nueva calibración
    _resetFilters();
  }
}
```

**Ejemplo de Flujo:**

```
1. Usuario coloca balanza vacía sobre plato
2. Estabilización: Lee ADC filtrado = 510
3. Usuario presiona botón "Tomar Cero"
4. Sistema: offset = 510 (persistido en SharedPreferences)
5. Desde ahora: peso = (ADC_filtrado - 510) × factorEscala
6. Cuando ADC_filtrado = 510, peso = 0 kg ✅
```

### 3.3 Tara

```dart
// Ubicación: lib/services/weight_service.dart

void setTareKg(double tare) {
  // Fijar tara a un valor específico (no persistente)
  _tareKg = tare;
}

void takeTareNow() {
  // Acumular tara: nueva_tara = peso_actual + tara_anterior
  _tareKg = _currentState.peso + _tareKg;
}
```

**Ejemplos de Tara:**

```
Escenario 1: Recipiente simple
═════════════════════════════
1. Coloca recipiente vacío: peso_bruto = 0.50 kg
2. Usuario presiona "TARA"
3. Sistema: _tareKg = 0.50 kg
4. Peso neto: 0.50 - 0.50 = 0.00 kg
5. Agrega producto: peso_bruto = 2.75 kg
6. Peso neto: 2.75 - 0.50 = 2.25 kg ✅

Escenario 2: Tara múltiple (acumulativa)
════════════════════════════════════════
1. Recipiente: 0.50 kg → TARA
   _tareKg = 0.50
2. Peso mostrado: 0.00 kg
3. Agrega primer ingrediente: 1.00 kg
   Peso mostrado: 1.00 kg
4. Usuario presiona TARA nuevamente
   _tareKg = 1.00 + 0.50 = 1.50 kg
5. Peso mostrado: 0.00 kg
6. Agrega segundo ingrediente: 0.30 kg
   Peso mostrado: 0.30 kg
7. Peso total: 1.50 + 0.30 = 1.80 kg
```

**Restaurar Tara:**

```dart
void setTareKg(double tare) {
  _tareKg = tare;
}

// Ejemplos de uso:
_weightService.setTareKg(0.0);  // Resetear tara
_weightService.setTareKg(0.50); // Fijar tara a 0.50 kg
```

### 3.4 Cero Operativo (Visual)

```dart
// Ubicación: lib/services/weight_service.dart

void setZeroOffset() {
  // Acumular cero operativo: nuevo_cero = peso_actual + cero_anterior
  _zeroOffsetKg = _currentState.peso + _zeroOffsetKg;
}

// En el cálculo de peso:
double pesoConZero = pesoNeto - _zeroOffsetKg;
```

**Diferencia: Tara vs Cero Operativo:**

```
Tara: Restar peso de recipiente ANTES de agregar producto
╔═══════════════════════════════════════════════════════════╗
║ pesoFinal = (pesoCorregido - tareKg) - zeroOffsetKg      ║
╚═══════════════════════════════════════════════════════════╝

Cero Operativo: Ajuste visual DESPUÉS de tara
╔═══════════════════════════════════════════════════════════╗
║ Permite "reajustar a cero" visualmente durante sesión    ║
║ Sin afectar calibración (no persistente)                 ║
╚═══════════════════════════════════════════════════════════╝

Ejemplo práctico:
═════════════════
1. Balanza inicialmente: 0.00 kg (correcta)
2. Usuario agrega 5 kg: 5.00 kg
3. Usuario presiona CERO: zeroOffsetKg = 5.00
4. Pantalla muestra: 5.00 - 5.00 = 0.00 kg
5. Usuario agrega más: 5.50 kg
6. Pantalla muestra: 5.50 - 5.00 = 0.50 kg (incremento visible)
```

### 3.5 Cuándo Se Aplica Cada Corrección

```
Secuencia de aplicación en _processData():
═══════════════════════════════════════════

1. pesoBase = (ADC_filtrado - offset) × factorEscala
               ▲─────────────────────────────────────
               └─ Offset aplicado AQUÍ

2. pesoCorregido = pesoBase × (1 + factorCorreccion)

3. pesoNeto = pesoCorregido - _tareKg
               ▲──────────────────────
               └─ Tara aplicada AQUÍ

4. pesoConZero = pesoNeto - _zeroOffsetKg
                 ▲────────────────────────
                 └─ Cero operativo AQUÍ

5. pesoFinal = _applyDivisionMinima(pesoConZero)
```

---

## 4. FILTRADO Y ESTABILIDAD

### 4.1 Parámetros de Filtrado

```dart
// Ubicación: lib/models/filter_params.dart
class FilterParams {
  final int muestras;           // Tamaño trim (default: 10)
  final int ventana;            // Tamaño ventana móvil (default: 5)
  final double emaAlpha;        // Coeficiente EMA (default: 0.3)
  final int updateIntervalMs;   // Intervalo procesamiento (default: 100ms)
  final double limiteSuperior;  // Límite superior (default: 1000000)
  final double limiteInferior;  // Límite inferior (default: -1000000)
}

// Valores por defecto:
FilterParams.defaultParams() = FilterParams(
  muestras: 10,
  ventana: 5,
  emaAlpha: 0.3,
  updateIntervalMs: 100,
  limiteSuperior: 1000000.0,
  limiteInferior: -1000000.0,
);
```

### 4.2 Método de Filtrado: Cascada de Tres Etapas

```
┌──────────────────────────────────────────────────┐
│ ETAPA 1: TRIM DE EXTREMOS (Eliminar outliers)   │
│                                                  │
│ Entrada: Últimas N muestras ADC crudas          │
│ Acción: Descartar M mínimos y M máximos         │
│ Salida: Media de muestras "interiores"          │
│                                                  │
│ Parámetro: muestras = 10 (por defecto)          │
│            Descartar los 2 menores y 2 mayores  │
│            Promediar los 6 interiores           │
│                                                  │
│ Ventaja: Elimina picos (interferencia RF, ruido)│
└──────────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 2: VENTANA MÓVIL (Moving Average)         │
│                                                  │
│ Entrada: Últimos N valores podados              │
│ Acción: Promediar sin ponderación               │
│ Salida: Promedio simple                         │
│                                                  │
│ Parámetro: ventana = 5 (por defecto)            │
│            Promediar últimas 5 muestras podadas │
│                                                  │
│ Ventaja: Suavizado lineal simple                │
└──────────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 3: FILTRO EMA (Exponential Smoothing)     │
│                                                  │
│ Entrada: Última promedio de ventana             │
│ Acción: EMA = α×X + (1-α)×EMA_anterior         │
│ Salida: Valor suavizado exponencialmente        │
│                                                  │
│ Parámetro: emaAlpha = 0.3 (por defecto)         │
│            Mayor alpha = más respuesta rápida  │
│            Menor alpha = más suavización        │
│                                                  │
│ Ventaja: Equilibrio entre respuesta y ruido    │
└──────────────────────────────────────────────────┘
                        │
                        ▼
                   ADC Filtrado
```

### 4.3 Efecto de Parámetros

#### Alpha del EMA

| Alpha | Velocidad | Ruido | Caso de Uso |
|-------|-----------|-------|-----------|
| 0.1 | Lenta | Bajo (muy suavizado) | Aplicaciones estables, poco movimiento |
| 0.3 | Media | Medio (balanceado) | **Default - Balanzas normales** |
| 0.5 | Rápida | Alto (menos suavizado) | Aplicaciones dinámicas, cambios rápidos |
| 0.7 | Muy Rápida | Muy Alto | No recomendado para balanzas |

#### Tamaño de Trim

| Muestras | Efecto |
|----------|--------|
| 5 | Muy sensible a outliers |
| 10 | **Default - Balance óptimo** |
| 20 | Menos sensible a ruido, pero más lento |
| 50 | Muy suavizado, retraso significativo |

### 4.4 Detección de Estabilidad

```dart
// Ubicación: lib/services/weight_service.dart
bool _detectStability() {
  // Verificar que hay suficientes muestras
  if (_pesoWindowBuffer.length < _pesoWindowSize) {
    return false;
  }

  // Encontrar rango de pesos en ventana
  double minPeso = _pesoWindowBuffer
    .reduce((a, b) => a < b ? a : b);
  
  double maxPeso = _pesoWindowBuffer
    .reduce((a, b) => a > b ? a : b);
  
  // Calcular amplitud del rango
  double span = (maxPeso - minPeso).abs();

  // Threshold para estabilidad: mitad de división mínima
  double threshold = _divisionMinima * 0.5;

  // Estable si rango < threshold
  return span < threshold;
}

// Ejemplos:
// ─────────
// divisionMinima = 0.10 kg
// threshold = 0.05 kg
// pesoWindow = [5.10, 5.11, 5.09, 5.12, 5.10]
// span = 5.12 - 5.09 = 0.03 kg
// 0.03 < 0.05 ✅ → ESTABLE

// pesoWindow = [5.00, 5.15, 5.05, 5.20, 5.10]
// span = 5.20 - 5.00 = 0.20 kg
// 0.20 > 0.05 ❌ → INESTABLE
```

### 4.5 Intervalo de Actualización

```dart
// Ubicación: lib/services/weight_service.dart
void start() {
  _processingTimer = Timer.periodic(
    Duration(milliseconds: _updateIntervalMs),  // Default: 100 ms
    (Timer timer) => _processData(),
  );
}

// Intervalo configurado en FilterParams
// Default: 100 ms (10 actualizaciones/segundo)
// Rango recomendado: 50 - 200 ms
```

### 4.6 Buffers Internos

| Buffer | Tipo | Tamaño Máx | Propósito |
|--------|------|-----------|-----------|
| `_rawBuffer` | `Queue<int>` | 50 | Almacenar ADC crudos |
| `_trimmedBuffer` | `Queue<double>` | 50 | Almacenar valores podados |
| `_windowBuffer` | `Queue<double>` | 5 | Ventana móvil |
| `_pesoWindowBuffer` | `Queue<double>` | 5 | Detección estabilidad |

---

## 5. RECONEXIÓN BLUETOOTH

### 5.1 Detección de Desconexión

```dart
// Ubicación: lib/services/bluetooth_service.dart → _onConnectionStateChanged()
void _onConnectionStateChanged(fbp.BluetoothConnectionState state) {
  debugPrint('[BLE_STATE] Cambio de estado: $state');

  if (state == fbp.BluetoothConnectionState.disconnected) {
    // Detectada desconexión
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;

    // ¿Fue desconexión manual o involuntaria?
    if (!_manualDisconnect && _lastDevice != null) {
      // Involuntaria → Intentar auto-reconectar
      _reconnectAttempts = 0;
      _attemptAutoReconnect();
    } else {
      // Manual → Solo limpiar
      debugPrint('[BLE_STATE] Desconexión manual confirmada');
      _reconnectAttempts = 0;
    }
  }
}
```

### 5.2 Procedimiento de Auto-Reconexión

```
┌─────────────────────────────────────┐
│ Desconexión Detectada               │
│ (estado == disconnected)             │
└────────────┬────────────────────────┘
             │
             ▼ ¿Desconexión manual?
        ┌────────────┐
    NO  │            │ SÍ
        ▼            ▼
┌───────────────┐  Limpiar
│ Auto-reconect │  y terminar
└────────┬──────┘
         │
         ▼ Esperar 2 segundos
┌────────────────────────────────┐
│ INTENTO 1                      │
│ - Estado: CONNECTING           │
│ - Descubrir servicios BLE      │
│ - Activar notificaciones       │
│ - Timeout: 15s                 │
└────────┬───────────────────────┘
         │
         ├─ Éxito → Estado: CONNECTED → FIN
         │
         └─ Fallo ↓
           
┌────────────────────────────────┐
│ Esperar 5 segundos             │
│ INTENTO 2                      │
│ (mismo procedimiento)           │
└────────┬───────────────────────┘
         │
         ├─ Éxito → Estado: CONNECTED → FIN
         │
         └─ Fallo ↓
           
┌────────────────────────────────┐
│ Esperar 10 segundos            │
│ INTENTO 3                      │
│ (mismo procedimiento)           │
└────────┬───────────────────────┘
         │
         ├─ Éxito → Estado: CONNECTED → FIN
         │
         └─ Fallo ↓
           
┌────────────────────────────────┐
│ Máximo de intentos alcanzado   │
│ Estado: ERROR                  │
│ Usuario notificado             │
└────────────────────────────────┘
```

### 5.3 Código de Auto-Reconexión

```dart
// Ubicación: lib/services/bluetooth_service.dart → _attemptAutoReconnect()
void _attemptAutoReconnect() {
  debugPrint(
    '[BLE_RECONNECT] Esperando 2s antes de auto-reconectar...'
  );

  Future.delayed(const Duration(seconds: 2), () async {
    if (_lastDevice == null || _manualDisconnect) {
      debugPrint('[BLE_RECONNECT] Cancelado');
      return;
    }

    _reconnectAttempts++;
    debugPrint(
      '[BLE_RECONNECT] Intento $_reconnectAttempts/$_maxReconnectAttempts'
    );

    try {
      // Delay progresivo:
      // Intento 1: Ya esperamos 2s antes
      // Intento 2: Esperar 5s adicionales
      // Intento 3: Esperar 10s adicionales
      if (_reconnectAttempts > 1) {
        final int delaySeconds = _reconnectAttempts == 2 ? 5 : 10;
        debugPrint(
          '[BLE_RECONNECT] Esperando ${delaySeconds}s antes del intento $_reconnectAttempts...'
        );
        await Future.delayed(Duration(seconds: delaySeconds));
      }

      if (_manualDisconnect) {
        debugPrint('[BLE_RECONNECT] Desconexión manual detectada, cancelando');
        return;
      }

      debugPrint('[BLE_RECONNECT] Intentando reconectar...');
      
      // Conectar al dispositivo guardado
      await _lastDevice!.connect(
        license: fbp.License.free,
        timeout: const Duration(seconds: 15),
        mtu: 512,
        autoConnect: false,
      );

      // RE-INICIALIZAR COMPLETAMENTE
      // (Descubrir servicios, características, activar notificaciones)
      // [código idéntico al flujo de connect()]

      debugPrint(
        '[BLE_RECONNECT] ✅ Auto-reconexión exitosa en intento $_reconnectAttempts'
      );
      _reconnectAttempts = 0; // Reset tras éxito
    } catch (e) {
      debugPrint(
        '[BLE_RECONNECT] ❌ Intento $_reconnectAttempts falló: $e'
      );
      _statusNotifier.value = BluetoothStatus.error;
      _scheduleNextReconnectAttempt();
    }
  });
}

// Máximo de intentos
static const int _maxReconnectAttempts = 3;
```

### 5.4 Reconexión Manual desde UI

```dart
// Ubicación: lib/services/bluetooth_service.dart → attemptManualReconnect()
Future<void> attemptManualReconnect() async {
  try {
    if (_lastDevice == null) {
      debugPrint('[BLE_MANUAL_RECONNECT] No hay dispositivo guardado');
      return;
    }

    if (_statusNotifier.value == BluetoothStatus.connected) {
      debugPrint('[BLE_MANUAL_RECONNECT] Ya conectado');
      return;
    }

    if (_statusNotifier.value == BluetoothStatus.connecting) {
      debugPrint('[BLE_MANUAL_RECONNECT] Ya intentando reconectar');
      return;
    }

    debugPrint(
      '[BLE_MANUAL_RECONNECT] Iniciando reconexión manual desde UI...'
    );
    
    _manualDisconnect = false;  // Permitir reconexión
    _reconnectAttempts = 0;     // Reset contador
    _statusNotifier.value = BluetoothStatus.connecting;

    // Utilizar misma lógica que _attemptAutoReconnect()
    await _lastDevice!.connect(...);
    // ... (RE-INICIALIZAR servicios y características)
  }
}
```

### 5.5 Estados de Conexión

```dart
enum BluetoothStatus {
  disconnected,  // Sin conexión (inicial o después desconectar)
  connecting,    // En progreso de conexión
  connected,     // Conectado y recibiendo ADC
  error,         // Error en conexión (mostrar a usuario)
}
```

### 5.6 Preservación de Estado

| Elemento | Preservado | Ubicación |
|----------|-----------|-----------|
| **Calibración (offset, factorEscala)** | ✅ Sí | SharedPreferences |
| **Parámetros de filtro** | ✅ Sí | SharedPreferences |
| **Configuración de celda de carga** | ✅ Sí | SharedPreferences |
| **Tara actual** | ❌ No | Volátil (sesión) |
| **Cero operativo** | ❌ No | Volátil (sesión) |
| **Último dispositivo conectado** | ✅ Sí | Referencia en memoria |
| **Sesiones de pesaje** | ✅ Sí | SharedPreferences (sesiones_v1_) |

### 5.7 Timeout de ADC

```dart
// Ubicación: lib/services/weight_service.dart
static const Duration _adcTimeout = Duration(seconds: 3);

// Detector de timeout
void start() {
  // ... (otros inicios)
  
  _timeoutCheckTimer = Timer.periodic(Duration(seconds: 1), (_) {
    if (!_isAdcActive) {
      // Si no hay datos por más de 3 segundos
      _weightStateController.add(WeightState(
        adcRaw: 0,
        adcFiltered: 0.0,
        peso: 0.0,
        estable: false,
        overload: false,
        adcActive: false,  // Marcar como inactivo
      ));
    }
  });
}

bool get _isAdcActive {
  if (_lastAdcTimestamp == null) return false;
  return DateTime.now().difference(_lastAdcTimestamp!) < _adcTimeout;
}
```

**Uso en UI:**

```dart
// En pantalla (home_screen.dart)
WeightState state; // Contiene adcActive

if (!state.adcActive) {
  // Mostrar advertencia "Sin datos del sensor"
  // Color rojo o ícono de error
}
```

---

## 6. CALIBRACIÓN

### 6.1 Modelo de Calibración

```dart
// Ubicación: lib/models/calibration_model.dart
class CalibrationModel {
  final double offset;           // Valor ADC cuando peso = 0
  final double adcReferencia;    // ADC de punto de calibración
  final double pesoPatron;       // Peso patrón usado en calibración
  final double factorEscala;     // Factor de conversión ADC → kg

  factory CalibrationModel.defaultModel() {
    return CalibrationModel(
      offset: 0.0,
      adcReferencia: 0.0,
      pesoPatron: 0.0,
      factorEscala: 1.0,
    );
  }
}
```

### 6.2 Proceso de Calibración Completo

```
PASO 1: TOMAR CERO (Punto Inicial)
════════════════════════════════════
1. Colocar balanza VACÍA sobre plato
2. Aguardar estabilización (~5 segundos)
3. Usuario presiona botón "TOMAR CERO"
4. Sistema captura: ADC_cero = ADC_filtrado_actual
5. Persistir: CalibrationModel.offset = ADC_cero

   Pantalla muestra: "Cero establecido: 510"


PASO 2: COLOCAR PESO PATRÓN
═════════════════════════════
1. Usuario introduce peso patrón (ej: 10.0 kg)
2. Coloca peso patrón en balanza
3. Aguarda estabilización
4. Presiona "TOMAR PESO DE CALIBRACIÓN"
5. Sistema captura: ADC_ref = ADC_filtrado_actual
6. Persistir temporalmente (no guardado aún)

   Pantalla muestra: "Peso de referencia capturado: 1510"


PASO 3: VALIDACIÓN Y RECÁLCULO DE FACTOR
═══════════════════════════════════════════
1. Usuario presiona "RECALCULAR FACTOR"
2. Sistema valida:
   - offset != 0? ✅
   - adcReferencia != 0? ✅
   - pesoPatron > 0? ✅
   - adcReferencia != offset? ✅
3. Calcula: factorEscala = pesoPatron / (adcReferencia - offset)

   Ejemplo:
   ───────
   offset = 510
   ADC_ref = 1510
   pesoPatron = 10.0 kg
   
   factorEscala = 10.0 / (1510 - 510)
                = 10.0 / 1000
                = 0.01 kg/ADC
   
   Pantalla: "Factor calculado: 0.010000"


PASO 4: GUARDAR CALIBRACIÓN
═════════════════════════════════
1. Usuario presiona "GUARDAR CALIBRACIÓN"
2. Sistema solicita contraseña técnica (fija)
   - Clave: 2016 (2000 - 16)
3. Si contraseña válida:
   - Persistir todo en SharedPreferences:
     {
       "offset": 510,
       "adcReferencia": 1510,
       "pesoPatron": 10.0,
       "factorEscala": 0.01
     }
   - Reiniciar filtros
   - Mostrar: "✅ Calibración guardada exitosamente"
   - Retornar a pantalla anterior


VALIDACIÓN DE CALIBRACIÓN
════════════════════════════
Después de guardar, probar con pesos conocidos:

   Test 1: Balanza vacía
   ADC_actual = 510
   peso = (510 - 510) × 0.01 = 0.0 kg ✅
   
   Test 2: Peso patrón 10 kg
   ADC_actual = 1510
   peso = (1510 - 510) × 0.01 = 10.0 kg ✅
   
   Test 3: Peso patrón 5 kg
   ADC_actual = 1010
   peso = (1010 - 510) × 0.01 = 5.0 kg ✅
```

### 6.3 Calibración desde UI (CalibrationScreen)

```dart
// Ubicación: lib/screens/calibration_screen.dart

// Botones principales:

// 1. TOMAR CERO
void _handleTomarCero() {
  if (!_hasData) {
    _showSnackBar('Esperando datos del sensor...', Colors.red);
    return;
  }
  
  setState(() {
    _offset = _adcFiltered;
    _offsetController.text = _offset.toStringAsFixed(2);
  });
  _weightService.setZeroNow();  // ← Persistir
  _showSnackBar('Cero establecido: ${_offset.toStringAsFixed(2)}', Colors.orange);
}

// 2. TOMAR PESO DE CALIBRACIÓN
void _handleTomarPesoCalibrado() {
  if (!_hasData) {
    _showSnackBar('Esperando datos del sensor...', Colors.red);
    return;
  }
  
  double peso = double.tryParse(_pesoPatronController.text) ?? 0.0;
  if (peso <= 0) {
    _showSnackBar('El peso patrón debe ser mayor a cero', Colors.red);
    return;
  }
  
  setState(() {
    _pesoPatron = peso;
    _adcReferencia = _adcFiltered;
    _adcReferenciaController.text = _adcReferencia.toStringAsFixed(2);
  });
  _showSnackBar('Peso de referencia capturado: ${_adcReferencia.toStringAsFixed(2)}', Colors.blue);
}

// 3. RECALCULAR FACTOR
void _handleRecalcularFactor() {
  if (_offset == 0) {
    _showSnackBar('Primero establezca el cero', Colors.red);
    return;
  }
  if (_adcReferencia == 0) {
    _showSnackBar('Primero tome el peso de referencia', Colors.red);
    return;
  }
  if (_pesoPatron <= 0) {
    _showSnackBar('El peso patrón debe ser mayor a cero', Colors.red);
    return;
  }
  
  double deltaADC = _adcReferencia - _offset;
  if (deltaADC == 0) {
    _showSnackBar('El ADC de referencia debe ser diferente al offset', Colors.red);
    return;
  }
  
  setState(() {
    _factorEscala = _pesoPatron / deltaADC;
    _factorEscalaController.text = _factorEscala.toStringAsFixed(6);
  });
  
  _showSnackBar('Factor calculado: ${_factorEscala.toStringAsFixed(6)}', Colors.green);
}

// 4. GUARDAR CALIBRACIÓN
Future<void> _handleGuardarCalibracion() async {
  // Solicitar contraseña técnica
  if (!await _pedirPassFija(2000 - 16)) {
    _showSnackBar('Contraseña incorrecta', Colors.red);
    return;
  }
  
  // Validar valores
  if (_pesoPatron <= 0) {
    _showSnackBar('El peso patrón debe ser mayor a cero', Colors.red);
    return;
  }
  
  if (_adcReferencia == _offset) {
    _showSnackBar('El ADC de referencia debe ser diferente al offset', Colors.red);
    return;
  }
  
  if (_factorEscala == 0) {
    _showSnackBar('El factor de escala no puede ser cero', Colors.red);
    return;
  }
  
  // Aplicar y persistir
  _weightService.applyCalibrationFromReference(_adcReferencia, _pesoPatron);
  
  _showSnackBar('✅ Calibración guardada exitosamente', Colors.green);
  
  // Retornar tras 1 segundo
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) {
      Navigator.pop(context);
    }
  });
}
```

### 6.4 Calibración de Fábrica

```dart
// Ubicación: lib/services/weight_service.dart

/// Guardar calibración actual como calibración de fábrica
Future<void> saveFactoryCalibration() async {
  await _persistenceService.saveFactoryCalibration(_calibration);
}

/// Restaurar calibración de fábrica (si existe)
Future<void> restoreFactoryCalibration() async {
  final CalibrationModel? factoryCalibration =
      await _persistenceService.loadFactoryCalibration();
  if (factoryCalibration != null) {
    setCalibration(factoryCalibration);
  }
}
```

**Ubicación Persistencia:**

```dart
// Ubicación: lib/services/persistence_service.dart
static const String _keyFactoryCalibration = 'factory_calibration_json';

Future<void> saveFactoryCalibration(CalibrationModel model) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String jsonString = jsonEncode(model.toJson());
  await prefs.setString(_keyFactoryCalibration, jsonString);
}

Future<CalibrationModel?> loadFactoryCalibration() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? jsonString = prefs.getString(_keyFactoryCalibration);
  if (jsonString == null) return null;
  final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
  return CalibrationModel.fromJson(jsonMap);
}
```

### 6.5 Factor de Corrección

```dart
// Ubicación: lib/models/load_cell_config.dart
class LoadCellConfig {
  // ...
  final double factorCorreccion;  // Rango: -10% a +10%
}

// Aplicación en cálculo de peso:
double factor = _loadCellConfig.factorCorreccion;
if (factor < -0.10) factor = -0.10;
if (factor > 0.10) factor = 0.10;
double pesoCorregido = pesoBase * (1 + factor);

// Ejemplo: compensar envejecimiento de sensor
// Si sensor reduce 5%, factorCorreccion = +0.05 (5%)
// Esto multiplica todos los pesos por 1.05 automáticamente
```

### 6.6 Protecciones de Calibración

| Protección | Mecanismo | Descripción |
|-----------|-----------|-----------|
| **Contraseña Fija** | PIN técnico fijo | Clave: 2016 para guardar calibración |
| **Contraseña Dinámica** | Hash con timestamp | Clave adicional para operaciones críticas |
| **Validación de Valores** | Rangos y restricciones | Validar offset ≠ ADC_ref, peso > 0 |
| **Persistencia** | SharedPreferences | Datos guardados localmente, no se pierden |
| **Calibración de Fábrica** | Backup restaurable | Guardar y restaurar valores iniciales |

---

## 7. MANEJO DE ERRORES

### 7.1 Errores Detectables

| Tipo de Error | Detector | Acción |
|--------------|----------|--------|
| **Paquete BLE incompleto** | `data.length < 4` | Log, descartar paquete |
| **Conexión BLE perdida** | `onConnectionStateChanged(disconnected)` | Auto-reconectar o mostrar error |
| **Timeout de conexión** | Timeout 15 segundos | Cambiar a estado ERROR |
| **Servicio BLE no encontrado** | `targetService == null` | Desconectar, mostrar error |
| **Característica no encontrada** | `targetCharacteristic == null` | Desconectar, mostrar error |
| **Timeout de ADC** | `DateTime.now() - lastAdcTimestamp > 3s` | Marcar `adcActive = false` |
| **ADC fuera de rango** | ADC > capacidad | Establecer `overload = true` |
| **Error de parseo de datos** | `Exception` en `_onBinaryDataReceived()` | Log, continuar |
| **Error de persistencia** | `Exception` en SharedPreferences | Log, usar valores por defecto |
| **Contraseña incorrecta** | Hash no coincide | Rechazar operación, mostrar mensaje |

### 7.2 Códigos de Error en Logs

```dart
// Ubicación: lib/services/bluetooth_service.dart (ejemplos)

'[BLE_CLEANUP] Iniciando limpieza de recursos BLE...'
'[BLE_DISCONNECT] Iniciando desconexión manual...'
'[BLE_RECONNECT] Intento X/3'
'[BLE_STATE] Cambio de estado: $state'
'[BLE_MANUAL_RECONNECT] Iniciando reconexión manual desde UI...'

// Ubicación: lib/services/weight_service.dart (ejemplos)

'Error procesando datos binarios BLE: $e'
'Error guardando configuración: $e'
'Error cargando calibración: $e'
```

### 7.3 Estados de Error

```dart
enum BluetoothStatus {
  disconnected,  // Normal
  connecting,    // En progreso
  connected,     // Normal
  error,         // ← Error: mostrar a usuario
}

// Cuando pasar a ERROR:
// - Timeout en conexión
// - UUID de servicio no encontrado
// - UUID de característica no encontrado
// - Max intentos de reconexión alcanzados
```

### 7.4 Notificación de Errores a Usuario

```dart
// En CalibrationScreen:
void _showSnackBar(String message, Color backgroundColor) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 3),
    ),
  );
}

// Ejemplos de uso:
_showSnackBar('Esperando datos del sensor...', Colors.red);
_showSnackBar('Contraseña incorrecta', Colors.red);
_showSnackBar('Cero establecido: 510', Colors.orange);
_showSnackBar('✅ Calibración guardada exitosamente', Colors.green);
```

### 7.5 Recuperación de Errores

| Error | Estrategia |
|-------|-----------|
| Paquete incompleto | Descartar, esperar siguiente |
| Conexión perdida | Auto-reconectar (hasta 3 intentos) |
| ADC inactivo | Marcar `adcActive = false`, mostrar advertencia |
| Overload | Marcar `overload = true`, no procesar peso |
| Persistencia fallida | Log + usar valor por defecto |
| Contraseña incorrecta | Rechazar operación, permanecer en pantalla |

---

## 8. ARQUITECTURA INTERNA

### 8.1 Diagrama de Capas

```
┌─────────────────────────────────────────────────────────┐
│                 UI LAYER (Screens)                      │
│  HomeScreen | BluetoothScreen | CalibrationScreen       │
│  ConfigScreen | HistoryScreen | SessionScreen           │
└──────────────────────┬──────────────────────────────────┘
                       │ (ValueListenableBuilder)
                       ▼
┌─────────────────────────────────────────────────────────┐
│            SERVICE LAYER (Singletons)                   │
├──────────────┬──────────────────┬──────────────┬─────────┤
│ Bluetooth    │ Weight           │ Persistence  │ Auth    │
│ Service      │ Service          │ Service      │ Service │
│              │                  │              │         │
│ - Connect    │ - Calibration    │ - Save Config│ - Token │
│ - Disconnect │ - Filtrado       │ - Load       │ - Hash  │
│ - Reconnect  │ - Tara/Cero      │ - Sessions   │ - Pass  │
│ - ADC stream │ - Stability      │              │         │
└──────────────┼──────────────────┼──────────────┼─────────┘
               │                  │              │
               ▼                  ▼              ▼
┌──────────────────────────────────────────────────────────┐
│              MODEL LAYER (Data Classes)                  │
├──────────────┬──────────────────┬──────────────┬─────────┤
│ WeightState  │ CalibrationModel │ FilterParams │ Load    │
│              │                  │              │ CellCfg │
│ - adcRaw     │ - offset         │ - muestras   │ - cap   │
│ - peso       │ - factor         │ - ventana    │ - sens  │
│ - estable    │ - adcRef         │ - emaAlpha   │ - div   │
│ - overload   │ - pesoPatron     │ - interval   │         │
└──────────────┴──────────────────┴──────────────┴─────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│        BLUETOOTH + PERSISTENCE LAYER                     │
├──────────────────────┬──────────────────────────────────┤
│ flutter_blue_plus    │ shared_preferences               │
│                      │ (SQLite de Android)              │
│ - BLE connection     │ - calibration_model              │
│ - Services/Chars     │ - filter_params                  │
│ - Notifications      │ - load_cell_config               │
│                      │ - factory_calibration_json       │
│                      │ - sessions_v1_*                  │
└──────────────────────┴──────────────────────────────────┘
```

### 8.2 Servicios (Singletons)

```dart
// Patrón Singleton implementado en cada servicio:

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();
  
  // ... resto de implementación
}

// Uso:
BluetoothService bluetooth = BluetoothService();  // Siempre la misma instancia
WeightService weight = WeightService();            // Siempre la misma instancia
```

**Ventajas:**
- Una sola instancia por aplicación
- Estado compartido entre pantallas
- Eficiente en memoria
- Inicialización única

### 8.3 Gestión de Estado

```
┌─────────────────────────────────────┐
│ STATE MANAGEMENT (No Redux/Bloc)    │
├─────────────────────────────────────┤
│ ValueNotifier                        │
│ └─ BluetoothStatus                   │
│                                      │
│ StreamController (Broadcast)         │
│ ├─ adcStream (BluetoothService)     │
│ ├─ weightStateStream (WeightService) │
│ └─ configStream (WeightService)      │
│                                      │
│ Listeners directos en UI:            │
│ ├─ ValueListenableBuilder            │
│ └─ StreamBuilder                     │
└─────────────────────────────────────┘
```

### 8.4 Dependencias entre Servicios

```
WeightService
├─ BluetoothService (singleton)
│  └─ _bluetoothService.adcStream
│     └─ Escucha ADC continuamente
│
└─ PersistenceService (singleton)
   ├─ Carga calibración al iniciar
   ├─ Carga filtros al iniciar
   ├─ Carga configuración celda al iniciar
   └─ Guarda cambios en calibración/filtros

BluetoothService
├─ flutter_blue_plus
│  └─ BLE device connection
│
└─ Emite ValueNotifier<BluetoothStatus>
   └─ Escuchado por UI
```

### 8.5 Flujo de Datos Completo

```
┌─────────────────────────────────────────────┐
│ Balanza Física (ESP32 + Sensor de Carga)    │
│ Emite ADC cada ~50ms vía BLE                │
└────────────────┬────────────────────────────┘
                 │ (Paquete binario BLE)
                 ▼
┌─────────────────────────────────────────────┐
│ BluetoothService                            │
│ - Conectado al dispositivo BLE              │
│ - Recibe notificaciones                     │
│ - _onBinaryDataReceived() extrae ADC        │
│ - Emite adcStream.add(adcValue)             │
└────────────────┬────────────────────────────┘
                 │ (Stream<int> adcStream)
                 ▼
┌─────────────────────────────────────────────┐
│ WeightService.start()                       │
│ - Escucha adcStream                         │
│ - Cada 100ms: _processData()                │
│   ├─ Trim (últimas 10 muestras)            │
│   ├─ Ventana móvil (últimas 5)              │
│   ├─ EMA (suavizado exponencial)            │
│   ├─ Calibración (offset + factor)          │
│   ├─ Factor corrección                      │
│   ├─ Tara                                   │
│   ├─ Cero operativo                         │
│   ├─ División mínima                        │
│   ├─ Detección estabilidad                  │
│   └─ Emite weightStateStream.add(state)     │
└────────────────┬────────────────────────────┘
                 │ (Stream<WeightState>)
                 ▼
┌─────────────────────────────────────────────┐
│ UI Layers                                   │
│ - HomeScreen (StreamBuilder)                │
│ - CalibrationScreen (StreamBuilder)         │
│ - ConfigScreen (ValueListenableBuilder)     │
│ - HistoryScreen (SessionHistory)            │
│                                             │
│ Muestran:                                   │
│ - Peso actual (kg)                          │
│ - Estado (estable/inestable)                │
│ - Estado Bluetooth (connected/error)        │
│ - Overload warning                          │
│ - ADC status                                │
└─────────────────────────────────────────────┘
```

### 8.6 ¿Existe Servicio de Pesaje? (Sí)

```dart
// Ubicación: lib/services/weight_service.dart
class WeightService {
  static final WeightService _instance = WeightService._internal();
  factory WeightService() => _instance;
  
  // Este ES el servicio de pesaje centralizado
  // Maneja toda la lógica de conversión ADC → kg
  // No depende de pantallas específicas
  // Estado global compartido
}

// Inicialización recomendada (en main.dart o screens):
Future<void> _initServices() async {
  final WeightService ws = WeightService();
  await ws.initialize();  // Cargar calibración, filtros, config
  ws.start();             // Comenzar procesamiento ADC
}
```

### 8.7 ¿El Peso Depende de Pantallas? (No)

```dart
// ❌ INCORRECTO: No hacer esto
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  double peso = 0.0;  // ← NO, esto es estado local
  
  // Si navego a otra pantalla, se pierden los datos
}

// ✅ CORRECTO: Usar servicio global
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final WeightService _weightService = WeightService();
  
  @override
  void initState() {
    super.initState();
    _weightService.start();  // Inicia si no estaba iniciado
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WeightState>(
      stream: _weightService.weightStateStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          double peso = snapshot.data!.peso;  // ← Dato global, actualizado
          return Text('Peso: $peso kg');
        }
        return Text('Esperando...');
      },
    );
  }
}

// Si navego a otra pantalla y vuelvo, el estado persiste
// porque WeightService es singleton
```

### 8.8 Estado Global (ValueNotifier)

```dart
// BluetoothStatus es global y accesible desde cualquier pantalla

class BluetoothService {
  final ValueNotifier<BluetoothStatus> _statusNotifier =
      ValueNotifier<BluetoothStatus>(BluetoothStatus.disconnected);
  
  ValueNotifier<BluetoothStatus> get statusNotifier => _statusNotifier;
  BluetoothStatus get status => _statusNotifier.value;
}

// Uso en UI:
class MyScreen extends StatelessWidget {
  final BluetoothService _bluetooth = BluetoothService();
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BluetoothStatus>(
      valueListenable: _bluetooth.statusNotifier,
      builder: (context, status, child) {
        if (status == BluetoothStatus.connected) {
          return Text('Conectado ✅');
        } else if (status == BluetoothStatus.connecting) {
          return Text('Conectando...');
        } else if (status == BluetoothStatus.error) {
          return Text('Error ❌');
        }
        return Text('Desconectado');
      },
    );
  }
}
```

### 8.9 Clases Críticas

| Clase | Archivo | Responsabilidad |
|-------|---------|-----------------|
| `BluetoothService` | `services/bluetooth_service.dart` | Conexión BLE, flujo ADC |
| `WeightService` | `services/weight_service.dart` | Calibración, filtrado, cálculo peso |
| `PersistenceService` | `services/persistence_service.dart` | SharedPreferences, persistencia |
| `CalibrationModel` | `models/calibration_model.dart` | Offset, factorEscala, adcRef |
| `WeightState` | `models/weight_state.dart` | Estado actual de peso + flags |
| `FilterParams` | `models/filter_params.dart` | Parámetros de filtrado |
| `LoadCellConfig` | `models/load_cell_config.dart` | Propiedades del sensor |

---

## 9. REUTILIZACIÓN PARA F22

### 9.1 Reutilizable SIN Cambios

#### Servicios Completos

| Servicio | Ruta | Cambios Necesarios |
|----------|------|-------------------|
| **BluetoothService** | `lib/services/bluetooth_service.dart` | ❌ Ninguno (copiar tal cual) |
| **WeightService** | `lib/services/weight_service.dart` | ❌ Ninguno (copiar tal cual) |
| **PersistenceService** | `lib/services/persistence_service.dart` | ❌ Ninguno (copiar tal cual) |

**Instrucciones:**
```bash
# 1. Copiar archivos completos a F22
cp F16/lib/services/bluetooth_service.dart F22/lib/services/
cp F16/lib/services/weight_service.dart F22/lib/services/
cp F16/lib/services/persistence_service.dart F22/lib/services/

# 2. En pubspec.yaml de F22, agregar:
dependencies:
  flutter_blue_plus: ^2.1.0
  permission_handler: ^11.4.0
  shared_preferences: ^2.2.2
```

#### Modelos Completos

| Modelo | Ruta | Estado |
|--------|------|--------|
| **CalibrationModel** | `lib/models/calibration_model.dart` | ✅ Copiar sin cambios |
| **WeightState** | `lib/models/weight_state.dart` | ✅ Copiar sin cambios |
| **FilterParams** | `lib/models/filter_params.dart` | ✅ Copiar sin cambios |
| **LoadCellConfig** | `lib/models/load_cell_config.dart` | ✅ Copiar sin cambios |

#### Lógica de Algoritmos

| Algoritmo | Ubicación | Copiable |
|-----------|-----------|----------|
| **EMA (Exponential Moving Average)** | `WeightService._applyEMA()` | ✅ Sí |
| **Trim de Extremos** | `WeightService._calculateTrimmedMean()` | ✅ Sí |
| **Ventana Móvil** | `WeightService._calculateWindowAverage()` | ✅ Sí |
| **Calibración** | `WeightService._calculateWeight()` | ✅ Sí |
| **Detección de Estabilidad** | `WeightService._detectStability()` | ✅ Sí |
| **División Mínima** | `WeightService._applyDivisionMinima()` | ✅ Sí |

**Fragmento de Código (copiar directamente):**

```dart
// Copiar estas funciones sin modificación
double _calculateTrimmedMean() { ... }
double _calculateWindowAverage() { ... }
double _applyEMA(double newValue) { ... }
double _calculateWeight(double adcFiltered) { ... }
bool _detectStability() { ... }
double _applyDivisionMinima(double peso) { ... }
```

### 9.2 Reutilizable CON Adaptación Menor

#### BluetoothAdapter (Abstracción)

**Archivo:** `lib/services/bluetooth_adapter.dart`

**Cambios:**
- Si F22 usa Bluetooth distinto (SPP en lugar de BLE), crear nueva implementación
- Interface: igual
- Implementación: adaptada al nuevo protocolo

```dart
// Interface (NO cambiar)
abstract class BluetoothAdapter {
  Future<bool> isBluetoothEnabled();
  Future<bool?> requestEnable();
  Future<List<BluetoothDevice>> getBondedDevices();
  // ...
}

// Implementación para BLE (copiar si F22 también usa BLE)
class FlutterBluePlusAdapter implements BluetoothAdapter { ... }

// Nueva implementación si F22 usa SPP
class BluetoothSerialAdapter implements BluetoothAdapter { ... }
```

#### UUID de Servicios/Características

**Ubicación:** `BluetoothService` líneas 38-41

```dart
// CAMBIAR estos UUIDs para F22:
// (Pedir al fabricante de hardware)

static const String _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
static const String _characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

// En F22, probablemente serán otros UUIDs
// Todo lo demás sigue igual
```

**Instrucciones:**

```
1. Obtener del fabricante de balanza F22:
   - Service UUID
   - Characteristic UUID
   - Propiedades (notify/read/write)

2. Reemplazar en BluetoothService (línea 38-41)

3. El resto del código NO cambia
```

#### Constantes de Configuración

**Archivo:** `lib/utils/constants.dart`

**Cambios Recomendados:**
```dart
class AppConstants {
  // Tamaños de UI (específicos a F22)
  static const double iconSizeSmall = 30.0;
  static const double iconSizeMedium = 36.0;
  
  // Pero NO tocar:
  // - Constantes de Bluetooth
  // - Constantes de calibración
  // - Constantes de filtrado
}
```

### 9.3 Reutilizable en Parte (Refactorización)

#### AuthService (Contraseñas y Seguridad)

**Ubicación:** `lib/services/auth_service.dart`

**Estado Actual:**
- Sistema de contraseñas fijas y dinámicas
- Claves hardcodeadas: `2016`, `2200 + 54`, etc.

**Para F22:**
- ✅ Copiar patrón de contraseñas
- ⚠️ Cambiar claves específicas (si se requiere)
- ⚠️ O parametrizar en archivo de configuración

**Opción 1: Copiar y cambiar claves**
```dart
// Antes (F16):
static const int FIXED_KEY_CALIBRATION = 1600 + 16;  // 1616

// Después (F22):
static const int FIXED_KEY_CALIBRATION = 2000 + 22;  // 2022 (ejemplo)
```

**Opción 2: Externalizar claves**
```dart
// auth_config.dart (nuevo archivo)
class AuthConfig {
  static const int FIXED_KEY_CALIBRATION = 2022;
  static const int FIXED_KEY_FACTORY = 2054;
}

// Usar en AuthService:
if (await _authService.validateFixed(input, AuthConfig.FIXED_KEY_CALIBRATION)) {
  ...
}
```

#### PersistenceService (Namespace separado)

**Para F22:** Cambiar namespace para evitar colisiones si ambas apps están en el mismo dispositivo

```dart
// F16 (actual):
static const String _keyCalibration = 'calibration_model';

// F22 (propuesto):
static const String _keyCalibration = 'f22_calibration_model';
static const String _keyFilterParams = 'f22_filter_params';
static const String _keyLoadCellConfig = 'f22_load_cell_config';
```

**Ventaja:** Cada app tiene su propia configuración persistida, sin conflictos.

### 9.4 NO Reutilizable (Descartar/Reescribir)

| Elemento | Ubicación | Motivo | Alternativa |
|----------|-----------|--------|------------|
| **Screens** | `lib/screens/*.dart` | UI específica de F16 | Reescribir UI para F22 |
| **Widgets** | `lib/widgets/*.dart` | Componentes UI de F16 | Crear widgets para F22 |
| **SessionHistory** | `services/session_history_service.dart` | Lógica de sesiones | Adaptar si F22 tiene sesiones |
| **PDF Export** | `services/pdf_export_service.dart` | Específico de reportes F16 | Reescribir para F22 |
| **Themes/Colores** | `utils/constants.dart` (parcial) | Estética F16 | Redefinir para F22 |

### 9.5 Checklist de Reutilización

```
┌─────────────────────────────────────────────────────────────┐
│ CHECKLIST: Migración F16 → F22                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ SERVICIOS CORE                                              │
│ ✓ Copiar: bluetooth_service.dart                           │
│ ✓ Copiar: weight_service.dart                              │
│ ✓ Copiar: persistence_service.dart                         │
│ ✓ Actualizar UUIDs BLE (si cambió hardware)                │
│                                                              │
│ MODELOS                                                     │
│ ✓ Copiar: calibration_model.dart                           │
│ ✓ Copiar: weight_state.dart                                │
│ ✓ Copiar: filter_params.dart                               │
│ ✓ Copiar: load_cell_config.dart                            │
│                                                              │
│ ALGORITMOS (en WeightService)                               │
│ ✓ Copiar: _calculateTrimmedMean()                          │
│ ✓ Copiar: _calculateWindowAverage()                        │
│ ✓ Copiar: _applyEMA()                                      │
│ ✓ Copiar: _calculateWeight()                               │
│ ✓ Copiar: _detectStability()                               │
│ ✓ Copiar: _applyDivisionMinima()                           │
│                                                              │
│ AUTENTICACIÓN                                               │
│ ✓ Copiar: auth_service.dart (adaptando claves si necesario)│
│ ✓ Copiar: password_dialog.dart                             │
│                                                              │
│ PERSISTENCIA                                                │
│ ✓ Actualizar namespaces (agregar prefijo f22_)            │
│                                                              │
│ DEPENDENCIAS (pubspec.yaml)                                 │
│ ✓ flutter_blue_plus: ^2.1.0                                │
│ ✓ permission_handler: ^11.4.0                              │
│ ✓ shared_preferences: ^2.2.2                               │
│                                                              │
│ UI (REESCRIBIR)                                             │
│ ✗ No copiar screens                                        │
│ ✗ No copiar widgets específicos                            │
│ → Crear nueva UI llamando WeightService                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 9.6 Ejemplo: Inicializar WeightService en F22

```dart
// main.dart (F22)
import 'package:f22_app/services/weight_service.dart';
import 'package:f22_app/services/bluetooth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar WeightService
  final WeightService weightService = WeightService();
  await weightService.initialize();  // Cargar calibración persistida
  weightService.start();              // Comenzar procesamiento ADC
  
  // 2. Inicializar BluetoothService (opcional, solo si necesitas gestión manual)
  final BluetoothService bluetoothService = BluetoothService();
  
  runApp(const F22App());
}

// home_screen.dart (F22)
class F22HomeScreen extends StatelessWidget {
  final WeightService _weightService = WeightService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<WeightState>(
        stream: _weightService.weightStateStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final WeightState state = snapshot.data!;
            
            return Column(
              children: [
                Text(
                  'Peso: ${state.peso.toStringAsFixed(2)} kg',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  'Estado: ${state.estable ? "Estable ✅" : "Inestable ❌"}',
                ),
                if (state.overload)
                  Text('⚠️ SOBRECARGA', style: TextStyle(color: Colors.red)),
                if (!state.adcActive)
                  Text('⚠️ Sin datos del sensor', style: TextStyle(color: Colors.orange)),
              ],
            );
          }
          
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
```

---

## 10. CONCLUSIÓN TÉCNICA

### 10.1 Riesgos Detectados

| Riesgo | Severidad | Mitigación |
|--------|-----------|-----------|
| **Pérdida de conexión BLE sin notificación** | 🔴 Alta | Auto-reconexión implementada (3 intentos) |
| **Timeout de ADC sin detección** | 🔴 Alta | Detector de timeout implementado (3s) |
| **Corrupción de calibración por múltiples escrituras** | 🟡 Media | SharedPreferences es thread-safe |
| **Memory leak en listeners de streams** | 🟡 Media | Suscripciones canceladas en dispose() |
| **Contraseña hardcodeada predecible** | 🟡 Media | Claves fijas + dinámicas, cambiar si es crítico |
| **Overflow de buffers** | 🟢 Baja | Tamaño máximo limitado (50) |

### 10.2 Puntos Fuertes del Diseño

| Fortaleza | Impacto |
|-----------|--------|
| **Singleton pattern** | Gestión centralizada, estado compartido |
| **Streams para reactividad** | Sincronización automática en UI |
| **Separación de capas** | Fácil de testear y mantener |
| **Persistencia automática** | Configuración no se pierde |
| **Auto-reconexión robusta** | Continuidad operativa después de fallos |
| **Filtrado multinivel** | Eliminación efectiva de ruido |
| **Calibración bidireccional** | Precisión de medición ajustable |
| **Detección de estabilidad** | Seguridad en lecturas críticas |

### 10.3 Recomendaciones para F22

#### Corto Plazo (Fase 1)
```
1. ✅ Copiar servicios core sin cambios
   - BluetoothService
   - WeightService
   - PersistenceService

2. ✅ Adaptar UUIDs BLE (si hardware diferente)
   - Obtener del fabricante
   - Reemplazar en líneas 38-41 de bluetooth_service.dart

3. ✅ Crear UI simplificada
   - Usar WeightService como fuente de verdad
   - StreamBuilder para actualizaciones
   - ValueListenableBuilder para estado Bluetooth

4. ✅ Cambiar namespaces de persistencia
   - Prefijo "f22_" en SharedPreferences
   - Evitar colisiones si ambas apps coexisten
```

#### Mediano Plazo (Fase 2)
```
1. ✅ Testing de algoritmos de filtrado
   - Reproducir con pesos reales
   - Ajustar parámetros según casos de uso

2. ✅ Calibración de fábrica
   - Guardar/restaurar calibraciones múltiples
   - Gestión de versiones de calibración

3. ✅ Logging avanzado
   - Exportar logs de sesión
   - Diagnóstico de problemas BLE
```

#### Largo Plazo (Fase 3)
```
1. ✅ Machine Learning (opcional)
   - Predicción de estabilidad
   - Detección de anomalías

2. ✅ Sincronización multi-dispositivo
   - Compartir calibraciones entre terminales
   - Servidor central (si aplica)

3. ✅ Certificación metrológica
   - Validación ISO 6954 (si se requiere)
   - Trazabilidad de mediciones
```

### 10.4 Advertencias Importantes

⚠️ **CRÍTICO:**
- No modificar fórmulas de calibración sin pruebas exhaustivas
- No cambiar UUIDs BLE sin validar hardware
- No eliminar validaciones de contraseña
- No cambiar claves de autenticación sin documentar

⚠️ **IMPORTANTE:**
- Respaldar calibración después de cada ajuste
- Testear reconexión en escenarios reales
- Validar rangos de parámetros (especialmente alpha EMA)
- Usar mismo tipo de celda de carga (misma sensibilidad)

⚠️ **RECOMENDADO:**
- Implementar Unit Tests para algoritmos
- Crear logs detallados de calibración
- Documentar cambios de hardware
- Mantener repositorio de calibraciones de referencia

### 10.5 Resumen de Datos Técnicos

```
┌─────────────────────────────────────────────────────────┐
│ RESUMEN EJECUTIVO                                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ COMUNICACIÓN                                             │
│ - Protocolo: BLE (Bluetooth Low Energy)                 │
│ - Frecuencia: ~50ms (20 Hz)                              │
│ - Formato: ADC 32-bit Little Endian                     │
│ - Servicios: UUID 4fafc201-1fb5-459e...                │
│                                                          │
│ PROCESAMIENTO DE DATOS                                  │
│ - Trim: últimas 10 muestras, descartar 2 extremos     │
│ - Ventana: media móvil de 5 valores                    │
│ - EMA: alpha = 0.3 (configurable)                      │
│ - Calibración: peso = (ADC - offset) × factorEscala    │
│ - Cuantización: redondeo a división mínima             │
│                                                          │
│ PERSISTENCIA                                             │
│ - Sistema: SharedPreferences (SQLite)                   │
│ - Datos: Calibración, Filtros, Configuración            │
│ - Sesiones: JSON + historial                            │
│                                                          │
│ REUTILIZACIÓN                                            │
│ - Servicios: 100% sin cambios                           │
│ - Modelos: 100% sin cambios                             │
│ - Algoritmos: 100% sin cambios                          │
│ - UUIDs: Cambiar si hardware diferente                 │
│                                                          │
│ CONFIABILIDAD                                            │
│ - Auto-reconexión: Sí (3 intentos)                      │
│ - Detección timeout ADC: Sí (3 segundos)                │
│ - Persistencia de estado: Sí                            │
│ - Recovery de errores: Sí                               │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 10.6 Conclusión Final

**F16 proporciona una base técnica robusta y reutilizable para F22.**

✅ **100% de la lógica de pesaje y Bluetooth es extraíble sin cambios**
✅ **Arquitectura es modular y bien documentada**
✅ **Algoritmos de filtrado están validados en producción**
✅ **Sistema de calibración es flexible y seguro**

🎯 **Para F22:**
1. Copiar servicios core (3 archivos)
2. Actualizar UUIDs si hardware es diferente
3. Crear UI acorde a F22
4. Testear en ambiente real

**Tiempo estimado de integración: 2-3 semanas (sin complicaciones de hardware)**

---

## ANEXOS

### Anexo A: Tablas de Referencia Rápida

#### Parámetros por Defecto

```dart
FilterParams.defaultParams() {
  muestras: 10,           // Trim size
  ventana: 5,             // Moving average window
  emaAlpha: 0.3,          // Exponential smoothing
  updateIntervalMs: 100,  // Processing interval
}

LoadCellConfig.defaultConfig() {
  capacidadKg: 20000.0,
  sensibilidadMvV: 2.0,
  voltajeExcitacion: 5.0,
  gananciaHX711: 128.0,
  voltajeReferencia: 3.3,
  divisionMinima: 10.0,
  unidad: 'kg',
}
```

#### Fórmula Consolidada

```
pesoFinal = ROUND( ((ADC_filtrado - offset) × factorEscala
                    × (1 + factorCorrection)
                    - tareKg
                    - zeroOffsetKg) / divisionMinima
                  ) × divisionMinima
```

#### Estados Bluetooth

```
disconnected → connecting → connected
                    ↓
                  error
                    ↓
               disconnected
```

### Anexo B: Archivos a Copiar

```
F16 → F22 (Copia directa, sin cambios)
═════════════════════════════════════════
lib/services/
├─ bluetooth_service.dart
├─ weight_service.dart
├─ persistence_service.dart
└─ bluetooth_adapter.dart

lib/models/
├─ calibration_model.dart
├─ weight_state.dart
├─ filter_params.dart
└─ load_cell_config.dart
```

### Anexo C: Referencias Externas

- **Flutter Blue Plus**: https://pub.dev/packages/flutter_blue_plus
- **Bluetooth BLE Spec**: Bluetooth 4.0+ Specification
- **Shared Preferences**: https://pub.dev/packages/shared_preferences

---

**Documento generado automáticamente. No realizar modificaciones sin validación técnica.**

**Autor**: Análisis Técnico F16  
**Fecha**: 1 de febrero de 2026  
**Versión**: 2.0.4  
**Estado**: PRODUCCIÓN
