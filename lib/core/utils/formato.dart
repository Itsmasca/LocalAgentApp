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
