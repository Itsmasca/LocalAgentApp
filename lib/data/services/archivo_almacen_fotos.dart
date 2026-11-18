import 'dart:io';

import '../../domain/services/almacen_fotos.dart';

class ArchivoAlmacenFotos implements AlmacenFotos {
  @override
  Future<bool> existe(String ruta) async {
    try {
      return await File(ruta).exists();
    } catch (_) {
      return false;
    }
  }
}
