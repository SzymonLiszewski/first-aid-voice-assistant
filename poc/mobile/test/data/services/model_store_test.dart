import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:first_aid_voice_assistant/data/services/model_store.dart';
import 'package:first_aid_voice_assistant/domain/models/speech_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Local HTTP server that serves one model file and honours Range requests.
class _ModelServer {
  _ModelServer(this.body);

  Uint8List body;
  late final HttpServer _server;
  final List<String?> rangeHeaders = [];

  /// The next response sends only this many bytes, as if the connection broke.
  int? cutAfter;

  Uri get uri =>
      Uri.parse('http://${_server.address.host}:${_server.port}/model.bin');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      final range = request.headers.value(HttpHeaders.rangeHeader);
      rangeHeaders.add(range);
      var start = 0;
      if (range != null) {
        start = int.parse(range.substring('bytes='.length, range.indexOf('-')));
        request.response.statusCode = HttpStatus.partialContent;
      }
      final cut = cutAfter;
      cutAfter = null;
      request.response.add(body.sublist(start, cut ?? body.length));
      await request.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late Directory dir;
  late _ModelServer server;
  final body = Uint8List.fromList(List<int>.generate(50000, (i) => i % 251));

  FileModelStore store({String? checksum, bool unzip = false}) =>
      FileModelStore(
        directory: () async => dir.path,
        describe: (_) => [
          ModelFile(
            path: unzip ? 'pack/model.zip' : 'pack/model.bin',
            url: server.uri.toString(),
            sha256: checksum ?? sha256.convert(server.body).toString(),
            sizeBytes: server.body.length,
            extract: unzip,
          ),
        ],
        retryDelay: Duration.zero,
        idleTimeout: const Duration(seconds: 5),
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('model_store_test');
    server = _ModelServer(body);
    await server.start();
  });

  tearDown(() async {
    await server.stop();
    await dir.delete(recursive: true);
  });

  test('downloads, verifies and reports progress', () async {
    final progress = <double>[];

    final root = await store().ensureDownloaded(
      SpeechEngine.whisperBase,
      onProgress: progress.add,
    );

    expect(await File('$root/pack/model.bin').readAsBytes(), body);
    expect(progress.last, 1.0);
    expect(await store().isDownloaded(SpeechEngine.whisperBase), isTrue);
  });

  test('resumes an interrupted download with a Range request', () async {
    server.cutAfter = 20000;

    final root = await store().ensureDownloaded(SpeechEngine.whisperBase);

    expect(await File('$root/pack/model.bin').readAsBytes(), body);
    expect(server.rangeHeaders, hasLength(2));
    expect(server.rangeHeaders.last, startsWith('bytes='));
  });

  test('rejects a file with a wrong checksum', () async {
    final wrong = store(checksum: '0' * 64);

    await expectLater(
      wrong.ensureDownloaded(SpeechEngine.whisperBase),
      throwsA(isA<ModelDownloadException>()),
    );
    expect(await wrong.isDownloaded(SpeechEngine.whisperBase), isFalse);
  });

  test('does not download a model that is already complete', () async {
    await store().ensureDownloaded(SpeechEngine.whisperBase);
    server.rangeHeaders.clear();

    await store().ensureDownloaded(SpeechEngine.whisperBase);

    expect(server.rangeHeaders, isEmpty);
  });

  test('unpacks an archive and remembers it was unpacked', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('vosk-model/conf/model.conf', 'ok'));
    server.body = ZipEncoder().encodeBytes(archive);

    final root = await store(unzip: true).ensureDownloaded(SpeechEngine.vosk);

    expect(
      await File('$root/pack/vosk-model/conf/model.conf').readAsString(),
      'ok',
    );
    expect(await File('$root/pack/model.zip').exists(), isFalse);
    expect(await store(unzip: true).isDownloaded(SpeechEngine.vosk), isTrue);
  });
}
