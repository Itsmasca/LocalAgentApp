import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/formato.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/services/device_services.dart';
import 'estado_vista.dart';

/// Hoja inferior con el mapa interactivo del lugar y el acceso a Google Maps
/// (spec 004, D-031; conserva FR-009 de la spec 001).
Future<void> mostrarHojaMapa(
    BuildContext context, Ubicacion ubicacion, MapLauncher mapas) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => HojaMapaUbicacion(ubicacion: ubicacion, mapas: mapas),
  );
}

class HojaMapaUbicacion extends StatelessWidget {
  final Ubicacion ubicacion;
  final MapLauncher mapas;

  const HojaMapaUbicacion(
      {super.key, required this.ubicacion, required this.mapas});

  Future<void> _abrirMaps(BuildContext context) async {
    try {
      await mapas.abrirEnMapas(ubicacion.latitud, ubicacion.longitud);
    } catch (e) {
      if (context.mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(ubicacion.latitud, ubicacion.longitud);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ubicacion.nombre,
                style: Theme.of(context).textTheme.titleMedium),
            Text(formatearCoordenadas(ubicacion.latitud, ubicacion.longitud),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 240,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: punto,
                    initialZoom: 17,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bitacora_campo',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: punto,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin,
                            size: 40, color: Colors.red),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _abrirMaps(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Abrir en Google Maps'),
            ),
          ],
        ),
      ),
    );
  }
}
