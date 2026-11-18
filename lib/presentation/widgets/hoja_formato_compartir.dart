import 'package:flutter/material.dart';

import '../../domain/entities/paquete_evidencia.dart';

/// Hoja inferior para elegir cómo compartir (contracts/flujo-ui.md §1).
/// Devuelve el formato elegido o `null` si se cerró.
Future<FormatoCompartir?> mostrarHojaFormatoCompartir(BuildContext context) {
  return showModalBottomSheet<FormatoCompartir>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Compartir evidencia',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          _Opcion(
            icono: Icons.picture_as_pdf_outlined,
            titulo: 'Reporte formal',
            detalle: 'PDF con folio, ideal para clientes',
            formato: FormatoCompartir.reporteFormal,
          ),
          _Opcion(
            icono: Icons.chat_outlined,
            titulo: 'Mensaje',
            detalle: 'Texto y fotos para WhatsApp o correo',
            formato: FormatoCompartir.mensaje,
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _Opcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final FormatoCompartir formato;

  const _Opcion({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.formato,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      leading: Icon(icono),
      title: Text(titulo),
      subtitle: Text(detalle),
      onTap: () => Navigator.pop(context, formato),
    );
  }
}
