import 'package:first_aid_voice_assistant/utils/server_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('turns an HTTP address into the chat WebSocket address', () {
    expect(
      chatSocketUri('http://10.0.2.2:8000').toString(),
      'ws://10.0.2.2:8000/v1/chat',
    );
  });

  test('accepts an address without a scheme', () {
    expect(
      chatSocketUri(' 192.168.1.20:8000 ').toString(),
      'ws://192.168.1.20:8000/v1/chat',
    );
  });

  test('uses wss for https', () {
    expect(
      chatSocketUri('https://example.org').toString(),
      'wss://example.org/v1/chat',
    );
  });

  test('replaces any path', () {
    expect(
      chatSocketUri('ws://host:8000/dev').toString(),
      'ws://host:8000/v1/chat',
    );
  });

  test('rejects empty and unsupported addresses', () {
    expect(chatSocketUri(''), isNull);
    expect(chatSocketUri('ftp://host'), isNull);
    expect(chatSocketUri('http://'), isNull);
  });
}
