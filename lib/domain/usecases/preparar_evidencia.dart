import '../../core/errors/app_exception.dart';
import '../entities/entrada.dart';
import '../entities/paquete_evidencia.dart';
import '../entities/ubicacion.dart';
import '../repositories/ajustes_repository.dart';
import '../repositories/entrada_repository.dart';

/// Arma el paquete inicial de lo que se va a compartir:
/// todas las entradas de la ubicación (o solo [soloEsta]) en orden
/// cronológico, con las preferencias y los datos del responsable guardados.
class PrepararEvidencia {
  final EntradaRepository _entradas;
  final AjustesRepository _ajustes;
  final DateTime Function() _ahora;

  PrepararEvidencia(this._entradas, this._ajustes, {DateTime Function()? ahora})
      : _ahora = ahora ?? DateTime.now;

  Future<PaqueteEvidencia> call(
    Ubicacion ubicacion, {
    required FormatoCompartir formato,
    Entrada? soloEsta,
  }) async {
    final entradas = soloEsta != null
        ? [soloEsta]
        : await _entradas.obtenerPorUbicacion(ubicacion.id!);
    if (entradas.isEmpty) {
      throw const AppException('Aún no hay entradas para compartir.');
    }

    // De la más antigua a la más reciente (FR-003).
    final ordenadas = List.of(entradas)
      ..sort((a, b) => a.creadaEn.compareTo(b.creadaEn));

    return PaqueteEvidencia(
      ubicacion: ubicacion,
      entradas: List.unmodifiable(ordenadas),
      formato: formato,
      incluirCoordenadas: await _ajustes.incluirCoordenadas(),
      responsable: await _ajustes.obtenerResponsable(),
      generadoEn: _ahora(),
    );
  }
}
