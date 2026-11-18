import 'package:bitacora_campo/core/errors/app_exception.dart';
import 'package:bitacora_campo/domain/usecases/agregar_observacion.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeObservacionRepository observaciones;

  AgregarObservacion caso(FakeEntradaRepository entradas) =>
      AgregarObservacion(entradas, observaciones);

  Matcher errorCon(String mensaje) => throwsA(
      isA<AppException>().having((e) => e.mensaje, 'mensaje', mensaje));

  setUp(() => observaciones = FakeObservacionRepository());

  final conEntradas = FakeEntradaRepository([
    entrada(1, DateTime(2026, 11, 1, 9), texto: 'Primera visita'),
    entrada(2, DateTime(2026, 11, 10, 9), texto: 'Segunda visita'),
  ]);

  test('texto vacío o solo espacios no se guarda (RN-09)', () async {
    for (final texto in ['', '   ', '\n\t ']) {
      await expectLater(caso(conEntradas)(ubicacionId: casa.id!, texto: texto),
          errorCon('Escribe la observación.'));
    }
    expect(observaciones.guardadas, isEmpty);
  });

  test('más de 2000 caracteres no se guarda (RN-09)', () async {
    await expectLater(
        caso(conEntradas)(ubicacionId: casa.id!, texto: 'a' * 2001),
        errorCon('La observación puede tener como máximo 2000 caracteres.'));
    expect(observaciones.guardadas, isEmpty);
  });

  test('2000 caracteres exactos sí se guardan', () async {
    await caso(conEntradas)(ubicacionId: casa.id!, texto: 'a' * 2000);
    expect(observaciones.guardadas, hasLength(1));
  });

  test('lugar sin entradas se rechaza (RN-10)', () async {
    await expectLater(
        caso(FakeEntradaRepository([]))(ubicacionId: casa.id!, texto: 'Hola'),
        errorCon('Registra primero una visita en este lugar.'));
    expect(observaciones.guardadas, isEmpty);
  });

  test('se asigna a la entrada más reciente con el texto recortado (RN-10)',
      () async {
    final o = await caso(conEntradas)(
        ubicacionId: casa.id!, texto: '  Se cambió el capacitor  ');
    expect(o.id, isNotNull);
    expect(o.entradaId, 2);
    expect(o.texto, 'Se cambió el capacitor');
    expect(observaciones.guardadas.single.entradaId, 2);
  });
}
