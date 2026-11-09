import 'package:flutter/material.dart';

import '../domain/entities/ubicacion.dart';
import '../presentation/screens/nueva_entrada_screen.dart';
import '../presentation/screens/ubicacion_detail_screen.dart';
import '../presentation/screens/ubicaciones_list_screen.dart';
import 'app_container.dart';

/// Nombres de rutas de la app.
abstract final class AppRoutes {
  static const lista = '/';
  static const detalle = '/ubicacion';        // argumento: Ubicacion
  static const nuevaEntrada = '/nueva-entrada'; // argumento: Ubicacion? (opcional)
}

/// Construye cada pantalla inyectándole solo las dependencias que necesita.
class AppRouter {
  final AppContainer _c;

  AppRouter(this._c);

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.lista:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => UbicacionesListScreen(ubicaciones: _c.ubicaciones),
        );

      case AppRoutes.detalle:
        final ubicacion = settings.arguments as Ubicacion;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => UbicacionDetailScreen(
            ubicacion: ubicacion,
            entradas: _c.entradas,
            mapas: _c.mapas,
          ),
        );

      case AppRoutes.nuevaEntrada:
        final ubicacionFija = settings.arguments as Ubicacion?;
        // Regresa `true` si se guardó algo, para que la pantalla anterior recargue.
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => NuevaEntradaScreen(
            ubicacionFija: ubicacionFija,
            location: _c.location,
            media: _c.media,
            speech: _c.speech,
            resolverUbicacion: _c.resolverUbicacion,
            guardarEntrada: _c.guardarEntrada,
          ),
        );

      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('No encontrado')),
            body: Center(child: Text('Ruta desconocida: ${settings.name}')),
          ),
        );
    }
  }
}
