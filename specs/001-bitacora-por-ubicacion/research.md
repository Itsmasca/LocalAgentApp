# Research & Decisiones: 001-bitacora-por-ubicacion

Registro de decisiones técnicas de la spec 001. Formato: Decisión / Justificación /
Alternativas. Las decisiones posteriores van en el `research.md` de su propia spec.

---

## D-001 · Organizar la memoria por ubicación

- **Decisión**: La unidad de organización es la ubicación (`ubicacion_id`), no la sesión.
- **Justificación**: Para un técnico de campo el contexto vive en el domicilio. Es la idea que distingue al proyecto.
- **Alternativas**: Historial por fecha (galería), por contacto (WhatsApp), por conversación (apps de IA). Todas obligan a buscar o reexplicar.

## D-002 · Identificar el lugar por radio alrededor de coordenadas

- **Decisión**: Cada ubicación tiene un radio (75 m por defecto); se usa Haversine para la distancia.
- **Justificación**: Funciona sin internet y sin servicios de terceros.
- **Alternativas**: Geocodificación inversa a dirección postal (requiere red, falla con direcciones informales); geocercas nativas del sistema (más permisos y complejidad, innecesario si no hay notificaciones en segundo plano).

## D-003 · Resolver la ubicación al abrir el formulario

- **Decisión**: `ResolverUbicacion` corre al abrir "Nueva entrada"; la escritura ocurre al guardar.
- **Justificación**: El técnico sabe de inmediato dónde está o si creará un lugar nuevo.
- **Alternativas**: Resolver al guardar (sin retroalimentación previa).

## D-004 · Dos entidades: Ubicación y Entrada

- **Decisión**: No existe la entidad Visita en esta versión.
- **Justificación**: Menos tablas y pantallas; una visita se puede derivar agrupando por fecha (Constitución V).
- **Alternativas**: Ubicación → Visita → Entrada (más fiel al dominio, más alcance del que pide el parcial).

## D-005 · SQLite con `sqflite`

- **Decisión**: Dos tablas con llave foránea y `ON DELETE CASCADE`, índice en `entradas(ubicacion_id)`.
- **Justificación**: Hay relaciones, borrado en cascada y consultas por lugar.
- **Alternativas**: SharedPreferences (solo clave-valor); Isar/Hive/Drift (paquetes extra sin necesidad clara).

## D-006 · Copiar imágenes a la carpeta privada

- **Decisión**: `ImagePickerMediaService` copia la imagen a `documents/fotos/` y guarda esa ruta.
- **Justificación**: La ruta que devuelve `image_picker` es temporal.
- **Alternativas**: Guardar la ruta original (se rompe si el sistema limpia la caché); guardar la imagen como BLOB (base pesada).

## D-007 · `flutter_map` + botón a Google Maps

- **Decisión**: Mapa interactivo con mosaicos de OpenStreetMap y un botón que abre Google Maps vía `url_launcher`.
- **Justificación**: Sin API key ni cuenta de facturación; cumple ambas opciones del requisito.
- **Alternativas**: `google_maps_flutter` (requiere API key y configuración por plataforma).

## D-008 · Dictado con `speech_to_text` (es_MX)

- **Decisión**: Reconocimiento del sistema en modo dictado con resultados parciales.
- **Justificación**: Sin costo ni llaves; buena calidad en español.
- **Alternativas**: Grabar audio y transcribir con un servicio externo (red y costo); modelo en el dispositivo (complejidad).
- **Consecuencia**: No se guarda el archivo de audio, y el reconocedor del sistema puede procesarlo en línea en Android e iOS. Ver D-012 y D-013 en la spec 002.

## D-009 · Inyección de dependencias manual por constructor

- **Decisión**: `AppContainer` crea las implementaciones; `AppRouter` las pasa a cada pantalla.
- **Justificación**: Sin paquetes extra; cada pantalla declara lo que usa (Constitución III y V).
- **Alternativas**: `get_it`, `provider`, `riverpod`.

## D-010 · Una sola excepción de aplicación

- **Decisión**: `AppException(mensaje, causa)`; repositorios y servicios traducen todo error.
- **Justificación**: La UI solo muestra `mensaje` (Constitución IV).
- **Alternativas**: Tipos de error por capa (más precisión, más código para el alcance actual).

## D-011 · Asistente generativo fuera de esta spec

- **Decisión**: No se integra un modelo generativo en la 001.
- **Justificación**: No es requisito, añade dependencia de red y riesgo a los requisitos obligatorios (Constitución II y V).
- **Alternativas**: Resumen al llegar con un LLM (queda como trabajo futuro).
