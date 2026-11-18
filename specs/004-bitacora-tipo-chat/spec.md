# Feature Specification: Bitácora de cada lugar en formato de chat

**Feature Branch**: `004-bitacora-tipo-chat`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "Ok necesitamos aunque todavia no estamos en la fase de agentic pero lo que si necesito es una interfaz mas sencilla tipo chat solo que el formato de los mensajes tiene que resaltar el estilo grafico del mensaje, las fotos y la entrada y que despues solo sean mensajes como observacion simples adicionales"

## Contexto

Hoy registrar algo en un lugar implica abrir un formulario completo ("Nueva entrada")
aunque el técnico solo quiera anotar una frase más ("el compresor sigue haciendo
ruido", "el cliente pidió presupuesto"). El historial, además, se ve como una lista
de tarjetas iguales. Los técnicos ya usan WhatsApp todo el día: escribir en un chat
es el gesto que menos esfuerzo les cuesta.

Esta función convierte el historial de cada ubicación en una conversación: la
**entrada** (la visita, con sus fotos) aparece como un mensaje destacado y vistoso, y
lo que el técnico agregue después son **observaciones** cortas, con aspecto de
mensaje simple. El objetivo es que registrar sea tan rápido como mandar un mensaje,
sin perder la organización por lugar (Principio I).

**No es el asistente**: en esta fase nadie responde en el chat. Todos los mensajes son
del técnico; el formato de chat se elige porque será la base natural de la futura fase
de asistente, pero esta spec no agrega ninguna respuesta automática ni dato que salga
del teléfono.

**Fuera de alcance**: respuestas automáticas o generadas por IA, chat entre personas
(técnico–cliente o técnico–supervisor), editar mensajes ya enviados, reacciones,
mensajes de voz como burbuja de audio reproducible dentro del chat (la nota de voz de
la spec 002 se sigue mostrando como hoy dentro de la entrada), búsqueda dentro del
chat, conversaciones que mezclen varias ubicaciones.

## Clarifications

### Session 2026-11-17

- Q: ¿Qué hace que un mensaje sea "entrada" destacada y no "observación" simple? → A: El técnico pulsa explícitamente "Nueva visita" para crear la entrada (con el formulario de entrada); todo lo que se envía desde el cuadro de texto del chat es observación (US3, FR-006, FR-010).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver el historial de un lugar como conversación (Priority: P1)

El técnico abre una ubicación y, en lugar de una lista de tarjetas, ve una
conversación: cada entrada aparece como un mensaje grande y destacado, con sus fotos
en primer plano, la fecha y el texto; debajo de cada entrada aparecen, como burbujas
sencillas, las observaciones que agregó después. Lo más reciente queda abajo, junto
al cuadro para escribir, como en cualquier app de mensajería.

**Why this priority**: Es el cambio visual que pide el usuario y no depende de nada
nuevo: los registros existentes ya pueden mostrarse así. Por sí solo hace el historial
más fácil de leer.

**Independent Test**: Con una ubicación que tenga 3 entradas existentes (con y sin
fotos), abrirla y verificar que se ven como 3 mensajes destacados en orden cronológico
(la más reciente abajo), con fotos visibles sin tener que abrir nada.

**Acceptance Scenarios**:

1. **Given** una ubicación con 3 entradas, **When** el técnico la abre, **Then** ve las 3 como mensajes destacados, ordenados de la más antigua (arriba) a la más reciente (abajo), y la vista arranca mostrando la más reciente.
2. **Given** una entrada con 4 fotos, **When** aparece en la conversación, **Then** sus fotos se muestran en un mosaico dentro del mensaje y al tocar una se abre en pantalla completa.
3. **Given** una entrada con observaciones posteriores, **When** se muestra la conversación, **Then** las observaciones aparecen debajo de su entrada con un estilo claramente más simple (burbuja de texto, sin fotos ni encabezado).
4. **Given** mensajes de días distintos, **When** se muestra la conversación, **Then** aparece un separador con la fecha cada vez que cambia el día.

---

### User Story 2 - Agregar una observación rápida (Priority: P1)

Ya dentro de la conversación de un lugar, el técnico escribe (o dicta con el
micrófono) una frase en el cuadro inferior y pulsa enviar. La observación aparece al
instante como burbuja simple al final de la conversación, sin pasar por ningún
formulario.

**Why this priority**: Es el ahorro de esfuerzo que justifica la función: anotar algo
adicional en dos toques.

**Independent Test**: Abrir una ubicación con una entrada, escribir "Se cambió el
capacitor" y enviar; la burbuja aparece abajo con la hora, y sigue ahí después de
cerrar y volver a abrir la app.

**Acceptance Scenarios**:

1. **Given** la conversación de un lugar abierta, **When** el técnico escribe un texto y pulsa enviar, **Then** aparece una observación al final con la hora de envío y el cuadro de texto queda vacío.
2. **Given** el cuadro de texto, **When** el técnico pulsa el micrófono y habla, **Then** el texto dictado aparece en el cuadro para revisarlo antes de enviar.
3. **Given** el cuadro vacío o solo con espacios, **When** el técnico intenta enviar, **Then** no se crea ningún mensaje (el botón de enviar está deshabilitado).
4. **Given** el teléfono en modo avión, **When** el técnico envía una observación, **Then** se guarda igual.

---

### User Story 3 - Registrar una entrada nueva desde la conversación (Priority: P2)

Cuando el técnico regresa al lugar en otra visita, pulsa "Nueva visita" desde la
misma conversación, registra la entrada (fotos, texto o dictado) y esta aparece como
mensaje destacado; las observaciones que escriba a partir de ahí en el cuadro del chat
quedan debajo de esa nueva entrada.

**Why this priority**: Sin esto, el chat solo serviría para observaciones; pero el
alta de entradas ya existe en el formulario actual, por lo que puede llegar después
de US1 y US2.

**Independent Test**: En una ubicación con una entrada antigua y observaciones, crear
una entrada nueva con 2 fotos desde la conversación; debe aparecer como mensaje
destacado al final, y una observación enviada después debe quedar debajo de ella.

**Acceptance Scenarios**:

1. **Given** la conversación de un lugar, **When** el técnico pulsa "Nueva visita" y guarda una entrada con fotos, **Then** vuelve a la conversación y la entrada aparece al final como mensaje destacado con sus fotos.
2. **Given** una entrada nueva recién creada, **When** el técnico envía una observación, **Then** esta queda agrupada bajo la nueva entrada y no bajo la anterior.
3. **Given** la conversación de un lugar, **When** el técnico escribe en el cuadro del chat y envía, **Then** siempre se crea una observación, nunca una entrada; el cuadro del chat no permite adjuntar fotos.
4. **Given** el técnico pulsa "Nueva visita" y guarda una entrada solo con texto, **When** vuelve a la conversación, **Then** la entrada aparece como mensaje destacado aunque no tenga fotos.
5. **Given** el formulario de "Nueva visita" abierto, **When** el técnico cancela, **Then** vuelve a la conversación sin crear nada.
6. **Given** una ubicación nueva detectada por GPS desde la pantalla principal, **When** el técnico guarda su primera entrada, **Then** se abre la conversación de ese lugar con la entrada como primer mensaje.

---

### Edge Cases

- Ubicación sin entradas (por ejemplo, tras eliminar la única que tenía): la conversación muestra un mensaje que invita a registrar la primera entrada; no se pueden enviar observaciones sueltas sin una entrada a la que pertenezcan.
- Foto cuyo archivo ya no existe: dentro del mensaje destacado se muestra un marcador de imagen no disponible, sin romper el resto del mensaje.
- Texto muy largo en una observación (más de 2 000 caracteres): se recorta al límite y se avisa; una burbuja muy larga se muestra completa con desplazamiento normal.
- Dictado no disponible o permiso de micrófono negado: mensaje claro y el técnico puede seguir escribiendo a mano (Principio IV).
- Falla al guardar una observación: el texto no se pierde del cuadro y se muestra un mensaje para reintentar.
- Conversación con cientos de mensajes: la vista se abre en lo más reciente sin esperar a cargar todo el historial.
- Teclado abierto: el último mensaje y el cuadro de texto siguen visibles.
- Entradas creadas antes de esta función: se muestran como mensajes destacados sin observaciones; no requieren ninguna acción del técnico.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El detalle de cada ubicación MUST mostrar su historial como una conversación en orden cronológico ascendente (lo más reciente abajo) y abrirse posicionado en el mensaje más reciente.
- **FR-002**: Cada entrada MUST mostrarse como mensaje destacado: fotos en primer plano (una foto a todo el ancho; varias en mosaico con indicador "+N" si no caben), fecha y hora, y texto completo; visualmente distinto y de mayor jerarquía que una observación.
- **FR-003**: Cada observación MUST mostrarse como burbuja simple de texto con su hora, sin encabezado ni fotos.
- **FR-004**: Las observaciones MUST pertenecer a una entrada y mostrarse agrupadas debajo de ella; una observación nueva se asigna a la entrada más reciente de la ubicación.
- **FR-005**: La conversación MUST mostrar un separador de fecha cada vez que cambia el día entre dos mensajes consecutivos.
- **FR-006**: Users MUST be able to escribir una observación en un cuadro fijo al pie de la conversación y enviarla con un solo toque. Todo lo enviado desde este cuadro es una observación; el cuadro no permite adjuntar fotos.
- **FR-007**: Users MUST be able to dictar el texto de una observación con el micrófono del cuadro; el texto dictado queda en el cuadro para revisarse antes de enviar.
- **FR-008**: System MUST rechazar observaciones vacías o solo con espacios, y limitar su texto a 2 000 caracteres.
- **FR-009**: System MUST guardar cada observación en el dispositivo, con su texto y fecha y hora, sin conexión a internet (Principio II); esta función no envía ningún dato fuera del teléfono.
- **FR-010**: La conversación MUST ofrecer una acción visible "Nueva visita" que abre el registro de entrada para esa ubicación (fotos, texto, dictado, nota de voz; sin detección por GPS, como el actual "Agregar aquí"). La entrada guardada aparece al final como mensaje destacado, tenga o no fotos. Solo esta acción crea entradas.
- **FR-011**: Al tocar una foto de un mensaje destacado, System MUST abrirla en pantalla completa.
- **FR-012**: Users MUST be able to eliminar una observación propia, con confirmación; eliminar una entrada MUST eliminar también sus observaciones.
- **FR-013**: Las entradas existentes antes de esta función MUST mostrarse en la conversación sin pérdida de datos ni acción del usuario.
- **FR-014**: La actividad de una ubicación usada para ordenar la lista principal MUST considerar también la observación más reciente (agregar una observación sube el lugar al inicio de la lista).
- **FR-015**: Las acciones ya existentes sobre una entrada (compartir de la spec 003, nota de voz de la spec 002, abrir en mapa) MUST seguir disponibles desde el mensaje destacado.

### Key Entities

- **Ubicación**: sin cambios; su historial ahora se presenta como conversación.
- **Entrada**: registro principal de una visita (texto, fotos, coordenadas, fecha). Se presenta como mensaje destacado y agrupa las observaciones posteriores.
- **Observación**: nota breve agregada después de una entrada. Texto (escrito o dictado) y fecha y hora. Pertenece a una sola entrada (y, a través de ella, a una sola ubicación). No tiene fotos ni coordenadas propias.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Agregar una observación a un lugar ya abierto toma menos de 10 segundos y como máximo 2 toques además de escribir.
- **SC-002**: En una prueba con 5 técnicos, al menos 4 identifican sin explicación cuál mensaje es la entrada (la visita) y cuáles son observaciones.
- **SC-003**: La conversación de un lugar con 100 entradas y 300 observaciones se abre mostrando lo más reciente en menos de 1 segundo.
- **SC-004**: El 100 % de las entradas registradas antes de esta función aparecen en la conversación tras actualizar la app.
- **SC-005**: Registrar entradas y observaciones funciona con el modo avión activado.

## Assumptions

- Todos los mensajes son del técnico; no hay "otro lado" en la conversación. Las burbujas pueden alinearse de un solo lado.
- La conversación reemplaza la lista del detalle de ubicación; la pantalla principal (lista de lugares) y la detección por GPS al crear una entrada desde ella se mantienen como están.
- Una observación hereda el lugar de su entrada; no captura GPS propio (el técnico ya está en el lugar o lo anota después).
- Se mantiene el máximo de 10 fotos por entrada; las observaciones no llevan fotos.
- El registro de entrada que abre "Nueva visita" reutiliza el formulario actual con sus reglas (texto o al menos una foto); no se rediseña en esta spec.
- Si el técnico quiere comentar una entrada antigua, la observación igual se agrega al final, bajo la entrada más reciente (no hay respuestas a mensajes específicos en esta fase).
- El reporte de la spec 003 debería incluir las observaciones bajo su entrada; ese ajuste se planifica junto con esta spec o como seguimiento de la 003.
- El dictado usa el mismo servicio de reconocimiento de voz que ya usa la app.
