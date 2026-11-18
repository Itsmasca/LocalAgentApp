import '../entities/paquete_evidencia.dart';
import '../repositories/ajustes_repository.dart';
import '../services/almacen_fotos.dart';
import '../services/compartir_service.dart';
import '../services/generador_reporte.dart';
import 'formatear_mensaje.dart';

/// Genera lo que el usuario eligió y lo entrega al menú de compartir.
///
/// Nada sale del teléfono hasta que el usuario elige un destino en ese
/// menú (FR-009, D-023).
class CompartirEvidencia {
  final AjustesRepository _ajustes;
  final GeneradorReporte _generador;
  final CompartirService _compartir;
  final AlmacenFotos _fotos;
  final FormatearMensaje _formatear;

  CompartirEvidencia(
    this._ajustes,
    this._generador,
    this._compartir,
    this._fotos, {
    FormatearMensaje formatear = const FormatearMensaje(),
  }) : _formatear = formatear;

  Future<EnvioEvidencia> call(
    PaqueteEvidencia paquete, {
    void Function(double progreso)? onProgreso,
  }) async {
    // Los archivos del envío anterior ya no se necesitan (D-022).
    await _compartir.limpiarTemporales();

    final envio = switch (paquete.formato) {
      FormatoCompartir.reporteFormal => await _reporte(paquete, onProgreso),
      FormatoCompartir.mensaje => await _mensaje(paquete),
    };

    // La elección de coordenadas se recuerda para la próxima vez (FR-006).
    await _ajustes.guardarIncluirCoordenadas(paquete.incluirCoordenadas);
    return envio;
  }

  Future<EnvioEvidencia> _reporte(
      PaqueteEvidencia paquete, void Function(double)? onProgreso) async {
    final folio = await _ajustes.reservarFolio(paquete.generadoEn);
    final reporte =
        await _generador.generar(paquete, folio, onProgreso: onProgreso);
    final resultado = await _compartir.compartirArchivo(
      reporte.rutaArchivo,
      asunto: 'Reporte de evidencia – ${paquete.ubicacion.nombre} – $folio',
    );
    return (resultado: resultado, archivo: reporte.rutaArchivo);
  }

  Future<EnvioEvidencia> _mensaje(PaqueteEvidencia paquete) async {
    final existentes = <String>[];
    for (final e in paquete.entradas) {
      for (final ruta in e.fotos) {
        if (await _fotos.existe(ruta)) existentes.add(ruta);
      }
    }
    final resultado =
        await _compartir.compartirMensaje(_formatear(paquete), existentes);
    return (resultado: resultado, archivo: null);
  }
}
