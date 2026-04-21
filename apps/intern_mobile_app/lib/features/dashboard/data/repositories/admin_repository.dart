import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class AdminStats {
  final int totalUsers;
  final int totalUniversities;
  final int totalCompanies;
  final int pendingApprovals;

  AdminStats({
    required this.totalUsers,
    required this.totalUniversities,
    required this.totalCompanies,
    required this.pendingApprovals,
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
    );
  }
}

class AdminRepository {
  AdminRepository({required this.apiClient});
  final ApiClient apiClient;

  bool _isSuccess(dynamic data) {
    if (data == null) return false;
    final success = data['success'];
    return success == true || success == 'true' || success == 1;
  }

  Future<AdminStats> getStats() async {
    final response = await apiClient.dio.get('/admin/stats');
    final data = response.data;
    if (_isSuccess(data)) {
      return AdminStats.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to fetch admin stats');
  }

  Future<List<dynamic>> getPendingUniversities() async {
    final response = await apiClient.dio.get('/admin/pending-universities');
    final data = response.data;
    if (_isSuccess(data)) {
      return data['data'] ?? [];
    }
    return [];
  }

  Future<List<dynamic>> getPendingCompanies() async {
    final response = await apiClient.dio.get('/admin/pending-companies');
    final data = response.data;
    if (_isSuccess(data)) {
      return data['data'] ?? [];
    }
    return [];
  }

  Future<void> updateUniversityStatus(int id, String status, {String? reason}) async {
    await apiClient.dio.patch('/admin/university-status/$id', data: {
      'status': status,
      'rejection_reason': reason,
    });
  }

  Future<void> updateCompanyStatus(int id, String status, {String? reason}) async {
    await apiClient.dio.patch('/admin/company-status/$id', data: {
      'status': status,
      'rejection_reason': reason,
    });
  }

  Future<List<dynamic>> getPendingCoordinators() async {
    final response = await apiClient.dio.get('/admin/pending-coordinators');
    final data = response.data;
    if (_isSuccess(data)) return data['data'] ?? [];
    return [];
  }

  Future<void> approveCoordinator(String userId) async {
    await apiClient.dio.post('/admin/coordinators/$userId/approve');
  }

  Future<void> rejectCoordinator(String userId) async {
    await apiClient.dio.post('/admin/coordinators/$userId/reject');
  }

  Future<List<dynamic>> getPendingSupervisors() async {
    final response = await apiClient.dio.get('/admin/pending-supervisors');
    final data = response.data;
    if (_isSuccess(data)) return data['data'] ?? [];
    return [];
  }

  Future<void> approveSupervisor(String userId) async {
    await apiClient.dio.post('/admin/supervisors/$userId/approve');
  }

  Future<void> rejectSupervisor(String userId) async {
    await apiClient.dio.post('/admin/supervisors/$userId/reject');
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await apiClient.dio.get('/admin/users');
    final data = response.data;
    if (_isSuccess(data)) return data['data'] ?? [];
    return [];
  }

  Future<List<dynamic>> getAuditLogs() async {
    final response = await apiClient.dio.get('/admin/audit-logs');
    final data = response.data;
    if (_isSuccess(data)) return data['data'] ?? [];
    return [];
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
