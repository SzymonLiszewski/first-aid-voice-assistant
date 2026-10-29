const Set<String> _abbreviations = {
  'np',
  'itp',
  'itd',
  'tzn',
  'tj',
  'ok',
  'm.in',
  'dr',
  'nr',
  'ul',
  'godz',
  'min',
  'tel',
  'wg',
  'pkt',
  'ds',
  'prof',
  'zob',
  'tzw',
  'ew',
};

final RegExp _sentenceEnd = RegExp(r'[.!?…]+["”»)\]*_]*(?=\s)|\n+');
final RegExp _lastWord = RegExp(r'(\S+)$');
final RegExp _leadingPunctuation = RegExp(r'^[("„«\[]+');

class SentenceSplitter {
  SentenceSplitter({this.maxLength = 160});

  final int maxLength;
  String _pending = '';

  List<String> add(String text) {
    _pending += text;
    final sentences = <String>[];
    var cut = 0;
    for (final match in _sentenceEnd.allMatches(_pending)) {
      if (match.start < cut) continue;
      if (_endsWithAbbreviation(_pending.substring(cut, match.start), match)) {
        continue;
      }
      _addSentence(sentences, _pending.substring(cut, match.end));
      cut = match.end;
    }
    _pending = _pending.substring(cut);
    while (_pending.length > maxLength) {
      final comma = _pending.lastIndexOf(', ', maxLength);
      final space = _pending.lastIndexOf(' ', maxLength);
      final at = comma > 0 ? comma + 1 : space;
      if (at <= 0) break;
      _addSentence(sentences, _pending.substring(0, at));
      _pending = _pending.substring(at);
    }
    return sentences;
  }

  String flush() {
    final rest = _pending.trim();
    _pending = '';
    return rest;
  }

  void _addSentence(List<String> sentences, String text) {
    final sentence = text.trim();
    if (sentence.isNotEmpty) sentences.add(sentence);
  }

  bool _endsWithAbbreviation(String before, RegExpMatch end) {
    if (end[0] != '.') return false;
    final word = _lastWord.firstMatch(before)?.group(1);
    if (word == null) return false;
    return _abbreviations.contains(
      word.replaceFirst(_leadingPunctuation, '').toLowerCase(),
    );
  }
}

final RegExp _markdownMarks = RegExp(r'[*#`~>|]+');
final RegExp _listMarker = RegExp(r'^\s*(?:[-•]|\d+[.)])\s*');
final RegExp _spaces = RegExp(r'\s+');

String speakable(String sentence) => sentence
    .replaceAll(_markdownMarks, '')
    .replaceFirst(_listMarker, '')
    .replaceAll(_spaces, ' ')
    .trim();
