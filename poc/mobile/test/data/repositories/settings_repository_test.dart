import 'package:first_aid_voice_assistant/data/repositories/settings_repository.dart';
import 'package:first_aid_voice_assistant/domain/models/speech_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/services.dart';

void main() {
  test('uses Parakeet when nothing is saved', () async {
    final settings = await SettingsRepository.load(MemoryStore());

    expect(settings.speechEngine, SpeechEngine.parakeet);
  });

  test('remembers the chosen engine', () async {
    final store = MemoryStore();
    final settings = await SettingsRepository.load(store);

    await settings.setSpeechEngine(SpeechEngine.vosk);
    final reloaded = await SettingsRepository.load(store);

    expect(reloaded.speechEngine, SpeechEngine.vosk);
  });

  test('falls back to the default for an unknown saved value', () async {
    final store = MemoryStore()..values['speech_engine'] = 'huge';

    final settings = await SettingsRepository.load(store);

    expect(settings.speechEngine, SpeechEngine.defaultEngine);
  });
}
