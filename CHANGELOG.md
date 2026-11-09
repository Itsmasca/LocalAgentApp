# Historial de cambios

Cada entrada corresponde a una spec de `specs/`. Las decisiones detalladas de cada una
están en su `research.md`. Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

## [Sin publicar]

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
