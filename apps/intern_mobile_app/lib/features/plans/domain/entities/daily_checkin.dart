import 'plan_enums.dart';

class DailyCheckin {
  final int id;
  final int planId;
  final DateTime date;
  final DailyCheckinStatus status;
  final String? notes;

  const DailyCheckin({
    required this.id,
    required this.planId,
    required this.date,
    required this.status,
    this.notes,
  });
}

