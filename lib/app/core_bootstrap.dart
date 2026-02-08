/// ETAPA 13.1 - Bootstrap del CORE
/// 
/// Este archivo es responsable únicamente de INSTANCIAR los gestores/servicios
/// del CORE (ETAPAS 1-12) que ya existen en el proyecto.
/// 
/// ⚠️ REGLAS ESTRICTAS:
/// - NO ejecuta métodos de negocio
/// - NO dispara eventos
/// - NO simula escenarios
/// - NO inicializa procesos automáticos
/// - Solo CREA REFERENCIAS para inyección de dependencias
/// 
/// Esto es CABLEADO (wiring), no USO.

import '../services/bluetooth_service.dart';
import '../services/weight_service.dart';
import '../services/persistence_service.dart';
import '../services/session_history_service.dart';
import '../services/auth_service.dart';
import '../services/pdf_export_service.dart';

/// Contenedor de los servicios del CORE
/// 
/// Esta clase solo almacena referencias a los servicios singleton
/// que ya existen en el proyecto. No ejecuta ninguna lógica.
class CoreBootstrap {
  // Instancias de los servicios del CORE (ETAPAS 1-12)
  // Estos servicios ya están implementados como singletons
  late final BluetoothService bluetoothService;
  late final WeightService weightService;
  late final PersistenceService persistenceService;
  late final SessionHistoryService sessionHistoryService;
  late final AuthService authService;
  late final PdfExportService pdfExportService;

  CoreBootstrap._();

  /// Inicializa las referencias a los servicios del CORE
  /// 
  /// ⚠️ IMPORTANTE: Solo obtiene las instancias singleton.
  /// NO ejecuta ningún método de inicialización.
  /// NO dispara ningún evento.
  /// NO realiza ninguna operación.
  static CoreBootstrap initialize() {
    final bootstrap = CoreBootstrap._();
    
    // Obtener referencias a los servicios singleton existentes
    // Esto solo invoca los factory constructors, no ejecuta lógica
    bootstrap.bluetoothService = BluetoothService();
    bootstrap.weightService = WeightService();
    bootstrap.persistenceService = PersistenceService();
    bootstrap.sessionHistoryService = SessionHistoryService();
    bootstrap.authService = AuthService();
    bootstrap.pdfExportService = PdfExportService();

    return bootstrap;
  }
}
