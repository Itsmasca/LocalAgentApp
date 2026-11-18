import 'package:bitacora_campo/domain/entities/observacion.dart';
import 'package:bitacora_campo/domain/entities/visita.dart';
import 'package:bitacora_campo/presentation/conversacion/elementos_conversacion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fakes.dart';

Observacion obs(int id, int entradaId, DateTime f) =>
    Observacion(id: id, entradaId: entradaId, texto: 'obs $id', creadaEn: f);

/// Resume los elementos como texto para comparar fácilmente.
List<String> resumen(List<ElementoConversacion> l) => [
      for (final e in l)
        switch (e) {
          SeparadorDia(:final dia) => 'dia ${dia.month}/${dia.day}',
          MensajeEntrada(:final entrada) => 'entrada ${entrada.id}',
          MensajeObservacion(:final observacion) => 'obs ${observacion.id}',
        }
    ];

void main() {
  test('sin visitas no hay elementos', () {
    expect(armarElementosConversacion([]), isEmpty);
  });

  test('una visita sin observaciones lleva separador y entrada', () {
    final v = Visita(entrada: entrada(1, DateTime(2026, 11, 10, 9)));
    expect(resumen(armarElementosConversacion([v])),
        ['dia 11/10', 'entrada 1']);
  });

  test('entrada y observaciones del mismo día comparten un separador', () {
    final v = Visita(entrada: entrada(1, DateTime(2026, 11, 10, 9)), observaciones: [
      obs(1, 1, DateTime(2026, 11, 10, 9, 30)),
      obs(2, 1, DateTime(2026, 11, 10, 18)),
    ]);
    expect(resumen(armarElementosConversacion([v])),
        ['dia 11/10', 'entrada 1', 'obs 1', 'obs 2']);
  });

  test('una observación al día siguiente agrega un separador', () {
    final v = Visita(entrada: entrada(1, DateTime(2026, 11, 10, 23)), observaciones: [
      obs(1, 1, DateTime(2026, 11, 11, 0, 5)),
    ]);
    expect(resumen(armarElementosConversacion([v])),
        ['dia 11/10', 'entrada 1', 'dia 11/11', 'obs 1']);
  });

  test('dos visitas en días distintos quedan en orden con sus separadores', () {
    final v1 = Visita(entrada: entrada(1, DateTime(2026, 11, 1, 10)), observaciones: [
      obs(1, 1, DateTime(2026, 11, 1, 11)),
    ]);
    final v2 = Visita(entrada: entrada(2, DateTime(2026, 11, 5, 10)), observaciones: [
      obs(2, 2, DateTime(2026, 11, 5, 12)),
    ]);
    expect(resumen(armarElementosConversacion([v1, v2])), [
      'dia 11/1', 'entrada 1', 'obs 1',
      'dia 11/5', 'entrada 2', 'obs 2',
    ]);
  });
}
