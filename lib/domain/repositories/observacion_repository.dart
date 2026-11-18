import '../entities/observacion.dart';

/// Contrato de persistencia de observaciones.
abstract interface class ObservacionRepository {
  /// Inserta y devuelve la observación con su `id`.
  /// Lanza `AppException('No se pudo guardar la observación.')` si falla.
  Future<Observacion> crear(Observacion observacion);

  /// Lanza `AppException('No se pudo eliminar la observación.')` si falla.
  Future<void> eliminar(int id);
}
