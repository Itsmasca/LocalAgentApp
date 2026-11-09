# Implementation Plan: Bitácora de campo organizada por ubicación

**Branch**: `001-bitacora-por-ubicacion` | **Date**: 2026-11-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-bitacora-por-ubicacion/spec.md`

## Summary

App Flutter de tres pantallas (lista, detalle, nueva entrada) que guarda entradas con
foto, dictado y GPS en SQLite, agrupadas por ubicación. La regla central (RN-01)
asigna cada entrada a la ubicación cuyo radio contiene la posición. Arquitectura por
capas con dominio independiente e inyección por constructor. Decisiones en
[research.md](./research.md).

## Technical Context

**Language/Version**: Dart 3.4+, Flutter estable

**Primary Dependencies**: sqflite, path_provider, image_picker, speech_to_text, geolocator, flutter_map, latlong2, url_launcher

**Storage**: SQLite local (`bitacora_campo.db`) + archivos de imagen en la carpeta privada de la app

**Testing**: `flutter_test` (pruebas unitarias del dominio previstas en spec 002)

**Target Platform**: Android (demostración); iOS compatible con los permisos del README

**Project Type**: mobile-app

**Performance Goals**: Historial de un lugar en < 1 s con 100 entradas

**Constraints**: Offline para registrar y consultar; sin API keys

**Scale/Scope**: Un usuario, cientos de ubicaciones, miles de entradas

## Constitution Check

| Principio | Cumple | Evidencia |
|---|---|---|
| I. Ubicación como llave | ✅ | Toda `Entrada` tiene `ubicacion_id`; RN-01 en `ResolverUbicacion` |
| II. Offline y datos locales | ✅ | SQLite + archivos locales; salidas a red documentadas en spec (mapa, dictado) |
| III. Dominio independiente | ✅ | `domain/` sin imports de Flutter; interfaces implementadas en `data/` |
| IV. Ningún gadget rompe la app | ✅ | `AppException` en todos los servicios; GPS con Reintentar |
| V. Simplicidad | ✅ | Sin paquetes de estado/DI; sin entidad Visita |

## Project Structure

### Documentation (this feature)

```text
specs/001-bitacora-por-ubicacion/
├── spec.md
├── plan.md          # Este archivo
├── research.md      # Decisiones D-001 a D-011
├── data-model.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── main.dart
├── app/            # app_container.dart (composición), routes.dart
├── core/           # errors/app_exception.dart, utils/
├── domain/         # entities/, repositories/ (interfaces), services/ (interfaces), usecases/
├── data/           # db/, models/, repositories/ (SQLite), services/ (plugins)
└── presentation/   # screens/, widgets/
docs/
└── arquitectura.md # Diagramas Mermaid
```

**Structure Decision**: Proyecto Flutter único con capas dentro de `lib/`. La
dirección de dependencias es `presentation → domain ← data`, y `app/` compone.

## Complexity Tracking

Sin violaciones de la constitución.
