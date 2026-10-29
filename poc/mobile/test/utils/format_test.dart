import 'package:first_aid_voice_assistant/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats seconds with one decimal and a decimal comma', () {
    expect(formatSeconds(const Duration(milliseconds: 1840)), '1,8 s');
    expect(formatSeconds(const Duration(seconds: 36)), '36,0 s');
  });

  test('formats the time of day with leading zeros', () {
    expect(formatClock(DateTime(2026, 10, 27, 9, 5, 3)), '09:05:03');
  });
}
