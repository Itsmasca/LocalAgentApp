# Contrato: formatos de salida

Fechas con el formato existente `dd/mm/aaaa hh:mm` (`formatearFecha`) y
coordenadas con 5 decimales (`formatearCoordenadas`). Enlace al mapa según D-021.
Las partes marcadas *(coordenadas)* se omiten si `incluirCoordenadas == false`.

## Reporte formal (PDF)

Tamaño carta, vertical, márgenes de 2 cm, fuente Noto Sans (D-018).

### Encabezado (primera página)

```text
REPORTE DE EVIDENCIA DE CAMPO                       Folio: BC-2026-0007
Generado: 17/11/2026 18:42

Lugar:        Casa Sra. López
Ubicación:    19.43260, -99.13320  ·  Ver en mapa (enlace)   (coordenadas)
Periodo:      03/11/2026 10:15 – 17/11/2026 18:30
Contenido:    3 entradas · 7 fotos

Responsable:  Juan Pérez · Clima Pérez · 999 123 4567         (si existe)
Cliente:      María López · Calle 60 #123, Centro, Mérida      (si se capturó)
```

### Cuerpo (una sección por entrada, cronológico)

```text
Entrada 1 de 3 — 03/11/2026 10:15
<texto completo de la entrada; respeta saltos de línea; puede continuar en otra página>

[foto] [foto]        ← 2 por fila, proporción conservada, ancho de media columna
[foto] [Foto no disponible]
```

- Una entrada sin texto muestra solo sus fotos; sin fotos, solo su texto.
- Si las fotos no caben, siguen en la página siguiente con el título
  "Entrada 1 de 3 (continuación)".

### Pie (todas las páginas)

```text
Generado con Bitácora de Campo el 17/11/2026 18:42 · Folio BC-2026-0007 · Página 2 de 4
```

### Archivo

Nombre: `Reporte_<lugar-sin-acentos-ni-espacios>_<folio>.pdf`, por ejemplo
`Reporte_Casa_Sra_Lopez_BC-2026-0007.pdf`. Asunto al compartir:
`Reporte de evidencia – <lugar> – <folio>`.

## Mensaje

Texto plano, apto para WhatsApp y correo. Las fotos van adjuntas en el orden de las
entradas (FR-015).

```text
📍 Casa Sra. López
19.43260, -99.13320                                            (coordenadas)
https://www.google.com/maps/search/?api=1&query=19.4326,-99.1332 (coordenadas)

🗓 03/11/2026 10:15
Se cambió el capacitor del condensador. Queda pendiente limpiar el serpentín.

🗓 17/11/2026 18:30
Limpieza de serpentín terminada.

— Enviado desde Bitácora de Campo
```

- Una sola entrada: mismo formato con un solo bloque 🗓.
- Entrada sin texto: solo la línea de fecha.
- No incluye folio, responsable ni cliente (son propios del reporte formal).
