import '../../core/utils/geo_utils.dart';
import '../entities/ubicacion.dart';
import '../repositories/ubicacion_repository.dart';
import '../services/device_services.dart';

/// REGLA DE NEGOCIO PRINCIPAL:
/// dadas unas coordenadas, devuelve la ubicación cuyo radio las contiene.
/// Si hay varias (radios traslapados), gana la más cercana.
/// Si no hay ninguna, devuelve `null` y la UI propone crear un lugar nuevo.
class ResolverUbicacion {
  final UbicacionRepository _repositorio;

  ResolverUbicacion(this._repositorio);

  Future<Ubicacion?> call(Coordenadas c) async {
    final ubicaciones = await _repositorio.obtenerTodas();

    Ubicacion? masCercana;
    var menorDistancia = double.infinity;

    for (final u in ubicaciones) {
      final d = distanciaMetros(c.latitud, c.longitud, u.latitud, u.longitud);
      if (d <= u.radioMetros && d < menorDistancia) {
        masCercana = u;
        menorDistancia = d;
      }
    }
    return masCercana;
  }
}
