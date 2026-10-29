import 'dart:async';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

abstract interface class TextToSpeech {
  Future<bool> setLanguage(String language);

  Future<void> speak(String text, {void Function()? onStart});

  Future<void> stop();

  Future<void> dispose();
}

class TextToSpeechException implements Exception {
  const TextToSpeechException(this.message);

  final String message;

  @override
  String toString() => 'TextToSpeechException: $message';
}

class FlutterTextToSpeech implements TextToSpeech {
  final FlutterTts _tts = FlutterTts();
  Completer<void>? _speaking;
  void Function()? _onStart;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    _tts
      ..setStartHandler(() {
        final onStart = _onStart;
        _onStart = null;
        onStart?.call();
      })
      ..setCompletionHandler(_complete)
      ..setCancelHandler(_complete)
      ..setErrorHandler(
        (message) => _complete(error: TextToSpeechException('$message')),
      );
    await _tts.awaitSpeakCompletion(false);
    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
      );
    }
  }

  @override
  Future<bool> setLanguage(String language) async {
    await _configure();
    if (await _tts.isLanguageAvailable(language) != true) return false;
    await _tts.setLanguage(language);
    return true;
  }

  @override
  Future<void> speak(String text, {void Function()? onStart}) async {
    await _configure();
    _complete();
    final done = Completer<void>();
    _speaking = done;
    _onStart = onStart;
    final result = await _tts.speak(text);
    if (result != 1) {
      _complete(error: TextToSpeechException('speak returned $result'));
    }
    return done.future;
  }

  void _complete({Object? error}) {
    final speaking = _speaking;
    _speaking = null;
    _onStart = null;
    if (speaking == null || speaking.isCompleted) return;
    if (error == null) {
      speaking.complete();
    } else {
      speaking.completeError(error);
    }
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _complete();
  }

  @override
  Future<void> dispose() => stop();
}
