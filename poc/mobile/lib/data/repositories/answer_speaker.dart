import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../utils/sentences.dart';
import 'speech_output.dart';

class AnswerSpeaker {
  AnswerSpeaker(
    this._output, {
    this.onFirstSound,
    this.onChange,
    this.onError,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final SpeechOutput _output;
  final void Function()? onFirstSound;
  final void Function()? onChange;
  final void Function(Object error)? onError;
  final DateTime Function() _now;
  final SentenceSplitter _splitter = SentenceSplitter();
  final Queue<String> _queue = Queue<String>();
  final List<String> _spoken = [];
  final Completer<void> _done = Completer<void>();
  bool _busy = false;
  bool _sounding = false;
  bool _finished = false;
  bool _stopped = false;
  DateTime? _firstSoundAt;
  DateTime? _lastSoundAt;

  bool get isActive => !_done.isCompleted;

  bool get isSpeaking => _sounding && !_stopped;

  String get spokenText => _spoken.join(' ');

  DateTime? get firstSoundAt => _firstSoundAt;

  DateTime? get lastSoundAt => _lastSoundAt;

  Future<void> get done => _done.future;

  void add(String text) {
    if (_stopped || _finished) return;
    _splitter.add(text).forEach(_enqueue);
  }

  void finish() {
    if (_stopped || _finished) return;
    _finished = true;
    _enqueue(_splitter.flush());
    _pump();
  }

  void say(String text) {
    add(text);
    finish();
  }

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    _queue.clear();
    if (_sounding) _lastSoundAt = _now();
    _sounding = false;
    final wasBusy = _busy;
    _complete();
    if (wasBusy) await _output.stop();
  }

  void _enqueue(String text) {
    final sentence = speakable(text);
    if (sentence.isEmpty || _stopped) return;
    _queue.add(sentence);
    _output.prefetch(sentence);
    _pump();
  }

  void _pump() {
    if (_busy || _stopped) return;
    if (_queue.isEmpty) {
      if (_finished) _complete();
      return;
    }
    final sentence = _queue.removeFirst();
    _busy = true;
    _output
        .speak(sentence, onStart: () => _onSentenceStart(sentence))
        .catchError((Object error) {
          debugPrint('Speaking failed: $error');
          if (!_stopped) onError?.call(error);
        })
        .whenComplete(() {
          _busy = false;
          if (_sounding) _lastSoundAt = _now();
          _sounding = false;
          _pump();
        });
  }

  void _onSentenceStart(String sentence) {
    if (_stopped) return;
    _spoken.add(sentence);
    _sounding = true;
    final first = _firstSoundAt == null;
    _firstSoundAt ??= _now();
    if (first) onFirstSound?.call();
    onChange?.call();
  }

  void _complete() {
    if (_done.isCompleted) return;
    _done.complete();
    onChange?.call();
  }
}
