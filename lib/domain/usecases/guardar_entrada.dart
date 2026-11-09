import '../../core/errors/app_exception.dart';
import '../entities/entrada.dart';
import '../entities/ubicacion.dart';
import '../repositories/entrada_repository.dart';
import '../repositories/ubicacion_repository.dart';
import '../services/device_services.dart';

/// Guarda una entrada aplicando las reglas de negocio:
/// 1. Una entrada necesita texto o foto.
/// 2. Si no pertenece a una ubicación existente, se crea una nueva con
///    las coordenadas actuales y el nombre que dio el usuario.
/// 3. La primera foto de una ubicación se vuelve su portada.
class GuardarEntrada {
  final UbicacionRepository _ubicaciones;
  final EntradaRepository _entradas;

  GuardarEntrada(this._ubicaciones, this._entradas);

  Future<Entrada> call({
    required Coordenadas coordenadas,
    required String texto,
    String? imagenPath,
    Ubicacion? ubicacion,
    String? nombreNuevaUbicacion,
  }) async {
    if (texto.trim().isEmpty && imagenPath == null) {
      throw const AppException('La entrada necesita texto o una foto.');
    }

    var destino = ubicacion;
    if (destino == null) {
      final nombre = nombreNuevaUbicacion?.trim() ?? '';
      if (nombre.isEmpty) {
        throw const AppException('Ponle nombre al nuevo lugar.');
      }
      destino = await _ubicaciones.crear(Ubicacion(
        nombre: nombre,
        latitud: coordenadas.latitud,
        longitud: coordenadas.longitud,
        creadaEn: DateTime.now(),
      ));
    }

    final entrada = await _entradas.crear(Entrada(
      ubicacionId: destino.id!,
      texto: texto.trim(),
      imagenPath: imagenPath,
      latitud: coordenadas.latitud,
      longitud: coordenadas.longitud,
      creadaEn: DateTime.now(),
    ));

    if (imagenPath != null && destino.fotoPortada == null) {
      await _ubicaciones.actualizarPortada(destino.id!, imagenPath);
    }
    return entrada;
  }
}
