import '../entities/entrada.dart';
import '../entities/visita.dart';

/// Contrato de persistencia de entradas.
abstract interface class EntradaRepository {
  /// Entradas de una ubicación, de la más reciente a la más antigua.
  Future<List<Entrada>> obtenerPorUbicacion(int ubicacionId);
  Future<Entrada> crear(Entrada entrada);

  /// Visitas del lugar de la más antigua a la más reciente, cada una con sus
  /// fotos y observaciones (ascendentes). Lista vacía si no hay entradas.
  /// Lanza `AppException('No se pudo cargar la conversación.')` si falla.
  Future<List<Visita>> obtenerVisitas(int ubicacionId);

  /// La entrada más reciente del lugar, o `null` si no tiene.
  Future<Entrada?> obtenerMasReciente(int ubicacionId);
}
