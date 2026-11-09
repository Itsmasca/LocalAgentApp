/// Interfaces de los gadgets del dispositivo. Cada una tiene una sola
/// responsabilidad (ISP) y la UI depende de ellas, no de los plugins.

class Coordenadas {
  final double latitud;
  final double longitud;
  const Coordenadas(this.latitud, this.longitud);
}

/// GPS.
abstract interface class LocationService {
  /// Lanza [AppException] si el GPS está apagado o no hay permiso.
  Future<Coordenadas> obtenerPosicionActual();
}

/// Cámara y galería. Devuelven la ruta local donde quedó guardada la imagen,
/// o `null` si el usuario canceló.
abstract interface class MediaService {
  Future<String?> tomarFoto();
  Future<String?> elegirDeGaleria();
}

/// Micrófono → texto.
abstract interface class SpeechService {
  Future<bool> inicializar();

  /// [onResultado] recibe el texto reconocido y si ya es el resultado final.
  Future<void> escuchar(void Function(String texto, bool esFinal) onResultado);
  Future<void> detener();
  bool get escuchando;
}

/// Abre las coordenadas en la app de mapas del sistema.
abstract interface class MapLauncher {
  Future<void> abrirEnMapas(double latitud, double longitud);
}
