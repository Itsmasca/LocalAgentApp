# Data Model: 001-bitacora-por-ubicacion

## Entidades

### Ubicacion (`lib/domain/entities/ubicacion.dart`)

| Campo | Tipo | Regla |
|---|---|---|
| id | int? | Asignado por SQLite |
| nombre | String | Obligatorio, no vacío (RN-02) |
| latitud, longitud | double | Posición al crearla |
| radioMetros | double | 75 por defecto (RN-01) |
| fotoPortada | String? | Ruta local; se asigna con la primera foto (RN-04) |
| creadaEn | DateTime | Momento de creación |

### Entrada (`lib/domain/entities/entrada.dart`)

| Campo | Tipo | Regla |
|---|---|---|
| id | int? | Asignado por SQLite |
| ubicacionId | int | Obligatorio; FK a Ubicacion |
| texto | String | Puede ir vacío solo si hay foto (RN-03) |
| imagenPath | String? | Ruta en la carpeta privada (RN-08) |
| latitud, longitud | double | Posición al guardar |
| creadaEn | DateTime | Momento de guardado |

Relación: Ubicacion 1 — * Entrada, con borrado en cascada (RN-06).

## Esquema SQLite (versión 1)

```sql
CREATE TABLE ubicaciones (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre        TEXT    NOT NULL,
  latitud       REAL    NOT NULL,
  longitud      REAL    NOT NULL,
  radio_metros  REAL    NOT NULL DEFAULT 75,
  foto_portada  TEXT,
  creada_en     TEXT    NOT NULL
);

CREATE TABLE entradas (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  ubicacion_id  INTEGER NOT NULL REFERENCES ubicaciones(id) ON DELETE CASCADE,
  texto         TEXT    NOT NULL,
  imagen_path   TEXT,
  latitud       REAL    NOT NULL,
  longitud      REAL    NOT NULL,
  creada_en     TEXT    NOT NULL
);

CREATE INDEX idx_entradas_ubicacion ON entradas(ubicacion_id);
```

`PRAGMA foreign_keys = ON` se activa en `onConfigure`.

## Reglas de negocio

| ID | Regla | Implementación |
|---|---|---|
| RN-01 | Asignar a la ubicación cuyo radio contiene la posición; si varias, la más cercana | `ResolverUbicacion` |
| RN-02 | Sin ubicación cercana → crear una con nombre obligatorio | `GuardarEntrada` |
| RN-03 | Entrada necesita texto o foto | `GuardarEntrada` |
| RN-04 | Primera foto = portada | `GuardarEntrada` |
| RN-05 | Entrada desde el detalle pertenece a ese lugar | `NuevaEntradaScreen` |
| RN-06 | Borrar ubicación borra sus entradas | SQLite `ON DELETE CASCADE` |
| RN-07 | Lista ordenada por actividad más reciente | `SqliteUbicacionRepository.obtenerTodas` |
| RN-08 | Imágenes copiadas a la carpeta privada | `ImagePickerMediaService` |
