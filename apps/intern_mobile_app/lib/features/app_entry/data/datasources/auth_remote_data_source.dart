import 'dart:convert';


import '../../../../core/network/api_client.dart';
import '../models/current_user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CurrentUserModel> fetchCurrentUser(String token) async {
    final response = await _apiClient.get(
      _apiClient.authUri('me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      throw const SessionInvalidException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SessionValidationException(
        'Failed to validate token: HTTP ${response.statusCode}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const SessionValidationException('Malformed /auth/me response.');
    }

    return CurrentUserModel.fromJson(data);
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
