# Feature Specification: Bitácora de campo organizada por ubicación

**Feature Branch**: `001-bitacora-por-ubicacion`

**Created**: 2026-11-08

**Status**: Implemented (pendiente de verificación en dispositivo)

**Input**: User description: "Una app móvil para técnicos de campo donde la memoria se
organiza por ubicación y no por sesión: cada lugar guarda su historial de fotos,
dictados y coordenadas, con persistencia local para proteger la privacidad."

## Contexto

Los técnicos de campo (aire acondicionado, plomería, electricidad, refrigeración,
redes) regresan una y otra vez a los mismos domicilios, pero el contexto de cada visita
se pierde entre la galería, WhatsApp y su memoria. Las apps de IA organizan por
conversación, no por lugar. Caso de referencia: técnico de aire acondicionado en Mérida.

**Fuera de alcance**: CRM, agenda, cobros, coordinación de equipos, asistente generativo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrar una entrada en el lugar donde estoy (Priority: P1)

El técnico abre "Nueva entrada" en un domicilio. La app detecta su posición, le dice
en qué lugar registrado está (o le pide nombre si es nuevo), y él agrega una foto y
dicta una nota.

**Why this priority**: Sin registro no hay historial; es el núcleo de la app.

**Independent Test**: Con la base vacía, crear una entrada con foto y dictado; debe
aparecer una ubicación nueva en la lista.

**Acceptance Scenarios**:

1. **Given** no hay ubicaciones, **When** el técnico guarda una entrada con nombre "Casa López", **Then** se crea la ubicación con sus coordenadas y la entrada queda dentro.
2. **Given** existe "Casa López" a 30 m, **When** abre "Nueva entrada", **Then** ve "Estás en: Casa López" y la entrada se guarda ahí.
3. **Given** el formulario abierto, **When** pulsa el micrófono y habla, **Then** el texto aparece en el campo.
4. **Given** el formulario abierto, **When** toma una foto o elige de galería, **Then** ve la vista previa.

---

### User Story 2 - Consultar el historial de un lugar (Priority: P2)

El técnico abre un lugar de la lista y ve su portada, un mapa y todas las entradas,
de la más reciente a la más antigua.

**Why this priority**: Es el beneficio principal (recuperar contexto), pero depende de US1.

**Independent Test**: Con datos de prueba, abrir una ubicación y verificar mapa,
portada con transición Hero e historial ordenado.

**Acceptance Scenarios**:

1. **Given** una ubicación con 3 entradas, **When** la abre, **Then** ve las 3 ordenadas por fecha descendente.
2. **Given** el detalle abierto, **When** pulsa el ícono de mapa, **Then** se abre Google Maps en esas coordenadas.
3. **Given** el detalle abierto, **When** pulsa "Agregar aquí", **Then** la nueva entrada se guarda en ese lugar sin aplicar detección por GPS.

---

### User Story 3 - Ver todos mis lugares (Priority: P3)

La pantalla principal lista las ubicaciones, la de actividad más reciente primero.

**Why this priority**: Navegación; útil cuando hay varios lugares.

**Independent Test**: Crear entradas en dos lugares en distinto orden y verificar el orden de la lista.

**Acceptance Scenarios**:

1. **Given** dos ubicaciones, **When** se agrega una entrada a la más antigua, **Then** esa pasa al primer lugar de la lista.
2. **Given** la base vacía, **When** abre la app, **Then** ve un mensaje que explica cómo crear su primera entrada.

### Edge Cases

- GPS apagado o permiso negado: mensaje claro, botón Reintentar, Guardar deshabilitado hasta tener coordenadas.
- Permiso bloqueado permanentemente: mensaje que indica activarlo en Ajustes.
- Posición dentro del radio de dos ubicaciones: se asigna a la más cercana.
- Entrada sin texto ni foto: no se guarda; se muestra mensaje.
- Lugar nuevo sin nombre: no se guarda; se muestra mensaje.
- El usuario cancela cámara o galería: no pasa nada.
- Reconocimiento de voz no disponible: mensaje; se puede escribir a mano.
- El archivo de una foto ya no existe: se muestra un placeholder.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST capturar la posición GPS al abrir el formulario de nueva entrada.
- **FR-002**: System MUST asignar la entrada a la ubicación cuyo radio (75 m por defecto) contiene la posición; si hay varias, a la más cercana (RN-01).
- **FR-003**: System MUST crear una ubicación nueva con nombre obligatorio cuando ninguna contiene la posición (RN-02).
- **FR-004**: System MUST rechazar entradas sin texto y sin foto (RN-03).
- **FR-005**: Users MUST be able to tomar una foto con la cámara o elegirla de la galería.
- **FR-006**: Users MUST be able to dictar el texto de la entrada con el micrófono.
- **FR-007**: System MUST guardar entradas y metadatos (ruta de imagen, latitud, longitud, fecha) en almacenamiento local.
- **FR-008**: System MUST usar la primera foto de una ubicación como portada (RN-04).
- **FR-009**: System MUST mostrar en el detalle un mapa interactivo y un acceso a Google Maps.
- **FR-010**: System MUST eliminar las entradas de una ubicación cuando esta se elimina (RN-06).
- **FR-011**: System MUST listar ubicaciones por actividad más reciente (RN-07).
- **FR-012**: System MUST copiar las imágenes a la carpeta privada de la app (RN-08).
- **FR-013**: UI MUST usar Scaffold, AppBar, Drawer, rutas con nombre, Hero y FutureBuilder (requisitos de la entrega).

### Key Entities

- **Ubicación**: lugar físico al que se regresa. Nombre, coordenadas, radio, portada, fecha de creación.
- **Entrada**: registro hecho en una ubicación. Texto, foto opcional, coordenadas, fecha. Pertenece a una sola ubicación.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Registrar una entrada con foto y dictado toma menos de 60 segundos desde abrir el formulario.
- **SC-002**: Al abrir un lugar, su historial aparece en menos de 1 segundo con 100 entradas guardadas.
- **SC-003**: Registrar y consultar funciona con el modo avión activado (salvo los mosaicos del mapa).
- **SC-004**: Ningún permiso negado provoca un cierre de la app.

## Assumptions

- Un radio de 75 m distingue domicilios en zonas residenciales típicas de Mérida; en edificios o casas contiguas puede fallar (ver spec 002).
- El técnico usa un solo dispositivo; no hay sincronización.
- El dictado usa el reconocedor del sistema (Google en Android, Apple en iOS), que puede procesar el audio en línea (ver D-013).
