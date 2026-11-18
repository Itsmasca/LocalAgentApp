/// Resultado de generar un reporte formal.
class ReporteGenerado {
  /// `BC-AAAA-NNNN` (D-020).
  final String folio;

  /// Ruta local del PDF, en la carpeta temporal de compartir (D-022).
  final String rutaArchivo;

  /// Fotos que no se pudieron incluir porque su archivo ya no existe.
  final int fotosOmitidas;

  const ReporteGenerado({
    required this.folio,
    required this.rutaArchivo,
    required this.fotosOmitidas,
  });
}
