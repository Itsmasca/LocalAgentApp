import '../data/db/app_database.dart';
import '../data/repositories/sqlite_ajustes_repository.dart';
import '../data/repositories/sqlite_entrada_repository.dart';
import '../data/repositories/sqlite_observacion_repository.dart';
import '../data/repositories/sqlite_ubicacion_repository.dart';
import '../data/services/archivo_almacen_fotos.dart';
import '../data/services/geolocator_location_service.dart';
import '../data/services/image_picker_media_service.dart';
import '../data/services/pdf_generador_reporte.dart';
import '../data/services/share_plus_compartir_service.dart';
import '../data/services/speech_to_text_service.dart';
import '../data/services/url_map_launcher.dart';
import '../domain/repositories/ajustes_repository.dart';
import '../domain/repositories/entrada_repository.dart';
import '../domain/repositories/observacion_repository.dart';
import '../domain/repositories/ubicacion_repository.dart';
import '../domain/services/almacen_fotos.dart';
import '../domain/services/compartir_service.dart';
import '../domain/services/device_services.dart';
import '../domain/services/generador_reporte.dart';
import '../domain/usecases/agregar_observacion.dart';
import '../domain/usecases/compartir_evidencia.dart';
import '../domain/usecases/guardar_entrada.dart';
import '../domain/usecases/preparar_evidencia.dart';
import '../domain/usecases/resolver_ubicacion.dart';
import '../domain/usecases/resumir_evidencia.dart';

/// Raíz de composición: el ÚNICO lugar que conoce las implementaciones
/// concretas. El resto de la app recibe interfaces por constructor.
/// Para pruebas basta con crear otro contenedor con implementaciones falsas.
class AppContainer {
  final UbicacionRepository ubicaciones;
  final EntradaRepository entradas;
  final ObservacionRepository observaciones;
  final AjustesRepository ajustes;
  final LocationService location;
  final MediaService media;
  final SpeechService speech;
  final MapLauncher mapas;
  final AlmacenFotos almacenFotos;
  final GeneradorReporte generadorReporte;
  final CompartirService compartir;

  final ResolverUbicacion resolverUbicacion;
  final GuardarEntrada guardarEntrada;
  final PrepararEvidencia prepararEvidencia;
  final ResumirEvidencia resumirEvidencia;
  final CompartirEvidencia compartirEvidencia;
  final AgregarObservacion agregarObservacion;

  AppContainer({
    required this.ubicaciones,
    required this.entradas,
    required this.observaciones,
    required this.ajustes,
    required this.location,
    required this.media,
    required this.speech,
    required this.mapas,
    required this.almacenFotos,
    required this.generadorReporte,
    required this.compartir,
  })  : resolverUbicacion = ResolverUbicacion(ubicaciones),
        guardarEntrada = GuardarEntrada(ubicaciones),
        prepararEvidencia = PrepararEvidencia(entradas, ajustes),
        resumirEvidencia = ResumirEvidencia(almacenFotos),
        compartirEvidencia = CompartirEvidencia(
            ajustes, generadorReporte, compartir, almacenFotos),
        agregarObservacion = AgregarObservacion(entradas, observaciones);

  factory AppContainer.produccion() {
    final db = AppDatabase();
    return AppContainer(
      ubicaciones: SqliteUbicacionRepository(db),
      entradas: SqliteEntradaRepository(db),
      observaciones: SqliteObservacionRepository(db),
      ajustes: SqliteAjustesRepository(db),
      location: GeolocatorLocationService(),
      media: ImagePickerMediaService(),
      speech: SpeechToTextService(),
      mapas: UrlMapLauncher(),
      almacenFotos: ArchivoAlmacenFotos(),
      generadorReporte: PdfGeneradorReporte(),
      compartir: SharePlusCompartirService(),
    );
  }
}
