import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/speech_engine.dart';

abstract interface class ModelStore {
  Future<bool> isDownloaded(SpeechEngine engine);

  Future<String> ensureDownloaded(
    SpeechEngine engine, {
    void Function(double progress)? onProgress,
  });
}

class ModelDownloadException implements Exception {
  const ModelDownloadException(this.message);

  final String message;

  @override
  String toString() => 'ModelDownloadException: $message';
}

class FileModelStore implements ModelStore {
  FileModelStore({
    Future<String> Function()? directory,
    List<ModelFile> Function(SpeechEngine engine)? describe,
    this.maxAttempts = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.connectTimeout = const Duration(seconds: 20),
    this.idleTimeout = const Duration(seconds: 30),
  }) : _directory = directory ?? _defaultDirectory,
       _describe = describe ?? ((engine) => engine.files);

  final Future<String> Function() _directory;
  final List<ModelFile> Function(SpeechEngine engine) _describe;
  final int maxAttempts;
  final Duration retryDelay;
  final Duration connectTimeout;
  final Duration idleTimeout;

  static Future<String> _defaultDirectory() async =>
      '${(await getApplicationSupportDirectory()).path}/models';

  @override
  Future<bool> isDownloaded(SpeechEngine engine) async {
    final root = await _directory();
    for (final file in _describe(engine)) {
      if (!await _isReady(root, file)) return false;
    }
    return true;
  }

  @override
  Future<String> ensureDownloaded(
    SpeechEngine engine, {
    void Function(double progress)? onProgress,
  }) async {
    final root = await _directory();
    final missing = <ModelFile>[];
    for (final file in _describe(engine)) {
      if (!await _isReady(root, file)) missing.add(file);
    }
    final total = missing.fold<int>(0, (sum, file) => sum + file.sizeBytes);
    var done = 0;
    for (final file in missing) {
      await _fetch(root, file, (received) {
        if (total > 0) {
          onProgress?.call(((done + received) / total).clamp(0, 1).toDouble());
        }
      });
      done += file.sizeBytes;
    }
    return root;
  }

  Future<bool> _isReady(String root, ModelFile file) async {
    if (file.unzip) return File(_markerPath(root, file)).exists();
    final target = File('$root/${file.path}');
    return await target.exists() && await target.length() == file.sizeBytes;
  }

  String _markerPath(String root, ModelFile file) =>
      '$root/${file.path}.extracted';

  Future<void> _fetch(
    String root,
    ModelFile file,
    void Function(int received) onReceived,
  ) async {
    final target = File('$root/${file.path}');
    await target.parent.create(recursive: true);
    if (await target.exists()) await target.delete();

    final partial = File('${target.path}.part');
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _download(file, partial, onReceived);
        await _verify(file, partial);
        await partial.rename(target.path);
        if (file.unzip) await _extract(root, file, target);
        return;
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(retryDelay * attempt);
        }
      }
    }
    throw ModelDownloadException(
      'Download of ${file.path} failed after $maxAttempts attempts: $lastError',
    );
  }

  Future<void> _download(
    ModelFile file,
    File partial,
    void Function(int received) onReceived,
  ) async {
    var existing = await partial.exists() ? await partial.length() : 0;
    if (existing > file.sizeBytes) {
      await partial.delete();
      existing = 0;
    }
    if (existing == file.sizeBytes) return;

    final client = HttpClient()..connectionTimeout = connectTimeout;
    try {
      final request = await client.getUrl(file.uri);
      if (existing > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existing-');
      }
      final response = await request.close().timeout(idleTimeout);

      final int offset;
      if (response.statusCode == HttpStatus.partialContent && existing > 0) {
        offset = existing;
      } else if (response.statusCode == HttpStatus.ok) {
        offset = 0;
      } else {
        await response.drain<void>();
        if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
          await partial.delete();
        }
        throw ModelDownloadException('HTTP ${response.statusCode}');
      }

      final sink = partial.openWrite(
        mode: offset > 0 ? FileMode.append : FileMode.write,
      );
      var received = offset;
      onReceived(received);
      try {
        await for (final chunk in response.timeout(idleTimeout)) {
          sink.add(chunk);
          received += chunk.length;
          onReceived(received);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _verify(ModelFile file, File partial) async {
    final size = await partial.length();
    if (size != file.sizeBytes) {
      throw ModelDownloadException(
        'Incomplete download: $size of ${file.sizeBytes} bytes',
      );
    }
    final digest = await sha256.bind(partial.openRead()).first;
    if (digest.toString() != file.sha256) {
      await partial.delete();
      throw const ModelDownloadException('Checksum mismatch');
    }
  }

  Future<void> _extract(String root, ModelFile file, File archive) async {
    final archivePath = archive.path;
    final outputPath = archive.parent.path;
    await Isolate.run(() => extractFileToDisk(archivePath, outputPath));
    await archive.delete();
    await File(_markerPath(root, file)).writeAsString('ok');
  }
}
