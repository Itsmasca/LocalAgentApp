import '../../core/errors/app_exception.dart';

/// Quién emite los reportes formales: el técnico y, si quiere, su negocio
/// y teléfono. Se captura una vez y se guarda en el dispositivo (FR-012).
class Responsable {
  static const maxNombre = 80;
  static const maxNegocio = 80;
  static const maxTelefono = 20;

  /// Obligatorio; 1–80 caracteres.
  final String nombre;

  /// Opcional; vacío se guarda como ausente. 0–80 caracteres.
  final String? negocio;

  /// Opcional. 0–20 caracteres (dígitos, espacios, `+ - ( )`).
  final String? telefono;

  Responsable._(this.nombre, this.negocio, this.telefono);

  /// Recorta espacios y valida. Lanza [AppException] si algo no cumple.
  factory Responsable({
    required String nombre,
    String? negocio,
    String? telefono,
  }) {
    final n = nombre.trim();
    final neg = _opcional(negocio);
    final tel = _opcional(telefono);

    if (n.isEmpty) {
      throw const AppException('Escribe tu nombre para los reportes.');
    }
    if (n.length > maxNombre) {
      throw const AppException(
          'El nombre puede tener como máximo $maxNombre caracteres.');
    }
    if (neg != null && neg.length > maxNegocio) {
      throw const AppException(
          'El negocio puede tener como máximo $maxNegocio caracteres.');
    }
    if (tel != null) {
      if (tel.length > maxTelefono) {
        throw const AppException(
            'El teléfono puede tener como máximo $maxTelefono caracteres.');
      }
      if (!RegExp(r'^[0-9 +\-()]+$').hasMatch(tel)) {
        throw const AppException(
            'El teléfono solo puede tener dígitos, espacios y + - ( ).');
      }
    }
    return Responsable._(n, neg, tel);
  }

  static String? _opcional(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
