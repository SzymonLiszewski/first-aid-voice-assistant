import 'package:first_aid_voice_assistant/data/repositories/answer_speaker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/services.dart';

void main() {
  late FakeSpeechOutput output;

  setUp(() => output = FakeSpeechOutput(holdSentences: true));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'starts speaking the first sentence before the answer is complete',
    () async {
      var firstSound = 0;
      final speaker = AnswerSpeaker(output, onFirstSound: () => firstSound++);

      speaker.add('Zadzwoń pod sto dwanaście.');
      speaker.add(' Potem');
      await settle();

      expect(output.spoken, ['Zadzwoń pod sto dwanaście.']);
      expect(speaker.isSpeaking, isTrue);
      expect(firstSound, 1);
    },
  );

  test('speaks the sentences one after another, in order', () async {
    final speaker = AnswerSpeaker(output)
      ..add('Pierwsze. Drugie. ')
      ..add('Trzecie')
      ..finish();
    await settle();
    expect(output.spoken, ['Pierwsze.']);
    expect(output.prefetched, ['Pierwsze.', 'Drugie.', 'Trzecie']);

    output.finishSentence();
    await settle();
    output.finishSentence();
    await settle();
    output.finishSentence();
    await settle();

    expect(output.spoken, ['Pierwsze.', 'Drugie.', 'Trzecie']);
    expect(speaker.isActive, isFalse);
    expect(speaker.spokenText, 'Pierwsze. Drugie. Trzecie');
  });

  test('stop silences the output and drops the remaining sentences', () async {
    final speaker = AnswerSpeaker(output)..say('Pierwsze. Drugie. Trzecie.');
    await settle();

    await speaker.stop();
    speaker.add(' Czwarte. ');
    await settle();

    expect(output.stops, 1);
    expect(output.spoken, ['Pierwsze.']);
    expect(speaker.spokenText, 'Pierwsze.');
    expect(speaker.isActive, isFalse);
    expect(speaker.isSpeaking, isFalse);
    expect(speaker.lastSoundAt, isNotNull);
  });

  test('keeps going after a sentence fails to play', () async {
    output
      ..holdSentences = false
      ..speakError = Exception('tts');
    Object? reported;
    final speaker = AnswerSpeaker(output, onError: (e) => reported = e)
      ..say('Pierwsze. Drugie.');

    await speaker.done;

    expect(reported, isNotNull);
  });

  test('stays active while waiting for more text', () async {
    output.holdSentences = false;
    final speaker = AnswerSpeaker(output)..add('Pierwsze. ');
    await settle();

    expect(speaker.isActive, isTrue);
    expect(speaker.isSpeaking, isFalse);

    speaker.finish();
    await speaker.done;
    expect(speaker.isActive, isFalse);
  });

  test('reads the text without markdown', () async {
    output.holdSentences = false;
    final speaker = AnswerSpeaker(output)
      ..say('**Nie panikuj.** 1. **Sprawdź oddech.**');

    await speaker.done;

    expect(output.spoken, ['Nie panikuj.', 'Sprawdź oddech.']);
  });
}
