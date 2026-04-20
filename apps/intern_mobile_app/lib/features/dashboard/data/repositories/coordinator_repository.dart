import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class CoordinatorStats {
  final int totalStudents;
  final int totalCompanies;
  final int activePlacements;
  final int pendingProposals;
  final String universityName;

  CoordinatorStats({
    required this.totalStudents,
    required this.totalCompanies,
    required this.activePlacements,
    required this.pendingProposals,
    required this.universityName,
  });

  factory CoordinatorStats.fromJson(Map<String, dynamic> json) {
    return CoordinatorStats(
      totalStudents: json['totalStudents'] ?? 0,
      totalCompanies: json['totalCompanies'] ?? 0,
      activePlacements: json['activePlacements'] ?? 0,
      pendingProposals: json['pendingProposals'] ?? 0,
      universityName: json['universityName'] ?? 'Your University',
    );
  }
}

class CoordinatorRepository {
  CoordinatorRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<CoordinatorStats> getStats() async {
    final response = await apiClient.dio.get('/coordinator-portal/dashboard-stats');
    if (response.data['success'] == true) {
      return CoordinatorStats.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to fetch stats');
  }

  Future<List<dynamic>> getCompanies() async {
    final response = await apiClient.dio.get('/coordinator-portal/companies');
    if (response.data['success'] == true) {
      return response.data['data'];
    }
    return [];
  }

  Future<List<dynamic>> getPendingHods() async {
    final response = await apiClient.dio.get('/coordinator/pending-hods');
    if (response.data['success'] == true) {
      return response.data['data'];
    }
    return [];
  }

  Future<void> verifyHod(int userId, String status, {String? reason}) async {
    await apiClient.dio.patch('/coordinator/verify-hod', data: {
      'userId': userId,
      'status': status,
      'rejectionReason': reason,
    });
  }
}

final coordinatorRepositoryProvider = Provider<CoordinatorRepository>((ref) {
  return CoordinatorRepository(apiClient: ref.watch(apiClientProvider));
});

final coordinatorStatsProvider = FutureProvider<CoordinatorStats>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getStats();
});

final pendingHodsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(coordinatorRepositoryProvider).getPendingHods();
});
