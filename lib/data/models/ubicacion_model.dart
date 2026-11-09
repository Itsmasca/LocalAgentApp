import '../../domain/entities/ubicacion.dart';

/// Traduce entre la entidad [Ubicacion] y una fila de SQLite.
class UbicacionModel {
  static Ubicacion fromMap(Map<String, Object?> m) => Ubicacion(
        id: m['id'] as int,
        nombre: m['nombre'] as String,
        latitud: (m['latitud'] as num).toDouble(),
        longitud: (m['longitud'] as num).toDouble(),
        radioMetros: (m['radio_metros'] as num).toDouble(),
        fotoPortada: m['foto_portada'] as String?,
        creadaEn: DateTime.parse(m['creada_en'] as String),
      );

  static Map<String, Object?> toMap(Ubicacion u) => {
        if (u.id != null) 'id': u.id,
        'nombre': u.nombre,
        'latitud': u.latitud,
        'longitud': u.longitud,
        'radio_metros': u.radioMetros,
        'foto_portada': u.fotoPortada,
        'creada_en': u.creadaEn.toIso8601String(),
      };
}
