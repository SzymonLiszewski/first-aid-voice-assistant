import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

abstract interface class ChatSocket {
  Future<ChatConnection> connect(Uri uri, {required Duration timeout});
}

abstract interface class ChatConnection {
  Stream<String> get incoming;

  void send(String message);

  Future<void> close();
}

class WebSocketChatSocket implements ChatSocket {
  @override
  Future<ChatConnection> connect(Uri uri, {required Duration timeout}) async {
    final channel = WebSocketChannel.connect(uri);
    try {
      await channel.ready.timeout(timeout);
    } catch (_) {
      unawaited(channel.sink.close());
      rethrow;
    }
    return _WebSocketConnection(channel);
  }
}

class _WebSocketConnection implements ChatConnection {
  _WebSocketConnection(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<String> get incoming =>
      _channel.stream.where((message) => message is String).cast<String>();

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}
