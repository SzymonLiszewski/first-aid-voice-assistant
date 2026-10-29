import 'dart:async';

import 'package:first_aid_voice_assistant/data/repositories/speech_output.dart';
import 'package:first_aid_voice_assistant/domain/models/voice_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/services.dart';

void main() {
  group('system voice', () {
    test('needs a Polish voice on the phone', () async {
      final tts = FakeTextToSpeech()..languageAvailable = false;

      expect(
        SystemSpeechOutput(tts: tts).prepare(),
        throwsA(isA<MissingVoiceException>()),
      );
    });

    test('speaks through the phone text-to-speech', () async {
      final tts = FakeTextToSpeech();
      final output = SystemSpeechOutput(tts: tts);
      var started = false;

      await output.prepare();
      await output.speak('Dzień dobry.', onStart: () => started = true);

      expect(tts.spoken, ['Dzień dobry.']);
      expect(started, isTrue);
    });
  });

  group('Piper voice', () {
    late FakeModelStore store;
    late FakeSpeechSynthesizer synthesizer;
    late FakeAudioOutput audio;
    late SynthesizedSpeechOutput output;

    setUp(() {
      store = FakeModelStore({});
      synthesizer = FakeSpeechSynthesizer();
      audio = FakeAudioOutput();
      output = SynthesizedSpeechOutput(
        engine: VoiceEngine.piperGosia,
        store: store,
        synthesizer: synthesizer,
        audio: audio,
      );
    });

    test('downloads and loads the voice, then warms it up', () async {
      await output.prepare();

      expect(store.downloaded, contains(VoiceEngine.piperGosia));
      expect(
        synthesizer.loadedModel,
        'models/piper/vits-piper-pl_PL-gosia-medium/pl_PL-gosia-medium.onnx',
      );
      expect(synthesizer.synthesized, hasLength(1));
    });

    test('plays the synthesized sentence as WAV', () async {
      await output.speak('Uciskaj.');

      expect(synthesizer.synthesized, ['Uciskaj.']);
      expect(audio.played.single.length, 44 + 'Uciskaj.'.length * 2);
    });

    test('uses audio prepared in advance', () async {
      output.prefetch('Uciskaj.');
      await output.speak('Uciskaj.');

      expect(synthesizer.synthesized, ['Uciskaj.']);
      expect(audio.played, hasLength(1));
    });

    test(
      'does not play a sentence stopped while it was being prepared',
      () async {
        synthesizer.gate = Completer<void>();
        var started = false;
        final speaking = output.speak(
          'Uciskaj.',
          onStart: () => started = true,
        );

        await output.stop();
        synthesizer.gate!.complete();
        await speaking;

        expect(started, isFalse);
        expect(audio.played, isEmpty);
        expect(audio.stops, 1);
      },
    );
  });
}
