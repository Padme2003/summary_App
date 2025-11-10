import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  String? _currentText;

  // Configurar TTS
  Future<void> initialize({
    String language = 'es-ES',
    double speechRate = 0.5,
    double volume = 1.0,
    double pitch = 1.0,
  }) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.setSpeechRate(speechRate);
    await _flutterTts.setVolume(volume);
    await _flutterTts.setPitch(pitch);

    // Configurar callbacks
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
    });
  }

  // Hablar texto
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    _currentText = text;
    await _flutterTts.speak(text);
  }

  // Pausar
  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
  }

  // Reanudar
  Future<void> resume() async {
    if (_currentText != null) {
      await _flutterTts.speak(_currentText!);
    }
  }

  // Detener
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
    _currentText = null;
  }

  // Obtener voces disponibles
  Future<List<dynamic>> getVoices() async {
    return await _flutterTts.getVoices;
  }

  // Configurar voz
  Future<void> setVoice(Map<String, String> voice) async {
    await _flutterTts.setVoice(voice);
  }

  // Estado
  bool get isPlaying => _isPlaying;

  // Liberar recursos
  void dispose() {
    _flutterTts.stop();
  }
}
