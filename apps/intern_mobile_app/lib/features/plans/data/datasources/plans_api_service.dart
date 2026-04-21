import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class PlansApiService {
  PlansApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> fetchMyPlans() async {
    final res = await _apiClient.dio.get('/progress/my-plans');
    return (res.data as List);
  }

  Future<Map<String, dynamic>> submitPlan({
    required int weekNumber,
    required String planDescription,
    String? presentationFilePath,
  }) async {
    final form = FormData.fromMap({
      'week_number': weekNumber.toString(),
      'plan_description': planDescription,
      if (presentationFilePath != null && presentationFilePath.trim().isNotEmpty)
        'presentation': await MultipartFile.fromFile(
          presentationFilePath,
          filename: presentationFilePath.split(Platform.pathSeparator).last,
        ),
    });

    final res = await _apiClient.dio.post(
      '/progress/submit',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected submit response');
  }

  Future<Map<String, dynamic>> updatePlanDescription({
    required int planId,
    required String planDescription,
  }) async {
    final res = await _apiClient.dio.patch(
      '/progress/plan/$planId',
      data: {'plan_description': planDescription},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected update response');
  }

  Future<Map<String, dynamic>> submitCheckin({
    required int planId,
    required String workDateIso, // YYYY-MM-DD
    String? notes,
  }) async {
    // Backend currently accepts { workDate }, but we keep notes ready for future extension.
    final res = await _apiClient.dio.post(
      '/progress/plan/$planId/days',
      data: {
        'workDate': workDateIso,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected check-in response');
  }

  Future<void> deleteCheckin({
    required int planId,
    required String workDateIso, // YYYY-MM-DD
  }) async {
    await _apiClient.dio.delete('/progress/plan/$planId/days/$workDateIso');
  }
}

