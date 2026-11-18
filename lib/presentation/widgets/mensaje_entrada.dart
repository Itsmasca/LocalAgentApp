import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/utils/formato.dart';
import '../../domain/entities/entrada.dart';
import '../screens/visor_fotos_screen.dart';
import 'mosaico_fotos.dart';

/// Mensaje destacado de una visita en la conversación (spec 004, FR-002):
/// fotos en primer plano, etiqueta "VISITA" con fecha y hora, y el texto.
class TarjetaVisita extends StatelessWidget {
  final Entrada entrada;

  /// Compartir esta entrada (spec 003). Si viene, se muestra el botón y
  /// mantener presionada la tarjeta también comparte (FR-015).
  final VoidCallback? onCompartir;

  const TarjetaVisita({super.key, required this.entrada, this.onCompartir});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final estilos = tema.textTheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      elevation: 2,
      color: colores.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: onCompartir,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entrada.fotos.isNotEmpty)
              MosaicoFotos(
                fotos: entrada.fotos,
                onTocar: (i) => Navigator.pushNamed(context, AppRoutes.fotos,
                    arguments: VisorFotosArgs(entrada.fotos, i)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 16, color: colores.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    'VISITA · ${formatearFecha(entrada.creadaEn)}',
                    style: estilos.labelMedium?.copyWith(
                      color: colores.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            if (entrada.texto.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Text(entrada.texto,
                    style: estilos.bodyLarge
                        ?.copyWith(color: colores.onPrimaryContainer)),
              ),
            if (onCompartir != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style:
                        TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    onPressed: onCompartir,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Compartir'),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
