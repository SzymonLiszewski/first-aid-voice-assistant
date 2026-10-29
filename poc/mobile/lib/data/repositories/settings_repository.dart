import 'package:flutter/foundation.dart';

import '../../domain/models/speech_engine.dart';
import '../../domain/models/voice_engine.dart';
import '../../utils/server_address.dart';
import '../services/key_value_store.dart';

class SettingsRepository extends ChangeNotifier {
  SettingsRepository._(
    this._store,
    this._speechEngine,
    this._voiceEngine,
    this._serverAddress,
  );

  static const String _speechEngineKey = 'speech_engine';
  static const String _voiceEngineKey = 'voice_engine';
  static const String _serverAddressKey = 'server_address';

  final KeyValueStore _store;
  SpeechEngine _speechEngine;
  VoiceEngine _voiceEngine;
  String _serverAddress;

  static Future<SettingsRepository> load(KeyValueStore store) async {
    final engine = SpeechEngine.values
        .asNameMap()[await store.getString(_speechEngineKey)];
    final voice = VoiceEngine.values
        .asNameMap()[await store.getString(_voiceEngineKey)];
    return SettingsRepository._(
      store,
      engine ?? SpeechEngine.defaultEngine,
      voice ?? VoiceEngine.defaultEngine,
      await store.getString(_serverAddressKey) ?? defaultServerAddress,
    );
  }

  SpeechEngine get speechEngine => _speechEngine;

  VoiceEngine get voiceEngine => _voiceEngine;

  String get serverAddress => _serverAddress;

  Uri? get chatUri => chatSocketUri(_serverAddress);

  Future<void> setSpeechEngine(SpeechEngine engine) async {
    if (engine == _speechEngine) return;
    _speechEngine = engine;
    notifyListeners();
    await _store.setString(_speechEngineKey, engine.name);
  }

  Future<void> setVoiceEngine(VoiceEngine engine) async {
    if (engine == _voiceEngine) return;
    _voiceEngine = engine;
    notifyListeners();
    await _store.setString(_voiceEngineKey, engine.name);
  }

  Future<void> setServerAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed == _serverAddress) return;
    _serverAddress = trimmed;
    notifyListeners();
    await _store.setString(_serverAddressKey, trimmed);
  }
}
