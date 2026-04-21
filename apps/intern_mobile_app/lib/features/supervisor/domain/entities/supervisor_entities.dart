import '../../../plans/domain/entities/plan_enums.dart';
import '../../../plans/domain/entities/weekly_plan.dart';

class SupervisorStats {
  final int pendingProposals;
  final int pendingWeeklyPlans;
  final int activeStudents;

  const SupervisorStats({
    required this.pendingProposals,
    required this.pendingWeeklyPlans,
    required this.activeStudents,
  });

  factory SupervisorStats.fromJson(Map<String, dynamic> json) {
    return SupervisorStats(
      pendingProposals: json['pendingProposalsCount'] ?? 0,
      pendingWeeklyPlans: json['pendingWeeklyPlansCount'] ?? 0,
      activeStudents: json['placedStudentsCount'] ?? 0,
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
