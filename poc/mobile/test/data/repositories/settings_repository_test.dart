import 'package:first_aid_voice_assistant/data/repositories/settings_repository.dart';
import 'package:first_aid_voice_assistant/domain/models/speech_engine.dart';
import 'package:first_aid_voice_assistant/domain/models/voice_engine.dart';
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

  test('uses the system voice and the emulator address by default', () async {
    final settings = await SettingsRepository.load(MemoryStore());

    expect(settings.voiceEngine, VoiceEngine.system);
    expect(settings.serverAddress, 'http://10.0.2.2:8000');
    expect(settings.chatUri.toString(), 'ws://10.0.2.2:8000/v1/chat');
  });

  test('remembers the voice and the server address', () async {
    final store = MemoryStore();
    final settings = await SettingsRepository.load(store);

    await settings.setVoiceEngine(VoiceEngine.piperGosia);
    await settings.setServerAddress(' 192.168.1.20:8000 ');
    final reloaded = await SettingsRepository.load(store);

    expect(reloaded.voiceEngine, VoiceEngine.piperGosia);
    expect(reloaded.serverAddress, '192.168.1.20:8000');
    expect(reloaded.chatUri.toString(), 'ws://192.168.1.20:8000/v1/chat');
  });

  test('an invalid server address gives no connection address', () async {
    final settings = await SettingsRepository.load(MemoryStore());

    await settings.setServerAddress('');

    expect(settings.chatUri, isNull);
  });
}
