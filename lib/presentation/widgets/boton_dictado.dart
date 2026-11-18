import 'package:flutter/material.dart';

import '../../domain/services/device_services.dart';
import 'estado_vista.dart';

/// Botón de micrófono que dicta texto al final de [controlador].
///
/// Lo usan el formulario de entrada y la barra de la conversación
/// (spec 004, D-029). Si el dictado falla o no hay permiso, muestra el
/// mensaje y el usuario puede seguir escribiendo (principio IV).
/// Para detenerlo desde fuera, usar un `GlobalKey<BotonDictadoState>`.
class BotonDictado extends StatefulWidget {
  final SpeechService speech;
  final TextEditingController controlador;

  /// Avisa cuando empieza o termina de escuchar.
  final ValueChanged<bool>? onEscuchandoCambio;

  const BotonDictado({
    super.key,
    required this.speech,
    required this.controlador,
    this.onEscuchandoCambio,
  });

  @override
  State<BotonDictado> createState() => BotonDictadoState();
}

class BotonDictadoState extends State<BotonDictado> {
  bool _escuchando = false;

  /// Texto que había antes de empezar a dictar; el dictado se agrega al final.
  String _textoAntesDeDictar = '';

  bool get escuchando => _escuchando;

  void _cambiar(bool valor) {
    if (!mounted || _escuchando == valor) return;
    setState(() => _escuchando = valor);
    widget.onEscuchandoCambio?.call(valor);
  }

  /// Detiene el dictado si está activo.
  Future<void> detener() async {
    if (!_escuchando) return;
    await widget.speech.detener();
    _cambiar(false);
  }

  Future<void> _alternar() async {
    if (_escuchando) {
      await detener();
      return;
    }
    final ctrl = widget.controlador;
    try {
      _textoAntesDeDictar = ctrl.text;
      _cambiar(true);
      await widget.speech.escuchar(
        (texto, esFinal) {
          if (!mounted) return;
          ctrl.text = '$_textoAntesDeDictar $texto'.trim();
          ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
          if (esFinal) _cambiar(false);
        },
        // El reconocedor puede parar solo (silencio o tiempo máximo).
        onTerminado: () => _cambiar(false),
        onError: (e) {
          if (!mounted) return;
          _cambiar(false);
          mostrarError(context, e);
        },
      );
    } catch (e) {
      if (!mounted) return;
      _cambiar(false);
      mostrarError(context, e);
    }
  }

  @override
  void dispose() {
    if (_escuchando) widget.speech.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _escuchando ? 'Detener dictado' : 'Dictar',
      icon: Icon(_escuchando ? Icons.stop_circle : Icons.mic,
          color: _escuchando ? Colors.red : null),
      onPressed: _alternar,
    );
  }
}
