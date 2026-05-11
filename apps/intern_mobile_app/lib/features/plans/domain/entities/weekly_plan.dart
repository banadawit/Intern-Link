import 'daily_checkin.dart';
import 'plan_enums.dart';
import 'plan_file.dart';

/// A single file attachment on a plan or proposal.
class PlanAttachment {
  final String url;
  final String name;
  final String type;
  final int size;
  final DateTime uploadedAt;

  const PlanAttachment({
    required this.url,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  factory PlanAttachment.fromJson(Map<String, dynamic> json) {
    return PlanAttachment(
      url: json['url']?.toString() ?? '',
      name: json['name']?.toString() ?? 'file',
      type: json['type']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'type': type,
        'size': size,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  String get sizeLabel {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isImage => type.startsWith('image/');
  bool get isPdf => type == 'application/pdf';
}

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
  final List<PlanAttachment> attachments;
  final int version;

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
    this.attachments = const [],
    this.version = 1,
  });

  bool get canEdit => status == WeeklyPlanStatus.draft || status == WeeklyPlanStatus.rejected;
  bool get canResubmit => status == WeeklyPlanStatus.rejected;
  bool get canSubmit => status == WeeklyPlanStatus.draft;
  bool get canCheckin => status == WeeklyPlanStatus.approved;
  bool get hasFeedback => (feedback ?? '').trim().isNotEmpty;
  bool get isUnderReview => status == WeeklyPlanStatus.pending || status == WeeklyPlanStatus.resubmitted;
}

