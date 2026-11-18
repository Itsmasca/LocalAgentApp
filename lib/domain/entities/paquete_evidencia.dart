import 'entrada.dart';
import 'responsable.dart';
import 'ubicacion.dart';

/// Cómo se comparte la evidencia (FR-002).
enum FormatoCompartir { reporteFormal, mensaje }

/// Para quién es un reporte formal (FR-017). Se usa solo en ese reporte y
/// nunca se guarda.
class Destinatario {
  static const maxNombre = 80;
  static const maxDireccion = 200;

  /// Opcional, 0–80 caracteres.
  final String? nombre;

  /// Opcional, 0–200 caracteres.
  final String? direccion;

  Destinatario({String? nombre, String? direccion})
      : nombre = _limpio(nombre, maxNombre),
        direccion = _limpio(direccion, maxDireccion);

  bool get estaVacio => nombre == null && direccion == null;

  static String? _limpio(String? s, int max) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t.length > max ? t.substring(0, max) : t;
  }
}

/// Lo que el usuario decidió compartir en un momento dado. Es temporal:
/// se arma en la pantalla de compartir y se descarta al terminar.
class PaqueteEvidencia {
  final Ubicacion ubicacion;

  /// Al menos una; ordenadas de la más antigua a la más reciente (FR-003).
  final List<Entrada> entradas;
  final FormatoCompartir formato;
  final bool incluirCoordenadas;

  /// Solo se usa en el reporte formal.
  final Responsable? responsable;

  /// Solo se usa en el reporte formal.
  final Destinatario? destinatario;
  final DateTime generadoEn;

  const PaqueteEvidencia({
    required this.ubicacion,
    required this.entradas,
    required this.formato,
    required this.incluirCoordenadas,
    this.responsable,
    this.destinatario,
    required this.generadoEn,
  });

  int get totalFotos => entradas.fold(0, (s, e) => s + e.fotos.length);

  /// Fecha de la primera y de la última entrada incluida.
  ({DateTime desde, DateTime hasta}) get periodo =>
      (desde: entradas.first.creadaEn, hasta: entradas.last.creadaEn);

  /// Las propiedades nulables se pueden quitar con [sinResponsable] y
  /// [sinDestinatario].
  PaqueteEvidencia copyWith({
    List<Entrada>? entradas,
    FormatoCompartir? formato,
    bool? incluirCoordenadas,
    Responsable? responsable,
    bool sinResponsable = false,
    Destinatario? destinatario,
    bool sinDestinatario = false,
    DateTime? generadoEn,
  }) =>
      PaqueteEvidencia(
        ubicacion: ubicacion,
        entradas: entradas ?? this.entradas,
        formato: formato ?? this.formato,
        incluirCoordenadas: incluirCoordenadas ?? this.incluirCoordenadas,
        responsable: sinResponsable ? null : (responsable ?? this.responsable),
        destinatario:
            sinDestinatario ? null : (destinatario ?? this.destinatario),
        generadoEn: generadoEn ?? this.generadoEn,
      );
}

/// Lo que se le muestra al usuario antes de enviar (FR-007).
class ResumenEvidencia {
  final int entradas;
  final int fotos;

  /// Rutas de fotos registradas cuyo archivo ya no existe.
  final List<String> fotosFaltantes;
  final bool incluyeCoordenadas;

  const ResumenEvidencia({
    required this.entradas,
    required this.fotos,
    required this.fotosFaltantes,
    required this.incluyeCoordenadas,
  });
}
