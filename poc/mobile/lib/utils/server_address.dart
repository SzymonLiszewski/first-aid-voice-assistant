const String defaultServerAddress = 'http://10.0.2.2:8000';

const String chatPath = '/v1/chat';

Uri? chatSocketUri(String address) {
  var text = address.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'http://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;
  final scheme = switch (uri.scheme) {
    'http' || 'ws' => 'ws',
    'https' || 'wss' => 'wss',
    _ => null,
  };
  if (scheme == null) return null;
  return Uri(
    scheme: scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: chatPath,
  );
}
