<!--
Sync Impact Report
- Versión: (plantilla) → 1.0.0
- Principios agregados: I–V (todos nuevos)
- Secciones agregadas: Restricciones técnicas, Flujo de desarrollo, Gobernanza
- Plantillas revisadas: plan-template.md ✅ (Constitution Check usa estos principios), spec-template.md ✅, tasks-template.md ✅
- Pendientes: ninguno
-->

# Constitución de Bitácora de Campo

## Principios

### I. La ubicación es la llave de memoria

Toda la información se organiza por **lugar físico**, no por sesión ni por conversación.
Cada entrada pertenece a exactamente una ubicación. Una función nueva que agrupe
información de otra forma (por fecha, por cliente, por sesión) debe justificarse en
el `research.md` de su spec.

### II. Offline primero, datos locales

La app MUST funcionar sin internet para registrar y consultar. Los registros (texto,
fotos, coordenadas) se guardan solo en el dispositivo. Cualquier dato que salga a la
red (mapas, dictado del sistema, un modelo generativo) MUST documentarse en la spec,
indicando qué sale y por qué.

### III. Dominio independiente (capas + inversión de dependencias)

- `domain/` no importa Flutter ni ningún plugin.
- Las reglas de negocio viven en casos de uso, nunca en pantallas.
- `data/` implementa interfaces definidas en `domain/`.
- Solo `app/app_container.dart` conoce clases concretas; las pantallas reciben sus
  dependencias por constructor.

### IV. Ningún gadget rompe la app

Todo error técnico se traduce a `AppException` con un mensaje para el usuario. Un
permiso negado, el GPS apagado o una cámara no disponible MUST mostrar un mensaje y
una salida (reintentar, elegir a mano), nunca un cierre ni una pantalla bloqueada.

### V. Simplicidad y alcance

Primero se cumplen los requisitos obligatorios de la entrega; los extras van después.
No se agregan paquetes de estado o de inyección de dependencias mientras el
`setState` y la inyección por constructor alcancen. YAGNI.

## Restricciones técnicas

- Flutter (Dart 3), Android como plataforma principal de demostración.
- Persistencia: SQLite vía `sqflite`; imágenes como archivo en la carpeta privada de
  la app y su ruta en la base.
- Paquetes aprobados: `sqflite`, `path`, `path_provider`, `image_picker`,
  `speech_to_text`, `geolocator`, `flutter_map`, `latlong2`, `url_launcher`.
  Un paquete nuevo se aprueba registrándolo en el `research.md` de la spec que lo usa.
- Código y comentarios en español.

## Flujo de desarrollo

1. Todo cambio funcional empieza con una spec nueva en `specs/NNN-nombre/`
   (`/speckit-specify`).
2. Las decisiones técnicas se registran en `research.md` con el formato
   Decisión / Justificación / Alternativas. Ese archivo es el historial de decisiones.
3. `tasks.md` se actualiza marcando `[X]` al terminar cada tarea.
4. Commits descriptivos que mencionen la spec o la tarea (`feat(gps): ... [001/T014]`).
5. `CHANGELOG.md` resume cada spec entregada.

## Gobernanza

Esta constitución tiene prioridad sobre cualquier otra práctica del proyecto. Cada
plan (`plan.md`) incluye un *Constitution Check*; una violación se justifica en
*Complexity Tracking* o no entra. Las enmiendas suben la versión (MAJOR: se quita o
redefine un principio; MINOR: se agrega uno; PATCH: redacción) y se registran en
`CHANGELOG.md`.

**Version**: 1.0.0 | **Ratified**: 2026-11-08 | **Last Amended**: 2026-11-08
