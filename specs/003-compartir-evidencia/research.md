# Research: Compartir evidencia de campo

Decisiones técnicas de la spec 003. Formato: Decisión / Justificación / Alternativas.
Continúa la numeración de las specs 001 y 002.

## D-015 · Generar el reporte formal como PDF con el paquete `pdf`

- **Decisión**: Usar el paquete `pdf` (Dart puro) para construir el documento página
  por página, con encabezado, pie con folio y número de página, y una sección por
  entrada con sus fotos.
- **Justificación**: Funciona sin internet (principio II), no necesita servicios del
  sistema, admite imágenes y paginación automática, y al ser Dart puro se puede
  ejecutar fuera del hilo de la interfaz para no congelar la app (SC-002).
- **Alternativas**: `printing` (agrega vista previa de impresión y fuentes de Google,
  pero las fuentes se descargan de internet y no se necesita imprimir);
  `syncfusion_flutter_pdf` (licencia comercial); generar HTML y convertirlo (depende
  de un WebView y no es fiable sin conexión).

## D-016 · Menú de compartir del sistema con `share_plus`

- **Decisión**: Usar `share_plus` para entregar el PDF o el mensaje (texto + fotos)
  al menú de compartir de Android/iOS.
- **Justificación**: Es el estándar de la comunidad Flutter, comparte varios archivos
  con texto en una sola acción, e informa si el usuario canceló (FR-008, edge case de
  cancelar sin error). Los datos solo salen cuando el usuario elige un destino (FR-009).
- **Alternativas**: Canal de plataforma propio (más código nativo que mantener);
  `url_launcher` con `mailto:`/`whatsapp:` (no adjunta archivos y obliga a elegir la
  app por el usuario).

## D-017 · Reducir las fotos con `flutter_image_compress`

- **Decisión**: Antes de insertar cada foto en el PDF, reducirla a un máximo de
  1280 px de lado largo con calidad JPEG 70. En el mensaje se comparten las fotos
  originales (ya están limitadas a 1600 px al capturarlas).
- **Justificación**: Las fotos guardadas pesan ~300–500 KB; 30 de ellas superan los
  10 MB (SC-003). A 1280 px / calidad 70 quedan en ~120–200 KB, y el texto de una
  placa sigue legible (FR-011). La compresión nativa es rápida, lo que ayuda a SC-002.
- **Alternativas**: Paquete `image` en Dart puro (decodificar y codificar 30 fotos
  puede tardar decenas de segundos en gama media); `dart:ui` con `targetWidth` (solo
  codifica PNG, que pesa más que el JPEG original).

## D-018 · Fuente incluida en la app para acentos, ñ y emojis

- **Decisión**: Incluir en `assets/fonts/` las fuentes Noto Sans (regular y negrita)
  y Noto Emoji (monocroma) como respaldo, ambas con licencia OFL.
- **Justificación**: Las fuentes estándar de PDF no cubren todos los caracteres
  (emojis, algunos signos); el edge case pide mostrar textos con emojis completos.
  Incluirlas evita descargarlas (principio II). Noto Emoji monocroma pesa ~2 MB,
  frente a ~10 MB de la versión a color.
- **Alternativas**: Fuentes de Google descargadas al vuelo (requiere internet);
  quitar los emojis del texto (pierde información del técnico).

## D-019 · Ajustes del técnico en una tabla clave-valor de SQLite (esquema v3)

- **Decisión**: Guardar los datos del responsable, la preferencia de incluir
  coordenadas y el consecutivo del folio en una tabla `ajustes (clave, valor)` en la
  base existente, con migración a la versión 3.
- **Justificación**: Reutiliza `sqflite`, ya aprobado; no agrega paquetes (principio V).
  Son pocos valores y se leen al abrir la pantalla de compartir.
- **Alternativas**: `shared_preferences` (paquete nuevo para tres valores); un archivo
  JSON propio (más código de lectura/escritura y sin transacciones para el folio).
- **Nota**: La versión 2 del esquema ya la usa la tabla `fotos` (varias fotos por
  entrada). La migración de notas de voz planeada en la spec 002 (`audio_path`)
  pasa a ser la siguiente versión disponible cuando se implemente.

## D-020 · Folio consecutivo por dispositivo

- **Decisión**: Formato `BC-AAAA-NNNN` (por ejemplo `BC-2026-0007`): año de generación
  y un consecutivo de 4 dígitos que se reinicia cada año. Se incrementa solo cuando un
  reporte formal se genera con éxito, en la misma operación que lo reserva.
- **Justificación**: Un consecutivo es más formal y fácil de citar ("reporte 7") que
  un código aleatorio; por clarificación, no se requiere verificar integridad (FR-016).
- **Alternativas**: Fecha y hora como folio (difícil de dictar por teléfono); UUID
  (único pero ilegible para un cliente).

## D-021 · Enlace al mapa universal

- **Decisión**: Usar `https://www.google.com/maps/search/?api=1&query=LAT,LNG`
  como enlace en el reporte y en el mensaje.
- **Justificación**: Abre en cualquier teléfono o computadora, con o sin la app de
  Google Maps instalada, y es el mismo destino del botón que ya existe en el detalle.
- **Alternativas**: URI `geo:` (no funciona en iOS ni en computadoras); enlace de
  OpenStreetMap (menos familiar para clientes).

## D-022 · Generación fuera del hilo de la interfaz y archivos temporales

- **Decisión**: Las fotos se comprimen de forma asíncrona y el PDF se arma con
  `Isolate.run`, mostrando progreso. Los archivos se escriben en
  `<temporal>/compartir/` y esa carpeta se vacía al iniciar cada nuevo compartir
  y al abrir la app.
- **Justificación**: Evita congelar la interfaz con reportes grandes (SC-002). Borrar
  justo después de cerrar el menú del sistema es inseguro: algunas apps (correo,
  WhatsApp) leen el archivo unos segundos después; limpiar en el siguiente uso cumple
  FR-014 sin romper el envío.
- **Alternativas**: Borrar al regresar del menú (puede adjuntar un archivo vacío);
  no borrar nunca (acumula basura).

## D-023 · Datos que salen del teléfono (principio II)

- **Decisión**: Esta función no envía nada por sí misma. El PDF o el mensaje solo
  salen cuando el usuario elige un destino en el menú del sistema. Lo que sale es
  exactamente lo que muestra el resumen (FR-007): entradas seleccionadas, sus fotos,
  y coordenadas solo si el usuario las dejó activas. Los datos del cliente (FR-017)
  van solo en ese reporte y no se guardan.
- **Justificación**: Cumple el principio II: se documenta qué sale, a dónde (la app
  que elige el usuario) y por qué (entregar evidencia).
- **Alternativas**: Ninguna; es un requisito de la constitución.
