import 'package:flutter/foundation.dart';

import '../../domain/models/speech_engine.dart';
import '../services/key_value_store.dart';

class SettingsRepository extends ChangeNotifier {
  SettingsRepository._(this._store, this._speechEngine);

  static const String _speechEngineKey = 'speech_engine';

  final KeyValueStore _store;
  SpeechEngine _speechEngine;

  static Future<SettingsRepository> load(KeyValueStore store) async {
    final engine = SpeechEngine.values
        .asNameMap()[await store.getString(_speechEngineKey)];
    return SettingsRepository._(store, engine ?? SpeechEngine.defaultEngine);
  }

  SpeechEngine get speechEngine => _speechEngine;

  Future<void> setSpeechEngine(SpeechEngine engine) async {
    if (engine == _speechEngine) return;
    _speechEngine = engine;
    notifyListeners();
    await _store.setString(_speechEngineKey, engine.name);
  }
}
