/// Un registro hecho en una ubicación: texto (escrito o dictado), foto y GPS.
class Entrada {
  final int? id;
  final int ubicacionId;
  final String texto;
  final String? imagenPath;
  final double latitud;
  final double longitud;
  final DateTime creadaEn;

  const Entrada({
    this.id,
    required this.ubicacionId,
    required this.texto,
    this.imagenPath,
    required this.latitud,
    required this.longitud,
    required this.creadaEn,
  });

  Entrada copyWith({int? id}) => Entrada(
        id: id ?? this.id,
        ubicacionId: ubicacionId,
        texto: texto,
        imagenPath: imagenPath,
        latitud: latitud,
        longitud: longitud,
        creadaEn: creadaEn,
      );
}
