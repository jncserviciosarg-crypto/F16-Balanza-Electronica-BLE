# Project Maintenance

## Build

- Flutter SDK required (stable channel recommended).
- To build debug APK:

```powershell
flutter pub get
flutter build apk --debug
```

- To build release APK (signed):

```powershell
flutter build apk --release
```

## Generate launcher icons

Configured with `flutter_launcher_icons`.

```powershell
# After placing icon in assets/appstore.png
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## How Bluetooth works (high level)

- The app uses an adapter pattern (`BluetoothAdapter`) that abstracts `flutter_bluetooth_serial`.
- `BluetoothService` handles connection lifecycle, reading input stream and parsing ADC values.
- The plugin `third_party/flutter_bluetooth_serial_fork` provides the native bridge.

> Note: Do not change plugin core logic without QA.

## PDF / Excel generation

- PDFs are generated using `package:pdf` and `printing`.
- Excel exports use `package:excel`.
- Exports are created in temporary directory and returned as file paths.

## Permissions

Android runtime permissions required (depending on API level):
- `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` (Android 12+)
- For older Android versions: `BLUETOOTH`, `ACCESS_FINE_LOCATION` (if required by plugin)

Only request permissions at runtime where needed; avoid requesting unnecessary permissions.

## Cleaning and analysis

- Run analyzer:

```powershell
flutter analyze
```

- To apply safe Dart automated fixes (review before applying):

```powershell
dart fix --dry-run
# Review suggested fixes
dart fix --apply
```

## Notes

- Avoid modifying `third_party/flutter_bluetooth_serial_fork` core logic unless intended.
- Keep `flutter_launcher_icons` in `dev_dependencies` for reproducibility.

