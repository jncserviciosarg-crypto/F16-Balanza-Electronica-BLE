# ❓ DUDAS TÉCNICAS — Sistema BLE y Procesamiento de Peso

**Proyecto**: F16 Balanza Electrónica BLE  
**Fecha**: 11 de febrero de 2026  
**Propósito**: Registrar ambigüedades encontradas durante la extracción de conocimiento

---

## ⚠️ IMPORTANTE

Este documento contiene dudas técnicas identificadas durante el análisis del código existente. Estas dudas **NO son problemas del código actual** (que funciona correctamente), sino **falta de documentación explícita** sobre decisiones de diseño o especificaciones del hardware.

**Ninguna de estas dudas impide la operación del sistema actual.**

---

## 📋 ÍNDICE DE DUDAS

1. [Resolución Real del ADC](#1-resolución-real-del-adc)
2. [Frecuencia Exacta de Envío BLE](#2-frecuencia-exacta-de-envío-ble)
3. [Significado de Bytes Adicionales](#3-significado-de-bytes-adicionales)
4. [Razón del Orden de Filtros](#4-razón-del-orden-de-filtros)
5. [Uso de Parámetros de Hardware en LoadCellConfig](#5-uso-de-parámetros-de-hardware-en-loadcellconfig)

---

## 1. Resolución Real del ADC

### 📍 Contexto

El sistema recibe valores ADC del hardware vía BLE. En el código se observa:

- **Tipo de dato**: Int32 (rango: -2,147,483,648 a 2,147,483,647)
- **Documentación existente**: Menciona rango "0 - 4095", sugiriendo ADC de 12 bits
- **Validación**: NO existe validación de rango en el código

**Ubicaciones en código**:
- `lib/services/bluetooth_service.dart` línea 462: `final int adcValue = byteData.getInt32(0, Endian.little);`
- `ANALISIS_TECNICO_PESAJE_BLE.md` línea 67: Comentario menciona "0 - 4095 (12 bits típico)"

### ❓ Qué No Está Claro

1. **¿El hardware realmente genera valores ADC de 12 bits (0-4095)?**
   - Si es así, ¿por qué usar Int32 que soporta 32 bits?
   - ¿Es por simplicidad de implementación o previsión de cambios futuros?

2. **¿Puede el ADC enviar valores negativos?**
   - El código acepta Int32 con signo
   - ¿Qué significaría un ADC negativo? ¿Sensor bipolar? ¿Error?

3. **¿Existe ADC de mayor resolución?**
   - ¿16 bits? (0-65,535)
   - ¿24 bits? (0-16,777,215) común en HX711
   - ¿32 bits reales?

### 💭 Opciones Existentes

| Opción | Descripción | Probabilidad |
|--------|-------------|--------------|
| **A** | ADC es realmente 12 bits, Int32 es oversizing por simplicidad de implementación | Alta |
| **B** | ADC es 24 bits (típico de HX711), el rango completo se usa | Media |
| **C** | ADC puede ser negativo (sensor bipolar o error de lectura) | Baja |

### ✅ Qué Necesita Confirmación Humana

1. **Revisar especificaciones del hardware real**:
   - ¿Qué ADC se usa? (HX711, ADS1234, otro)
   - ¿Qué resolución configurada? (12/16/24 bits)
   - ¿Rango de salida esperado?

2. **Revisar firmware del dispositivo BLE**:
   - ¿Qué valor se empaqueta en los 4 bytes?
   - ¿Se usa signo o sin signo?
   - ¿Hay transformación antes de enviar?

3. **Pruebas empíricas**:
   - Capturar paquetes BLE reales con sniffer
   - Registrar valores ADC mínimos y máximos en operación real
   - Verificar si alguna vez se reciben valores negativos

### 🎯 Impacto en Reutilización

- **Si ADC es 12 bits**: El código actual es sobre-dimensionado pero funcional
- **Si ADC es 24 bits**: El código actual es correcto
- **Si ADC puede ser negativo**: Puede requerir manejo especial (actualmente no se valida)

**Recomendación**: Documentar la resolución real del hardware antes de reutilizar en otro proyecto, ya que puede afectar la calibración y precisión esperada.

---

## 2. Frecuencia Exacta de Envío BLE

### 📍 Contexto

El hardware envía notificaciones BLE con valores ADC continuamente. En el código:

- **Procesamiento en app**: Timer de 100ms (`lib/services/weight_service.dart` línea 107-110)
- **Frecuencia inferida del hardware**: ~50ms (mencionado en comentarios)
- **No está codificado explícitamente**: La frecuencia del hardware no aparece en constantes

**Ubicaciones relevantes**:
- `ANALISIS_TECNICO_PESAJE_BLE.md` línea 100: "Frecuencia de envío: ~50ms (20 Hz)"
- Comentarios en código mencionan "cada ~50ms"

### ❓ Qué No Está Claro

1. **¿50ms es una frecuencia garantizada del hardware?**
   - ¿O es un valor aproximado observado?
   - ¿Está configurado en firmware o es limitación del ADC?

2. **¿Qué tan estable es la frecuencia?**
   - ¿Hay jitter significativo?
   - ¿Puede variar bajo carga de CPU del hardware?

3. **¿Por qué el procesamiento es a 100ms si el hardware envía a 50ms?**
   - ¿Es para reducir carga computacional?
   - ¿Es para acumular más muestras en buffers?

### 💭 Opciones Existentes

| Opción | Descripción | Probabilidad |
|--------|-------------|--------------|
| **A** | Hardware envía a frecuencia fija 50ms configurada en firmware | Alta |
| **B** | Hardware envía cuando ADC tiene nueva lectura disponible (frecuencia variable) | Media |
| **C** | Frecuencia puede cambiar según configuración del hardware | Baja |

### ✅ Qué Necesita Confirmación Humana

1. **Revisar firmware del dispositivo**:
   - ¿Hay timer configurado para envío BLE?
   - ¿Qué valor de delay entre notificaciones?

2. **Mediciones reales**:
   - Registrar timestamps de notificaciones BLE recibidas
   - Calcular estadísticas: media, desviación estándar, min, max
   - Verificar si hay drift a lo largo del tiempo

3. **Diseño de procesamiento**:
   - ¿Por qué se eligió 100ms para procesamiento?
   - ¿Fue resultado de pruebas de performance?

### 🎯 Impacto en Reutilización

- **Si frecuencia es 50ms fija**: El código actual es adecuado (buffers correctamente dimensionados)
- **Si frecuencia varía**: Puede requerir ajuste de tamaños de buffer o lógica adaptativa
- **Si frecuencia es diferente en otro hardware**: Requerirá calibrar timer de procesamiento y tamaños de buffer

**Recomendación**: Medir frecuencia real del hardware destino antes de reutilizar, especialmente para ajustar parámetros de filtros (muestras, ventana).

---

## 3. Significado de Bytes Adicionales

### 📍 Contexto

El protocolo BLE actual:

- **Lee solo los primeros 4 bytes** del paquete BLE
- **MTU configurado**: 512 bytes
- **Código de parseo**: `data.sublist(0, 4)` (ignora el resto)

**Ubicación en código**: `lib/services/bluetooth_service.dart` líneas 458-462

```dart
final Uint8List rawBytes = Uint8List.fromList(data.sublist(0, 4));
final ByteData byteData = ByteData.view(rawBytes.buffer);
final int adcValue = byteData.getInt32(0, Endian.little);
```

### ❓ Qué No Está Claro

1. **¿El hardware envía exactamente 4 bytes siempre?**
   - Si es así, ¿por qué MTU = 512?
   - ¿Es previsión para extensiones futuras?

2. **¿Existen bytes adicionales con otros datos?**
   - ¿Temperatura del sensor?
   - ¿Nivel de batería?
   - ¿Checksum o CRC?
   - ¿Estado del hardware?
   - ¿Timestamp del ADC?

3. **Si existen bytes adicionales, ¿son útiles?**
   - ¿Deben usarse para validación?
   - ¿Deben mostrarse en UI?
   - ¿Afectan calibración (ej: compensación térmica)?

### 💭 Opciones Existentes

| Opción | Descripción | Probabilidad |
|--------|-------------|--------------|
| **A** | Hardware envía exactamente 4 bytes (solo ADC) | Alta |
| **B** | Hardware envía más datos que la app ignora intencionalmente | Media |
| **C** | Protocolo permite extensión futura, ahora solo 4 bytes | Alta |

### ✅ Qué Necesita Confirmación Humana

1. **Captura de paquetes BLE reales**:
   - Usar sniffer Bluetooth (nRF Sniffer, Wireshark)
   - Verificar tamaño exacto de payloads recibidos
   - Analizar contenido de bytes más allá del 4to

2. **Revisar documentación de protocolo del hardware**:
   - ¿Existe especificación formal?
   - ¿Hay versiones del protocolo?
   - ¿Está planeada expansión?

3. **Consultar con equipo de hardware**:
   - ¿Qué se envía realmente?
   - ¿Por qué se eligieron 4 bytes?
   - ¿Hay planes de agregar datos adicionales?

### 🎯 Impacto en Reutilización

- **Si solo 4 bytes**: Código actual es correcto, sin cambios
- **Si hay bytes útiles ignorados**: Puede perderse información valiosa (temperatura, validación)
- **Si protocolo es extensible**: Considerar diseño que permita parseo de versiones futuras

**Recomendación**: Capturar paquetes reales del hardware destino y documentar protocolo completo antes de reutilizar, especialmente si se planea agregar funcionalidades futuras.

---

## 4. Razón del Orden de Filtros

### 📍 Contexto

El pipeline de filtrado tiene un orden específico:

1. **Trim Mean** (eliminar outliers)
2. **Moving Average** (promediar ventana)
3. **EMA** (suavizado exponencial)

**Ubicación**: `lib/services/weight_service.dart` función `_processData()` líneas 160-187

```dart
double trimmedMean = _calculateTrimmedMean();      // Paso 1
_windowBuffer.add(trimmedMean);                     // Paso 2 prep
double windowAverage = _calculateWindowAverage();   // Paso 2
double emaFiltered = _applyEMA(windowAverage);      // Paso 3
```

### ❓ Qué No Está Claro

1. **¿Por qué este orden específico?**
   - ¿Es óptimo desde teoría de procesamiento de señales?
   - ¿Fue encontrado empíricamente?

2. **¿Se probaron otros órdenes?**
   - ¿EMA → Trim → MA?
   - ¿MA → EMA → Trim?
   - ¿Cuáles fueron los resultados?

3. **¿Qué característica de la señal se optimiza?**
   - ¿Tiempo de respuesta?
   - ¿Reducción de ruido?
   - ¿Estabilidad?

### 💭 Opciones Existentes

| Opción | Descripción | Probabilidad |
|--------|-------------|--------------|
| **A** | Orden óptimo encontrado experimentalmente en campo | Alta |
| **B** | Orden basado en principios teóricos de DSP | Media |
| **C** | Orden arbitrario que funciona suficientemente bien | Baja |

### ✅ Qué Necesita Confirmación Humana

1. **Revisión de historial de desarrollo**:
   - ¿Hay registros de pruebas con diferentes órdenes?
   - ¿Existe documentación de decisiones de diseño?
   - ¿Comentarios en commits relacionados?

2. **Análisis teórico**:
   - ¿Hay estudios previos que justifiquen el orden?
   - ¿Características de la señal de entrada fueron analizadas?

3. **Pruebas comparativas**:
   - Implementar otros órdenes
   - Medir tiempo de respuesta, overshoot, ruido residual
   - Validar en condiciones reales de operación

### 🎯 Impacto en Reutilización

- **Si orden es crítico**: NO cambiar sin validación exhaustiva
- **Si orden es flexible**: Puede optimizarse para otros sensores/aplicaciones
- **Si no hay justificación documentada**: Considerar pruebas antes de reutilizar en aplicación crítica

**Recomendación**: Mantener el orden actual para reutilización inicial, ya que está validado en campo. Si se requiere optimización, realizar estudios comparativos específicos para el nuevo hardware.

---

## 5. Uso de Parámetros de Hardware en LoadCellConfig

### 📍 Contexto

El modelo `LoadCellConfig` incluye parámetros técnicos del hardware:

```dart
class LoadCellConfig {
  final double capacidadKg;           // ✅ Se usa: para detectar sobrecarga
  final double sensibilidadMvV;       // ❓ NO se usa en cálculos
  final double voltajeExcitacion;     // ❓ NO se usa en cálculos
  final double gananciaHX711;         // ❓ NO se usa en cálculos
  final double voltajeReferencia;     // ❓ NO se usa en cálculos
  final double divisionMinima;        // ✅ Se usa: cuantización
  final String unidad;                // ✅ Se usa: UI
  final double factorCorreccion;      // ✅ Se usa: corrección ±10%
}
```

**Ubicación**: `lib/models/load_cell_config.dart`

### ❓ Qué No Está Claro

1. **¿Por qué se guardan parámetros que no se usan?**
   - ¿Son solo metadatos informativos?
   - ¿Estaban previstos para cálculos que no se implementaron?

2. **¿Se pueden usar para calibración automática teórica?**
   - Fórmula teórica: `factor = (sensibilidad × voltaje × ganancia) / (ADC_max × capacidad)`
   - ¿Por qué no se usa esta fórmula en lugar de calibración empírica?

3. **¿Son reliquias de diseño anterior?**
   - ¿Se usaban en versiones antiguas del código?
   - ¿Se planea usarlos en futuras versiones?

### 💭 Opciones Existentes

| Opción | Descripción | Probabilidad |
|--------|-------------|--------------|
| **A** | Metadatos informativos para documentación del hardware | Alta |
| **B** | Originalmente se usaban, ahora obsoletos tras cambios de diseño | Media |
| **C** | Planificados para calibración automática en futuras versiones | Media |

### ✅ Qué Necesita Confirmación Humana

1. **Revisar historial de commits**:
   - ¿Cuándo se agregaron estos campos?
   - ¿Hubo código que los usaba?
   - ¿Por qué se dejaron de usar (si es el caso)?

2. **Consultar intención de diseño original**:
   - ¿Documentación de diseño inicial?
   - ¿Notas de reuniones de desarrollo?

3. **Evaluar utilidad actual**:
   - ¿Ayudan a entender la configuración del sistema?
   - ¿Son útiles para depuración?
   - ¿Deben mantenerse o eliminarse?

### 🎯 Impacto en Reutilización

- **Si son solo metadatos**: Mantener, son útiles para documentación
- **Si estaban previstos para uso futuro**: Considerar implementar calibración teórica
- **Si son obsoletos**: Pueden eliminarse para simplificar modelo

**Recomendación**: Mantener estos campos en reutilización, ya que son informativos y no afectan funcionalidad. Si se implementa calibración automática futura, podrían ser útiles.

---

## 📊 RESUMEN DE DUDAS

| # | Duda | Prioridad | Necesita Revisar |
|---|------|-----------|------------------|
| 1 | Resolución ADC | Alta | Hardware / Firmware |
| 2 | Frecuencia BLE | Media | Firmware / Mediciones |
| 3 | Bytes adicionales | Media | Captura de paquetes / Firmware |
| 4 | Orden de filtros | Baja | Historial / Teoría |
| 5 | Parámetros LoadCellConfig | Baja | Historial / Diseño |

### 🎯 Prioridades para Reutilización

**ALTA** (resolver antes de reutilizar):
- Resolución del ADC: Afecta precisión esperada y validaciones

**MEDIA** (resolver para optimizar):
- Frecuencia BLE: Afecta dimensionado de buffers
- Bytes adicionales: Puede haber información útil ignorada

**BAJA** (informativo):
- Orden de filtros: Ya validado, cambiar solo si se requiere optimización
- Parámetros hardware: Útiles para documentación, no críticos

---

## ✅ PRÓXIMOS PASOS RECOMENDADOS

Para resolver estas dudas antes de reutilizar el conocimiento en otro proyecto:

1. **Documentar hardware actual**:
   - Especificaciones del ADC
   - Configuración del firmware
   - Protocolo BLE completo

2. **Realizar mediciones**:
   - Captura de paquetes BLE (sniffer)
   - Registro de frecuencias reales
   - Análisis de valores ADC en operación

3. **Consolidar documentación**:
   - Crear especificación formal del protocolo
   - Documentar decisiones de diseño de filtros
   - Explicar parámetros de configuración

4. **Validación en nuevo hardware**:
   - Verificar compatibilidad de especificaciones
   - Ajustar parámetros según mediciones reales
   - Validar comportamiento en campo

---

**Fin del documento de dudas técnicas**
