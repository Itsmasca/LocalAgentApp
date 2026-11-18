import 'package:flutter/material.dart';

import '../../core/utils/formato.dart';
import '../../domain/entities/observacion.dart';

/// Observación simple en la conversación: burbuja de texto con su hora,
/// sangrada bajo su entrada y sin encabezado ni fotos (spec 004, FR-003).
class BurbujaObservacion extends StatelessWidget {
  final Observacion observacion;
  final VoidCallback? onMantener;

  const BurbujaObservacion(
      {super.key, required this.observacion, this.onMantener});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ancho = MediaQuery.sizeOf(context).width;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 3, 12, 3),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ancho * 0.8),
          child: Material(
            color: tema.colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onLongPress: onMantener,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(observacion.texto,
                          style: tema.textTheme.bodyMedium),
                    ),
                    const SizedBox(height: 2),
                    Text(formatearHora(observacion.creadaEn),
                        style: tema.textTheme.labelSmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
