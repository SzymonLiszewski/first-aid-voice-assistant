import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

abstract interface class AudioOutput {
  Future<void> playWav(Uint8List wav);

  Future<void> stop();

  Future<void> dispose();
}

class AudioPlayersOutput implements AudioOutput {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completions;
  Completer<void>? _playing;

  Future<void> _configure() async {
    if (_completions != null) return;
    _completions = _player.onPlayerComplete.listen((_) => _finish());
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setAudioContext(
      AudioContextConfig(
        route: AudioContextConfigRoute.speaker,
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build(),
    );
  }

  @override
  Future<void> playWav(Uint8List wav) async {
    await _configure();
    _finish();
    final done = Completer<void>();
    _playing = done;
    try {
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (e) {
      _finish(error: e);
    }
    return done.future;
  }

  void _finish({Object? error}) {
    final playing = _playing;
    _playing = null;
    if (playing == null || playing.isCompleted) return;
    if (error == null) {
      playing.complete();
    } else {
      playing.completeError(error);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _finish();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _completions?.cancel();
    await _player.dispose();
  }
}
