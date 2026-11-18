/// Formatea una fecha como dd/mm/aaaa hh:mm sin depender de paquetes externos.
String formatearFecha(DateTime f) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
}

String formatearCoordenadas(double lat, double lng) =>
    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

/// Enlace que abre el punto en un mapa desde cualquier dispositivo (D-021).
String enlaceMapa(double lat, double lng) =>
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

String _dos(int n) => n.toString().padLeft(2, '0');

/// Hora como hh:mm.
String formatearHora(DateTime f) => '${_dos(f.hour)}:${_dos(f.minute)}';

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Día para los separadores de la conversación: "Hoy", "Ayer" o
/// "12 nov 2026" (spec 004, FR-005). [hoy] se puede fijar en pruebas.
String formatearDia(DateTime dia, {DateTime? hoy}) {
  final ref = hoy ?? DateTime.now();
  // En UTC para que un cambio de horario no altere la cuenta de días.
  final d = DateTime.utc(dia.year, dia.month, dia.day);
  final h = DateTime.utc(ref.year, ref.month, ref.day);
  final diferencia = h.difference(d).inDays;
  if (diferencia == 0) return 'Hoy';
  if (diferencia == 1) return 'Ayer';
  return '${d.day} ${_meses[d.month - 1]} ${d.year}';
}
