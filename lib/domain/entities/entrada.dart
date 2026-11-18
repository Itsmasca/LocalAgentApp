/// Un registro hecho en una ubicación: texto (escrito o dictado), fotos y GPS.
class Entrada {
  /// Máximo de fotos por entrada.
  static const maxFotos = 10;

  final int? id;
  final int ubicacionId;
  final String texto;

  /// Rutas locales de las fotos, en el orden en que se agregaron.
  final List<String> fotos;
  final double latitud;
  final double longitud;
  final DateTime creadaEn;

  const Entrada({
    this.id,
    required this.ubicacionId,
    required this.texto,
    this.fotos = const [],
    required this.latitud,
    required this.longitud,
    required this.creadaEn,
  });

  /// Primera foto de la entrada, o `null` si no tiene.
  String? get fotoPrincipal => fotos.isEmpty ? null : fotos.first;

  Entrada copyWith({int? id, int? ubicacionId, List<String>? fotos}) => Entrada(
        id: id ?? this.id,
        ubicacionId: ubicacionId ?? this.ubicacionId,
        texto: texto,
        fotos: fotos ?? this.fotos,
        latitud: latitud,
        longitud: longitud,
        creadaEn: creadaEn,
      );
}
