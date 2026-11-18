# Data Model: Bitácora de cada lugar en formato de chat

`ubicaciones`, `entradas` y `fotos` **no cambian**. Se agrega la tabla
`observaciones` y dos entidades de dominio.

## Persistente

### Tabla `observaciones` (nueva, siguiente versión libre del esquema, D-025)

| Columna | Tipo | Reglas |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | |
| `entrada_id` | INTEGER NOT NULL REFERENCES `entradas(id)` ON DELETE CASCADE | Entrada a la que pertenece (FR-004) |
| `texto` | TEXT NOT NULL | 1–2 000 caracteres tras `trim` (FR-008) |
| `creada_en` | TEXT NOT NULL | ISO-8601 local, mismo formato que `entradas.creada_en` |

Índice: `idx_observaciones_entrada ON observaciones(entrada_id, creada_en)`.

**Migración** `onUpgrade` (`if (deVersion < N)`): `CREATE TABLE` + índice. No mueve
datos, porque las entradas existentes simplemente no tienen observaciones (FR-013, SC-004).
`onCreate` crea el esquema completo de la versión N.

**Orden de la lista principal** (FR-014):

```text
actividad(u) = MAX( u.creada_en,
                    MAX(e.creada_en) de sus entradas,
                    MAX(o.creada_en) de las observaciones de esas entradas )
ORDER BY actividad DESC
```

## Dominio

### `Observacion` (`lib/domain/entities/observacion.dart`)

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `int?` | `null` antes de guardar |
| `entradaId` | `int` | Obligatorio |
| `texto` | `String` | Sin espacios al inicio o al final; no vacío; ≤ `maxCaracteres` |
| `creadaEn` | `DateTime` | Hora de envío |

Constante: `static const maxCaracteres = 2000`.

### `Visita` (`lib/domain/entities/visita.dart`)

| Campo | Tipo | Reglas |
|---|---|---|
| `entrada` | `Entrada` | El mensaje destacado |
| `observaciones` | `List<Observacion>` | Inmodificable, orden ascendente por `creadaEn` |

Derivado: `DateTime get ultimaActividad` = `creadaEn` de la última observación, o de la entrada si no tiene.

Una ubicación tiene de 0 a N visitas, ordenadas por `entrada.creadaEn` ascendente.

### Reglas

| Id | Regla | Dónde |
|---|---|---|
| RN-09 | Una observación necesita texto no vacío de hasta 2 000 caracteres | `AgregarObservacion` |
| RN-10 | Una observación nueva se asigna a la entrada más reciente de su ubicación; si el lugar no tiene entradas, se rechaza | `AgregarObservacion` |
| RN-11 | Borrar una entrada o ubicación borra sus observaciones | FK `ON DELETE CASCADE` |
| RN-12 | Solo "Nueva visita" (o el alta desde la lista) crea entradas; la barra del chat crea solo observaciones | UI (contrato de flujo) |

## Presentación (sin persistencia)

### `ElementoConversacion` (`lib/presentation/conversacion/elementos_conversacion.dart`, Dart puro)

Unión sellada con tres variantes:

- `SeparadorDia(DateTime dia)`
- `MensajeEntrada(Entrada entrada)`
- `MensajeObservacion(Observacion observacion)`

`List<ElementoConversacion> armarElementosConversacion(List<Visita> visitas)` recorre en orden
cronológico la entrada y luego sus observaciones, e inserta un `SeparadorDia` antes del
primer mensaje y cada vez que cambia el día calendario entre dos mensajes
consecutivos (FR-005). La lista invertida la recorre desde el final (D-027).
