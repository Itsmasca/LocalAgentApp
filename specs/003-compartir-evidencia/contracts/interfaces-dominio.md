# Contrato: interfaces de dominio

Interfaces nuevas en `lib/domain/`. Las implementa `lib/data/` y solo
`app/app_container.dart` conoce las clases concretas (principio III). Ninguna
importa Flutter. Todas lanzan `AppException` con mensaje para el usuario
(principio IV).

## `AjustesRepository` (`domain/repositories/`)

| Operación | Entrada | Salida | Notas |
|---|---|---|---|
| `obtenerResponsable()` | — | `Responsable?` | `null` si no hay nombre guardado |
| `guardarResponsable(r)` | `Responsable` | — | Valida nombre 1–80 |
| `borrarResponsable()` | — | — | "Omitir" no borra; esto es explícito desde ajustes |
| `incluirCoordenadas()` | — | `bool` | `true` por defecto |
| `guardarIncluirCoordenadas(v)` | `bool` | — | FR-006 |
| `reservarFolio(fecha)` | `DateTime` | `String` | Atómico; `BC-AAAA-NNNN` (D-020) |

## `AlmacenFotos` (`domain/services/`)

| Operación | Entrada | Salida |
|---|---|---|
| `existe(ruta)` | `String` | `Future<bool>` |

## `GeneradorReporte` (`domain/services/`)

| Operación | Entrada | Salida | Notas |
|---|---|---|---|
| `generar(paquete, folio, {onProgreso})` | `PaqueteEvidencia`, `String`, `void Function(double)?` | `ReporteGenerado` | Sin internet; fotos reducidas (D-017); progreso 0.0–1.0 |

Errores: espacio insuficiente o archivo ilegible → `AppException('No se pudo generar el reporte…')`.
Una foto faltante **no** es error: se dibuja "Foto no disponible" y se cuenta en `fotosOmitidas`.

## `CompartirService` (`domain/services/`)

| Operación | Entrada | Salida |
|---|---|---|
| `compartirArchivo(ruta, {asunto})` | `String`, `String?` | `ResultadoCompartir` |
| `compartirMensaje(texto, fotos)` | `String`, `List<String>` | `ResultadoCompartir` |
| `limpiarTemporales()` | — | `Future<void>` |

`ResultadoCompartir`: `enviado` | `cancelado` | `noDisponible`.
`cancelado` no muestra error. `noDisponible` → mensaje y opción de guardar el archivo.

## Casos de uso (`domain/usecases/`)

### `PrepararEvidencia`

`call(ubicacion, {Entrada? soloEsta}) → PaqueteEvidencia`

1. Carga las entradas de la ubicación (o usa `soloEsta`).
2. Las ordena de la más antigua a la más reciente.
3. Toma `incluirCoordenadas` y `responsable` de `AjustesRepository`.
4. Lanza `AppException('Aún no hay entradas para compartir.')` si no hay entradas.

### `ResumirEvidencia`

`call(paquete) → ResumenEvidencia { entradas, fotos, fotosFaltantes, incluyeCoordenadas }` (FR-007).

### `FormatearMensaje` (función pura)

`call(paquete) → String`. Formato en [formatos-salida.md](./formatos-salida.md#mensaje).
Sin coordenadas si `incluirCoordenadas == false` (SC-007).

### `CompartirEvidencia`

`call(paquete, {onProgreso}) → ResultadoCompartir`

- `reporteFormal`: limpia temporales → reserva folio → `GeneradorReporte.generar` → `compartirArchivo`.
- `mensaje`: limpia temporales → `FormatearMensaje` → `compartirMensaje` con las fotos que existen.
- Guarda `incluirCoordenadas` como nueva preferencia (FR-006).
