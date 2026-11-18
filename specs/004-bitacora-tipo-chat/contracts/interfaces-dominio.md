# Contrato: interfaces de dominio

Todo vive en `lib/domain/` sin importar Flutter (Principio III). Los errores técnicos se
lanzan como `AppException` con un mensaje para el usuario (Principio IV).

## `EntradaRepository` (se amplía)

```dart
abstract interface class EntradaRepository {
  /// Sin cambios (la usa la spec 003): de la más reciente a la más antigua.
  Future<List<Entrada>> obtenerPorUbicacion(int ubicacionId);
  Future<Entrada> crear(Entrada entrada);

  /// NUEVO. Visitas del lugar en orden ascendente, cada una con sus fotos y
  /// observaciones (ascendentes). Lista vacía si no hay entradas.
  /// Error → AppException('No se pudo cargar la conversación.')
  Future<List<Visita>> obtenerVisitas(int ubicacionId);

  /// NUEVO. La entrada con `creadaEn` más reciente del lugar, o `null`.
  Future<Entrada?> obtenerMasReciente(int ubicacionId);
}
```

## `ObservacionRepository` (nuevo)

```dart
abstract interface class ObservacionRepository {
  /// Inserta y devuelve la observación con su `id`.
  /// Error → AppException('No se pudo guardar la observación.')
  Future<Observacion> crear(Observacion observacion);

  /// Error → AppException('No se pudo eliminar la observación.')
  Future<void> eliminar(int id);
}
```

## `AgregarObservacion` (caso de uso nuevo)

```dart
class AgregarObservacion {
  AgregarObservacion(EntradaRepository entradas, ObservacionRepository observaciones);

  /// Aplica RN-09 y RN-10 y guarda.
  Future<Observacion> call({required int ubicacionId, required String texto});
}
```

| Entrada | Resultado |
|---|---|
| `texto` vacío o solo espacios | `AppException('Escribe la observación.')`, no se guarda nada |
| `texto.trim()` > 2 000 caracteres | `AppException('La observación puede tener como máximo 2000 caracteres.')` |
| Lugar sin entradas | `AppException('Registra primero una visita en este lugar.')` |
| Válido | `Observacion(entradaId: <más reciente>, texto: trim, creadaEn: ahora)` guardada |

## `UbicacionRepository.obtenerTodas` (cambia solo el orden)

Firma igual. Ordena por actividad, que incluye las observaciones (data-model, FR-014).

## `AppContainer`

Nuevos campos: `observaciones: ObservacionRepository` (implementación
`SqliteObservacionRepository`) y `agregarObservacion: AgregarObservacion`.
