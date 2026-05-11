import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

import '../../../plans/domain/entities/weekly_plan.dart';
import '../../../plans/domain/entities/plan_enums.dart';
import '../../../plans/data/models/plans_dtos.dart';

// ---------------------------------------------------------
// REPOSITORY
// ---------------------------------------------------------

class ProgressRepository {
  ProgressRepository(this._apiClient);
  final ApiClient _apiClient;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<WeeklyPlan>> getMyWeeklyPlans() async {
    final response = await _apiClient.dio.get('/progress/my-plans');
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? raw) : raw;
    if (list is! List) return [];
    return list
        .map((e) => PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Submit new plan (with optional file attachments) ──────────────────────

  Future<WeeklyPlan> submitWeeklyPlan(
    int weekNumber,
    String description, {
    List<String>? filePaths,       // local file paths (mobile)
    List<List<int>>? fileBytes,    // raw bytes (web)
    List<String>? fileNames,
    List<String>? fileMimeTypes,
  }) async {
    final formData = FormData.fromMap({
      'week_number': weekNumber.toString(),
      'plan_description': description,
    });

    // Attach files if provided
    if (fileBytes != null && fileNames != null) {
      for (int i = 0; i < fileBytes.length; i++) {
        formData.files.add(MapEntry(
          'attachments',
          MultipartFile.fromBytes(
            fileBytes[i],
            filename: fileNames[i],
            contentType: _mimeType(fileMimeTypes?[i] ?? fileNames[i]),
          ),
        ));
      }
    }

    final response = await _apiClient.dio.post(
      '/progress/submit',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final raw = response.data;
    final planData = raw is Map ? (raw['data']?['plan'] ?? raw['plan'] ?? raw) : raw;
    return PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(planData as Map));
  }

  // ── Resubmit a REJECTED plan ──────────────────────────────────────────────

  Future<WeeklyPlan> resubmitWeeklyPlan(
    int planId,
    String description, {
    List<List<int>>? fileBytes,
    List<String>? fileNames,
    List<String>? fileMimeTypes,
  }) async {
    final formData = FormData.fromMap({
      'plan_description': description,
    });

    if (fileBytes != null && fileNames != null) {
      for (int i = 0; i < fileBytes.length; i++) {
        formData.files.add(MapEntry(
          'attachments',
          MultipartFile.fromBytes(
            fileBytes[i],
            filename: fileNames[i],
            contentType: _mimeType(fileMimeTypes?[i] ?? fileNames[i]),
          ),
        ));
      }
    }

    final response = await _apiClient.dio.post(
      '/progress/plan/$planId/resubmit',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final raw = response.data;
    final planData = raw is Map ? (raw['data']?['plan'] ?? raw['plan'] ?? raw) : raw;
    return PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(planData as Map));
  }

  // ── Update PENDING/REJECTED plan ─────────────────────────────────────────

  Future<WeeklyPlan> updateWeeklyPlan(
    int planId,
    String description, {
    List<List<int>>? fileBytes,
    List<String>? fileNames,
    List<String>? fileMimeTypes,
  }) async {
    final formData = FormData.fromMap({'plan_description': description});

    if (fileBytes != null && fileNames != null) {
      for (int i = 0; i < fileBytes.length; i++) {
        formData.files.add(MapEntry(
          'attachments',
          MultipartFile.fromBytes(
            fileBytes[i],
            filename: fileNames[i],
            contentType: _mimeType(fileMimeTypes?[i] ?? fileNames[i]),
          ),
        ));
      }
    }

    final response = await _apiClient.dio.patch(
      '/progress/plan/$planId',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final raw = response.data;
    final planData = raw is Map ? (raw['data']?['plan'] ?? raw['plan'] ?? raw) : raw;
    return PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(planData as Map));
  }

  // ── Remove a single attachment ────────────────────────────────────────────

  Future<void> removePlanAttachment(int planId, String attachmentUrl) async {
    await _apiClient.dio.delete(
      '/progress/plan/$planId/attachment',
      data: {'attachmentUrl': attachmentUrl},
    );
  }

  // ── Upload files standalone (returns attachment metadata) ─────────────────

  Future<List<PlanAttachment>> uploadAttachments(
    List<List<int>> fileBytes,
    List<String> fileNames, {
    List<String>? mimeTypes,
  }) async {
    final formData = FormData();
    for (int i = 0; i < fileBytes.length; i++) {
      formData.files.add(MapEntry(
        'attachments',
        MultipartFile.fromBytes(
          fileBytes[i],
          filename: fileNames[i],
          contentType: _mimeType(mimeTypes?[i] ?? fileNames[i]),
        ),
      ));
    }

    final response = await _apiClient.dio.post(
      '/upload/plan-attachment',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final raw = response.data;
    final list = raw is Map ? (raw['data'] ?? []) : raw;
    if (list is! List) return [];
    return list
        .map((e) => PlanAttachment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ── Daily check-ins ───────────────────────────────────────────────────────

  Future<void> submitPlanDay(int planId, String workDate) async {
    await _apiClient.dio.post(
      '/progress/plan/$planId/days',
      data: {'workDate': workDate},
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DioMediaType _mimeType(String fileNameOrMime) {
    if (fileNameOrMime.contains('/')) {
      final parts = fileNameOrMime.split('/');
      return DioMediaType(parts[0], parts[1]);
    }
    final ext = fileNameOrMime.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'  => DioMediaType('application', 'pdf'),
      'ppt'  => DioMediaType('application', 'vnd.ms-powerpoint'),
      'pptx' => DioMediaType('application', 'vnd.openxmlformats-officedocument.presentationml.presentation'),
      'doc'  => DioMediaType('application', 'msword'),
      'docx' => DioMediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
      'jpg' || 'jpeg' => DioMediaType('image', 'jpeg'),
      'png'  => DioMediaType('image', 'png'),
      _      => DioMediaType('application', 'octet-stream'),
    };
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
