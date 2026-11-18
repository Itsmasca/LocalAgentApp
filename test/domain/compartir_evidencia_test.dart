import 'package:bitacora_campo/domain/entities/paquete_evidencia.dart';
import 'package:bitacora_campo/domain/services/compartir_service.dart';
import 'package:bitacora_campo/domain/usecases/compartir_evidencia.dart';
import 'package:bitacora_campo/domain/usecases/formatear_mensaje.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeAjustesRepository ajustes;
  late FakeGeneradorReporte generador;
  late FakeCompartirService compartir;

  CompartirEvidencia crear({Set<String> faltantes = const {}}) =>
      CompartirEvidencia(
          ajustes, generador, compartir, FakeAlmacenFotos(faltantes: faltantes));

  PaqueteEvidencia paquete(FormatoCompartir formato,
          {bool coordenadas = true}) =>
      PaqueteEvidencia(
        ubicacion: casa,
        entradas: [
          entrada(1, DateTime(2026, 11, 3), texto: 'Uno', fotos: ['/f/a.jpg']),
          entrada(2, DateTime(2026, 11, 4), fotos: ['/f/b.jpg', '/f/c.jpg']),
        ],
        formato: formato,
        incluirCoordenadas: coordenadas,
        generadoEn: DateTime(2026, 11, 17),
      );

  setUp(() {
    ajustes = FakeAjustesRepository();
    generador = FakeGeneradorReporte();
    compartir = FakeCompartirService();
  });

  group('reporte formal', () {
    test('limpia, reserva folio, genera y comparte el PDF', () async {
      final r = await crear()(paquete(FormatoCompartir.reporteFormal));
      expect(r.archivo, '/tmp/compartir/BC-2026-0001.pdf');

      expect(r.resultado, ResultadoCompartir.enviado);
      expect(compartir.eventos, ['limpiar', 'archivo']);
      expect(generador.llamadas.single.$2, 'BC-2026-0001');
      expect(compartir.archivos.single.$1, '/tmp/compartir/BC-2026-0001.pdf');
      expect(compartir.archivos.single.$2,
          'Reporte de evidencia – Casa Sra. López – BC-2026-0001');
    });

    test('cada reporte usa un folio nuevo', () async {
      final uc = crear();
      await uc(paquete(FormatoCompartir.reporteFormal));
      await uc(paquete(FormatoCompartir.reporteFormal));
      expect(generador.llamadas.map((l) => l.$2),
          ['BC-2026-0001', 'BC-2026-0002']);
    });

    test('cancelar el menú no es error', () async {
      compartir.resultado = ResultadoCompartir.cancelado;
      expect((await crear()(paquete(FormatoCompartir.reporteFormal))).resultado,
          ResultadoCompartir.cancelado);
    });
  });

  group('mensaje', () {
    test('comparte el texto formateado y solo las fotos que existen',
        () async {
      final p = paquete(FormatoCompartir.mensaje);
      await crear(faltantes: {'/f/b.jpg'})(p);

      expect(compartir.eventos, ['limpiar', 'mensaje']);
      expect(compartir.mensajes.single.$1, const FormatearMensaje()(p));
      expect(compartir.mensajes.single.$2, ['/f/a.jpg', '/f/c.jpg']);
    });

    test('no reserva folio ni genera reporte', () async {
      await crear()(paquete(FormatoCompartir.mensaje));
      expect(ajustes.folios, 0);
      expect(generador.llamadas, isEmpty);
    });
  });

  group('coordenadas', () {
    test('se recuerda la elección del usuario', () async {
      await crear()(paquete(FormatoCompartir.mensaje, coordenadas: false));
      await crear()(paquete(FormatoCompartir.reporteFormal));
      expect(ajustes.coordenadasGuardadas, [false, true]);
    });

    test('sin coordenadas, el mensaje no contiene coordenadas ni enlace',
        () async {
      await crear()(paquete(FormatoCompartir.mensaje, coordenadas: false));
      final texto = compartir.mensajes.single.$1;
      expect(texto, isNot(contains('19.43260')));
      expect(texto, isNot(contains('google.com/maps')));
    });

    test('el generador recibe la elección del usuario', () async {
      await crear()(paquete(FormatoCompartir.reporteFormal, coordenadas: false));
      expect(generador.llamadas.single.$1.incluirCoordenadas, isFalse);
    });
  });
}
