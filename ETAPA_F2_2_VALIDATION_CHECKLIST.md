# ETAPA F2.2 — CHECKLIST DE VALIDACIÓN

**Objetivo**: Verificar que la sincronización global de estado Bluetooth funciona correctamente

---

## ✅ VERIFICACIONES PRE-EJECUCIÓN

- [ ] **Compilación**: `flutter pub get` sin errores
- [ ] **Build**: `flutter build apk --release` completado
- [ ] **Dispositivo**: Android 11+ con Bluetooth disponible
- [ ] **Emulador**: (Opcional) Android Emulator API 31+
- [ ] **Dispositivo BT**: Balanza o módulo BT encendido y emparejado

---

## 🎯 PRUEBA 1: Indicadores Visibles

### HomeScreen
- [ ] Iniciar app → pantalla principal
- [ ] Verificar esquina superior derecha
- [ ] Buscar icono Bluetooth con borde
- [ ] Estado esperado: **Gris (desconectado)** o **Verde (conectado)**

### CalibrationScreen
- [ ] Navegar a CALIBRAR
- [ ] Verificar AppBar (título "CALIBRACIÓN")
- [ ] Buscar icono Bluetooth entre título y botón screenshot
- [ ] Estado esperado: Sincronizado con HomeScreen

### ConfigScreen
- [ ] Navegar a CONFIG
- [ ] Verificar icono Bluetooth en AppBar
- [ ] Estado esperado: Sincronizado con HomeScreen

### SessionProScreen
- [ ] En HomeScreen, presionar CARGA
- [ ] Verificar icono Bluetooth en AppBar
- [ ] Estado esperado: Sincronizado

---

## 🔄 PRUEBA 2: Sincronización en Navegación

### Caso de Uso 1: Desconectado

```
Precondiciones: Bluetooth desconectado (gris)

1. HomeScreen → indicador GRIS
2. Navegar a CALIBRAR → indicador GRIS en AppBar
3. Volver atrás (back button) → HomeScreen indicador GRIS
4. Navegar a CONFIG → indicador GRIS en AppBar

✅ ESPERADO: Todos los indicadores GRISES (consistentes)
❌ FALLO: Algunos indicadores en diferentes estados
```

### Caso de Uso 2: Conectado

```
Precondiciones: Dispositivo BT pareado y conectado (verde)

1. HomeScreen → indicador VERDE
2. Navegar a CALIBRAR → indicador VERDE en AppBar
3. Volver atrás → HomeScreen indicador VERDE
4. Navegar a CARGA → SessionPro indicador VERDE en AppBar
5. Volver atrás → HomeScreen indicador VERDE

✅ ESPERADO: Todos los indicadores VERDES (consistentes)
❌ FALLO: Algunos indicadores en diferentes estados
```

---

## ⚡ PRUEBA 3: Transiciones de Estado (Conectar/Desconectar)

### Conectar desde BluetoothScreen

```
Precondiciones: Bluetooth desconectado

1. HomeScreen abierta → indicador GRIS
2. Navegar a BT
3. Presionar dispositivo para conectar
4. Durante conexión → indicador NARANJA (conectando)
5. Conexión exitosa → indicador VERDE
6. Volver a HomeScreen → indicador VERDE (SIN RETRASO)

✅ ESPERADO: Transición suave Gris → Naranja → Verde
❌ FALLO: Retraso >1 segundo en HomeScreen
❌ FALLO: Indicador no cambia
```

### Desconectar desde BluetoothScreen

```
Precondiciones: Bluetooth conectado

1. HomeScreen abierta → indicador VERDE
2. Navegar a BT
3. Presionar dispositivo para desconectar
4. Inmediato → indicador GRIS
5. Volver a HomeScreen → indicador GRIS

✅ ESPERADO: Cambio inmediato a GRIS
❌ FALLO: HomeScreen sigue mostrando VERDE
```

---

## 🌐 PRUEBA 4: Sincronización Multi-Pantalla

### Tablet/Split-Screen (Si aplica)

```
Precondiciones: Tablet con pantalla grande (>900px)

1. Abrir HomeScreen en panel izquierdo
2. Abrir CalibrationScreen en panel derecho
3. Ambas pantallas visibles simultáneamente
4. Desconectar Bluetooth (botón en BT Screen)
5. HomeScreen indicador → GRIS
6. CalibrationScreen indicador → GRIS (simultáneamente)

✅ ESPERADO: Ambas pantallas se actualizan al mismo tiempo
❌ FALLO: Una pantalla se actualiza con retraso
❌ FALLO: Indicadores en estados diferentes
```

---

## 📱 PRUEBA 5: Comportamiento con Background

### Escenario: App al Background

```
Precondiciones: Bluetooth conectado (VERDE)

1. HomeScreen abierta, indicador VERDE
2. Presionar botón Home del dispositivo (app → background)
3. Desconectar dispositivo BT físicamente
4. Esperar 2 segundos
5. Volver a la app (presionar recent apps o app icon)

✅ ESPERADO: Indicador GRIS (estado actual correcto)
❌ FALLO: Indicador sigue VERDE (estado antiguo)
```

### Escenario: App al Background + Reconexión

```
Precondiciones: Bluetooth conectado (VERDE)

1. HomeScreen abierta, indicador VERDE
2. Presionar botón Home (app → background)
3. Reconectar dispositivo BT externamente (mediante app del sistema)
4. Esperar 3 segundos
5. Volver a la app

✅ ESPERADO: Indicador VERDE (sin lag)
❌ FALLO: Indicador GRIS (no se actualizó)
❌ FALLO: App crash
```

---

## 🚨 PRUEBA 6: Manejo de Errores

### Escenario: Error de Conexión

```
Precondiciones: Dispositivo BT apagado o fuera de rango

1. HomeScreen abierta
2. Navegar a BT
3. Intentar conectar a dispositivo
4. Conexión fallará

✅ ESPERADO: Indicador ROJO (error) en ambas pantallas
❌ FALLO: Indicador NARANJA (conectando) indefinidamente
❌ FALLO: Indicador VERDE falsamente (sin datos ADC)
```

### Escenario: Desconexión Inesperada

```
Precondiciones: Bluetooth conectado (VERDE)

1. HomeScreen abierta, indicador VERDE
2. Apagar dispositivo BT remotamente
3. Esperar 5 segundos

✅ ESPERADO: 
   - Indicador cambia a ROJO o GRIS
   - WeightService deja de recibir ADC
   - Display de peso "congelado" (último valor)

❌ FALLO: 
   - Indicador sigue VERDE
   - App crash
```

---

## 🔍 PRUEBA 7: Tooltip (Información Flotante)

### HomeScreen Tooltip

```
1. HomeScreen, pausar cursor sobre indicador Bluetooth
2. Esperar 1 segundo

✅ ESPERADO: Tooltip aparece:
   - Si VERDE: "Bluetooth: Conectado"
   - Si NARANJA: "Bluetooth: Conectando..."
   - Si ROJO: "Bluetooth: Error de conexión"
   - Si GRIS: "Bluetooth: Desconectado"

❌ FALLO: No aparece tooltip
```

### AppBar Tooltips (Calibration/Config/SessionPro)

```
1. CalibrationScreen, pausar cursor sobre icono en AppBar
2. Esperar 1 segundo

✅ ESPERADO: Tooltip con estado actual
❌ FALLO: No aparece tooltip
```

---

## 📊 PRUEBA 8: Rendimiento

### Stress Test: Reconexiones Rápidas

```
Precondiciones: Bluetooth disponible

1. HomeScreen abierta
2. Abrir CalibrationScreen en split (si tablet)
3. Navegar a BluetoothScreen
4. Conectar/Desconectar/Conectar (5 veces en 10 segundos)
5. Observar indicadores

✅ ESPERADO:
   - Indicadores actualizan suavemente
   - Sin congelaciones
   - FPS estable (60 fps)

❌ FALLO:
   - App lenta o congelada
   - Rebuild excesivo
   - Consumo alto de CPU
```

### Memory Leak Test

```
Precondiciones: Bluetooth conectado

1. Abrir: HomeScreen → CalibrationScreen → ConfigScreen → SessionPro
2. Navegar atrás a HomeScreen (4 veces)
3. Repetir 5 veces (total: 20 navegaciones)
4. Verificar memoria (Settings > Apps > Memory)

✅ ESPERADO:
   - Memoria estable o ligeramente creciente
   - Dispositivo no se ralentiza

❌ FALLO:
   - Memoria crece continuamente
   - Dispositivo se ralentiza
```

---

## 💾 PRUEBA 9: Persistencia de Estado (Post-F2.3)

**NOTA**: Esta prueba está pendiente para ETAPA F2.3

```
1. Conectar a Bluetooth
2. Cerrar app completamente (force stop)
3. Reabrir app

Esperado en F2.3:
   - Indicador VERDE (auto-reconectado)
   - Estado restaurado

Actual (F2.2):
   - Indicador GRIS (reconexión manual requerida)
```

---

## 📋 REGISTRO DE RESULTADOS

### Fecha: _______________

| Prueba | Plataforma | Estado | Notas |
|--------|-----------|--------|-------|
| 1. Indicadores Visibles | [ ] Android | [ ] ✅ [ ] ❌ | |
| 2. Sincronización Navegación | [ ] Android | [ ] ✅ [ ] ❌ | |
| 3. Transiciones de Estado | [ ] Android | [ ] ✅ [ ] ❌ | |
| 4. Multi-Pantalla | [ ] Tablet | [ ] ✅ [ ] ❌ | |
| 5. Comportamiento Background | [ ] Android | [ ] ✅ [ ] ❌ | |
| 6. Manejo de Errores | [ ] Android | [ ] ✅ [ ] ❌ | |
| 7. Tooltips | [ ] Android | [ ] ✅ [ ] ❌ | |
| 8. Rendimiento | [ ] Android | [ ] ✅ [ ] ❌ | |

### Resumen
- **Total Pruebas**: 8
- **Exitosas**: ___/8
- **Fallidas**: ___/8
- **Tasa de Éxito**: ____%

### Observaciones
```
[Espacio para notas]
```

---

## 🐛 Problemas Encontrados

### Si una prueba falla:

1. **Anotar el número de prueba y detalles**
2. **Reproducir paso a paso (con logs si es necesario)**
3. **Verificar en terminal**:
   ```bash
   flutter run -v
   ```
4. **Ver logs de Bluetooth**:
   ```bash
   adb logcat | grep -i bluetooth
   ```

### Archivo de log sugerido:
```
logs/
└─ F2_2_VALIDATION_<FECHA>.log
```

---

## ✅ Criterios de Aceptación Final

- [ ] Pruebas 1-7 al 100% exitosas
- [ ] Prueba 8 (rendimiento) sin problemas críticos
- [ ] Cero crashes durante todas las pruebas
- [ ] Indicadores sincronizados en todas las pantallas
- [ ] No hay memory leaks detectados
- [ ] Tooltips funcionan en todas las pantallas
- [ ] Transiciones de estado son suaves (<500ms)

---

## 🚀 Próximos Pasos

Si todas las pruebas pasan ✅:
1. Proceder a ETAPA F2.3 (Persistencia)
2. Documentar en changelog

Si hay fallos ❌:
1. Revisar logs en `flutter run -v`
2. Abrir issue con reproducción mínima
3. Verificar BluetoothService.statusNotifier

---

**Documento de Validación Generado**: ETAPA F2.2  
**Versión**: 1.0  
**Última Actualización**: 10 de enero de 2026
