# Historial de cambios

Cada entrada corresponde a una spec de `specs/`. Las decisiones detalladas de cada una
están en su `research.md`. Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [Sin publicar]

### Agregado — spec [004-bitacora-tipo-chat](specs/004-bitacora-tipo-chat/spec.md)
- El detalle de cada lugar es una conversación: cada entrada es un mensaje destacado con mosaico de fotos y visor a pantalla completa; debajo van sus observaciones como burbujas simples.
- Barra fija para escribir o dictar observaciones y botón "Nueva visita" que abre el formulario de entrada.
- Tabla `observaciones` (esquema v4) ligada a la entrada; se borran en cascada con ella (D-024, D-025).
- La lista de lugares ordena por actividad incluyendo observaciones; al crear una entrada desde la lista se abre la conversación del lugar.
- El mapa interactivo y "Abrir en Google Maps" pasan a una hoja inferior; la portada (Hero) queda en la barra superior (D-031).
- Decisiones D-024 a D-032 en [research.md](specs/004-bitacora-tipo-chat/research.md).


### Planeado — spec [002-mejoras-pre-entrega](specs/002-mejoras-pre-entrega/spec.md)
- Notas de voz con `record`, separadas del dictado (D-012).
- Aclaración de privacidad del dictado en ambas plataformas (D-013).

### Cambiado — spec 002
- Guardar una entrada es atómico: lugar nuevo, entrada y portada en una sola transacción (D-014).
- Cambiar el lugar detectado y confirmar cuando la precisión del GPS es baja.
- Pruebas unitarias de las reglas de negocio.

## [1.0.0] - 2026-11-08

### Agregado — spec [001-bitacora-por-ubicacion](specs/001-bitacora-por-ubicacion/spec.md)
- Memoria organizada por ubicación con asignación automática por radio (RN-01).
- Formulario con GPS, cámara/galería y dictado.
- Historial por lugar con mapa interactivo, Hero y acceso a Google Maps.
- Persistencia SQLite local y arquitectura por capas con inyección por constructor.
- Decisiones D-001 a D-011 en [research.md](specs/001-bitacora-por-ubicacion/research.md).

### Gobernanza
- Constitución del proyecto v1.0.0 en `.specify/memory/constitution.md`.
