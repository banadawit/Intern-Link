import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class HodStats {
  final int totalStudents;
  final int pendingApprovals;
  final int placedStudents;
  final int totalReports;

  HodStats({
    required this.totalStudents,
    required this.pendingApprovals,
    required this.placedStudents,
    required this.totalReports,
  });

  factory HodStats.fromJson(Map<String, dynamic> json) {
    // Backend returns flat fields: totalStudents, pendingApprovals, placedStudents, reports (int)
    return HodStats(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      pendingApprovals: (json['pendingApprovals'] as num?)?.toInt() ?? 0,
      placedStudents: (json['placedStudents'] as num?)?.toInt() ?? 0,
      totalReports: (json['reports'] as num?)?.toInt() ?? 0,
    );
  }
}

class HodRepository {
  final ApiClient apiClient;

  HodRepository({required this.apiClient});

  Future<HodStats> getStats() async {
    final response = await apiClient.dio.get('/hod/dashboard-stats');
    return HodStats.fromJson(response.data['data'] ?? response.data);
  }

  Future<List<dynamic>> getStudents() async {
    final response = await apiClient.dio.get('/hod/students');
    return (response.data['data'] as List?) ?? (response.data as List?) ?? [];
  }

  Future<List<dynamic>> getReports() async {
    final response = await apiClient.dio.get('/hod/reports');
    return (response.data['data'] as List?) ?? (response.data as List?) ?? [];
  }
}

final hodRepositoryProvider = Provider<HodRepository>((ref) {
  return HodRepository(apiClient: ref.watch(apiClientProvider));
});

final hodStatsProvider = FutureProvider<HodStats>((ref) {
  return ref.watch(hodRepositoryProvider).getStats();
});

final hodStudentsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(hodRepositoryProvider).getStudents();
});

final hodReportsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(hodRepositoryProvider).getReports();
});
