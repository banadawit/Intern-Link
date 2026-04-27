import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class CoordinatorStats {
  final int totalStudents;
  final int totalCompanies;
  final int activePlacements;
  final int pendingProposals;
  final int totalHods;
  final int pendingHods;
  final int reportsCount;
  final String universityName;

  CoordinatorStats({
    required this.totalStudents,
    required this.totalCompanies,
    required this.activePlacements,
    required this.pendingProposals,
    required this.totalHods,
    required this.pendingHods,
    required this.reportsCount,
    required this.universityName,
  });

  factory CoordinatorStats.fromJson(Map<String, dynamic> json) {
    return CoordinatorStats(
      totalStudents: (json['students']?['total'] as num?)?.toInt() ?? 0,
      totalCompanies: (json['totalCompanies'] as num?)?.toInt() ?? 0,
      activePlacements: (json['activeAssignments'] as num?)?.toInt() ?? 0,
      pendingProposals: (json['proposalsPending'] as num?)?.toInt() ?? 0,
      totalHods: (json['hods']?['total'] as num?)?.toInt() ?? 0,
      pendingHods: (json['hods']?['pending'] as num?)?.toInt() ?? 0,
      reportsCount: (json['reportsCount'] as num?)?.toInt() ?? 0,
      universityName: json['universityName'] as String? ?? 'Your University',
    );
  }
}

// ─── Repository ───────────────────────────────────────────────────────────────

class CoordinatorRepository {
  CoordinatorRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<CoordinatorStats> getStats() async {
    final res = await apiClient.dio.get('/coordinator-portal/dashboard-stats');
    final data = res.data;
    if (data is Map<String, dynamic>) return CoordinatorStats.fromJson(data);
    throw Exception('Failed to fetch coordinator stats');
  }

  Future<List<dynamic>> getCompanies() async {
    final res = await apiClient.dio.get('/coordinator-portal/companies');
    final data = res.data;
    return data is List ? data : [];
  }

  Future<List<dynamic>> getPendingHods() async {
    final res = await apiClient.dio.get('/coordinator/pending-hods');
    final data = res.data;
    return data is List ? data : [];
  }

  Future<List<dynamic>> getApprovedHods() async {
    final res = await apiClient.dio.get('/coordinator/approved-hods');
    final data = res.data;
    return data is List ? data : [];
  }

  Future<List<dynamic>> getRejectedHods() async {
    final res = await apiClient.dio.get('/coordinator/rejected-hods');
    final data = res.data;
    return data is List ? data : [];
  }

  Future<void> verifyHod(int userId, String status, {String? reason}) async {
    await apiClient.dio.patch('/coordinator/verify-hod', data: {
      'userId': userId,
      'status': status,
      if (reason != null) 'reason': reason,
    });
  }

  Future<List<dynamic>> getProposals() async {
    final res = await apiClient.dio.get('/coordinator-portal/proposals/overview');
    final data = res.data;
    return data is List ? data : [];
  }

  Future<List<dynamic>> getAssignments() async {
    final res = await apiClient.dio.get('/coordinator-portal/assignments/overview');
    final data = res.data;
    return data is List ? data : [];
  }

  Future<List<dynamic>> getReports() async {
    final res = await apiClient.dio.get('/coordinator-portal/reports/overview');
    final data = res.data;
    return data is List ? data : [];
  }

  Future<List<dynamic>> getStudents() async {
    final res = await apiClient.dio.get('/coordinator-portal/students');
    final data = res.data;
    return data is List ? data : [];
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final coordinatorRepositoryProvider = Provider<CoordinatorRepository>((ref) {
  return CoordinatorRepository(apiClient: ref.watch(apiClientProvider));
});

final coordinatorStatsProvider = FutureProvider<CoordinatorStats>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getStats();
});

final pendingHodsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getPendingHods();
});

final approvedHodsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getApprovedHods();
});

final rejectedHodsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getRejectedHods();
});

final coordinatorProposalsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getProposals();
});

final coordinatorAssignmentsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getAssignments();
});

final coordinatorReportsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getReports();
});

final coordinatorCompaniesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getCompanies();
});

final coordinatorStudentsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getStudents();
});
