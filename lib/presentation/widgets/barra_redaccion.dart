import 'package:flutter/material.dart';

import '../../domain/entities/observacion.dart';
import '../../domain/services/device_services.dart';
import 'boton_dictado.dart';

/// Barra fija al pie de la conversación (spec 004, D-029):
/// [Nueva visita] [campo de texto] [micrófono] [enviar].
///
/// Todo lo que se envía desde aquí es una observación (RN-12). Si [onEnviar]
/// termina bien, el campo se vacía; si lanza, el texto se conserva para
/// reintentar (quien llama muestra el error).
class BarraRedaccion extends StatefulWidget {
  final SpeechService speech;
  final Future<void> Function(String texto) onEnviar;
  final VoidCallback? onNuevaVisita;

  /// Sin visitas no hay a qué asociar una observación.
  final bool habilitada;

  const BarraRedaccion({
    super.key,
    required this.speech,
    required this.onEnviar,
    this.onNuevaVisita,
    this.habilitada = true,
  });

  @override
  State<BarraRedaccion> createState() => _BarraRedaccionState();
}

class _BarraRedaccionState extends State<BarraRedaccion> {
  /// A partir de aquí se muestra el contador de caracteres.
  static const _avisoCaracteres = 1800;

  final _ctrl = TextEditingController();
  final _dictado = GlobalKey<BotonDictadoState>();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Habilita o deshabilita "enviar" según el texto.
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _puedeEnviar =>
      widget.habilitada && !_enviando && _ctrl.text.trim().isNotEmpty;

  Future<void> _enviar() async {
    if (!_puedeEnviar) return;
    setState(() => _enviando = true);
    try {
      await _dictado.currentState?.detener();
      await widget.onEnviar(_ctrl.text);
      _ctrl.clear();
    } catch (_) {
      // El texto se queda en el campo; el error ya se mostró.
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Material(
      color: colores.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.onNuevaVisita != null)
                IconButton(
                  tooltip: 'Nueva visita',
                  icon: const Icon(Icons.add_a_photo_outlined),
                  onPressed: widget.onNuevaVisita,
                ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: widget.habilitada,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: Observacion.maxCaracteres,
                  textCapitalization: TextCapitalization.sentences,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      currentLength < _avisoCaracteres
                          ? null
                          : Text('$currentLength/$maxLength'),
                  decoration: InputDecoration(
                    hintText: widget.habilitada
                        ? 'Escribe una observación…'
                        : 'Registra una visita para agregar observaciones',
                    filled: true,
                    fillColor: colores.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (widget.habilitada)
                BotonDictado(
                    key: _dictado, speech: widget.speech, controlador: _ctrl),
              IconButton(
                tooltip: 'Enviar observación',
                icon: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                color: colores.primary,
                onPressed: _puedeEnviar ? _enviar : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
