import 'package:flutter/material.dart';

import '../../core/utils/formato.dart';

/// Separador con el día ("Hoy", "Ayer", "12 nov 2026") entre mensajes
/// de días distintos (spec 004, FR-005).
class SeparadorDiaVista extends StatelessWidget {
  final DateTime dia;

  const SeparadorDiaVista({super.key, required this.dia});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final linea = Expanded(
        child: Divider(color: tema.colorScheme.outlineVariant, height: 1));
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          linea,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(formatearDia(dia),
                style: tema.textTheme.labelMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant)),
          ),
          linea,
        ],
      ),
    );
  }
}
