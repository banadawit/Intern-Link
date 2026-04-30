import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class HodStats {
  final int totalStudents;
  final int pendingApprovals;
  final int approvedStudents;
  final int rejectedStudents;
  final int placedStudents;
  final int approvedNotPlaced;
  final int totalReports;
  final Map<String, int> proposals;
  final List<Map<String, dynamic>> recentPendingStudents;
  final String universityName;
  final String department;

  HodStats({
    required this.totalStudents,
    required this.pendingApprovals,
    required this.approvedStudents,
    required this.rejectedStudents,
    required this.placedStudents,
    required this.approvedNotPlaced,
    required this.totalReports,
    required this.proposals,
    required this.recentPendingStudents,
    required this.universityName,
    required this.department,
  });

  factory HodStats.fromJson(Map<String, dynamic> json) {
    final p = json['proposals'] as Map<String, dynamic>? ?? {};
    final uni = json['university'] as Map<String, dynamic>? ?? {};

    int _i(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return HodStats(
      totalStudents: _i(json['totalStudents']),
      pendingApprovals: _i(json['pendingApprovals']),
      approvedStudents: _i(json['approvedStudents']),
      rejectedStudents: _i(json['rejectedStudents']),
      placedStudents: _i(json['placedStudents']),
      approvedNotPlaced: _i(json['approvedNotPlaced']),
      totalReports: _i(json['reports']),
      proposals: {
        'pending': _i(p['pending']),
        'approved': _i(p['approved']),
        'rejected': _i(p['rejected']),
      },
      recentPendingStudents: List<Map<String, dynamic>>.from(
        (json['recentPendingStudents'] as List?)?.map(
              (e) => Map<String, dynamic>.from(e as Map),
            ) ??
            [],
      ),
      universityName: uni['name'] as String? ?? '',
      department: json['department'] as String? ?? '',
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

/// Deep-converts a dynamic value to a JSON-safe Dart type.
dynamic _deepConvert(dynamic v) {
  if (v is Map)
    return Map<String, dynamic>.fromEntries(
      v.entries.map((e) => MapEntry(e.key.toString(), _deepConvert(e.value))),
    );
  if (v is List) return v.map(_deepConvert).toList();
  return v;
}

dynamic _unwrapApiData(dynamic responseData) {
  if (responseData is Map) {
    final map = Map<String, dynamic>.from(responseData);
    return map['data'] ?? map;
  }
  return responseData;
}

class HodRepository {
  final ApiClient apiClient;

  HodRepository({required this.apiClient});

  // Dashboard
  Future<HodStats> getStats() async {
    final res = await apiClient.dio.get('/hod/dashboard-stats');
    final data = _unwrapApiData(res.data);
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected dashboard stats response format');
    }
    return HodStats.fromJson(data as Map<String, dynamic>);
  }

  // Students
  Future<List<Map<String, dynamic>>> getStudents({
    String status = 'all',
  }) async {
    final res = await apiClient.dio.get(
      '/hod/students',
      queryParameters: {'status': status},
    );
    final raw = _unwrapApiData(res.data);
    final list = raw is List ? raw : [];
    return list.map((e) => _deepConvert(e) as Map<String, dynamic>).toList();
  }

  Future<void> approveStudent(int studentId) async {
    await apiClient.dio.patch('/hod/students/$studentId/approve');
  }

  Future<void> rejectStudent(int studentId, {String reason = ''}) async {
    await apiClient.dio.patch(
      '/hod/students/$studentId/reject',
      data: {'reason': reason},
    );
  }

  // Proposals
  Future<List<Map<String, dynamic>>> getProposals() async {
    final res = await apiClient.dio.get('/hod/proposals');
    final raw = _unwrapApiData(res.data);
    final list = raw is List ? raw : [];
    return list.map((e) => _deepConvert(e) as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> sendProposal({
    required int studentId,
    required int companyId,
    String? proposalType,
    int? expectedDurationWeeks,
    String? expectedOutcomes,
  }) async {
    final res = await apiClient.dio.post(
      '/hod/proposals',
      data: {
        'studentId': studentId,
        'companyId': companyId,
        if (proposalType != null) 'proposal_type': proposalType,
        if (expectedDurationWeeks != null)
          'expected_duration_weeks': expectedDurationWeeks,
        if (expectedOutcomes != null) 'expected_outcomes': expectedOutcomes,
      },
    );
    final data = _unwrapApiData(res.data);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Unexpected proposal response format');
  }

  // Open Letters
  Future<List<Map<String, dynamic>>> getOpenLetters() async {
    final res = await apiClient.dio.get('/hod/proposals/open-letters');
    final raw = _unwrapApiData(res.data);
    final list = raw is List ? raw : [];
    return list.map((e) => _deepConvert(e) as Map<String, dynamic>).toList();
  }

  Future<void> updateOpenLetter(int id, String status) async {
    await apiClient.dio.patch(
      '/hod/proposals/open-letters/$id',
      data: {'status': status},
    );
  }

  // Companies
  Future<List<Map<String, dynamic>>> getCompanies({String query = ''}) async {
    final res = await apiClient.dio.get(
      '/hod/companies',
      queryParameters: {if (query.isNotEmpty) 'q': query},
    );
    final raw = _unwrapApiData(res.data);
    final list = raw is List ? raw : [];
    return list.map((e) => _deepConvert(e) as Map<String, dynamic>).toList();
  }

  Future<void> inviteCompany({
    required String email,
    required String companyName,
  }) async {
    await apiClient.dio.post(
      '/hod/invite-company',
      data: {'email': email, 'company_name': companyName},
    );
  }

  // Reports
  Future<List<Map<String, dynamic>>> getReports() async {
    final res = await apiClient.dio.get('/hod/reports');
    final raw = _unwrapApiData(res.data);
    final list = raw is List ? raw : [];
    return list.map((e) => _deepConvert(e) as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getReportDownload(int id) async {
    final res = await apiClient.dio.get('/hod/reports/$id/download');
    final data = _unwrapApiData(res.data);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Unexpected report download response format');
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final hodRepositoryProvider = Provider<HodRepository>((ref) {
  return HodRepository(apiClient: ref.watch(apiClientProvider));
});

final hodStatsProvider = FutureProvider<HodStats>((ref) {
  return ref.watch(hodRepositoryProvider).getStats();
});

// Students — filterable by status: 'all' | 'pending' | 'approved' | 'rejected'
final hodStudentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, status) {
      return ref.watch(hodRepositoryProvider).getStudents(status: status);
    });

final hodProposalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(hodRepositoryProvider).getProposals();
});

final hodOpenLettersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return ref.watch(hodRepositoryProvider).getOpenLetters();
});

final hodCompaniesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) {
      return ref.watch(hodRepositoryProvider).getCompanies(query: query);
    });

final hodReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(hodRepositoryProvider).getReports();
});
