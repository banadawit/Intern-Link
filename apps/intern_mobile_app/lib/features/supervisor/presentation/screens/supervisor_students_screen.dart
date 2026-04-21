import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supervisor_providers.dart';
import '../domain/entities/supervisor_entities.dart';
import '../../dashboard/presentation/screens/dashboards.dart' show ModernSliverAppBar;

class SupervisorStudentsTab extends ConsumerWidget {
  const SupervisorStudentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(supervisorStudentsProvider);

    return CustomScrollView(
      slivers: [
        const ModernSliverAppBar(
          title: 'Students',
          subtitle: 'Team Management',
          profileName: 'Supervisor',
          gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
          backgroundIcon: Icons.people_rounded,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: studentsAsync.when(
            data: (students) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _StudentCard(student: students[index]),
                childCount: students.length,
              ),
            ),
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _StudentCard extends ConsumerWidget {
  final SupervisorStudent student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, child: Text(student.fullName[0])),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(student.universityName, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'track', child: Text('Track Progress')),
                  const PopupMenuItem(value: 'eval', child: Text('Final Evaluation')),
                  const PopupMenuItem(value: 'report', child: Text('View Reports')),
                ],
                onSelected: (val) {
                  if (val == 'eval') _showEvaluationSheet(context, ref, student);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoTile(context, Icons.work_outline_rounded, 'Project', student.projectName ?? 'Not Assigned'),
              const SizedBox(width: 24),
              _infoTile(context, Icons.calendar_today_rounded, 'Started', _formatDate(student.startDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showEvaluationSheet(BuildContext context, WidgetRef ref, SupervisorStudent student) {
    final techController = TextEditingController();
    final softController = TextEditingController();
    final commentsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 40),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Final Evaluation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Evaluating ${student.fullName}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _scoreInput('Technical Score (0-100)', techController),
            const SizedBox(height: 16),
            _scoreInput('Soft Skills Score (0-100)', softController),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'General Comments', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  final t = double.tryParse(techController.text) ?? 0;
                  final s = double.tryParse(softController.text) ?? 0;
                  ref.read(supervisorActionsProvider.notifier).submitEvaluation(student.id, t, s, commentsController.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Submit Evaluation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
