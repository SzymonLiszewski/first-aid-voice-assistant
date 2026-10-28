import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'segment_decoder.dart';

class ParakeetDecoder implements SegmentDecoder {
  ParakeetDecoder({this.modelDirectory = 'parakeet-v3', this.threads = 4});

  final String modelDirectory;
  final int threads;

  Isolate? _isolate;
  SendPort? _toWorker;
  ReceivePort? _fromWorker;
  Completer<void>? _loaded;
  final Map<int, Completer<String>> _pending = {};
  int _nextId = 0;

  @override
  Future<void> load(String modelsDirectory) async {
    if (_isolate != null) return;
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
          _pending.remove(msg[1] as int)?.complete(msg[2] as String);
        case 'error':
          final id = msg[1] as int;
          final error = ParakeetException(msg[2] as String);
          if (id < 0) {
            if (!loaded.isCompleted) loaded.completeError(error);
          } else {
            _pending.remove(id)?.completeError(error);
          }
      }
    });
    _isolate = await Isolate.spawn(_parakeetWorker, fromWorker.sendPort);
    final toWorker = await ready.future;
    _toWorker = toWorker;
    final dir = '$modelsDirectory/$modelDirectory';
    toWorker.send([
      'load',
      '$dir/encoder.int8.onnx',
      '$dir/decoder.int8.onnx',
      '$dir/joiner.int8.onnx',
      '$dir/tokens.txt',
      threads,
    ]);
    await loaded.future;
  }

  @override
  Future<String> decode(Float32List samples) {
    final toWorker = _toWorker;
    final loaded = _loaded;
    if (toWorker == null || loaded == null || !loaded.isCompleted) {
      return Future.error(const ParakeetException('Model is not loaded'));
    }
    final id = _nextId++;
    final completer = Completer<String>();
    _pending[id] = completer;
    toWorker.send([
      'decode',
      id,
      TransferableTypedData.fromList([samples]),
    ]);
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    _toWorker?.send(const ['dispose']);
    _fromWorker?.close();
    for (final pending in _pending.values) {
      pending.completeError(const ParakeetException('Decoder disposed'));
    }
    _pending.clear();
    _isolate = null;
    _toWorker = null;
    _fromWorker = null;
  }
}

class ParakeetException implements Exception {
  const ParakeetException(this.message);

  final String message;

  @override
  String toString() => 'ParakeetException: $message';
}

void _parakeetWorker(SendPort toMain) {
  final inbox = ReceivePort();
  toMain.send(['ready', inbox.sendPort]);
  sherpa.OfflineRecognizer? recognizer;

  inbox.listen((dynamic message) {
    final msg = message as List<dynamic>;
    switch (msg[0] as String) {
      case 'load':
        try {
          sherpa.initBindings();
          recognizer = sherpa.OfflineRecognizer(
            sherpa.OfflineRecognizerConfig(
              model: sherpa.OfflineModelConfig(
                transducer: sherpa.OfflineTransducerModelConfig(
                  encoder: msg[1] as String,
                  decoder: msg[2] as String,
                  joiner: msg[3] as String,
                ),
                tokens: msg[4] as String,
                numThreads: msg[5] as int,
                modelType: 'nemo_transducer',
                debug: false,
              ),
            ),
          );
          toMain.send(const ['loaded']);
        } catch (e) {
          toMain.send(['error', -1, '$e']);
        }
      case 'decode':
        final id = msg[1] as int;
        try {
          final samples = (msg[2] as TransferableTypedData)
              .materialize()
              .asFloat32List();
          final engine = recognizer!;
          final stream = engine.createStream();
          stream.acceptWaveform(samples: samples, sampleRate: 16000);
          engine.decode(stream);
          final text = engine.getResult(stream).text;
          stream.free();
          toMain.send(['result', id, text]);
        } catch (e) {
          toMain.send(['error', id, '$e']);
        }
      case 'dispose':
        recognizer?.free();
        inbox.close();
        Isolate.exit();
    }
  });
}
