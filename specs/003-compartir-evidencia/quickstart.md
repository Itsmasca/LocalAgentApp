# Quickstart: validar "Compartir evidencia"

Recorrido para comprobar la spec 003 de punta a punta. Formatos esperados en
[contracts/formatos-salida.md](./contracts/formatos-salida.md); pantallas en
[contracts/flujo-ui.md](./contracts/flujo-ui.md).

## Preparación

```powershell
flutter pub get
flutter test                       # pruebas de dominio de la 003 en verde
flutter run -d emulator-5554
.\tool\simular_ubicacion.ps1 zocalo
```

Datos: una ubicación "Casa prueba" con 3 entradas (una con 3 fotos, una con 1 foto
y texto con emoji 👍, una solo con texto). Tener instalada alguna app que reciba
archivos (Gmail, Drive o "Archivos").

## Escenarios

| # | Pasos | Resultado esperado | Cubre |
|---|---|---|---|
| 1 | Detalle → Compartir → Reporte formal → Enviar → "Guardar en Archivos" | PDF con encabezado, folio `BC-AAAA-0001`, 3 entradas en orden cronológico, 4 fotos, pie con página "x de y" | Historia 1, FR-004, FR-010 |
| 2 | Abrir el PDF en una computadora y tocar "Ver en mapa" | Se abre el punto correcto en el mapa | FR-005, D-021 |
| 3 | Repetir el escenario 1 | Folio `…-0002` | D-020 |
| 4 | Compartir → Reporte formal, desmarcar la entrada solo-texto | El PDF tiene 2 entradas; resumen "2 entradas · 4 fotos" | FR-003, FR-007 |
| 5 | Desactivar "Incluir coordenadas", generar reporte y mensaje | Ninguno contiene coordenadas ni enlace; al volver a abrir Compartir el interruptor sigue apagado | Historia 3, FR-006, SC-007 |
| 6 | Mantener presionada la entrada con emoji → Mensaje → WhatsApp (o Gmail) | Llega el texto formateado con 📍/🗓 y la foto adjunta; el emoji se ve bien | Historia 2, FR-015 |
| 7 | Primer reporte sin datos del responsable | Se ofrece el diálogo; "Omitir" genera el reporte sin esa sección | Historia 4 esc. 1 |
| 8 | Guardar responsable; escribir cliente y dirección; generar; volver a Compartir | El PDF muestra responsable y cliente; en el siguiente reporte el responsable sigue y los campos del cliente están vacíos | Historia 4, FR-012, FR-017 |
| 9 | Activar modo avión y generar un reporte | Se genera igual; solo el envío depende de la app destino | FR-009, SC-006 |
| 10 | Borrar a mano una foto (`adb shell run-as … rm app_flutter/fotos/<archivo>`) y compartir | Aviso "1 foto ya no está…"; el PDF muestra "Foto no disponible" | Edge case |
| 11 | Abrir el menú del sistema y cancelar | Sin error; la selección se conserva | FR-013, edge case |
| 12 | Ubicación sin entradas | Ícono Compartir deshabilitado con tooltip | Edge case |
| 13 | Reporte de 10 entradas × 3 fotos | Tarda < 10 s, pesa < 10 MB, la placa de un equipo se lee en el PDF | SC-002, SC-003, FR-011 |
| 14 | Compartir dos veces seguidas y revisar `<temporal>/compartir/` | Solo queda el archivo del último envío | FR-014, D-022 |

Para medir el escenario 13:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell run-as com.example.bitacora_campo ls -l cache/compartir
```

## Criterio de salida

Los 14 escenarios pasan en el emulador y al menos los escenarios 1, 6, 9 y 13 en un
teléfono físico. `flutter analyze` sin errores.
