import '../data/db/app_database.dart';
import '../data/repositories/sqlite_entrada_repository.dart';
import '../data/repositories/sqlite_ubicacion_repository.dart';
import '../data/services/geolocator_location_service.dart';
import '../data/services/image_picker_media_service.dart';
import '../data/services/speech_to_text_service.dart';
import '../data/services/url_map_launcher.dart';
import '../domain/repositories/entrada_repository.dart';
import '../domain/repositories/ubicacion_repository.dart';
import '../domain/services/device_services.dart';
import '../domain/usecases/guardar_entrada.dart';
import '../domain/usecases/resolver_ubicacion.dart';

/// Raíz de composición: el ÚNICO lugar que conoce las implementaciones
/// concretas. El resto de la app recibe interfaces por constructor.
/// Para pruebas basta con crear otro contenedor con implementaciones falsas.
class AppContainer {
  final UbicacionRepository ubicaciones;
  final EntradaRepository entradas;
  final LocationService location;
  final MediaService media;
  final SpeechService speech;
  final MapLauncher mapas;
  final ResolverUbicacion resolverUbicacion;
  final GuardarEntrada guardarEntrada;

  AppContainer({
    required this.ubicaciones,
    required this.entradas,
    required this.location,
    required this.media,
    required this.speech,
    required this.mapas,
  })  : resolverUbicacion = ResolverUbicacion(ubicaciones),
        guardarEntrada = GuardarEntrada(ubicaciones, entradas);

  factory AppContainer.produccion() {
    final db = AppDatabase();
    return AppContainer(
      ubicaciones: SqliteUbicacionRepository(db),
      entradas: SqliteEntradaRepository(db),
      location: GeolocatorLocationService(),
      media: ImagePickerMediaService(),
      speech: SpeechToTextService(),
      mapas: UrlMapLauncher(),
    );
  }
}
