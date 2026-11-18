/// Consulta las fotos guardadas en el dispositivo.
abstract interface class AlmacenFotos {
  /// `false` si el archivo de la foto ya no existe.
  Future<bool> existe(String ruta);
}
