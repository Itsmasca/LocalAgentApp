/// Nota breve que el técnico agrega después de una entrada (spec 004).
/// No tiene fotos ni coordenadas propias: hereda el lugar de su entrada.
class Observacion {
  /// Máximo de caracteres del texto (FR-008).
  static const maxCaracteres = 2000;

  final int? id;
  final int entradaId;
  final String texto;
  final DateTime creadaEn;

  const Observacion({
    this.id,
    required this.entradaId,
    required this.texto,
    required this.creadaEn,
  });

  Observacion copyWith({int? id}) => Observacion(
        id: id ?? this.id,
        entradaId: entradaId,
        texto: texto,
        creadaEn: creadaEn,
      );
}
