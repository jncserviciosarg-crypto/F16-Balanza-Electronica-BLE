/// Utilidad genérica para capturar y gestionar screenshots de widgets.
///
/// Uso básico:
/// 1. Definir un GlobalKey: `final _shotKey = GlobalKey();`
/// 2. Envolver el contenido a capturar:
///    ```dart
///    RepaintBoundary(
///      key: _shotKey,
///      child: ... // contenido existente
///    )
///    ```
/// 3. Capturar:
///    ```dart
///    final bytes = await ScreenshotHelper.captureWidget(_shotKey);
///    if (bytes != null) {
///      final path = await ScreenshotHelper.saveTempPng(bytes);
///      // Opcional: await ScreenshotHelper.sharePng(bytes);
///    }
///    ```
///
/// No depende de providers ni lógica de negocio. Puede usarse desde cualquier pantalla.
///
/// TODO: Evaluar creación futura de `ScreenshotButton` o mixin `WithScreenshot` para evitar repetición.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ScreenshotHelper {
  /// Captura el contenido de un widget envuelto en un `RepaintBoundary`.
  ///
  /// [boundaryKey] debe ser el GlobalKey asociado al RepaintBoundary.
  /// [pixelRatio] permite incrementar la resolución del PNG (por defecto 3.0).
  /// Retorna los bytes PNG o null si falla.
  static Future<Uint8List?> captureWidget(GlobalKey boundaryKey,
      {double pixelRatio = 3.0}) async {
    try {
      final BuildContext? context = boundaryKey.currentContext;
      if (context == null) return null;
      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;

      final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturando widget: $e');
      return null;
    }
  }

  /// Guarda bytes PNG en un archivo temporal y retorna la ruta completa.
  /// El [prefix] permite personalizar el nombre base.
  static Future<String> saveTempPng(Uint8List bytes,
      {String prefix = 'screenshot'}) async {
    final Directory dir = await getTemporaryDirectory();
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String filePath = '${dir.path}/${prefix}_$timestamp.png';
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }

  /// Comparte la imagen PNG directamente sin guardarla primero.
  /// Si requiere persistencia, combinar con [saveTempPng] antes.
  static Future<void> sharePng(Uint8List bytes,
      {String filenamePrefix = 'screenshot'}) async {
    try {
      final String path = await saveTempPng(bytes, prefix: filenamePrefix);
      await Share.shareXFiles(<XFile>[XFile(path)], text: 'Captura de pantalla');
    } catch (e) {
      debugPrint('Error compartiendo screenshot: $e');
    }
  }
}
