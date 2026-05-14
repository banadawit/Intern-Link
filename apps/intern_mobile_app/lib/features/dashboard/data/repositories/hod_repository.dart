import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ── Safe parsers ──────────────────────────────────────────────────────────────

int _si(dynamic v, [int fb = 0]) {
  if (v == null) return fb;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fb;
  return fb;
}

double _sd(dynamic v, [double fb = 0.0]) {
  if (v == null) return fb;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fb;
  return fb;
}

dynamic _deepConvert(dynamic v) {
  if (v is Map) return Map<String, dynamic>.fromEntries(
    v.entries.map((e) => MapEntry(e.key.toString(), _deepConvert(e.value))),
  );
  if (v is List) return v.map(_deepConvert).toList();
  return v;
}

dynamic _unwrap(dynamic data) {
  if (data is Map) {
    final m = Map<String, dynamic>.from(data);
    return m['data'] ?? m;
  }
  return data;
}

List<Map<String, dynamic>> _toMapList(dynamic raw) {
  final list = raw is List ? raw : [];
  return list.map((e) => _deepConvert(e) as Map<String, dynamic>).toList();
}

// ── Models ────────────────────────────────────────────────────────────────────

class HodAlert {
  final String type;
  final String message;
  final int? studentId;
  final String? studentName;
  final int? daysElapsed;

  const HodAlert({
    required this.type,
    required this.message,
    this.studentId,
    this.studentName,
    this.daysElapsed,
  });

  factory HodAlert.fromJson(Map<String, dynamic> j) => HodAlert(
        type: j['type']?.toString() ?? '',
        message: j['message']?.toString() ?? '',
        studentId: j['studentId'] != null ? _si(j['studentId']) : null,
        studentName: j['studentName']?.toString(),
        daysElapsed: j['daysElapsed'] != null ? _si(j['daysElapsed']) : null,
      );
}

class WeeklyTrendPoint {
  final String weekLabel;
  final String weekStart;
  final int count;

  const WeeklyTrendPoint({
    required this.weekLabel,
    required this.weekStart,
    required this.count,
  });

  factory WeeklyTrendPoint.fromJson(Map<String, dynamic> j) => WeeklyTrendPoint(
        weekLabel: j['weekLabel']?.toString() ?? '',
        weekStart: j['weekStart']?.toString() ?? '',
        count: _si(j['count']),
      );
}

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
    return HodStats(
      totalStudents: _si(json['totalStudents']),
      pendingApprovals: _si(json['pendingApprovals']),
      approvedStudents: _si(json['approvedStudents']),
      rejectedStudents: _si(json['rejectedStudents']),
      placedStudents: _si(json['placedStudents']),
      approvedNotPlaced: _si(json['approvedNotPlaced']),
      totalReports: _si(json['reports']),
      proposals: {
        'pending': _si(p['pending']),
        'approved': _si(p['approved']),
        'rejected': _si(p['rejected']),
      },
      recentPendingStudents: _toMapList(json['recentPendingStudents']),
      universityName: uni['name']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
    );
  }
}

class HodEnhancedStats extends HodStats {
  final double placementRate;
  final double reportsCompletionRate;
  final double approvalSuccessRate;
  final List<HodAlert> alerts;
  final List<WeeklyTrendPoint> weeklyPlacementTrend;

  HodEnhancedStats({
    required super.totalStudents,
    required super.pendingApprovals,
    required super.approvedStudents,
    required super.rejectedStudents,
    required super.placedStudents,
    required super.approvedNotPlaced,
    required super.totalReports,
    required super.proposals,
    required super.recentPendingStudents,
    required super.universityName,
    required super.department,
    required this.placementRate,
    required this.reportsCompletionRate,
    required this.approvalSuccessRate,
    required this.alerts,
    required this.weeklyPlacementTrend,
  });

  factory HodEnhancedStats.fromJson(Map<String, dynamic> json) {
    final base = HodStats.fromJson(json);
    return HodEnhancedStats(
      totalStudents: base.totalStudents,
      pendingApprovals: base.pendingApprovals,
      approvedStudents: base.approvedStudents,
      rejectedStudents: base.rejectedStudents,
      placedStudents: base.placedStudents,
      approvedNotPlaced: base.approvedNotPlaced,
      totalReports: base.totalReports,
      proposals: base.proposals,
      recentPendingStudents: base.recentPendingStudents,
      universityName: base.universityName,
      department: base.department,
      placementRate: _sd(json['placementRate']),
      reportsCompletionRate: _sd(json['reportsCompletionRate']),
      approvalSuccessRate: _sd(json['approvalSuccessRate']),
      alerts: (json['alerts'] as List? ?? [])
          .map((e) => HodAlert.fromJson(_deepConvert(e) as Map<String, dynamic>))
          .toList(),
      weeklyPlacementTrend: (json['weeklyPlacementTrend'] as List? ?? [])
          .map((e) => WeeklyTrendPoint.fromJson(_deepConvert(e) as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── WeeklyReportFilter (value class for FutureProvider.family key) ────────────

class WeeklyReportFilter {
  final int? weekNumber;
  final String? attendanceStatus;
  final String? studentName;

  const WeeklyReportFilter({this.weekNumber, this.attendanceStatus, this.studentName});

  @override
  bool operator ==(Object other) =>
      other is WeeklyReportFilter &&
      other.weekNumber == weekNumber &&
      other.attendanceStatus == attendanceStatus &&
      other.studentName == studentName;

  @override
  int get hashCode => Object.hash(weekNumber, attendanceStatus, studentName);
}

// ── Repository ────────────────────────────────────────────────────────────────

class HodRepository {
  final ApiClient apiClient;

  HodRepository({required this.apiClient});

  // ── Dashboard ──────────────────────────────────────────────────────────────

  Future<HodStats> getStats() async {
    final res = await apiClient.dio.get('/hod/dashboard-stats');
    final data = _unwrap(res.data);
    return HodStats.fromJson(data as Map<String, dynamic>);
  }

  Future<HodEnhancedStats> getEnhancedStats() async {
    final res = await apiClient.dio.get('/hod/dashboard-stats/enhanced');
    final data = _unwrap(res.data);
    return HodEnhancedStats.fromJson(data as Map<String, dynamic>);
  }

  // ── Students ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStudents({String status = 'all'}) async {
    final res = await apiClient.dio.get('/hod/students', queryParameters: {'status': status});
    return _toMapList(_unwrap(res.data));
  }

  Future<void> approveStudent(int studentId) async {
    await apiClient.dio.patch('/hod/students/$studentId/approve');
  }

  Future<void> rejectStudent(int studentId, {String reason = ''}) async {
    await apiClient.dio.patch('/hod/students/$studentId/reject', data: {'reason': reason});
  }

  Future<void> markStudentViewed(int studentId) async {
    await apiClient.dio.patch('/hod/students/$studentId/mark-viewed');
  }

  Future<Map<String, dynamic>> bulkApproveStudents(List<int> studentIds) async {
    final res = await apiClient.dio.post('/hod/students/bulk-approve', data: {'studentIds': studentIds});
    final data = _unwrap(res.data);
    return _deepConvert(data) as Map<String, dynamic>;
  }

  Future<void> flagStudent(int studentId, String flagType, {String? note}) async {
    await apiClient.dio.patch('/hod/students/$studentId/flag', data: {
      'flagType': flagType,
      if (note != null) 'note': note,
    });
  }

  Future<void> unflagStudent(int studentId) async {
    await apiClient.dio.delete('/hod/students/$studentId/flag');
  }

  Future<List<Map<String, dynamic>>> getStudentTimeline(int studentId) async {
    final res = await apiClient.dio.get('/hod/students/$studentId/timeline');
    return _toMapList(_unwrap(res.data));
  }

  Future<void> reprocessStudent(int studentId) async {
    await apiClient.dio.patch('/hod/students/$studentId/reprocess');
  }

  // ── Proposals ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProposals() async {
    final res = await apiClient.dio.get('/hod/proposals');
    return _toMapList(_unwrap(res.data));
  }

  Future<List<Map<String, dynamic>>> getProposalsFiltered({String? status}) async {
    final res = await apiClient.dio.get('/hod/proposals', queryParameters: {
      if (status != null && status != 'ALL') 'status': status,
    });
    return _toMapList(_unwrap(res.data));
  }

  Future<Map<String, dynamic>> sendProposal({
    required int studentId,
    required int companyId,
    String? proposalType,
    int? expectedDurationWeeks,
    String? expectedOutcomes,
  }) async {
    final body = <String, dynamic>{
      'studentId': studentId,
      'companyId': companyId,
    };
    if (proposalType != null) body['proposal_type'] = proposalType;
    if (expectedDurationWeeks != null) body['expected_duration_weeks'] = expectedDurationWeeks;
    if (expectedOutcomes != null) body['expected_outcomes'] = expectedOutcomes;

    final res = await apiClient.dio.post(
      '/hod/proposals',
      data: body,
      options: Options(contentType: 'application/json'),
    );
    final data = _unwrap(res.data);
    return _deepConvert(data) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendTeamProposal({
    required List<int> studentIds,
    required int companyId,
    String? teamName,
    int? expectedDurationWeeks,
    String? expectedOutcomes,
  }) async {
    // Explicitly build the JSON body to ensure correct serialization on web
    final body = <String, dynamic>{
      'proposal_kind': 'TEAM',
      'studentIds': studentIds,
      'companyId': companyId,
    };
    if (teamName != null) body['team_name'] = teamName;
    if (expectedDurationWeeks != null) body['expected_duration_weeks'] = expectedDurationWeeks;
    if (expectedOutcomes != null) body['expected_outcomes'] = expectedOutcomes;

    final res = await apiClient.dio.post(
      '/hod/proposals',
      data: body,
      options: Options(contentType: 'application/json'),
    );
    final data = _unwrap(res.data);
    return _deepConvert(data) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> transitionProposalState(int proposalId, String targetState) async {
    final res = await apiClient.dio.patch('/hod/proposals/$proposalId/state', data: {'targetState': targetState});
    final data = _unwrap(res.data);
    return _deepConvert(data) as Map<String, dynamic>;
  }

  // ── Open Letters ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOpenLetters() async {
    final res = await apiClient.dio.get('/hod/proposals/open-letters');
    return _toMapList(_unwrap(res.data));
  }

  Future<void> updateOpenLetter(int id, String status, {String? reason}) async {
    await apiClient.dio.patch('/hod/proposals/open-letters/$id', data: {
      'status': status,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  // ── Companies ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCompanies({String query = ''}) async {
    final res = await apiClient.dio.get('/hod/companies', queryParameters: {
      if (query.isNotEmpty) 'q': query,
    });
    return _toMapList(_unwrap(res.data));
  }

  Future<void> inviteCompany({required String email, required String companyName}) async {
    await apiClient.dio.post('/hod/invite-company', data: {
      'email': email,
      'company_name': companyName,
    });
  }

  // ── Placements ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPlacements({String? status}) async {
    final res = await apiClient.dio.get('/hod/placements', queryParameters: {
      if (status != null) 'status': status,
    });
    return _toMapList(_unwrap(res.data));
  }

  Future<void> forceEndPlacement(int placementId, String reason) async {
    await apiClient.dio.patch('/hod/placements/$placementId/force-end', data: {'reason': reason});
  }

  // ── Reports ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getReports() async {
    final res = await apiClient.dio.get('/hod/reports');
    return _toMapList(_unwrap(res.data));
  }

  Future<Map<String, dynamic>> getReportDownload(int id) async {
    final res = await apiClient.dio.get('/hod/reports/$id/download');
    final data = _unwrap(res.data);
    return _deepConvert(data) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getWeeklyReports({
    int? weekNumber,
    String? attendanceStatus,
    String? studentName,
  }) async {
    final res = await apiClient.dio.get('/hod/reports/weekly', queryParameters: {
      if (weekNumber != null) 'weekNumber': weekNumber,
      if (attendanceStatus != null && attendanceStatus != 'ALL') 'attendanceStatus': attendanceStatus,
      if (studentName != null && studentName.isNotEmpty) 'studentName': studentName,
    });
    return _toMapList(_unwrap(res.data));
  }

  Future<Map<String, dynamic>> getReportsSummary() async {
    final res = await apiClient.dio.get('/hod/reports/summary');
    final data = _unwrap(res.data);
    return _deepConvert(data) as Map<String, dynamic>;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final hodRepositoryProvider = Provider<HodRepository>((ref) {
  return HodRepository(apiClient: ref.watch(apiClientProvider));
});

// Basic stats (legacy — kept for backward compat)
final hodStatsProvider = FutureProvider<HodStats>((ref) {
  return ref.watch(hodRepositoryProvider).getStats();
});

// Enhanced stats (used by Overview tab)
final hodEnhancedStatsProvider = FutureProvider<HodEnhancedStats>((ref) {
  return ref.watch(hodRepositoryProvider).getEnhancedStats();
});

// Students — filterable by status: 'all' | 'pending' | 'approved' | 'rejected'
final hodStudentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, status) {
  return ref.watch(hodRepositoryProvider).getStudents(status: status);
});

// Student timeline
final hodStudentTimelineProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, studentId) {
  return ref.watch(hodRepositoryProvider).getStudentTimeline(studentId);
});

// Proposals — filterable by status string (null or 'ALL' = all)
final hodProposalsFilteredProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, status) {
  return ref.watch(hodRepositoryProvider).getProposalsFiltered(status: status);
});

// Open letters
final hodOpenLettersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(hodRepositoryProvider).getOpenLetters();
});

// Companies — filterable by search query
final hodCompaniesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) {
  return ref.watch(hodRepositoryProvider).getCompanies(query: query);
});

// Placements — filterable by status (null = all)
final hodPlacementsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, status) {
  return ref.watch(hodRepositoryProvider).getPlacements(status: status);
});

// Weekly reports — filterable
final hodWeeklyReportsProvider = FutureProvider.family<List<Map<String, dynamic>>, WeeklyReportFilter>((ref, filter) {
  return ref.watch(hodRepositoryProvider).getWeeklyReports(
    weekNumber: filter.weekNumber,
    attendanceStatus: filter.attendanceStatus,
    studentName: filter.studentName,
  );
});

// Final reports
final hodReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(hodRepositoryProvider).getReports();
});

// Reports summary
final hodReportsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(hodRepositoryProvider).getReportsSummary();
});

// Proposals (all, no filter — used by Placement tab legacy)
final hodProposalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(hodRepositoryProvider).getProposals();
});
