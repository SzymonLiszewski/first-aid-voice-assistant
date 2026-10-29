import 'dart:convert';
import 'dart:typed_data';

import 'package:first_aid_voice_assistant/utils/wav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes a 16-bit mono WAV header and samples', () {
    final wav = encodeWav(Float32List.fromList([0, 1, -1, 2]), 22050);
    final data = ByteData.sublistView(wav);

    expect(wav.length, 44 + 8);
    expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(wav.sublist(8, 16)), 'WAVEfmt ');
    expect(data.getUint32(4, Endian.little), 36 + 8);
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint32(24, Endian.little), 22050);
    expect(data.getUint32(28, Endian.little), 44100);
    expect(data.getUint16(34, Endian.little), 16);
    expect(data.getUint32(40, Endian.little), 8);
    expect(
      [for (var i = 0; i < 4; i++) data.getInt16(44 + i * 2, Endian.little)],
      [0, 32767, -32767, 32767],
    );
  });
}
