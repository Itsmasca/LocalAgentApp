---
description: "Tareas de 001-bitacora-por-ubicacion"
---

# Tasks: Bitácora de campo organizada por ubicación

**Input**: Design documents from `/specs/001-bitacora-por-ubicacion/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: No solicitados en esta spec (pruebas del dominio en spec 002).

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Crear estructura por capas en `lib/` según plan.md
- [X] T002 Declarar dependencias en `pubspec.yaml`
- [ ] T003 Generar carpetas de plataforma (`flutter create .`) y agregar permisos Android/iOS del README

## Phase 2: Foundational

- [X] T004 `AppException` en `lib/core/errors/app_exception.dart`
- [X] T005 [P] Haversine en `lib/core/utils/geo_utils.dart`
- [X] T006 [P] Entidades en `lib/domain/entities/ubicacion.dart` y `entrada.dart`
- [X] T007 [P] Interfaces de repositorios en `lib/domain/repositories/`
- [X] T008 [P] Interfaces de gadgets en `lib/domain/services/device_services.dart`
- [X] T009 Esquema SQLite en `lib/data/db/app_database.dart`
- [X] T010 [P] Mapeos en `lib/data/models/`
- [X] T011 Repositorios SQLite en `lib/data/repositories/`
- [X] T012 Raíz de composición en `lib/app/app_container.dart`
- [X] T013 Rutas con nombre en `lib/app/routes.dart` y arranque en `lib/main.dart`

## Phase 3: User Story 1 - Registrar una entrada (P1) 🎯 MVP

- [X] T014 [US1] `ResolverUbicacion` (RN-01) en `lib/domain/usecases/resolver_ubicacion.dart`
- [X] T015 [US1] `GuardarEntrada` (RN-02 a RN-04) en `lib/domain/usecases/guardar_entrada.dart`
- [X] T016 [P] [US1] `GeolocatorLocationService` en `lib/data/services/`
- [X] T017 [P] [US1] `ImagePickerMediaService` (RN-08) en `lib/data/services/`
- [X] T018 [P] [US1] `SpeechToTextService` en `lib/data/services/`
- [X] T019 [US1] `NuevaEntradaScreen` en `lib/presentation/screens/nueva_entrada_screen.dart`

## Phase 4: User Story 2 - Historial de un lugar (P2)

- [X] T020 [P] [US2] `UrlMapLauncher` en `lib/data/services/url_map_launcher.dart`
- [X] T021 [US2] `UbicacionDetailScreen` con Hero, `flutter_map` y FutureBuilder

## Phase 5: User Story 3 - Lista de lugares (P3)

- [X] T022 [US3] `UbicacionesListScreen` con FutureBuilder y orden por actividad (RN-07)
- [X] T023 [P] [US3] `AppDrawer` en `lib/presentation/widgets/app_drawer.dart`

## Phase 6: Polish

- [X] T024 [P] Widgets compartidos `FotoLocal`, `VistaError`, `VistaVacia`
- [X] T025 [P] `docs/arquitectura.md` con diagrama de clases y flujo de datos
- [ ] T026 `flutter analyze` sin errores
- [ ] T027 Recorrido completo de `quickstart.md` en dispositivo físico

## Dependencies

Setup → Foundational → US1 → (US2, US3 en paralelo) → Polish.
