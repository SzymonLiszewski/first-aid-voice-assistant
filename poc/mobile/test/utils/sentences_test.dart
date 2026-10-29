import 'package:first_aid_voice_assistant/utils/sentences.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> splitAll(List<String> deltas) {
  final splitter = SentenceSplitter();
  return [...deltas.expand(splitter.add), splitter.flush()]
    ..removeWhere((s) => s.isEmpty);
}

void main() {
  test('returns a sentence as soon as the next word starts', () {
    final splitter = SentenceSplitter();

    expect(splitter.add('Zadzwoń pod sto'), isEmpty);
    expect(splitter.add(' dwanaście.'), isEmpty);
    expect(splitter.add(' Czy'), ['Zadzwoń pod sto dwanaście.']);
    expect(splitter.flush(), 'Czy');
  });

  test('splits on question and exclamation marks', () {
    expect(splitAll(['Czy oddycha? Sprawdź! Teraz.']), [
      'Czy oddycha?',
      'Sprawdź!',
      'Teraz.',
    ]);
  });

  test('does not split after Polish abbreviations', () {
    expect(splitAll(['Połóż go np. na boku. Potem sprawdź.']), [
      'Połóż go np. na boku.',
      'Potem sprawdź.',
    ]);
  });

  test('splits on new lines', () {
    expect(splitAll(['Pierwsze\nDrugie']), ['Pierwsze', 'Drugie']);
  });

  test('cuts a very long sentence at a comma', () {
    final splitter = SentenceSplitter(maxLength: 45);

    final sentences = splitter.add(
      'Uciskaj mocno i szybko na środku klatki, nie przerywaj ',
    );

    expect(sentences, ['Uciskaj mocno i szybko na środku klatki,']);
  });

  test('flush returns nothing for whitespace', () {
    final splitter = SentenceSplitter()..add('Dobrze. ');

    expect(splitter.flush(), isEmpty);
  });

  test('speakable text has no markdown or list markers', () {
    expect(speakable('**Nie panikuj.**'), 'Nie panikuj.');
    expect(speakable('1. **Sprawdź oddech.**'), 'Sprawdź oddech.');
    expect(speakable('- Zadzwoń   pod 112.'), 'Zadzwoń pod 112.');
    expect(speakable('**'), isEmpty);
    expect(speakable('1.'), isEmpty);
  });
}
