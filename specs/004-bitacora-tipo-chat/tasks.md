---
description: "Tareas de 004-bitacora-tipo-chat"
---

# Tasks: Bitácora de cada lugar en formato de chat

**Input**: Design documents from `/specs/004-bitacora-tipo-chat/`

**Prerequisites**: plan.md, spec.md, research.md (D-024…D-032), data-model.md, contracts/, quickstart.md

**Tests**: Incluidas para `AgregarObservacion` y `armarElementosConversacion`, porque el plan (Technical Context → Testing) las define. La interfaz se valida con [quickstart.md](./quickstart.md).

**Organization**: Tareas agrupadas por historia de usuario para implementarlas y probarlas por separado.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Se puede hacer en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia a la que pertenece (US1…US3)
- Código y comentarios en español (constitución). Todo error técnico → `AppException` con mensaje para el usuario (principio IV). `domain/` no importa Flutter ni plugins (principio III). Sin paquetes nuevos (plan).

---

## Phase 1: Setup

**Purpose**: Base de pruebas.

- [X] T001 Ampliar `test/domain/fakes.dart` (ya existe, lo creó la spec 003) para que el doble de `EntradaRepository` implemente `obtenerVisitas` y `obtenerMasReciente`, y añadir un doble en memoria de `ObservacionRepository` que guarde en una lista y registre las llamadas; confirmar que las pruebas de la 003 (`test/domain/*_test.dart`) siguen compilando

---

## Phase 2: Foundational (bloquea todas las historias)

**Purpose**: Entidades, tabla `observaciones`, lectura de la conversación y armado de elementos que usan las tres historias.

**⚠️ CRITICAL**: Ninguna historia empieza hasta terminar esta fase.

### Dominio

- [X] T002 [P] Crear `lib/domain/entities/observacion.dart`: clase inmutable `Observacion` con `int? id`, `int entradaId`, `String texto`, `DateTime creadaEn`, constante `static const maxCaracteres = 2000` y `copyWith({int? id})` (data-model)
- [X] T003 [P] Crear `lib/domain/entities/visita.dart`: `Visita { final Entrada entrada; final List<Observacion> observaciones; }` (lista inmodificable, "orden ascendente por `creadaEn`") con `DateTime get ultimaActividad` = `creadaEn` de la última observación, o de la entrada si no tiene (data-model)
- [X] T004 [P] Crear `lib/domain/repositories/observacion_repository.dart` con `abstract interface class ObservacionRepository { Future<Observacion> crear(Observacion o); Future<void> eliminar(int id); }` y documentar los errores: `'No se pudo guardar la observación.'` y `'No se pudo eliminar la observación.'` ([contracts/interfaces-dominio.md](./contracts/interfaces-dominio.md))
- [X] T005 Ampliar `lib/domain/repositories/entrada_repository.dart` con `Future<List<Visita>> obtenerVisitas(int ubicacionId)` (visitas ascendentes con fotos y observaciones ascendentes; lista vacía si no hay entradas; error `'No se pudo cargar la conversación.'`) y `Future<Entrada?> obtenerMasReciente(int ubicacionId)`, sin cambiar `obtenerPorUbicacion` (la usa la spec 003) (depende de T002, T003)

### Persistencia

- [X] T006 En `lib/data/db/app_database.dart`: agregar la constante `tablaObservaciones = 'observaciones'`; subir `_version` de 3 a **4** (la v3 ya la usa la tabla `ajustes` de la spec 003); crear `_crearTablaObservaciones(DatabaseExecutor db)` con `id INTEGER PRIMARY KEY AUTOINCREMENT`, `entrada_id INTEGER NOT NULL REFERENCES entradas(id) ON DELETE CASCADE`, `texto TEXT NOT NULL`, `creada_en TEXT NOT NULL` y el índice `idx_observaciones_entrada ON observaciones(entrada_id, creada_en)`; llamarla desde `_crearEsquema` y desde `_migrar` dentro de `if (deVersion < 4)`, después del bloque `< 3` existente; añadir "- 4: tabla `observaciones`" al comentario de versiones (D-024, D-025)
- [X] T007 [P] Crear `lib/data/models/observacion_model.dart` con `ObservacionModel.fromMap(Map<String, Object?>)` y `toMap(Observacion)`, con `creada_en` como `toIso8601String()` / `DateTime.parse`, igual que `EntradaModel` (depende de T002)
- [X] T008 Implementar `obtenerVisitas` y `obtenerMasReciente` en `lib/data/repositories/sqlite_entrada_repository.dart`. `obtenerVisitas` hace exactamente 3 consultas: entradas `ORDER BY creada_en ASC`, fotos del lugar (reutilizar la consulta agrupada actual) y observaciones del lugar con `JOIN entradas` y `ORDER BY o.entrada_id, o.creada_en`; las agrupa en `Visita`. `obtenerMasReciente` usa `ORDER BY creada_en DESC LIMIT 1` y carga sus fotos. Envolver los errores en `AppException` (D-026) (depende de T005, T006, T007)
- [X] T009 [P] Crear `lib/data/repositories/sqlite_observacion_repository.dart` con `crear` (insert y devolver `copyWith(id:)`) y `eliminar` (`delete where id = ?`), con los mensajes de T004 (depende de T004, T006, T007)
- [X] T010 Registrar `ObservacionRepository observaciones` en `lib/app/app_container.dart` (constructor y `produccion()` con `SqliteObservacionRepository(db)`) (depende de T009)

### Armado de la conversación (Dart puro)

- [X] T011 [P] Crear `lib/presentation/conversacion/elementos_conversacion.dart` **sin importar Flutter**, con `sealed class ElementoConversacion` y sus variantes `SeparadorDia(DateTime dia)`, `MensajeEntrada(Entrada entrada)` y `MensajeObservacion(Observacion observacion)`, y la función `List<ElementoConversacion> armarElementosConversacion(List<Visita> visitas)`: en orden cronológico, la entrada y luego sus observaciones; un `SeparadorDia` antes del primer mensaje y cada vez que cambia el día calendario entre dos mensajes consecutivos (FR-005, D-026) (depende de T002, T003)
- [X] T012 [P] Crear `test/presentation/elementos_conversacion_test.dart`: lista vacía → `[]`; una visita sin observaciones → `[SeparadorDia, MensajeEntrada]`; entrada y 2 observaciones el mismo día → un solo separador; una observación al día siguiente de su entrada → separador entre ambas; dos visitas en días distintos → orden y separadores correctos (depende de T011)

**Checkpoint**: `flutter test` pasa; la app abre y migra sin errores (la interfaz aún no cambia).

---

## Phase 3: User Story 1 - Ver el historial de un lugar como conversación (Priority: P1) 🎯 MVP

**Goal**: El detalle del lugar muestra las entradas como mensajes destacados con mosaico de fotos y las observaciones como burbujas simples, en una lista invertida que arranca en lo más reciente.

**Independent Test**: Con una ubicación de 3 entradas (0, 1 y 4 fotos), abrirla y verificar mensajes destacados ascendentes, la vista abajo, separadores de fecha, la cuadrícula 2×2 y el visor al tocar una foto (quickstart 1, 2, 14).

### Implementation for User Story 1

- [X] T013 [P] [US1] Crear `lib/presentation/widgets/mosaico_fotos.dart`: `MosaicoFotos({required List<String> fotos, required void Function(int indice) onTocar})`. Con 1 foto, todo el ancho en proporción 4:3; con 2, lado a lado; con 3, una grande a la izquierda y dos apiladas; con 4 o más, cuadrícula 2×2 con la cuarta celda cubierta por "+N" (N = fotos − 4 + 1). Cada celda usa `FotoLocal` (D-028)
- [X] T014 [P] [US1] Añadir a `lib/presentation/widgets/foto_local.dart` un parámetro opcional `int? cacheWidth` que se pase a `Image.file` para no decodificar fotos a resolución completa en el mosaico (plan, Riesgos); `MosaicoFotos` lo calcula con `MediaQuery.devicePixelRatio` × el ancho de la celda
- [X] T015 [P] [US1] Crear `lib/presentation/screens/visor_fotos_screen.dart` con `VisorFotosArgs(List<String> fotos, int inicial)` y `VisorFotosScreen`: fondo negro, `PageView` que empieza en `inicial`, `InteractiveViewer` por foto, contador "2/5" y botón de cerrar; las fotos que faltan muestran el marcador de `FotoLocal` (FR-011, contrato flujo-ui)
- [X] T016 [US1] Registrar la ruta `AppRoutes.fotos = '/fotos'` (argumento `VisorFotosArgs`) en `lib/app/routes.dart` (depende de T015)
- [X] T017 [P] [US1] Crear `lib/presentation/widgets/mensaje_entrada.dart`: `MensajeEntrada` (widget; importar el elemento con prefijo para evitar el choque de nombres) con tarjeta a todo el ancho menos márgenes, fondo `primaryContainer` con elevación, `MosaicoFotos` arriba si hay fotos, etiqueta "VISITA · " + `formatearFecha`, texto en `bodyLarge`, y un `VoidCallback? onCompartir`: si viene, se muestra un `TextButton.icon` "Compartir" al pie de la tarjeta y `onLongPress` de la tarjeta lo llama (conserva el comportamiento de la spec 003 en `_TarjetaEntrada`, FR-015). Al tocar una foto se navega a `/fotos` (FR-002) (depende de T013, T016)
- [X] T018 [P] [US1] Crear `lib/presentation/widgets/burbuja_observacion.dart`: burbuja de ancho máximo 80 % con sangría izquierda de 24 px, fondo `surfaceContainerHighest` plano, texto en `bodyMedium`, hora `hh:mm` en `labelSmall` y un callback opcional `onMantener` (FR-003)
- [X] T019 [P] [US1] Crear `lib/presentation/widgets/separador_dia.dart`: texto centrado "Hoy", "Ayer" o `d mmm aaaa` (meses abreviados en español, sin paquetes), entre líneas finas (FR-005)
- [X] T020 [P] [US1] Crear `lib/presentation/widgets/hoja_mapa_ubicacion.dart` y la función `mostrarHojaMapa(BuildContext, Ubicacion, MapLauncher)`: `showModalBottomSheet` con un `FlutterMap` de 240 px y su marcador (mover la configuración actual de `ubicacion_detail_screen.dart`, incluido `userAgentPackageName`), `formatearCoordenadas` y el botón "Abrir en Google Maps", que muestra `mostrarError` si falla (D-031)
- [X] T021 [US1] Reescribir `lib/presentation/screens/ubicacion_detail_screen.dart` como conversación, **conservando lo de la spec 003**: el parámetro `prepararEvidencia`, el método `_compartir({Entrada? soloEsta})`, el ícono "Compartir evidencia" de la AppBar (deshabilitado si no hay visitas, ahora calculado sobre `List<Visita>`) y `onCompartir: () => _compartir(soloEsta: visita.entrada)` en cada `MensajeEntrada`. AppBar con `Hero(tag: _u.heroTag)` alrededor de un avatar circular de 40 px (`FotoLocal`) más el nombre, y el ícono de mapa, que ahora llama a `mostrarHojaMapa` en lugar de abrir Google Maps directamente. `FutureBuilder` sobre `entradas.obtenerVisitas(_u.id!)` con los estados de carga, `VistaError` con Reintentar, y vacío (`VistaVacia` "Aún no hay visitas en este lugar"). Con datos, `armarElementosConversacion` y `ListView.builder(reverse: true)` que indexa `elementos[elementos.length - 1 - i]` y pinta `SeparadorDia`, `MensajeEntrada` o `BurbujaObservacion`. Conservar temporalmente el FAB "Agregar aquí" hasta US3. Eliminar `_TarjetaEntrada` y `_CarruselFotos` (FR-001, FR-013, D-027) (depende de T011, T017–T020)

**Checkpoint**: US1 funciona por sí sola; quickstart 1, 2, 12 (foto faltante) y 14 pasan.

---

## Phase 4: User Story 2 - Agregar una observación rápida (Priority: P1)

**Goal**: Escribir o dictar una observación en la barra fija y enviarla en un toque; se guarda bajo la entrada más reciente, sube el lugar en la lista y se puede eliminar.

**Independent Test**: En un lugar con una entrada, enviar "Se cambió el capacitor"; aparece abajo con la hora y sigue ahí tras reiniciar la app (quickstart 3, 4, 5, 9, 10, 11).

### Tests for User Story 2

- [X] T022 [P] [US2] Crear `test/domain/agregar_observacion_test.dart` con los dobles de `test/domain/fakes.dart`: `''` y `'   '` → `AppException('Escribe la observación.')` sin llamar a `crear`; 2 001 caracteres → `AppException('La observación puede tener como máximo 2000 caracteres.')`; lugar sin entradas → `AppException('Registra primero una visita en este lugar.')`; con 2 entradas, se guarda con `entradaId` de la más reciente y `texto` recortado (RN-09, RN-10)

### Implementation for User Story 2

- [X] T023 [US2] Crear `lib/domain/usecases/agregar_observacion.dart`: `AgregarObservacion(EntradaRepository, ObservacionRepository)` con `Future<Observacion> call({required int ubicacionId, required String texto})` que aplica, en ese orden, RN-09 (texto no vacío tras `trim` y como máximo `Observacion.maxCaracteres`) y RN-10 (`obtenerMasReciente`; si es `null`, error) con los mensajes exactos de T022, y luego `crear(Observacion(entradaId: …, texto: trim, creadaEn: DateTime.now()))` (depende de T022)
- [X] T024 [US2] Registrar `agregarObservacion` en `lib/app/app_container.dart`, construido con `entradas` y `observaciones` (depende de T023)
- [X] T025 [P] [US2] Extraer el dictado de `lib/presentation/screens/nueva_entrada_screen.dart` (`_alternarDictado`, `_escuchando`, `_textoAntesDeDictar`, la detención en `dispose` y antes de guardar) a `lib/presentation/widgets/boton_dictado.dart`: `BotonDictado({required SpeechService speech, required TextEditingController controlador})`, con ícono de micrófono que cambia mientras escucha, el mismo manejo de `onTerminado` y `onError` con `mostrarError`, y `detener()` accesible mediante `GlobalKey<BotonDictadoState>`. Reemplazar su uso en `nueva_entrada_screen.dart` sin cambiar el comportamiento (D-029)
- [X] T026 [US2] Crear `lib/presentation/widgets/barra_redaccion.dart`: `BarraRedaccion({required SpeechService speech, required Future<void> Function(String texto) onEnviar, VoidCallback? onNuevaVisita, bool habilitada = true})` en `SafeArea`, con un hueco a la izquierda para "Nueva visita" (se llena en US3), un `TextField` multilínea de 1 a 5 líneas con `maxLength: Observacion.maxCaracteres` y contador visible solo a partir de 1 800 caracteres, `BotonDictado` y un `IconButton` de enviar deshabilitado si `texto.trim().isEmpty` o mientras se envía. Si `onEnviar` sale bien, vacía el campo; si lanza, conserva el texto (el que llama muestra el error). Con `habilitada: false`, el campo queda deshabilitado con la pista "Registra una visita para agregar observaciones" (FR-006–FR-008) (depende de T025)
- [X] T027 [US2] Integrar en `lib/presentation/screens/ubicacion_detail_screen.dart`: recibir `SpeechService speech`, `AgregarObservacion agregarObservacion` y `ObservacionRepository observaciones` por constructor; pasarlos desde `lib/app/routes.dart`; poner `BarraRedaccion` en `bottomNavigationBar` o al pie de un `Column` con `resizeToAvoidBottomInset`, con `habilitada` solo si hay visitas; `onEnviar` llama a `agregarObservacion` y recarga; ante un error, `mostrarError` y relanzar para que la barra conserve el texto (FR-006, FR-009) (depende de T021, T024, T026)
- [X] T028 [US2] Eliminar observación en `lib/presentation/screens/ubicacion_detail_screen.dart`: `onMantener` de `BurbujaObservacion` abre un menú con "Eliminar" y luego un `AlertDialog` de confirmación ("¿Eliminar esta observación?" con Cancelar / Eliminar); al confirmar, `observaciones.eliminar(id)` y recargar; los errores van a `mostrarError` (FR-012, D-032) (depende de T027)
- [X] T029 [P] [US2] Cambiar el orden de `obtenerTodas` en `lib/data/repositories/sqlite_ubicacion_repository.dart` para que la actividad sea el `MAX` entre `u.creada_en`, `(SELECT MAX(e.creada_en) FROM entradas e WHERE e.ubicacion_id = u.id)` y `(SELECT MAX(o.creada_en) FROM observaciones o JOIN entradas e ON e.id = o.entrada_id WHERE e.ubicacion_id = u.id)`, usando subconsultas en vez de `LEFT JOIN … GROUP BY` y `COALESCE` para los `NULL`, con `ORDER BY` descendente (FR-014, D-032) (depende de T006)
- [X] T030 [US2] Al volver de la conversación a `lib/presentation/screens/ubicaciones_list_screen.dart`, recargar siempre la lista (`await Navigator.pushNamed(...)` en `_abrirDetalle` y luego `_recargar()`) para que se vea el nuevo orden (FR-014) (depende de T029)

**Checkpoint**: US1 y US2 funcionan; `flutter test` pasa; quickstart 3, 4, 5, 9, 10 y 11 pasan.

---

## Phase 5: User Story 3 - Registrar una entrada nueva desde la conversación (Priority: P2)

**Goal**: El botón "Nueva visita" de la barra abre el formulario existente; la entrada nueva aparece como mensaje destacado y las observaciones siguientes quedan bajo ella. El alta desde la lista abre la conversación del lugar.

**Independent Test**: En un lugar con una entrada antigua, crear una "Nueva visita" con 2 fotos, enviar "Listo" y ver la burbuja bajo la entrada nueva; cancelar otra "Nueva visita" no crea nada (quickstart 6, 7, 8).

### Implementation for User Story 3

- [X] T031 [US3] En `lib/presentation/screens/nueva_entrada_screen.dart`, devolver la `Entrada` guardada: `Navigator.pop(context, entradaGuardada)` en lugar de `true`; cambiar la ruta en `lib/app/routes.dart` a `MaterialPageRoute<Entrada?>` y actualizar su comentario (contrato flujo-ui)
- [X] T032 [US3] En `lib/presentation/widgets/barra_redaccion.dart`, llenar el hueco con un `IconButton` (ícono `Icons.add_a_photo_outlined`, tooltip "Nueva visita") que llama a `onNuevaVisita`; siempre está habilitado, aunque no haya visitas (RN-12, D-029) (depende de T026)
- [X] T033 [US3] En `lib/presentation/screens/ubicacion_detail_screen.dart`: quitar el FAB "Agregar aquí"; crear `_nuevaVisita()`, que hace `pushNamed<Entrada?>(AppRoutes.nuevaEntrada, arguments: _u)` y, si no es `null`, recarga (la lista invertida queda en lo más reciente); pasarlo como `onNuevaVisita`; en el estado vacío, añadir a `VistaVacia` un `FilledButton` "Registrar primera visita" que llama a `_nuevaVisita` (FR-010, US3-1, US3-5) (depende de T031, T032, T027)
- [X] T034 [US3] En `lib/presentation/screens/ubicaciones_list_screen.dart`, `_nuevaEntrada()` recibe `Entrada?`; si no es `null`, `ubicaciones.obtenerPorId(entrada.ubicacionId)` y luego `_abrirDetalle(ubicacion)` (que recarga al volver, T030); errores con `mostrarError` (US3-6) (depende de T031, T030)
- [X] T035 [P] [US3] En `lib/presentation/widgets/app_drawer.dart`, el atajo a `AppRoutes.nuevaEntrada` debe pasar por el mismo flujo: usar el callback `onNuevaEntrada` de la lista en lugar de `pushNamed` directo, para que también abra la conversación (US3-6) (depende de T034)

**Checkpoint**: Las tres historias funcionan; quickstart 6, 7 y 8 pasan.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T036 Correr `flutter analyze` y `flutter test` y corregir las advertencias en los archivos tocados
- [ ] T037 Crear un sembrado solo para depuración en `tool/sembrar_conversacion.dart` (o un método `assert`-only en `lib/main.dart`, si es más simple), que cree un lugar con 100 entradas y 300 observaciones, y medir SC-003 (quickstart 13); si pasa de 1 s, anotar en `research.md` la mitigación (paginar por visitas)
- [ ] T038 Ejecutar en un dispositivo Android los escenarios 1 a 14 de `specs/004-bitacora-tipo-chat/quickstart.md`, incluida la migración desde una instalación v2 y el modo avión
- [X] T039 [P] Añadir en `specs/003-compartir-evidencia/plan.md` (Riesgos) la nota: "La spec 004 agrega observaciones (esquema v4); el reporte y el mensaje aún no las incluyen. Seguimiento: `PrepararEvidencia` debe usar `EntradaRepository.obtenerVisitas` e incluirlas bajo su entrada"
- [X] T040 [P] Actualizar `CHANGELOG.md` con el resumen de la spec 004 (conversación, observaciones, Nueva visita, tabla `observaciones` en vN) y cambiar el **Status** de `specs/004-bitacora-tipo-chat/spec.md` a "Implemented"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias.
- **Foundational (Phase 2)**: depende de Setup; **bloquea** todas las historias.
- **US1 (Phase 3)**: depende de Foundational. Es el MVP.
- **US2 (Phase 4)**: depende de Foundational y de T021 (pantalla de conversación) para T027 y T028. T022–T026 y T029 pueden avanzar en paralelo con US1.
- **US3 (Phase 5)**: depende de T026 y T027 (barra integrada). T031 puede adelantarse.
- **Polish (Phase 6)**: depende de las historias que se entreguen.

### Within Each Story

- Prueba (T022) antes del caso de uso (T023), que debe fallar primero.
- Widgets [P] antes de la pantalla que los integra (T021, T027, T033).
- `routes.dart` y `app_container.dart` se tocan en varias tareas: no paralelizarlas entre sí.

### Parallel Opportunities

- Foundational: T002, T003 y T004 juntos; después T007, T009 y T011/T012.
- US1: T013, T014, T015, T018, T019 y T020 juntos; después T017; al final T021.
- US2: T022, T025 y T029 juntos y en paralelo con US1.
- Polish: T039 y T040.

---

## Parallel Example: Foundational

```text
Tarea: "T002 Crear Observacion en lib/domain/entities/observacion.dart"
Tarea: "T003 Crear Visita en lib/domain/entities/visita.dart"
Tarea: "T004 Crear ObservacionRepository en lib/domain/repositories/observacion_repository.dart"
```

## Parallel Example: User Story 1

```text
Tarea: "T013 MosaicoFotos en lib/presentation/widgets/mosaico_fotos.dart"
Tarea: "T015 VisorFotosScreen en lib/presentation/screens/visor_fotos_screen.dart"
Tarea: "T018 BurbujaObservacion en lib/presentation/widgets/burbuja_observacion.dart"
Tarea: "T019 SeparadorDia en lib/presentation/widgets/separador_dia.dart"
Tarea: "T020 HojaMapaUbicacion en lib/presentation/widgets/hoja_mapa_ubicacion.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 + Phase 2 (tabla, lectura y armado probados).
2. Phase 3: la conversación de solo lectura reemplaza el detalle; "Agregar aquí" sigue funcionando.
3. **Parar y validar**: quickstart 1, 2, 12 y 14. Ya se puede mostrar el nuevo estilo.

### Incremental Delivery

1. US1 → historial como chat (demo visual).
2. US2 → observaciones rápidas: el ahorro de esfuerzo que justifica la función.
3. US3 → "Nueva visita" en la barra y la conversación tras el alta desde la lista; se retira el FAB.
4. Polish → rendimiento, quickstart completo, CHANGELOG.

---

## Notes

- Commits con referencia a la spec y la tarea, por ejemplo `feat(chat): mosaico de fotos [004/T013]`.
- Marcar `[X]` en este archivo al terminar cada tarea (constitución, flujo de desarrollo).
- La spec 003 ya está en el código (esquema v3, `test/domain/fakes.dart`, compartir en el detalle): esta spec usa v4 y no debe romper sus pruebas ni su flujo de compartir.
