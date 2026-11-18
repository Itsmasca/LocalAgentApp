// Dart puro (sin Flutter): arma la secuencia de mensajes de la conversación
// de un lugar para poder probarla sin widgets (spec 004, D-026).

import '../../domain/entities/entrada.dart';
import '../../domain/entities/observacion.dart';
import '../../domain/entities/visita.dart';

/// Un elemento de la conversación, en orden cronológico.
sealed class ElementoConversacion {
  const ElementoConversacion();
}

/// Separador con el día calendario de los mensajes que le siguen.
final class SeparadorDia extends ElementoConversacion {
  final DateTime dia;
  const SeparadorDia(this.dia);
}

/// La entrada de una visita (mensaje destacado).
final class MensajeEntrada extends ElementoConversacion {
  final Entrada entrada;
  const MensajeEntrada(this.entrada);
}

/// Una observación simple.
final class MensajeObservacion extends ElementoConversacion {
  final Observacion observacion;
  const MensajeObservacion(this.observacion);
}

/// Recorre las [visitas] en orden (entrada y luego sus observaciones) e
/// inserta un [SeparadorDia] antes del primer mensaje y cada vez que cambia
/// el día calendario entre dos mensajes consecutivos (FR-005).
List<ElementoConversacion> armarElementosConversacion(List<Visita> visitas) {
  final elementos = <ElementoConversacion>[];
  DateTime? diaActual;

  void agregar(DateTime fecha, ElementoConversacion e) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    if (diaActual != dia) {
      elementos.add(SeparadorDia(dia));
      diaActual = dia;
    }
    elementos.add(e);
  }

  for (final v in visitas) {
    agregar(v.entrada.creadaEn, MensajeEntrada(v.entrada));
    for (final o in v.observaciones) {
      agregar(o.creadaEn, MensajeObservacion(o));
    }
  }
  return elementos;
}
