import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/device_services.dart';

/// Toma o elige imágenes y las copia a la carpeta privada de la app,
/// para que las rutas guardadas en SQLite sigan siendo válidas después.
class ImagePickerMediaService implements MediaService {
  static const _calidad = 80;
  static const _anchoMax = 1600.0;

  final ImagePicker _picker = ImagePicker();

  /// Evita nombres repetidos al copiar varias imágenes en el mismo milisegundo.
  int _secuencia = 0;

  @override
  Future<String?> tomarFoto() async {
    try {
      final archivo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _calidad,
        maxWidth: _anchoMax,
      );
      if (archivo == null) return null; // el usuario canceló
      return await _copiarAFotos(archivo);
    } catch (e) {
      throw AppException('No se pudo obtener la imagen.', causa: e);
    }
  }

  @override
  Future<List<String>> elegirDeGaleria({required int limite}) async {
    if (limite <= 0) return const [];
    try {
      // pickMultiImage exige un límite de al menos 2.
      final archivos = limite == 1
          ? [
              await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: _calidad,
                maxWidth: _anchoMax,
              )
            ].whereType<XFile>().toList()
          : await _picker.pickMultiImage(
              imageQuality: _calidad,
              maxWidth: _anchoMax,
              limit: limite,
            );

      final rutas = <String>[];
      // Algunas galerías ignoran el límite: se recorta aquí por si acaso.
      for (final a in archivos.take(limite)) {
        rutas.add(await _copiarAFotos(a));
      }
      return rutas;
    } catch (e) {
      throw AppException('No se pudieron obtener las imágenes.', causa: e);
    }
  }

  @override
  Future<void> descartar(String ruta) async {
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) await archivo.delete();
    } catch (_) {
      // Si no se pudo borrar solo queda un archivo huérfano; no es un error
      // que el usuario deba ver.
    }
  }

  Future<String> _copiarAFotos(XFile archivo) async {
    final docs = await getApplicationDocumentsDirectory();
    final carpeta = Directory(p.join(docs.path, 'fotos'));
    await carpeta.create(recursive: true);

    final nombre = '${DateTime.now().millisecondsSinceEpoch}_${_secuencia++}'
        '${p.extension(archivo.path)}';
    final destino = p.join(carpeta.path, nombre);
    await File(archivo.path).copy(destino);
    return destino;
  }
}
