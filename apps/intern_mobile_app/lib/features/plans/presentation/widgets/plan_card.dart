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
        ? 'Objectives pending submission...'
        : (plan.objectives.length > 80 ? '${plan.objectives.substring(0, 80)}…' : plan.objectives);

    final statusColor = switch (plan.status.name.toUpperCase()) {
      'APPROVED' => Colors.green,
      'REJECTED' => Colors.red,
      'PENDING' => Colors.orange,
      'DRAFT' => Colors.grey,
      _ => Colors.blue,
    };

    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          // Main Card
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    plan.title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    objectivesPreview,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _extremeActionButton(context, Icons.remove_red_eye_rounded, 'OPEN', Colors.blue, onView),
                      const SizedBox(width: 12),
                      if (plan.canEdit)
                        _extremeActionButton(context, Icons.bolt_rounded, 'EDIT', theme.colorScheme.primary, onEdit),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Massive Week Indicator
          Positioned(
            top: 20,
            right: 20,
            child: Opacity(
              opacity: 0.05,
              child: Text(
                '${plan.weekNumber.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: statusColor),
              ),
            ),
          ),
          // Status Chip
          Positioned(
            top: 32,
            left: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Text(
                plan.status.name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
              ),
            ),
          ),
          // Week Label
          Positioned(
            top: 40,
            right: 40,
            child: Text(
              'WEEK',
              style: TextStyle(color: statusColor.withOpacity(0.5), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _extremeActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

