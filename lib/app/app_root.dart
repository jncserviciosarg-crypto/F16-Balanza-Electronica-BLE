/// ETAPA 13.1 - App Root (Contenedor)
/// 
/// Widget raíz de la aplicación Flutter que actúa como CONTENEDOR
/// del CORE ya implementado.
/// 
/// ⚠️ REGLAS ESTRICTAS:
/// - NO agrega comportamiento nuevo
/// - NO modifica el pipeline lógico
/// - NO ejecuta acciones reales
/// - Solo proporciona la estructura base de la app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core_bootstrap.dart';
import '../screens/home_screen.dart';
import '../screens/f16_splash_screen.dart';

/// Widget raíz de la aplicación
/// 
/// Configura MaterialApp con theme básico y pantalla inicial.
/// Mantiene la referencia al CoreBootstrap pero NO lo usa activamente.
/// 
/// NOTA: La configuración de SystemChrome (orientación, UI) proviene
/// del código original de la app, NO es parte de ETAPA 13.1.
class AppRoot extends StatefulWidget {
  final CoreBootstrap coreBootstrap;

  const AppRoot({
    super.key,
    required this.coreBootstrap,
  });

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    
    // Configuración del sistema (código original de la app)
    // Forzar orientación horizontal
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Ocultar barra de estado
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F16 Balanza Electrónica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const AppInitializer(),
    );
  }
}

/// Widget inicial que muestra la pantalla F-16 BIT solo durante el arranque
/// y luego delega a la pantalla principal (HomeScreen).
/// 
/// Este widget mantiene la funcionalidad existente de la app.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _showSplash = true;

  void _onSplashComplete() {
    if (!mounted) return;
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mientras _showSplash == true mostramos la pantalla BIT; al terminar
    // mostramos la HomeScreen original. No se realiza navegación automática
    // desde dentro del splash para mantener la separación de responsabilidades.
    return _showSplash
        ? F16SplashScreen(onComplete: _onSplashComplete)
        : const HomeScreen();
  }
}
