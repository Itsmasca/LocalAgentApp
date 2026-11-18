import '../entities/responsable.dart';

/// Ajustes del técnico guardados en el dispositivo (D-019).
abstract interface class AjustesRepository {
  /// `null` si nunca se guardó un nombre.
  Future<Responsable?> obtenerResponsable();
  Future<void> guardarResponsable(Responsable responsable);
  Future<void> borrarResponsable();

  /// Si incluir coordenadas al compartir; `true` por defecto (FR-006).
  Future<bool> incluirCoordenadas();
  Future<void> guardarIncluirCoordenadas(bool valor);

  /// Reserva de forma atómica el siguiente folio `BC-AAAA-NNNN` para [fecha].
  /// El consecutivo se reinicia cada año (D-020).
  Future<String> reservarFolio(DateTime fecha);
}
