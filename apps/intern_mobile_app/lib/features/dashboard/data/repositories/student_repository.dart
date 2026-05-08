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
  final DateTime? internshipStartDate;
  final int currentInternshipWeek;
  final String status;
  final String internshipStatus;

  StudentProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.companyName,
    this.supervisorName,
    this.internshipStartDate,
    required this.currentInternshipWeek,
    required this.status,
    required this.internshipStatus,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final activeAssignment = json['activeAssignment'];
    final company = activeAssignment != null ? activeAssignment['company'] : null;
    final supervisor = json['supervisor'];
    final startDateRaw = activeAssignment != null ? activeAssignment['start_date'] : null;

    int si(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return StudentProfile(
      id: si(json['id']),
      fullName: user['full_name']?.toString() ?? 'Unknown Student',
      email: user['email']?.toString() ?? '',
      companyName: company != null ? company['name']?.toString() : null,
      supervisorName: supervisor != null ? supervisor['full_name']?.toString() : null,
      internshipStartDate: startDateRaw is String ? DateTime.tryParse(startDateRaw) : null,
      currentInternshipWeek: si(json['currentInternshipWeek']),
      status: json['hod_approval_status']?.toString() ?? 'PENDING',
      internshipStatus: json['internship_status']?.toString() ?? 'PENDING',
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
