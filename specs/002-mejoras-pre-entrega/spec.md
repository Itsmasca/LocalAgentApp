# Feature Specification: Mejoras antes de la entrega

**Feature Branch**: `002-mejoras-pre-entrega`

**Created**: 2026-11-08

**Status**: Draft

**Input**: User description: "Cerrar los huecos detectados al revisar la 001: guardar el
audio del dictado, permitir cambiar el lugar detectado y agregar pruebas unitarias de
las reglas de negocio."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Grabar notas de voz (Priority: P1)

El técnico graba una nota de voz con un solo toque (acción principal del formulario).
El dictado a texto sigue disponible como acción separada. En el historial se puede
reproducir la nota. Ver decisión D-012 en [research.md](./research.md).

**Why this priority**: El requisito de la entrega dice que la captura de audio es fundamental; hoy solo se guarda texto.

**Independent Test**: Grabar una nota, guardar, abrir el detalle y reproducir el audio.

**Acceptance Scenarios**:

1. **Given** el formulario abierto, **When** el técnico pulsa "Grabar nota", habla, la detiene y guarda, **Then** la entrada tiene un archivo de audio.
3. **Given** una nota grabada, **When** además dicta texto, **Then** la entrada guarda ambos.
2. **Given** una entrada con audio, **When** pulsa reproducir en el detalle, **Then** se escucha la nota.

---

### User Story 2 - Corregir el lugar detectado (Priority: P1)

Si la app detecta un lugar equivocado, el técnico puede elegir otro de la lista o
crear uno nuevo.

**Why this priority**: En casas contiguas o interiores el GPS puede equivocarse y hoy no hay forma de corregirlo.

**Independent Test**: Con dos ubicaciones cercanas, abrir el formulario, cambiar a la otra y guardar.

**Acceptance Scenarios**:

1. **Given** "Estás en: Casa A", **When** pulsa "Cambiar" y elige "Casa B", **Then** la entrada se guarda en Casa B.
2. **Given** la precisión del GPS es peor que el radio, **When** abre el formulario, **Then** la app pide confirmar el lugar.

---

### User Story 3 - Pruebas de las reglas de negocio (Priority: P2)

Pruebas unitarias de `ResolverUbicacion` y `GuardarEntrada` con repositorios falsos.

**Why this priority**: Demuestran las reglas y el valor de la inyección de dependencias en la defensa.

**Independent Test**: `flutter test` en verde.

### Edge Cases

- El usuario intenta dictar mientras graba una nota: se detiene la grabación antes de iniciar el dictado.
- Falla la grabación del archivo: mensaje y la entrada se puede guardar sin audio.
- El técnico cambia de lugar y luego cancela.

## Requirements *(mandatory)*

- **FR-001**: System MUST grabar y guardar en el dispositivo una nota de voz por entrada, independiente del dictado.
- **FR-002**: Users MUST be able to reproducir el audio desde el detalle.
- **FR-003**: Users MUST be able to cambiar la ubicación detectada antes de guardar.
- **FR-004**: System MUST pedir confirmación cuando la precisión del GPS sea mayor que el radio de la ubicación.
- **FR-005**: El proyecto MUST incluir pruebas unitarias de RN-01 a RN-04.
- **FR-006**: Cambio de esquema: columna `audio_path` en `entradas` con migración `onUpgrade` (versión 2). Una nota de voz por entrada (D-012).

## Success Criteria *(mandatory)*

- **SC-001**: Grabar una nota de voz toma un toque para iniciar y uno para detener.
- **SC-002**: Corregir el lugar toma un toque más una selección.
- **SC-003**: `flutter test` cubre RN-01 a RN-04 y pasa.

## Assumptions

- Paquete para grabar audio: `record` (aprobado en D-012).
- Accesibilidad: botones con ícono y texto, área táctil ≥ 48 dp y etiquetas `Semantics`.
