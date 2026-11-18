import 'package:flutter/material.dart';

import '../../core/utils/formato.dart';
import '../../domain/entities/entrada.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/services/device_services.dart';
import '../../domain/usecases/guardar_entrada.dart';
import '../../domain/usecases/resolver_ubicacion.dart';
import '../widgets/boton_dictado.dart';
import '../widgets/estado_vista.dart';
import '../widgets/foto_local.dart';

/// Formulario de creación: GPS automático, cámara/galería y dictado.
///
/// Si [ubicacionFija] viene de la pantalla de detalle, la entrada se
/// agrega a ese lugar. Si no, se aplica la regla de [ResolverUbicacion].
/// Al guardar regresa la [Entrada] creada; al cancelar, `null`.
class NuevaEntradaScreen extends StatefulWidget {
  final Ubicacion? ubicacionFija;
  final LocationService location;
  final MediaService media;
  final SpeechService speech;
  final ResolverUbicacion resolverUbicacion;
  final GuardarEntrada guardarEntrada;

  const NuevaEntradaScreen({
    super.key,
    this.ubicacionFija,
    required this.location,
    required this.media,
    required this.speech,
    required this.resolverUbicacion,
    required this.guardarEntrada,
  });

  @override
  State<NuevaEntradaScreen> createState() => _NuevaEntradaScreenState();
}

class _NuevaEntradaScreenState extends State<NuevaEntradaScreen> {
  final _textoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _dictado = GlobalKey<BotonDictadoState>();

  Coordenadas? _coordenadas;
  Ubicacion? _ubicacionDetectada;
  String? _errorUbicacion;
  final List<String> _fotos = [];

  bool _buscandoUbicacion = true;
  bool _escuchando = false;
  bool _guardando = false;

  /// Si la entrada se guardó, sus fotos ya son de la base; si no, al salir
  /// se borran para no dejar archivos huérfanos.
  bool _guardada = false;

  int get _espacioFotos => Entrada.maxFotos - _fotos.length;

  Ubicacion? get _destino => widget.ubicacionFija ?? _ubicacionDetectada;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    // BotonDictado detiene el micrófono en su propio dispose.
    if (!_guardada) {
      for (final ruta in _fotos) {
        widget.media.descartar(ruta);
      }
    }
    _textoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  // ---------- GPS ----------
  Future<void> _obtenerUbicacion() async {
    setState(() {
      _buscandoUbicacion = true;
      _errorUbicacion = null;
    });
    try {
      final c = await widget.location.obtenerPosicionActual();
      final detectada = widget.ubicacionFija == null
          ? await widget.resolverUbicacion(c)
          : null;
      if (!mounted) return;
      setState(() {
        _coordenadas = c;
        _ubicacionDetectada = detectada;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorUbicacion = mensajeDeError(e));
      mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  // ---------- Cámara / galería ----------
  Future<void> _agregarFotos({required bool camara}) async {
    if (_espacioFotos <= 0) {
      mostrarError(context, 'Máximo ${Entrada.maxFotos} fotos por entrada.');
      return;
    }
    try {
      final nuevas = camara
          ? [await widget.media.tomarFoto()].whereType<String>().toList()
          : await widget.media.elegirDeGaleria(limite: _espacioFotos);
      if (nuevas.isEmpty) return;
      if (!mounted) {
        // La pantalla se cerró mientras se elegían: no se van a guardar.
        for (final r in nuevas) {
          widget.media.descartar(r);
        }
        return;
      }
      setState(() => _fotos.addAll(nuevas));
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  void _quitarFoto(int i) {
    final ruta = _fotos[i];
    setState(() => _fotos.removeAt(i));
    widget.media.descartar(ruta);
  }

  // ---------- Guardar ----------
  Future<void> _guardar() async {
    final c = _coordenadas;
    if (c == null) {
      mostrarError(context, 'Esperando la ubicación GPS.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _dictado.currentState?.detener();
      final guardada = await widget.guardarEntrada(
        coordenadas: c,
        texto: _textoCtrl.text,
        fotos: List.of(_fotos),
        ubicacion: _destino,
        nombreNuevaUbicacion: _nombreCtrl.text,
      );
      _guardada = true;
      if (mounted) Navigator.pop<Entrada>(context, guardada);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva entrada')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tarjetaUbicacion(),
          const SizedBox(height: 16),
          _fotos.isEmpty
              ? const FotoLocal(ruta: null, alto: 200, ancho: double.infinity)
              : _tiraDeFotos(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _espacioFotos > 0
                      ? () => _agregarFotos(camara: true)
                      : null,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _espacioFotos > 0
                      ? () => _agregarFotos(camara: false)
                      : null,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
          if (_fotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_fotos.length} de ${Entrada.maxFotos} fotos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _textoCtrl,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: '¿Qué hiciste o qué quedó pendiente?',
              border: const OutlineInputBorder(),
              suffixIcon: BotonDictado(
                key: _dictado,
                speech: widget.speech,
                controlador: _textoCtrl,
                onEscuchandoCambio: (v) => setState(() => _escuchando = v),
              ),
            ),
          ),
          if (_escuchando)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _guardando || _buscandoUbicacion ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Miniaturas de las fotos elegidas, cada una con botón para quitarla.
  Widget _tiraDeFotos() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _fotos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Stack(
          children: [
            FotoLocal(ruta: _fotos[i], alto: 120, ancho: 120),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _quitarFoto(i),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaUbicacion() {
    final Widget contenido;

    if (_buscandoUbicacion) {
      contenido = const ListTile(
        leading: SizedBox(
            width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('Obteniendo ubicación…'),
      );
    } else if (_coordenadas == null) {
      contenido = ListTile(
        leading: const Icon(Icons.location_off),
        title: const Text('Sin ubicación'),
        subtitle: Text(_errorUbicacion ?? ''),
        trailing: TextButton(
            onPressed: _obtenerUbicacion, child: const Text('Reintentar')),
      );
    } else if (_destino != null) {
      contenido = ListTile(
        leading: const Icon(Icons.place, color: Colors.teal),
        title: Text(widget.ubicacionFija != null
            ? 'Agregando a: ${_destino!.nombre}'
            : 'Estás en: ${_destino!.nombre}'),
        subtitle: Text(formatearCoordenadas(
            _coordenadas!.latitud, _coordenadas!.longitud)),
      );
    } else {
      contenido = Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lugar nuevo',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(formatearCoordenadas(
                _coordenadas!.latitud, _coordenadas!.longitud)),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del lugar (ej. Casa Sra. López)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      );
    }
    return Card(child: contenido);
  }
}
