# Implementation Plan: Compartir evidencia de campo

**Branch**: `003-compartir-evidencia` (spec activa vía `.specify/feature.json`; se trabaja en `main`) | **Date**: 2026-11-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-compartir-evidencia/spec.md`

## Summary

Un menú "Compartir" en el detalle de la ubicación y en cada entrada permite enviar la
evidencia como **reporte formal en PDF** (folio consecutivo, encabezado con lugar,
responsable y cliente opcional, una sección por entrada con sus fotos) o como
**mensaje** (texto formateado con las fotos adjuntas), a través del menú de compartir
del sistema. Todo se genera sin internet; el usuario controla si salen las coordenadas
y ve un resumen antes de enviar. Decisiones D-015 a D-023 en [research.md](./research.md).

## Technical Context

**Language/Version**: Dart 3.4+, Flutter 3.47 estable

**Primary Dependencies**: existentes (`sqflite`, `path_provider`, `path`) + nuevas aprobadas en research: `pdf` (D-015), `share_plus` (D-016), `flutter_image_compress` (D-017); fuentes Noto Sans y Noto Emoji como assets (D-018)

**Storage**: SQLite existente; nueva tabla `ajustes` con migración a esquema v3 (D-019). PDF y copias temporales en `<temporal>/compartir/` (D-022)

**Testing**: `flutter_test` con repositorios y servicios falsos para los casos de uso (`PrepararEvidencia`, `ResumirEvidencia`, `FormatearMensaje`, `CompartirEvidencia`) y el folio; el PDF se valida con el quickstart

**Target Platform**: Android (principal); iOS compatible

**Project Type**: mobile-app

**Performance Goals**: reporte de 10 entradas × 3 fotos en < 10 s (SC-002) y < 10 MB (SC-003), sin congelar la interfaz

**Constraints**: offline para generar (FR-009); datos salen solo por acción del usuario (D-023); no se modifican `ubicaciones`, `entradas` ni `fotos`

**Scale/Scope**: 1 pantalla nueva, 1 hoja inferior, 1 diálogo; 4 casos de uso; 4 interfaces de dominio; hasta ~150 fotos por reporte

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumple | Evidencia |
|---|---|---|
| I. Ubicación como llave | ✅ | Se comparte una ubicación o una entrada de ella; no se agrupa por otro criterio |
| II. Offline y datos locales | ✅ | PDF y mensaje se generan sin red; fuentes incluidas (D-018); sin mapa en imagen; qué sale y a dónde documentado en D-023 |
| III. Dominio independiente | ✅ | `AjustesRepository`, `AlmacenFotos`, `GeneradorReporte`, `CompartirService` definidos en `domain/`; implementaciones en `data/`; casos de uso sin Flutter ([contracts/interfaces-dominio.md](./contracts/interfaces-dominio.md)) |
| IV. Ningún gadget rompe la app | ✅ | Fallas → `AppException`; cancelar no es error; foto faltante no cancela; sin app destino → "Guardar en el teléfono" |
| V. Simplicidad y alcance | ✅ | Tres paquetes nuevos, cada uno resuelve un requisito y está registrado en research; ajustes en SQLite existente en vez de otro paquete; sin gestor de estado |

**Post-diseño (re-check)**: ✅ sin cambios. Los paquetes nuevos quedan aprobados en D-015 a D-017 conforme a "Restricciones técnicas".

## Project Structure

### Documentation (this feature)

```text
specs/003-compartir-evidencia/
├── spec.md
├── plan.md              # Este archivo
├── research.md          # D-015 a D-023
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── interfaces-dominio.md
│   ├── formatos-salida.md
│   └── flujo-ui.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
assets/fonts/                         # NotoSans-Regular/Bold.ttf, NotoEmoji-Regular.ttf (+ OFL.txt)

lib/
├── app/
│   ├── app_container.dart            # + ajustes, almacenFotos, generadorReporte, compartir y casos de uso
│   └── routes.dart                   # + ruta /compartir (argumento: PaqueteEvidencia)
├── core/utils/formato.dart           # + enlaceMapa(lat, lng) (D-021)
├── domain/
│   ├── entities/
│   │   ├── paquete_evidencia.dart    # PaqueteEvidencia, FormatoCompartir, Destinatario, ResumenEvidencia
│   │   ├── responsable.dart
│   │   └── reporte_generado.dart
│   ├── repositories/ajustes_repository.dart
│   ├── services/
│   │   ├── almacen_fotos.dart
│   │   ├── generador_reporte.dart
│   │   └── compartir_service.dart    # + ResultadoCompartir
│   └── usecases/
│       ├── preparar_evidencia.dart
│       ├── resumir_evidencia.dart
│       ├── formatear_mensaje.dart
│       └── compartir_evidencia.dart
├── data/
│   ├── db/app_database.dart          # versión 3: tabla ajustes
│   ├── repositories/sqlite_ajustes_repository.dart
│   └── services/
│       ├── archivo_almacen_fotos.dart
│       ├── pdf_generador_reporte.dart     # pdf + flutter_image_compress + Isolate.run
│       └── share_plus_compartir_service.dart
└── presentation/
    ├── screens/
    │   ├── compartir_screen.dart
    │   └── ubicacion_detail_screen.dart   # + ícono Compartir y botón por entrada
    └── widgets/
        ├── hoja_formato_compartir.dart
        └── dialogo_responsable.dart

test/
└── domain/
    ├── preparar_evidencia_test.dart
    ├── resumir_evidencia_test.dart
    ├── formatear_mensaje_test.dart
    └── compartir_evidencia_test.dart
```

**Structure Decision**: Se mantiene la app Flutter única con capas `domain/`,
`data/`, `presentation/` de la spec 001. Las pruebas viven en `test/domain/` y usan
dobles de las interfaces. `test/widget_test.dart` (plantilla del contador, roto) se
reemplaza por estas pruebas.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| WhatsApp a veces ignora el texto cuando hay varias fotos | El texto también va como "asunto"; aceptado y anotado en el quickstart (escenario 6) |
| Reporte grande tarda más de 10 s en gama baja | Progreso visible; compresión nativa; si SC-002 falla en el teléfono físico, bajar a 1024 px |
| La migración v3 choca con la de notas de voz de la 002 | D-019: la 002 tomará la siguiente versión libre; actualizar su spec (FR-006 dice "versión 2") |

## Complexity Tracking

Sin violaciones de la constitución.
