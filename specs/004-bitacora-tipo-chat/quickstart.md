# Quickstart: validar la bitácora tipo chat

## Requisitos

- Teléfono o emulador Android con cámara o galería y la app instalada en la versión anterior (para la migración).
- `tool/simular_ubicacion.ps1` para fijar la posición en el emulador.

```bash
flutter pub get
flutter test                 # pruebas de dominio y de armarElementosConversacion
flutter run
```

## Pruebas automáticas esperadas

| Archivo | Cubre |
|---|---|
| `test/domain/agregar_observacion_test.dart` | RN-09 (vacío, espacios, 2 001 caracteres) y RN-10 (se asigna a la entrada más reciente; lugar sin entradas → error) |
| `test/presentation/elementos_conversacion_test.dart` | Orden entrada → observaciones, separador al cambiar de día, sin separadores duplicados el mismo día |

## Escenarios manuales

1. **Migración (SC-004, FR-013).** Con datos de la versión anterior (2 lugares, 3 entradas con 0, 1 y 4 fotos), actualiza la app y abre cada lugar. **Esperado**: todas las entradas aparecen como mensajes destacados, en orden ascendente y sin observaciones.
2. **Conversación (US1).** Abre el lugar con 3 entradas. **Esperado**: la vista arranca abajo, en la más reciente; hay separadores de fecha; la entrada de 4 fotos se ve en una cuadrícula de 2×2 y al tocar la tercera foto el visor se abre en "3/4" y permite hacer zoom.
3. **Observación rápida (US2, SC-001).** Escribe "Se cambió el capacitor" y envía, cronometrando. **Esperado**: menos de 10 s, la burbuja aparece bajo la última entrada con la hora y el campo queda vacío. Cierra la app por completo, vuelve a abrirla y la observación sigue ahí.
4. **Dictado.** Pulsa 🎤 y di "revisar presión del gas". **Esperado**: el texto queda en el campo sin enviarse. Niega el permiso de micrófono y repite: aparece un mensaje y se puede seguir escribiendo.
5. **Validaciones.** Con el campo vacío o solo con espacios, enviar está deshabilitado. Pega 2 100 caracteres: el campo se detiene en 2 000.
6. **Nueva visita (US3).** Pulsa 📷, agrega 2 fotos y guarda. **Esperado**: un mensaje destacado nuevo al final. Envía "Listo": la burbuja queda bajo la entrada nueva. Abre otra "Nueva visita" y cancela: no se crea nada.
7. **Entrada solo con texto (US3-4).** Crea una visita sin fotos. **Esperado**: también se ve como mensaje destacado.
8. **Alta desde la lista (US3-6).** Con el GPS simulado en un punto nuevo, crea una entrada desde la pantalla principal. **Esperado**: al guardar se abre la conversación del lugar nuevo con esa entrada.
9. **Orden de la lista (FR-014).** Agrega una observación al lugar que está más abajo en la lista principal. **Esperado**: sube al primer lugar.
10. **Eliminar (FR-012).** Mantén presionada una observación, elige "Eliminar" y cancela: sigue ahí. Repite y confirma: desaparece. Elimina el lugar desde la lista: al crearlo de nuevo no reaparecen observaciones antiguas.
11. **Offline (SC-005).** En modo avión, crea una visita y dos observaciones. **Esperado**: todo se guarda; solo el mapa de la hoja inferior no carga sus mosaicos.
12. **Fallas.** Borra a mano el archivo de una foto. **Esperado**: su celda muestra el marcador y el resto del mensaje se ve bien. Con el teclado abierto, el último mensaje y la barra siguen visibles.
13. **Rendimiento (SC-003).** Con un lugar sembrado con 100 entradas y 300 observaciones (script de semilla en modo depuración), ábrelo. **Esperado**: lo más reciente aparece en menos de 1 s.
14. **Hero y mapa.** Desde la lista, abre un lugar con portada: la miniatura vuela al avatar de la AppBar. Pulsa 🗺: la hoja muestra el mapa y "Abrir en Google Maps" funciona.
