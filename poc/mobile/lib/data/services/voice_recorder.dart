import 'dart:typed_data';

import 'package:record/record.dart';

abstract interface class VoiceRecorder {
  Future<bool> hasPermission();

  Future<Stream<Uint8List>> startStream();

  Future<void> stop();

  Future<void> dispose();
}

class MicrophoneVoiceRecorder implements VoiceRecorder {
  static const int sampleRate = 16000;

  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> startStream() => _recorder.startStream(
    const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
    ),
  );

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
