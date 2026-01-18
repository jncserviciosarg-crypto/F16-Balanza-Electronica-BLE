# F16 Balanza Electrónica

**Aplicación Flutter** para lectura de peso en tiempo real vía Bluetooth con calibración y filtrado avanzado.

## � Información Rápida

| Campo | Valor |
|-------|-------|
| **Versión** | **2.0.0** |
| **Estado** | ✅ **ESTABLE / PRODUCCIÓN** |
| **SDK Flutter** | ^3.0.0 |
| **API Android** | Min: 31 (Android 12), Target: 36 (Android 16) |
| **Última Actualización** | 18 de enero de 2026 |

---

## 🎯 Propósito del Proyecto

F16 es una **solución industrial completa** para pesaje electrónico mediante Bluetooth. La aplicación ha sido validada en campo y se encuentra en **producción operativa**.

### Funcionalidades Principales
- ✅ Lectura de peso en tiempo real vía Bluetooth
- ✅ Calibración bidireccional con validación de estabilidad
- ✅ Filtrado avanzado (EMA, trim, media móvil)
- ✅ Sesiones de pesaje profesional con exportación PDF
- ✅ Visualización gráfica de historial
- ✅ Configuración avanzada de parámetros
- ✅ Reconexión automática ante desconexiones
- ✅ Interfaz optimizada para modo landscape (industrial)

---

## 📖 Documentación Disponible

La documentación está organizada en tres archivos complementarios:

### 1. **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** — Descripción Técnica Completa
Contiene:
- Descripción funcional detallada
- Arquitectura general y patrones implementados
- Máquina de estados Bluetooth
- Descripción de las 6 pantallas
- Historial completo de etapas (F1 → F2.2 → Migración → v2.0.0)
- Decisiones técnicas fundamentales
- Cambios recientes (Migración BLE, reconexión automática)
- Mejoras futuras sugeridas

### 2. **[PROJECT_MAINTENANCE.md](PROJECT_MAINTENANCE.md)** — Operación y Mantenimiento
Contiene:
- Instrucciones de compilación (APK debug/release)
- Generación de launcher icons
- Información sobre el sistema Bluetooth
- Gestión de permisos Android 12+
- Generación de PDF/Excel
- Comandos de análisis y limpieza
- Reglas críticas de mantenimiento

---

## ⚠️ Estado del Código

**LA LÓGICA BLE Y DE NEGOCIO HA SIDO VALIDADA EN CAMPO Y SE ENCUENTRA OPERATIVA.**

### Garantías de Estabilidad
- ✅ Sistema probado en entornos de producción real
- ✅ Reconexión automática funcionando correctamente
- ✅ Manejo de desconexiones sin pérdida de datos
- ✅ Permisos Android 12+ completamente implementados
- ✅ Cero memory leaks detectados
- ✅ Performance optimizado para uso industrial prolongado

---

## 🚀 Inicio Rápido

```bash
# 1. Clonar y configurar
git clone https://github.com/jncserviciosarg-crypto/F16-Balanza-Electronica-BLE.git
cd F16-Balanza-Electronica-BLE
flutter pub get

# 2. Compilar APK release
flutter build apk --release

# 3. Instalar en dispositivo
adb install build/app/outputs/apk/release/app-release.apk
```

Para más detalles, consulta **[PROJECT_MAINTENANCE.md](PROJECT_MAINTENANCE.md)**.

---

## 📁 Estructura Base

```
lib/
├── main.dart                    # Punto entrada
├── screens/                     # 6 pantallas de UI
├── services/                    # Singletons (Bluetooth, Weight, Persistence)
├── models/                      # Clases de datos
├── widgets/                     # Componentes reutilizables
├── utils/                       # Constantes y helpers
└── mixins/                      # Lógica compartida
```

Para descripción completa, ver **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md#guía-de-inicio-rápido)**.

---

## 🔗 Enlaces Útiles

- **Problemas frecuentes**: [PROJECT_MAINTENANCE.md](PROJECT_MAINTENANCE.md#posibles-errores-comunes)
- **Debugging**: [PROJECT_MAINTENANCE.md](PROJECT_MAINTENANCE.md#debugging)
- **Mejoras futuras**: [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md#-mejoras-futuras-sugeridas)

---

**Versión Estable**: 2.0.0  
**Checkpoint**: 18 de enero de 2026  
**Licencia**: MIT
