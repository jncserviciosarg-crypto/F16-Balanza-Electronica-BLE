# Fork de flutter_bluetooth_serial

## Propósito

Este directorio contiene (o contendrá) un fork local o parcheado de `flutter_bluetooth_serial` para compatibilidad con:
- Android API 34-36
- Flutter 3.38+
- Kotlin 2.2+

## Estado Actual

- **v0.4.0**: Versión original sin cambios (se usa desde pub.dev)
- **Próxima versión**: Fork local si se necesitan parches urgentes

## Cómo Usar

### Opción 1: Git Dependency (Repositorio remoto)

Si se crea un fork en GitHub, editar `pubspec.yaml`:

```yaml
dependencies:
  flutter_bluetooth_serial:
    git:
      url: https://github.com/tu-usuario/flutter_bluetooth_serial.git
      ref: android-api34-36-compat
```

### Opción 2: Path Dependency (Desarrollo local)

Para desarrollo local, descargar el fork aquí y editar `pubspec.yaml`:

```yaml
dependencies:
  flutter_bluetooth_serial:
    path: ./third_party/flutter_bluetooth_serial_fork
```

### Opción 3: Mantener pub.dev

Por ahora (STAGE 2), se mantiene la versión v0.4.0 desde pub.dev.
La migración a `flutter_blue_plus` está preparada en `lib/services/bluetooth_adapter.dart`.

## Migraciones Futuras

1. **STAGE 3**: Crear fork de flutter_bluetooth_serial con parches para API 34+
2. **STAGE 4**: Migrar a `flutter_blue_plus` gradualmente
3. **STAGE 5**: Eliminar flutter_bluetooth_serial

## Referencias

- Paquete original: https://pub.dev/packages/flutter_bluetooth_serial
- Fork sugerido: https://github.com/RoyalJames/flutter_bluetooth_serial
- Alternativa moderna: https://pub.dev/packages/flutter_blue_plus

## Notas de Desarrollo

- No modificar `bluetooth_service.dart` hasta que se decida la estrategia
- El adaptador `bluetooth_adapter.dart` permite cambios sin romper código existente
- Mantener backups del estado actual en `android/app/src/main/AndroidManifest.xml.bak`
