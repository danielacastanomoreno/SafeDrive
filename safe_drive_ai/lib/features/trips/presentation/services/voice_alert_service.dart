import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAlertService {
  VoiceAlertService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      _initialized = true;
    } catch (e) {
      debugPrint('[VOICE_ALERT] init failed: $e');
    }
  }

  Future<void> speak(String message) async {
    await _ensureInitialized();
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (e) {
      debugPrint('[VOICE_ALERT] speak failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
  }
}
