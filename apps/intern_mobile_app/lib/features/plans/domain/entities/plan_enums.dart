enum WeeklyPlanStatus {
  draft,
  pending,
  approved,
  rejected;

  static WeeklyPlanStatus fromApi(String raw) {
    final v = raw.trim().toUpperCase();
    return switch (v) {
      'DRAFT' => WeeklyPlanStatus.draft,
      'APPROVED' => WeeklyPlanStatus.approved,
      'REJECTED' => WeeklyPlanStatus.rejected,
      _ => WeeklyPlanStatus.pending,
    };
  }

  String toApi() => switch (this) {
        WeeklyPlanStatus.draft => 'DRAFT',
        WeeklyPlanStatus.pending => 'PENDING',
        WeeklyPlanStatus.approved => 'APPROVED',
        WeeklyPlanStatus.rejected => 'REJECTED',
      };
}

enum DailyCheckinStatus {
  present,
  absent;

  static DailyCheckinStatus fromApi(String raw) {
    final v = raw.trim().toUpperCase();
    return v == 'ABSENT' ? DailyCheckinStatus.absent : DailyCheckinStatus.present;
  }

  String toApi() => this == DailyCheckinStatus.absent ? 'ABSENT' : 'PRESENT';
}

