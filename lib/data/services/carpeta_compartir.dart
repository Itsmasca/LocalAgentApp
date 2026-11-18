import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Carpeta temporal donde se escriben los archivos que se van a compartir
/// (`<temporal>/compartir/`, D-022). Se crea si no existe.
Future<Directory> carpetaCompartir() async {
  final temporal = await getTemporaryDirectory();
  final carpeta = Directory(p.join(temporal.path, 'compartir'));
  await carpeta.create(recursive: true);
  return carpeta;
}
