import 'package:flutter/material.dart';

import '../domain/entities/entrada.dart';
import '../domain/entities/paquete_evidencia.dart';
import '../domain/entities/ubicacion.dart';
import '../presentation/screens/compartir_screen.dart';
import '../presentation/screens/nueva_entrada_screen.dart';
import '../presentation/screens/ubicacion_detail_screen.dart';
import '../presentation/screens/ubicaciones_list_screen.dart';
import '../presentation/screens/visor_fotos_screen.dart';
import 'app_container.dart';

/// Nombres de rutas de la app.
abstract final class AppRoutes {
  static const lista = '/';
  static const detalle = '/ubicacion';        // argumento: Ubicacion
  static const nuevaEntrada = '/nueva-entrada'; // argumento: Ubicacion? (opcional)
  static const compartir = '/compartir';      // argumento: PaqueteEvidencia
  static const fotos = '/fotos';              // argumento: VisorFotosArgs
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
            observaciones: _c.observaciones,
            mapas: _c.mapas,
            speech: _c.speech,
            agregarObservacion: _c.agregarObservacion,
            prepararEvidencia: _c.prepararEvidencia,
          ),
        );

      case AppRoutes.fotos:
        final args = settings.arguments as VisorFotosArgs;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => VisorFotosScreen(args: args),
        );

      case AppRoutes.nuevaEntrada:
        final ubicacionFija = settings.arguments as Ubicacion?;
        // Regresa la Entrada guardada (o null si se canceló) para que la
        // pantalla anterior recargue o abra la conversación (spec 004).
        return MaterialPageRoute<Entrada?>(
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

      case AppRoutes.compartir:
        final paquete = settings.arguments as PaqueteEvidencia;
        // Regresa `true` si se compartió.
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => CompartirScreen(
            paquete: paquete,
            resumirEvidencia: _c.resumirEvidencia,
            compartirEvidencia: _c.compartirEvidencia,
            ajustes: _c.ajustes,
            compartir: _c.compartir,
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
