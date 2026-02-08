/// ETAPA 13.1 - Punto de Entrada de la Aplicación
/// 
/// Este archivo es el punto de entrada definitivo de la app Flutter.
/// Su única responsabilidad es:
/// 1. Inicializar Flutter
/// 2. Bootstrap del CORE (solo preparar contenedor)
/// 3. Lanzar el AppRoot
/// 
/// ⚠️ NO contiene lógica de negocio
/// ⚠️ NO ejecuta procesos automáticamente
/// ⚠️ NO modifica configuración del sistema
/// ⚠️ Solo prepara el terreno

import 'package:flutter/material.dart';
import 'app/app_root.dart';
import 'app/core_bootstrap.dart';

void main() {
  // Inicializar Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap del CORE (ETAPAS 1-12)
  // ⚠️ Solo prepara el contenedor, NO instancia servicios
  final coreBootstrap = CoreBootstrap.initialize();

  // Lanzar la aplicación con el App Root
  runApp(AppRoot(coreBootstrap: coreBootstrap));
}
