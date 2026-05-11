import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/dashboard/data/repositories/progress_repository.dart';
import '../../domain/entities/weekly_plan.dart';
import '../../domain/entities/plan_enums.dart';
import '../providers/checkins_provider.dart';
import '../providers/plans_providers.dart';
import '../widgets/status_badge.dart';
import 'plan_editor_screen.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final int planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  bool _resubmitting = false;

  // ── Resubmit flow ─────────────────────────────────────────────────────────
  Future<void> _resubmit(WeeklyPlan plan) async {
    final descCtrl = TextEditingController(text: plan.objectives);
    List<XFile> pickedFiles = [];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Resubmit Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Address the feedback and resubmit.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 16),
            // Feedback reminder
            if (plan.hasFeedback)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.forum_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(plan.feedback!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                ]),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Updated description / objectives', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            // File picker
            OutlinedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final files = await picker.pickMultiImage();
                setS(() => pickedFiles = files);
              },
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: Text(pickedFiles.isEmpty ? 'Attach files (optional)' : '${pickedFiles.length} file(s) selected'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6941C6)),
                child: const Text('Resubmit', style: TextStyle(fontWeight: FontWeight.w800)),
              )),
            ]),
          ]),
        );
      }),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _resubmitting = true);

    try {
      List<List<int>>? bytes;
      List<String>? names;
      if (pickedFiles.isNotEmpty) {
        bytes = [];
        names = [];
        for (final f in pickedFiles) {
          bytes.add(await f.readAsBytes());
          names.add(f.name);
        }
      }

      await ref.read(progressRepositoryProvider).resubmitWeeklyPlan(
        plan.id,
        descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : plan.objectives,
        fileBytes: bytes,
        fileNames: names,
      );

      ref.invalidate(plansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan resubmitted — awaiting supervisor review ✓')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _resubmitting = false);
    }
  }

  // ── Open attachment URL ───────────────────────────────────────────────────
  Future<void> _openAttachment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open file.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planDetailProvider(widget.planId));
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
          if (plan.version > 1)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text('v${plan.version}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
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
            // ── Status + title ───────────────────────────────────────────────
            _softCard(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(plan.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                StatusBadge(status: plan.status),
              ]),
              const SizedBox(height: 12),
              Text('Objectives', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(plan.objectives.isEmpty ? '—' : plan.objectives, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75), height: 1.45)),
            ])),

            // ── Feedback banner (rejection) ──────────────────────────────────
            if (plan.hasFeedback) ...[
              const SizedBox(height: 14),
              _softCard(context, borderColor: Colors.red.withOpacity(0.3), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.forum_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text('Supervisor Feedback', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.red)),
                ]),
                const SizedBox(height: 10),
                Text(plan.feedback ?? '', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.75), height: 1.45)),
                if (plan.canResubmit) ...[
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: FilledButton.icon(
                    onPressed: _resubmitting ? null : () => _resubmit(plan),
                    icon: _resubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(_resubmitting ? 'Resubmitting…' : 'Resubmit Plan'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6941C6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
                ],
              ])),
            ],

            // ── Under review banner ──────────────────────────────────────────
            if (plan.isUnderReview) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.07), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.25))),
                child: Row(children: [
                  const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    plan.status == WeeklyPlanStatus.resubmitted
                        ? 'Resubmitted — awaiting supervisor review.'
                        : 'Submitted — awaiting supervisor review.',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                  )),
                ]),
              ),
            ],

            // ── Tasks ────────────────────────────────────────────────────────
            const SizedBox(height: 14),
            _softCard(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tasks', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (plan.tasks.isEmpty)
                Text('No tasks provided.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))
              else
                ...plan.tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]),
                )),
            ])),

            // ── Attachments ──────────────────────────────────────────────────
            const SizedBox(height: 14),
            _softCard(context, child: _AttachmentsSection(plan: plan, onOpen: _openAttachment)),

            // ── Check-ins ────────────────────────────────────────────────────
            const SizedBox(height: 14),
            _softCard(context, child: _CheckinsSection(plan: plan)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _softCard(BuildContext context, {required Widget child, Color? borderColor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}

// ── Attachments section ───────────────────────────────────────────────────────

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({required this.plan, required this.onOpen});
  final WeeklyPlan plan;
  final Future<void> Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allFiles = [
      // Legacy single presentation file
      ...plan.files.map((f) => _FileItem(name: f.fileName, url: f.fileUrl, isLegacy: true)),
      // New JSON attachments
      ...plan.attachments.map((a) => _FileItem(name: a.name, url: a.url, size: a.sizeLabel, type: a.type)),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Attachments', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        const Spacer(),
        Text('${allFiles.length} file${allFiles.length == 1 ? '' : 's'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ]),
      const SizedBox(height: 12),
      if (allFiles.isEmpty)
        Text('No attachments.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))
      else
        ...allFiles.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => onOpen(f.url),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
              ),
              child: Row(children: [
                Icon(_fileIcon(f.type), color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                  if (f.size != null) Text(f.size!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ])),
                Icon(Icons.open_in_new_rounded, size: 16, color: theme.colorScheme.primary.withOpacity(0.6)),
              ]),
            ),
          ),
        )),
    ]);
  }

  IconData _fileIcon(String? type) {
    if (type == null) return Icons.insert_drive_file_rounded;
    if (type.startsWith('image/')) return Icons.image_rounded;
    if (type == 'application/pdf') return Icons.picture_as_pdf_rounded;
    if (type.contains('presentation') || type.contains('powerpoint')) return Icons.slideshow_rounded;
    if (type.contains('word')) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }
}

class _FileItem {
  final String name;
  final String url;
  final String? size;
  final String? type;
  final bool isLegacy;
  const _FileItem({required this.name, required this.url, this.size, this.type, this.isLegacy = false});
}

// ── Check-ins section (unchanged) ────────────────────────────────────────────

class _CheckinsSection extends ConsumerWidget {
  const _CheckinsSection({required this.plan});
  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final workDateIso = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final already = plan.checkins.any((c) => c.date.year == today.year && c.date.month == today.month && c.date.day == today.day);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Daily Check-ins', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        const Spacer(),
        if (!plan.canCheckin)
          StatusBadge(status: plan.status)
        else
          FilledButton.tonalIcon(
            onPressed: already ? null : () async {
              try {
                await ref.read(checkinsControllerProvider.notifier).markPresent(planId: plan.id, workDateIso: workDateIso);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in saved.')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            icon: const Icon(Icons.add_task_rounded, size: 18),
            label: Text(already ? 'Done' : 'Mark Present'),
          ),
      ]),
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
          spacing: 8, runSpacing: 8,
          children: plan.checkins.map((c) => Container(
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
          )).toList(),
        ),
    ]);
  }
}
