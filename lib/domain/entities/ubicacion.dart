/// Un lugar físico al que el usuario regresa (domicilio, obra, propiedad).
///
/// Es la "llave de memoria" de la app: todo el historial se agrupa por
/// ubicación y no por sesión.
class Ubicacion {
  final int? id;
  final String nombre;
  final double latitud;
  final double longitud;

  /// Radio en metros dentro del cual una nueva entrada se asigna a este lugar.
  final double radioMetros;

  /// Ruta local de la foto que se usa como portada (y en la animación Hero).
  final String? fotoPortada;
  final DateTime creadaEn;

  static const double radioPorDefecto = 75;

  const Ubicacion({
    this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.radioMetros = radioPorDefecto,
    this.fotoPortada,
    required this.creadaEn,
  });

  Ubicacion copyWith({int? id, String? fotoPortada}) => Ubicacion(
        id: id ?? this.id,
        nombre: nombre,
        latitud: latitud,
        longitud: longitud,
        radioMetros: radioMetros,
        fotoPortada: fotoPortada ?? this.fotoPortada,
        creadaEn: creadaEn,
      );

  /// Tag compartido entre lista y detalle para la transición Hero.
  String get heroTag => 'ubicacion-foto-$id';
}
