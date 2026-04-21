import 'package:flutter/material.dart';

import '../../domain/entities/weekly_plan.dart';
import 'status_badge.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.onView,
    required this.onEdit,
  });

  final WeeklyPlan plan;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final objectivesPreview = plan.objectives.trim().isEmpty
        ? 'No objectives provided.'
        : (plan.objectives.length > 120 ? '${plan.objectives.substring(0, 120)}…' : plan.objectives);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Week ${plan.weekNumber}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              StatusBadge(status: plan.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(plan.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            objectivesPreview,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.65), height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('View'),
              ),
              const Spacer(),
              if (plan.canEdit)
                FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit'),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: null,
                  icon: const Icon(Icons.lock_rounded, size: 18),
                  label: const Text('Locked'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

