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
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalUniversities: json['totalUniversities'] ?? 0,
      totalCompanies: json['totalCompanies'] ?? 0,
      pendingApprovals: json['pendingApprovals'] ?? 0,
    );
  }
}

class AdminRepository {
  AdminRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<AdminStats> getStats() async {
    final response = await apiClient.dio.get('/admin/stats');
    if (response.data['success'] == true) {
      return AdminStats.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch admin stats');
  }

  Future<List<dynamic>> getPendingUniversities() async {
    final response = await apiClient.dio.get('/admin/pending-universities');
    if (response.data['success'] == true) {
      return response.data['data'];
    }
    return [];
  }

  Future<List<dynamic>> getPendingCompanies() async {
    final response = await apiClient.dio.get('/admin/pending-companies');
    if (response.data['success'] == true) {
      return response.data['data'];
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
