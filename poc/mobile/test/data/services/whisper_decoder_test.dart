import 'dart:typed_data';

import 'package:first_aid_voice_assistant/data/services/whisper_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('audio context follows the segment length', () {
    expect(WhisperDecoder.audioContextFor(16000), 150);
    expect(WhisperDecoder.audioContextFor(16000 * 5), 300);
    expect(WhisperDecoder.audioContextFor(16000 * 60), 1500);
  });

  test('pads segments shorter than whisper.cpp accepts', () {
    expect(WhisperDecoder.padded(Float32List(4000)).length, 17600);
    expect(WhisperDecoder.padded(Float32List(32000)).length, 32000);
  });
}
