import 'package:flutter/material.dart';
import '../../../plans/domain/entities/plan_enums.dart';

class StatusBadge extends StatelessWidget {
  final WeeklyPlanStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case WeeklyPlanStatus.approved:
        color = Colors.green;
        label = 'APPROVED';
        break;
      case WeeklyPlanStatus.rejected:
        color = Colors.red;
        label = 'REJECTED';
        break;
      case WeeklyPlanStatus.pending:
        color = Colors.orange;
        label = 'PENDING';
        break;
      default:
        color = Colors.grey;
        label = 'DRAFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

class PlanReviewCard extends StatelessWidget {
  final String studentName;
  final int weekNumber;
  final String description;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PlanReviewCard({
    super.key,
    required this.studentName,
    required this.weekNumber,
    required this.description,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, child: Text(studentName[0])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Week $weekNumber Plan', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              const StatusBadge(status: WeeklyPlanStatus.pending),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
