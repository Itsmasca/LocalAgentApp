/// Qué pasó con el menú de compartir del sistema.
enum ResultadoCompartir {
  /// El usuario eligió una app destino.
  enviado,

  /// El usuario cerró el menú sin elegir nada. No es un error.
  cancelado,

  /// No hay ninguna app que pueda recibir el contenido.
  noDisponible,
}

/// Entrega contenido al menú de compartir del sistema operativo (FR-008).
/// Los datos solo salen del teléfono cuando el usuario elige un destino.
abstract interface class CompartirService {
  Future<ResultadoCompartir> compartirArchivo(String ruta, {String? asunto});

  /// [fotos] son rutas locales que ya se comprobó que existen.
  Future<ResultadoCompartir> compartirMensaje(String texto, List<String> fotos);

  /// Vacía la carpeta temporal de compartir (D-022).
  Future<void> limpiarTemporales();

  /// Copia un archivo generado a una carpeta permanente de la app, para
  /// cuando no hay ninguna app que lo reciba. Devuelve la ruta final.
  Future<String> guardarEnDispositivo(String ruta);
}

/// Resultado de un envío: qué pasó con el menú y, si se generó un
/// archivo, dónde quedó.
typedef EnvioEvidencia = ({ResultadoCompartir resultado, String? archivo});
