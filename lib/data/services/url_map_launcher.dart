import 'package:url_launcher/url_launcher.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/device_services.dart';

/// Abre Google Maps (app o web) con las coordenadas guardadas.
class UrlMapLauncher implements MapLauncher {
  @override
  Future<void> abrirEnMapas(double latitud, double longitud) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud');
    try {
      final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abierto) throw const AppException('No se pudo abrir Google Maps.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('No se pudo abrir Google Maps.', causa: e);
    }
  }
}
