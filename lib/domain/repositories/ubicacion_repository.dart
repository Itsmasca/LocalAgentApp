import '../entities/ubicacion.dart';

/// Contrato de persistencia de ubicaciones (Inversión de dependencias:
/// el dominio define la interfaz, la capa de datos la implementa).
abstract interface class UbicacionRepository {
  Future<List<Ubicacion>> obtenerTodas();
  Future<Ubicacion?> obtenerPorId(int id);
  Future<Ubicacion> crear(Ubicacion ubicacion);
  Future<void> actualizarPortada(int id, String rutaImagen);
  Future<void> eliminar(int id);
}
