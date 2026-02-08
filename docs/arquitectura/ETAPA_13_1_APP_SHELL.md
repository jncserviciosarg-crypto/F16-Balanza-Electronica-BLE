# ETAPA 13.1 — App Shell & Bootstrap de la Aplicación

**Fecha**: 8 de febrero de 2026  
**Estado**: ✅ IMPLEMENTADO (Alcance Corregido)
**Versión**: 2.0

---

## 📋 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Contexto en el Plan Maestro](#contexto-en-el-plan-maestro)
3. [Qué es el CORE (ETAPAS 1-12)](#qué-es-el-core-etapas-1-12)
4. [Qué HACE esta Etapa](#qué-hace-esta-etapa)
5. [Qué NO HACE esta Etapa](#qué-no-hace-esta-etapa)
6. [Arquitectura Implementada](#arquitectura-implementada)
7. [Diferencias Clave](#diferencias-clave)
8. [Archivos Creados y Modificados](#archivos-creados-y-modificados)
9. [Próximos Pasos](#próximos-pasos)

---

## 🎯 Resumen Ejecutivo

La **ETAPA 13.1** implementa la estructura base (contenedor) de la aplicación Flutter que está **PREPARADA** para recibir el CORE cuando sea implementado en futuras etapas.

### Propósito

> 🧱 "Crear el contenedor vacío donde vivirá el CORE cuando sea construido"

Esta etapa:
- ✅ Crea la estructura organizativa (`lib/app/`)
- ✅ Prepara el bootstrap para recibir gestores del CORE
- ✅ Mantiene la app funcional sin cambios de comportamiento
- ❌ NO instancia servicios existentes (no son parte del CORE)
- ❌ NO modifica configuración del sistema dentro del bootstrap
- ❌ NO ejecuta ninguna lógica

---

## 📍 Contexto en el Plan Maestro

Según PLAN_MAESTRO.md v1.3:

- **CORE (ETAPAS 1–12)** → ⏳ PENDIENTE (gestores aún no implementados)
- **ETAPA 13** → 🔄 EN PROGRESO
- **ETAPA 13.1** → ✅ App Shell & Bootstrap (esta documentación)
- **ETAPA 13.2** → ⏳ PENDIENTE (Simulación - futura)
- **ETAPA 13.3** → ⏳ PENDIENTE (Hardware real - futura)

---

## ❓ Qué es el CORE (ETAPAS 1-12)

El CORE se refiere EXCLUSIVAMENTE a los **gestores/managers** que implementan la lógica de negocio principal:

### Gestores del CORE
1. **Validaciones** - Valida entradas y estados
2. **Diagnóstico** - Detecta problemas y anomalías
3. **Reacciones** - Define respuestas a eventos
4. **Ejecución abstracta** - Orquesta el pipeline lógico
5. **Auditoría** - Registra operaciones y eventos

### ⚠️ QUÉ NO ES EL CORE

Los siguientes servicios existentes **NO** son parte del CORE (ETAPAS 1-12):

- ❌ `BluetoothService` - Capa de infraestructura
- ❌ `WeightService` - Capa de aplicación
- ❌ `PersistenceService` - Capa de infraestructura
- ❌ `SessionHistoryService` - Capa de aplicación
- ❌ `AuthService` - Capa de aplicación
- ❌ `PdfExportService` - Capa de infraestructura

Estos servicios son **implementaciones existentes** que serán **usadas** por el CORE, pero **NO son el CORE**.

---

## ✅ Qué HACE esta Etapa

### 1. Estructura de Directorios

Crea la carpeta `lib/app/` para el App Shell:

```
lib/
├── app/                      # NUEVO: App Shell (ETAPA 13.1)
│   ├── app_root.dart        # Widget raíz MaterialApp
│   └── core_bootstrap.dart  # Bootstrap del CORE (contenedor vacío)
├── main.dart                 # MODIFICADO: Punto de entrada neutral
├── services/                 # EXISTENTE: Servicios de infraestructura
├── models/                   # EXISTENTE: Modelos de datos
├── screens/                  # EXISTENTE: Pantallas de UI
└── ...
```

### 2. main.dart - Punto de Entrada Neutral

**Responsabilidades**:
- Inicializa Flutter (`WidgetsFlutterBinding.ensureInitialized()`)
- Ejecuta el bootstrap del CORE (crea contenedor vacío)
- Lanza el AppRoot

**Lo que NO hace**:
- ❌ No configura SystemChrome (eso está en AppRoot, código original)
- ❌ No contiene lógica de negocio
- ❌ No instancia servicios

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final coreBootstrap = CoreBootstrap.initialize();
  runApp(AppRoot(coreBootstrap: coreBootstrap));
}
```

### 3. CoreBootstrap - Contenedor Vacío del CORE

**Responsabilidades**:
- Provee estructura para recibir gestores del CORE
- Está preparado para inyección de dependencias
- NO instancia nada por ahora

**Gestores que recibirá (futuro)**:
- Validaciones (cuando se implemente)
- Diagnóstico (cuando se implemente)
- Reacciones (cuando se implemente)
- Ejecución abstracta (cuando se implemente)
- Auditoría (cuando se implemente)

```dart
class CoreBootstrap {
  // Aquí se agregarán referencias a los gestores del CORE
  // cuando sean implementados
  
  CoreBootstrap._();
  
  static CoreBootstrap initialize() {
    final bootstrap = CoreBootstrap._();
    // El bootstrap está listo para recibir los gestores del CORE
    // Por ahora, no hay gestores que instanciar
    return bootstrap;
  }
}
```

### 4. AppRoot - Widget Raíz

**Responsabilidades**:
- Configura MaterialApp con theme Material 3
- Mantiene funcionalidad existente de la app (splash + home)
- Mantiene configuración de SystemChrome del código original
- Recibe CoreBootstrap pero NO lo usa activamente

**Nota importante**: La configuración de SystemChrome (orientación, UI) proviene del **código original de la app**, NO es parte de ETAPA 13.1.

---

## ❌ Qué NO HACE esta Etapa

### Restricciones Cumplidas

Esta implementación **NO** hace:

1. ❌ NO instancia `BluetoothService`, `WeightService`, etc. (no son parte del CORE)
2. ❌ NO crea validaciones nuevas
3. ❌ NO crea diagnósticos nuevos
4. ❌ NO ejecuta el pipeline
5. ❌ NO simula errores o hardware
6. ❌ NO crea lógica condicional nueva
7. ❌ NO ejecuta reacciones
8. ❌ NO registra auditoría automáticamente
9. ❌ NO modifica comportamiento del sistema desde el bootstrap
10. ❌ NO agrega dependencias
11. ❌ NO adelanta ETAPA 13.2 o 13.3

### ⚠️ Correcciones Aplicadas

Versión 2.0 corrige el alcance para:
- ✅ NO instanciar servicios existentes en el bootstrap
- ✅ NO modificar SystemChrome desde el bootstrap de ETAPA 13.1
- ✅ Preparar contenedor vacío para gestores del CORE (aún no implementados)

---

## 🏗️ Arquitectura Implementada

### Diagrama de Capas

```
┌─────────────────────────────────────────────────┐
│         main.dart (Entry Point - Neutral)        │
│  - Inicializa Flutter                            │
│  - Bootstrap CORE (contenedor vacío)             │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│       AppRoot (lib/app/app_root.dart)            │
│  - MaterialApp                                   │
│  - Theme Material 3                              │
│  - Configuración SystemChrome (código original)  │
│  - Splash + Home (funcionalidad existente)       │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│  CoreBootstrap (lib/app/core_bootstrap.dart)     │
│  - Contenedor vacío para gestores del CORE      │
│  - NO instancia servicios                        │
│  - Preparado para recibir:                       │
│    * Validaciones (futuro)                       │
│    * Diagnóstico (futuro)                        │
│    * Reacciones (futuro)                         │
│    * Ejecución abstracta (futuro)                │
│    * Auditoría (futuro)                          │
└──────────────────────────────────────────────────┘
```

### Flujo de Inicialización

```
1. main()
2. WidgetsFlutterBinding.ensureInitialized()
3. CoreBootstrap.initialize() → crea contenedor vacío
4. runApp(AppRoot(...))
5. AppRoot inicializa SystemChrome (código original)
6. MaterialApp
7. AppInitializer
8. F16SplashScreen
9. HomeScreen
```

---

## 🔄 Diferencias Clave

### CORE (ETAPAS 1-12) vs Servicios Existentes

| Aspecto | CORE (ETAPAS 1-12) | Servicios Existentes |
|---------|-------------------|---------------------|
| **Qué son** | Gestores de lógica de negocio | Capa de infraestructura/aplicación |
| **Componentes** | Validaciones, Diagnóstico, Reacciones, Ejecución, Auditoría | Bluetooth, Weight, Persistence, etc. |
| **Estado** | ⏳ Pendiente (no implementados) | ✅ Implementados |
| **Ubicación** | `lib/core/` (futuro) | `lib/services/` (existente) |
| **Bootstrap** | ✅ Sí (cuando existan) | ❌ No (no son parte del CORE) |

### App Shell (ETAPA 13.1) vs Simulación (ETAPA 13.2)

| Aspecto | App Shell (13.1) | Simulación (13.2) |
|---------|-----------------|------------------|
| **Propósito** | Estructura contenedora | Pruebas sin hardware |
| **CORE** | Contenedor vacío | Usará gestores del CORE |
| **Servicios** | No los usa | Simulará servicios |
| **Estado** | ✅ Implementado | ⏳ Pendiente |

---

## 📁 Archivos Creados y Modificados

### Archivos NUEVOS

1. **lib/app/core_bootstrap.dart** (30 líneas aprox.)
   - Contenedor vacío para gestores del CORE
   - Preparado para recibir: Validaciones, Diagnóstico, Reacciones, Ejecución, Auditoría
   - NO instancia servicios existentes

2. **lib/app/app_root.dart** (95 líneas aprox.)
   - Widget raíz MaterialApp
   - Mantiene configuración SystemChrome del código original
   - Funcionalidad splash + home existente

3. **docs/arquitectura/ETAPA_13_1_APP_SHELL.md**
   - Esta documentación (versión 2.0 corregida)

### Archivos MODIFICADOS

1. **lib/main.dart**
   - Simplificado a ~25 líneas
   - Removida configuración SystemChrome (movida a AppRoot)
   - Agregado bootstrap del CORE (contenedor vacío)

### Archivos NO MODIFICADOS

- ✅ `lib/services/*` - Servicios existentes intactos
- ✅ `lib/models/*` - Modelos existentes
- ✅ `lib/screens/*` - Pantallas existentes
- ✅ `lib/widgets/*` - Widgets existentes
- ✅ `pubspec.yaml` - Sin cambios en dependencias

---

## 🚀 Próximos Pasos

### Implementación de CORE (Etapas futuras)

Cuando se implemente el CORE (ETAPAS 1-12), se agregarán los gestores:

```dart
class CoreBootstrap {
  late final ValidacionesManager validaciones;
  late final DiagnosticoManager diagnostico;
  late final ReaccionesManager reacciones;
  late final EjecucionManager ejecucion;
  late final AuditoriaManager auditoria;
  
  static CoreBootstrap initialize() {
    final bootstrap = CoreBootstrap._();
    bootstrap.validaciones = ValidacionesManager();
    bootstrap.diagnostico = DiagnosticoManager();
    // ... etc
    return bootstrap;
  }
}
```

### ETAPA 13.2 - Simulación (PENDIENTE)

Cuando se implemente ETAPA 13.2:
- Creará simuladores para probar el CORE
- Generará datos de prueba
- Simulará errores y escenarios
- Usará los gestores del CORE

### ETAPA 13.3 - Hardware Real (PENDIENTE)

Cuando se implemente ETAPA 13.3:
- Habilitará hardware real
- Conectará a balanza física
- Procesará datos reales
- Ejecutará el CORE en producción

---

## �� Resumen

### Estado Actual

- ✅ Estructura de App Shell creada (`lib/app/`)
- ✅ Bootstrap del CORE preparado (contenedor vacío)
- ✅ App funcional sin cambios de comportamiento
- ✅ Documentación corregida (v2.0)

### Alcance Corregido

Esta etapa **prepara** el contenedor para el CORE, **NO** instancia servicios existentes.

> 📌 Prepara el terreno
> 📌 No ejecuta nada
> 📌 No instancia servicios
> 📌 No modifica comportamiento del sistema desde el bootstrap

El CORE (gestores) será implementado en etapas futuras. Cuando exista, el bootstrap lo recibirá sin ejecutar ninguna lógica.

---

**Versión**: 2.0 (Alcance Corregido)
**Fecha**: 8 de febrero de 2026  
**Estado**: ✅ IMPLEMENTADO según alcance de ETAPA 13.1
