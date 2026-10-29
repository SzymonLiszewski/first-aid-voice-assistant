import 'dart:math';
import 'dart:typed_data';

import 'package:whisper_cpp_flutter_plus/whisper_cpp_flutter_plus.dart'
    as whisper;

import 'segment_decoder.dart';

class WhisperDecoder implements SegmentDecoder {
  WhisperDecoder({
    required this.modelPath,
    this.language = 'pl',
    this.threads = 4,
  });

  static const int _framesPerSecond = 50;
  static const int _contextMargin = 50;
  static const int _minContext = 150;
  static const int _maxContext = 1500;
  static const int _minSamples = 17600;

  final String modelPath;
  final String language;
  final int threads;
  whisper.WhisperEngine? _engine;

  static int audioContextFor(int samples) {
    final seconds = samples / 16000;
    final frames = (seconds * _framesPerSecond).ceil() + _contextMargin;
    return min(_maxContext, max(_minContext, frames));
  }

  @override
  Future<void> load(String modelsDirectory) async {
    _engine ??= await whisper.WhisperEngine.load('$modelsDirectory/$modelPath');
  }

  static Float32List padded(Float32List samples) {
    if (samples.length >= _minSamples) return samples;
    return Float32List(_minSamples)..setAll(0, samples);
  }

  @override
  Future<String> decode(Float32List samples) async {
    final engine = _engine;
    if (engine == null) throw StateError('Whisper model is not loaded');
    final input = padded(samples);
    final result = await engine
        .transcribe(
          input,
          options: whisper.TranscribeOptions(
            language: language,
            threads: threads,
            audioContext: audioContextFor(input.length),
            greedyBestOf: 1,
            beamSize: 1,
            temperatureIncrement: 0,
            noContext: true,
            singleSegment: true,
            noTimestamps: true,
            tokenTimestamps: false,
            suppressNonSpeechTokens: true,
          ),
        )
        .result;
    return result.text;
  }

  @override
  Future<void> dispose() async {
    _engine?.dispose();
    _engine = null;
  }
}
