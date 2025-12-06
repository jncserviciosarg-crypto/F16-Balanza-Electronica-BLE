# F16 Balanza Electrónica

Este es un proyecto de aplicación Flutter llamado "F16 Balanza Electrónica". La aplicación está diseñada para interactuar con una balanza electrónica, mostrando el peso actual y permitiendo configuraciones a través de una interfaz de usuario amigable.

## Estructura del Proyecto

El proyecto tiene la siguiente estructura de directorios:

```
F16-Balanza-Electronica
├── android                # Código específico para Android
├── ios                    # Código específico para iOS
├── lib                    # Código fuente de la aplicación
│   ├── main.dart          # Punto de entrada de la aplicación
│   ├── app.dart           # Configuración de la aplicación
│   ├── src                # Contiene la lógica de la aplicación
│   │   ├── screens        # Pantallas de la aplicación
│   │   │   ├── home_screen.dart       # Pantalla principal
│   │   │   └── settings_screen.dart    # Pantalla de configuración
│   │   ├── widgets        # Widgets reutilizables
│   │   │   ├── balance_display.dart     # Widget para mostrar el peso
│   │   │   └── keypad.dart              # Widget para el teclado numérico
│   │   ├── models         # Modelos de datos
│   │   │   └── measurement.dart          # Modelo de medición
│   │   ├── services       # Servicios de la aplicación
│   │   │   └── bluetooth_service.dart    # Lógica de conexión Bluetooth
│   │   └── utils          # Utilidades y constantes
│   │       └── constants.dart            # Constantes de la aplicación
├── test                   # Pruebas unitarias
│   └── widget_test.dart   # Pruebas para los widgets
├── assets                 # Recursos de la aplicación
│   ├── fonts              # Fuentes personalizadas
│   └── translations       # Archivos de traducción
├── pubspec.yaml           # Configuración del proyecto Flutter
├── analysis_options.yaml   # Configuraciones de análisis de código
├── .gitignore             # Archivos a ignorar por el control de versiones
└── README.md              # Documentación del proyecto
```

## Instalación

Para instalar y ejecutar la aplicación, sigue estos pasos:

1. Clona el repositorio en tu máquina local.
2. Navega al directorio del proyecto.
3. Ejecuta `flutter pub get` para instalar las dependencias.
4. Conecta tu dispositivo o inicia un emulador.
5. Ejecuta `flutter run` para iniciar la aplicación.

## Uso

La aplicación permite a los usuarios:

- Ver el peso actual medido por la balanza.
- Ajustar configuraciones a través de la pantalla de configuración.
- Interactuar con la balanza electrónica mediante conexión Bluetooth.

## Contribuciones

Las contribuciones son bienvenidas. Si deseas contribuir, por favor abre un issue o envía un pull request.

## Licencia

Este proyecto está bajo la Licencia MIT. Para más detalles, consulta el archivo LICENSE.