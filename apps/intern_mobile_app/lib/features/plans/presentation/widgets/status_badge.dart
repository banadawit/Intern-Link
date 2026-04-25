import 'package:flutter/material.dart';

import '../../domain/entities/plan_enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final WeeklyPlanStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      WeeklyPlanStatus.draft => ('Draft', const Color(0xFF475467), Icons.edit_note_rounded),
      WeeklyPlanStatus.pending => ('Pending', const Color(0xFFB54708), Icons.pending_rounded),
      WeeklyPlanStatus.approved => ('Approved', const Color(0xFF067647), Icons.check_circle_rounded),
      WeeklyPlanStatus.rejected => ('Rejected', const Color(0xFFB42318), Icons.cancel_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}

