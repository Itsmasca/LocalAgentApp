import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';

/// Vista de error reutilizable para los FutureBuilder.
class VistaError extends StatelessWidget {
  final Object? error;
  final VoidCallback onReintentar;

  const VistaError({super.key, required this.error, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final mensaje = mensajeDeError(error ?? 'Ocurrió un error.');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Vista vacía reutilizable.
class VistaVacia extends StatelessWidget {
  final IconData icono;
  final String mensaje;

  const VistaVacia({super.key, required this.icono, required this.mensaje});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 56),
              const SizedBox(height: 12),
              Text(mensaje, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

/// Convierte cualquier error en un mensaje para el usuario.
String mensajeDeError(Object error) => switch (error) {
      AppException e => e.mensaje,
      String s => s,
      _ => 'Ocurrió un error inesperado.',
    };

/// Muestra el mensaje de una excepción (o un texto) en un SnackBar.
void mostrarError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(mensajeDeError(error))));
}
