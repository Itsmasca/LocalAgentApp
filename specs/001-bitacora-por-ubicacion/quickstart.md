# Quickstart: validar 001-bitacora-por-ubicacion

Requisitos: dispositivo Android físico (la cámara y el GPS del emulador son limitados),
permisos configurados según el README.

1. `flutter create --org com.example --project-name bitacora_campo .` y `flutter pub get`.
2. `flutter analyze` sin errores.
3. `flutter run` en el dispositivo.

## Recorrido de prueba

| # | Acción | Resultado esperado | Cubre |
|---|---|---|---|
| 1 | Abrir la app con la base vacía | Mensaje de lista vacía | US3 |
| 2 | Nueva entrada → aceptar permiso de ubicación | "Lugar nuevo" con coordenadas | FR-001, FR-003 |
| 3 | Tomar foto, dictar "cambié el capacitor", nombre "Casa prueba", Guardar | Vuelve a la lista con "Casa prueba" y su miniatura | US1, FR-005–008 |
| 4 | Sin moverse, otra Nueva entrada | "Estás en: Casa prueba" | RN-01 |
| 5 | Abrir "Casa prueba" | Transición Hero, mapa con marcador, 2 entradas ordenadas | US2 |
| 6 | Pulsar ícono de mapa | Se abre Google Maps en el punto | FR-009 |
| 7 | Guardar sin texto ni foto | Mensaje "La entrada necesita texto o una foto." | RN-03 |
| 8 | Negar el permiso de ubicación | Mensaje y botón Reintentar; la app no se cierra | SC-004 |
| 9 | Modo avión y repetir 3–5 | Funciona (el mapa puede salir sin mosaicos) | SC-003 |
