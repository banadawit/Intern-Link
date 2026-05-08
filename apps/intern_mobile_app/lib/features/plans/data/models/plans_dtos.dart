import '../../domain/entities/daily_checkin.dart';
import '../../domain/entities/plan_enums.dart';
import '../../domain/entities/plan_file.dart';
import '../../domain/entities/weekly_plan.dart';
import '../codecs/plan_description_codec.dart';

int _safeInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

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
                  id: _safeInt(e['id']),
                  planId: _safeInt(e['weeklyPlanId'] ?? json['id']),
                  date: DateTime.parse(e['workDate'].toString()),
                  status: DailyCheckinStatus.present,
                  notes: e['notes']?.toString(),
                ))
            .toList() ??
        const <DailyCheckin>[];

    final presentation = json['presentation'];
    final files = <PlanFile>[
      if (presentation is Map && (presentation['file_url'] ?? '').toString().trim().isNotEmpty)
        PlanFile(
          id: _safeInt(presentation['id']),
          planId: _safeInt(json['id']),
          fileUrl: presentation['file_url'].toString(),
          fileName: _fileNameFromUrl(presentation['file_url'].toString()),
        ),
    ];

    // Parse JSON attachments array
    final rawAttachments = json['attachments'];
    final attachments = <PlanAttachment>[];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        if (a is Map) {
          try {
            attachments.add(PlanAttachment.fromJson(Map<String, dynamic>.from(a)));
          } catch (_) {}
        }
      }
    }

    final version = _safeInt(json['version'], 1);

    return WeeklyPlan(
      id: _safeInt(json['id']),
      studentId: _safeInt(json['studentId']),
      weekNumber: int.tryParse((json['week_number'] ?? 0).toString()) ?? 0,
      title: decoded.title.isNotEmpty ? decoded.title : 'Week ${(json['week_number'] ?? '')} Plan',
      objectives: decoded.objectives,
      tasks: decoded.tasks,
      status: status,
      feedback: json['feedback']?.toString(),
      createdAt: createdAt,
      checkins: daySubs,
      files: files,
      attachments: attachments,
      version: version,
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
