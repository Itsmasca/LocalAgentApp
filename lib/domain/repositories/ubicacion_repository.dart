import '../entities/entrada.dart';
import '../entities/ubicacion.dart';

/// Contrato de persistencia de ubicaciones (Inversión de dependencias:
/// el dominio define la interfaz, la capa de datos la implementa).
///
/// La Ubicación es la raíz de su agregado: una Entrada no existe sin su
/// lugar. Por eso registrar una entrada (y, si hace falta, su lugar nuevo
/// y su portada) es una sola operación atómica de este repositorio.
abstract interface class UbicacionRepository {
  Future<List<Ubicacion>> obtenerTodas();
  Future<Ubicacion?> obtenerPorId(int id);
  Future<Ubicacion> crear(Ubicacion ubicacion);
  Future<void> actualizarPortada(int id, String rutaImagen);
  Future<void> eliminar(int id);

  /// Guarda en una sola transacción (todo o nada):
  /// 1. la ubicación [nueva], si viene;
  /// 2. la [entrada], ligada a esa ubicación nueva o a `entrada.ubicacionId`;
  /// 3. la portada del lugar con la foto de la entrada, si [ponerPortada].
  Future<Entrada> registrarEntrada({
    Ubicacion? nueva,
    required Entrada entrada,
    bool ponerPortada = false,
  });
}
