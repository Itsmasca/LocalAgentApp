# Research: Bitácora de cada lugar en formato de chat

Decisiones D-024 a D-032. Formato: Decisión / Justificación / Alternativas.
Ningún paquete nuevo: todo se resuelve con Flutter y los paquetes ya aprobados.

## D-024 · Observaciones en una tabla propia ligada a la entrada

- **Decisión**: Tabla nueva `observaciones` (`entrada_id` → `entradas.id ON DELETE CASCADE`, `texto`, `creada_en`). La observación pertenece a una entrada, no directamente a la ubicación.
- **Justificación**: Una observación no tiene fotos ni coordenadas (spec, Key Entities), así que no cabe en `entradas` sin columnas vacías y reglas especiales. Ligarla a la entrada cumple FR-004 (agrupar bajo su visita) y FR-012 (se borra con su entrada) con la cascada que ya usa `fotos`. Las consultas existentes sobre `entradas` (incluida la spec 003) no cambian de significado.
- **Alternativas**: (a) columna `tipo` en `entradas` y observaciones como entradas sin foto: mezcla dos conceptos, obliga a filtrar en cada consulta y rompe RN-04 y la spec 003. (b) `ubicacion_id` en vez de `entrada_id`: pierde la agrupación por visita y obliga a calcularla por fechas.

## D-025 · Versión de esquema: la siguiente libre, con migraciones acumulativas

- **Decisión**: `observaciones` entra en la **siguiente versión libre** del esquema. (Actualización: la 003 ya se implementó con v3, así que `observaciones` es la **v4**.) Hoy la base está en v2 y la spec 003 tiene reservada la v3 (tabla `ajustes`, D-019) pero no está implementada. La primera que se implemente toma v3 y la otra v4. Cada paso de `_migrar` va protegido con `if (deVersion < N)` y `onCreate` crea el esquema completo de la última versión.
- **Justificación**: Evita que dos specs escriban la misma versión. Las migraciones acumulativas funcionan desde cualquier versión anterior.
- **Alternativas**: Fijar ya v4 y dejar un hueco si la 003 se retrasa. Se descarta porque sqflite no admite saltos sin un paso intermedio y el hueco confunde.

## D-026 · La conversación se arma en dominio como lista de `Visita`

- **Decisión**: Entidad `Visita { Entrada entrada; List<Observacion> observaciones }`. `EntradaRepository.obtenerVisitas(ubicacionId)` las devuelve en orden ascendente y hace **tres consultas** por lugar (entradas, fotos, observaciones), igual que el patrón actual de fotos. Los separadores de fecha se calculan con una función pura `armarElementosConversacion` en `presentation/conversacion/`, sin Flutter, y tiene prueba.
- **Justificación**: Agrupar y ordenar es una regla de presentación de datos que conviene probar sin widgets. Tres consultas evitan el N+1. Con 100 entradas y 300 observaciones (SC-003) son unas 400 filas locales, muy por debajo de 1 s.
- **Alternativas**: Paginación con carga incremental. Se descarta por YAGNI (Principio V) mientras SC-003 se cumpla sin ella; queda como mitigación en Riesgos.

## D-027 · Lista invertida que construye perezosamente

- **Decisión**: `ListView.builder(reverse: true)` recorriendo los elementos desde el final. La vista arranca en lo más reciente sin desplazar por código (FR-001), solo construye lo visible y mantiene abajo el último mensaje cuando aparece el teclado.
- **Justificación**: Es el patrón estándar de las apps de mensajería en Flutter y evita calcular saltos de scroll.
- **Alternativas**: Una lista normal con `jumpTo(maxScrollExtent)` al cargar, que parpadea y falla con alturas de imagen aún desconocidas.

## D-028 · Mosaico de fotos y visor a pantalla completa sin paquetes

- **Decisión**: El mosaico depende del número de fotos: 1 foto a todo el ancho (proporción 4:3); 2 fotos lado a lado; 3 fotos, una grande y dos apiladas; 4 o más, una cuadrícula de 2×2 donde la cuarta celda muestra "+N". Al tocar cualquiera se abre `VisorFotosScreen` (ruta `/fotos`), con `PageView` e `InteractiveViewer` para zoom, empezando en la foto tocada (FR-011). Cada celda reutiliza `FotoLocal`, que ya muestra un marcador cuando falta el archivo.
- **Justificación**: Las fotos quedan en primer plano sin deslizar (US1-2), como en WhatsApp. `InteractiveViewer` ya viene en Flutter.
- **Alternativas**: Mantener el carrusel actual, que oculta las fotos detrás de un deslizamiento. `photo_view`, que es un paquete más para algo que Flutter ya trae.

## D-029 · Barra de redacción: texto y dictado; enviar crea observación

- **Decisión**: La barra fija al pie tiene, en este orden: botón "Nueva visita" (ícono `add_a_photo`), campo de texto multilínea (de 1 a 5 líneas, `maxLength` 2000 con contador oculto hasta 1 800), botón de micrófono y botón de enviar. Enviar se deshabilita si el texto está vacío tras `trim` (FR-008). Si guardar falla, el texto **se queda** en el campo y aparece un mensaje (edge case). El dictado reutiliza `SpeechService` y el manejo de `nueva_entrada_screen.dart` se extrae a un widget `BotonDictado` que usan ambas pantallas.
- **Justificación**: Concentra todas las acciones de registro en el lugar donde el pulgar ya está. Extraer `BotonDictado` evita duplicar la lógica de permisos y errores del dictado (Principio IV).
- **Alternativas**: Copiar la lógica del dictado en la nueva pantalla, lo que duplica unas 40 líneas con manejo de errores. Poner "Nueva visita" como FAB, que tapa los mensajes de abajo en una vista invertida.

## D-030 · "Nueva visita" reutiliza el formulario actual

- **Decisión**: "Nueva visita" navega a la ruta existente `/nueva-entrada` con `ubicacionFija` (el antiguo "Agregar aquí": sin detección por GPS, que se usa solo para las coordenadas de la entrada). Al volver con `true`, la conversación recarga y queda al final. Desde la lista principal, al guardar una entrada se abre el detalle (la conversación) de esa ubicación (US3-6): `NuevaEntradaScreen` devuelve la `Entrada` creada y la lista navega a su ubicación.
- **Justificación**: Es la aclaración B de la spec: entrada solo por acción explícita, y el formulario no se rediseña (Assumptions). Ya resuelve fotos, dictado, validación RN-03 y la transacción D-014.
- **Alternativas**: Un formulario en hoja inferior dentro del chat, que es más trabajo y duplicaría las reglas del formulario.

## D-031 · Encabezado compacto: Hero en la AppBar y mapa en hoja inferior

- **Decisión**: La portada pasa a ser un avatar circular (40 px) con el mismo `heroTag` junto al nombre en la AppBar, así que la transición Hero desde la lista se conserva (requisito de entrega FR-013 de la 001). El mapa interactivo y "Abrir en Google Maps" se mueven a una hoja inferior (`HojaMapaUbicacion`) que abre el ícono de mapa de la AppBar.
- **Justificación**: En un chat el espacio vertical es para los mensajes. Así se mantienen los requisitos de la 001 (mapa interactivo y acceso a Google Maps en el detalle, FR-009) sin quitar pantalla a la conversación.
- **Alternativas**: Una portada y un mapa grandes que se colapsan con `SliverAppBar`, que es incompatible con la lista invertida. Quitar el mapa, que viola FR-009 de la 001.

## D-032 · Actividad del lugar incluye observaciones y borrado con confirmación

- **Decisión**: `obtenerTodas` ordena por la fecha más reciente entre `entradas.creada_en` y `observaciones.creada_en` (FR-014), con subconsultas `MAX` para no multiplicar filas en el `JOIN`. Para eliminar una observación se mantiene presionada su burbuja, se elige "Eliminar" en un menú y se confirma en un diálogo (FR-012). El borrado de una entrada (que hoy no existe en la interfaz) o de una ubicación arrastra sus observaciones por `ON DELETE CASCADE`.
- **Justificación**: Es el gesto habitual de las apps de mensajería. La cascada ya está activa (`PRAGMA foreign_keys = ON`).
- **Alternativas**: Deslizar para borrar, que es fácil de activar por accidente en una lista con desplazamiento.

## Datos que salen del teléfono (Principio II)

Ninguno nuevo. Las observaciones se guardan solo en SQLite local. Los mosaicos del
mapa (OpenStreetMap) y el dictado del sistema siguen como en D-007 y D-013.
