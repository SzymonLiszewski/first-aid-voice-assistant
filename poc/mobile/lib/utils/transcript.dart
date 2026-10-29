final RegExp _bracketTag = RegExp(r'\[[^\]]*\]');
final RegExp _wholeSoundTag = RegExp(r'^(\([^)]*\)|\*[^*]*\*)$');
final RegExp _whitespace = RegExp(r'\s+');
final RegExp _punctuation = RegExp(r'[^\p{L}\p{N}]', unicode: true);

String cleanTranscript(String raw) {
  var text = raw
      .replaceAll(_bracketTag, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();
  if (_wholeSoundTag.hasMatch(text)) return '';
  return collapseRepetitions(text);
}

String collapseRepetitions(String text) {
  var words = text.split(' ').where((w) => w.isNotEmpty).toList();
  for (var size = 1; size <= 3; size++) {
    words = _collapse(words, size, minRepeats: size == 1 ? 4 : 3);
  }
  return words.join(' ');
}

List<String> _collapse(
  List<String> words,
  int size, {
  required int minRepeats,
}) {
  final result = <String>[];
  var i = 0;
  while (i < words.length) {
    var repeats = 1;
    while (_sameGroup(words, i, i + repeats * size, size)) {
      repeats++;
    }
    if (repeats >= minRepeats) {
      result.addAll(words.sublist(i, i + size));
      i += repeats * size;
    } else {
      result.add(words[i]);
      i++;
    }
  }
  return result;
}

bool _sameGroup(List<String> words, int first, int second, int size) {
  if (second + size > words.length) return false;
  for (var k = 0; k < size; k++) {
    if (_normalize(words[first + k]) != _normalize(words[second + k])) {
      return false;
    }
  }
  return true;
}

String _normalize(String word) =>
    word.toLowerCase().replaceAll(_punctuation, '');
