import 'package:dio/dio.dart';

import '../models/auth_models.dart';

class AuthRemoteService {
  AuthRemoteService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      final token = data?['token']?.toString().trim();
      if (token == null || token.isEmpty) {
        throw const AuthApiException('Login response did not include a token.');
      }

      return LoginResult(token: token);
    } on DioException catch (error) {
      throw _buildException(error);
    }
  }

  Future<void> register(RegisterPayload payload) async {
    final formData = FormData.fromMap({
      'full_name': payload.fullName,
      'email': payload.email,
      'password': payload.password,
      'role': payload.role.backendValue,
      if (payload.universityName?.trim().isNotEmpty ?? false)
        'university_name': payload.universityName!.trim(),
      if (payload.companyName?.trim().isNotEmpty ?? false)
        'company_name': payload.companyName!.trim(),
      if (payload.department?.trim().isNotEmpty ?? false)
        'department': payload.department!.trim(),
      if (payload.studentId?.trim().isNotEmpty ?? false)
        'student_id': payload.studentId!.trim(),
      if (payload.position?.trim().isNotEmpty ?? false)
        'position': payload.position!.trim(),
      if (payload.universityId != null)
        'university_id': payload.universityId.toString(),
      if (payload.hodId != null) 'hod_id': payload.hodId.toString(),
      if (payload.employeeId?.trim().isNotEmpty ?? false)
        'employee_id': payload.employeeId!.trim(),
    });

    try {
      await _dio.post<void>(
        '/auth/register',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (error) {
      throw _buildException(error);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post<void>('/auth/forgot-password', data: {'email': email});
    } on DioException catch (error) {
      throw _buildException(error);
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      await _dio.post<void>('/auth/verify-email', data: {'token': token});
    } on DioException catch (error) {
      throw _buildException(error);
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _dio.post<void>(
        '/auth/resend-verification',
        data: {'email': email},
      );
    } on DioException catch (error) {
      throw _buildException(error);
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }

    return 'Request failed. Please try again.';
  }

  AuthApiException _buildException(DioException error) {
    final data = error.response?.data;

    String? code;
    bool requiresVerification = false;
    String? email;
    if (data is Map<String, dynamic>) {
      code = data['code']?.toString();
      requiresVerification = data['requiresVerification'] == true;
      email = data['email']?.toString();
    }

    return AuthApiException(
      _extractErrorMessage(error),
      statusCode: error.response?.statusCode,
      code: code,
      requiresVerification: requiresVerification,
      email: email,
    );
  }
}

class AuthApiException implements Exception {
  const AuthApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.requiresVerification = false,
    this.email,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final bool requiresVerification;
  final String? email;

  @override
  String toString() => message;
}
