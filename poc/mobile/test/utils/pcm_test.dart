import 'dart:typed_data';

import 'package:first_aid_voice_assistant/utils/pcm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts little-endian 16-bit samples to floats', () {
    final samples = Pcm16Decoder().convert(
      Uint8List.fromList([0x00, 0x40, 0x00, 0xC0, 0xFF, 0x7F]),
    );

    expect(samples, [0.5, -0.5, closeTo(1, 0.0001)]);
  });

  test('keeps a byte split between two chunks', () {
    final decoder = Pcm16Decoder();

    final first = decoder.convert(Uint8List.fromList([0x00, 0x40, 0x00]));
    final second = decoder.convert(Uint8List.fromList([0xC0]));

    expect(first, [0.5]);
    expect(second, [-0.5]);
  });
}
