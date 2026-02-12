# 🗺️ MAPEO ARQUITECTÓNICO — Flujo de Datos BLE → ADC → Peso

**Proyecto**: F16 Balanza Electrónica BLE  
**Versión**: 1.0.0  
**Fecha**: 11 de febrero de 2026  
**Etapa**: 16.1.2  
**Propósito**: Documentación conceptual del flujo de datos BLE y propuesta de separación de responsabilidades  
**Tipo**: SOLO DOCUMENTACIÓN / SIN IMPLEMENTACIÓN

---

## ⚠️ IMPORTANTE

Este documento es **SOLO DESCRIPTIVO Y PROPOSITIVO**:

✅ Documenta el contrato de datos BLE existente  
✅ Describe el flujo lógico de procesamiento validado  
✅ Propone separación de responsabilidades arquitectónicas  
✅ Refleja implicancias conceptuales de UI  

❌ NO redefine el protocolo BLE  
❌ NO modifica código existente  
❌ NO implementa cambios funcionales  
❌ NO propone optimizaciones algorítmicas  

---

## 📋 TABLA DE CONTENIDOS

1. [Contrato de Datos BLE](#1-contrato-de-datos-ble)
2. [Flujo Lógico de Procesamiento](#2-flujo-lógico-de-procesamiento)
3. [Separación de Responsabilidades](#3-separación-de-responsabilidades)
4. [Implicancias de UI](#4-implicancias-de-ui)
5. [Anexos y Referencias](#5-anexos-y-referencias)

---

## 1. CONTRATO DE DATOS BLE

### 1.1 Descripción General

El sistema recibe datos continuos de un dispositivo de pesaje externo (basado en ESP32) mediante **Bluetooth Low Energy (BLE)**. Este dispositivo:

- **Envía**: Mensajes JSON completos en forma de stream continuo
- **Frecuencia**: Aproximadamente cada 50 ms (20 Hz)
- **Protocolo**: GATT (Generic Attribute Profile) con notificaciones
- **Formato**: JSON con campos estructurados

### 1.2 Especificaciones BLE

#### Identificadores Únicos

| Elemento | UUID | Propiedades |
|----------|------|-------------|
| **Servicio BLE** | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | Servicio personalizado |
| **Característica** | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | `notify` (notificaciones) |

#### Configuración de Conexión

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| **MTU** | 512 bytes | Tamaño máximo de unidad de transmisión |
| **Timeout de conexión** | 15 segundos | Tiempo máximo para establecer conexión |
| **Dirección de datos** | Unidireccional | Solo hardware → aplicación |

### 1.3 Estructura del Mensaje BLE

#### Formato JSON

El ESP32 envía un **objeto JSON completo** por cada notificación BLE:

```json
{
  "adc": 1234,
  "peso": 12.34
}
```

#### Campos del JSON

| Campo | Tipo | Unidad | Descripción |
|-------|------|--------|-------------|
| **adc** | Entero | Cuentas ADC | Valor crudo del convertidor analógico-digital (señal) |
| **peso** | Decimal | kg | Peso calculado en paralelo por el ESP32 (interpretación) |

**Descripción de los campos**:

**Campo `adc` (ADC crudo)**:
- **Tipo de dato**: Entero (int)
- **Rango práctico esperado**: 0 a 4095 (sugiere ADC de 12 bits) o mayor según hardware
- **Representación**: Cuenta digital directa del convertidor analógico-digital
- **Origen físico**: Señal de celda de carga → amplificador → ADC → valor numérico
- **Rol**: Señal primaria para filtrado y calibración en la aplicación

**Campo `peso` (Peso calculado)**:
- **Tipo de dato**: Decimal (float/double)
- **Unidad**: Kilogramos (kg)
- **Origen**: Cálculo realizado por el ESP32 (puede incluir calibración básica)
- **Rol**: Valor informativo/diagnóstico que viaja en paralelo

#### Ejemplo de Mensaje Real

```json
{
  "adc": 1000,
  "peso": 10.5
}
```

**Interpretación**:
- El sensor reporta 1000 cuentas ADC (señal cruda)
- El ESP32 calculó 10.5 kg como peso (interpretación paralela)
- La aplicación debe usar principalmente el campo `adc` para procesamiento
- El campo `peso` puede usarse para diagnóstico o validación

### 1.4 Significado de los Datos

#### ADC Crudo: Señal Primaria

El valor ADC es una **señal digital cruda** que representa:

| Aspecto | Descripción |
|---------|-------------|
| **Naturaleza** | Medición directa del sensor (cuentas digitales) |
| **Unidad** | Cuentas ADC (adimensional) |
| **Relación física** | Proporcional al peso aplicado sobre la celda de carga |
| **Estado** | Sin procesar, sin filtrar, sin calibrar |
| **Rol en la aplicación** | Señal primaria para filtrado y calibración |

**Importante**: El ADC NO es peso. Es la materia prima que debe procesarse.

#### Peso Calculado: Valor Informativo en Paralelo

El campo `peso` es un **valor calculado por el ESP32** que viaja en paralelo:

| Aspecto | Descripción |
|---------|-------------|
| **Naturaleza** | Interpretación/cálculo realizado en el hardware |
| **Unidad** | Kilogramos (kg) |
| **Estado** | Posiblemente incluye calibración básica del ESP32 |
| **Rol en la aplicación** | Informativo, diagnóstico, validación |

**Observación**: La aplicación puede comparar su peso calculado con el peso del ESP32 para diagnóstico.

#### Relación entre ADC y Peso

```
┌─────────────────────────────────────────────────┐
│           Mensaje JSON del ESP32                │
│                                                 │
│  ┌──────────────┐        ┌──────────────┐      │
│  │   adc: 1234  │        │ peso: 12.34  │      │
│  │   (Señal)    │        │ (Interpreta) │      │
│  └──────┬───────┘        └──────┬───────┘      │
│         │                       │              │
└─────────┼───────────────────────┼──────────────┘
          │                       │
          │                       │
          ▼                       ▼
    ┌──────────────┐        ┌──────────────┐
    │ Procesamiento│        │  Puede usarse│
    │   en App     │        │ para diagnós-│
    │              │        │ tico/validac │
    │ Filtros →    │        │              │
    │ Calibración →│        │              │
    │ Peso Final   │        │              │
    └──────────────┘        └──────────────┘
```

#### ¿Por Qué Enviar Ambos Valores?

El protocolo envía tanto ADC como peso calculado por las siguientes razones:

1. **ADC como señal primaria**: La aplicación tiene control total sobre filtrado y calibración sofisticados
2. **Flexibilidad de procesamiento**: Permite aplicar diferentes estrategias de filtrado en la aplicación
3. **Calibración dinámica**: La app puede recalibrar sin cambiar firmware del ESP32
4. **Peso como diagnóstico**: Permite comparar el cálculo del ESP32 vs el de la aplicación
5. **Validación cruzada**: El usuario/técnico puede verificar consistencia entre ambos valores
6. **Tara y cero**: Operaciones que requieren estado de UI y contexto de usuario

### 1.5 Validación del Protocolo

#### Validaciones Esperadas para JSON

| Validación | Descripción | Acción en caso de fallo |
|------------|-------------|------------------------|
| **JSON válido** | Verificar que el payload sea JSON bien formado | Descartar mensaje y loguear |
| **Campos requeridos** | Verificar presencia de `adc` y `peso` | Descartar mensaje y loguear |
| **Tipos de datos** | `adc` debe ser entero, `peso` debe ser numérico | Descartar mensaje y loguear |
| **Manejo de excepciones** | Try-catch en parseo JSON | Loguear error y continuar |

#### Validaciones Opcionales

| Validación | Razón |
|------------|-------|
| **Rango de ADC** | Hardware puede tener diferentes resoluciones, validar según necesidad |
| **Coherencia ADC-Peso** | Verificar que el peso del ESP32 sea consistente con el ADC (diagnóstico) |

---

## 2. FLUJO LÓGICO DE PROCESAMIENTO

### 2.1 Descripción General del Pipeline

El procesamiento de ADC → Peso sigue un pipeline secuencial y validado:

```
┌──────────────────────────────┐
│  Mensaje JSON desde BLE      │ ← Entrada desde BLE (cada ~50ms)
│  {"adc": 1234, "peso": 12.34}│   - JSON completo
└──────┬───────────────────────┘   - Dos campos: adc + peso
       │
       │ Parsing JSON
       ▼
┌──────────────────────────────┐
│  Campo ADC extraído          │
│  (Señal Cruda)               │   - Valor directo del sensor
└──────┬───────────────────────┘   - Sin procesar
       │                            - Unidad: cuentas ADC
       ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 1: ALMACENAMIENTO EN BUFFER                │
│ ─────────────────────────────────────────────    │
│ • Cola FIFO de muestras crudas                   │
│ • Capacidad: 50 muestras                         │
│ • Propósito: Acumular para filtrado posterior    │
└──────┬───────────────────────────────────────────┘
       │ (Procesamiento cada 100ms)
       ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 2: FILTRO 1 — TRIM MEAN                   │
│ ─────────────────────────────────────────────    │
│ • Toma últimas 10 muestras del buffer           │
│ • Ordena de menor a mayor                       │
│ • Elimina 2 mínimos y 2 máximos (outliers)     │
│ • Calcula promedio de las 6 restantes          │
│ • Resultado: ADC podado (double)               │
└──────┬───────────────────────────────────────────┘
       │ ✓ Outliers eliminados
       ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 3: FILTRO 2 — MOVING AVERAGE              │
│ ─────────────────────────────────────────────    │
│ • Buffer de ventana: 5 valores trimados        │
│ • Calcula promedio aritmético simple           │
│ • Resultado: ADC suavizado (double)            │
└──────┬───────────────────────────────────────────┘
       │ ✓ Señal suavizada
       ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 4: FILTRO 3 — EMA                         │
│ ─────────────────────────────────────────────    │
│ • Exponential Moving Average                    │
│ • Alpha = 0.3 (configurable)                   │
│ • Fórmula: EMA = α×nuevo + (1-α)×EMA_anterior │
│ • Resultado: ADC filtrado final (double)       │
└──────┬───────────────────────────────────────────┘
       │ ✓ ADC procesado
       ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 5: CALIBRACIÓN — ADC → PESO               │
│ ─────────────────────────────────────────────    │
│ • Fórmula: peso = (ADC - offset) × factorEscala │
│ • offset: ADC cuando peso = 0                   │
│ • factorEscala: kg por cuenta ADC               │
│ • Resultado: Peso base en kg (double)           │
└──────┬───────────────────────────────────────────┘
       │ ✓ Convertido a unidad física
       ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 6: CORRECCIÓN — AJUSTE FINO               │
│ ─────────────────────────────────────────────    │
│ • Factor de corrección: -10% a +10%            │
│ • Fórmula: peso_corr = peso × (1 + factor)     │
│ • Propósito: Compensar no-linealidades         │
│ • Resultado: Peso corregido (double)           │
└──────┬───────────────────────────────────────────┘
       │ ✓ Ajuste aplicado
       ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 7: TARA — RESTA DE CONTENEDOR             │
│ ─────────────────────────────────────────────    │
│ • Fórmula: peso_neto = peso_corr - tara        │
│ • tara: peso a restar (configurable por usuario)│
│ • Resultado: Peso neto (double)                │
└──────┬───────────────────────────────────────────┘
       │ ✓ Tara aplicada
       ▼
┌──────────────────────────────────────────────────┐
│ ETAPA 8: CUANTIZACIÓN — DIVISIÓN MÍNIMA         │
│ ─────────────────────────────────────────────    │
│ • División mínima: 0.001 kg (típico)           │
│ • Redondeo al múltiplo más cercano             │
│ • Resultado: Peso final cuantizado (double)    │
└──────┬───────────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│ Peso Final   │ ← Salida para UI y lógica
│   (kg)       │   - Filtrado
└──────────────┘   - Calibrado
                   - Corregido
                   - Con tara aplicada
                   - Cuantizado
```

### 2.2 Razón del Orden de Procesamiento

#### Por Qué los Filtros Van ANTES de la Calibración

**Principio fundamental**: Los filtros deben operar sobre la **señal cruda** (ADC), NO sobre la interpretación (peso).

| Aspecto | Aplicar sobre ADC | Aplicar sobre Peso |
|---------|-------------------|--------------------|
| **Linealidad** | ✅ ADC es espacio lineal | ❌ Peso puede tener no-linealidades post-calibración |
| **Outliers** | ✅ Detectables en rango ADC conocido | ❌ Más difícil detectar en espacio peso |
| **Rendimiento** | ✅ Operaciones sobre enteros/doubles simples | ⚠️ Similar, pero menos directo |
| **Independencia** | ✅ Filtros independientes de calibración | ❌ Filtros dependerían de parámetros de calibración |

**Ejemplo de problema si se filtra el peso**:
```
ADC crudos: [1000, 1002, 5000, 1001]  ← outlier obvio (5000)
Pesos:      [10.0, 10.2, 498.0, 10.1] ← outlier obvio (498.0)

Si se filtra ADC → trim elimina 5000 → calibra → peso limpio
Si se filtra peso → trim elimina 498.0 → pero ya se calibró mal
```

#### Orden Específico de Filtros

1. **Trim Mean primero**: Elimina outliers discretos antes de promediar
2. **Moving Average segundo**: Suaviza la señal ya limpia
3. **EMA tercero**: Aplica suavizado exponencial final

Este orden está **validado en campo** y debe mantenerse.

### 2.3 Flujo de Datos: ADC y Peso en Paralelo

```
┌─────────────────────────────────────────────────────────┐
│                    OBSERVABLE STATE                      │
│                                                           │
│  ┌────────────────┐              ┌────────────────┐     │
│  │  ADC Crudo     │              │  Peso Final    │     │
│  │  (Señal)       │              │  (Resultado)   │     │
│  │                │              │                │     │
│  │  Int           │              │  Double (kg)   │     │
│  └────────────────┘              └────────────────┘     │
│         │                                  ▲             │
│         │                                  │             │
│         └──────────┐            ┌──────────┘             │
│                    │            │                        │
│                    ▼            │                        │
│              ┌────────────────────┐                      │
│              │   UI / Pantallas   │                      │
│              │                    │                      │
│              │  • Muestra ADC     │                      │
│              │  • Muestra Peso    │                      │
│              │  • Ambos visibles  │                      │
│              └────────────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

**Observación importante**: El sistema mantiene disponibles tanto el ADC crudo como el peso procesado. Ambos fluyen en paralelo y pueden observarse simultáneamente.

---

## 3. SEPARACIÓN DE RESPONSABILIDADES

### 3.1 Propuesta Arquitectónica Conceptual

Esta sección define **dónde debería vivir cada responsabilidad** en una arquitectura limpia, sin implementar cambios.

```
┌─────────────────────────────────────────────────────────┐
│                    CAPA DE ADAPTADORES                   │
│  ───────────────────────────────────────────────────    │
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │  ADAPTADOR BLE                                    │  │
│  │  ─────────────────────────────────────────────    │  │
│  │                                                   │  │
│  │  Responsabilidades:                               │  │
│  │  • Gestión de conexión BLE                        │  │
│  │  • Escaneo de dispositivos                        │  │
│  │  • Activación de notificaciones GATT              │  │
│  │  • Recepción de mensajes JSON vía BLE             │  │
│  │  • Parsing JSON (extracción de campos)            │  │
│  │  • Emisión de ADC crudo a observadores            │  │
│  │  • Emisión de peso del ESP32 a observadores       │  │
│  │    (para diagnóstico/validación)                  │  │
│  │                                                   │  │
│  │  Límites:                                          │  │
│  │  • NO procesa el ADC (solo extrae del JSON)       │  │
│  │  • NO calcula peso (solo pasa el del ESP32)       │  │
│  │  • NO aplica filtros                              │  │
│  │                                                   │  │
│  │  Salidas:                                          │  │
│  │  • Stream<int> adcStream                          │  │
│  │  • Stream<double> pesoESP32Stream (opcional)      │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
└───────────────────────┬───────────────────────────────────┘
                        │
                        │ ADC crudo (int)
                        ▼
┌─────────────────────────────────────────────────────────┐
│                     CAPA DE DOMINIO                      │
│  ───────────────────────────────────────────────────    │
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │  CORE DE PROCESAMIENTO DE PESO                    │  │
│  │  ─────────────────────────────────────────────    │  │
│  │                                                   │  │
│  │  Responsabilidades:                               │  │
│  │  • Recepción de ADC desde adaptador BLE           │  │
│  │  • FILTROS (sobre ADC):                           │  │
│  │    - Buffer de muestras crudas                    │  │
│  │    - Trim mean (eliminación de outliers)          │  │
│  │    - Moving average (ventana móvil)               │  │
│  │    - EMA (suavizado exponencial)                  │  │
│  │  • CALIBRACIÓN:                                   │  │
│  │    - Conversión ADC → peso base                   │  │
│  │    - Uso de offset y factor de escala             │  │
│  │  • CORRECCIONES:                                  │  │
│  │    - Factor de corrección (-10% a +10%)           │  │
│  │  • OPERACIONES DE PESAJE:                         │  │
│  │    - Aplicación de tara                           │  │
│  │    - Establecer cero                              │  │
│  │  • CUANTIZACIÓN:                                  │  │
│  │    - División mínima                              │  │
│  │  • Emisión de valores procesados                  │  │
│  │                                                   │  │
│  │  Límites:                                          │  │
│  │  • NO conoce detalles del protocolo BLE           │  │
│  │  • NO maneja UI directamente                      │  │
│  │  • NO guarda sesiones (es lógica pura)            │  │
│  │                                                   │  │
│  │  Salidas:                                          │  │
│  │  • Stream<int> adcCrudoObservable                 │  │
│  │  • Stream<double> pesoProcesadoObservable         │  │
│  │  • Stream<EstadoEstabilidad> estabilidadObservable│  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
└───────────────────────┬───────────────────────────────────┘
                        │
                        │ Peso procesado (double)
                        │ ADC crudo (int)
                        │ Estado de estabilidad
                        ▼
┌─────────────────────────────────────────────────────────┐
│                      CAPA DE ESTADO                      │
│  ───────────────────────────────────────────────────    │
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │  ESTADO OBSERVABLE (Notifiers/Streams)            │  │
│  │  ─────────────────────────────────────────────    │  │
│  │                                                   │  │
│  │  Responsabilidades:                               │  │
│  │  • Mantener estado actual observable del sistema  │  │
│  │  • ADC crudo (último valor + histórico)           │  │
│  │  • Peso procesado final                           │  │
│  │  • Estado de conexión BLE                         │  │
│  │  • Estado de estabilidad                          │  │
│  │  • Configuración actual (calibración, filtros)    │  │
│  │  • Tara activa                                    │  │
│  │                                                   │  │
│  │  Límites:                                          │  │
│  │  • NO procesa datos (solo almacena y notifica)    │  │
│  │  • NO contiene lógica de negocio                  │  │
│  │                                                   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
└───────────────────────┬───────────────────────────────────┘
                        │
                        │ Observables
                        ▼
┌─────────────────────────────────────────────────────────┐
│                       CAPA DE UI                         │
│  ───────────────────────────────────────────────────    │
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │  PANTALLAS Y WIDGETS                              │  │
│  │  ─────────────────────────────────────────────    │  │
│  │                                                   │  │
│  │  Responsabilidades:                               │  │
│  │  • SOLO observar estado                           │  │
│  │  • Mostrar ADC crudo                              │  │
│  │  • Mostrar peso procesado                         │  │
│  │  • Mostrar estado de conexión                     │  │
│  │  • Capturar acciones del usuario                  │  │
│  │  • Enviar comandos al CORE (ej: "tarar")          │  │
│  │                                                   │  │
│  │  Límites:                                          │  │
│  │  • NO procesa ADC                                 │  │
│  │  • NO calcula peso                                │  │
│  │  • NO aplica filtros                              │  │
│  │  • NO modifica configuración directamente         │  │
│  │    (pasa por capa de servicios/CORE)              │  │
│  │                                                   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Detalle de Responsabilidades por Módulo

#### ADAPTADOR BLE

**Propósito**: Interfaz con el hardware Bluetooth

| Responsabilidad | Detalle |
|-----------------|---------|
| **Conectar** | Escanear, conectar, configurar MTU |
| **Recibir** | Suscribirse a notificaciones GATT |
| **Parsear JSON** | Convertir mensaje JSON → campos estructurados |
| **Extraer campos** | Extraer `adc` (int) y `peso` (double) del JSON |
| **Emitir** | Publicar ADC y peso ESP32 en streams observables |

**NO hace**:
- NO filtra el ADC
- NO calibra
- NO procesa el peso (solo lo pasa como diagnóstico)

**Salidas**: 
- `Stream<int> adcStream` (señal primaria)
- `Stream<double> pesoESP32Stream` (informativo/diagnóstico)

#### CORE DE PROCESAMIENTO

**Propósito**: Lógica de negocio de conversión ADC → Peso

| Responsabilidad | Detalle |
|-----------------|---------|
| **Filtrar ADC** | Trim mean → Moving avg → EMA |
| **Calibrar** | ADC → kg usando offset y factor |
| **Corregir** | Aplicar factor de corrección |
| **Tarar** | Restar tara configurada |
| **Cuantizar** | Redondear a división mínima |
| **Detectar estabilidad** | Analizar varianza de señal |

**NO hace**:
- NO conoce BLE
- NO dibuja UI
- NO persiste sesiones (eso es capa superior)

**Entradas**: 
- `Stream<int> adcStream` (del adaptador)
- Configuración de calibración
- Configuración de filtros

**Salidas**:
- `Stream<int> adcCrudo` (pass-through para UI)
- `Stream<double> pesoProcesado`
- `Stream<bool> esEstable`

#### ESTADO OBSERVABLE

**Propósito**: Mantener estado actual del sistema

| Responsabilidad | Detalle |
|-----------------|---------|
| **Almacenar estado actual** | Último ADC, último peso, conexión |
| **Notificar cambios** | ValueNotifier, StreamController |
| **Configuración activa** | Calibración, tara, filtros |

**NO hace**:
- NO procesa datos
- NO tiene lógica de negocio

**Expone**:
- `ValueNotifier<int> adcActual`
- `ValueNotifier<double> pesoActual` (peso procesado por la app)
- `ValueNotifier<double> pesoESP32` (peso del ESP32, opcional para diagnóstico)
- `ValueNotifier<BluetoothStatus> conexionBLE`
- `ValueNotifier<bool> estable`

#### CAPA DE UI

**Propósito**: Presentación e interacción con usuario

| Responsabilidad | Detalle |
|-----------------|---------|
| **Observar** | Escuchar cambios de estado |
| **Renderizar** | Mostrar ADC crudo y peso |
| **Capturar acciones** | Botones de tara, cero, calibración |
| **Navegar** | Entre pantallas de configuración |

**NO hace**:
- NO procesa ADC
- NO calcula peso
- NO aplica filtros (solo configura parámetros)

---

## 4. IMPLICANCIAS DE UI

### 4.1 Principios de Diseño de Interfaz

Esta sección describe **conceptualmente** qué debería poder hacer el usuario en la interfaz, sin diseñar pantallas específicas.

#### Principio 1: Visibilidad de Datos Crudos y Procesados

El sistema debe permitir **ver simultáneamente**:

```
┌─────────────────────────────────────┐
│     PANTALLA PRINCIPAL              │
│                                     │
│  ADC Crudo:     1234 cuentas        │  ← Señal directa del sensor (del JSON)
│  ────────────────────────────────   │
│                                     │
│  Peso App:      12.34 kg            │  ← Resultado procesado por la app
│  ────────────────────────────────   │
│                                     │
│  Peso ESP32:    12.30 kg            │  ← Peso del ESP32 (diagnóstico/validación)
│  ────────────────────────────────   │
│                                     │
│  Estado:        ⚫ Estable           │  ← Indicador de estabilidad
│                                     │
└─────────────────────────────────────┘
```

**Razón**: Transparencia y diagnóstico. El usuario/técnico puede:
- Verificar que el sensor funciona (ADC cambia)
- Confirmar que el procesamiento es correcto
- Comparar peso de la app vs peso del ESP32
- Detectar problemas (ADC cambia pero peso no, o viceversa)
- Validar calibración (ambos pesos deberían ser similares)

#### Principio 2: Configuración Separada por Concepto

Las configuraciones deben estar organizadas conceptualmente:

```
┌─────────────────────────────────┐
│     MENÚ DE CONFIGURACIÓN       │
│                                 │
│  ▸ Conexión BLE                 │  ← Adaptador
│    • Escanear dispositivos      │
│    • Estado de conexión         │
│                                 │
│  ▸ Filtros                      │  ← CORE (procesamiento)
│    • Tamaño de buffer           │
│    • Parámetros trim mean       │
│    • Ventana moving average     │
│    • Alpha de EMA               │
│                                 │
│  ▸ Calibración                  │  ← CORE (calibración)
│    • Offset (ADC en cero)       │
│    • Factor de escala           │
│    • Proceso de calibración     │
│                                 │
│  ▸ Corrección                   │  ← CORE (ajuste fino)
│    • Factor de corrección (%)   │
│                                 │
│  ▸ Operación                    │  ← CORE (pesaje)
│    • División mínima            │
│    • Unidad de medida           │
│    • Tara                       │
│                                 │
└─────────────────────────────────┘
```

**Razón**: Separación de conceptos clara. Cada sección mapea a una responsabilidad específica del sistema.

### 4.2 Funcionalidades Esperadas

#### Visualización

| Dato a Mostrar | Ubicación Conceptual | Actualización |
|----------------|---------------------|---------------|
| **ADC crudo** | Pantalla principal | Tiempo real (~100ms) |
| **Peso procesado (App)** | Pantalla principal | Tiempo real (~100ms) |
| **Peso ESP32** | Pantalla principal (diagnóstico) | Tiempo real (~50ms) |
| **Indicador de estabilidad** | Pantalla principal | Tiempo real |
| **Estado de conexión BLE** | Header / Barra superior | Al cambiar |
| **Configuración activa** | Pantalla de ajustes | Al modificar |

#### Acciones del Usuario

| Acción | Efecto en CORE | Efecto en Estado |
|--------|----------------|------------------|
| **Conectar BLE** | N/A | Adaptador BLE conecta |
| **Tarar** | CORE aplica tara = peso actual | Tara actualizada |
| **Establecer cero** | CORE recalibra offset | Offset actualizado |
| **Modificar filtros** | CORE usa nuevos parámetros | Configuración actualizada |
| **Calibrar** | CORE recalcula factor escala | Calibración actualizada |

### 4.3 Flujo de Interacción Conceptual

#### Caso: Configurar Filtros

```
Usuario                      UI                    CORE
   │                         │                      │
   │ Abre ajustes           │                      │
   │────────────────────────>│                      │
   │                         │                      │
   │                         │ Muestra configuración│
   │<────────────────────────│     actual           │
   │                         │                      │
   │ Modifica alpha EMA     │                      │
   │────────────────────────>│                      │
   │                         │                      │
   │                         │ Actualiza parámetro  │
   │                         │─────────────────────>│
   │                         │                      │
   │                         │                      │ (Filtros usan
   │                         │                      │  nuevo alpha)
   │                         │                      │
   │ Ve cambio en peso      │                      │
   │<────────────────────────│<─────────────────────│
   │   (nuevo suavizado)    │  (peso actualizado)  │
```

#### Caso: Visualizar ADC y Peso

```
Adaptador BLE          CORE                 Estado           UI
      │                 │                     │              │
      │ JSON recibido  │                     │              │
      │ {adc:1234,     │                     │              │
      │  peso:12.30}   │                     │              │
      │─────────────────>│                     │              │
      │                 │                     │              │
      │ Emite ADC=1234 │                     │              │
      │─────────────────>│                     │              │
      │                 │                     │              │
      │                 │ Filtra+Calibra     │              │
      │                 │ PesoApp=12.34 kg   │              │
      │                 │─────────────────────>│              │
      │                 │                     │              │
      │ Emite Peso     │                     │              │
      │ ESP32=12.30    │                     │              │
      │─────────────────────────────────────>│              │
      │                 │                     │              │
      │                 │                     │ Notifica     │
      │                 │                     │──────────────>│
      │                 │                     │              │
      │                 │                     │              │ Renderiza:
      │                 │                     │              │ ADC: 1234
      │                 │                     │              │ Peso App: 12.34
      │                 │                     │              │ Peso ESP32: 12.30
```

### 4.4 Subsecciones Propuestas de Configuración

#### Subsección: Filtros

**Intención arquitectónica**: Permitir ajustar parámetros de filtrado del ADC

Parámetros ajustables conceptualmente:
- Tamaño de buffer de muestras crudas
- Número de muestras para trim mean
- Cantidad de recortes en trim
- Ventana de moving average
- Alpha de EMA

**Ubicación**: `Menú → Ajustes → Filtros`

#### Subsección: Calibración

**Intención arquitectónica**: Permitir calibrar la conversión ADC → Peso

Parámetros ajustables conceptualmente:
- Offset (ADC cuando peso = 0)
- Factor de escala (kg por cuenta ADC)
- Proceso guiado de calibración (con pesos conocidos)

**Ubicación**: `Menú → Ajustes → Calibración`

#### Subsección: Corrección

**Intención arquitectónica**: Permitir ajuste fino del peso calculado

Parámetros ajustables conceptualmente:
- Factor de corrección (-10% a +10%)

**Ubicación**: `Menú → Ajustes → Corrección`

### 4.5 Consideraciones de Diseño

#### ¿Qué NO se Define Aquí?

❌ Diseño visual específico (colores, tipografía, espaciado)  
❌ Disposición exacta de elementos en pantalla  
❌ Iconografía o branding  
❌ Animaciones o transiciones  
❌ Navegación detallada entre pantallas  

#### ¿Qué SÍ se Define Aquí?

✅ Qué datos deben ser visibles  
✅ Qué acciones debe poder realizar el usuario  
✅ Cómo se agrupan conceptualmente las configuraciones  
✅ Qué información es esencial vs secundaria  

---

## 5. ANEXOS Y REFERENCIAS

### 5.1 Documentos Relacionados

| Documento | Ubicación | Propósito |
|-----------|-----------|-----------|
| **Extracción de Conocimiento** | `docs/EXTRACCION_CONOCIMIENTO_DATOS_BLE_Y_PESO.md` | Análisis exhaustivo del sistema actual |
| **Análisis Técnico** | `ANALISIS_TECNICO_PESAJE_BLE.md` | Especificación técnica completa |
| **Dudas Técnicas** | `docs/DUDAS.md` | Ambigüedades identificadas |

### 5.2 Glosario de Términos

| Término | Definición |
|---------|------------|
| **ADC** | Analog-to-Digital Converter. Valor numérico crudo del sensor (cuentas digitales) |
| **BLE** | Bluetooth Low Energy. Protocolo de comunicación inalámbrica |
| **GATT** | Generic Attribute Profile. Protocolo de servicios BLE |
| **Trim Mean** | Promedio podado. Técnica de filtrado que elimina valores extremos antes de promediar |
| **Moving Average** | Promedio móvil. Filtro que promedia una ventana deslizante de valores |
| **EMA** | Exponential Moving Average. Filtro que da más peso a valores recientes |
| **Offset** | Valor ADC cuando no hay peso (cero del sensor) |
| **Factor de Escala** | Multiplicador para convertir cuentas ADC a kilogramos |
| **Tara** | Peso a restar del resultado (típicamente contenedor) |
| **División Mínima** | Resolución mínima de lectura (cuantización) |

### 5.3 Fórmulas Clave (Resumen)

#### Filtros

```
Trim Mean:
  sorted = sort(últimas_10_muestras)
  trimmed = sorted[2:-2]  // elimina 2 min y 2 max
  result = mean(trimmed)

Moving Average:
  result = sum(últimos_5_valores) / 5

EMA:
  EMA(t) = alpha × valor_nuevo + (1 - alpha) × EMA(t-1)
```

#### Calibración y Procesamiento

```
Peso Base:
  peso_base = (ADC_filtrado - offset) × factor_escala

Corrección:
  peso_corregido = peso_base × (1 + factor_correccion)

Tara:
  peso_neto = peso_corregido - tara

Cuantización:
  peso_final = round(peso_neto / division_minima) × division_minima
```

### 5.4 Decisiones Arquitectónicas Clave

#### ¿Por Qué Filtrar el ADC y NO el Peso?

**Razón**: El ADC es el espacio lineal correcto para filtrado de señal. Filtrar peso implicaría:
- Dependencia de parámetros de calibración en filtros
- Pérdida de capacidad de detectar outliers en rango ADC
- Complejidad innecesaria

**Validado en campo**: Este enfoque está probado y funcional.

#### ¿Por Qué Tres Filtros en Serie?

**Razón**: Cada filtro cumple un propósito específico:
1. **Trim Mean**: Elimina outliers discretos (picos)
2. **Moving Average**: Suaviza varianza de corto plazo
3. **EMA**: Proporciona respuesta adaptativa y suavizado continuo

**Orden validado**: No cambiar sin pruebas exhaustivas.

#### ¿Por Qué ADC y Peso Visibles Simultáneamente?

**Razón**: Transparencia operativa y diagnóstico:
- Técnicos pueden verificar funcionamiento del sensor
- Usuarios avanzados pueden detectar problemas de calibración
- Facilita depuración en campo

### 5.5 Consideraciones para ETAPA 16.2 (Implementación Futura)

Cuando se implemente el código basado en esta documentación, considerar:

1. **No cambiar el protocolo BLE**: Está definido por hardware externo
2. **Respetar el orden de filtros**: Está validado en operación real
3. **Mantener ADC y Peso observables**: Ambos son útiles
4. **Configuración persistente**: Calibración y filtros deben guardarse
5. **Manejo de errores**: BLE puede desconectarse, manejar reconexión
6. **Estabilidad**: Implementar detector de estabilidad (análisis de varianza)

### 5.6 Dudas Pendientes

Si durante la lectura de este documento surgen dudas sobre:

- Detalles del protocolo BLE
- Especificaciones de hardware
- Parámetros óptimos de filtros
- Rangos de calibración

Consultar: `docs/DUDAS.md` donde están documentadas las ambigüedades conocidas.

---

## ✅ RESUMEN EJECUTIVO

### Contrato de Datos BLE

- **Formato**: Binario (4 bytes, Int32 Little Endian)
- **Contenido**: Valor ADC crudo (señal del sensor)
- **Frecuencia**: ~50 ms (20 Hz)
- **Protocolo**: Notificaciones GATT sobre BLE

### Flujo de Procesamiento

```
ADC → Buffer → Trim Mean → Moving Avg → EMA → Calibración → Corrección → Tara → Cuantización → Peso Final
```

### Separación de Responsabilidades

- **Adaptador BLE**: Recepción y parsing
- **CORE**: Filtros, calibración, corrección, tara
- **Estado Observable**: Notificadores de cambios
- **UI**: Solo observa y muestra datos

### UI Conceptual

- Muestra ADC crudo y peso procesado simultáneamente
- Configuración separada: Filtros, Calibración, Corrección
- Acciones: Tarar, Cero, Calibrar, Ajustar parámetros

---

**Documento completado para ETAPA 16.1.2**  
**Próximo paso**: ETAPA 16.2 (Implementación — Futura)

📌 **Este documento NO implementa código**  
📌 **Este documento NO modifica funcionalidad existente**  
📌 **Este documento SOLO documenta y propone arquitectura conceptual**
