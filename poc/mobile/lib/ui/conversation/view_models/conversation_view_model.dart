import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/speech_input.dart';
import '../../../domain/models/utterance.dart';

enum ConversationStatus {
  preparingModel,
  ready,
  starting,
  recording,
  transcribing,
  failed,
}

class ConversationViewModel extends ChangeNotifier {
  ConversationViewModel({required this._input});

  final SpeechInput _input;

  final List<Utterance> _utterances = [];
  ConversationStatus _status = ConversationStatus.preparingModel;
  String? _message;
  String _partialText = '';
  double? _downloadProgress;
  int _recognizedInRecording = 0;
  StreamSubscription<String>? _partials;
  StreamSubscription<Utterance>? _recognized;
  bool _disposed = false;

  List<Utterance> get utterances => List.unmodifiable(_utterances);
  ConversationStatus get status => _status;
  String get modelLabel => _input.label;
  String? get message => _message;
  String get partialText => _partialText;
  double? get downloadProgress => _downloadProgress;
  bool get canRecord => _status == ConversationStatus.ready;
  bool get isRecording => _status == ConversationStatus.recording;

  Future<void> initialize() async {
    _partials ??= _input.partialText.listen(_onPartialText);
    _recognized ??= _input.utterances.listen(_onUtterance);
    _downloadProgress = null;
    _setStatus(ConversationStatus.preparingModel);
    try {
      await _input.prepare(onProgress: _onDownloadProgress);
      _downloadProgress = null;
      _setStatus(ConversationStatus.ready);
    } catch (e) {
      debugPrint('Preparing speech recognition failed: $e');
      _setStatus(
        ConversationStatus.failed,
        message:
            'Nie udało się przygotować modelu rozpoznawania mowy. '
            'Sprawdź połączenie z internetem i spróbuj ponownie.',
      );
    }
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    if (!canRecord) return;
    _setStatus(ConversationStatus.starting);
    if (!await _input.hasPermission()) {
      _setStatus(
        ConversationStatus.ready,
        message: 'Brak dostępu do mikrofonu. Zezwól na niego w ustawieniach telefonu.',
      );
      return;
    }
    try {
      await _input.start();
    } catch (e) {
      debugPrint('Starting speech recognition failed: $e');
      _setStatus(
        ConversationStatus.ready,
        message: 'Nie udało się uruchomić nagrywania.',
      );
      return;
    }
    _partialText = '';
    _recognizedInRecording = 0;
    _setStatus(ConversationStatus.recording);
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    _setStatus(ConversationStatus.transcribing);
    try {
      await _input.finish();
      _partialText = '';
      _setStatus(
        ConversationStatus.ready,
        message: _recognizedInRecording == 0
            ? 'Nie rozpoznano mowy. Spróbuj jeszcze raz.'
            : null,
      );
    } catch (e) {
      debugPrint('Speech recognition failed: $e');
      _partialText = '';
      _setStatus(
        ConversationStatus.ready,
        message: 'Nie udało się rozpoznać mowy.',
      );
    }
  }

  void _onUtterance(Utterance utterance) {
    if (_disposed) return;
    _utterances.add(utterance);
    _recognizedInRecording++;
    _partialText = '';
    notifyListeners();
  }

  void _onPartialText(String text) {
    if (_disposed) return;
    if (_status != ConversationStatus.recording &&
        _status != ConversationStatus.transcribing) {
      return;
    }
    _partialText = text;
    notifyListeners();
  }

  void _onDownloadProgress(double progress) {
    final previous = ((_downloadProgress ?? -1) * 100).floor();
    _downloadProgress = progress;
    if (!_disposed && (progress * 100).floor() != previous) notifyListeners();
  }

  void _setStatus(ConversationStatus status, {String? message}) {
    if (_disposed) return;
    _status = status;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _partials?.cancel();
    _recognized?.cancel();
    _input.dispose();
    super.dispose();
  }
}
