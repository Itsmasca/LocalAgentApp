import 'package:bitacora_campo/domain/entities/paquete_evidencia.dart';
import 'package:bitacora_campo/domain/usecases/resumir_evidencia.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  PaqueteEvidencia paquete({bool coordenadas = true}) => PaqueteEvidencia(
        ubicacion: casa,
        entradas: [
          entrada(1, DateTime(2026, 11, 3), fotos: ['/f/a.jpg', '/f/b.jpg']),
          entrada(2, DateTime(2026, 11, 4), texto: 'Solo texto'),
          entrada(3, DateTime(2026, 11, 5), fotos: ['/f/c.jpg']),
        ],
        formato: FormatoCompartir.reporteFormal,
        incluirCoordenadas: coordenadas,
        generadoEn: DateTime(2026, 11, 17),
      );

  test('cuenta entradas y fotos', () async {
    final r = await ResumirEvidencia(FakeAlmacenFotos())(paquete());
    expect(r.entradas, 3);
    expect(r.fotos, 3);
    expect(r.fotosFaltantes, isEmpty);
  });

  test('lista las fotos cuyo archivo ya no existe', () async {
    final r = await ResumirEvidencia(
        FakeAlmacenFotos(faltantes: {'/f/b.jpg'}))(paquete());
    expect(r.fotos, 3);
    expect(r.fotosFaltantes, ['/f/b.jpg']);
  });

  test('refleja si se incluyen coordenadas', () async {
    final almacen = FakeAlmacenFotos();
    expect((await ResumirEvidencia(almacen)(paquete())).incluyeCoordenadas,
        isTrue);
    expect(
        (await ResumirEvidencia(almacen)(paquete(coordenadas: false)))
            .incluyeCoordenadas,
        isFalse);
  });
}
