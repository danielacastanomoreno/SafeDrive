import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceResponseService {
  VoiceResponseService({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  bool _listening = false;

  Future<bool> listenForResponse({
    required Duration duration,
    double soundLevelThreshold = 0.4,
  }) async {
    final ready = await _ensureInitialized();
    if (!ready) return false;

    if (_listening) {
      await stop();
    }

    final completer = Completer<bool>();
    double maxSoundLevel = 0;

    void completeIfNeeded(bool heard) {
      if (completer.isCompleted) return;
      completer.complete(heard);
      unawaited(stop());
    }

    void handleResult(SpeechRecognitionResult result) {
      final words = result.recognizedWords.trim();
      if (words.isNotEmpty) {
        completeIfNeeded(true);
      }
    }

    void handleSound(double level) {
      if (level > maxSoundLevel) maxSoundLevel = level;
      if (level >= soundLevelThreshold) {
        completeIfNeeded(true);
      }
    }

    try {
      _listening = true;
      final locale = await _speech.systemLocale();
      await _speech.listen(
        onResult: handleResult,
        listenFor: duration,
        pauseFor: duration,
        onSoundLevelChange: handleSound,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        localeId: locale?.localeId ?? 'es_ES',
        partialResults: true,
      );

      Timer(duration, () => completeIfNeeded(false));
      final heard = await completer.future;
      return heard || maxSoundLevel >= soundLevelThreshold;
    } catch (e) {
      debugPrint('[VOICE_RESPONSE] listen failed: $e');
      return false;
    } finally {
      await stop();
    }
  }

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (error) =>
            debugPrint('[VOICE_RESPONSE] error: ${error.errorMsg}'),
        onStatus: (status) =>
            debugPrint('[VOICE_RESPONSE] status: $status'),
      );
      return _initialized;
    } catch (e) {
      debugPrint('[VOICE_RESPONSE] init failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (!_listening) return;
    _listening = false;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
  }
}
