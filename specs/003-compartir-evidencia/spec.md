# Feature Specification: Compartir evidencia de campo

**Feature Branch**: `003-compartir-evidencia`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "Menú para compartir la evidencia de campo de una ubicación o entrada (texto, fotos, fecha y coordenadas) de forma formal, útil y fácil de usar"

## Contexto

Hoy la evidencia de una visita (fotos, notas, fecha, lugar) se queda dentro de la app.
Cuando el técnico necesita demostrar el trabajo a un cliente, a un supervisor o a una
aseguradora, termina reenviando fotos sueltas por WhatsApp, sin fecha, sin dirección y
sin las notas. Esta función convierte lo que ya está registrado en algo que se puede
entregar: un reporte formal o un mensaje rápido, en pocos toques.

**Fuera de alcance**: envío automático o programado, almacenamiento en la nube,
firma electrónica con validez legal, verificación de que el reporte no fue alterado
(códigos de verificación o huellas de las fotos), guardar datos de clientes por
ubicación, edición de las fotos, resumen generado por IA
(queda para la fase de asistente multimodal), compartir varias ubicaciones a la vez.

## Clarifications

### Session 2026-11-17

- Q: ¿El reporte debe permitir comprobar que no fue alterado, o basta con folio y fecha? → A: Folio y fecha de generación bastan (FR-016).
- Q: ¿El reporte incluye datos del cliente o destinatario, y se guardan por ubicación? → A: Se capturan al compartir, de forma opcional, y no se guardan (FR-017).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enviar un reporte formal de una ubicación (Priority: P1)

Al terminar el trabajo en un domicilio, el técnico abre la ubicación, pulsa
"Compartir", elige "Reporte formal", revisa qué entradas incluir y lo envía por la app
que prefiera (correo, WhatsApp, guardar en el teléfono). El cliente recibe un solo
documento con encabezado, datos del lugar y cada entrada con su fecha, notas y fotos.

**Why this priority**: Es la razón de la función: entregar evidencia presentable y
completa en lugar de fotos sueltas. Por sí sola ya aporta valor.

**Independent Test**: Con una ubicación que tenga 3 entradas con fotos, generar el
reporte, abrir el documento resultante y verificar que contiene el encabezado, los
datos del lugar y las 3 entradas completas en orden cronológico.

**Acceptance Scenarios**:

1. **Given** una ubicación con entradas, **When** el técnico pulsa "Compartir" → "Reporte formal" y confirma, **Then** se genera un documento y se abre el menú del sistema para enviarlo o guardarlo.
2. **Given** la vista previa del reporte, **When** el técnico desmarca dos entradas, **Then** el documento generado no las incluye.
3. **Given** un reporte generado, **When** el cliente lo abre en otro dispositivo, **Then** ve el nombre del lugar, las coordenadas con un enlace al mapa, y por cada entrada su fecha y hora, su texto y sus fotos.
4. **Given** el teléfono sin internet, **When** el técnico genera el reporte, **Then** el documento se genera igual; solo el envío depende de la app elegida.

---

### User Story 2 - Compartir una sola entrada de forma rápida (Priority: P2)

Desde el historial de una ubicación, el técnico mantiene presionada una entrada (o usa
su botón de compartir) y la envía como mensaje: el texto de la nota con la fecha y el
lugar, junto con sus fotos adjuntas.

**Why this priority**: Es el uso diario más frecuente ("ya quedó, te mando la foto"),
pero el reporte formal cubre el caso que hoy no tiene solución.

**Independent Test**: Compartir una entrada con 2 fotos a una app de mensajería y
verificar que llegan el texto con fecha y lugar y las 2 fotos.

**Acceptance Scenarios**:

1. **Given** una entrada con texto y fotos, **When** el técnico elige "Compartir" → "Mensaje", **Then** se abre el menú del sistema con el texto formateado y todas las fotos adjuntas.
2. **Given** una entrada sin fotos, **When** la comparte como mensaje, **Then** se comparte solo el texto, sin errores.
3. **Given** una entrada, **When** el técnico elige "Reporte formal", **Then** se genera el mismo tipo de documento de la historia 1, con esa sola entrada.

---

### User Story 3 - Controlar qué datos salen del teléfono (Priority: P2)

Antes de enviar, el técnico decide si incluir las coordenadas exactas y ve un resumen
de lo que va a salir (número de entradas, número de fotos, si van coordenadas).

**Why this priority**: La constitución (principio II) exige que el usuario sepa qué
dato sale del teléfono. Las coordenadas de un domicilio son información sensible.

**Independent Test**: Generar un reporte con las coordenadas desactivadas y verificar
que el documento no contiene coordenadas ni enlace al mapa.

**Acceptance Scenarios**:

1. **Given** la pantalla de compartir, **When** el técnico desactiva "Incluir coordenadas", **Then** el reporte y el mensaje no contienen coordenadas ni enlace al mapa.
2. **Given** la pantalla de compartir, **When** se muestra el resumen, **Then** indica cuántas entradas y fotos se van a compartir y si van coordenadas.

---

### User Story 4 - Datos del responsable y del cliente en el reporte (Priority: P3)

El reporte formal muestra quién lo emite (nombre del técnico y, opcionalmente, su
negocio y teléfono) y, si el técnico lo escribe, para quién es (nombre del cliente y
dirección), para que el documento sea claro sobre su origen y destino.

**Why this priority**: Da formalidad al documento, pero el reporte ya es útil sin ella.

**Independent Test**: Capturar los datos del responsable una vez, generar dos reportes
y verificar que ambos los muestran sin volver a pedirlos.

**Acceptance Scenarios**:

1. **Given** que el técnico nunca capturó sus datos, **When** genera su primer reporte formal, **Then** la app le ofrece capturarlos y le permite omitirlos.
2. **Given** datos del responsable guardados, **When** genera un reporte, **Then** el encabezado los muestra.
3. **Given** la pantalla del reporte formal, **When** el técnico escribe el nombre del cliente y la dirección, **Then** el encabezado de ese reporte los muestra, y el siguiente reporte vuelve a mostrar esos campos vacíos.
4. **Given** la pantalla del reporte formal, **When** el técnico deja vacíos los datos del cliente, **Then** el reporte se genera sin esa sección.

### Edge Cases

- La ubicación no tiene entradas: la opción "Compartir" aparece deshabilitada con la explicación "Aún no hay entradas para compartir".
- Una foto registrada ya no existe en el teléfono: el reporte muestra un recuadro "Foto no disponible" en su lugar y el resumen avisa cuántas faltan; no se cancela la generación.
- Muchas fotos (por ejemplo, 15 entradas con 10 fotos cada una): el documento se genera con las fotos reducidas para que su tamaño permita enviarlo por correo o mensajería (ver SC-003); la app muestra progreso mientras genera.
- El técnico cancela el menú del sistema sin enviar: no se muestra error y el archivo temporal se descarta.
- No hay ninguna app capaz de recibir el archivo: mensaje claro y opción de guardarlo en el teléfono.
- Falla la generación (por ejemplo, poco espacio): mensaje para el usuario y la app sigue usable (principio IV).
- Textos muy largos o con emojis: el reporte los muestra completos, sin cortarse ni romper el diseño.
- Una entrada con más fotos de las que caben en una página: continúan en la página siguiente con el mismo encabezado de entrada.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to abrir un menú "Compartir" desde el detalle de una ubicación y desde cada entrada del historial.
- **FR-002**: El menú MUST ofrecer dos formatos: "Reporte formal" (un documento) y "Mensaje" (texto formateado con las fotos adjuntas).
- **FR-003**: Al compartir una ubicación, Users MUST be able to elegir qué entradas incluir; por defecto van todas, en orden cronológico (de la más antigua a la más reciente).
- **FR-004**: El reporte formal MUST incluir: título, nombre del lugar, fecha y hora de generación, periodo cubierto (primera y última entrada incluida), número de entradas y de fotos, y por cada entrada su fecha y hora, su texto y todas sus fotos.
- **FR-005**: Cuando se incluyan coordenadas, el reporte y el mensaje MUST mostrarlas en formato decimal legible y con un enlace que abra el punto en un mapa.
- **FR-006**: Users MUST be able to desactivar la inclusión de coordenadas antes de compartir; la elección se recuerda para la próxima vez.
- **FR-007**: Antes de enviar, el sistema MUST mostrar un resumen de lo que se compartirá (entradas, fotos, si van coordenadas) y las fotos faltantes, si las hay.
- **FR-008**: El sistema MUST entregar el resultado al menú de compartir del sistema operativo, para que el usuario elija la app destino o lo guarde en el teléfono.
- **FR-009**: La generación del reporte y del mensaje MUST funcionar sin internet (principio II); los datos solo salen del teléfono cuando el usuario elige un destino en el menú del sistema.
- **FR-010**: El reporte MUST incluir un folio de identificación único y la leyenda "Generado con Bitácora de Campo el [fecha y hora]" en cada página, junto con el número de página.
- **FR-011**: El sistema MUST reducir el tamaño de las fotos dentro del reporte para cumplir SC-003, manteniendo legibles los detalles (por ejemplo, el texto de una placa de equipo).
- **FR-012**: Users MUST be able to capturar una vez los datos del responsable (nombre obligatorio; negocio y teléfono opcionales), editarlos después, y omitirlos; si existen, el reporte los muestra en el encabezado.
- **FR-013**: Toda falla al generar o compartir MUST mostrarse como un mensaje para el usuario sin cerrar la app ni perder la selección hecha (principio IV).
- **FR-014**: El sistema MUST borrar los archivos temporales generados para compartir una vez que ya no se necesiten.
- **FR-015**: El "Mensaje" MUST tener este contenido, en este orden: nombre del lugar; coordenadas y enlace al mapa (si están activadas); por cada entrada, fecha y hora y su texto; y las fotos adjuntas.
- **FR-016**: La identificación formal del reporte MUST ser el folio y la fecha y hora de generación (FR-010); el reporte no incluye mecanismos para comprobar que no fue alterado.
- **FR-017**: Antes de generar un reporte formal, Users MUST be able to escribir de forma opcional los datos del destinatario (nombre del cliente y dirección); si se capturan, aparecen en el encabezado del reporte. Estos datos se usan solo para ese reporte y no se guardan.

### Key Entities *(include if feature involves data)*

- **Paquete de evidencia**: lo que el usuario decidió compartir en un momento dado: la ubicación, las entradas seleccionadas, si incluye coordenadas, el formato elegido, el folio y, opcionalmente, el destinatario (nombre del cliente y dirección). Es temporal: se arma para compartir y no se guarda.
- **Reporte formal**: el documento generado a partir de un paquete de evidencia. Tiene folio, fecha de generación, encabezado (lugar y, si existen, datos del responsable y del destinatario) y una sección por entrada.
- **Responsable** (nuevo, persistente): nombre del técnico, negocio y teléfono opcionales. Uno por dispositivo. Se guarda localmente.
- **Preferencias de compartir** (nuevo, persistente): si incluir coordenadas por defecto.
- Se reutilizan **Ubicación**, **Entrada** y sus **fotos** existentes; esta función no los modifica.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Desde el detalle de una ubicación, el técnico envía un reporte formal con todas las entradas en 4 toques o menos (Compartir → Reporte formal → Enviar → app destino).
- **SC-002**: Un reporte de 10 entradas con 3 fotos cada una se genera en menos de 10 segundos en un teléfono de gama media.
- **SC-003**: Un reporte de 10 entradas con 3 fotos cada una pesa menos de 10 MB, de modo que se puede adjuntar a un correo o enviar por mensajería.
- **SC-004**: Un cliente que nunca usó la app identifica, solo leyendo el reporte, el lugar, la fecha de cada visita y qué se hizo, sin explicación adicional (verificado con al menos 3 personas).
- **SC-005**: En pruebas con técnicos, 9 de cada 10 logran compartir una entrada como mensaje al primer intento sin ayuda.
- **SC-006**: El 100 % de los reportes generados sin internet se completan correctamente.
- **SC-007**: Con las coordenadas desactivadas, ningún reporte ni mensaje contiene coordenadas ni enlace al mapa (verificado en el 100 % de las pruebas).

## Assumptions

- El destinatario típico es un cliente, supervisor o aseguradora que recibe el reporte por correo o mensajería y lo abre en su teléfono o computadora.
- El formato del reporte formal es un documento PDF, porque se abre igual en cualquier dispositivo y se puede imprimir.
- El reporte no incluye una imagen de mapa, porque obtenerla requiere internet (principio II); en su lugar lleva coordenadas y un enlace al mapa.
- El idioma del reporte y del mensaje es español; el formato de fecha es el mismo que ya usa la app (día/mes/año y hora de 24 horas).
- Un nuevo paquete para generar documentos y otro para el menú de compartir del sistema se aprobarán en el `research.md` de esta spec, como pide la constitución.
- Esta spec depende de la función de varias fotos por entrada (ya implementada) y no modifica cómo se guardan las entradas; los datos del responsable y las preferencias se guardan aparte.
- La numeración "003" difiere del roadmap, donde la 003 estaba reservada para "Robustez"; el roadmap se actualizará.
- Accesibilidad: botones con ícono y texto, área táctil de al menos 48 dp y etiquetas para lectores de pantalla, igual que en la spec 002.
