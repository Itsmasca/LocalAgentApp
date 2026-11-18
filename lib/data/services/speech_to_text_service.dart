import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/device_services.dart';

/// Dictado continuo, de preferencia en español de México.
///
/// El reconocedor de Android está pensado para frases cortas: cierra la
/// sesión en cuanto detecta una pausa breve, ignore el `pauseFor` que se le
/// pida. Para dictar notas largas este servicio encadena "tramos": cuando
/// un tramo termina vuelve a escuchar solo y acumula el texto, hasta que el
/// usuario llama a [detener] o pasa [_silencioMaximo] sin oír palabras.
class SpeechToTextService implements SpeechService {
  static const _idiomaPreferido = 'es_MX';

  /// Sin palabras nuevas durante este tiempo, el dictado se da por terminado.
  static const _silencioMaximo = Duration(seconds: 8);

  /// Duración máxima de una sesión completa de dictado.
  static const _duracionMaxima = Duration(minutes: 5);

  /// Espera antes de reabrir el micrófono entre tramos.
  static const _pausaEntreTramos = Duration(milliseconds: 150);

  final SpeechToText _stt = SpeechToText();
  bool _disponible = false;
  String? _localeId;

  // ----- Estado de la sesión de dictado -----
  bool _activa = false;

  /// Texto de los tramos que ya terminaron.
  String _confirmado = '';

  /// Texto (parcial) del tramo en curso.
  String _tramo = '';

  /// Cada tramo tiene un número; evita reanudar dos veces el mismo tramo
  /// cuando llegan 'done' y un error para él.
  int _tramoId = 0;
  bool _tramoCerrado = false;

  DateTime _inicio = DateTime.now();
  DateTime _ultimaVoz = DateTime.now();

  void Function(String texto, bool esFinal)? _onResultado;
  void Function()? _onTerminado;
  void Function(Object error)? _onError;

  @override
  Future<bool> inicializar() async {
    if (_disponible) return true;
    try {
      _disponible = await _stt.initialize(
        onStatus: _alCambiarEstado,
        onError: _alFallar,
      );
      if (_disponible) _localeId = await _elegirIdioma();
      return _disponible;
    } catch (e) {
      throw AppException('El micrófono no está disponible.', causa: e);
    }
  }

  @override
  Future<void> escuchar(
    void Function(String texto, bool esFinal) onResultado, {
    void Function()? onTerminado,
    void Function(Object error)? onError,
  }) async {
    if (!await inicializar()) {
      throw const AppException(
          'El reconocimiento de voz no está disponible o no hay permiso '
          'de micrófono.');
    }
    if (_activa) await _terminar(notificar: false);

    _onResultado = onResultado;
    _onTerminado = onTerminado;
    _onError = onError;
    _activa = true;
    _confirmado = '';
    _tramo = '';
    _inicio = DateTime.now();
    _ultimaVoz = _inicio;

    try {
      await _abrirTramo();
    } catch (e) {
      _activa = false;
      _limpiarCallbacks();
      throw AppException('No se pudo iniciar el dictado.', causa: e);
    }
  }

  @override
  Future<void> detener() => _terminar(notificar: true);

  @override
  bool get escuchando => _activa;

  // ---------------------------------------------------------------------
  // Tramos
  // ---------------------------------------------------------------------

  Future<void> _abrirTramo() async {
    _tramoId++;
    _tramoCerrado = false;
    _tramo = '';
    await _stt.listen(
      onResult: _alRecibirResultado,
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        partialResults: true,
        listenMode: ListenMode.dictation,
        // Los errores se manejan aquí (reanudar o terminar), no en el plugin.
        cancelOnError: false,
        listenFor: _duracionMaxima,
      ),
    );
  }

  void _alRecibirResultado(SpeechRecognitionResult r) {
    if (!_activa) return;
    final palabras = r.recognizedWords.trim();
    if (palabras.isNotEmpty) _ultimaVoz = DateTime.now();

    // Un resultado final (o "intermedio" en Android 13+) cierra un pedazo
    // del texto: se pasa a lo confirmado. Uno parcial solo se muestra.
    if (r.finalResult || r.resultTypeValue == ResultType.intermediate) {
      _confirmado = _unir(_confirmado, palabras);
      _tramo = '';
    } else {
      _tramo = palabras;
    }
    _onResultado?.call(_textoActual, false);
  }

  /// El tramo actual terminó (por pausa o por error de "no se oyó nada"):
  /// se reanuda si la sesión sigue viva, o se termina.
  void _alCerrarTramo() {
    if (!_activa || _tramoCerrado) return;
    _tramoCerrado = true;

    // Si el último parcial no llegó a confirmarse, se conserva.
    if (_tramo.isNotEmpty) {
      _confirmado = _unir(_confirmado, _tramo);
      _tramo = '';
    }

    final ahora = DateTime.now();
    final callado = ahora.difference(_ultimaVoz) >= _silencioMaximo;
    final agotado = ahora.difference(_inicio) >= _duracionMaxima;
    if (callado || agotado) {
      _terminar(notificar: true);
      return;
    }

    final id = _tramoId;
    Future.delayed(_pausaEntreTramos, () async {
      // Pudo haberse detenido o abierto otro tramo mientras se esperaba.
      if (!_activa || id != _tramoId) return;
      try {
        await _abrirTramo();
      } catch (e) {
        _fallar(AppException('Se interrumpió el dictado.', causa: e));
      }
    });
  }

  Future<void> _terminar({required bool notificar}) async {
    if (!_activa) return;
    _activa = false;
    _tramoId++; // invalida cualquier reanudación pendiente
    try {
      await _stt.stop();
    } catch (_) {
      // Si ya estaba detenido no importa.
    }
    if (_tramo.isNotEmpty) {
      _confirmado = _unir(_confirmado, _tramo);
      _tramo = '';
    }
    final onResultado = _onResultado;
    final onTerminado = _onTerminado;
    _limpiarCallbacks();
    if (notificar) {
      onResultado?.call(_confirmado, true);
      onTerminado?.call();
    }
  }

  void _fallar(AppException error) {
    final onError = _onError;
    _terminar(notificar: true);
    onError?.call(error);
  }

  // ---------------------------------------------------------------------
  // Eventos del plugin
  // ---------------------------------------------------------------------

  void _alCambiarEstado(String estado) {
    if (estado == SpeechToText.doneStatus) _alCerrarTramo();
  }

  void _alFallar(SpeechRecognitionError error) {
    if (!_activa) return;
    switch (error.errorMsg) {
      // "No se oyó nada" en este tramo: es normal entre frases.
      case 'error_no_match':
      case 'error_speech_timeout':
      // El reconocedor aún no liberaba el tramo anterior.
      case 'error_busy':
      case 'error_client':
        _alCerrarTramo();
      case 'error_permission':
        _fallar(const AppException('No hay permiso para usar el micrófono.'));
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
      case 'error_server_disconnected':
        _fallar(const AppException(
            'El dictado necesita internet o el paquete de voz sin conexión.'));
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        _fallar(const AppException(
            'El idioma español no está disponible para dictado.'));
      default:
        _fallar(AppException('Falló el dictado (${error.errorMsg}).',
            causa: error));
    }
  }

  // ---------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------

  String get _textoActual => _unir(_confirmado, _tramo);

  static String _unir(String a, String b) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a $b';
  }

  void _limpiarCallbacks() {
    _onResultado = null;
    _onTerminado = null;
    _onError = null;
  }

  /// es_MX si está instalado; si no, cualquier variante de español;
  /// si tampoco, el idioma del sistema (null).
  Future<String?> _elegirIdioma() async {
    try {
      final idiomas = await _stt.locales();
      final ids = idiomas.map((l) => l.localeId.replaceAll('-', '_')).toList();
      if (ids.contains(_idiomaPreferido)) return _idiomaPreferido;
      final espanol = ids.where((id) => id.startsWith('es')).toList();
      if (espanol.isNotEmpty) return espanol.first;
    } catch (_) {
      // Si no se pueden listar, se usa el idioma del sistema.
    }
    return null;
  }
}
