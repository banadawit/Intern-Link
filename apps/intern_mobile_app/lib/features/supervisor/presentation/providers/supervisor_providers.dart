import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/supervisor_entities.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../../plans/domain/entities/weekly_plan.dart';

final supervisorStatsProvider = FutureProvider<SupervisorStats>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getStats();
});

final supervisorStudentsProvider = FutureProvider<List<SupervisorStudent>>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getStudents();
});

final supervisorProposalsProvider = FutureProvider<List<InternshipProposal>>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getProposals();
});

final supervisorPendingPlansProvider = FutureProvider<List<WeeklyPlan>>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getPendingPlans();
});

final supervisorTeamsProvider = FutureProvider<List<SupervisorTeam>>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getTeams();
});

// Controllers for actions

class SupervisorActionsNotifier extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> respondToProposal(int id, bool approve, {String? reason}) async {
    state = const AsyncLoading();
    try {
      await ref.read(supervisorRepositoryProvider).respondToProposal(id, approve: approve, reason: reason);
      ref.invalidate(supervisorProposalsProvider);
      ref.invalidate(supervisorStatsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reviewPlan(int id, bool approve, {String? feedback}) async {
    state = const AsyncLoading();
    try {
      await ref.read(supervisorRepositoryProvider).reviewPlan(id, approve: approve, feedback: feedback);
      ref.invalidate(supervisorPendingPlansProvider);
      ref.invalidate(supervisorStatsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> submitEvaluation(int studentId, double technical, double soft, String comments) async {
    state = const AsyncLoading();
    try {
      await ref.read(supervisorRepositoryProvider).submitEvaluation(
        studentId: studentId,
        technicalScore: technical,
        softSkillScore: soft,
        comments: comments,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> createTeam(String name) async {
    state = const AsyncLoading();
    try {
      await ref.read(supervisorRepositoryProvider).createTeam(name);
      ref.invalidate(supervisorTeamsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final supervisorActionsProvider = NotifierProvider.autoDispose<SupervisorActionsNotifier, AsyncValue<void>>(
  SupervisorActionsNotifier.new,
);
