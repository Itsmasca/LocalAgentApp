import 'package:bitacora_campo/core/errors/app_exception.dart';
import 'package:bitacora_campo/domain/entities/paquete_evidencia.dart';
import 'package:bitacora_campo/domain/entities/responsable.dart';
import 'package:bitacora_campo/domain/usecases/preparar_evidencia.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  final vieja = entrada(1, DateTime(2026, 11, 3, 10, 15), texto: 'Capacitor');
  final nueva = entrada(2, DateTime(2026, 11, 17, 18, 30), texto: 'Limpieza');
  final ahora = DateTime(2026, 11, 17, 19);

  PrepararEvidencia crear({
    List entradas = const [],
    FakeAjustesRepository? ajustes,
  }) =>
      PrepararEvidencia(
        FakeEntradaRepository(List.of(entradas.cast())),
        ajustes ?? FakeAjustesRepository(),
        ahora: () => ahora,
      );

  test('ordena las entradas de la más antigua a la más reciente', () async {
    // El repositorio las entrega de la más reciente a la más antigua.
    final p = await crear(entradas: [nueva, vieja])(
        casa, formato: FormatoCompartir.reporteFormal);
    expect(p.entradas.map((e) => e.id), [1, 2]);
    expect(p.periodo.desde, vieja.creadaEn);
    expect(p.periodo.hasta, nueva.creadaEn);
    expect(p.generadoEn, ahora);
  });

  test('con soloEsta, el paquete trae solo esa entrada', () async {
    final p = await crear(entradas: [nueva, vieja])(casa,
        formato: FormatoCompartir.mensaje, soloEsta: nueva);
    expect(p.entradas, [nueva]);
    expect(p.formato, FormatoCompartir.mensaje);
  });

  test('toma la preferencia de coordenadas y el responsable de ajustes',
      () async {
    final ajustes = FakeAjustesRepository(
      coordenadas: false,
      responsable: Responsable(nombre: 'Juan Pérez'),
    );
    final p = await crear(entradas: [vieja], ajustes: ajustes)(
        casa, formato: FormatoCompartir.reporteFormal);
    expect(p.incluirCoordenadas, isFalse);
    expect(p.responsable?.nombre, 'Juan Pérez');
  });

  test('sin entradas lanza AppException con mensaje para el usuario',
      () async {
    expect(
      () => crear()(casa, formato: FormatoCompartir.reporteFormal),
      throwsA(isA<AppException>().having(
          (e) => e.mensaje, 'mensaje', 'Aún no hay entradas para compartir.')),
    );
  });
}
