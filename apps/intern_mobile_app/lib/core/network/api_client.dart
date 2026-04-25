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
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
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
            // Handle varied success flag types (bool, string, int)
            final isSuccess = success == true || success == 'true' || success == 1 || success == '1';
            
            if (isSuccess) {
              // Extract the inner data if it exists, otherwise return the whole wrapper
              // (This allows gradual migration of all endpoints)
              if (data.containsKey('data')) {
                response.data = data['data'];
              }
            } else {
              // If success is false, we could reject here, but we'll let repositories handle messages
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
