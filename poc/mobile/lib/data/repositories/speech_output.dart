import 'dart:async';

import '../../domain/models/voice_engine.dart';
import '../../utils/wav.dart';
import '../services/audio_output.dart';
import '../services/model_store.dart';
import '../services/speech_synthesizer.dart';
import '../services/text_to_speech.dart';

abstract interface class SpeechOutput {
  String get label;

  Future<void> prepare({void Function(double progress)? onProgress});

  void prefetch(String text);

  Future<void> speak(String text, {void Function()? onStart});

  Future<void> stop();

  Future<void> dispose();
}

class SpeechOutputException implements Exception {
  const SpeechOutputException(this.message);

  final String message;

  @override
  String toString() => 'SpeechOutputException: $message';
}

class MissingVoiceException extends SpeechOutputException {
  const MissingVoiceException(String language)
    : super('No system voice for $language');
}

class SystemSpeechOutput implements SpeechOutput {
  SystemSpeechOutput({required this._tts});

  final TextToSpeech _tts;

  @override
  String get label => VoiceEngine.system.title;

  @override
  Future<void> prepare({void Function(double progress)? onProgress}) async {
    if (!await _tts.setLanguage(VoiceEngine.language)) {
      throw const MissingVoiceException(VoiceEngine.language);
    }
  }

  @override
  void prefetch(String text) {}

  @override
  Future<void> speak(String text, {void Function()? onStart}) =>
      _tts.speak(text, onStart: onStart);

  @override
  Future<void> stop() => _tts.stop();

  @override
  Future<void> dispose() => _tts.dispose();
}

class SynthesizedSpeechOutput implements SpeechOutput {
  SynthesizedSpeechOutput({
    required this.engine,
    required this._store,
    required this._synthesizer,
    required this._audio,
  });

  final VoiceEngine engine;
  final ModelStore _store;
  final SpeechSynthesizer _synthesizer;
  final AudioOutput _audio;
  final Map<String, Future<SynthesizedSpeech>> _prefetched = {};
  int _stops = 0;

  @override
  String get label => engine.title;

  @override
  Future<void> prepare({void Function(double progress)? onProgress}) async {
    final root = await _store.ensureDownloaded(engine, onProgress: onProgress);
    final directory = '$root/${engine.modelDirectory}';
    await _synthesizer.load(
      model: '$directory/${engine.modelName}',
      tokens: '$directory/tokens.txt',
      espeakVoice: engine.espeakVoice,
    );
    await _synthesizer.synthesize('Gotowe.');
  }

  @override
  void prefetch(String text) {
    _prefetched.putIfAbsent(text, () {
      final speech = _synthesizer.synthesize(text);
      speech.ignore();
      return speech;
    });
  }

  @override
  Future<void> speak(String text, {void Function()? onStart}) async {
    final stops = _stops;
    final speech =
        await (_prefetched.remove(text) ?? _synthesizer.synthesize(text));
    if (stops != _stops) return;
    onStart?.call();
    await _audio.playWav(encodeWav(speech.samples, speech.sampleRate));
  }

  @override
  Future<void> stop() async {
    _stops++;
    _prefetched.clear();
    await _audio.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _audio.dispose();
    await _synthesizer.dispose();
  }
}
