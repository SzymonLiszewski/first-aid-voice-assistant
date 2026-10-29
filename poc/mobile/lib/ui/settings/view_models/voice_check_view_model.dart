import 'package:flutter/foundation.dart';

import '../../../data/repositories/speech_output.dart';
import '../../../domain/models/voice_engine.dart';

enum VoiceCheckStatus { idle, preparing, speaking, failed }

const String voiceCheckSentence =
    'Jestem asystentem pierwszej pomocy. '
    'W nagłym wypadku zadzwoń pod numer sto dwanaście.';

class VoiceCheckViewModel extends ChangeNotifier {
  VoiceCheckViewModel({required this._createOutput});

  final SpeechOutput Function(VoiceEngine voice) _createOutput;

  VoiceCheckStatus _status = VoiceCheckStatus.idle;
  double? _progress;
  String? _message;
  SpeechOutput? _output;
  bool _disposed = false;

  VoiceCheckStatus get status => _status;
  double? get progress => _progress;
  String? get message => _message;
  bool get isBusy =>
      _status == VoiceCheckStatus.preparing ||
      _status == VoiceCheckStatus.speaking;

  Future<void> check(VoiceEngine voice) async {
    if (isBusy) return;
    final output = _createOutput(voice);
    _output = output;
    _progress = null;
    _set(VoiceCheckStatus.preparing);
    try {
      await output.prepare(onProgress: _onProgress);
      _set(VoiceCheckStatus.speaking);
      await output.speak(voiceCheckSentence);
      _set(VoiceCheckStatus.idle);
    } catch (e) {
      debugPrint('Voice check failed: $e');
      _set(
        VoiceCheckStatus.failed,
        message: e is MissingVoiceException
            ? 'Telefon nie ma polskiego głosu systemowego. Zainstaluj go '
                  'w ustawieniach mowy telefonu albo wybierz głos Piper.'
            : 'Nie udało się odtworzyć głosu. Sprawdź połączenie z internetem.',
      );
    } finally {
      _output = null;
      await output.dispose();
    }
  }

  void _onProgress(double progress) {
    final previous = ((_progress ?? -1) * 100).floor();
    _progress = progress;
    if (!_disposed && (progress * 100).floor() != previous) notifyListeners();
  }

  void _set(VoiceCheckStatus status, {String? message}) {
    if (_disposed) return;
    _status = status;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _output?.stop();
    super.dispose();
  }
}
