import '../../../plans/domain/entities/plan_enums.dart';
import '../../../plans/domain/entities/weekly_plan.dart';

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

  const SupervisorStats({
    required this.pendingProposals,
    required this.pendingPlans,
    required this.totalStudents,
    required this.reportsDue,
  });

  factory SupervisorStats.fromJson(Map<String, dynamic> json) {
    return SupervisorStats(
      pendingProposals: _si(json['pendingProposalsCount']),
      pendingPlans: _si(json['pendingWeeklyPlansCount']),
      totalStudents: _si(json['placedStudentsCount']),
      reportsDue: _si(json['reportsDueCount']),
    );
  }
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
  final List<SupervisorStudent> members;
  final DateTime createdAt;

  const SupervisorTeam({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
  });
}

class SupervisorProject {
  final int id;
  final String name;
  final List<SupervisorStudent> members;
  final DateTime createdAt;

  const SupervisorProject({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
  });
}
