import 'package:flutter/material.dart';

import '../../core/utils/formato.dart';
import '../../domain/entities/paquete_evidencia.dart';
import '../../domain/entities/responsable.dart';
import '../../domain/repositories/ajustes_repository.dart';
import '../../domain/services/compartir_service.dart';
import '../../domain/usecases/compartir_evidencia.dart';
import '../../domain/usecases/resumir_evidencia.dart';
import '../widgets/dialogo_responsable.dart';
import '../widgets/estado_vista.dart';

/// Pantalla "Compartir" (contracts/flujo-ui.md §2): qué entradas incluir,
/// coordenadas, datos del cliente y del responsable, resumen y envío.
class CompartirScreen extends StatefulWidget {
  /// Paquete inicial armado por `PrepararEvidencia` (todas las entradas
  /// marcadas, o una sola si se compartió desde una entrada).
  final PaqueteEvidencia paquete;
  final ResumirEvidencia resumirEvidencia;
  final CompartirEvidencia compartirEvidencia;
  final AjustesRepository ajustes;
  final CompartirService compartir;

  const CompartirScreen({
    super.key,
    required this.paquete,
    required this.resumirEvidencia,
    required this.compartirEvidencia,
    required this.ajustes,
    required this.compartir,
  });

  @override
  State<CompartirScreen> createState() => _CompartirScreenState();
}

class _CompartirScreenState extends State<CompartirScreen> {
  late final List<bool> _marcadas =
      List.filled(widget.paquete.entradas.length, true);
  late bool _coordenadas = widget.paquete.incluirCoordenadas;
  late Responsable? _responsable = widget.paquete.responsable;
  final _clienteNombre = TextEditingController();
  final _clienteDireccion = TextEditingController();

  Future<ResumenEvidencia>? _resumen;
  bool _generando = false;
  double _progreso = 0;

  bool get _esReporte =>
      widget.paquete.formato == FormatoCompartir.reporteFormal;

  /// Con una sola entrada (compartir desde una tarjeta) no hay lista.
  bool get _variasEntradas => widget.paquete.entradas.length > 1;

  int get _cuantasMarcadas => _marcadas.where((m) => m).length;

  PaqueteEvidencia get _paqueteActual => widget.paquete.copyWith(
        entradas: [
          for (var i = 0; i < _marcadas.length; i++)
            if (_marcadas[i]) widget.paquete.entradas[i],
        ],
        incluirCoordenadas: _coordenadas,
        responsable: _esReporte ? _responsable : null,
        sinResponsable: !_esReporte || _responsable == null,
        destinatario: _esReporte
            ? Destinatario(
                nombre: _clienteNombre.text,
                direccion: _clienteDireccion.text)
            : null,
        sinDestinatario: !_esReporte,
        generadoEn: DateTime.now(),
      );

  @override
  void initState() {
    super.initState();
    _recalcularResumen();
    // Historia 4, escenario 1: la primera vez se ofrecen los datos del
    // responsable, una sola vez por pantalla.
    if (_esReporte && _responsable == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _editarResponsable());
    }
  }

  @override
  void dispose() {
    _clienteNombre.dispose();
    _clienteDireccion.dispose();
    super.dispose();
  }

  void _recalcularResumen() {
    final nuevo =
        _cuantasMarcadas == 0 ? null : widget.resumirEvidencia(_paqueteActual);
    setState(() {
      _resumen = nuevo;
    });
  }

  Future<void> _editarResponsable() async {
    if (!mounted) return;
    final r = await mostrarDialogoResponsable(context,
        ajustes: widget.ajustes, actual: _responsable);
    // "Omitir" devuelve null: se conservan los datos que ya hubiera.
    if (r != null && mounted) setState(() => _responsable = r);
  }

  Future<void> _enviar() async {
    setState(() {
      _generando = true;
      _progreso = 0;
    });
    try {
      final envio = await widget.compartirEvidencia(
        _paqueteActual,
        onProgreso: (v) {
          if (mounted) setState(() => _progreso = v);
        },
      );
      if (!mounted) return;
      switch (envio.resultado) {
        case ResultadoCompartir.enviado:
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Evidencia compartida')));
          Navigator.pop(context, true);
        case ResultadoCompartir.cancelado:
          break; // sin mensaje; se conserva la selección
        case ResultadoCompartir.noDisponible:
          _ofrecerGuardar(envio.archivo);
      }
    } catch (e) {
      if (mounted) mostrarError(context, e); // FR-013: se conserva todo
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  void _ofrecerGuardar(String? archivo) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content: const Text('No hay apps para recibir el archivo.'),
      action: archivo == null
          ? null
          : SnackBarAction(
              label: 'Guardar en el teléfono',
              onPressed: () async {
                try {
                  final ruta = await widget.compartir.guardarEnDispositivo(archivo);
                  if (mounted) mostrarError(context, 'Guardado en $ruta');
                } catch (e) {
                  if (mounted) mostrarError(context, e);
                }
              },
            ),
    ));
  }

  Future<bool> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar el envío?'),
        content: const Text('El reporte se está preparando.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir esperando')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salir')),
        ],
      ),
    );
    return salir ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_generando,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmarSalida() && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_esReporte
              ? 'Compartir · Reporte formal'
              : 'Compartir · Mensaje'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            Text(widget.paquete.ubicacion.nombre, style: estilos.titleMedium),
            const SizedBox(height: 8),
            if (_variasEntradas) ..._listaEntradas(estilos),
            Semantics(
              toggled: _coordenadas,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Incluir coordenadas y enlace al mapa'),
                subtitle: const Text('Las coordenadas muestran dónde está el lugar'),
                value: _coordenadas,
                onChanged: _generando
                    ? null
                    : (v) {
                        _coordenadas = v;
                        _recalcularResumen();
                      },
              ),
            ),
            if (_esReporte) ..._seccionReporte(estilos),
            const Divider(height: 32),
            _resumenWidget(estilos),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: _generando
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_esReporte
                        ? 'Preparando reporte… ${(_progreso * 100).round()} %'
                        : 'Preparando mensaje…'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _esReporte ? _progreso : null),
                  ],
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  onPressed: _cuantasMarcadas == 0 ? null : _enviar,
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar'),
                ),
        ),
      ),
    );
  }

  List<Widget> _listaEntradas(TextTheme estilos) {
    final todas = _cuantasMarcadas == _marcadas.length;
    return [
      Row(
        children: [
          Expanded(child: Text('Entradas', style: estilos.titleSmall)),
          TextButton.icon(
            onPressed: _generando
                ? null
                : () {
                    final valor = !todas;
                    for (var i = 0; i < _marcadas.length; i++) {
                      _marcadas[i] = valor;
                    }
                    _recalcularResumen();
                  },
            icon: Icon(todas ? Icons.check_box : Icons.check_box_outline_blank),
            label: const Text('Todas'),
          ),
        ],
      ),
      for (var i = 0; i < _marcadas.length; i++)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _marcadas[i],
          onChanged: _generando
              ? null
              : (v) {
                  _marcadas[i] = v ?? false;
                  _recalcularResumen();
                },
          title: Text(formatearFecha(widget.paquete.entradas[i].creadaEn)),
          subtitle: Text(
            widget.paquete.entradas[i].texto.isEmpty
                ? '(sin texto)'
                : widget.paquete.entradas[i].texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          secondary: widget.paquete.entradas[i].fotos.isEmpty
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.photo_camera_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text('${widget.paquete.entradas[i].fotos.length}'),
                ]),
        ),
      const Divider(height: 24),
    ];
  }

  List<Widget> _seccionReporte(TextTheme estilos) => [
        const SizedBox(height: 8),
        Text('Cliente (opcional)', style: estilos.titleSmall),
        TextField(
          controller: _clienteNombre,
          enabled: !_generando,
          maxLength: Destinatario.maxNombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        TextField(
          controller: _clienteDireccion,
          enabled: !_generando,
          maxLength: Destinatario.maxDireccion,
          maxLines: 2,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Dirección'),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 48,
          leading: const Icon(Icons.badge_outlined),
          title: Text(_responsable == null
              ? 'Sin datos del responsable'
              : 'Responsable: ${[
                  _responsable!.nombre,
                  _responsable!.negocio,
                ].whereType<String>().join(' · ')}'),
          trailing: TextButton(
            onPressed: _generando ? null : _editarResponsable,
            child: Text(_responsable == null ? 'Agregar mis datos' : 'Editar'),
          ),
        ),
      ];

  Widget _resumenWidget(TextTheme estilos) {
    if (_resumen == null) {
      return const Text('Marca al menos una entrada para compartir.');
    }
    return FutureBuilder<ResumenEvidencia>(
      future: _resumen,
      builder: (context, s) {
        if (!s.hasData) {
          return const LinearProgressIndicator();
        }
        final r = s.data!;
        final faltan = r.fotosFaltantes.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: estilos.titleSmall),
            const SizedBox(height: 4),
            Text('${r.entradas} ${r.entradas == 1 ? 'entrada' : 'entradas'} · '
                '${r.fotos} ${r.fotos == 1 ? 'foto' : 'fotos'} · '
                '${r.incluyeCoordenadas ? 'con' : 'sin'} coordenadas'),
            if (faltan > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Icon(Icons.warning_amber,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(faltan == 1
                        ? '1 foto ya no está en el teléfono y se omitirá.'
                        : '$faltan fotos ya no están en el teléfono y se omitirán.'),
                  ),
                ]),
              ),
          ],
        );
      },
    );
  }
}
