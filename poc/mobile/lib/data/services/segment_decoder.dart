import 'dart:typed_data';

abstract interface class SegmentDecoder {
  Future<void> load(String modelsDirectory);

  Future<String> decode(Float32List samples);

  Future<void> dispose();
}
