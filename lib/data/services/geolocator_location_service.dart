import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/device_services.dart';

class GeolocatorLocationService implements LocationService {
  @override
  Future<Coordenadas> obtenerPosicionActual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AppException('Activa el GPS del dispositivo.');
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        throw const AppException('Se necesita permiso de ubicación.');
      }
      if (permiso == LocationPermission.deniedForever) {
        throw const AppException(
            'El permiso de ubicación está bloqueado. Actívalo en Ajustes.');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return Coordenadas(pos.latitude, pos.longitude);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo obtener tu ubicación.', causa: e);
    }
  }
}
