import 'package:first_aid_voice_assistant/utils/transcript.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes Whisper tags in square brackets', () {
    expect(cleanTranscript('[BLANK_AUDIO]'), '');
    expect(
      cleanTranscript(' Kolega [MUSIC] nie oddycha '),
      'Kolega nie oddycha',
    );
  });

  test('drops a transcript that is only a sound description', () {
    expect(cleanTranscript('(muzyka)'), '');
    expect(cleanTranscript('*kaszel*'), '');
  });

  test('keeps words in parentheses inside real speech', () {
    expect(cleanTranscript('Dzwonię (już) na 112'), 'Dzwonię (już) na 112');
  });

  test('collapses a word repeated in a loop', () {
    expect(
      cleanTranscript('Gada gada gada gada gada gada gada możnik bambor.'),
      'Gada możnik bambor.',
    );
  });

  test('collapses a repeated phrase', () {
    expect(
      collapseRepetitions(
        'uciskaj mocno uciskaj mocno uciskaj mocno, licz głośno',
      ),
      'uciskaj mocno licz głośno',
    );
  });

  test('keeps short natural repetitions', () {
    expect(collapseRepetitions('nie nie nie oddycha'), 'nie nie nie oddycha');
    expect(collapseRepetitions('raz dwa trzy cztery'), 'raz dwa trzy cztery');
  });
}
