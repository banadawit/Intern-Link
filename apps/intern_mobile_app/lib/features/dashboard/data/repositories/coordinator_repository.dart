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
      totalStudents: (json['students']?['total'] as num?)?.toInt() ?? 0,
      totalCompanies: (json['companies']?['total'] as num?)?.toInt() ?? 
                       (json['totalCompanies'] as num?)?.toInt() ?? 0,
      activePlacements: (json['activeAssignments'] as num?)?.toInt() ?? 0,
      pendingProposals: (json['proposalsPending'] as num?)?.toInt() ?? 0,
      universityName: json['universityName'] ?? 'Your University',
    );
  }
}

class CoordinatorRepository {
  CoordinatorRepository({required this.apiClient});
  final ApiClient apiClient;

  dynamic _extractData(dynamic data) {
    if (data == null) return null;
    if (data is List) return data;
    if (data is Map) {
      if (data.containsKey('success')) {
        final success = data['success'];
        if (success == true || success == 'true' || success == 1) {
          return data['data'];
        }
        return null;
      }
      return data;
    }
    return data;
  }

  Future<CoordinatorStats> getStats() async {
    final response = await apiClient.dio.get('/coordinator-portal/dashboard-stats');
    final data = _extractData(response.data);
    if (data != null && data is Map) {
      return CoordinatorStats.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch stats');
  }

  Future<List<dynamic>> getCompanies() async {
    final response = await apiClient.dio.get('/coordinator-portal/companies');
    return (_extractData(response.data) as List?) ?? [];
  }

  Future<List<dynamic>> getPendingHods() async {
    final response = await apiClient.dio.get('/coordinator/pending-hods');
    return (_extractData(response.data) as List?) ?? [];
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
