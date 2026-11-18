import '../../core/errors/app_exception.dart';
import '../entities/entrada.dart';
import '../entities/ubicacion.dart';
import '../repositories/ubicacion_repository.dart';
import '../services/device_services.dart';

/// Guarda una entrada aplicando las reglas de negocio:
/// 1. Una entrada necesita texto o al menos una foto (RN-03), y como mucho
///    [Entrada.maxFotos] fotos.
/// 2. Si no pertenece a una ubicación existente, se crea una nueva con
///    las coordenadas actuales y el nombre que dio el usuario (RN-02).
/// 3. La primera foto de una ubicación se vuelve su portada (RN-04).
///
/// El caso de uso DECIDE qué se guarda; el repositorio lo guarda de forma
/// atómica (decisión D-014): o se guarda todo, o nada.
class GuardarEntrada {
  final UbicacionRepository _ubicaciones;

  GuardarEntrada(this._ubicaciones);

  Future<Entrada> call({
    required Coordenadas coordenadas,
    required String texto,
    List<String> fotos = const [],
    Ubicacion? ubicacion,
    String? nombreNuevaUbicacion,
  }) async {
    if (texto.trim().isEmpty && fotos.isEmpty) {
      throw const AppException('La entrada necesita texto o una foto.');
    }
    if (fotos.length > Entrada.maxFotos) {
      throw const AppException(
          'Una entrada puede tener como máximo ${Entrada.maxFotos} fotos.');
    }

    Ubicacion? nueva;
    if (ubicacion == null) {
      final nombre = nombreNuevaUbicacion?.trim() ?? '';
      if (nombre.isEmpty) {
        throw const AppException('Ponle nombre al nuevo lugar.');
      }
      nueva = Ubicacion(
        nombre: nombre,
        latitud: coordenadas.latitud,
        longitud: coordenadas.longitud,
        creadaEn: DateTime.now(),
      );
    }

    final sinPortada = nueva != null || ubicacion!.fotoPortada == null;

    return _ubicaciones.registrarEntrada(
      nueva: nueva,
      entrada: Entrada(
        // Si el lugar es nuevo, el repositorio sustituye este id por el real.
        ubicacionId: ubicacion?.id ?? 0,
        texto: texto.trim(),
        fotos: List.unmodifiable(fotos),
        latitud: coordenadas.latitud,
        longitud: coordenadas.longitud,
        creadaEn: DateTime.now(),
      ),
      ponerPortada: fotos.isNotEmpty && sinPortada,
    );
  }
}
