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
    await apiClient.dio.patch('/admin/university-status/$id', data: {'status': status});
  }

  Future<void> updateCompanyStatus(int id, String status) async {
    await apiClient.dio.patch('/admin/company-status/$id', data: {'status': status});
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
  Future<List<dynamic>> getAllUniversities({String? status}) async {
    final response = await apiClient.dio.get('/admin/universities', queryParameters: status != null ? {'status': status} : null);
    return (response.data as List?) ?? [];
  }

  Future<List<dynamic>> getAllCompanies({String? status}) async {
    final response = await apiClient.dio.get('/admin/companies', queryParameters: status != null ? {'status': status} : null);
    return (response.data as List?) ?? [];
  }

  // --- SYSTEM CONFIGURATION ---

  Future<Map<String, String>> getConfig() async {
    final response = await apiClient.dio.get('/admin/config');
    final data = response.data['data'] as Map?;
    return data?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {};
  }

  Future<void> updateConfig(Map<String, String> updates) async {
    await apiClient.dio.patch('/admin/config', data: updates);
  }

  Future<bool> testSmtp() async {
    final response = await apiClient.dio.post('/admin/config/test-smtp');
    return response.data['success'] == true;
  }

  Future<void> broadcast(String title, String content) async {
    await apiClient.dio.post('/admin/config/broadcast', data: {
      'title': title,
      'content': content,
    });
  }

  Future<String> exportAuditLogsCsv() async {
    final response = await apiClient.dio.get('/admin/config/export-audit-csv');
    return response.data.toString();
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

final allUniversitiesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUniversities();
});

final allCompaniesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllCompanies();
});

final verifiedUniversitiesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUniversities(status: 'APPROVED');
});

final verifiedCompaniesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllCompanies(status: 'APPROVED');
});

final systemConfigProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.watch(adminRepositoryProvider).getConfig();
});
