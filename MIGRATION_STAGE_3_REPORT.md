# MIGRATION STAGE 3 REPORT - Bluetooth (Refactor Controlado)

Fecha: 8 de diciembre de 2025
Rama: `migration/stage-2-prepare` (continuación)

Resumen rápido:
- Objetivo: preparar un fork local y refactorizar `bluetooth_service.dart` para usar
  el `BluetoothAdapter` sin cambiar la lógica ni reemplazar `flutter_bluetooth_serial`.
- Resultado: se aplicaron cambios de preparación (comentario en `pubspec.yaml`,
  creación de `PATCH_NOTES.md`), se intentó un refactor pero se revirtió porque la
  compilación en dispositivo falló por ausencia del paquete `flutter_bluetooth_serial`
  en el cache local de pub.

Pasos ejecutados:

1) Intento de crear fork local
   - Se intentó copiar automáticamente el paquete desde el cache de pub.
   - No se encontró `flutter_bluetooth_serial-0.4.0` en el cache local; se dejó el
     directorio `third_party/flutter_bluetooth_serial_fork/` con documentación
     (`README.md` existente y `PATCH_NOTES.md` agregado).

2) `pubspec.yaml`
   - Se añadió (comentada) la entrada:
     ```yaml
     # flutter_bluetooth_serial:
     #   path: third_party/flutter_bluetooth_serial_fork
     ```
   - Commit: `docs: preparar dependencia local comentada para futuro swap`

3) Refactor temporal en `bluetooth_service.dart`
   - Se implementó un cambio para delegar llamadas a un `BluetoothAdapter`.
   - Commit realizado: `refactor: usar BluetoothAdapter en bluetooth_service`.

4) Validación y problema encontrado
   - `flutter pub get` y `flutter analyze` OK (solo warnings/infos).
   - Al ejecutar `flutter run` en dispositivo Android (API 36) la build falló con
     errores de compilación: el paquete `flutter_bluetooth_serial` no estaba
     disponible en el cache de pub (faltaban archivos en `.../flutter_bluetooth_serial-0.4.0/lib/...`).
   - Debido a este error de build se REVERTIÓ el commit del refactor para no dejar
     el proyecto en un estado roto.

5) Reversiones y estado actual
   - Commit de revert creado: revirtió el cambio de `bluetooth_service.dart`.
   - Estado actual: la app compila y analiza como antes de este intento (solo
     warnings/infos habituales). El adaptador `lib/services/bluetooth_adapter.dart`
     y el archivo demo todavía existen en el repo (no se integran en runtime).

Checklist de funcionalidad Bluetooth (STAGE 3):
- [ ] Copiar paquete `flutter_bluetooth_serial-0.4.0` al fork local (third_party)
- [ ] O ejecutar `flutter pub cache repair` para restaurar el paquete en el cache
- [ ] Reaplicar el refactor y compilar en dispositivo
- [ ] Probar: listar dispositivos emparejados, conectar, recibir datos, desconectar

Recomendaciones y siguientes pasos (acción requerida antes de reintentar):
1. Restaurar `flutter_bluetooth_serial` en el cache local: ejecutar
   `flutter pub cache repair` o copiar manualmente el paquete desde otra máquina.
2. Alternativamente, copiar la versión completa del paquete en
   `third_party/flutter_bluetooth_serial_fork/` y descomentar la dependencia en
   `pubspec.yaml` (la línea añadida está comentada) para usar la copia local.
3. Reaplicar el refactor en `bluetooth_service.dart` y ejecutar pruebas en un
   dispositivo Android con API 34-36.

Notas finales:
- Se respetaron las restricciones: no se actualizó ni reemplazó `flutter_bluetooth_serial`.
- Se mantuvo la lógica original; el revert sucedió por un problema de entorno
  (paquete faltante), no por la refactorización en sí.
