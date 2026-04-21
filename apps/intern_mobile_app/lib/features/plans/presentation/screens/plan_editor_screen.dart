import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/weekly_plan.dart';
import '../../domain/entities/plan_enums.dart';
import '../providers/plan_editor_provider.dart';

class PlanEditorScreen extends ConsumerStatefulWidget {
  const PlanEditorScreen({super.key, this.existing});

  final WeeklyPlan? existing;

  @override
  ConsumerState<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends ConsumerState<PlanEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _objectivesCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _objectivesCtrl = TextEditingController(text: widget.existing?.objectives ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _objectivesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final existing = widget.existing;

    final args = PlanEditorArgs(
      draftId: (existing != null && existing.status == WeeklyPlanStatus.draft) ? existing.id : null,
      submittedPlanId: (existing != null && existing.status != WeeklyPlanStatus.draft) ? existing.id : null,
      initialWeekNumber: existing?.weekNumber ?? 1,
      initialTitle: existing?.title ?? '',
      initialObjectives: existing?.objectives ?? '',
      initialTasks: existing?.tasks.isNotEmpty == true ? existing!.tasks : const ['', ''],
    );

    final notifier = ref.read(planEditorProvider.notifier)..init(args);
    final state = ref.watch(planEditorProvider);

    _titleCtrl.value = _titleCtrl.value.copyWith(text: state.title, selection: _titleCtrl.selection);
    _objectivesCtrl.value = _objectivesCtrl.value.copyWith(text: state.objectives, selection: _objectivesCtrl.selection);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(existing == null ? 'Create Plan' : (existing.canEdit ? 'Edit Plan' : 'View Plan')),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (state.error != null) ...[
                _errorBanner(context, state.error!),
                const SizedBox(height: 14),
              ],
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      value: state.weekNumber,
                      decoration: const InputDecoration(labelText: 'Week number'),
                      items: List.generate(24, (i) => i + 1)
                          .map((w) => DropdownMenuItem(value: w, child: Text('Week $w')))
                          .toList(),
                      onChanged: existing != null && !existing.canEdit ? null : (v) => notifier.setWeekNumber(v ?? 1),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleCtrl,
                      enabled: existing == null || existing.canEdit,
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: notifier.setTitle,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _objectivesCtrl,
                      enabled: existing == null || existing.canEdit,
                      decoration: const InputDecoration(labelText: 'Objectives'),
                      minLines: 3,
                      maxLines: 6,
                      onChanged: notifier.setObjectives,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Objectives are required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Tasks', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                        if (existing == null || existing.canEdit)
                          FilledButton.tonalIcon(
                            onPressed: notifier.addTask,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Minimum 2 tasks.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    const SizedBox(height: 12),
                    ...List.generate(state.tasks.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                enabled: existing == null || existing.canEdit,
                                initialValue: state.tasks[i],
                                decoration: InputDecoration(labelText: 'Task ${i + 1}'),
                                onChanged: (v) => notifier.setTask(i, v),
                                validator: (v) => null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: (existing == null || existing.canEdit) ? () => notifier.removeTask(i) : null,
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (existing == null || existing.canEdit) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isSavingDraft
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                await notifier.saveDraft();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved.')));
                                }
                              },
                        icon: state.isSavingDraft ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                        label: const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                await notifier.submit();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan submitted.')));
                                  Navigator.pop(context);
                                }
                              },
                        icon: state.isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
                        label: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'This plan is locked. Only Draft or Rejected plans can be edited.',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
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

  Widget _errorBanner(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

