# Contrato: flujo de interfaz

Botones con ícono y texto, área táctil ≥ 48 dp, etiquetas `Semantics`.

## Puntos de entrada (FR-001)

| Dónde | Control | Abre |
|---|---|---|
| Detalle de ubicación, barra superior | Ícono "Compartir" (deshabilitado sin entradas, con tooltip "Aún no hay entradas para compartir") | Hoja de formato con toda la ubicación |
| Tarjeta de entrada en el historial | Botón "Compartir" en la tarjeta y mantener presionada la tarjeta | Hoja de formato con esa sola entrada |

## 1. Hoja de formato (bottom sheet)

```text
Compartir evidencia
[📄 Reporte formal]   PDF con folio, ideal para clientes
[💬 Mensaje]          Texto y fotos para WhatsApp o correo
```

Un toque elige el formato y abre la pantalla "Compartir".

## 2. Pantalla "Compartir"

```text
← Compartir · Reporte formal

Entradas                             [Todas ✓]
 ☑ 03/11/2026 10:15  Se cambió el capacitor…  📷 3
 ☑ 17/11/2026 18:30  Limpieza de serpentín…   📷 4
                     (solo si se compartió la ubicación completa)

[✓] Incluir coordenadas y enlace al mapa

Cliente (opcional)          ← solo en reporte formal
 Nombre   [            ]
 Dirección[            ]

Responsable: Juan Pérez · Editar      ← solo en reporte formal;
                                         "Agregar mis datos" si no existen

Resumen: 2 entradas · 7 fotos · con coordenadas
⚠ 1 foto ya no está en el teléfono y se omitirá

            [ Enviar ]
```

- "Enviar" se deshabilita si no queda ninguna entrada marcada.
- Mientras genera: indicador de progreso con "Preparando reporte… 40 %"; la
  pantalla no se puede abandonar a medias sin confirmar.
- Al volver del menú del sistema:
  - `enviado` → regresa al detalle con "Evidencia compartida".
  - `cancelado` → se queda en la pantalla con la misma selección, sin mensaje.
  - `noDisponible` → mensaje y botón "Guardar en el teléfono".
  - error → mensaje de `AppException`; la selección se conserva (FR-013).

## 3. Datos del responsable

Diálogo desde "Agregar mis datos" / "Editar":

```text
Tus datos para los reportes
 Nombre*   [            ]
 Negocio   [            ]
 Teléfono  [            ]
[Omitir]            [Guardar]
```

- Primera vez que se elige "Reporte formal" sin datos guardados: el diálogo se
  ofrece una vez automáticamente (historia 4, escenario 1). "Omitir" continúa sin
  responsable y no vuelve a ofrecerse en esa pantalla.
