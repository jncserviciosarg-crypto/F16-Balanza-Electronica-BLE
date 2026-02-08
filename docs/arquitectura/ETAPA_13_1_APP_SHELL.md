# ETAPA 13.1 — App Shell & Bootstrap de la Aplicación

**Fecha**: 8 de febrero de 2026  
**Estado**: ✅ COMPLETADO  
**Versión**: 1.0

---

## 📋 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Contexto en el Plan Maestro](#contexto-en-el-plan-maestro)
3. [Qué HACE esta Etapa](#qué-hace-esta-etapa)
4. [Qué NO HACE esta Etapa](#qué-no-hace-esta-etapa)
5. [Arquitectura Implementada](#arquitectura-implementada)
6. [Diferencias Clave](#diferencias-clave)
7. [Archivos Creados y Modificados](#archivos-creados-y-modificados)
8. [Criterios de Aceptación](#criterios-de-aceptación)
9. [Próximos Pasos](#próximos-pasos)

---

## 🎯 Resumen Ejecutivo

La **ETAPA 13.1** implementa la estructura base de la aplicación Flutter que actúa como **CONTENEDOR** del CORE ya implementado (servicios existentes). 

### Propósito

> 🧱 "Dar un cuerpo a la app donde viva el cerebro ya construido, sin interferir con él"

Esta etapa **NO** agrega comportamiento nuevo, **NO** modifica el pipeline lógico, **NO** ejecuta acciones reales. Su único propósito es proporcionar una estructura organizativa clara que separa:

- **CORE** (lógica de negocio existente)
- **App Shell** (contenedor Flutter)
- **Bootstrap** (inicialización sin ejecución)

---

## 📍 Contexto en el Plan Maestro

Según PLAN_MAESTRO.md v1.3:

- **CORE (ETAPAS 1–12)** → ✅ COMPLETO y CONGELADO
- **ETAPA 13** → ❌ NO INICIADA (antes de esta etapa)
- **ETAPA 13.1** → ✅ App Shell & Bootstrap (esta documentación)
- **ETAPA 13.2** → ⏳ PENDIENTE (Simulación - futura)
- **ETAPA 13.3** → ⏳ PENDIENTE (Hardware real - futura)

### ¿Qué es el CORE?

El CORE se refiere a los servicios y gestores existentes implementados en etapas anteriores:

- `BluetoothService` - Gestión de conexiones Bluetooth
- `WeightService` - Procesamiento de peso y filtrado
- `PersistenceService` - Almacenamiento de configuración
- `SessionHistoryService` - Gestión de sesiones de pesaje
- `AuthService` - Autenticación
- `PdfExportService` - Exportación de documentos

Estos servicios implementan toda la lógica de validación, diagnóstico, reacciones, ejecución abstracta y auditoría del sistema.

---

## ✅ Qué HACE esta Etapa

### 1. Estructura de Directorios

Crea la carpeta `lib/app/` para el App Shell:

```
lib/
├── app/                      # NUEVO: App Shell (ETAPA 13.1)
│   ├── app_root.dart        # Widget raíz MaterialApp
│   └── core_bootstrap.dart  # Bootstrap del CORE
├── main.dart                 # MODIFICADO: Punto de entrada simplificado
├── services/                 # EXISTENTE: CORE (ETAPAS 1-12)
├── models/                   # EXISTENTE: Modelos de datos
├── screens/                  # EXISTENTE: Pantallas de UI
└── ...
```

### 2. main.dart Definitivo

**Responsabilidades**:
- Inicializa Flutter (`WidgetsFlutterBinding.ensureInitialized()`)
- Configura el sistema (orientación horizontal, UI inmersiva)
- Ejecuta el bootstrap del CORE (solo instanciación)
- Lanza el AppRoot

**Lo que NO hace**:
- ❌ No contiene lógica de negocio
- ❌ No ejecuta procesos automáticamente
- ❌ No dispara eventos
- ❌ No simula escenarios

### 3. AppRoot (lib/app/app_root.dart)

**Responsabilidades**:
- Widget raíz que configura `MaterialApp`
- Define theme básico (Material 3)
- Define title de la aplicación
- Mantiene referencia al CoreBootstrap (pero NO lo usa activamente)
- Delega a la pantalla inicial existente (splash + home)

**Lo que NO hace**:
- ❌ No implementa navegación compleja
- ❌ No define rutas dinámicas
- ❌ No ejecuta flujos de usuario

### 4. CoreBootstrap (lib/app/core_bootstrap.dart)

**Responsabilidades**:
- Crea instancias de los servicios singleton existentes
- Almacena referencias para inyección de dependencias
- Proporciona acceso centralizado al CORE

**Lo que NO hace**:
- ❌ NO ejecuta métodos de negocio
- ❌ NO dispara eventos
- ❌ NO simula escenarios
- ❌ NO inicializa procesos automáticos
- ❌ Solo CREA REFERENCIAS

> **Esto es CABLEADO (wiring), no USO.**

### 5. Documentación

Crea `docs/arquitectura/ETAPA_13_1_APP_SHELL.md` (este archivo) que explica:
- Qué hace ETAPA 13.1
- Qué NO hace
- Diferencias entre CORE, App Shell y Simulación futura
- Por qué no se ejecuta nada en esta etapa

---

## ❌ Qué NO HACE esta Etapa

Esta etapa **NO**:

1. ❌ Crea validaciones nuevas
2. ❌ Crea diagnósticos nuevos
3. ❌ Ejecuta el pipeline de procesamiento
4. ❌ Simula errores o escenarios
5. ❌ Simula hardware (eso es ETAPA 13.2)
6. ❌ Crea lógica condicional nueva
7. ❌ Ejecuta reacciones
8. ❌ Registra auditoría automáticamente
9. ❌ Modifica código de ETAPAS 1–12
10. ❌ Cambia contratos existentes
11. ❌ Agrega dependencias nuevas
12. ❌ Crea servicios nuevos
13. ❌ Crea simuladores
14. ❌ Adelanta ETAPA 13.2 o 13.3

### ⚠️ Regla Estricta

> Si algo "parece útil para que la app funcione mejor", **NO** se hace en esta etapa.

---

## 🏗️ Arquitectura Implementada

### Diagrama de Capas (Post-ETAPA 13.1)

```
┌─────────────────────────────────────────────────┐
│              main.dart (Entry Point)             │
│  - Inicializa Flutter                            │
│  - Configura sistema                             │
│  - Bootstrap CORE (sin ejecutar)                 │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│         AppRoot (lib/app/app_root.dart)          │
│  - MaterialApp                                   │
│  - Theme básico                                  │
│  - Pantalla inicial                              │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│    CoreBootstrap (lib/app/core_bootstrap.dart)   │
│  - Referencias a servicios CORE                  │
│  - NO ejecuta lógica                             │
│  - Solo wiring/cableado                          │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│              CORE (ETAPAS 1-12)                  │
│  - BluetoothService                              │
│  - WeightService                                 │
│  - PersistenceService                            │
│  - SessionHistoryService                         │
│  - AuthService                                   │
│  - PdfExportService                              │
│                                                   │
│  ⚠️ CONGELADO - NO se modifica                   │
└──────────────────────────────────────────────────┘
```

### Flujo de Inicialización

```
1. main()
   ↓
2. WidgetsFlutterBinding.ensureInitialized()
   ↓
3. Configurar orientación + UI
   ↓
4. CoreBootstrap.initialize()
   │  ↓
   │  - BluetoothService() → obtiene singleton
   │  - WeightService() → obtiene singleton
   │  - PersistenceService() → obtiene singleton
   │  - SessionHistoryService() → obtiene singleton
   │  - AuthService() → obtiene singleton
   │  - PdfExportService() → obtiene singleton
   │  ↓
   │  ⚠️ IMPORTANTE: Solo obtiene referencias
   │     NO ejecuta métodos, NO dispara eventos
   ↓
5. runApp(AppRoot(coreBootstrap))
   ↓
6. AppRoot.build()
   ↓
7. MaterialApp → AppInitializer → Splash → HomeScreen
```

---

## 🔄 Diferencias Clave

### CORE (ETAPAS 1–12) vs App Shell (ETAPA 13.1)

| Aspecto | CORE (ETAPAS 1-12) | App Shell (ETAPA 13.1) |
|---------|-------------------|----------------------|
| **Propósito** | Lógica de negocio | Contenedor/estructura |
| **Ubicación** | `lib/services/`, `lib/models/` | `lib/app/`, `lib/main.dart` |
| **Responsabilidad** | Validación, procesamiento, persistencia | Inicialización, configuración UI |
| **Estado** | ✅ Completo y congelado | ✅ Completo (esta etapa) |
| **Modificable** | ❌ NO (está congelado) | ✅ SÍ (si es necesario) |
| **Ejecuta lógica** | ✅ SÍ (cuando se invoca) | ❌ NO (solo prepara) |

### App Shell (ETAPA 13.1) vs Simulación (ETAPA 13.2 - Futura)

| Aspecto | App Shell (13.1) | Simulación (13.2) |
|---------|-----------------|------------------|
| **Propósito** | Estructura base | Pruebas sin hardware |
| **Ejecuta CORE** | ❌ NO | ✅ SÍ |
| **Simula datos** | ❌ NO | ✅ SÍ |
| **Interactúa con UI** | Mínimo (splash + home) | ✅ SÍ (completo) |
| **Estado** | ✅ Completo | ⏳ Pendiente |

### App Shell (ETAPA 13.1) vs Hardware Real (ETAPA 13.3 - Futura)

| Aspecto | App Shell (13.1) | Hardware Real (13.3) |
|---------|-----------------|---------------------|
| **Propósito** | Estructura base | Operación en producción |
| **Usa Bluetooth** | ❌ NO | ✅ SÍ |
| **Datos reales** | ❌ NO | ✅ SÍ |
| **Estado** | ✅ Completo | ⏳ Pendiente |

---

## 📁 Archivos Creados y Modificados

### Archivos NUEVOS

1. **lib/app/core_bootstrap.dart**
   - Bootstrap del CORE
   - Solo instanciación de servicios
   - 60 líneas aprox.

2. **lib/app/app_root.dart**
   - Widget raíz MaterialApp
   - Configuración de theme
   - Pantalla inicial
   - 70 líneas aprox.

3. **docs/arquitectura/ETAPA_13_1_APP_SHELL.md**
   - Este documento
   - Documentación completa de la etapa

### Archivos MODIFICADOS

1. **lib/main.dart**
   - Simplificado a ~35 líneas
   - Mueve lógica de widgets a `app_root.dart`
   - Agrega bootstrap del CORE
   - Mantiene configuración del sistema

### Archivos NO MODIFICADOS

- ✅ `lib/services/*` - CORE congelado
- ✅ `lib/models/*` - Modelos existentes
- ✅ `lib/screens/*` - Pantallas existentes
- ✅ `lib/widgets/*` - Widgets existentes
- ✅ `pubspec.yaml` - Sin cambios en dependencias

---

## ✅ Criterios de Aceptación

### Completados

- [x] La app compila correctamente
- [x] Existe `main.dart` claro y simple
- [x] Existe un App Root (`lib/app/app_root.dart`)
- [x] El CORE se instancia pero NO se usa activamente
- [x] No hay lógica nueva de negocio
- [x] No se rompe arquitectura congelada (ETAPAS 1-12)
- [x] Todo el código está en español
- [x] Código mínimo y legible
- [x] Documentación completa creada

### Verificación

1. **Compilación**:
   ```bash
   flutter pub get
   flutter analyze
   flutter build apk --debug
   ```

2. **Ejecución**:
   - La app arranca correctamente
   - Muestra splash screen
   - Navega a HomeScreen
   - No hay errores en consola

3. **Arquitectura**:
   - CORE (servicios) no modificado
   - Separación clara entre App Shell y CORE
   - Bootstrap solo instancia, no ejecuta

---

## 🔚 Resultado Esperado

Una aplicación Flutter que:

- ✅ Arranca correctamente
- ✅ Muestra pantalla base (splash + home)
- ✅ Tiene el CORE inyectado pero "dormido"
- ✅ Está lista para que ETAPA 13.2 agregue simulación
- ✅ Mantiene toda la funcionalidad existente

### Características Post-ETAPA 13.1

- **Estructura organizada**: Separación clara entre app shell y CORE
- **CORE intacto**: Servicios existentes no modificados
- **Sin ejecución automática**: Bootstrap solo instancia, no ejecuta
- **Documentación completa**: Este documento explica todo
- **Preparada para simulación**: ETAPA 13.2 podrá agregar simuladores fácilmente

---

## 🚀 Próximos Pasos

### ETAPA 13.2 - Simulación (PENDIENTE)

Cuando se implemente ETAPA 13.2, podrá:

1. Crear simuladores de hardware
2. Generar datos de prueba
3. Simular errores y escenarios
4. Probar el CORE sin hardware real
5. Usar `CoreBootstrap` para inyectar simuladores

### ETAPA 13.3 - Hardware Real (PENDIENTE)

Cuando se implemente ETAPA 13.3, podrá:

1. Habilitar Bluetooth real
2. Conectar a balanza física
3. Procesar datos reales
4. Operar en producción

---

## 📝 Notas Importantes

### ¿Por qué no se ejecuta nada en esta etapa?

Porque el objetivo es **preparar** el terreno, no **usar** el terreno. Las razones son:

1. **Separación de responsabilidades**: App Shell ≠ CORE
2. **Arquitectura limpia**: Wiring sin ejecución
3. **Preparación para simulación**: ETAPA 13.2 decidirá qué ejecutar
4. **Mantenibilidad**: Código claro y enfocado

### ¿Qué pasa con la funcionalidad existente?

**Nada**. La aplicación mantiene toda su funcionalidad:

- Splash screen funciona igual
- HomeScreen funciona igual
- Todos los servicios funcionan igual
- Solo se reorganiza el código de inicialización

### ¿Se puede usar la app ahora?

**SÍ**. La aplicación es completamente funcional. Esta etapa solo reorganiza la estructura de inicialización sin cambiar el comportamiento.

---

## 🎓 Resumen para Desarrolladores

### Lo que debes saber

1. **CORE = Servicios existentes** (`lib/services/`)
2. **App Shell = Estructura Flutter** (`lib/app/`, `lib/main.dart`)
3. **Bootstrap = Wiring sin ejecución** (`CoreBootstrap`)

### Lo que NO debes hacer

1. ❌ NO modificar servicios del CORE
2. ❌ NO agregar lógica a `core_bootstrap.dart`
3. ❌ NO ejecutar métodos en el bootstrap
4. ❌ NO simular datos (eso es ETAPA 13.2)

### Lo que SÍ puedes hacer

1. ✅ Usar `CoreBootstrap` para obtener referencias a servicios
2. ✅ Modificar `AppRoot` si es necesario
3. ✅ Agregar configuración de UI
4. ✅ Prepararte para ETAPA 13.2

---

**Fin de la Documentación ETAPA 13.1**

📌 Esta etapa **prepara**  
📌 No **ejecuta**  
📌 No **decide**  
📌 No **simula**

**Estado**: ✅ COMPLETADO  
**Fecha**: 8 de febrero de 2026  
**Versión**: 1.0
