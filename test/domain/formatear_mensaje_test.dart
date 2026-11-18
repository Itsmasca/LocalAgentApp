import 'package:bitacora_campo/domain/entities/paquete_evidencia.dart';
import 'package:bitacora_campo/domain/entities/responsable.dart';
import 'package:bitacora_campo/domain/usecases/formatear_mensaje.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  const formatear = FormatearMensaje();

  PaqueteEvidencia paquete(List entradas, {bool coordenadas = true}) =>
      PaqueteEvidencia(
        ubicacion: casa,
        entradas: entradas.cast(),
        formato: FormatoCompartir.mensaje,
        incluirCoordenadas: coordenadas,
        responsable: Responsable(nombre: 'Juan Pérez'),
        destinatario: Destinatario(nombre: 'María López'),
        generadoEn: DateTime(2026, 11, 17, 19),
      );

  final e1 = entrada(1, DateTime(2026, 11, 3, 10, 15),
      texto: 'Se cambió el capacitor del condensador.');
  final e2 = entrada(2, DateTime(2026, 11, 17, 18, 30),
      texto: 'Limpieza de serpentín terminada.');

  test('formato completo con coordenadas, en orden cronológico', () {
    expect(
      formatear(paquete([e1, e2])),
      '📍 Casa Sra. López\n'
      '19.43260, -99.13320\n'
      'https://www.google.com/maps/search/?api=1&query=19.4326,-99.1332\n'
      '\n'
      '🗓 03/11/2026 10:15\n'
      'Se cambió el capacitor del condensador.\n'
      '\n'
      '🗓 17/11/2026 18:30\n'
      'Limpieza de serpentín terminada.\n'
      '\n'
      '— Enviado desde Bitácora de Campo',
    );
  });

  test('sin coordenadas no incluye coordenadas ni enlace al mapa', () {
    final t = formatear(paquete([e1], coordenadas: false));
    expect(t, isNot(contains('19.43260')));
    expect(t, isNot(contains('google.com/maps')));
    expect(t, startsWith('📍 Casa Sra. López\n\n🗓 03/11/2026 10:15\n'));
  });

  test('una entrada sin texto muestra solo su fecha', () {
    final t = formatear(paquete([entrada(3, DateTime(2026, 11, 5, 9, 0))]));
    expect(t, contains('🗓 05/11/2026 09:00\n\n— Enviado'));
  });

  test('conserva emojis del texto', () {
    final t = formatear(paquete(
        [entrada(4, DateTime(2026, 11, 5, 9, 0), texto: 'Todo bien 👍')]));
    expect(t, contains('Todo bien 👍'));
  });

  test('no incluye folio, responsable ni cliente', () {
    final t = formatear(paquete([e1]));
    expect(t, isNot(contains('BC-')));
    expect(t, isNot(contains('Juan Pérez')));
    expect(t, isNot(contains('María López')));
  });
}
