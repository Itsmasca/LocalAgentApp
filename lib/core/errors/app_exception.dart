/// Excepción única de la app.
///
/// Las capas de datos y servicios traducen cualquier error técnico
/// (SQLite, permisos, plugins) a una [AppException] con un mensaje
/// legible, para que la UI solo tenga que mostrar [mensaje].
class AppException implements Exception {
  final String mensaje;
  final Object? causa;

  const AppException(this.mensaje, {this.causa});

  @override
  String toString() =>
      'AppException: $mensaje${causa != null ? ' (causa: $causa)' : ''}';
}
