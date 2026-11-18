# Data Model: Compartir evidencia de campo

Esta función **no modifica** `ubicaciones`, `entradas` ni `fotos`. Solo las lee.
Agrega una tabla de ajustes (persistente) y entidades de dominio temporales.

## Persistente

### Tabla `ajustes` (nueva, esquema v3 — D-019)

| Columna | Tipo | Reglas |
|---|---|---|
| `clave` | TEXT PRIMARY KEY | Una de las claves de abajo |
| `valor` | TEXT NOT NULL | Texto; los booleanos se guardan como `'1'` / `'0'` |

Claves usadas:

| Clave | Valor | Por defecto | Origen |
|---|---|---|---|
| `responsable.nombre` | Texto, 1–80 caracteres, sin espacios al inicio/fin | (no existe) | FR-012 |
| `responsable.negocio` | Texto, 0–80 caracteres | (no existe) | FR-012 |
| `responsable.telefono` | Texto, 0–20 caracteres (dígitos, espacios, `+ - ( )`) | (no existe) | FR-012 |
| `compartir.incluir_coordenadas` | `'1'` / `'0'` | `'1'` | FR-006 |
| `folio.anio` | Año del último folio, p. ej. `'2026'` | (no existe) | D-020 |
| `folio.consecutivo` | Último número usado ese año, p. ej. `'7'` | (no existe) | D-020 |

Migración `onUpgrade` de v2 a v3: `CREATE TABLE ajustes (...)`. No mueve datos.
Una instalación nueva crea el esquema v3 completo en `onCreate`.

**Reservar folio** (atómico, en una transacción): leer `folio.anio` y
`folio.consecutivo`; si el año cambió, el consecutivo vuelve a 1; si no, +1;
escribir ambos y devolver `BC-AAAA-NNNN`. Se reserva justo antes de escribir el
PDF; si la generación falla, el número se pierde (huecos aceptables, como en una
factura cancelada).

## Dominio (sin persistencia)

### `Responsable`

| Campo | Tipo | Reglas |
|---|---|---|
| `nombre` | String | Obligatorio para guardar; 1–80 caracteres |
| `negocio` | String? | Opcional; vacío se guarda como ausente |
| `telefono` | String? | Opcional |

Si no hay `responsable.nombre`, el responsable "no existe" y el reporte omite esa
sección (historia 4, escenario 1).

### `Destinatario` (FR-017)

| Campo | Tipo | Reglas |
|---|---|---|
| `nombre` | String? | Opcional, 0–80 caracteres |
| `direccion` | String? | Opcional, 0–200 caracteres |

Vacío si ambos campos están vacíos; entonces no aparece en el reporte. Nunca se guarda.

### `FormatoCompartir`

`reporteFormal` | `mensaje` (FR-002).

### `PaqueteEvidencia`

Lo que el usuario decidió compartir. Se arma en la pantalla de compartir y se
descarta al terminar.

| Campo | Tipo | Reglas |
|---|---|---|
| `ubicacion` | Ubicacion | La ubicación de origen |
| `entradas` | List<Entrada> | ≥ 1; ordenadas de la más antigua a la más reciente (FR-003) |
| `formato` | FormatoCompartir | |
| `incluirCoordenadas` | bool | Valor inicial = ajuste `compartir.incluir_coordenadas` |
| `responsable` | Responsable? | Solo para `reporteFormal` |
| `destinatario` | Destinatario? | Solo para `reporteFormal` |
| `generadoEn` | DateTime | Momento de generación |

Derivados (para el resumen, FR-007):

- `totalFotos` = suma de `entrada.fotos.length`.
- `fotosFaltantes` = rutas cuyo archivo ya no existe (consultado con `AlmacenFotos`).
- `periodo` = fecha de la primera y la última entrada incluida.

Validaciones:

- `entradas` vacía → no se puede compartir ("Aún no hay entradas para compartir").
- Compartir desde una entrada = paquete con esa sola entrada (historia 2).

### `ReporteGenerado`

| Campo | Tipo | Notas |
|---|---|---|
| `folio` | String | `BC-AAAA-NNNN` |
| `rutaArchivo` | String | PDF en `<temporal>/compartir/` |
| `fotosOmitidas` | int | Fotos que no se pudieron incluir (archivo faltante) |

## Relaciones

```text
Ubicacion 1 ──< Entrada 1 ──< Foto          (existentes, solo lectura)
PaqueteEvidencia ──> Ubicacion, Entrada*    (temporal)
PaqueteEvidencia ──> Responsable?, Destinatario?
ReporteGenerado <── PaqueteEvidencia        (temporal; el archivo se limpia, D-022)
ajustes                                     (independiente)
```
