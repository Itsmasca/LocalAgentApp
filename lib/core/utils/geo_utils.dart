import 'dart:math';

/// Distancia en metros entre dos coordenadas (fórmula de Haversine).
double distanciaMetros(double lat1, double lng1, double lat2, double lng2) {
  const radioTierra = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return radioTierra * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double grados) => grados * pi / 180;
