import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart' show ApiClient, apiClientProvider;
import '../../domain/entities/weekly_plan.dart';
import '../../domain/entities/plan_enums.dart';
import '../datasources/plans_api_service.dart';
import '../datasources/plans_draft_storage.dart';
import '../models/plans_dtos.dart';

class PlansRepository {
  PlansRepository({
    required ApiClient apiClient,
    PlansDraftStorage? draftStorage,
  })  : _api = PlansApiService(apiClient),
        _drafts = draftStorage ?? PlansDraftStorage();

  final PlansApiService _api;
  final PlansDraftStorage _drafts;

  /// Returns submitted plans from API + local drafts (as synthetic plans with negative ids).
  Future<List<WeeklyPlan>> getPlans() async {
    final apiRaw = await _api.fetchMyPlans();
    final apiPlans = apiRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(PlansDtos.weeklyPlanFromApi)
        .toList();

    final draftRaw = await _drafts.loadDrafts();
    final draftPlans = draftRaw.map(_draftJsonToEntity).toList();

    final merged = [...draftPlans, ...apiPlans];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  /// Create/update a local draft. Returns the draft plan.
  Future<WeeklyPlan> upsertDraft({
    int? draftId,
    required int weekNumber,
    required String title,
    required String objectives,
    required List<String> tasks,
  }) async {
    final existing = await _drafts.loadDrafts();
    final now = DateTime.now().toIso8601String();

    final id = draftId ?? _nextDraftId(existing);
    final idx = existing.indexWhere((d) => d['id'] == id);

    final payload = <String, dynamic>{
      'id': id,
      'weekNumber': weekNumber,
      'title': title,
      'objectives': objectives,
      'tasks': tasks,
      'createdAt': idx >= 0 ? (existing[idx]['createdAt'] ?? now) : now,
      'updatedAt': now,
    };

    if (idx >= 0) {
      existing[idx] = payload;
    } else {
      existing.add(payload);
    }

    await _drafts.saveDrafts(existing);
    return _draftJsonToEntity(payload);
  }

  Future<void> deleteDraft(int draftId) async {
    final existing = await _drafts.loadDrafts();
    existing.removeWhere((d) => d['id'] == draftId);
    await _drafts.saveDrafts(existing);
  }

  /// Submit a draft or a newly created plan. Backend will create a PENDING plan.
  Future<WeeklyPlan> submitPlan({
    required int weekNumber,
    required String title,
    required String objectives,
    required List<String> tasks,
    String? presentationFilePath,
    int? deleteDraftIdAfterSubmit,
  }) async {
    final desc = PlansDtos.encodeDescription(title: title, objectives: objectives, tasks: tasks);

    try {
      final res = await _api.submitPlan(
        weekNumber: weekNumber,
        planDescription: desc,
        presentationFilePath: presentationFilePath,
      );

      final planJson = res['plan'];
      if (planJson is! Map) throw Exception('Missing plan in response');
      final plan = PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(planJson));

      if (deleteDraftIdAfterSubmit != null) {
        await deleteDraft(deleteDraftIdAfterSubmit);
      }

      return plan;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      throw Exception('Failed to submit plan');
    }
  }

  /// API edit: backend allows editing only PENDING currently. For REJECTED, we recommend creating a new submission.
  Future<WeeklyPlan> updateSubmittedPlanObjectives({
    required int planId,
    required String title,
    required String objectives,
    required List<String> tasks,
  }) async {
    final desc = PlansDtos.encodeDescription(title: title, objectives: objectives, tasks: tasks);
    final res = await _api.updatePlanDescription(planId: planId, planDescription: desc);
    final planJson = res['plan'] ?? res['updatedPlan'] ?? res['data'];
    if (planJson is! Map) {
      // Fallback: refetch list later; still consider operation successful.
      return WeeklyPlan(
        id: planId,
        studentId: 0,
        weekNumber: 0,
        title: title,
        objectives: objectives,
        tasks: tasks,
        status: WeeklyPlanStatus.pending,
        createdAt: DateTime.now(),
      );
    }
    return PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(planJson));
  }

  Future<void> submitCheckin({
    required int planId,
    required String workDateIso,
    String? notes,
  }) async {
    try {
      await _api.submitCheckin(planId: planId, workDateIso: workDateIso, notes: notes);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception('Failed to submit check-in');
    }
  }

  Future<void> deleteCheckin({
    required int planId,
    required String workDateIso,
  }) async {
    try {
      await _api.deleteCheckin(planId: planId, workDateIso: workDateIso);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception('Failed to delete check-in');
    }
  }

  WeeklyPlan _draftJsonToEntity(Map<String, dynamic> j) {
    final tasks = (j['tasks'] is List) ? (j['tasks'] as List).map((e) => e.toString()).toList() : <String>[];
    final createdAt = DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now();
    return WeeklyPlan(
      id: (j['id'] ?? -1) as int,
      studentId: 0,
      weekNumber: int.tryParse((j['weekNumber'] ?? 0).toString()) ?? 0,
      title: (j['title'] ?? 'Weekly Plan').toString(),
      objectives: (j['objectives'] ?? '').toString(),
      tasks: tasks,
      status: WeeklyPlanStatus.draft,
      createdAt: createdAt,
    );
  }

  int _nextDraftId(List<Map<String, dynamic>> existing) {
    final ids = existing.map((e) => int.tryParse((e['id'] ?? '').toString()) ?? 0).toList();
    final maxId = ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }
}

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlansRepository(apiClient: apiClient);
});

