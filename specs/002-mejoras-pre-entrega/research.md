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
