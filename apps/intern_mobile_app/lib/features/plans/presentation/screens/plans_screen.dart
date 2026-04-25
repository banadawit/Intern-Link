import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan_enums.dart';
import '../../domain/entities/weekly_plan.dart';
import '../providers/plans_providers.dart';
import '../widgets/plan_card.dart';
import 'plan_detail_screen.dart';
import 'plan_editor_screen.dart';
import 'package:intern_mobile_app/features/dashboard/presentation/screens/dashboards.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  WeeklyPlanStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plansAsync = ref.watch(plansProvider);

    final bg = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        isDark ? const Color(0xFF0F172A) : Colors.white,
      ],
    );

    return Container(
      decoration: BoxDecoration(gradient: bg),
      child: RefreshIndicator(
        onRefresh: () => ref.read(plansProvider.notifier).refresh(),
        child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ModernSliverAppBar(
                title: 'Plans',
                subtitle: 'Weekly Reports',
                profileName: 'Student',
                gradient: const [Color(0xFF6a11cb), Color(0xFF2575fc)],
                backgroundIcon: Icons.assignment_rounded,
                actions: [
                  IconButton(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: _FilterChips(
                    selected: _filter,
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
              ),
              plansAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: err.toString(),
                    onRetry: () => ref.read(plansProvider.notifier).refresh(),
                  ),
                ),
                data: (plans) {
                  final filtered = _applyFilter(plans, _filter);
                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        onCreate: () => _openEditor(context),
                        filter: _filter,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final plan = filtered[index];
                        return PlanCard(
                          plan: plan,
                          onView: () => _openDetail(context, plan.id),
                          onEdit: () => _openEditor(context, plan: plan),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
        ),
      ),
    );
  }

  List<WeeklyPlan> _applyFilter(List<WeeklyPlan> plans, WeeklyPlanStatus? filter) {
    if (filter == null) return plans;
    return plans.where((p) => p.status == filter).toList();
  }

  void _openDetail(BuildContext context, int planId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlanDetailScreen(planId: planId)),
    );
  }

  void _openEditor(BuildContext context, {WeeklyPlan? plan}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlanEditorScreen(existing: plan)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark) BoxShadow(color: const Color(0xFF764ba2).withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Plans', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('Plan your week, submit, and track approvals.', style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onNew,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3F2B96)),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New'),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final WeeklyPlanStatus? selected;
  final ValueChanged<WeeklyPlanStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(context, 'All', selected == null, () => onChanged(null)),
        _chip(context, 'Pending', selected == WeeklyPlanStatus.pending, () => onChanged(WeeklyPlanStatus.pending)),
        _chip(context, 'Approved', selected == WeeklyPlanStatus.approved, () => onChanged(WeeklyPlanStatus.approved)),
        _chip(context, 'Rejected', selected == WeeklyPlanStatus.rejected, () => onChanged(WeeklyPlanStatus.rejected)),
        _chip(context, 'Draft', selected == WeeklyPlanStatus.draft, () => onChanged(WeeklyPlanStatus.draft)),
      ],
    );
  }

  Widget _chip(BuildContext context, String text, bool active, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primary.withOpacity(0.12) : theme.colorScheme.surface.withOpacity(0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? theme.colorScheme.primary.withOpacity(0.25) : theme.colorScheme.outlineVariant.withOpacity(0.2)),
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, color: active ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.65))),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.filter});

  final VoidCallback onCreate;
  final WeeklyPlanStatus? filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = filter == null ? 'No plans yet' : 'No plans in this filter';
    final subtitle = filter == null
        ? 'Create a weekly plan draft, then submit it for supervisor review.'
        : 'Try switching to All or create a new plan.';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.25)),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create Plan'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 54, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Couldn’t load plans', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

