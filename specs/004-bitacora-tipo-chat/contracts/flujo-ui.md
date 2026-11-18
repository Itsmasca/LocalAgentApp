# Contrato: flujo de interfaz

## Rutas

| Ruta | Argumento | Cambio |
|---|---|---|
| `/` | — | Al volver de `/nueva-entrada` con una `Entrada`, abre `/ubicacion` de su lugar (US3-6) |
| `/ubicacion` | `Ubicacion` | **Se reemplaza** por la conversación (misma ruta y clase `UbicacionDetailScreen`) |
| `/nueva-entrada` | `Ubicacion?` | Devuelve la `Entrada` guardada (antes `true`), o `null` si se canceló |
| `/fotos` | `VisorFotosArgs(fotos, inicial)` | **Nueva**: visor a pantalla completa |

## Pantalla de conversación (`/ubicacion`)

```text
┌──────────────────────────────────────────┐
│ ←  (◉) Casa López                  🗺    │  AppBar: Hero avatar + nombre; mapa → hoja inferior
├──────────────────────────────────────────┤
│              ── 12 nov 2026 ──           │  SeparadorDia
│ ┌──────────────────────────────────────┐ │
│ │ [ foto grande ][ foto ]              │ │  MensajeEntrada: tarjeta con fondo de color
│ │                [ +3   ]              │ │  primario suave, mosaico de fotos (D-028)
│ │ VISITA · 12/11/2026 10:42            │ │  etiqueta "Visita" + fecha y hora
│ │ Mantenimiento minisplit recámara.    │ │  texto completo
│ └──────────────────────────────────────┘ │
│   ┌──────────────────────────┐           │
│   │ El cliente pidió presup. │ 10:55     │  MensajeObservacion: burbuja simple,
│   └──────────────────────────┘           │  sangrada bajo su entrada, sin encabezado
│              ── Hoy ──                   │
│   ┌────────────────────┐                 │
│   │ Sigue goteando     │ 09:10           │
│   └────────────────────┘                 │
├──────────────────────────────────────────┤
│ [📷] [ Escribe una observación…  ] 🎤 ➤ │  BarraRedaccion (fija; sube con el teclado)
└──────────────────────────────────────────┘
```

### Jerarquía visual (FR-002, FR-003, SC-002)

| | MensajeEntrada | MensajeObservacion |
|---|---|---|
| Ancho | 100 % menos márgenes | Máximo 80 %, sangría izquierda de 24 px |
| Fondo | `primaryContainer`, con elevación | `surfaceContainerHighest`, plano |
| Contenido | Mosaico de fotos, etiqueta "VISITA", fecha y hora, texto `bodyLarge` | Texto `bodyMedium` y hora `labelSmall` |
| Acciones | Tocar una foto → `/fotos`; menú ⋮ con un hueco reservado para "Compartir" (spec 003) y la nota de voz (spec 002) si existen (FR-015) | Mantener presionada → "Eliminar" → diálogo de confirmación |

Separador de fecha: "Hoy", "Ayer" o `d mmm aaaa`.

### Estados

| Estado | Vista |
|---|---|
| Cargando | Indicador centrado |
| Error al cargar | `VistaError` con "Reintentar" |
| Sin entradas | `VistaVacia` "Aún no hay visitas en este lugar" + botón **Registrar primera visita**; el campo de texto queda deshabilitado con la pista "Registra una visita para agregar observaciones" |
| Con visitas | Lista invertida (D-027) |

### Barra de redacción (D-029)

| Acción | Resultado |
|---|---|
| 📷 "Nueva visita" | `/nueva-entrada` con la ubicación fija; al volver con una `Entrada` se recarga y queda al final |
| Escribir | Enviar se habilita si `trim` no queda vacío; el contador aparece a partir de 1 800 caracteres |
| 🎤 | `BotonDictado`: el texto dictado se agrega al campo; con el permiso negado o sin reconocedor se muestra un mensaje y se sigue escribiendo a mano |
| ➤ | `AgregarObservacion`. Si sale bien, el campo se vacía y aparece la burbuja. Si falla, el texto se queda y se muestra un SnackBar con el mensaje |

### Hoja de mapa (D-031)

`flutter_map` de 240 px de alto con el marcador del lugar, las coordenadas
(`formatearCoordenadas`) y el botón "Abrir en Google Maps" (`MapLauncher`).

## Visor de fotos (`/fotos`)

Fondo negro, `PageView` que empieza en `inicial`, `InteractiveViewer` para zoom, contador
"2/5" y botón de cerrar. Una foto que falta se muestra con el marcador de `FotoLocal`.
