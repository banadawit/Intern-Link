import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ---------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------

class SupervisorMe {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String companyName;

  SupervisorMe({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.companyName,
  });

  factory SupervisorMe.fromJson(Map<String, dynamic> json) {
    return SupervisorMe(
      id: json['id'] ?? 0,
      fullName: json['user']?['full_name'] ?? 'Supervisor',
      email: json['user']?['email'] ?? '',
      phone: json['phone_number'] ?? '',
      companyName: json['company']?['name'] ?? 'Assigned Company',
    );
  }
}

class SupervisorStudent {
  final int id;
  final String fullName;
  final String email;
  final String status;
  final DateTime startDate;

  SupervisorStudent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    required this.startDate,
  });

  factory SupervisorStudent.fromJson(Map<String, dynamic> json) {
    return SupervisorStudent(
      id: json['id'] ?? 0,
      fullName: json['user']?['full_name'] ?? 'Student',
      email: json['user']?['email'] ?? '',
      status: json['internship_status'] ?? 'UNKNOWN',
      startDate: DateTime.tryParse(json['assignments']?[0]?['start_date'] ?? '') ?? DateTime.now(),
    );
  }
}

class SupervisorPlan {
  final int id;
  final int weekNumber;
  final String studentName;
  final String description;
  final String status;

  SupervisorPlan({
    required this.id,
    required this.weekNumber,
    required this.studentName,
    required this.description,
    required this.status,
  });

  factory SupervisorPlan.fromJson(Map<String, dynamic> json) {
    return SupervisorPlan(
      id: json['id'] ?? 0,
      weekNumber: json['week_number'] ?? 0,
      studentName: json['student']?['user']?['full_name'] ?? 'Student',
      description: json['plan_description'] ?? '',
      status: json['status'] ?? 'PENDING',
    );
  }
}

// ---------------------------------------------------------
// REPOSITORY
// ---------------------------------------------------------

class SupervisorRepository {
  SupervisorRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<SupervisorMe> getMe() async {
    try {
      final response = await _apiClient.dio.get('/supervisor/me');
      return SupervisorMe.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load profile');
    }
  }

  Future<List<SupervisorStudent>> getStudents() async {
    try {
      final response = await _apiClient.dio.get('/supervisor/students');
      return (response.data as List).map((e) => SupervisorStudent.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load students');
    }
  }

  Future<List<SupervisorPlan>> getWeeklyPlans() async {
    try {
      final response = await _apiClient.dio.get('/supervisor/weekly-plans');
      return (response.data as List).map((e) => SupervisorPlan.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load plans');
    }
  }
  
  Future<void> reviewPlan(int planId, String status, String remarks, bool attendance) async {
    try {
      await _apiClient.dio.patch(
        '/progress/review/$planId',
        data: {
          'status': status,
          'remarks': remarks,
          'attendance': attendance,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to review plan');
    }
  }
}

// ---------------------------------------------------------
// PROVIDERS
// ---------------------------------------------------------

final supervisorRepositoryProvider = Provider<SupervisorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupervisorRepository(apiClient);
});

final supervisorMeProvider = FutureProvider.autoDispose<SupervisorMe>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return await repo.getMe();
});

final supervisorStudentsProvider = FutureProvider.autoDispose<List<SupervisorStudent>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return await repo.getStudents();
});

final supervisorPlansProvider = FutureProvider.autoDispose<List<SupervisorPlan>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return await repo.getWeeklyPlans();
});
