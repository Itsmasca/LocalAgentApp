import 'package:flutter/material.dart';

import '../../core/utils/formato.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/services/device_services.dart';
import '../../domain/usecases/guardar_entrada.dart';
import '../../domain/usecases/resolver_ubicacion.dart';
import '../widgets/estado_vista.dart';
import '../widgets/foto_local.dart';

/// Formulario de creación: GPS automático, cámara/galería y dictado.
///
/// Si [ubicacionFija] viene de la pantalla de detalle, la entrada se
/// agrega a ese lugar. Si no, se aplica la regla de [ResolverUbicacion].
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

  Coordenadas? _coordenadas;
  Ubicacion? _ubicacionDetectada;
  String? _errorUbicacion;
  String? _imagenPath;

  bool _buscandoUbicacion = true;
  bool _escuchando = false;
  bool _guardando = false;

  /// Texto que había antes de empezar a dictar; el dictado se agrega al final.
  String _textoAntesDeDictar = '';

  Ubicacion? get _destino => widget.ubicacionFija ?? _ubicacionDetectada;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    if (_escuchando) widget.speech.detener();
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
  Future<void> _elegirImagen({required bool camara}) async {
    try {
      final ruta = camara
          ? await widget.media.tomarFoto()
          : await widget.media.elegirDeGaleria();
      if (ruta != null && mounted) setState(() => _imagenPath = ruta);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  // ---------- Micrófono ----------
  Future<void> _alternarDictado() async {
    if (_escuchando) {
      await widget.speech.detener();
      setState(() => _escuchando = false);
      return;
    }
    try {
      _textoAntesDeDictar = _textoCtrl.text;
      setState(() => _escuchando = true);
      await widget.speech.escuchar((texto, esFinal) {
        if (!mounted) return;
        _textoCtrl.text = '$_textoAntesDeDictar $texto'.trim();
        _textoCtrl.selection =
            TextSelection.collapsed(offset: _textoCtrl.text.length);
        if (esFinal) setState(() => _escuchando = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _escuchando = false);
      mostrarError(context, e);
    }
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
      if (_escuchando) await widget.speech.detener();
      await widget.guardarEntrada(
        coordenadas: c,
        texto: _textoCtrl.text,
        imagenPath: _imagenPath,
        ubicacion: _destino,
        nombreNuevaUbicacion: _nombreCtrl.text,
      );
      if (mounted) Navigator.pop(context, true);
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
          FotoLocal(ruta: _imagenPath, alto: 200, ancho: double.infinity),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _elegirImagen(camara: true),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _elegirImagen(camara: false),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textoCtrl,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: '¿Qué hiciste o qué quedó pendiente?',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _escuchando ? 'Detener dictado' : 'Dictar',
                icon: Icon(_escuchando ? Icons.stop_circle : Icons.mic,
                    color: _escuchando ? Colors.red : null),
                onPressed: _alternarDictado,
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
