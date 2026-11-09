import 'package:speech_to_text/speech_to_text.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/device_services.dart';

/// Captura audio del micrófono y lo transcribe en español (México).
class SpeechToTextService implements SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _disponible = false;

  @override
  Future<bool> inicializar() async {
    try {
      _disponible = await _stt.initialize();
      return _disponible;
    } catch (e) {
      throw AppException('El micrófono no está disponible.', causa: e);
    }
  }

  @override
  Future<void> escuchar(
      void Function(String texto, bool esFinal) onResultado) async {
    if (!_disponible && !await inicializar()) {
      throw const AppException(
          'El reconocimiento de voz no está disponible o no hay permiso.');
    }
    try {
      await _stt.listen(
        localeId: 'es_MX',
        onResult: (r) => onResultado(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      throw AppException('No se pudo iniciar el dictado.', causa: e);
    }
  }

  @override
  Future<void> detener() => _stt.stop();

  @override
  bool get escuchando => _stt.isListening;
}
