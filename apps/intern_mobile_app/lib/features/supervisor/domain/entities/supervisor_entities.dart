import '../../../plans/domain/entities/plan_enums.dart';
import '../../../plans/domain/entities/weekly_plan.dart';

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
      id: s['id'] ?? 0,
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
      pendingProposals: json['pendingProposalsCount'] ?? 0,
      pendingPlans: json['pendingWeeklyPlansCount'] ?? 0,
      totalStudents: json['placedStudentsCount'] ?? 0,
      reportsDue: json['reportsDueCount'] ?? 0,
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
      id: json['id'],
      studentId: json['studentId'],
      studentName: json['student']['user']['full_name'],
      weekNumber: json['weeklyPlan']['week_number'],
      attendanceStatus: json['attendanceStatus'] ?? 'PENDING',
      executionStatus: json['execution_status'],
      remarks: json['remarks'],
      submittedAt: DateTime.parse(json['submitted_at']),
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
      rangeStart: json['rangeStart'],
      rangeEnd: json['rangeEnd'],
      students: (json['students'] as List).map((s) => StudentHeatmapData.fromJson(s)).toList(),
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
      studentId: json['studentId'],
      fullName: json['fullName'],
      submittedDates: List<String>.from(json['submittedDates']),
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
