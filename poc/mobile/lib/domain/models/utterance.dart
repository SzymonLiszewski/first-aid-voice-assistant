class Utterance {
  const Utterance({
    required this.text,
    required this.endedAt,
    required this.speechDuration,
    required this.transcriptionDuration,
  });

  final String text;

  final DateTime endedAt;

  final Duration speechDuration;

  final Duration transcriptionDuration;
}
