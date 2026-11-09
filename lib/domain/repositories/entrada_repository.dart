import '../entities/entrada.dart';

/// Contrato de persistencia de entradas.
abstract interface class EntradaRepository {
  /// Entradas de una ubicación, de la más reciente a la más antigua.
  Future<List<Entrada>> obtenerPorUbicacion(int ubicacionId);
  Future<Entrada> crear(Entrada entrada);
}
