String formatSeconds(Duration duration) =>
    '${(duration.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';

String formatClock(DateTime time) =>
    '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}:${_twoDigits(time.second)}';

String _twoDigits(int value) => value.toString().padLeft(2, '0');
