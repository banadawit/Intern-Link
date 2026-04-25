import 'daily_checkin.dart';
import 'plan_enums.dart';
import 'plan_file.dart';

class WeeklyPlan {
  final int id;
  final int studentId;
  final int weekNumber;
  final String title;
  final String objectives;
  final List<String> tasks;
  final WeeklyPlanStatus status;
  final String? feedback;
  final DateTime createdAt;
  final List<DailyCheckin> checkins;
  final List<PlanFile> files;

  const WeeklyPlan({
    required this.id,
    required this.studentId,
    required this.weekNumber,
    required this.title,
    required this.objectives,
    required this.tasks,
    required this.status,
    required this.createdAt,
    this.feedback,
    this.checkins = const [],
    this.files = const [],
  });

  bool get canEdit => status == WeeklyPlanStatus.draft || status == WeeklyPlanStatus.rejected;

  bool get canSubmit => status == WeeklyPlanStatus.draft;

  bool get canCheckin => status == WeeklyPlanStatus.approved;

  bool get hasFeedback => (feedback ?? '').trim().isNotEmpty;
}

