import 'dart:convert';
import 'dart:typed_data';

import 'package:vosk_flutter_service/vosk_flutter_service.dart';

class StreamingResult {
  const StreamingResult({required this.text, this.start, this.end});

  final String text;
  final Duration? start;
  final Duration? end;
}

abstract interface class StreamingRecognizer {
  Future<void> load(String modelDirectory);

  Future<void> startSession();

  Future<bool> accept(Uint8List pcm16);

  Future<String> partialText();

  Future<StreamingResult> result();

  Future<StreamingResult> finalResult();

  Future<void> endSession();

  Future<void> dispose();
}

class VoskStreamingRecognizer implements StreamingRecognizer {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;

  @override
  Future<void> load(String modelDirectory) async {
    _model ??= await _vosk.createModel(modelDirectory);
  }

  @override
  Future<void> startSession() async {
    final model = _model;
    if (model == null) throw StateError('Vosk model is not loaded');
    final recognizer = await _vosk.createRecognizer(
      model: model,
      sampleRate: 16000,
    );
    await recognizer.setWords(words: true);
    _recognizer = recognizer;
  }

  @override
  Future<bool> accept(Uint8List pcm16) =>
      _requireRecognizer().acceptWaveformBytes(pcm16);

  @override
  Future<String> partialText() async {
    final decoded = _decode(await _requireRecognizer().getPartialResult());
    return decoded['partial'] as String? ?? '';
  }

  @override
  Future<StreamingResult> result() async =>
      _parse(await _requireRecognizer().getResult());

  @override
  Future<StreamingResult> finalResult() async =>
      _parse(await _requireRecognizer().getFinalResult());

  @override
  Future<void> endSession() async {
    await _recognizer?.dispose();
    _recognizer = null;
  }

  @override
  Future<void> dispose() async {
    await endSession();
    _model?.dispose();
    _model = null;
  }

  Recognizer _requireRecognizer() {
    final recognizer = _recognizer;
    if (recognizer == null) throw StateError('Vosk session is not started');
    return recognizer;
  }

  static Map<String, dynamic> _decode(String json) {
    final decoded = jsonDecode(json);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  static StreamingResult _parse(String json) {
    final decoded = _decode(json);
    final words = (decoded['result'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return StreamingResult(
      text: decoded['text'] as String? ?? '',
      start: words.isEmpty ? null : _seconds(words.first['start']),
      end: words.isEmpty ? null : _seconds(words.last['end']),
    );
  }

  static Duration? _seconds(Object? value) => value is num
      ? Duration(microseconds: (value * Duration.microsecondsPerSecond).round())
      : null;
}
