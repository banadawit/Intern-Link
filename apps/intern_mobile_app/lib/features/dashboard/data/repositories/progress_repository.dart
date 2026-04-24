import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

import '../../../plans/domain/entities/weekly_plan.dart';
import '../../../plans/domain/entities/daily_checkin.dart';
import '../../../plans/domain/entities/plan_enums.dart';
import '../../../plans/data/models/plans_dtos.dart';

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
      return data.map((e) => PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(e))).toList();
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
      return PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(response.data['plan']));
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

  Future<void> submitPlanDay(int planId, String workDate) async {
    try {
      await _apiClient.dio.post(
        '/progress/plan/$planId/days',
        data: {'workDate': workDate},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to log daily check-in';
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
