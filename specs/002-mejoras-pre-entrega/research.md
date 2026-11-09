# Research & Decisiones: 002-mejoras-pre-entrega

Continúa la numeración de `specs/001-bitacora-por-ubicacion/research.md`.

---

## D-012 · Nota de voz separada del dictado

- **Decisión**: Dos acciones independientes en el formulario:
  1. **Grabar nota** (acción principal, botón grande): graba un archivo de audio con el paquete `record`.
  2. **Dictar texto** (micrófono dentro del campo): sigue usando `speech_to_text`.
- **Justificación**:
  - El requisito dice que la captura de audio es fundamental, y hoy solo se guarda la transcripción.
  - `speech_to_text` no da acceso al audio, y su documentación indica que en Android no se
    puede grabar audio mientras corre el reconocimiento ni transcribir audio ya grabado.
    Grabar y dictar al mismo tiempo no es viable.
  - Es la opción más simple y con menos riesgo para la fecha de entrega (Constitución V).
- **Alternativas**:
  - **B. Grabar y transcribir en el dispositivo** (Whisper local): una sola acción, offline y
    privada, pero el modelo pesa decenas de MB, es lento en gama baja y es más complejo.
    Se pospone a la siguiente fase.
  - **C. Grabar y transcribir con una API en la nube**: mejor calidad, pero necesita llave y red
    y contradice la Constitución II. Descartada.
- **Costo aceptado**: Menor accesibilidad, porque el usuario elige entre dos botones. Se mitiga con:
  - la nota de voz como acción principal, de un toque;
  - etiquetas con ícono y texto ("Grabar nota" / "Dictar texto");
  - áreas táctiles de al menos 48 dp y etiquetas `Semantics`.
- **Impacto en datos**: Columna `audio_path` en `entradas` (esquema v2, migración `onUpgrade`).
  Resuelve la duda de FR-006: una nota de voz por entrada.

## D-013 · Privacidad del dictado

- **Decisión**: Documentar que el dictado puede procesarse en línea en ambas plataformas.
- **Justificación**: En iOS el reconocimiento de Apple es un servicio por red. En Android puede
  usar servicios remotos, salvo que el usuario instale el paquete de idioma offline de la app
  de Google. La app no controla dónde se procesa.
- **Alternativas**: Afirmar que todo es local (incorrecto). Quitar el dictado (incumple el requisito).
- **Mitigación**: La nota de voz (D-012) se guarda solo en el dispositivo; el dictado es opcional.

## D-014 · Escritura atómica del agregado Ubicación

- **Decisión**: `UbicacionRepository.registrarEntrada(...)` hace en una sola transacción de
  SQLite (`db.transaction`) los tres pasos de guardar: crear la ubicación nueva (si aplica),
  insertar la entrada y poner la portada (si aplica). `GuardarEntrada` decide qué guardar y
  delega la escritura a ese método.
- **Justificación**:
  - Antes, los tres pasos eran escrituras independientes. Si fallaba el insert de la entrada,
    la ubicación nueva quedaba creada y vacía (registro huérfano).
  - La Ubicación es la raíz de su agregado (DDD): una Entrada no existe sin su lugar, así que
    persistir el agregado de forma atómica es responsabilidad de su repositorio.
  - No hay que pasar transacciones entre capas ni entre repositorios (Constitución V).
- **Alternativas**:
  - **Aceptar el riesgo** y documentarlo: es simple, pero deja datos inconsistentes posibles.
  - **Unit of Work como puerto del dominio** (Fowler, PoEAA): es más general, pero obliga a que
    todos los repositorios acepten la transacción. Es excesivo para un agregado de dos tablas.
    Se reconsidera si aparecen operaciones que crucen varios agregados.
- **Impacto**: `GuardarEntrada` ya no depende de `EntradaRepository`. `Entrada.copyWith`
  acepta `ubicacionId`.
