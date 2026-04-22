import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class AdminStats {
  final int totalUsers;
  final int totalUniversities;
   final int totalCompanies;
  final int pendingApprovals;
  final int totalEvaluations;
  final int totalReports;

  AdminStats({
    required this.totalUsers,
    required this.totalUniversities,
    required this.totalCompanies,
    required this.pendingApprovals,
    required this.totalEvaluations,
    required this.totalReports,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AdminStats(
      totalUsers: toInt(json['totalUsers']),
      totalUniversities: toInt(json['totalUniversities']),
      totalCompanies: toInt(json['totalCompanies']),
      pendingApprovals: toInt(json['pendingApprovals']),
      totalEvaluations: toInt(json['totalEvaluations']),
      totalReports: toInt(json['totalReports']),
    );
  }
}

class AdminRepository {
  AdminRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<AdminStats> getStats() async {
    final response = await apiClient.dio.get('/admin/stats');
    final data = response.data;
    if (data != null && data is Map) {
      return AdminStats(
        totalUsers: (data['totalUsers'] as num?)?.toInt() ?? 0,
        totalUniversities: ((data['approvedUniversities'] as num?)?.toInt() ?? 0) + ((data['pendingUniversities'] as num?)?.toInt() ?? 0),
        totalCompanies: ((data['approvedCompanies'] as num?)?.toInt() ?? 0) + ((data['pendingCompanies'] as num?)?.toInt() ?? 0),
        pendingApprovals: ((data['pendingUniversities'] as num?)?.toInt() ?? 0) + 
                         ((data['pendingCompanies'] as num?)?.toInt() ?? 0) + 
                         ((data['pendingCoordinators'] as num?)?.toInt() ?? 0) + 
                         ((data['pendingSupervisors'] as num?)?.toInt() ?? 0),
        totalEvaluations: (data['totalEvaluations'] as num?)?.toInt() ?? 0,
        totalReports: (data['totalReports'] as num?)?.toInt() ?? 0,
      );
    }
    throw Exception('Failed to fetch admin stats');
  }

  Future<List<dynamic>> getPendingUniversities() async {
    final response = await apiClient.dio.get('/admin/pending-universities');
    return (response.data as List?) ?? [];
  }

  Future<List<dynamic>> getPendingCompanies() async {
    final response = await apiClient.dio.get('/admin/pending-companies');
    return (response.data as List?) ?? [];
  }

  Future<List<dynamic>> getPendingCoordinators() async {
    final response = await apiClient.dio.get('/admin/pending-coordinators');
    return (response.data as List?) ?? [];
  }

  Future<List<dynamic>> getPendingSupervisors() async {
    final response = await apiClient.dio.get('/admin/pending-supervisors');
    return (response.data as List?) ?? [];
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await apiClient.dio.get('/admin/users');
    return (response.data as List?) ?? [];
  }

  Future<List<dynamic>> getAuditLogs() async {
    final response = await apiClient.dio.get('/admin/audit-logs');
    return (response.data as List?) ?? [];
  }

  Future<void> updateUniversityStatus(int id, String status) async {
    await apiClient.dio.patch('/admin/universities/$id/status', data: {'status': status});
  }

  Future<void> updateCompanyStatus(int id, String status) async {
    await apiClient.dio.patch('/admin/companies/$id/status', data: {'status': status});
  }

  Future<void> approveCoordinator(int userId) async {
    await apiClient.dio.post('/admin/coordinators/$userId/approve');
  }

  Future<void> rejectCoordinator(int userId) async {
    await apiClient.dio.post('/admin/coordinators/$userId/reject');
  }

  Future<void> approveSupervisor(int userId) async {
    await apiClient.dio.post('/admin/supervisors/$userId/approve');
  }

  Future<void> rejectSupervisor(int userId) async {
    await apiClient.dio.post('/admin/supervisors/$userId/reject');
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(apiClient: ref.watch(apiClientProvider));
});

final adminStatsProvider = FutureProvider<AdminStats>((ref) {
  return ref.watch(adminRepositoryProvider).getStats();
});

final pendingUniversitiesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingUniversities();
});

final pendingCompaniesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingCompanies();
});

final pendingCoordinatorsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingCoordinators();
});

final pendingSupervisorsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingSupervisors();
});

final allUsersProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

final auditLogsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAuditLogs();
});
