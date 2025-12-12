import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/f16_splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación horizontal
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Ocultar barra de estado
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const BalanzaApp());
}

class BalanzaApp extends StatelessWidget {
  const BalanzaApp({Key? key}) : super(key: key);

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
/// y luego delega a la pantalla principal (`HomeScreen`). Está diseñado para
/// ser mínimo y no tocar ninguna otra lógica de la aplicación.
class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

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
