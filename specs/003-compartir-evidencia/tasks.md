---
description: "Tareas de 003-compartir-evidencia"
---

# Tasks: Compartir evidencia de campo

**Input**: Design documents from `/specs/003-compartir-evidencia/`

**Prerequisites**: plan.md, spec.md, research.md (D-015…D-023), data-model.md, contracts/, quickstart.md

**Tests**: Incluidas para los casos de uso del dominio, porque el plan (Technical Context → Testing) las define con dobles de las interfaces. El PDF y la interfaz se validan con [quickstart.md](./quickstart.md).

**Organization**: Tareas agrupadas por historia de usuario para implementarlas y probarlas por separado.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Se puede hacer en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia a la que pertenece (US1…US4)
- Código y comentarios en español (constitución). Todo error técnico → `AppException` con mensaje para el usuario (principio IV). `domain/` no importa Flutter ni plugins (principio III).

---

## Phase 1: Setup

**Purpose**: Dependencias, fuentes y base de pruebas.

- [ ] T001 Agregar `pdf`, `share_plus` y `flutter_image_compress` con `flutter pub add pdf share_plus flutter_image_compress`; verificar que `pubspec.yaml` y `pubspec.lock` quedan con versiones fijadas (D-015, D-016, D-017)
- [ ] T002 [P] Descargar `NotoSans-Regular.ttf`, `NotoSans-Bold.ttf` y `NotoEmoji-Regular.ttf` (monocroma, ~2 MB) con su `OFL.txt` a `assets/fonts/` y declararlas en la sección `flutter: assets:` de `pubspec.yaml` (D-018)
- [ ] T003 [P] Borrar `test/widget_test.dart` (plantilla del contador; referencia `MyApp`, que no existe) y crear `test/domain/fakes.dart` con dobles en memoria de `UbicacionRepository`, `EntradaRepository`, `AjustesRepository`, `AlmacenFotos`, `GeneradorReporte` y `CompartirService` que registren las llamadas recibidas

---

## Phase 2: Foundational (bloquea todas las historias)

**Purpose**: Entidades, interfaces, ajustes persistentes y casos de uso que todas las historias necesitan.

**⚠️ CRITICAL**: Ninguna historia empieza hasta terminar esta fase.

### Entidades e interfaces de dominio

- [ ] T004 [P] Crear `Responsable` en `lib/domain/entities/responsable.dart`: `nombre` (String, obligatorio, "1–80 caracteres"), `negocio` (String?, "Opcional; vacío se guarda como ausente"), `telefono` (String?, opcional); constructor que recorta espacios y valida, lanzando `AppException` si el nombre queda vacío o supera 80
- [ ] T005 [P] Crear en `lib/domain/entities/paquete_evidencia.dart`: `enum FormatoCompartir { reporteFormal, mensaje }`; `Destinatario` (`nombre` String? "0–80 caracteres", `direccion` String? "0–200 caracteres", getter `estaVacio` cuando ambos están vacíos); `PaqueteEvidencia` (`ubicacion`, `entradas` "≥ 1; ordenadas de la más antigua a la más reciente", `formato`, `incluirCoordenadas`, `responsable?`, `destinatario?`, `generadoEn`, getters `totalFotos` y `periodo` (primera y última `creadaEn`), y `copyWith`); `ResumenEvidencia` (`entradas`, `fotos`, `fotosFaltantes` List<String>, `incluyeCoordenadas`)
- [ ] T006 [P] Crear `ReporteGenerado` (`folio` "BC-AAAA-NNNN", `rutaArchivo`, `fotosOmitidas`) en `lib/domain/entities/reporte_generado.dart`
- [ ] T007 [P] Crear la interfaz `AjustesRepository` en `lib/domain/repositories/ajustes_repository.dart` con las 6 operaciones de [contracts/interfaces-dominio.md](./contracts/interfaces-dominio.md#ajustesrepository-domainrepositories) (`obtenerResponsable`, `guardarResponsable`, `borrarResponsable`, `incluirCoordenadas` "true por defecto", `guardarIncluirCoordenadas`, `reservarFolio(DateTime)`)
- [ ] T008 [P] Crear la interfaz `AlmacenFotos` con `Future<bool> existe(String ruta)` en `lib/domain/services/almacen_fotos.dart`
- [ ] T009 [P] Crear la interfaz `CompartirService` (`compartirArchivo(ruta, {asunto})`, `compartirMensaje(texto, fotos)`, `limpiarTemporales()`) y `enum ResultadoCompartir { enviado, cancelado, noDisponible }` en `lib/domain/services/compartir_service.dart`
- [ ] T010 [P] Crear la interfaz `GeneradorReporte` con `Future<ReporteGenerado> generar(PaqueteEvidencia paquete, String folio, {void Function(double)? onProgreso})` en `lib/domain/services/generador_reporte.dart`; documentar que una foto faltante no es error (cuenta en `fotosOmitidas`)
- [ ] T011 [P] Agregar `String enlaceMapa(double lat, double lng)` que devuelva `https://www.google.com/maps/search/?api=1&query=LAT,LNG` en `lib/core/utils/formato.dart` (D-021)

### Persistencia de ajustes (esquema v3)

- [ ] T012 Subir `_version` a 3 en `lib/data/db/app_database.dart`: agregar `static const tablaAjustes = 'ajustes'`; en `onCreate` y en `_migrar` (si `deVersion < 3`) crear `CREATE TABLE ajustes (clave TEXT PRIMARY KEY, valor TEXT NOT NULL)`; actualizar el comentario de versiones (v3 = ajustes) (D-019)
- [ ] T013 Implementar `SqliteAjustesRepository` en `lib/data/repositories/sqlite_ajustes_repository.dart` con las claves de [data-model.md](./data-model.md#tabla-ajustes-nueva-esquema-v3--d-019) (`responsable.nombre`, `responsable.negocio`, `responsable.telefono`, `compartir.incluir_coordenadas` con `'1'`/`'0'` y `'1'` por defecto, `folio.anio`, `folio.consecutivo`); `reservarFolio` dentro de `db.transaction`: si el año cambió el consecutivo vuelve a 1, si no +1, y devuelve `BC-AAAA-NNNN` con 4 dígitos (D-020); depende de T007 y T012
- [ ] T014 [P] Implementar `ArchivoAlmacenFotos` (con `File(ruta).exists()`) en `lib/data/services/archivo_almacen_fotos.dart`

### Compartir con el sistema

- [ ] T015 [P] Implementar `SharePlusCompartirService` en `lib/data/services/share_plus_compartir_service.dart`: `compartirArchivo` y `compartirMensaje` usan `share_plus` (mensaje = texto + fotos como `XFile`, el texto también como `subject`); mapear el estado de `ShareResult` a `enviado`, `cancelado` (dismissed) y `noDisponible` (unavailable); `limpiarTemporales` borra el contenido de `<getTemporaryDirectory()>/compartir/`; envolver errores en `AppException('No se pudo abrir el menú de compartir.')` (D-016, D-022)

### Casos de uso comunes

- [ ] T016 Implementar `PrepararEvidencia` en `lib/domain/usecases/preparar_evidencia.dart`: `call(Ubicacion, {Entrada? soloEsta, required FormatoCompartir formato})` carga las entradas con `EntradaRepository.obtenerPorUbicacion` (o usa `soloEsta`), las ordena de la más antigua a la más reciente, toma `incluirCoordenadas` y `obtenerResponsable` de `AjustesRepository`, y lanza `AppException('Aún no hay entradas para compartir.')` si no hay entradas
- [ ] T017 Implementar `ResumirEvidencia` en `lib/domain/usecases/resumir_evidencia.dart`: devuelve `ResumenEvidencia` contando entradas y fotos, y listando en `fotosFaltantes` las rutas para las que `AlmacenFotos.existe` es `false` (FR-007)
- [ ] T018 [P] Pruebas de `PrepararEvidencia` en `test/domain/preparar_evidencia_test.dart`: orden cronológico, `soloEsta`, valores tomados de ajustes, error sin entradas
- [ ] T019 [P] Pruebas de `ResumirEvidencia` en `test/domain/resumir_evidencia_test.dart`: conteos y fotos faltantes

### Composición

- [ ] T020 Registrar en `lib/app/app_container.dart` `ajustes` (`SqliteAjustesRepository` con el mismo `AppDatabase`), `almacenFotos`, `compartir`, `prepararEvidencia` y `resumirEvidencia`; en `lib/main.dart` llamar a `compartir.limpiarTemporales()` al iniciar sin bloquear el arranque (D-022)

**Checkpoint**: `flutter analyze` sin errores y `flutter test` en verde; la app abre y migra a v3 sin perder datos.

---

## Phase 3: User Story 1 - Enviar un reporte formal de una ubicación (Priority: P1) 🎯 MVP

**Goal**: Desde el detalle de una ubicación, generar un PDF con folio y todas (o algunas) entradas y entregarlo al menú del sistema.

**Independent Test**: Ubicación con 3 entradas con fotos → Compartir → Reporte formal → Enviar → abrir el PDF: encabezado, datos del lugar y las 3 entradas en orden cronológico (quickstart escenarios 1–4).

### Tests for User Story 1

- [ ] T021 [P] [US1] Pruebas en `test/domain/compartir_evidencia_test.dart` del camino de reporte formal: limpia temporales, reserva folio, llama a `GeneradorReporte.generar` con ese folio, comparte el archivo con asunto `Reporte de evidencia – <lugar> – <folio>`, guarda `incluirCoordenadas` y devuelve `cancelado` sin lanzar error

### Implementation for User Story 1

- [ ] T022 [P] [US1] Implementar `PdfGeneradorReporte` en `lib/data/services/pdf_generador_reporte.dart`: (1) reducir cada foto existente a máximo 1280 px de lado largo y calidad JPEG 70 con `flutter_image_compress` (D-017), reportando progreso; (2) cargar las fuentes de `assets/fonts/` con Noto Emoji como `fontFallback` (D-018); (3) construir el documento con `Isolate.run` (D-022) en tamaño carta vertical con márgenes de 2 cm, siguiendo [formatos-salida.md](./contracts/formatos-salida.md#reporte-formal-pdf): encabezado (título, folio, fecha de generación, lugar, coordenadas + enlace "Ver en mapa" con `enlaceMapa` solo si `incluirCoordenadas`, periodo, "N entradas · M fotos"), una sección "Entrada i de n — fecha" por entrada con texto completo y fotos 2 por fila conservando proporción, recuadro "Foto no disponible" para archivos faltantes, títulos "(continuación)" al partir página, y pie en todas las páginas "Generado con Bitácora de Campo el … · Folio … · Página x de y"; (4) escribir `Reporte_<lugar sin acentos ni espacios>_<folio>.pdf` en `<temporal>/compartir/`; errores → `AppException('No se pudo generar el reporte…')`
- [ ] T023 [US1] Implementar `CompartirEvidencia` en `lib/domain/usecases/compartir_evidencia.dart` (rama `reporteFormal`): `limpiarTemporales` → `reservarFolio(paquete.generadoEn)` → `GeneradorReporte.generar(onProgreso)` → `compartirArchivo` → `guardarIncluirCoordenadas(paquete.incluirCoordenadas)`; devuelve `ResultadoCompartir`; depende de T021
- [ ] T024 [P] [US1] Crear la hoja inferior `HojaFormatoCompartir` en `lib/presentation/widgets/hoja_formato_compartir.dart` con la opción "📄 Reporte formal — PDF con folio, ideal para clientes" (botón con ícono y texto, ≥ 48 dp, `Semantics`); devuelve el `FormatoCompartir` elegido
- [ ] T025 [US1] Crear `CompartirScreen` en `lib/presentation/screens/compartir_screen.dart` según [flujo-ui.md](./contracts/flujo-ui.md#2-pantalla-compartir): lista de entradas con casillas y "Todas" (solo si se comparte la ubicación completa), resumen de `ResumirEvidencia` ("N entradas · M fotos · con/sin coordenadas" y aviso de fotos faltantes), botón "Enviar" deshabilitado sin entradas marcadas, progreso "Preparando reporte… NN %", confirmación al salir durante la generación; al volver: `enviado` → `Navigator.pop` y SnackBar "Evidencia compartida", `cancelado` → sin mensaje y conserva la selección, `noDisponible` → mensaje "No hay apps para recibir el archivo" con botón "Guardar en el teléfono" que copia el PDF a `<documentos de la app>/reportes/` e informa la ruta; errores → `mostrarError` conservando la selección (FR-013)
- [ ] T026 [US1] Registrar `generadorReporte` (`PdfGeneradorReporte`) y `compartirEvidencia` en `lib/app/app_container.dart`, y la ruta `AppRoutes.compartir = '/compartir'` (argumento `PaqueteEvidencia`) en `lib/app/routes.dart` inyectando solo lo que usa la pantalla
- [ ] T027 [US1] En `lib/presentation/screens/ubicacion_detail_screen.dart` agregar el ícono "Compartir" en la barra superior: deshabilitado con tooltip "Aún no hay entradas para compartir" si el historial está vacío; al tocarlo abre `HojaFormatoCompartir`, arma el paquete con `PrepararEvidencia` y navega a `/compartir`; necesita recibir `prepararEvidencia` por constructor (actualizar `routes.dart`)
- [ ] T028 [US1] Validar los escenarios 1, 2, 3, 4, 9, 10, 11, 12 y 13 de [quickstart.md](./quickstart.md) en el emulador y anotar los tiempos y el tamaño del escenario 13

**Checkpoint**: MVP — se puede entregar un reporte formal de una ubicación.

---

## Phase 4: User Story 2 - Compartir una sola entrada de forma rápida (Priority: P2)

**Goal**: Compartir una entrada (o la ubicación) como mensaje con texto formateado y fotos adjuntas, o como reporte formal de una sola entrada.

**Independent Test**: Compartir una entrada con 2 fotos a una app de mensajería: llegan el texto con fecha y lugar y las 2 fotos (quickstart escenario 6).

### Tests for User Story 2

- [ ] T029 [P] [US2] Pruebas en `test/domain/formatear_mensaje_test.dart`: formato exacto de [formatos-salida.md](./contracts/formatos-salida.md#mensaje) (📍 lugar, coordenadas y enlace, bloques 🗓 en orden cronológico, pie "— Enviado desde Bitácora de Campo"), una sola entrada, entrada sin texto (solo la fecha), texto con emoji, y que no incluye folio, responsable ni cliente
- [ ] T030 [P] [US2] Agregar a `test/domain/compartir_evidencia_test.dart` el camino de mensaje: limpia temporales, llama a `compartirMensaje` con el texto de `FormatearMensaje` y solo las fotos que existen, y no reserva folio

### Implementation for User Story 2

- [ ] T031 [P] [US2] Implementar `FormatearMensaje` (función pura, sin Flutter) en `lib/domain/usecases/formatear_mensaje.dart` usando `formatearFecha`, `formatearCoordenadas` y `enlaceMapa`
- [ ] T032 [US2] Agregar la rama `mensaje` a `CompartirEvidencia` en `lib/domain/usecases/compartir_evidencia.dart`: filtra las fotos con `AlmacenFotos.existe` y llama a `compartirMensaje`; depende de T030 y T031
- [ ] T033 [US2] Agregar la opción "💬 Mensaje — Texto y fotos para WhatsApp o correo" a `lib/presentation/widgets/hoja_formato_compartir.dart`
- [ ] T034 [US2] En `lib/presentation/screens/compartir_screen.dart` soportar el formato `mensaje`: título "Compartir · Mensaje", sin sección de cliente ni de responsable, y lista de entradas oculta cuando el paquete trae una sola entrada
- [ ] T035 [US2] En `_TarjetaEntrada` de `lib/presentation/screens/ubicacion_detail_screen.dart` agregar un botón "Compartir" (ícono y texto, ≥ 48 dp) y `onLongPress` en la tarjeta; ambos abren `HojaFormatoCompartir` y arman el paquete con `PrepararEvidencia(soloEsta: entrada)`
- [ ] T036 [US2] Validar el escenario 6 de [quickstart.md](./quickstart.md) con WhatsApp y con Gmail; anotar si WhatsApp descarta el texto con varias fotos (riesgo del plan)

**Checkpoint**: US1 y US2 funcionan por separado.

---

## Phase 5: User Story 3 - Controlar qué datos salen del teléfono (Priority: P2)

**Goal**: Interruptor de coordenadas recordado y resumen claro de lo que sale.

**Independent Test**: Con "Incluir coordenadas" apagado, ni el PDF ni el mensaje contienen coordenadas ni enlace; al reabrir Compartir sigue apagado (quickstart escenario 5).

### Tests for User Story 3

- [ ] T037 [P] [US3] Agregar pruebas en `test/domain/compartir_evidencia_test.dart` y `test/domain/formatear_mensaje_test.dart`: con `incluirCoordenadas == false` el mensaje no contiene coordenadas ni `google.com/maps`, y la preferencia se guarda con el valor elegido; en `test/domain/resumir_evidencia_test.dart`, `incluyeCoordenadas` refleja el paquete

### Implementation for User Story 3

- [ ] T038 [US3] En `lib/presentation/screens/compartir_screen.dart` agregar el interruptor "Incluir coordenadas y enlace al mapa" con valor inicial del paquete (que viene de ajustes); al cambiarlo, actualizar el paquete con `copyWith` y recalcular el resumen
- [ ] T039 [US3] Verificar en `lib/data/services/pdf_generador_reporte.dart` que con `incluirCoordenadas == false` el encabezado omite la línea "Ubicación" y el enlace "Ver en mapa" (SC-007)
- [ ] T040 [US3] Validar el escenario 5 de [quickstart.md](./quickstart.md) con reporte y con mensaje

**Checkpoint**: US1–US3 funcionan por separado.

---

## Phase 6: User Story 4 - Datos del responsable y del cliente en el reporte (Priority: P3)

**Goal**: Capturar una vez los datos del técnico y, opcionalmente por reporte, los del cliente.

**Independent Test**: Guardar los datos del responsable, generar dos reportes y verificar que ambos los muestran; capturar cliente en uno y verificar que el siguiente reporte trae esos campos vacíos (quickstart escenarios 7 y 8).

### Implementation for User Story 4

- [ ] T041 [P] [US4] Crear `DialogoResponsable` en `lib/presentation/widgets/dialogo_responsable.dart` según [flujo-ui.md](./contracts/flujo-ui.md#3-datos-del-responsable): campos Nombre* ("1–80 caracteres"), Negocio ("0–80 caracteres"), Teléfono ("0–20 caracteres (dígitos, espacios, `+ - ( )`)"); botones "Omitir" y "Guardar" (Guardar deshabilitado sin nombre); guarda con `AjustesRepository.guardarResponsable` y devuelve el `Responsable` o `null`
- [ ] T042 [US4] En `lib/presentation/screens/compartir_screen.dart`, solo en formato `reporteFormal`: fila "Responsable: … · Editar" o "Agregar mis datos" que abre el diálogo; si no hay responsable, ofrecer el diálogo automáticamente una sola vez al abrir la pantalla ("Omitir" no lo vuelve a ofrecer en esa pantalla); inyectar `ajustes` por constructor desde `routes.dart`
- [ ] T043 [US4] En `lib/presentation/screens/compartir_screen.dart`, solo en `reporteFormal`: sección "Cliente (opcional)" con Nombre ("0–80 caracteres") y Dirección ("0–200 caracteres"); se guarda en `paquete.destinatario` y nunca en ajustes; los campos empiezan vacíos cada vez (FR-017)
- [ ] T044 [US4] En `lib/data/services/pdf_generador_reporte.dart` agregar al encabezado "Responsable: nombre · negocio · teléfono" si existe y "Cliente: nombre · dirección" si `destinatario` no está vacío, omitiendo las partes vacías
- [ ] T045 [US4] Validar los escenarios 7 y 8 de [quickstart.md](./quickstart.md)

**Checkpoint**: Las 4 historias funcionan.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T046 [P] Revisar accesibilidad en `compartir_screen.dart`, `hoja_formato_compartir.dart` y `dialogo_responsable.dart`: botones con ícono y texto, área táctil ≥ 48 dp, `Semantics` en casillas, interruptor y botón Enviar
- [ ] T047 [P] Actualizar `specs/002-mejoras-pre-entrega/spec.md` FR-006: la columna `audio_path` irá en la siguiente versión libre del esquema (v2 = `fotos`, v3 = `ajustes`), según D-019
- [ ] T048 [P] Actualizar `docs/roadmap.html`: la spec 003 es "Compartir evidencia" y "Robustez" pasa a la siguiente numeración disponible (la 004 ya es "Bitácora tipo chat")
- [ ] T049 [P] Agregar la entrada de la spec 003 en `CHANGELOG.md` (y registrar ahí que las varias fotos por entrada y el esquema v2 se implementaron fuera de spec)
- [ ] T050 Ejecutar `flutter analyze` y `flutter test` sin errores
- [ ] T051 Recorrer los 14 escenarios de [quickstart.md](./quickstart.md) en el emulador y los escenarios 1, 6, 9 y 13 en un teléfono físico; si SC-002 falla, bajar la reducción a 1024 px en `pdf_generador_reporte.dart` (riesgo del plan)
- [ ] T052 Marcar `[X]` en este archivo cada tarea terminada y hacer commits con el formato `feat(compartir): … [003/T0NN]`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias.
- **Foundational (Phase 2)**: depende de Setup; **bloquea todas las historias**.
- **US1 (Phase 3)**: depende de Foundational. Es el MVP.
- **US2 (Phase 4)**: depende de Foundational. Usa `CompartirEvidencia`, `HojaFormatoCompartir` y `CompartirScreen` creados en US1 (T023–T025), así que en la práctica va después de US1.
- **US3 (Phase 5)**: depende de US1 (pantalla y generador); para validar el mensaje también de US2.
- **US4 (Phase 6)**: depende de US1 (pantalla y generador); independiente de US2 y US3.
- **Polish (Phase 7)**: después de las historias que se vayan a entregar.

### Within Each Story

- Pruebas antes que la implementación del caso de uso (deben fallar primero).
- Dominio → datos → pantalla → validación con el quickstart.

### Parallel Opportunities

- Setup: T002 y T003 en paralelo tras T001.
- Foundational: T004–T011 en paralelo; T014 y T015 en paralelo; T018 y T019 en paralelo.
- US1: T021, T022 y T024 en paralelo.
- US2: T029, T030 y T031 en paralelo.
- US4: T041 en paralelo con lo que quede de US3.
- Polish: T046–T049 en paralelo.

---

## Parallel Example: Foundational

```text
Task: "T004 Responsable en lib/domain/entities/responsable.dart"
Task: "T005 PaqueteEvidencia y relacionados en lib/domain/entities/paquete_evidencia.dart"
Task: "T007 AjustesRepository en lib/domain/repositories/ajustes_repository.dart"
Task: "T009 CompartirService en lib/domain/services/compartir_service.dart"
Task: "T011 enlaceMapa en lib/core/utils/formato.dart"
```

## Parallel Example: User Story 1

```text
Task: "T021 Pruebas de CompartirEvidencia (reporte) en test/domain/compartir_evidencia_test.dart"
Task: "T022 PdfGeneradorReporte en lib/data/services/pdf_generador_reporte.dart"
Task: "T024 HojaFormatoCompartir en lib/presentation/widgets/hoja_formato_compartir.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup.
2. Phase 2: Foundational (incluye la migración a v3).
3. Phase 3: US1 — reporte formal de una ubicación.
4. **Parar y validar** con los escenarios del quickstart de T028; ya se puede mostrar o entregar.

### Incremental Delivery

1. Setup + Foundational → base lista.
2. US1 → reporte formal (MVP).
3. US2 → mensaje rápido y compartir por entrada.
4. US3 → control de coordenadas.
5. US4 → responsable y cliente en el encabezado.
6. Polish → documentación, roadmap y validación en teléfono físico.

---

## Notes

- [P] = archivos distintos y sin dependencias pendientes.
- Las restricciones de [data-model.md](./data-model.md) se citan textualmente en T004, T005, T013, T041 y T043; no cambiarlas al implementar.
- La migración v3 no toca `ubicaciones`, `entradas` ni `fotos`.
