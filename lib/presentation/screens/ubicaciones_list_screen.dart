import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/utils/formato.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/repositories/ubicacion_repository.dart';
import '../widgets/app_drawer.dart';
import '../widgets/estado_vista.dart';
import '../widgets/foto_local.dart';

/// Vista de lista: todas las ubicaciones, la más activa primero.
class UbicacionesListScreen extends StatefulWidget {
  final UbicacionRepository ubicaciones;

  const UbicacionesListScreen({super.key, required this.ubicaciones});

  @override
  State<UbicacionesListScreen> createState() => _UbicacionesListScreenState();
}

class _UbicacionesListScreenState extends State<UbicacionesListScreen> {
  late Future<List<Ubicacion>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.ubicaciones.obtenerTodas();
  }

  void _recargar() =>
      setState(() => _futuro = widget.ubicaciones.obtenerTodas());

  Future<void> _nuevaEntrada() async {
    final guardo = await Navigator.pushNamed(context, AppRoutes.nuevaEntrada);
    if (guardo == true) _recargar();
  }

  Future<void> _abrirDetalle(Ubicacion u) async {
    await Navigator.pushNamed(context, AppRoutes.detalle, arguments: u);
    _recargar(); // pudo haber entradas nuevas o portada nueva
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis ubicaciones')),
      drawer: AppDrawer(
        rutaActual: AppRoutes.lista,
        onNuevaEntrada: _nuevaEntrada,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaEntrada,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Nueva entrada'),
      ),
      body: FutureBuilder<List<Ubicacion>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return VistaError(error: snapshot.error, onReintentar: _recargar);
          }
          final lista = snapshot.data ?? const [];
          if (lista.isEmpty) {
            return const VistaVacia(
              icono: Icons.travel_explore,
              mensaje: 'Aún no tienes lugares.\n'
                  'Crea tu primera entrada y se registrará donde estés.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final u = lista[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Hero(
                    tag: u.heroTag,
                    child: FotoLocal(ruta: u.fotoPortada, ancho: 56, alto: 56),
                  ),
                  title: Text(u.nombre),
                  subtitle: Text(formatearCoordenadas(u.latitud, u.longitud)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirDetalle(u),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
