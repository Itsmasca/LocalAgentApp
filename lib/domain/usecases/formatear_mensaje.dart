import '../../core/utils/formato.dart';
import '../entities/paquete_evidencia.dart';

/// Texto del formato "Mensaje" (FR-015, contracts/formatos-salida.md).
/// Función pura: no incluye folio, responsable ni cliente, que son propios
/// del reporte formal.
class FormatearMensaje {
  static const pie = '— Enviado desde Bitácora de Campo';

  const FormatearMensaje();

  String call(PaqueteEvidencia paquete) {
    final u = paquete.ubicacion;
    final b = StringBuffer('📍 ${u.nombre}\n');
    if (paquete.incluirCoordenadas) {
      b
        ..writeln(formatearCoordenadas(u.latitud, u.longitud))
        ..writeln(enlaceMapa(u.latitud, u.longitud));
    }
    for (final e in paquete.entradas) {
      b
        ..writeln()
        ..writeln('🗓 ${formatearFecha(e.creadaEn)}');
      if (e.texto.trim().isNotEmpty) b.writeln(e.texto.trim());
    }
    b
      ..writeln()
      ..write(pie);
    return b.toString();
  }
}
