# 🔧 Mantenimiento del Proyecto — F16 Balanza Electrónica v2.0.0

**Última Actualización**: 18 de enero de 2026  
**Versión**: 2.0.0  
**Estado**: ESTABLE / PRODUCCIÓN  
**Punto Checkpoint**: Versión con BLE y reconexión automática validada en campo

---

## 📋 TABLA DE CONTENIDOS

1. [Compilación (Build)](#compilación-build)
2. [Generación de Launcher Icons](#generación-de-launcher-icons)
3. [Sistema Bluetooth (SPP + BLE)](#sistema-bluetooth-spp--ble)
4. [Gestión de Permisos](#gestión-de-permisos)
5. [Generación de PDF/Excel](#generación-de-pdfexcel)
6. [Limpieza y Análisis](#limpieza-y-análisis)
7. [Reglas Críticas de Mantenimiento](#reglas-críticas-de-mantenimiento)
8. [Debugging](#debugging)
9. [Posibles Errores Comunes](#posibles-errores-comunes)

---

## 🔨 COMPILACIÓN (BUILD)

### Requisitos Previos
- Flutter SDK ≥ 3.0.0 (canal stable recomendado)
- Android SDK API 31+
- Gradle compilatiblemente actualizado
- JDK 11 o superior

### Compilación APK Debug

Para testing y desarrollo:

```powershell
flutter pub get
flutter clean          # Recomendado si hay problemas previos
flutter build apk --debug
```

**Ubicación**: `build/app/outputs/apk/debug/app-debug.apk`  
**Tamaño aprox**: 150–180 MB  
**Instalación**: `adb install build/app/outputs/apk/debug/app-debug.apk`

### Compilación APK Release (Firmado)

Para producción:

```powershell
flutter pub get
flutter clean          # Recomendado
flutter build apk --release
```

**Ubicación**: `build/app/outputs/apk/release/app-release.apk`  
**Tamaño aprox**: 120–150 MB (optimizado)  
**Instalación**: `adb install build/app/outputs/apk/release/app-release.apk`

### Notas sobre Build
- El archivo `key.properties` debe estar configurado en `android/` para firmar releases
- Todos los builds se cachean en `build/`. Si hay problemas persistentes, ejecutar `flutter clean` primero
- Los tiempos de build suelen ser 2–5 min en máquinas modernas

---

## 🎨 GENERACIÓN DE LAUNCHER ICONS

El proyecto usa `flutter_launcher_icons` para generar íconos automáticamente.

### Pasos

1. **Colocar ícono base** en `assets/appstore.png`:
   - Resolución recomendada: 1024x1024 px
   - Formato: PNG con canal alfa

2. **Ejecutar generador**:

```powershell
flutter pub get
flutter pub run flutter_launcher_icons:main
```

3. **Verificar resultados**:
   - Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Configuración
- Definida en `pubspec.yaml` bajo `flutter_icons:`
- El nombre de archivo de entrada: `appstore`
- Salida se genera automáticamente en múltiples resoluciones

---

## 📡 SISTEMA BLUETOOTH (SPP + BLE)

### Arquitectura Actual (v2.0.0)

**F16 soporta dos protocolos Bluetooth**:

1. **SPP (Bluetooth Serial Profile)**
   - Balanzas electrónicas clásicas
   - Comunicación vía InputStream/OutputStream
   - Configuración: Puerto serial emulado
   - Plugin: `flutter_bluetooth_serial` (fork local en `third_party/`)

2. **BLE (Bluetooth Low Energy)** — NUEVO en v2.0.0
   - Balanzas modernas y dispositivos de IoT
   - Comunicación vía GATT (Generic Attribute Profile)
   - Menor consumo de potencia
   - Plugin: `flutter_blue_plus`

### Reconexión Automática (v2.0.0)

El sistema incluye reintentos automáticos:

```dart
// En BluetoothService
// Tras desconexión accidental:
// 1. Intenta reconectar inmediatamente
// 2. Si falla, espera 2s y reintenta (máx 3 intentos)
// 3. Si sigue fallando, pasa a estado ERROR
// 4. Usuario puede reintentar manualmente desde UI
```

**Comportamiento esperado**:
- Si la balanza se desconecta: la app intentará reconectar automáticamente
- Si el usuario apaga la balanza: la app cambia a estado DISCONNECTED tras timeout (30s)
- Si hay interferencia: la app intenta mantener conexión con reintentos inteligentes

### Cambios Recientes

| Cambio | Versión | Impacto |
|--------|---------|--------|
| Soporte BLE añadido | 2.0.0 | +iOS compatible, mejor consumo |
| Reconexión automática | 2.0.0 | Mayor robustez ante desconexiones |
| Sincronización mejorada | 2.0.0 | Indicador BLE en todas las pantallas |
| Android 12+ validado | 1.0.1+ | Cero crashes de permisos |

### Flujo de Conexión

```
Usuario toca "Conectar"
    ↓
BluetoothAdapter verifica permisos runtime
    ↓
Intenta conectar (SPP o BLE según config)
    ↓
Si éxito: estado CONNECTED, escucha stream de datos
    ↓
Si timeout (30s): estado ERROR, ofrece reintentar
    ↓
Si éxito después de reintento: retorna a CONNECTED
    ↓
Si desconexión accidental: intenta reconectar (hasta 3 veces)
    ↓
Si persiste: estado ERROR, espera acción del usuario
```

---

## 🔐 GESTIÓN DE PERMISOS

### Permisos Requeridos (Android 12+)

En `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Permisos Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />

<!-- Para ubicación (requerido por algunos plugins) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Para almacenamiento (PDF/sesiones) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Solicitud en Runtime

El código solicita permisos dinámicamente usando `permission_handler`:

```dart
// BluetoothScreen.dart
if (await _requestBluetoothPermissions()) {
    // El usuario otorgó permisos
    // Proceder con conexión
} else {
    // El usuario denegó
    // Mostrar diálogo informativo
}
```

**Cuándo se solicitan**:
- Primera vez que el usuario intenta conectar dispositivo
- Si los permisos fueron revocados desde configuración del sistema
- Cada 30 días si no se utilizan (Android)

### Checklist de Permisos

- ✅ Declarados en AndroidManifest.xml
- ✅ Solicitados en runtime en BluetoothScreen
- ✅ Validados antes de cualquier operación Bluetooth
- ✅ Mensajes claros al usuario si son denegados
- ✅ Opción de "abrir configuración" si denegados

---

## 📄 GENERACIÓN DE PDF/EXCEL

### Librerías Utilizadas

| Librería | Función | Versión |
|----------|---------|---------|
| `package:pdf` | Generación de documentos PDF | 3.10.4+ |
| `package:printing` | Diálogo de impresión y vista previa | 5.12.0+ |
| `package:excel` | Exportación a formato XLSX | (si aplica) |

### Generación de PDF

```dart
// En SessionProScreen o HistoryScreen
final pdf = pw.Document();
pdf.addPage(
  pw.Page(
    build: (context) => _buildPdfContent(session),
  ),
);
// Compartir o guardar
await Printing.sharePdf(bytes: await pdf.save(), filename: 'sesion.pdf');
```

**Datos incluidos en PDF**:
- Fecha y hora de la sesión
- Tabla de mediciones (timestamp, peso, ADC)
- Estadísticas (min, max, promedio)
- Configuración de filtros usada
- Logo/header F16 (si aplica)

### Ubicación de Archivos Generados

- **Temporales**: Directorio temp del sistema (`getTemporaryDirectory()`)
- **Permanentes**: Almacenamiento externo si se guardan explícitamente

---

## 🧹 LIMPIEZA Y ANÁLISIS

### Análisis Estático (Flutter Analyzer)

```powershell
flutter analyze
```

Revisa:
- Errores de sintaxis
- Warnings de "código muerto"
- Problemas de tipos
- Mejores prácticas

**Resultado esperado**: 0 errores, warnings mínimos aceptados

### Linting Automático

```powershell
flutter format lib/         # Formatea código
dart fix --dry-run         # Propone fixes
dart fix --apply           # Aplica fixes automáticos
```

### Limpieza Profunda

```powershell
flutter clean              # Borra build/, cache
flutter pub get            # Reinstala dependencias
flutter pub outdated       # Muestra dependencias desactualizadas
```

**Cuándo hacer limpieza profunda**:
- Después de cambiar Flutter SDK
- Si los builds fallan con errores raros
- Antes de hacer release
- Si hay cambios en pubspec.yaml

### Caché del Pub

```powershell
# Limpiar caché global de pub
flutter pub cache repair
```

---

## 🛑 REGLAS CRÍTICAS DE MANTENIMIENTO

### ⚠️ NO TOCAR (Sin autorización explícita)

1. **Código Bluetooth en `bluetooth_service.dart` y `bluetooth_adapter.dart`**
   - La máquina de estados está calibrada
   - La reconexión automática es crítica
   - Cambios pueden causar desconexiones abruptas

2. **Fork local en `third_party/flutter_bluetooth_serial_fork/`**
   - Solo parches críticos de seguridad
   - Cambios de versión requieren testing exhaustivo
   - Sincronizar con upstream únicamente si hay fix crítico

3. **Calibración y Filtrado en `weight_service.dart`**
   - Validado en campo en múltiples balanzas
   - Cambios en EMA/trim afectan precisión
   - Requiere re-calibración de dispositivos

4. **Persistencia de Sesiones**
   - Datos actuales no deben corromperse
   - Migraciones de schema requieren cuidado especial
   - Backup recomendado antes de cambios

5. **Permisos en Android**
   - Android 12+ es restrictivo
   - Cambios pueden causar runtime crashes
   - Testear en múltiples API levels

### ✅ SEGURO CAMBIAR

- UI/colores/fuentes (siempre que no afecten indicadores críticos)
- Mensajes y textos (mantener términos técnicos)
- Layouts y responsive design (testear en orientación landscape)
- Strings/localizaciones (traducir a más idiomas)
- Documentación

### 🔄 PROCESOS DE CAMBIO APROBADO

**Para cambios Bluetooth/BLE**:
1. Crear rama feature (`git checkout -b feature/xxx`)
2. Implementar cambio
3. Testear en dispositivo real (no solo emulador)
4. Ejecutar `flutter analyze` sin errores
5. Hacer commit descriptivo
6. Solicitar review de código
7. Merge a `main` solo si pasa QA

**Para cambios en Calibración/Filtrado**:
1. Documentar cambio en este archivo
2. Testear con múltiples balanzas si es posible
3. Validar precisión antes/después
4. Re-calibrar dispositivos si es necesario

---

## 🐛 DEBUGGING

### Logs Detallados

```powershell
flutter run -v 2>&1 | tee flutter_debug.log
```

Esto:
- Ejecuta la app en modo verbose
- Guarda todos los logs en `flutter_debug.log`
- Permite revisar problemas post-ejecución

### Monitorear Logcat (Android)

```powershell
adb logcat | grep "flutter"
```

Para dispositivo específico:

```powershell
adb -s DEVICE_ID logcat | grep "flutter"
```

### Breakpoints en VS Code / Android Studio

1. Abrir archivo .dart
2. Hacer clic izquierdo en número de línea para agregar breakpoint
3. Ejecutar `flutter run`
4. La ejecución se pausará en el breakpoint
5. Inspeccionar variables en panel "Debug"

### Revisar Console Flutter

En VS Code, después de `flutter run`:
- Abre la consola integrada (Ctrl+`)
- Verá logs de Dart y Flutter en tiempo real
- Teclea `help` para ver comandos disponibles

### Ejemplo: Debugging de Conexión Bluetooth

```powershell
# 1. Ejecutar con verbose
flutter run -v

# 2. En la app, tocar "Conectar"
# 3. En consola, buscar líneas con "bluetooth" o "connection"
# 4. Identificar dónde falla (timeouts, permisos, etc.)

# 5. Inspeccionar logcat
adb logcat | grep "bluetooth"

# 6. Si persiste, revisar flutter_debug.log
```

---

## 🚨 POSIBLES ERRORES COMUNES

### Error: "flutter_bluetooth_serial not found"

**Síntomas**: Falla en compilación, import desconocido

**Causa**: Dependencias no resueltas

**Solución**:
```powershell
flutter pub get
flutter pub cache repair
flutter clean
flutter pub get  # De nuevo
flutter build apk --debug
```

---

### Error: "Permission denied (Bluetooth)"

**Síntomas**: App compila pero crash al conectar en Android 12+

**Causa**: Permisos runtime no concedidos

**Solución**:
1. Verificar que los permisos estén declarados en `AndroidManifest.xml`
2. Asegurarse de que el código solicita permisos en runtime
3. En settings del dispositivo, otorgar Bluetooth + Location si es necesario
4. Limpiar y reinstalar APK: `adb uninstall com.jncservicios.f16_balanza` && `flutter run`

---

### Error: "BluetoothConnection: No routes to host"

**Síntomas**: La app se conecta pero inmediatamente desconecta

**Causa**: 
- Dispositivo Bluetooth apagado o fuera de rango
- Balanza sin batería o sin módulo BT activado
- Interferencia de señal

**Solución**:
1. Verificar que el dispositivo Bluetooth esté encendido
2. Acercarse más al dispositivo
3. Apagar otros dispositivos que causan interferencia (WiFi cercano, microwaves)
4. Reintentar conexión
5. Si persiste: revisar logs con `flutter run -v`

---

### Error: "Gradle build failed"

**Síntomas**: Error durante `flutter build apk`

**Causa Común**: Incompatibilidad de versiones o dependencias obsoletas

**Solución**:
```powershell
flutter clean
flutter pub get
flutter pub upgrade    # Opcional, si las dependencias son seguras
flutter build apk --debug
```

Si sigue fallando:
```powershell
# Ver detalle del error
flutter build apk --debug -v 2>&1 | tail -n 50

# Revisar versión de Gradle
cat android/gradle/wrapper/properties
```

---

### Error: "Device connection timeout"

**Síntomas**: App intenta conectar pero timeout tras 30s

**Causa**: Dispositivo BT no responde, no emparejado, o fuera de rango

**Solución**:
1. Verificar que el dispositivo esté emparejado (Bluetooth settings)
2. Verificar que el MAC address sea correcto
3. Reiniciar el dispositivo Bluetooth
4. Aumentar timeout en código si es necesario (ADVANCED)

---

### Error: "app-release.apk: No such file or directory"

**Síntomas**: Falla al intentar instalar APK release

**Causa**: Build no generó archivo

**Solución**:
```powershell
# Verificar que build fue exitoso
flutter build apk --release -v

# Revisar ruta
dir build/app/outputs/apk/release/

# Si no existe, compilar de nuevo
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📞 SOPORTE

Para reportar issues:
1. Reproducir el problema
2. Capturar logs: `flutter run -v > logs.txt`
3. Incluir el archivo `logs.txt` en el reporte
4. Describir pasos exactos para reproducir
5. Mencionar dispositivo (marca, modelo, API level) y versión de balanza

---

**Mantenido por**: JNC Servicios Arg  
**Última revisión**: 18 de enero de 2026  
**Versión de documento**: 2.0.0  
**Licencia**: MIT

