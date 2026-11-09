import 'package:flutter/material.dart';

import '../../app/routes.dart';

/// Menú lateral principal.
class AppDrawer extends StatelessWidget {
  final String rutaActual;

  /// Acción para "Nueva entrada"; la pantalla que abre el drawer decide
  /// qué hacer al volver (por ejemplo, recargar su lista).
  final VoidCallback? onNuevaEntrada;

  const AppDrawer({super.key, required this.rutaActual, this.onNuevaEntrada});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: esquema.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.location_on, size: 40, color: esquema.primary),
                const SizedBox(height: 8),
                Text('Bitácora de Campo',
                    style: Theme.of(context).textTheme.titleLarge),
                const Text('Tu memoria por lugar'),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('Mis ubicaciones'),
            selected: rutaActual == AppRoutes.lista,
            onTap: () {
              Navigator.pop(context);
              if (rutaActual != AppRoutes.lista) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.lista, (_) => false);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_a_photo_outlined),
            title: const Text('Nueva entrada'),
            onTap: () {
              Navigator.pop(context);
              if (onNuevaEntrada != null) {
                onNuevaEntrada!();
              } else {
                Navigator.pushNamed(context, AppRoutes.nuevaEntrada);
              }
            },
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Bitácora de Campo',
            applicationVersion: '1.0.0',
            aboutBoxChildren: [
              Text('Historial de trabajo organizado por ubicación. '
                  'Todos los datos se guardan solo en este dispositivo.'),
            ],
          ),
        ],
      ),
    );
  }
}
