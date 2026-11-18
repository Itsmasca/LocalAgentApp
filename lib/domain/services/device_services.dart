/// Interfaces de los gadgets del dispositivo. Cada una tiene una sola
/// responsabilidad (ISP) y la UI depende de ellas, no de los plugins.
library;

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

/// Cámara y galería. Copian las imágenes a la carpeta privada de la app y
/// devuelven sus rutas locales.
abstract interface class MediaService {
  /// Ruta de la foto tomada, o `null` si el usuario canceló.
  Future<String?> tomarFoto();

  /// Rutas de las imágenes elegidas (hasta [limite]); vacía si canceló.
  Future<List<String>> elegirDeGaleria({required int limite});

  /// Borra una imagen que se descartó antes de guardarla.
  Future<void> descartar(String ruta);
}

/// Micrófono → texto.
abstract interface class SpeechService {
  Future<bool> inicializar();

  /// [onResultado] recibe el texto reconocido y si ya es el resultado final.
  /// [onTerminado] se llama cuando el reconocedor deja de escuchar por su
  /// cuenta (silencio, tiempo máximo) o por [detener].
  /// [onError] recibe un [AppException] si el dictado falla a medio camino.
  Future<void> escuchar(
    void Function(String texto, bool esFinal) onResultado, {
    void Function()? onTerminado,
    void Function(Object error)? onError,
  });
  Future<void> detener();
  bool get escuchando;
}

/// Abre las coordenadas en la app de mapas del sistema.
abstract interface class MapLauncher {
  Future<void> abrirEnMapas(double latitud, double longitud);
}
