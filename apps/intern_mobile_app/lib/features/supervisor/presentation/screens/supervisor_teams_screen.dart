import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supervisor_providers.dart';
import '../../dashboard/presentation/screens/dashboards.dart' show ModernSliverAppBar;

class SupervisorTeamsTab extends ConsumerWidget {
  const SupervisorTeamsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(supervisorTeamsProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const ModernSliverAppBar(
          title: 'Teams',
          subtitle: 'Collaborative Groups',
          profileName: 'Supervisor',
          gradient: [Color(0xFF4568DC), Color(0xFFB06AB3)],
          backgroundIcon: Icons.group_work_rounded,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildCreateTeamButton(context, ref),
              const SizedBox(height: 32),
              teamsAsync.when(
                data: (teams) {
                  if (teams.isEmpty) return const Center(child: Text('No teams created yet.'));
                  return Column(
                    children: teams.map((team) => _TeamCard(team: team)).toList(),
                  );
                },
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

  Widget _buildCreateTeamButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4568DC), Color(0xFFB06AB3)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF4568DC).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCreateTeamDialog(context, ref),
          borderRadius: BorderRadius.circular(24),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text('Create New Team', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Team'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Team Name', hintText: 'e.g. Frontend Squad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(supervisorActionsProvider.notifier).createTeam(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final dynamic team;
  const _TeamCard({required this.team});

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.groups_rounded, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
              const Icon(Icons.more_vert_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const Text('MEMBERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: (team.members as List).map((m) => Chip(
              label: Text(m.fullName, style: const TextStyle(fontSize: 10)),
              avatar: CircleAvatar(child: Text(m.fullName[0])),
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        ],
      ),
    );
  }
}
