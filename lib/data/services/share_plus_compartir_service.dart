import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/compartir_service.dart';
import 'carpeta_compartir.dart';

/// Entrega el contenido al menú de compartir del sistema (D-016).
class SharePlusCompartirService implements CompartirService {
  @override
  Future<ResultadoCompartir> compartirArchivo(String ruta,
      {String? asunto}) async {
    return _compartir(ShareParams(
      files: [XFile(ruta, mimeType: 'application/pdf')],
      subject: asunto,
      title: asunto,
    ));
  }

  @override
  Future<ResultadoCompartir> compartirMensaje(
      String texto, List<String> fotos) async {
    return _compartir(ShareParams(
      text: texto,
      // Algunas apps (correo) usan el asunto; WhatsApp a veces descarta el
      // texto cuando hay varias fotos (riesgo anotado en el plan).
      subject: texto.split('\n').first,
      files: fotos.isEmpty
          ? null
          : [for (final f in fotos) XFile(f, mimeType: 'image/jpeg')],
    ));
  }

  @override
  Future<void> limpiarTemporales() async {
    try {
      final carpeta = await carpetaCompartir();
      await for (final e in carpeta.list()) {
        try {
          await e.delete(recursive: true);
        } catch (_) {
          // Un archivo en uso no impide limpiar los demás.
        }
      }
    } catch (_) {
      // Limpiar es mantenimiento; nunca debe interrumpir al usuario.
    }
  }

  @override
  Future<String> guardarEnDispositivo(String ruta) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final carpeta = Directory(p.join(docs.path, 'reportes'));
      await carpeta.create(recursive: true);
      final destino = p.join(carpeta.path, p.basename(ruta));
      await File(ruta).copy(destino);
      return destino;
    } catch (e) {
      throw AppException('No se pudo guardar el archivo en el teléfono.',
          causa: e);
    }
  }

  Future<ResultadoCompartir> _compartir(ShareParams params) async {
    try {
      final r = await SharePlus.instance.share(params);
      return switch (r.status) {
        ShareResultStatus.success => ResultadoCompartir.enviado,
        ShareResultStatus.dismissed => ResultadoCompartir.cancelado,
        ShareResultStatus.unavailable => ResultadoCompartir.noDisponible,
      };
    } on FileSystemException catch (e) {
      throw AppException('No se encontró el archivo a compartir.', causa: e);
    } catch (e) {
      throw AppException('No se pudo abrir el menú de compartir.', causa: e);
    }
  }
}
