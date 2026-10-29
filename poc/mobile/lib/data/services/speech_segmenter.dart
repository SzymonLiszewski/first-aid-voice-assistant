import 'dart:math';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class SpeechRegion {
  const SpeechRegion(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;
}

abstract interface class SpeechSegmenter {
  Future<void> load(String modelPath);

  int? get activeStart;

  List<SpeechRegion> accept(Float32List samples);

  List<SpeechRegion> flush();

  void reset();

  void dispose();
}

class SileroSpeechSegmenter implements SpeechSegmenter {
  static const int _windowSize = 512;
  static const double _minSpeechSeconds = 0.25;
  static const int _lookback = 8000;

  sherpa.VoiceActivityDetector? _vad;
  final Float32List _window = Float32List(_windowSize);
  int _windowFill = 0;
  int _total = 0;
  int _lastEnd = 0;
  int? _activeStart;

  @override
  int? get activeStart => _activeStart;

  @override
  Future<void> load(String modelPath) async {
    if (_vad != null) return;
    sherpa.initBindings();
    _vad = sherpa.VoiceActivityDetector(
      config: sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: modelPath,
          threshold: 0.5,
          minSilenceDuration: 0.5,
          minSpeechDuration: _minSpeechSeconds,
          windowSize: _windowSize,
          maxSpeechDuration: 10,
        ),
        sampleRate: 16000,
        numThreads: 1,
        debug: false,
      ),
      bufferSizeInSeconds: 60,
    );
  }

  @override
  List<SpeechRegion> accept(Float32List samples) {
    final vad = _requireVad();
    final regions = <SpeechRegion>[];
    var offset = 0;
    while (offset < samples.length) {
      final count = min(_windowSize - _windowFill, samples.length - offset);
      _window.setRange(_windowFill, _windowFill + count, samples, offset);
      _windowFill += count;
      offset += count;
      _total += count;
      if (_windowFill == _windowSize) {
        vad.acceptWaveform(Float32List.fromList(_window));
        _windowFill = 0;
        regions.addAll(_drain(vad));
        _trackActive(vad);
      }
    }
    return regions;
  }

  @override
  List<SpeechRegion> flush() {
    final vad = _requireVad();
    vad.flush();
    _activeStart = null;
    return _drain(vad);
  }

  @override
  void reset() {
    _vad?.reset();
    _windowFill = 0;
    _total = 0;
    _lastEnd = 0;
    _activeStart = null;
  }

  @override
  void dispose() {
    _vad?.free();
    _vad = null;
  }

  sherpa.VoiceActivityDetector _requireVad() {
    final vad = _vad;
    if (vad == null) throw StateError('Voice activity detector is not loaded');
    return vad;
  }

  void _trackActive(sherpa.VoiceActivityDetector vad) {
    if (!vad.isDetected()) {
      _activeStart = null;
      return;
    }
    final active = _activeStart;
    if (active == null || active < _lastEnd) {
      _activeStart = max(_lastEnd, _total - _lookback);
    }
  }

  List<SpeechRegion> _drain(sherpa.VoiceActivityDetector vad) {
    final regions = <SpeechRegion>[];
    while (!vad.isEmpty()) {
      final segment = vad.front();
      vad.pop();
      final start = segment.start.clamp(_lastEnd, _total);
      final end = (start + segment.samples.length).clamp(start, _total);
      _lastEnd = end;
      if (end > start) regions.add(SpeechRegion(start, end));
    }
    return regions;
  }
}
