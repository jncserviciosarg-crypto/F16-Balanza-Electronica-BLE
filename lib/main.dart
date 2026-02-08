/// ETAPA 13.1 - Punto de Entrada de la Aplicación
/// 
/// Este archivo es el punto de entrada definitivo de la app Flutter.
/// Su única responsabilidad es:
/// 1. Inicializar Flutter
/// 2. Configurar el sistema (orientación, UI)
/// 3. Bootstrap del CORE (solo instanciación)
/// 4. Lanzar el AppRoot
/// 
/// ⚠️ NO contiene lógica de negocio
/// ⚠️ NO ejecuta procesos automáticamente
/// ⚠️ Solo prepara el terreno

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_root.dart';
import 'app/core_bootstrap.dart';

void main() {
  // Inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación horizontal (requerimiento industrial)
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Ocultar barra de estado (modo inmersivo)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Bootstrap del CORE (ETAPAS 1-12)
  // ⚠️ Solo instancia servicios, NO los ejecuta
  final coreBootstrap = CoreBootstrap.initialize();

  // Lanzar la aplicación con el App Root
  runApp(AppRoot(coreBootstrap: coreBootstrap));
}
