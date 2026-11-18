import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../domain/entities/entrada.dart';
import '../../domain/entities/observacion.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/entities/visita.dart';
import '../../domain/repositories/entrada_repository.dart';
import '../../domain/repositories/observacion_repository.dart';
import '../../domain/services/device_services.dart';
import '../../domain/usecases/agregar_observacion.dart';
import '../../domain/usecases/preparar_evidencia.dart';
import '../conversacion/elementos_conversacion.dart';
import '../widgets/barra_redaccion.dart';
import '../widgets/burbuja_observacion.dart';
import '../widgets/estado_vista.dart';
import '../widgets/foto_local.dart';
import '../widgets/hoja_formato_compartir.dart';
import '../widgets/hoja_mapa_ubicacion.dart';
import '../widgets/mensaje_entrada.dart';
import '../widgets/separador_dia.dart';

/// Detalle de un lugar como conversación (spec 004): cada entrada es un
/// mensaje destacado y debajo van sus observaciones; lo más reciente queda
/// abajo, junto a la barra para escribir.
///
/// La portada (Hero) vive en la AppBar y el mapa en una hoja inferior para
/// dejar el espacio a los mensajes (D-031).
class UbicacionDetailScreen extends StatefulWidget {
  final Ubicacion ubicacion;
  final EntradaRepository entradas;
  final ObservacionRepository observaciones;
  final MapLauncher mapas;
  final SpeechService speech;
  final AgregarObservacion agregarObservacion;
  final PrepararEvidencia prepararEvidencia;

  const UbicacionDetailScreen({
    super.key,
    required this.ubicacion,
    required this.entradas,
    required this.observaciones,
    required this.mapas,
    required this.speech,
    required this.agregarObservacion,
    required this.prepararEvidencia,
  });

  @override
  State<UbicacionDetailScreen> createState() => _UbicacionDetailScreenState();
}

class _UbicacionDetailScreenState extends State<UbicacionDetailScreen> {
  late Future<List<Visita>> _futuro;

  Ubicacion get _u => widget.ubicacion;

  @override
  void initState() {
    super.initState();
    _futuro = widget.entradas.obtenerVisitas(_u.id!);
  }

  void _recargar() => setState(() {
        _futuro = widget.entradas.obtenerVisitas(_u.id!);
      });

  /// "Nueva visita": abre el formulario de entrada para este lugar (D-030).
  Future<void> _nuevaVisita() async {
    final guardada = await Navigator.pushNamed<Object?>(
        context, AppRoutes.nuevaEntrada,
        arguments: _u);
    if (guardada is Entrada) _recargar();
  }

  Future<void> _enviarObservacion(String texto) async {
    try {
      await widget.agregarObservacion(ubicacionId: _u.id!, texto: texto);
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
      rethrow; // La barra conserva el texto para reintentar.
    }
  }

  /// Mantener presionada una observación → Eliminar → confirmar (FR-012).
  Future<void> _opcionesObservacion(Observacion o) async {
    final eliminar = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Eliminar'),
          onTap: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (eliminar != true || !mounted) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta observación?'),
        content: Text(o.texto, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    try {
      await widget.observaciones.eliminar(o.id!);
      _recargar();
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  /// Compartir toda la ubicación o solo [soloEsta] (spec 003, FR-001).
  Future<void> _compartir({Entrada? soloEsta}) async {
    final formato = await mostrarHojaFormatoCompartir(context);
    if (formato == null || !mounted) return;
    try {
      final paquete = await widget.prepararEvidencia(_u,
          formato: formato, soloEsta: soloEsta);
      if (!mounted) return;
      await Navigator.pushNamed(context, AppRoutes.compartir,
          arguments: paquete);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Visita>>(
      future: _futuro,
      builder: (context, snapshot) {
        // Al recargar, FutureBuilder conserva los datos anteriores: no parpadea.
        final hayVisitas = (snapshot.data ?? const []).isNotEmpty;

        return Scaffold(
          appBar: _appBar(hayVisitas),
          body: Column(
            children: [
              Expanded(child: _cuerpo(snapshot)),
              BarraRedaccion(
                speech: widget.speech,
                onEnviar: _enviarObservacion,
                onNuevaVisita: _nuevaVisita,
                habilitada: hayVisitas,
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(bool hayVisitas) {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Hero(
            tag: _u.heroTag,
            child: FotoLocal(
              ruta: _u.fotoPortada,
              ancho: 40,
              alto: 40,
              borde: BorderRadius.circular(20),
              cacheWidth: 160,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(_u.nombre, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: [
        // Deshabilitado mientras no haya entradas (edge case de la spec 003).
        IconButton(
          tooltip: hayVisitas
              ? 'Compartir evidencia'
              : 'Aún no hay entradas para compartir',
          icon: const Icon(Icons.share_outlined),
          onPressed: hayVisitas ? () => _compartir() : null,
        ),
        IconButton(
          tooltip: 'Mapa del lugar',
          icon: const Icon(Icons.map_outlined),
          onPressed: () => mostrarHojaMapa(context, _u, widget.mapas),
        ),
      ],
    );
  }

  Widget _cuerpo(AsyncSnapshot<List<Visita>> snapshot) {
    if (snapshot.hasError) {
      return VistaError(error: snapshot.error, onReintentar: _recargar);
    }
    final visitas = snapshot.data;
    if (visitas == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (visitas.isEmpty) {
      return VistaVacia(
        icono: Icons.forum_outlined,
        mensaje: 'Aún no hay visitas en este lugar.',
        accion: FilledButton.icon(
          onPressed: _nuevaVisita,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Registrar primera visita'),
        ),
      );
    }

    final elementos = armarElementosConversacion(visitas);
    // Lista invertida: arranca abajo, en lo más reciente, y solo construye
    // lo visible (D-027). El orden real vive en armarElementosConversacion.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: elementos.length,
      itemBuilder: (_, i) {
        final e = elementos[elementos.length - 1 - i];
        return switch (e) {
          SeparadorDia(:final dia) => SeparadorDiaVista(dia: dia),
          MensajeEntrada(:final entrada) => TarjetaVisita(
              entrada: entrada,
              onCompartir: () => _compartir(soloEsta: entrada),
            ),
          MensajeObservacion(:final observacion) => BurbujaObservacion(
              observacion: observacion,
              onMantener: () => _opcionesObservacion(observacion),
            ),
        };
      },
    );
  }
}
