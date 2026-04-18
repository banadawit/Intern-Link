import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _defaultBaseUrl = 'http://10.0.2.2:5000/api';

  String get baseUrl {
    final fromEnv = const String.fromEnvironment('API_BASE_URL');
    if (fromEnv.trim().isNotEmpty) {
      return _normalizeApiBase(fromEnv);
    }
    return _defaultBaseUrl;
  }

  static String _normalizeApiBase(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api')) {
      return trimmed;
    }
    return '$trimmed/api';
  }

  Uri authUri(String path) => Uri.parse('$baseUrl/auth/$path');

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) {
    return _client.get(url, headers: headers);
  }
}
