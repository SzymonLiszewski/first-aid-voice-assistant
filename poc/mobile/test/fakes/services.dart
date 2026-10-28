import 'dart:async';
import 'dart:typed_data';

import 'package:first_aid_voice_assistant/data/repositories/speech_input.dart';
import 'package:first_aid_voice_assistant/data/services/key_value_store.dart';
import 'package:first_aid_voice_assistant/data/services/model_store.dart';
import 'package:first_aid_voice_assistant/data/services/segment_decoder.dart';
import 'package:first_aid_voice_assistant/data/services/speech_segmenter.dart';
import 'package:first_aid_voice_assistant/data/services/streaming_recognizer.dart';
import 'package:first_aid_voice_assistant/data/services/voice_recorder.dart';
import 'package:first_aid_voice_assistant/domain/models/speech_engine.dart';
import 'package:first_aid_voice_assistant/domain/models/utterance.dart';

/// Speech input that "recognises" a fixed text when recording ends, for view model and UI tests.
class FakeSpeechInput implements SpeechInput {
  FakeSpeechInput({
    this.text = 'Kolega nie oddycha',
    this.engine = SpeechEngine.parakeet,
  });

  String text;
  final SpeechEngine engine;
  bool permission = true;
  Object? prepareError;
  Object? startError;
  Object? finishError;
  List<double> downloadSteps = [];
  bool listening = false;
  int cancelled = 0;
  final StreamController<String> _partials =
      StreamController<String>.broadcast();
  final StreamController<Utterance> _utterances =
      StreamController<Utterance>.broadcast();

  void emitPartial(String text) => _partials.add(text);

  void emitUtterance(String text) => _utterances.add(
    Utterance(
      text: text,
      endedAt: DateTime(2026, 10, 27, 14, 21, 2),
      speechDuration: const Duration(seconds: 2),
      transcriptionDuration: const Duration(milliseconds: 300),
    ),
  );

  @override
  String get label => engine.title;

  @override
  Stream<String> get partialText => _partials.stream;

  @override
  Stream<Utterance> get utterances => _utterances.stream;

  @override
  Future<void> prepare({void Function(double progress)? onProgress}) async {
    downloadSteps.forEach(onProgress ?? (_) {});
    if (prepareError != null) throw prepareError!;
  }

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start() async {
    if (startError != null) throw startError!;
    listening = true;
  }

  @override
  Future<void> finish() async {
    listening = false;
    if (finishError != null) throw finishError!;
    if (text.isNotEmpty) emitUtterance(text);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> cancel() async {
    listening = false;
    cancelled++;
  }

  @override
  Future<void> dispose() async {
    await _partials.close();
    await _utterances.close();
  }
}

class FakeVoiceRecorder implements VoiceRecorder {
  bool permission = true;
  StreamController<Uint8List> audio = StreamController<Uint8List>();
  bool streaming = false;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<Stream<Uint8List>> startStream() async {
    if (audio.isClosed) audio = StreamController<Uint8List>();
    streaming = true;
    return audio.stream;
  }

  @override
  Future<void> stop() async {
    if (!streaming) return;
    streaming = false;
    await audio.close();
  }

  @override
  Future<void> dispose() async {}
}

/// Decoder that answers with the number of samples it was given.
class FakeSegmentDecoder implements SegmentDecoder {
  final List<int> decodedLengths = [];
  String? loadedFrom;

  /// When set, every decode waits for it; lets tests hold a decode in flight.
  Completer<void>? gate;

  @override
  Future<void> load(String modelsDirectory) async =>
      loadedFrom = modelsDirectory;

  @override
  Future<String> decode(Float32List samples) async {
    decodedLengths.add(samples.length);
    await gate?.future;
    return 'n${samples.length}';
  }

  @override
  Future<void> dispose() async {}
}

/// Segmenter that treats audio between the given marks as speech.
class FakeSpeechSegmenter implements SpeechSegmenter {
  FakeSpeechSegmenter({this.speech = const []});

  /// Speech regions, reported once the audio has passed their end.
  final List<SpeechRegion> speech;
  String? loadedFrom;
  int _total = 0;
  int _reported = 0;

  @override
  Future<void> load(String modelPath) async => loadedFrom = modelPath;

  @override
  int? get activeStart {
    for (final region in speech.skip(_reported)) {
      if (region.start <= _total && _total < region.end) return region.start;
    }
    return null;
  }

  @override
  List<SpeechRegion> accept(Float32List samples) {
    _total += samples.length;
    final done = speech
        .skip(_reported)
        .takeWhile((region) => region.end <= _total)
        .toList();
    _reported += done.length;
    return done;
  }

  @override
  List<SpeechRegion> flush() {
    final rest = speech
        .skip(_reported)
        .where((region) => region.start < _total)
        .map((region) => SpeechRegion(region.start, _total))
        .toList();
    _reported = speech.length;
    return rest;
  }

  @override
  void reset() {
    _total = 0;
    _reported = 0;
  }

  @override
  void dispose() {}
}

/// Recognizer that treats every chunk as one word and ends a result on [finalChunk].
class FakeStreamingRecognizer implements StreamingRecognizer {
  FakeStreamingRecognizer({this.finalChunk});

  final int? finalChunk;
  String? loadedFrom;
  int sessions = 0;
  bool sessionOpen = false;
  final List<String> _words = [];
  int _chunks = 0;
  int _resultStart = 0;

  @override
  Future<void> load(String modelDirectory) async => loadedFrom = modelDirectory;

  @override
  Future<void> startSession() async {
    sessions++;
    sessionOpen = true;
    _words.clear();
    _chunks = 0;
    _resultStart = 0;
  }

  @override
  Future<bool> accept(Uint8List pcm16) async {
    _chunks++;
    _words.add('w$_chunks');
    return _chunks == finalChunk;
  }

  @override
  Future<String> partialText() async => _words.join(' ');

  @override
  Future<StreamingResult> result() async => _take();

  @override
  Future<StreamingResult> finalResult() async => _take();

  @override
  Future<void> endSession() async => sessionOpen = false;

  @override
  Future<void> dispose() async {}

  StreamingResult _take() {
    final result = StreamingResult(
      text: _words.join(' '),
      start: Duration(milliseconds: _resultStart * 100),
      end: Duration(milliseconds: _chunks * 100),
    );
    _words.clear();
    _resultStart = _chunks;
    return result;
  }
}

class FakeModelStore implements ModelStore {
  FakeModelStore(this.downloaded);

  final Set<SpeechEngine> downloaded;

  @override
  Future<bool> isDownloaded(SpeechEngine engine) async =>
      downloaded.contains(engine);

  @override
  Future<String> ensureDownloaded(
    SpeechEngine engine, {
    void Function(double progress)? onProgress,
  }) async {
    downloaded.add(engine);
    return 'models';
  }
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
