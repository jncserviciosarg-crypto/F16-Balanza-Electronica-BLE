# ETAPA E — BLOQUE 1: Preparación Release Android
## Status: ✅ COMPLETADO

**Fecha**: 13 de diciembre de 2025  
**Commit**: `ef39669` - "ETAPA_E_BLOQUE_1: Configure release signing with keystore support"

---

## 📋 TAREAS EJECUTADAS

### 1. ✅ Verificar versionado
- **pubspec.yaml**: `version: 1.0.0+1`
- **android/app/build.gradle.kts**:
  - `versionCode` = `flutter.versionCode`
  - `versionName` = `flutter.versionName`
- **Coherencia**: ✅ Sincronizado y delegado correctamente a Flutter

### 2. ✅ Configurar keystore de release
**Archivos creados/modificados**:
- ✅ `android/key.properties.template` - Template documentado (nueva)
- ✅ `android/app/build.gradle.kts` - Configuración de signing (modificado)

**Características implementadas**:
```gradle-kotlin-dsl
// 1. Cargar key.properties automáticamente
val keystorePropertiesFile = rootProject.file("android/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// 2. signingConfigs.release bloque
signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }
}

// 3. Aplicar a buildTypes.release
buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
        isMinifyEnabled = false
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

**Seguridad**:
- ✅ `android/key.properties` está en `.gitignore` (nunca se versiona)
- ✅ `android/*.keystore` y `android/*.jks` están en `.gitignore`
- ✅ Template documenta el flujo de setup sin exponer credenciales

### 3. ✅ Sanity Check Android

| Parámetro | Valor | Status |
|-----------|-------|--------|
| `namespace` | `com.example.f16_balanza_electronica` | ✅ |
| `applicationId` | `com.example.f16_balanza_electronica` | ✅ |
| `minSdk` | `flutter.minSdkVersion` (delegado) | ✅ |
| `targetSdk` | `flutter.targetSdkVersion` (delegado) | ✅ |
| `compileSdk` | `flutter.compileSdkVersion` (delegado) | ✅ |
| Java/Kotlin | `VERSION_17` | ✅ |
| NDK Version | `flutter.ndkVersion` (delegado) | ✅ |
| `sourceCompatibility` | `JavaVersion.VERSION_17` | ✅ |
| `targetCompatibility` | `JavaVersion.VERSION_17` | ✅ |

**Permisos Bluetooth** (AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```
✅ Correctos para API 31+

### 4. ✅ Validaciones
| Validación | Resultado |
|-----------|-----------|
| `flutter pub get` | ✅ **Got dependencies!** Sin errores |
| `flutter analyze` | ✅ **518 issues** - Todos en `third_party/` |
| Errores en `lib/` | ✅ **CERO** |
| `git status` | ✅ **Working tree clean** |
| Cambios no confirmados | ✅ **NINGUNO** |

---

## 📁 ARCHIVOS TOCADOS

### Creados:
- `android/key.properties.template` (new file)

### Modificados:
- `android/app/build.gradle.kts` (+57 líneas, -3 líneas)

### Eliminados:
- Ninguno

---

## 🔄 COMMITS REALIZADOS

```
ef39669 ETAPA_E_BLOQUE_1: Configure release signing with keystore support
```

**Descripción atómica**:
- Cargar credenciales desde `key.properties`
- Crear `signingConfigs.release` condicional
- Aplicar firma a `buildTypes.release`
- Fallback a debug signing si falta `key.properties`
- Documentación de seguridad en template

---

## 🎯 PRÓXIMOS PASOS (BLOQUE 2)

Para compilar release, el usuario debe:

1. **Crear keystore**:
   ```bash
   keytool -genkey -v -keystore android/key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias release -storepass PASSWORD -keypass PASSWORD \
     -dname "CN=Your Name, OU=Unit, O=Company, L=City, S=State, C=Country"
   ```

2. **Crear `android/key.properties`** (copiar del template y rellenar):
   ```properties
   storePassword=<password-del-keystore>
   keyPassword=<password-de-la-clave>
   keyAlias=release
   storeFile=android/key.jks
   ```

3. **Compilar release**:
   ```bash
   flutter build apk --release
   # o
   flutter build appbundle --release
   ```

---

## ✅ GARANTÍAS DE ETAPA E — BLOQUE 1

- ✅ **NO actualizado** Flutter, Gradle, AGP, Java
- ✅ **NO modificadas** dependencias ni versiones
- ✅ **NO cambiada** lógica de la app
- ✅ **NO eliminadas** plataformas
- ✅ **NO migrado** a BLE
- ✅ **NO refactors**
- ✅ **Proyecto listo** para `flutter build apk --release` (con credenciales)
- ✅ **Sin compilar aún** (según instrucciones)

---

## 📊 ESTADO DEL PROYECTO

```
Branch: main
Commits ahead: 9
Working directory: Clean
Pub dependencies: Got dependencies!
Analysis errors (lib/): 0
Build ready: YES (cuando credentials sean proporcionados)
```

---

**ETAPA E — BLOQUE 1 FINALIZADO. Listo para entrega de credenciales y compilación en BLOQUE 2.**
