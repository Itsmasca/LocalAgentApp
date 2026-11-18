import '../../core/errors/app_exception.dart';
import '../entities/observacion.dart';
import '../repositories/entrada_repository.dart';
import '../repositories/observacion_repository.dart';

/// Agrega una observación a un lugar aplicando las reglas de la spec 004:
/// - RN-09: necesita texto no vacío de hasta [Observacion.maxCaracteres].
/// - RN-10: se asigna a la entrada más reciente del lugar; si el lugar no
///   tiene entradas, se rechaza.
class AgregarObservacion {
  final EntradaRepository _entradas;
  final ObservacionRepository _observaciones;

  AgregarObservacion(this._entradas, this._observaciones);

  Future<Observacion> call(
      {required int ubicacionId, required String texto}) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) {
      throw const AppException('Escribe la observación.');
    }
    if (limpio.length > Observacion.maxCaracteres) {
      throw const AppException('La observación puede tener como máximo '
          '${Observacion.maxCaracteres} caracteres.');
    }

    final ultima = await _entradas.obtenerMasReciente(ubicacionId);
    if (ultima == null || ultima.id == null) {
      throw const AppException('Registra primero una visita en este lugar.');
    }

    return _observaciones.crear(Observacion(
      entradaId: ultima.id!,
      texto: limpio,
      creadaEn: DateTime.now(),
    ));
  }
}
