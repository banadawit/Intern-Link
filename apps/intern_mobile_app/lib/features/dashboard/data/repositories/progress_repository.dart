import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ---------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------

class PlanDaySubmission {
  final int id;
  final int weeklyPlanId;
  final DateTime workDate;

  PlanDaySubmission({
    required this.id,
    required this.weeklyPlanId,
    required this.workDate,
  });

  factory PlanDaySubmission.fromJson(Map<String, dynamic> json) {
    return PlanDaySubmission(
      id: json['id'] ?? 0,
      weeklyPlanId: json['weeklyPlanId'] ?? 0,
      workDate: DateTime.parse(json['workDate']),
    );
  }
}

class WeeklyPlan {
  final int id;
  final int weekNumber;
  final String planDescription;
  final String status;
  final String? feedback;
  final DateTime submittedAt;
  final List<PlanDaySubmission> daySubmissions;

  WeeklyPlan({
    required this.id,
    required this.weekNumber,
    required this.planDescription,
    required this.status,
    this.feedback,
    required this.submittedAt,
    required this.daySubmissions,
  });

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyPlan(
      id: json['id'] ?? 0,
      weekNumber: json['week_number'] ?? 0,
      planDescription: json['plan_description'] ?? '',
      status: json['status'] ?? 'PENDING',
      feedback: json['feedback'],
      submittedAt: DateTime.parse(json['submitted_at']),
      daySubmissions: (json['daySubmissions'] as List?)
              ?.map((e) => PlanDaySubmission.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------
// REPOSITORY
// ---------------------------------------------------------

class ProgressRepository {
  ProgressRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<WeeklyPlan>> getMyWeeklyPlans() async {
    try {
      final response = await _apiClient.dio.get('/progress/my-plans');
      final data = response.data as List;
      return data.map((e) => WeeklyPlan.fromJson(e)).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to load plans';
      if (data is Map && data.containsKey('message')) {
        message = data['message'];
      } else if (data is String) {
        message = data;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<WeeklyPlan> submitWeeklyPlan(int weekNumber, String description) async {
    try {
      final response = await _apiClient.dio.post(
        '/progress/submit',
        data: {
          'week_number': weekNumber.toString(),
          'plan_description': description,
        },
      );
      return WeeklyPlan.fromJson(response.data['plan']);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to submit plan';
      if (data is Map && data.containsKey('message')) {
        message = data['message'];
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

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgressRepository(apiClient);
});

final myWeeklyPlansProvider = FutureProvider.autoDispose<List<WeeklyPlan>>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  return await repo.getMyWeeklyPlans();
});
