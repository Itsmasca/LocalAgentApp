import 'dart:io';

import 'package:flutter/material.dart';

/// Muestra una imagen guardada en el dispositivo o un placeholder
/// si no hay ruta o el archivo ya no existe.
class FotoLocal extends StatelessWidget {
  final String? ruta;
  final double? ancho;
  final double? alto;
  final BorderRadius borde;

  const FotoLocal({
    super.key,
    required this.ruta,
    this.ancho,
    this.alto,
    this.borde = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: ancho,
      height: alto,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.photo_outlined),
    );

    return ClipRRect(
      borderRadius: borde,
      child: ruta == null
          ? placeholder
          : Image.file(
              File(ruta!),
              width: ancho,
              height: alto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}
