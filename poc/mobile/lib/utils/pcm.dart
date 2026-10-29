import 'dart:typed_data';

class Pcm16Decoder {
  int? _carry;

  Float32List convert(Uint8List bytes) {
    final carry = _carry;
    final total = bytes.length + (carry == null ? 0 : 1);
    final evenLength = total - total % 2;
    final samples = Float32List(evenLength ~/ 2);
    int byteAt(int i) =>
        carry == null ? bytes[i] : (i == 0 ? carry : bytes[i - 1]);
    for (var s = 0; s < samples.length; s++) {
      final low = byteAt(2 * s);
      final high = byteAt(2 * s + 1);
      final value = (high << 8) | low;
      samples[s] = (value >= 0x8000 ? value - 0x10000 : value) / 32768.0;
    }
    _carry = total.isOdd ? byteAt(total - 1) : null;
    return samples;
  }
}
