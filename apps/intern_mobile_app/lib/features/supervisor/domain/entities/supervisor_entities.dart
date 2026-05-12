import '../../../plans/domain/entities/plan_enums.dart';

int _si(dynamic v, [int fb = 0]) {
  if (v == null) return fb;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fb;
  return fb;
}

class SupervisorMe {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String companyName;

  SupervisorMe({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.companyName,
  });

  factory SupervisorMe.fromJson(Map<String, dynamic> json) {
    final s = json['supervisor'] ?? json;
    return SupervisorMe(
      id: _si(s['id']),
      fullName: s['user']?['full_name'] ?? 'Supervisor',
      email: s['user']?['email'] ?? '',
      phone: s['phone_number'] ?? '',
      companyName: s['company']?['name'] ?? 'Company',
    );
  }
}

class SupervisorStats {
  final int pendingProposals;
  final int pendingPlans;
  final int totalStudents;
  final int reportsDue;
  final int missedCheckins;

  const SupervisorStats({
    required this.pendingProposals,
    required this.pendingPlans,
    required this.totalStudents,
    required this.reportsDue,
    required this.missedCheckins,
  });

  factory SupervisorStats.fromJson(Map<String, dynamic> json) {
    return SupervisorStats(
      pendingProposals: _si(json['pendingProposalsCount']),
      pendingPlans: _si(json['pendingWeeklyPlansCount']),
      totalStudents: _si(json['placedStudentsCount']),
      reportsDue: _si(json['reportsSubmittedCount']),
      missedCheckins: _si(json['missedCheckinsCount']),
    );
  }
}

class SupervisorStudentSummary {
  final int studentId;
  final String studentName;
  final String studentEmail;
  final String status; // ACTIVE | AT_RISK | INACTIVE
  final String? lastPlanStatus;
  final int? lastPlanWeek;
  final int? daysSinceLastPlan;

  const SupervisorStudentSummary({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    this.lastPlanStatus,
    this.lastPlanWeek,
    this.daysSinceLastPlan,
  });

  factory SupervisorStudentSummary.fromJson(Map<String, dynamic> json) {
    return SupervisorStudentSummary(
      studentId: _si(json['studentId']),
      studentName: json['studentName']?.toString() ?? 'Student',
      studentEmail: json['studentEmail']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      lastPlanStatus: json['lastPlanStatus']?.toString(),
      lastPlanWeek: json['lastPlanWeek'] != null ? _si(json['lastPlanWeek']) : null,
      daysSinceLastPlan: json['daysSinceLastPlan'] != null ? _si(json['daysSinceLastPlan']) : null,
    );
  }
}

class SupervisorActivityItem {
  final String type; // PLAN | PROPOSAL
  final int id;
  final String title;
  final String status;
  final DateTime timestamp;

  const SupervisorActivityItem({
    required this.type,
    required this.id,
    required this.title,
    required this.status,
    required this.timestamp,
  });

  factory SupervisorActivityItem.fromJson(Map<String, dynamic> json) {
    return SupervisorActivityItem(
      type: json['type']?.toString() ?? 'PLAN',
      id: _si(json['id']),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SupervisorDeadline {
  final String type; // EVALUATION_DUE | REPORT_DUE
  final String studentName;
  final DateTime? dueDate;
  final int? daysLeft;

  const SupervisorDeadline({
    required this.type,
    required this.studentName,
    this.dueDate,
    this.daysLeft,
  });

  factory SupervisorDeadline.fromJson(Map<String, dynamic> json) {
    return SupervisorDeadline(
      type: json['type']?.toString() ?? 'EVALUATION_DUE',
      studentName: json['studentName']?.toString() ?? 'Student',
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      daysLeft: json['daysLeft'] != null ? _si(json['daysLeft']) : null,
    );
  }
}

class SupervisorDashboardData {
  final SupervisorStats stats;
  final List<Map<String, dynamic>> recentPendingProposals;
  final List<Map<String, dynamic>> recentPendingPlans;
  final List<SupervisorStudentSummary> studentsSummary;
  final List<SupervisorActivityItem> recentActivity;
  final List<SupervisorDeadline> deadlines;

  const SupervisorDashboardData({
    required this.stats,
    required this.recentPendingProposals,
    required this.recentPendingPlans,
    required this.studentsSummary,
    required this.recentActivity,
    required this.deadlines,
  });
}

class SupervisorAttendanceReport {
  final int id;
  final int studentId;
  final String studentName;
  final int weekNumber;
  final String attendanceStatus;
  final String? executionStatus;
  final String? remarks;
  final DateTime submittedAt;

  const SupervisorAttendanceReport({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.weekNumber,
    required this.attendanceStatus,
    this.executionStatus,
    this.remarks,
    required this.submittedAt,
  });

  factory SupervisorAttendanceReport.fromJson(Map<String, dynamic> json) {
    return SupervisorAttendanceReport(
      id: _si(json['id']),
      studentId: _si(json['studentId']),
      studentName: json['student']?['user']?['full_name'] ?? 'Student',
      weekNumber: _si(json['weeklyPlan']?['week_number']),
      attendanceStatus: json['attendanceStatus'] ?? 'PENDING',
      executionStatus: json['execution_status'],
      remarks: json['remarks'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AttendanceHeatmap {
  final String rangeStart;
  final String rangeEnd;
  final List<StudentHeatmapData> students;

  const AttendanceHeatmap({
    required this.rangeStart,
    required this.rangeEnd,
    required this.students,
  });

  factory AttendanceHeatmap.fromJson(Map<String, dynamic> json) {
    return AttendanceHeatmap(
      rangeStart: json['rangeStart']?.toString() ?? '',
      rangeEnd: json['rangeEnd']?.toString() ?? '',
      students: (json['students'] as List? ?? [])
          .map((s) => StudentHeatmapData.fromJson(s))
          .toList(),
    );
  }
}

class StudentHeatmapData {
  final int studentId;
  final String fullName;
  final List<String> submittedDates;

  const StudentHeatmapData({
    required this.studentId,
    required this.fullName,
    required this.submittedDates,
  });

  factory StudentHeatmapData.fromJson(Map<String, dynamic> json) {
    return StudentHeatmapData(
      studentId: _si(json['studentId']),
      fullName: json['fullName']?.toString() ?? 'Student',
      submittedDates: List<String>.from(json['submittedDates'] ?? []),
    );
  }
}

class SupervisorStudent {
  final int id;
  final String fullName;
  final String email;
  final String universityName;
  final String? department;
  final String internshipStatus;
  final String? projectName;
  final DateTime startDate;

  const SupervisorStudent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.universityName,
    this.department,
    required this.internshipStatus,
    this.projectName,
    required this.startDate,
  });
}

class InternshipProposal {
  final int id;
  final int studentId;
  final String studentName;
  final String universityName;
  final String type;
  final int? durationWeeks;
  final String? outcomes;
  final DateTime submittedAt;
  final WeeklyPlanStatus status;

  const InternshipProposal({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.universityName,
    required this.type,
    this.durationWeeks,
    this.outcomes,
    required this.submittedAt,
    required this.status,
  });
}

class SupervisorTeam {
  final int id;
  final String name;
  final int? projectId;
  final String? projectName;
  final List<SupervisorStudent> members;
  final DateTime createdAt;

  const SupervisorTeam({
    required this.id,
    required this.name,
    this.projectId,
    this.projectName,
    required this.members,
    required this.createdAt,
  });
}

class SupervisorProject {
  final int id;
  final String name;
  final String? description;
  final int capacity;
  final List<String> requiredSkills;
  final int memberCount;
  final int teamCount;
  final DateTime createdAt;

  const SupervisorProject({
    required this.id,
    required this.name,
    this.description,
    required this.capacity,
    required this.requiredSkills,
    required this.memberCount,
    required this.teamCount,
    required this.createdAt,
  });

  bool get isFull => capacity > 0 && memberCount >= capacity;
  String get capacityLabel => capacity == 0 ? 'Unlimited' : '$memberCount / $capacity';
}
