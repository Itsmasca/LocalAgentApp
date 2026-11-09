import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/device_services.dart';

/// Toma o elige una imagen y la copia a la carpeta privada de la app,
/// para que la ruta guardada en SQLite siga siendo válida después.
class ImagePickerMediaService implements MediaService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> tomarFoto() => _obtener(ImageSource.camera);

  @override
  Future<String?> elegirDeGaleria() => _obtener(ImageSource.gallery);

  Future<String?> _obtener(ImageSource origen) async {
    try {
      final archivo = await _picker.pickImage(
        source: origen,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (archivo == null) return null; // el usuario canceló

      final docs = await getApplicationDocumentsDirectory();
      final carpeta = Directory(p.join(docs.path, 'fotos'));
      await carpeta.create(recursive: true);

      final destino = p.join(carpeta.path,
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(archivo.path)}');
      await File(archivo.path).copy(destino);
      return destino;
    } catch (e) {
      throw AppException('No se pudo obtener la imagen.', causa: e);
    }
  }
}
