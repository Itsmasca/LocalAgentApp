import '../entities/paquete_evidencia.dart';
import '../entities/reporte_generado.dart';

/// Genera el reporte formal sin internet (FR-009).
abstract interface class GeneradorReporte {
  /// Escribe el documento y devuelve dónde quedó.
  ///
  /// Una foto cuyo archivo ya no existe NO es error: se dibuja
  /// "Foto no disponible" y se cuenta en [ReporteGenerado.fotosOmitidas].
  /// [onProgreso] recibe valores de 0.0 a 1.0.
  /// Lanza `AppException` si el documento no se pudo escribir.
  Future<ReporteGenerado> generar(
    PaqueteEvidencia paquete,
    String folio, {
    void Function(double progreso)? onProgreso,
  });
}
