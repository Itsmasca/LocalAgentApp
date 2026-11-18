import 'entrada.dart';
import 'observacion.dart';

/// Una entrada con las observaciones que se agregaron después de ella.
/// Es la unidad de la conversación de un lugar (spec 004, D-026).
class Visita {
  final Entrada entrada;

  /// Observaciones de la más antigua a la más reciente.
  final List<Observacion> observaciones;

  Visita({required this.entrada, List<Observacion> observaciones = const []})
      : observaciones = List.unmodifiable(observaciones);

  /// Fecha del último mensaje de la visita.
  DateTime get ultimaActividad =>
      observaciones.isEmpty ? entrada.creadaEn : observaciones.last.creadaEn;
}
