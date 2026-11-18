# Implementation Plan: Bitácora de cada lugar en formato de chat

**Branch**: `004-bitacora-tipo-chat` (spec activa vía `.specify/feature.json`; se trabaja en `main`) | **Date**: 2026-11-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-bitacora-tipo-chat/spec.md`

## Summary

El detalle de cada ubicación se convierte en una **conversación**. Cada entrada se
muestra como mensaje destacado, con un mosaico de fotos, la etiqueta "Visita" y la fecha;
debajo van sus **observaciones** como burbujas simples. Una barra fija al pie permite
escribir o dictar una observación y enviarla en un toque, y tiene el botón **"Nueva
visita"**, que abre el formulario de entrada existente (aclaración B). Las observaciones
se guardan en una tabla SQLite nueva ligada a la entrada. Sin paquetes nuevos y sin
datos que salgan del teléfono. Decisiones D-024 a D-032 en [research.md](./research.md).

## Technical Context

**Language/Version**: Dart 3.4+, Flutter estable

**Primary Dependencies**: Solo los existentes (`sqflite`, `path`, `speech_to_text`, `flutter_map`, `latlong2`, `url_launcher`). Nada nuevo (D-028: visor con `InteractiveViewer`)

**Storage**: SQLite existente. Tabla nueva `observaciones` en el esquema **v4** (la v3 es `ajustes` de la 003) con migración acumulativa (D-025)

**Testing**: `flutter_test`: caso de uso `AgregarObservacion` con repositorios falsos y función pura `armarElementosConversacion`. La interfaz se valida con el [quickstart](./quickstart.md)

**Target Platform**: Android (principal); iOS compatible

**Project Type**: mobile-app

**Performance Goals**: conversación de 100 entradas y 300 observaciones visible en < 1 s (SC-003); observación enviada en < 10 s (SC-001)

**Constraints**: offline (SC-005); no cambia `entradas`, `fotos` ni `ubicaciones`; se conservan Hero, mapa interactivo y acceso a Google Maps (requisitos de entrega de la 001)

**Scale/Scope**: 1 pantalla reescrita, 1 pantalla nueva (visor), 6 widgets; 1 caso de uso; 1 repositorio nuevo y 2 métodos nuevos en uno existente

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumple | Evidencia |
|---|---|---|
| I. Ubicación como llave | ✅ | La conversación es por lugar; cada observación cuelga de una entrada de ese lugar (D-024); no se agrupa por sesión ni por chat global |
| II. Offline y datos locales | ✅ | Observaciones en SQLite local; ningún dato nuevo sale del teléfono (research, sección final) |
| III. Dominio independiente | ✅ | `Observacion`, `Visita`, `ObservacionRepository` y `AgregarObservacion` en `domain/` sin Flutter; RN-09 y RN-10 en el caso de uso, no en la pantalla; `SqliteObservacionRepository` en `data/`; solo `AppContainer` lo instancia ([contracts/interfaces-dominio.md](./contracts/interfaces-dominio.md)) |
| IV. Ningún gadget rompe la app | ✅ | Fallas → `AppException`; si guardar falla, el texto se conserva; dictado sin permiso → mensaje y escritura a mano; foto faltante → marcador |
| V. Simplicidad y alcance | ✅ | Sin paquetes nuevos ni gestor de estado (`setState` + `FutureBuilder`); sin paginación (YAGNI, D-026); se reutiliza el formulario de entrada (D-030) |

**Post-diseño (re-check)**: ✅ sin cambios. "Código y comentarios en español" se respeta en todos los nombres del contrato.

## Project Structure

### Documentation (this feature)

```text
specs/004-bitacora-tipo-chat/
├── spec.md
├── plan.md              # Este archivo
├── research.md          # D-024 a D-032
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── interfaces-dominio.md
│   └── flujo-ui.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── app_container.dart                 # + observaciones, agregarObservacion
│   └── routes.dart                        # + /fotos; /nueva-entrada devuelve Entrada?
├── domain/
│   ├── entities/
│   │   ├── observacion.dart               # NUEVO
│   │   └── visita.dart                    # NUEVO
│   ├── repositories/
│   │   ├── entrada_repository.dart        # + obtenerVisitas, obtenerMasReciente
│   │   └── observacion_repository.dart    # NUEVO
│   └── usecases/agregar_observacion.dart  # NUEVO (RN-09, RN-10)
├── data/
│   ├── db/app_database.dart               # + tabla observaciones (versión siguiente, D-025)
│   ├── models/observacion_model.dart      # NUEVO
│   └── repositories/
│       ├── sqlite_entrada_repository.dart     # + obtenerVisitas (3 consultas), obtenerMasReciente
│       ├── sqlite_observacion_repository.dart # NUEVO
│       └── sqlite_ubicacion_repository.dart   # obtenerTodas ordena con observaciones (D-032)
└── presentation/
    ├── conversacion/elementos_conversacion.dart  # NUEVO, Dart puro (D-026)
    ├── screens/
    │   ├── ubicacion_detail_screen.dart   # REESCRITA como conversación
    │   ├── nueva_entrada_screen.dart      # usa BotonDictado; pop(Entrada)
    │   ├── ubicaciones_list_screen.dart   # abre la conversación tras crear una entrada
    │   └── visor_fotos_screen.dart        # NUEVO
    └── widgets/
        ├── mensaje_entrada.dart           # NUEVO
        ├── burbuja_observacion.dart       # NUEVO
        ├── mosaico_fotos.dart             # NUEVO (reemplaza _CarruselFotos)
        ├── separador_dia.dart             # NUEVO
        ├── barra_redaccion.dart           # NUEVO
        ├── boton_dictado.dart             # NUEVO, extraído de nueva_entrada_screen
        └── hoja_mapa_ubicacion.dart       # NUEVO

test/
├── domain/agregar_observacion_test.dart
└── presentation/elementos_conversacion_test.dart
```

**Structure Decision**: Se mantiene la app Flutter única con las capas `domain/`,
`data/` y `presentation/` de la 001. La única carpeta nueva es
`presentation/conversacion/`, para la lógica pura de armado que se prueba sin widgets.
`test/widget_test.dart` (plantilla rota) se elimina si la 003 no lo ha hecho ya.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Choque de versión de esquema con la 003 (tiene reservada v3) | D-025: la que se implemente primero toma v3; migraciones `if (deVersion < N)`; actualizar `data-model.md` de la que quede en v4 |
| El reporte de la 003 no incluye las observaciones | Fuera de esta spec; al implementar la 003, `PrepararEvidencia` debe usar `obtenerVisitas` (anotar en la 003) |
| FR-015 menciona compartir (003) y nota de voz (002), que aún no existen en el código | El mensaje destacado reserva un menú ⋮; cada spec agrega ahí su acción cuando se implemente |
| Cientos de imágenes en el mosaico → memoria | `FotoLocal` con `cacheWidth` según el ancho de la celda; si SC-003 falla en gama baja, paginar por visitas |
| `reverse: true` invierte el orden mental al programar | Toda la lógica de orden vive en `armarElementosConversacion` (ascendente) y tiene prueba; la lista solo indexa al revés |

## Complexity Tracking

Sin violaciones de la constitución.
