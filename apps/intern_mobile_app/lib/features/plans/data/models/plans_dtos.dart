import '../../domain/entities/daily_checkin.dart';
import '../../domain/entities/plan_enums.dart';
import '../../domain/entities/plan_file.dart';
import '../../domain/entities/weekly_plan.dart';
import '../codecs/plan_description_codec.dart';

class PlansDtos {
  static WeeklyPlan weeklyPlanFromApi(Map<String, dynamic> json) {
    final descRaw = (json['plan_description'] ?? '').toString();
    final decoded = PlanDescriptionCodec.decode(descRaw);

    final status = WeeklyPlanStatus.fromApi((json['status'] ?? 'PENDING').toString());
    final createdAt = DateTime.tryParse((json['submitted_at'] ?? json['created_at'] ?? '').toString()) ?? DateTime.now();

    final daySubs = (json['daySubmissions'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map((e) => DailyCheckin(
                  id: (e['id'] ?? 0) as int,
                  planId: (e['weeklyPlanId'] ?? json['id'] ?? 0) as int,
                  date: DateTime.parse(e['workDate'].toString()),
                  status: DailyCheckinStatus.present, // backend doesn’t store PRESENT/ABSENT for check-in currently
                  notes: e['notes']?.toString(),
                ))
            .toList() ??
        const <DailyCheckin>[];

    final presentation = json['presentation'];
    final files = <PlanFile>[
      if (presentation is Map && (presentation['file_url'] ?? '').toString().trim().isNotEmpty)
        PlanFile(
          id: (presentation['id'] ?? 0) as int,
          planId: (json['id'] ?? 0) as int,
          fileUrl: presentation['file_url'].toString(),
          fileName: _fileNameFromUrl(presentation['file_url'].toString()),
        ),
    ];

    return WeeklyPlan(
      id: (json['id'] ?? 0) as int,
      studentId: (json['studentId'] ?? 0) as int,
      weekNumber: int.tryParse((json['week_number'] ?? 0).toString()) ?? 0,
      title: decoded.title.isNotEmpty ? decoded.title : 'Week ${(json['week_number'] ?? '')} Plan',
      objectives: decoded.objectives,
      tasks: decoded.tasks,
      status: status,
      feedback: json['feedback']?.toString(),
      createdAt: createdAt,
      checkins: daySubs,
      files: files,
    );
  }

  static String encodeDescription({
    required String title,
    required String objectives,
    required List<String> tasks,
  }) {
    return PlanDescriptionCodec.encode(title: title, objectives: objectives, tasks: tasks);
  }

  static String _fileNameFromUrl(String url) {
    final cleaned = url.replaceAll('\\', '/');
    final parts = cleaned.split('/');
    return parts.isEmpty ? 'presentation' : parts.last;
  }
}

