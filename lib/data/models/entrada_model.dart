import '../../domain/entities/entrada.dart';

/// Traduce entre la entidad [Entrada] y una fila de SQLite.
class EntradaModel {
  static Entrada fromMap(Map<String, Object?> m) => Entrada(
        id: m['id'] as int,
        ubicacionId: m['ubicacion_id'] as int,
        texto: m['texto'] as String,
        imagenPath: m['imagen_path'] as String?,
        latitud: (m['latitud'] as num).toDouble(),
        longitud: (m['longitud'] as num).toDouble(),
        creadaEn: DateTime.parse(m['creada_en'] as String),
      );

  static Map<String, Object?> toMap(Entrada e) => {
        if (e.id != null) 'id': e.id,
        'ubicacion_id': e.ubicacionId,
        'texto': e.texto,
        'imagen_path': e.imagenPath,
        'latitud': e.latitud,
        'longitud': e.longitud,
        'creada_en': e.creadaEn.toIso8601String(),
      };
}
