import '../data/repositories/settings_repository.dart';
import '../data/repositories/speech_input.dart';
import '../data/services/key_value_store.dart';
import '../data/services/model_store.dart';
import '../data/services/parakeet_decoder.dart';
import '../data/services/speech_segmenter.dart';
import '../data/services/streaming_recognizer.dart';
import '../data/services/voice_recorder.dart';
import '../data/services/whisper_decoder.dart';
import '../domain/models/speech_engine.dart';
import '../ui/conversation/view_models/conversation_view_model.dart';

class AppDependencies {
  const AppDependencies({
    required this.settings,
    required this.modelStore,
    required this.createConversationViewModel,
  });

  static Future<AppDependencies> production() async {
    final modelStore = FileModelStore();
    return AppDependencies(
      settings: await SettingsRepository.load(SharedPreferencesStore()),
      modelStore: modelStore,
      createConversationViewModel: (engine) =>
          ConversationViewModel(input: _speechInput(engine, modelStore)),
    );
  }

  static SpeechInput _speechInput(SpeechEngine engine, ModelStore store) {
    return switch (engine.family) {
      EngineFamily.parakeet => SegmentedSpeechInput(
        engine: engine,
        store: store,
        recorder: MicrophoneVoiceRecorder(),
        segmenter: SileroSpeechSegmenter(),
        decoder: ParakeetDecoder(),
      ),
      EngineFamily.whisper => SegmentedSpeechInput(
        engine: engine,
        store: store,
        recorder: MicrophoneVoiceRecorder(),
        segmenter: SileroSpeechSegmenter(),
        decoder: WhisperDecoder(modelPath: engine.primaryModelPath),
      ),
      EngineFamily.vosk => StreamingSpeechInput(
        engine: engine,
        modelDirectory: SpeechEngine.voskModelDir,
        store: store,
        recorder: MicrophoneVoiceRecorder(),
        recognizer: VoskStreamingRecognizer(),
      ),
    };
  }

  final SettingsRepository settings;

  final ModelStore modelStore;

  final ConversationViewModel Function(SpeechEngine engine)
  createConversationViewModel;
}
