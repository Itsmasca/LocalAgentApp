import '../entities/paquete_evidencia.dart';
import '../services/almacen_fotos.dart';

/// Cuenta lo que va a salir del teléfono y detecta fotos faltantes (FR-007).
class ResumirEvidencia {
  final AlmacenFotos _fotos;

  ResumirEvidencia(this._fotos);

  Future<ResumenEvidencia> call(PaqueteEvidencia paquete) async {
    final faltantes = <String>[];
    for (final e in paquete.entradas) {
      for (final ruta in e.fotos) {
        if (!await _fotos.existe(ruta)) faltantes.add(ruta);
      }
    }
    return ResumenEvidencia(
      entradas: paquete.entradas.length,
      fotos: paquete.totalFotos,
      fotosFaltantes: List.unmodifiable(faltantes),
      incluyeCoordenadas: paquete.incluirCoordenadas,
    );
  }
}
