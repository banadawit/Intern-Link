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
  final List<Map<String, dynamic>> recentNotifications;

  CoordinatorStats({
    required this.totalStudents,
    required this.totalCompanies,
    required this.activePlacements,
    required this.pendingProposals,
    required this.totalHods,
    required this.pendingHods,
    required this.reportsCount,
    required this.universityName,
    this.recentNotifications = const [],
  });

  factory CoordinatorStats.fromJson(Map<String, dynamic> json) {
    int si(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    final rawNotifs = json['recentNotifications'];
    final notifs = rawNotifs is List
        ? rawNotifs.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    return CoordinatorStats(
      totalStudents: si(json['students']?['total']),
      totalCompanies: si(json['totalCompanies']),
      activePlacements: si(json['activeAssignments']),
      pendingProposals: si(json['proposalsPending']),
      totalHods: si(json['hods']?['total']),
      pendingHods: si(json['hods']?['pending']),
      reportsCount: si(json['reportsCount']),
      universityName: json['universityName']?.toString() ?? 'Your University',
      recentNotifications: notifs,
    );
  }
}

// ─── Repository ───────────────────────────────────────────────────────────────

dynamic _deepConvert(dynamic v) {
  if (v is Map) return Map<String, dynamic>.fromEntries(
    v.entries.map((e) => MapEntry(e.key.toString(), _deepConvert(e.value))),
  );
  if (v is List) return v.map(_deepConvert).toList();
  return v;
}

List<dynamic> _deepList(dynamic data) {
  final raw = data is Map ? (data['data'] ?? data) : data;
  if (raw is List) return raw.map(_deepConvert).toList();
  return [];
}

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
    return _deepList(res.data);
  }

  Future<List<dynamic>> getPendingHods() async {
    final res = await apiClient.dio.get('/coordinator/pending-hods');
    return _deepList(res.data);
  }

  Future<List<dynamic>> getApprovedHods() async {
    final res = await apiClient.dio.get('/coordinator/approved-hods');
    return _deepList(res.data);
  }

  Future<List<dynamic>> getRejectedHods() async {
    final res = await apiClient.dio.get('/coordinator/rejected-hods');
    return _deepList(res.data);
  }

  Future<List<dynamic>> getSuspendedHods() async {
    final res = await apiClient.dio.get('/coordinator/suspended-hods');
    return _deepList(res.data);
  }

  Future<List<dynamic>> getAllHods() async {
    final res = await apiClient.dio.get('/coordinator/all-hods');
    return _deepList(res.data);
  }

  Future<void> verifyHod(int userId, String status, {String? reason}) async {
    await apiClient.dio.patch('/coordinator/verify-hod', data: {
      'userId': userId,
      'status': status,
      if (reason != null) 'reason': reason,
    });
  }

  Future<Map<String, dynamic>> createHod({
    required String fullName,
    required String email,
    required String department,
    String? employeeId,
  }) async {
    final res = await apiClient.dio.post('/coordinator/hods', data: {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'department': department.trim(),
      if (employeeId != null && employeeId.trim().isNotEmpty) 'employeeId': employeeId.trim(),
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getProposals() async {
    final res = await apiClient.dio.get('/coordinator-portal/proposals/overview');
    return _deepList(res.data);
  }

  Future<List<dynamic>> getAssignments() async {
    final res = await apiClient.dio.get('/coordinator-portal/assignments/overview');
    return _deepList(res.data);
  }

  Future<List<dynamic>> getReports() async {
    final res = await apiClient.dio.get('/coordinator-portal/reports/overview');
    return _deepList(res.data);
  }

  Future<List<dynamic>> getStudents() async {
    final res = await apiClient.dio.get('/coordinator-portal/students');
    return _deepList(res.data);
  }

  Future<void> suspendHod(int userId) async {
    await apiClient.dio.patch('/coordinator/hods/$userId/suspend');
  }

  Future<void> activateHod(int userId) async {
    await apiClient.dio.patch('/coordinator/hods/$userId/activate');
  }

  Future<Map<String, dynamic>> getHodDetail(int userId) async {
    final res = await apiClient.dio.get('/coordinator/hods/$userId');
    return res.data as Map<String, dynamic>;
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

final suspendedHodsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getSuspendedHods();
});

final allHodsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getAllHods();
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

final hodDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, userId) {
  return ref.watch(coordinatorRepositoryProvider).getHodDetail(userId);
});
