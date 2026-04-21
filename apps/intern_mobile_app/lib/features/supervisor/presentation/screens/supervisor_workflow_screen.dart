import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supervisor_providers.dart';
import '../widgets/supervisor_widgets.dart';
import '../../dashboard/presentation/screens/dashboards.dart' show ModernSliverAppBar;

class SupervisorWorkflowTab extends ConsumerWidget {
  const SupervisorWorkflowTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(supervisorProposalsProvider);
    final plansAsync = ref.watch(supervisorPendingPlansProvider);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          const ModernSliverAppBar(
            title: 'Workflow',
            subtitle: 'Approvals & Reviews',
            profileName: 'Supervisor',
            gradient: [Color(0xFFF2994A), Color(0xFFF2C94C)],
            backgroundIcon: Icons.assignment_turned_in_rounded,
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              const TabBar(
                tabs: [Tab(text: 'Weekly Plans'), Tab(text: 'Proposals')],
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.orange,
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _buildPlansList(context, ref, plansAsync),
            _buildProposalsList(context, ref, proposalsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(BuildContext context, WidgetRef ref, AsyncValue plansAsync) {
    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) return const Center(child: Text('No pending plans.'));
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return PlanReviewCard(
              studentName: plan.studentName ?? 'Student',
              weekNumber: plan.weekNumber,
              description: plan.objectives,
              onApprove: () => ref.read(supervisorActionsProvider.notifier).reviewPlan(plan.id, true),
              onReject: () => _showFeedbackDialog(context, ref, plan.id, false),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildProposalsList(BuildContext context, WidgetRef ref, AsyncValue proposalsAsync) {
    return proposalsAsync.when(
      data: (proposals) {
        if (proposals.isEmpty) return const Center(child: Text('No incoming proposals.'));
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: proposals.length,
          itemBuilder: (context, index) {
            final p = proposals[index];
            return _ProposalCard(
              proposal: p,
              onApprove: () => ref.read(supervisorActionsProvider.notifier).respondToProposal(p.id, true),
              onReject: () => _showFeedbackDialog(context, ref, p.id, true),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref, int id, bool isProposal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isProposal ? 'Reject Proposal' : 'Reject Weekly Plan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Feedback / Reason', hintText: 'Required for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              if (isProposal) {
                ref.read(supervisorActionsProvider.notifier).respondToProposal(id, false, reason: controller.text);
              } else {
                ref.read(supervisorActionsProvider.notifier).reviewPlan(id, false, feedback: controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final dynamic proposal;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ProposalCard({required this.proposal, required this.onApprove, required this.onReject});

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
              CircleAvatar(child: Text(proposal.studentName[0])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proposal.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(proposal.universityName, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.timer_outlined, 'Duration', '${proposal.durationWeeks ?? "?"} Weeks'),
          const SizedBox(height: 8),
          _infoRow(Icons.description_outlined, 'Type', proposal.type),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onReject, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Reject'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: onApprove, style: FilledButton.styleFrom(backgroundColor: Colors.green), child: const Text('Approve'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 8), Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]);
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
