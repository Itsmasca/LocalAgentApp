import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/routes.dart';
import '../../core/utils/formato.dart';
import '../../domain/entities/entrada.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/repositories/entrada_repository.dart';
import '../../domain/services/device_services.dart';
import '../widgets/estado_vista.dart';
import '../widgets/foto_local.dart';

/// Vista de detalle: portada (Hero), mapa interactivo y entradas del lugar.
class UbicacionDetailScreen extends StatefulWidget {
  final Ubicacion ubicacion;
  final EntradaRepository entradas;
  final MapLauncher mapas;

  const UbicacionDetailScreen({
    super.key,
    required this.ubicacion,
    required this.entradas,
    required this.mapas,
  });

  @override
  State<UbicacionDetailScreen> createState() => _UbicacionDetailScreenState();
}

class _UbicacionDetailScreenState extends State<UbicacionDetailScreen> {
  late Future<List<Entrada>> _futuro;

  Ubicacion get _u => widget.ubicacion;

  @override
  void initState() {
    super.initState();
    _futuro = widget.entradas.obtenerPorUbicacion(_u.id!);
  }

  void _recargar() => setState(
      () => _futuro = widget.entradas.obtenerPorUbicacion(_u.id!));

  Future<void> _abrirMaps() async {
    try {
      await widget.mapas.abrirEnMapas(_u.latitud, _u.longitud);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  Future<void> _agregarEntrada() async {
    final guardo =
        await Navigator.pushNamed(context, AppRoutes.nuevaEntrada, arguments: _u);
    if (guardo == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(_u.latitud, _u.longitud);

    return Scaffold(
      appBar: AppBar(
        title: Text(_u.nombre),
        actions: [
          IconButton(
            tooltip: 'Abrir en Google Maps',
            icon: const Icon(Icons.map_outlined),
            onPressed: _abrirMaps,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarEntrada,
        icon: const Icon(Icons.add),
        label: const Text('Agregar aquí'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Hero(
            tag: _u.heroTag,
            child: FotoLocal(
              ruta: _u.fotoPortada,
              alto: 220,
              ancho: double.infinity,
              borde: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
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
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Historial',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          FutureBuilder<List<Entrada>>(
            future: _futuro,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return VistaError(error: snapshot.error, onReintentar: _recargar);
              }
              final entradas = snapshot.data ?? const [];
              if (entradas.isEmpty) {
                return const VistaVacia(
                    icono: Icons.notes, mensaje: 'Sin entradas todavía.');
              }
              return Column(
                children: entradas.map((e) => _TarjetaEntrada(entrada: e)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TarjetaEntrada extends StatelessWidget {
  final Entrada entrada;

  const _TarjetaEntrada({required this.entrada});

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entrada.imagenPath != null)
            FotoLocal(
              ruta: entrada.imagenPath,
              alto: 180,
              ancho: double.infinity,
              borde: BorderRadius.zero,
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatearFecha(entrada.creadaEn), style: estilos.labelMedium),
                if (entrada.texto.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(entrada.texto, style: estilos.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
