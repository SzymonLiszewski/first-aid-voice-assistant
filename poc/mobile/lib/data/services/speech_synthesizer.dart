import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:piper_phonemize/piper_phonemize.dart' as phonemizer;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class SynthesizedSpeech {
  const SynthesizedSpeech({required this.samples, required this.sampleRate});

  final Float32List samples;

  final int sampleRate;
}

abstract interface class SpeechSynthesizer {
  Future<void> load({
    required String model,
    required String tokens,
    required String espeakVoice,
  });

  Future<SynthesizedSpeech> synthesize(String text);

  Future<void> dispose();
}

class PiperSynthesizer implements SpeechSynthesizer {
  PiperSynthesizer({this.threads = 2});

  final int threads;

  Isolate? _isolate;
  SendPort? _toWorker;
  ReceivePort? _fromWorker;
  Completer<void>? _loaded;
  final Map<int, Completer<SynthesizedSpeech>> _pending = {};
  int _nextId = 0;

  @override
  Future<void> load({
    required String model,
    required String tokens,
    required String espeakVoice,
  }) async {
    if (_isolate != null) return;
    final espeakData = await phonemizer.extractEspeakNgData();
    final fromWorker = ReceivePort();
    _fromWorker = fromWorker;
    final ready = Completer<SendPort>();
    final loaded = Completer<void>();
    _loaded = loaded;
    fromWorker.listen((dynamic message) {
      final msg = message as List<dynamic>;
      switch (msg[0] as String) {
        case 'ready':
          ready.complete(msg[1] as SendPort);
        case 'loaded':
          loaded.complete();
        case 'result':
          _pending
              .remove(msg[1] as int)
              ?.complete(
                SynthesizedSpeech(
                  samples: (msg[2] as TransferableTypedData)
                      .materialize()
                      .asFloat32List(),
                  sampleRate: msg[3] as int,
                ),
              );
        case 'error':
          final id = msg[1] as int;
          final error = SpeechSynthesisException(msg[2] as String);
          if (id < 0) {
            if (!loaded.isCompleted) loaded.completeError(error);
          } else {
            _pending.remove(id)?.completeError(error);
          }
      }
    });
    _isolate = await Isolate.spawn(_piperWorker, fromWorker.sendPort);
    final toWorker = await ready.future;
    _toWorker = toWorker;
    toWorker.send(['load', model, tokens, espeakData, espeakVoice, threads]);
    await loaded.future;
  }

  @override
  Future<SynthesizedSpeech> synthesize(String text) {
    final toWorker = _toWorker;
    final loaded = _loaded;
    if (toWorker == null || loaded == null || !loaded.isCompleted) {
      return Future.error(
        const SpeechSynthesisException('Voice is not loaded'),
      );
    }
    final id = _nextId++;
    final completer = Completer<SynthesizedSpeech>();
    _pending[id] = completer;
    toWorker.send(['synthesize', id, text]);
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    _toWorker?.send(const ['dispose']);
    _fromWorker?.close();
    for (final pending in _pending.values) {
      pending.completeError(
        const SpeechSynthesisException('Synthesizer disposed'),
      );
    }
    _pending.clear();
    _isolate = null;
    _toWorker = null;
    _fromWorker = null;
  }
}

class SpeechSynthesisException implements Exception {
  const SpeechSynthesisException(this.message);

  final String message;

  @override
  String toString() => 'SpeechSynthesisException: $message';
}

void _piperWorker(SendPort toMain) {
  final inbox = ReceivePort();
  toMain.send(['ready', inbox.sendPort]);
  sherpa.OfflineTts? tts;
  var voice = '';

  inbox.listen((dynamic message) {
    final msg = message as List<dynamic>;
    switch (msg[0] as String) {
      case 'load':
        try {
          sherpa.initBindings();
          phonemizer.initBindings();
          if (phonemizer.PiperPhonemize.initialize(msg[3] as String) < 0) {
            throw const SpeechSynthesisException('espeak-ng failed to start');
          }
          voice = msg[4] as String;
          tts = sherpa.OfflineTts(
            sherpa.OfflineTtsConfig(
              model: sherpa.OfflineTtsModelConfig(
                vits: sherpa.OfflineTtsVitsModelConfig(
                  model: msg[1] as String,
                  tokens: msg[2] as String,
                ),
                numThreads: msg[5] as int,
                debug: false,
              ),
            ),
          );
          toMain.send(const ['loaded']);
        } catch (e) {
          toMain.send(['error', -1, '$e']);
        }
      case 'synthesize':
        final id = msg[1] as int;
        try {
          final text = msg[2] as String;
          final phonemes = phonemizer.PiperPhonemize.phonemize(
            text,
            voice: voice,
          ).where((sentence) => sentence.isNotEmpty).toList();
          if (phonemes.isEmpty) {
            throw SpeechSynthesisException('No phonemes for "$text"');
          }
          final audio = tts!.generateWithConfig(
            text: '',
            config: sherpa.OfflineTtsGenerationConfig(
              phonemeCodepoints: phonemes,
            ),
          );
          if (audio.samples.isEmpty) {
            throw SpeechSynthesisException('No audio for "$text"');
          }
          toMain.send([
            'result',
            id,
            TransferableTypedData.fromList([audio.samples]),
            audio.sampleRate,
          ]);
        } catch (e) {
          toMain.send(['error', id, '$e']);
        }
      case 'dispose':
        tts?.free();
        inbox.close();
        Isolate.exit();
    }
  });
}
