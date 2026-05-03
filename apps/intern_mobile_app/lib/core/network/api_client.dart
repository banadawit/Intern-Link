import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(sessionService: ref.watch(appSessionServiceProvider));
});

class ApiClient {
  ApiClient({required this.sessionService}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60), // AI responses can take time
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await sessionService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final data = response.data;
          if (data is Map && data.containsKey('success')) {
            final success = data['success'];
            final isSuccess = success == true || success == 'true' || success == 1 || success == '1';
            
            if (isSuccess && data.containsKey('data')) {
              final inner = data['data'];
              // Only unwrap Maps and Lists — leave primitives (int, String, bool) wrapped
              // so repositories can still access the full response if needed
              if (inner is Map || inner is List) {
                response.data = inner;
              }
            }
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Handle global errors here if needed (e.g. 401 token expiry)
          return handler.next(e);
        },
      ),
    );
  }

  final AppSessionService sessionService;
  late final Dio _dio;

  Dio get dio => _dio;

  static String get _defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://10.0.2.2:5000/api';
  }

  String get _baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
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
}
