import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/supervisor_entities.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../../plans/domain/entities/weekly_plan.dart';

final supervisorIncomingProposalsProvider =
    FutureProvider<List<InternshipProposal>>((ref) async {
      return ref.watch(supervisorRepositoryProvider).getProposals();
    });

final supervisorStatsProvider = FutureProvider<SupervisorStats>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getStats();
});

final supervisorDashboardProvider = FutureProvider<SupervisorDashboardData>((
  ref,
) async {
  return ref.watch(supervisorRepositoryProvider).getDashboard();
});

final supervisorPerformanceProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return ref.watch(supervisorRepositoryProvider).getPerformance();
});

final supervisorStudentsProvider = FutureProvider<List<SupervisorStudent>>((
  ref,
) async {
  return ref.watch(supervisorRepositoryProvider).getStudents();
});

final supervisorProposalsProvider = FutureProvider<List<InternshipProposal>>((
  ref,
) async {
  return ref.watch(supervisorRepositoryProvider).getProposals();
});

final supervisorPendingPlansProvider = FutureProvider<List<WeeklyPlan>>((
  ref,
) async {
  return ref.watch(supervisorRepositoryProvider).getPendingPlans();
});

final supervisorWeeklyReportsProvider =
    FutureProvider<List<SupervisorAttendanceReport>>((ref) async {
      return ref.watch(supervisorRepositoryProvider).getWeeklyReports();
    });

final supervisorAttendanceHeatmapProvider = FutureProvider<AttendanceHeatmap>((
  ref,
) async {
  return ref.watch(supervisorRepositoryProvider).getAttendanceHeatmap();
});

final supervisorTeamsProvider = FutureProvider<List<SupervisorTeam>>((
  ref,
) async {
  return ref.watch(supervisorRepositoryProvider).getTeams();
});

final supervisorProjectsProvider = FutureProvider<List<SupervisorProject>>((
  ref,
) async {
  return ref.watch(supervisorRepositoryProvider).getProjects();
});

final supervisorAssignmentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      return ref.watch(supervisorRepositoryProvider).getAssignments();
    });

final supervisorMeProvider = FutureProvider<SupervisorMe>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getMe();
});

// Controllers for actions

class SupervisorActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> respondToProposal(int id, bool approve, {String? reason}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(supervisorRepositoryProvider)
          .respondToProposal(id, approve: approve, reason: reason);
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
      await ref
          .read(supervisorRepositoryProvider)
          .reviewPlan(id, approve: approve, feedback: feedback);
      ref.invalidate(supervisorPendingPlansProvider);
      ref.invalidate(supervisorStatsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> submitEvaluation(
    int studentId,
    double technicalSkills,
    double problemSolving,
    double communication,
    double teamCollaboration,
    double timeManagement,
    double adaptability,
    double professionalism,
    double initiativeCreativity,
    double attendancePunctuality,
    double taskCompletionQuality,
    String comments,
  ) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(supervisorRepositoryProvider)
          .submitEvaluation(
            studentId: studentId,
            technicalSkills: technicalSkills,
            problemSolving: problemSolving,
            communication: communication,
            teamCollaboration: teamCollaboration,
            timeManagement: timeManagement,
            adaptability: adaptability,
            professionalism: professionalism,
            initiativeCreativity: initiativeCreativity,
            attendancePunctuality: attendancePunctuality,
            taskCompletionQuality: taskCompletionQuality,
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

final supervisorActionsProvider =
    NotifierProvider<SupervisorActionsNotifier, AsyncValue<void>>(
      SupervisorActionsNotifier.new,
    );
