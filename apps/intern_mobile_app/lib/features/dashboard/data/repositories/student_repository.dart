import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ---------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------

class StudentProfile {
  final int id;
  final String fullName;
  final String email;
  final String? companyName;
  final String? supervisorName;
  final int currentInternshipWeek;
  final String status;

  StudentProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.companyName,
    this.supervisorName,
    required this.currentInternshipWeek,
    required this.status,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final activeAssignment = json['activeAssignment'];
    final company = activeAssignment != null ? activeAssignment['company'] : null;
    final supervisor = json['supervisor'];

    return StudentProfile(
      id: json['id'] ?? 0,
      fullName: user['full_name'] ?? 'Unknown Student',
      email: user['email'] ?? '',
      companyName: company != null ? company['name'] : null,
      supervisorName: supervisor != null ? supervisor['full_name'] : null,
      currentInternshipWeek: json['currentInternshipWeek'] ?? 1,
      status: json['hod_approval_status'] ?? 'PENDING',
    );
  }
}

// ---------------------------------------------------------
// REPOSITORY
// ---------------------------------------------------------

class StudentRepository {
  StudentRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<StudentProfile> getStudentProfile() async {
    try {
      final response = await _apiClient.dio.get('/students/me');
      if (response.data is! Map) {
        throw Exception('Unexpected response format from server');
      }
      return StudentProfile.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to load profile';
      if (data is Map && data.containsKey('message')) {
        message = data['message'];
      } else if (data is Map && data.containsKey('error')) {
        message = data['error'];
      } else if (data is String) {
        message = data;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}

// ---------------------------------------------------------
// PROVIDERS
// ---------------------------------------------------------

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StudentRepository(apiClient);
});

final studentProfileProvider = FutureProvider.autoDispose<StudentProfile>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  return await repo.getStudentProfile();
});
