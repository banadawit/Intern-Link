enum WeeklyPlanStatus {
  draft,
  pending,
  approved,
  rejected,
  resubmitted;

  static WeeklyPlanStatus fromApi(String raw) {
    final v = raw.trim().toUpperCase();
    return switch (v) {
      'DRAFT'        => WeeklyPlanStatus.draft,
      'APPROVED'     => WeeklyPlanStatus.approved,
      'REJECTED'     => WeeklyPlanStatus.rejected,
      'RESUBMITTED'  => WeeklyPlanStatus.resubmitted,
      _              => WeeklyPlanStatus.pending,
    };
  }

  String toApi() => switch (this) {
        WeeklyPlanStatus.draft        => 'DRAFT',
        WeeklyPlanStatus.pending      => 'PENDING',
        WeeklyPlanStatus.approved     => 'APPROVED',
        WeeklyPlanStatus.rejected     => 'REJECTED',
        WeeklyPlanStatus.resubmitted  => 'RESUBMITTED',
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

