import '../../domain/entities/observacion.dart';

/// Traduce entre la entidad [Observacion] y su fila de `observaciones`.
class ObservacionModel {
  static Observacion fromMap(Map<String, Object?> m) => Observacion(
        id: m['id'] as int,
        entradaId: m['entrada_id'] as int,
        texto: m['texto'] as String,
        creadaEn: DateTime.parse(m['creada_en'] as String),
      );

  static Map<String, Object?> toMap(Observacion o) => {
        if (o.id != null) 'id': o.id,
        'entrada_id': o.entradaId,
        'texto': o.texto,
        'creada_en': o.creadaEn.toIso8601String(),
      };
}
