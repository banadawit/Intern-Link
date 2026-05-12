import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../plans/domain/entities/plan_enums.dart';
import '../../../plans/domain/entities/weekly_plan.dart';
import '../../../plans/data/models/plans_dtos.dart';
import '../../domain/entities/supervisor_entities.dart';

int _si(dynamic v, [int fb = 0]) {
  if (v == null) return fb;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fb;
  return fb;
}

class SupervisorRepository {
  final ApiClient _api;

  SupervisorRepository(this._api);
  
  Future<SupervisorMe> getMe() async {
    final res = await _api.dio.get('/supervisor/me');
    return SupervisorMe.fromJson(res.data['data'] ?? res.data);
  }

  Future<SupervisorStats> getStats() async {
    final res = await _api.dio.get('/supervisor/me');
    final data = res.data;
    if (data is Map && data.containsKey('data')) {
      final innerData = data['data'];
      return SupervisorStats.fromJson(innerData['stats'] ?? {});
    }
    return SupervisorStats.fromJson(res.data['stats'] ?? {});
  }

  Future<SupervisorDashboardData> getDashboard() async {
    final res = await _api.dio.get('/supervisor/me');
    final raw = res.data;
    final d = raw is Map ? (raw['data'] ?? raw) : raw;
    final stats = SupervisorStats.fromJson(d['stats'] ?? {});

    List<Map<String, dynamic>> toMapList(dynamic list) {
      if (list is! List) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final studentsSummary = ((d['studentsSummary'] as List?) ?? [])
        .map((e) => SupervisorStudentSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final recentActivity = ((d['recentActivity'] as List?) ?? [])
        .map((e) => SupervisorActivityItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final deadlines = ((d['deadlines'] as List?) ?? [])
        .map((e) => SupervisorDeadline.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return SupervisorDashboardData(
      stats: stats,
      recentPendingProposals: toMapList(d['recentPendingProposals']),
      recentPendingPlans: toMapList(d['recentPendingPlans']),
      studentsSummary: studentsSummary,
      recentActivity: recentActivity,
      deadlines: deadlines,
    );
  }

  Future<List<SupervisorStudent>> getStudents() async {
    final res = await _api.dio.get('/supervisor/students');
    final data = res.data;
    final List list = (data is Map && data.containsKey('data')) ? data['data'] : (data as List);

    return list.map((item) {
      final s = item['student'];
      final a = item['assignment'];
      return SupervisorStudent(
        id: _si(s['id']),
        fullName: s['user']?['full_name']?.toString() ?? 'Student',
        email: s['user']?['email']?.toString() ?? '',
        universityName: s['university']?['name']?.toString() ?? '',
        department: s['department']?.toString(),
        internshipStatus: s['internship_status']?.toString() ?? 'PENDING',
        projectName: a?['project_name']?.toString(),
        startDate: a?['start_date'] != null
            ? DateTime.tryParse(a['start_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }).toList();
  }

  Future<List<InternshipProposal>> getProposals() async {
    final res = await _api.dio.get('/placements/incoming');
    final data = res.data;
    final List list = (data is Map && data.containsKey('data')) ? data['data'] : (data as List);

    return list.map((item) => InternshipProposal(
      id: _si(item['id']),
      studentId: _si(item['studentId']),
      studentName: item['student']?['user']?['full_name']?.toString() ?? 'Student',
      universityName: item['university']?['name']?.toString() ?? '',
      type: item['proposal_type']?.toString() ?? '',
      durationWeeks: item['expected_duration_weeks'] != null ? _si(item['expected_duration_weeks']) : null,
      outcomes: item['expected_outcomes']?.toString(),
      submittedAt: item['submitted_at'] != null
          ? DateTime.tryParse(item['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: _mapStatus(item['status']?.toString() ?? 'PENDING'),
    )).toList();
  }

  Future<void> respondToProposal(int proposalId, {required bool approve, String? reason}) async {
    await _api.dio.patch('/placements/respond/$proposalId', data: {
      'status': approve ? 'APPROVED' : 'REJECTED',
      'reason': reason,
    });
  }

  Future<List<WeeklyPlan>> getPendingPlans() async {
    final res = await _api.dio.get('/supervisor/weekly-plans', queryParameters: {'status': 'PENDING'});
    final data = res.data;
    final List list = (data is Map && data.containsKey('data')) ? data['data'] : (data as List);

    return list.map((e) => PlansDtos.weeklyPlanFromApi(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> reviewPlan(int planId, {required bool approve, String? feedback}) async {
    await _api.dio.patch('/progress/review/$planId', data: {
      'status': approve ? 'APPROVED' : 'REJECTED',
      'remarks': feedback,
    });
  }

  Future<void> submitEvaluation({
    required int studentId,
    required double technicalScore,
    required double softSkillScore,
    required String comments,
  }) async {
    await _api.dio.post('/supervisor/evaluation', data: {
      'studentId': studentId,
      'technical_score': technicalScore,
      'soft_skill_score': softSkillScore,
      'comments': comments,
    });
  }

  Future<List<SupervisorTeam>> getTeams() async {
    final res = await _api.dio.get('/supervisor/teams');
    final data = res.data;
    final Map<String, dynamic> body = (data is Map && data.containsKey('data'))
        ? Map<String, dynamic>.from(data['data'])
        : Map<String, dynamic>.from(data);
    final list = (body['active'] as List?) ?? [];

    return list.map((t) => SupervisorTeam(
      id: _si(t['id']),
      name: t['name']?.toString() ?? 'Team',
      projectId: t['projectId'] != null ? _si(t['projectId']) : null,
      projectName: t['project']?['name']?.toString(),
      members: ((t['members'] as List?) ?? []).map((m) {
        final s = m['student'];
        return SupervisorStudent(
          id: _si(s['id']),
          fullName: s['user']?['full_name']?.toString() ?? 'Student',
          email: s['user']?['email']?.toString() ?? '',
          universityName: 'N/A',
          internshipStatus: 'ACTIVE',
          startDate: DateTime.now(),
        );
      }).toList(),
      createdAt: t['created_at'] != null
          ? DateTime.tryParse(t['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    )).toList();
  }

  Future<void> createTeam(String name, {int? projectId}) async {
    await _api.dio.post('/supervisor/teams', data: {
      'name': name,
      if (projectId != null) 'projectId': projectId,
    });
  }

  Future<void> addTeamMember(int teamId, int studentId) async {
    await _api.dio.post('/supervisor/teams/$teamId/members', data: {'studentId': studentId});
  }

  Future<void> removeTeamMember(int teamId, int studentId) async {
    await _api.dio.delete('/supervisor/teams/$teamId/members/$studentId');
  }

  // ── Projects ───────────────────────────────────────────────────────────────

  Future<List<SupervisorProject>> getProjects() async {
    final res = await _api.dio.get('/supervisor/projects');
    final data = res.data;
    final Map<String, dynamic> body = (data is Map && data.containsKey('data'))
        ? Map<String, dynamic>.from(data['data'])
        : Map<String, dynamic>.from(data);
    final list = (body['active'] as List?) ?? [];

    return list.map((p) => SupervisorProject(
      id: _si(p['id']),
      name: p['name']?.toString() ?? 'Project',
      description: p['description']?.toString(),
      capacity: _si(p['capacity']),
      requiredSkills: (p['requiredSkills'] as List?)?.map((s) => s.toString()).toList() ?? [],
      memberCount: (p['students'] as List?)?.length ?? 0,
      teamCount: (p['teams'] as List?)?.length ?? 0,
      createdAt: p['created_at'] != null
          ? DateTime.tryParse(p['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    )).toList();
  }

  Future<SupervisorProject> createProject({
    required String name,
    String? description,
    int capacity = 0,
    List<String> requiredSkills = const [],
  }) async {
    final res = await _api.dio.post('/supervisor/projects', data: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'capacity': capacity,
      'requiredSkills': requiredSkills,
    });
    final raw = res.data;
    final d = raw is Map ? (raw['data'] ?? raw) : raw;
    return SupervisorProject(
      id: _si(d['id']),
      name: d['name']?.toString() ?? name,
      description: d['description']?.toString(),
      capacity: _si(d['capacity']),
      requiredSkills: (d['requiredSkills'] as List?)?.map((s) => s.toString()).toList() ?? [],
      memberCount: 0,
      teamCount: 0,
      createdAt: DateTime.now(),
    );
  }

  Future<void> addProjectMember(int projectId, int studentId) async {
    await _api.dio.post('/supervisor/projects/$projectId/members', data: {'studentId': studentId});
  }

  // ── Bulk Assignment (all-in-one) ───────────────────────────────────────────

  Future<Map<String, dynamic>> bulkAssign({
    required List<int> studentIds,
    int? teamId,
    String? teamName,
    int? projectId,
  }) async {
    final res = await _api.dio.post('/supervisor/assignments', data: {
      'studentIds': studentIds,
      if (teamId != null) 'teamId': teamId,
      if (teamName != null && teamName.isNotEmpty) 'teamName': teamName,
      if (projectId != null) 'projectId': projectId,
    });
    final raw = res.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }

  Future<List<Map<String, dynamic>>> getAssignments() async {
    final res = await _api.dio.get('/supervisor/assignments');
    final raw = res.data;
    final list = raw is Map ? (raw['data'] ?? []) : raw;
    if (list is! List) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getPerformance() async {
    final res = await _api.dio.get('/supervisor/performance');
    final raw = res.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _api.dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// Move a student to a different team.
  /// Returns error message if blocked (evaluation submitted).
  Future<void> moveStudentToTeam(int studentId, int newTeamId) async {
    await _api.dio.patch('/supervisor/assignments/students/$studentId/team', data: {'teamId': newTeamId});
  }

  /// Move a team to a different project.
  /// Returns { warned, warningMessage } if active work exists.
  Future<Map<String, dynamic>> moveTeamToProject(int teamId, int newProjectId) async {
    final res = await _api.dio.patch('/supervisor/assignments/teams/$teamId/project', data: {'projectId': newProjectId});
    final raw = res.data;
    return Map<String, dynamic>.from(raw is Map ? (raw['data'] ?? raw) : {});
  }

  Future<List<SupervisorAttendanceReport>> getWeeklyReports() async {
    final res = await _api.dio.get('/supervisor/weekly-reports');
    final data = res.data;
    final List list = (data is Map && data.containsKey('data')) ? data['data'] : (data as List);
    return list.map((e) => SupervisorAttendanceReport.fromJson(e)).toList();
  }

  Future<AttendanceHeatmap> getAttendanceHeatmap() async {
    final res = await _api.dio.get('/supervisor/attendance-heatmap');
    final data = res.data;
    final Map<String, dynamic> body = (data is Map && data.containsKey('data'))
        ? Map<String, dynamic>.from(data['data'])
        : Map<String, dynamic>.from(data);
    return AttendanceHeatmap.fromJson(body);
  }

  WeeklyPlanStatus _mapStatus(String s) {
    switch (s.toUpperCase()) {
      case 'APPROVED': return WeeklyPlanStatus.approved;
      case 'REJECTED': return WeeklyPlanStatus.rejected;
      default: return WeeklyPlanStatus.pending;
    }
  }
}

final supervisorRepositoryProvider = Provider<SupervisorRepository>((ref) {
  return SupervisorRepository(ref.watch(apiClientProvider));
});
