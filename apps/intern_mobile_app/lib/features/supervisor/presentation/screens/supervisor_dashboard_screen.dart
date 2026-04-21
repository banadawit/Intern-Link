import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supervisor_providers.dart';
import '../../dashboard/presentation/screens/dashboards.dart' show ModernDashboardScaffold, DashboardTab, ModernSliverAppBar;
import 'supervisor_workflow_screen.dart';
import 'supervisor_students_screen.dart';

class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ModernDashboardScaffold(
      title: 'Supervisor Portal',
      roleLabel: 'SUPERVISOR',
      tabs: [
        DashboardTab(
          label: 'Overview', 
          icon: Icons.dashboard_outlined, 
          activeIcon: Icons.dashboard_rounded, 
          view: _SupervisorOverviewTab(),
        ),
        DashboardTab(
          label: 'Workflow', 
          icon: Icons.assignment_turned_in_outlined, 
          activeIcon: Icons.assignment_turned_in_rounded, 
          view: SupervisorWorkflowTab(),
        ),
        DashboardTab(
          label: 'Students', 
          icon: Icons.people_outline_rounded, 
          activeIcon: Icons.people_rounded, 
          view: SupervisorStudentsTab(),
        ),
        DashboardTab(
          label: 'Teams', 
          icon: Icons.group_work_outlined, 
          activeIcon: Icons.group_work_rounded, 
          view: _SupervisorTeamsTab(),
        ),
      ],
    );
  }
}

class _SupervisorOverviewTab extends ConsumerWidget {
  const _SupervisorOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(supervisorStatsProvider);

    return CustomScrollView(
      slivers: [
        const ModernSliverAppBar(
          title: 'Overview',
          subtitle: 'Assigned Students Dashboard',
          profileName: 'Supervisor',
          gradient: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          backgroundIcon: Icons.dashboard_rounded,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    _buildStatsGrid(context, stats),
                    const SizedBox(height: 32),
                    _buildQuickAction(
                      context, 
                      'Review Weekly Plans', 
                      '${stats.pendingWeeklyPlans} waiting for approval', 
                      Icons.pending_actions_rounded, 
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildQuickAction(
                      context, 
                      'Incoming Proposals', 
                      '${stats.pendingProposals} new requests', 
                      Icons.mail_outline_rounded, 
                      Colors.blue,
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, SupervisorStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _statCard(context, 'Interns', stats.activeStudents.toString(), Colors.blue),
        _statCard(context, 'Plans', stats.pendingWeeklyPlans.toString(), Colors.orange),
        _statCard(context, 'Proposals', stats.pendingProposals.toString(), Colors.purple),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}

// Placeholder tabs - to be filled in separate files
class _SupervisorWorkflowTab extends StatelessWidget { const _SupervisorWorkflowTab(); @override Widget build(BuildContext context) => const Center(child: Text('Workflow Tab')); }
class _SupervisorStudentsTab extends StatelessWidget { const _SupervisorStudentsTab(); @override Widget build(BuildContext context) => const Center(child: Text('Students Tab')); }
class _SupervisorTeamsTab extends StatelessWidget { const _SupervisorTeamsTab(); @override Widget build(BuildContext context) => const Center(child: Text('Teams Tab')); }
