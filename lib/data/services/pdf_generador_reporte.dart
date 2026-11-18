import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/errors/app_exception.dart';
import '../../core/utils/formato.dart';
import '../../domain/entities/paquete_evidencia.dart';
import '../../domain/entities/reporte_generado.dart';
import '../../domain/services/generador_reporte.dart';
import 'carpeta_compartir.dart';

/// Reporte formal en PDF, sin internet (D-015, contracts/formatos-salida.md).
///
/// 1. Reduce cada foto con compresión nativa (D-017).
/// 2. Arma el documento en otro isolate para no congelar la interfaz (D-022).
/// 3. Lo escribe en la carpeta temporal de compartir.
class PdfGeneradorReporte implements GeneradorReporte {
  /// El compresor escala por el lado corto: 960 px en una foto 4:3 deja el
  /// lado largo en 1280 px (D-017).
  static const _ladoCorto = 960;
  static const _calidad = 70;

  /// Parte del progreso que corresponde a reducir fotos; el resto es armar
  /// y escribir el documento.
  static const _pesoFotos = 0.85;

  @override
  Future<ReporteGenerado> generar(
    PaqueteEvidencia paquete,
    String folio, {
    void Function(double progreso)? onProgreso,
  }) async {
    try {
      onProgreso?.call(0);
      final fuentes = await _cargarFuentes();

      // Fotos reducidas por entrada; null = la foto ya no existe.
      final total = paquete.totalFotos;
      var hechas = 0;
      var omitidas = 0;
      final fotos = <List<Uint8List?>>[];
      for (final e in paquete.entradas) {
        final deEntrada = <Uint8List?>[];
        for (final ruta in e.fotos) {
          final bytes = await _reducir(ruta);
          if (bytes == null) omitidas++;
          deEntrada.add(bytes);
          hechas++;
          onProgreso?.call(_pesoFotos * hechas / (total == 0 ? 1 : total));
        }
        fotos.add(deEntrada);
      }

      final datos = _DatosReporte.de(paquete, folio, fotos);
      final pdf = await Isolate.run(() => _armar(datos, fuentes));
      onProgreso?.call(0.95);

      final carpeta = await carpetaCompartir();
      final archivo = File(p.join(
          carpeta.path, 'Reporte_${_nombreSeguro(paquete.ubicacion.nombre)}_$folio.pdf'));
      await archivo.writeAsBytes(pdf, flush: true);
      onProgreso?.call(1);

      return ReporteGenerado(
          folio: folio, rutaArchivo: archivo.path, fotosOmitidas: omitidas);
    } on AppException {
      rethrow;
    } on FileSystemException catch (e) {
      throw AppException(
          'No se pudo generar el reporte. Revisa que haya espacio en el teléfono.',
          causa: e);
    } catch (e) {
      throw AppException('No se pudo generar el reporte.', causa: e);
    }
  }

  Future<_Fuentes> _cargarFuentes() async {
    Future<Uint8List> leer(String nombre) async =>
        (await rootBundle.load('assets/fonts/$nombre')).buffer.asUint8List();
    return _Fuentes(
      regular: await leer('NotoSans-Regular.ttf'),
      negrita: await leer('NotoSans-Bold.ttf'),
      emoji: await leer('NotoEmoji-Regular.ttf'),
    );
  }

  /// JPEG reducido, o `null` si el archivo ya no existe o no se puede leer.
  Future<Uint8List?> _reducir(String ruta) async {
    final archivo = File(ruta);
    if (!await archivo.exists()) return null;
    try {
      final reducida = await FlutterImageCompress.compressWithFile(
        ruta,
        minWidth: _ladoCorto,
        minHeight: _ladoCorto,
        quality: _calidad,
        format: CompressFormat.jpeg,
      );
      return reducida ?? await archivo.readAsBytes();
    } catch (_) {
      // Si el compresor falla, mejor la foto original que ninguna.
      try {
        return await archivo.readAsBytes();
      } catch (_) {
        return null;
      }
    }
  }

  /// `Casa Sra. López` → `Casa_Sra_Lopez`.
  static String _nombreSeguro(String nombre) {
    const con = 'áéíóúüñÁÉÍÓÚÜÑ';
    const sin = 'aeiouunAEIOUUN';
    final b = StringBuffer();
    for (final ch in nombre.split('')) {
      final i = con.indexOf(ch);
      b.write(i >= 0 ? sin[i] : ch);
    }
    final limpio = b
        .toString()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return limpio.isEmpty ? 'Lugar' : limpio;
  }
}

// -------------------------------------------------------------------------
// Datos que viajan al isolate: solo tipos simples.
// -------------------------------------------------------------------------

class _Fuentes {
  final Uint8List regular;
  final Uint8List negrita;
  final Uint8List emoji;
  const _Fuentes(
      {required this.regular, required this.negrita, required this.emoji});
}

class _EntradaReporte {
  final String fecha;
  final String texto;
  final List<Uint8List?> fotos;
  const _EntradaReporte(this.fecha, this.texto, this.fotos);
}

class _DatosReporte {
  final String folio;
  final String generado;
  final String lugar;
  final String? coordenadas;
  final String? enlace;
  final String periodo;
  final String contenido;
  final String? responsable;
  final String? cliente;
  final List<_EntradaReporte> entradas;

  const _DatosReporte({
    required this.folio,
    required this.generado,
    required this.lugar,
    required this.coordenadas,
    required this.enlace,
    required this.periodo,
    required this.contenido,
    required this.responsable,
    required this.cliente,
    required this.entradas,
  });

  factory _DatosReporte.de(
      PaqueteEvidencia p, String folio, List<List<Uint8List?>> fotos) {
    final u = p.ubicacion;
    final r = p.responsable;
    final d = p.destinatario;
    String? unir(List<String?> partes) {
      final llenas = partes.whereType<String>().where((s) => s.isNotEmpty);
      return llenas.isEmpty ? null : llenas.join(' · ');
    }

    final n = p.entradas.length;
    final f = p.totalFotos;
    return _DatosReporte(
      folio: folio,
      generado: formatearFecha(p.generadoEn),
      lugar: u.nombre,
      // Sin coordenadas: ni coordenadas ni enlace (SC-007).
      coordenadas: p.incluirCoordenadas
          ? formatearCoordenadas(u.latitud, u.longitud)
          : null,
      enlace: p.incluirCoordenadas ? enlaceMapa(u.latitud, u.longitud) : null,
      periodo: n == 1
          ? formatearFecha(p.periodo.desde)
          : '${formatearFecha(p.periodo.desde)} – ${formatearFecha(p.periodo.hasta)}',
      contenido: '$n ${n == 1 ? 'entrada' : 'entradas'} · '
          '$f ${f == 1 ? 'foto' : 'fotos'}',
      responsable: r == null ? null : unir([r.nombre, r.negocio, r.telefono]),
      cliente: (d == null || d.estaVacio) ? null : unir([d.nombre, d.direccion]),
      entradas: [
        for (var i = 0; i < n; i++)
          _EntradaReporte(formatearFecha(p.entradas[i].creadaEn),
              p.entradas[i].texto.trim(), fotos[i]),
      ],
    );
  }
}

// -------------------------------------------------------------------------
// Construcción del documento (se ejecuta en otro isolate).
// -------------------------------------------------------------------------

const _gris = PdfColor.fromInt(0xFF5F6368);
const _acento = PdfColor.fromInt(0xFF00796B); // teal, como la app
const _fondoFoto = PdfColor.fromInt(0xFFECEFF1);

Future<Uint8List> _armar(_DatosReporte d, _Fuentes f) async {
  final regular = pw.Font.ttf(f.regular.buffer.asByteData());
  final negrita = pw.Font.ttf(f.negrita.buffer.asByteData());
  final emoji = pw.Font.ttf(f.emoji.buffer.asByteData());

  final doc = pw.Document(
    title: 'Reporte de evidencia ${d.folio}',
    author: 'Bitácora de Campo',
    theme: pw.ThemeData.withFont(
        base: regular, bold: negrita, fontFallback: [emoji]),
  );

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.letter,
    margin: const pw.EdgeInsets.all(2 * PdfPageFormat.cm),
    footer: (ctx) => pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        'Generado con Bitácora de Campo el ${d.generado} · Folio ${d.folio} · '
        'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: _gris),
      ),
    ),
    build: (ctx) => [
      ..._encabezado(d),
      pw.SizedBox(height: 16),
      for (var i = 0; i < d.entradas.length; i++)
        ..._entrada(d.entradas[i], i + 1, d.entradas.length),
    ],
  ));

  return doc.save();
}

List<pw.Widget> _encabezado(_DatosReporte d) {
  pw.Widget fila(String etiqueta, pw.Widget valor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 80,
              child: pw.Text(etiqueta,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(child: valor),
          ],
        ),
      );

  return [
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text('REPORTE DE EVIDENCIA DE CAMPO',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _acento)),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Folio: ${d.folio}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Generado: ${d.generado}',
                style: const pw.TextStyle(fontSize: 9, color: _gris)),
          ],
        ),
      ],
    ),
    pw.Divider(color: _acento, thickness: 1.5),
    pw.SizedBox(height: 6),
    fila('Lugar:', pw.Text(d.lugar)),
    if (d.coordenadas != null)
      fila(
        'Ubicación:',
        pw.Row(children: [
          pw.Text('${d.coordenadas}  ·  '),
          pw.UrlLink(
            destination: d.enlace!,
            child: pw.Text('Ver en mapa',
                style: const pw.TextStyle(
                    color: PdfColors.blue700,
                    decoration: pw.TextDecoration.underline)),
          ),
        ]),
      ),
    fila('Periodo:', pw.Text(d.periodo)),
    fila('Contenido:', pw.Text(d.contenido)),
    if (d.responsable != null) fila('Responsable:', pw.Text(d.responsable!)),
    if (d.cliente != null) fila('Cliente:', pw.Text(d.cliente!)),
  ];
}

List<pw.Widget> _entrada(_EntradaReporte e, int numero, int total) {
  final widgets = <pw.Widget>[
    pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 6),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      color: const PdfColor.fromInt(0xFFE0F2F1),
      child: pw.Text('Entrada $numero de $total — ${e.fecha}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    ),
  ];

  if (e.texto.isNotEmpty) {
    widgets.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      // `span` permite que un texto largo continúe en la página siguiente.
      child: pw.Text(e.texto, overflow: pw.TextOverflow.span),
    ));
  }

  // Fotos de 2 en 2; cada fila es un bloque para que la paginación no corte
  // una foto a la mitad.
  for (var i = 0; i < e.fotos.length; i += 2) {
    widgets.add(pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(children: [
        pw.Expanded(child: _foto(e.fotos[i])),
        pw.SizedBox(width: 8),
        pw.Expanded(
            child: i + 1 < e.fotos.length
                ? _foto(e.fotos[i + 1])
                : pw.SizedBox()),
      ]),
    ));
  }
  return widgets;
}

pw.Widget _foto(Uint8List? bytes) {
  const alto = 180.0;
  if (bytes == null) {
    return pw.Container(
      height: alto,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _fondoFoto,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Text('Foto no disponible',
          style: const pw.TextStyle(color: _gris)),
    );
  }
  return pw.Container(
    height: alto,
    color: _fondoFoto,
    alignment: pw.Alignment.center,
    child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
  );
}
