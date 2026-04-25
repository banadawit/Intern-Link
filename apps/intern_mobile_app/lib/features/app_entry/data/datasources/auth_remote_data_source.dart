import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/current_user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CurrentUserModel> fetchCurrentUser(String token) async {
    try {
      final response = await _apiClient.dio.get(
        '/auth/me',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        throw const SessionValidationException('Malformed /auth/me response.');
      }
      return CurrentUserModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const SessionInvalidException();
      }
      throw SessionValidationException(
        'Failed to validate token: HTTP ${e.response?.statusCode}',
      );
    } catch (e) {
      throw const SessionValidationException('An unexpected error occurred.');
    }
  }
}

class SessionInvalidException implements Exception {
  const SessionInvalidException();
}

class SessionValidationException implements Exception {
  const SessionValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
