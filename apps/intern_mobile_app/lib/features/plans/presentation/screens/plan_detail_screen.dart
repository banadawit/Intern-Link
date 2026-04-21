import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/weekly_plan.dart';
import '../providers/checkins_provider.dart';
import '../providers/plans_providers.dart';
import '../widgets/status_badge.dart';
import 'plan_editor_screen.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final int planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planDetailProvider(planId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plan')),
        body: const Center(child: Text('Plan not found. Pull to refresh.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Week ${plan.weekNumber}'),
        actions: [
          if (plan.canEdit)
            IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlanEditorScreen(existing: plan))),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(plansProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _softCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(plan.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                      StatusBadge(status: plan.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Objectives', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(plan.objectives.isEmpty ? '—' : plan.objectives, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75), height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _softCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tasks', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  if (plan.tasks.isEmpty)
                    Text('No tasks provided.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))
                  else
                    ...plan.tasks.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 10),
                              Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600))),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            if (plan.hasFeedback) ...[
              const SizedBox(height: 14),
              _softCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.forum_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text('Supervisor Feedback', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(plan.feedback ?? '', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75), height: 1.45)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _softCard(
              context,
              child: _CheckinsSection(plan: plan),
            ),
            const SizedBox(height: 14),
            _softCard(
              context,
              child: _FilesSection(plan: plan),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _softCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      child: child,
    );
  }
}

class _CheckinsSection extends ConsumerWidget {
  const _CheckinsSection({required this.plan});

  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final workDateIso = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final already = plan.checkins.any((c) => c.date.year == today.year && c.date.month == today.month && c.date.day == today.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Daily Check-ins', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            const Spacer(),
            if (!plan.canCheckin)
              StatusBadge(status: plan.status)
            else
              FilledButton.tonalIcon(
                onPressed: already
                    ? null
                    : () async {
                        try {
                          await ref.read(checkinsControllerProvider.notifier).markPresent(planId: plan.id, workDateIso: workDateIso);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in saved.')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: Text(already ? 'Done' : 'Mark Present'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          plan.canCheckin ? 'One check-in per day.' : 'Check-ins unlock only after your plan is approved.',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 12),
        if (plan.checkins.isEmpty)
          Text('No check-ins yet.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.checkins
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
                      ),
                      child: Text(
                        '${c.date.day.toString().padLeft(2, '0')}/${c.date.month.toString().padLeft(2, '0')}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: theme.colorScheme.primary),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _FilesSection extends StatelessWidget {
  const _FilesSection({required this.plan});

  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Files', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            const Spacer(),
            if (plan.status == WeeklyPlanStatus.draft)
              Text('Upload after submission', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.55), fontWeight: FontWeight.w700))
            else
              FilledButton.tonalIcon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Upload presentation'),
                      content: const Text('File picker not added yet. You can still submit with a file by passing a file path from a picker later.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Upload'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (plan.files.isEmpty)
          Text('No files uploaded.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))
        else
          ...plan.files.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f.fileName, style: const TextStyle(fontWeight: FontWeight.w700))),
                    TextButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('File URL'),
                          content: SelectableText(f.fileUrl),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                        ),
                      ),
                      child: const Text('View'),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

