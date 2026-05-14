part of 'dashboards.dart';

class HodDashboardScreen extends StatelessWidget {
  const HodDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardScaffold(
      title: 'HOD Portal',
      roleLabel: 'HEAD OF DEPARTMENT',
      tabs: [
        _DashboardTab(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          view: _HodOverviewTab(),
        ),
        _DashboardTab(
          label: 'Students',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          view: _HodStudentsTab(),
        ),
        _DashboardTab(
          label: 'Proposals',
          icon: Icons.send_outlined,
          activeIcon: Icons.send_rounded,
          view: _HodProposalsTab(),
          hideGlobalFab: true,
        ),
        _DashboardTab(
          label: 'Tracking',
          icon: Icons.track_changes_outlined,
          activeIcon: Icons.track_changes_rounded,
          view: _HodTrackingTab(),
        ),
        _DashboardTab(
          label: 'Reports',
          icon: Icons.description_outlined,
          activeIcon: Icons.description_rounded,
          view: _HodReportsTab(),
        ),
      ],
    );
  }
}

class _HodOverviewTab extends ConsumerWidget {
  const _HodOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(hodEnhancedStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) => statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (stats) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(hodEnhancedStatsProvider),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                ModernSliverAppBar(
                  title: 'Dashboard',
                  subtitle: 'Department Level Insights',
                  profileName: profile.fullName,
                  gradient: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  backgroundIcon: Icons.analytics_rounded,
                ),
                SliverPadding(
                  padding: EdgeInsets.all(
                    responsiveValue(
                      context,
                      mobile: 16.0,
                      tablet: 32.0,
                      desktop: 48.0,
                    ),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildStatGrid(context, stats, isDark),
                      const SizedBox(height: 16),
                      _buildRateRow(context, stats, isDark),
                      const SizedBox(height: 24),
                      _buildAlertsSection(context, ref, stats, isDark),
                      const SizedBox(height: 24),
                      _buildTrendChart(context, stats, isDark),
                      const SizedBox(height: 24),
                      FeedPreviewSection(),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatGrid(
    BuildContext context,
    HodEnhancedStats stats,
    bool isDark,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _statCard(
          'Total Students',
          stats.totalStudents.toString(),
          Icons.groups_rounded,
          Colors.blue,
          isDark,
        ),
        _statCard(
          'Pending Appr.',
          stats.pendingApprovals.toString(),
          Icons.pending_actions_rounded,
          Colors.orange,
          isDark,
        ),
        _statCard(
          'Placed',
          stats.placedStudents.toString(),
          Icons.check_circle_rounded,
          Colors.green,
          isDark,
        ),
        _statCard(
          'Reports',
          stats.totalReports.toString(),
          Icons.description_rounded,
          Colors.purple,
          isDark,
        ),
      ],
    );
  }

  Widget _buildRateRow(
    BuildContext context,
    HodEnhancedStats stats,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _rateCard(
            'Placement',
            '${stats.placementRate.toStringAsFixed(1)}%',
            Colors.teal,
            isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _rateCard(
            'Approval',
            '${stats.approvalSuccessRate.toStringAsFixed(1)}%',
            Colors.indigo,
            isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _rateCard(
            'Reports',
            '${stats.reportsCompletionRate.toStringAsFixed(1)}%',
            Colors.deepOrange,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _rateCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(
    BuildContext context,
    WidgetRef ref,
    HodEnhancedStats stats,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              size: 18,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              'Alerts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (stats.alerts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${stats.alerts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (stats.alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                SizedBox(width: 10),
                Text(
                  'All clear — no alerts',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          ...stats.alerts.map((a) => _buildAlertCard(context, ref, a, isDark)),
      ],
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    WidgetRef ref,
    HodAlert alert,
    bool isDark,
  ) {
    final color = alert.type == 'UNPLACED'
        ? Colors.orange
        : alert.type == 'NEEDS_REASSIGNMENT'
        ? Colors.red
        : alert.type == 'INACTIVE'
        ? Colors.blue
        : Colors.purple;
    final icon = alert.type == 'UNPLACED'
        ? Icons.person_off_rounded
        : alert.type == 'NEEDS_REASSIGNMENT'
        ? Icons.assignment_late_rounded
        : alert.type == 'INACTIVE'
        ? Icons.bedtime_rounded
        : Icons.schedule_rounded;
    final tabIndex =
        (alert.type == 'UNPLACED' || alert.type == 'NEEDS_REASSIGNMENT')
        ? 1
        : 3;

    return GestureDetector(
      onTap: () => ref.read(dashboardIndexProvider.notifier).state = tabIndex,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alert.message,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(
    BuildContext context,
    HodEnhancedStats stats,
    bool isDark,
  ) {
    if (stats.weeklyPlacementTrend.isEmpty) return const SizedBox.shrink();
    final maxCount = stats.weeklyPlacementTrend
        .map((p) => p.count)
        .fold(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Placement Trend',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.weeklyPlacementTrend.map((p) {
              final ratio = maxCount > 0 ? p.count / maxCount : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (p.count > 0)
                        Text(
                          '${p.count}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        height: 70 * ratio + 4,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.weekLabel,
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HodStudentsTab extends ConsumerStatefulWidget {
  const _HodStudentsTab();
  @override
  ConsumerState<_HodStudentsTab> createState() => _HodStudentsTabState();
}

class _HodStudentsTabState extends ConsumerState<_HodStudentsTab> {
  String _filter = 'all';
  bool _selectMode = false;
  final Set<int> _selected = {};
  final Set<int> _viewedIds = {};
  static const _filters = ['all', 'pending', 'approved', 'rejected'];

  Future<void> _approve(int studentId) async {
    try {
      await ref.read(hodRepositoryProvider).approveStudent(studentId);
      ref.invalidate(hodStudentsProvider(_filter));
      ref.invalidate(hodEnhancedStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Student approved ✓')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reject(int studentId) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Optional reason…'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, ctrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await ref
          .read(hodRepositoryProvider)
          .rejectStudent(studentId, reason: reason);
      ref.invalidate(hodStudentsProvider(_filter));
      ref.invalidate(hodEnhancedStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Student rejected')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _bulkApprove() async {
    if (_selected.isEmpty) return;
    try {
      final result = await ref
          .read(hodRepositoryProvider)
          .bulkApproveStudents(_selected.toList());
      final approved = (result['approved'] as List?)?.length ?? 0;
      ref.invalidate(hodStudentsProvider(_filter));
      ref.invalidate(hodEnhancedStatsProvider);
      setState(() {
        _selected.clear();
        _selectMode = false;
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$approved students approved ✓')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reprocess(int studentId) async {
    try {
      await ref.read(hodRepositoryProvider).reprocessStudent(studentId);
      ref.invalidate(hodStudentsProvider(_filter));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student reset to Pending')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showFlagSheet(int studentId, String? currentFlag) {
    final noteCtrl = TextEditingController();
    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(
            responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Flag Student',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              if (currentFlag != null)
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Colors.grey),
                  title: const Text('Remove Flag'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(hodRepositoryProvider)
                        .unflagStudent(studentId);
                    ref.invalidate(hodStudentsProvider(_filter));
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.trending_down_rounded,
                  color: Colors.orange,
                ),
                title: const Text('Low Performance'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(hodRepositoryProvider)
                      .flagStudent(
                        studentId,
                        'LOW_PERFORMANCE',
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      );
                  ref.invalidate(hodStudentsProvider(_filter));
                },
              ),
              ListTile(
                leading: const Icon(Icons.bedtime_rounded, color: Colors.blue),
                title: const Text('Inactive'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(hodRepositoryProvider)
                      .flagStudent(
                        studentId,
                        'INACTIVE',
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      );
                  ref.invalidate(hodStudentsProvider(_filter));
                },
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Optional note…',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeline(int studentId, String studentName) {
    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final timelineAsync = ref.watch(
            hodStudentTimelineProvider(studentId),
          );
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: EdgeInsets.all(
              responsiveValue(
                context,
                mobile: 16.0,
                tablet: 32.0,
                desktop: 48.0,
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timeline: $studentName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: timelineAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (events) => ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (ctx, i) {
                        final e = events[i];
                        final state = e['state']?.toString() ?? '';
                        final ts = e['timestamp']?.toString() ?? '';
                        final dt = DateTime.tryParse(ts);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                if (i < events.length - 1)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: Colors.teal.withOpacity(0.3),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (dt != null)
                                      Text(
                                        timeago.format(dt),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsAsync = ref.watch(hodStudentsProvider(_filter));

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: CustomScrollView(
        slivers: [
          ModernSliverAppBar(
            title: 'Students',
            subtitle: 'Department Enrollment',
            profileName:
                ref.watch(userProfileProvider).value?.fullName ?? 'HOD',
            gradient: const [Color(0xFF00b09b), Color(0xFF96c93d)],
            backgroundIcon: Icons.person_search_rounded,
            actions: [
              if (_selectMode)
                TextButton(
                  onPressed: _bulkApprove,
                  child: Text(
                    'Approve (${_selected.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  _selectMode ? Icons.close_rounded : Icons.checklist_rounded,
                  color: Colors.white,
                ),
                onPressed: () => setState(() {
                  _selectMode = !_selectMode;
                  _selected.clear();
                }),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final sel = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF00b09b)
                              : (isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? const Color(0xFF00b09b)
                                : (isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05)),
                          ),
                        ),
                        child: Text(
                          f[0].toUpperCase() + f.substring(1),
                          style: TextStyle(
                            color: sel
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          studentsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (students) {
              if (students.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildStudentCard(students[i], isDark),
                    childCount: students.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> s, bool isDark) {
    try {
      final user = s['user'] as Map<String, dynamic>? ?? {};
      final name = (user['full_name'] ?? '').toString();
      final email = (user['email'] ?? '').toString();
      final hodStatus = (s['hod_approval_status'] ?? 'PENDING').toString();
      final internStatus = (s['internship_status'] ?? 'PENDING').toString();
      final studentId = _parseInt(s['id']);
      final department = (s['department'] ?? '').toString();
      final flagType = s['flag_type']?.toString();
      final latestProposal = s['latestProposal'] as Map<String, dynamic>?;
      final proposalStatus = latestProposal?['status']?.toString();
      final docUrl = user['verification_document']?.toString() ?? '';
      final hasDoc = docUrl.isNotEmpty;
      final isViewed = user['document_viewed'] == true || _viewedIds.contains(studentId);

      // Proposal badge status
      final proposalBadgeStatus = internStatus == 'PLACED'
          ? 'PLACED'
          : proposalStatus == 'PENDING'
          ? 'PENDING'
          : proposalStatus == 'APPROVED'
          ? 'APPROVED'
          : proposalStatus == 'REJECTED'
          ? 'REJECTED'
          : null; // null = no badge

      Color statusColor = hodStatus == 'APPROVED'
          ? Colors.green
          : hodStatus == 'REJECTED'
          ? Colors.red
          : Colors.orange;
      final isSelected = _selected.contains(studentId);

      return GestureDetector(
        onTap: _selectMode
            ? () => setState(() {
                if (isSelected)
                  _selected.remove(studentId);
                else
                  _selected.add(studentId);
              })
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.teal.withOpacity(0.1)
                : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? Colors.teal
                  : (isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_selectMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (v) => setState(() {
                        if (v == true)
                          _selected.add(studentId);
                        else
                          _selected.remove(studentId);
                      }),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor.withOpacity(0.8), statusColor],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (department.isNotEmpty)
                          Text(
                            department,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        if (proposalBadgeStatus != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _ProposalStatusBadge(proposalBadgeStatus),
                              if (proposalStatus == 'PENDING' &&
                                  latestProposal?['companyName'] != null) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '→ ${latestProposal!['companyName']}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 9,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hodStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              flagType != null
                                  ? Icons.flag_rounded
                                  : Icons.flag_outlined,
                              size: 16,
                              color: flagType != null
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                            onPressed: () =>
                                _showFlagSheet(studentId, flagType),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.timeline_rounded,
                              size: 16,
                              color: Colors.teal,
                            ),
                            onPressed: () => _showTimeline(studentId, name),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (!_selectMode) ...[
                const SizedBox(height: 12),
                _buildDocumentRow(
                  context,
                  docUrl,
                  hasDoc,
                  isDark,
                  viewed: isViewed,
                  onView: () async {
                    try {
                      await ref.read(hodRepositoryProvider).markStudentViewed(studentId);
                      setState(() => _viewedIds.add(studentId));
                    } catch (_) {}
                  },
                ),
                if (hodStatus == 'PENDING') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reject(studentId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Tooltip(
                          message: (hasDoc && !isViewed) ? 'Review document first' : '',
                          child: FilledButton(
                            onPressed: (hasDoc && !isViewed)
                                ? null
                                : () => _approve(studentId),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00b09b),
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (hodStatus == 'APPROVED' &&
                    internStatus != 'PLACED') ...[
                  if (proposalStatus == 'PENDING')
                    // Already has a pending proposal — show info instead of send button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pending proposal to ${latestProposal?['companyName'] ?? 'a company'}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showSmartConflictDialog(
                              context,
                              studentName: name,
                              proposalStatus: 'PENDING',
                              companyName:
                                  latestProposal?['companyName']?.toString() ??
                                  'the company',
                              submittedAt:
                                  latestProposal?['submittedAt'] != null
                                  ? DateTime.tryParse(
                                      latestProposal!['submittedAt'].toString(),
                                    )
                                  : null,
                            ),
                            child: const Text(
                              'Details',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            _showSendProposalSheet(context, studentId, name),
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: Text(
                          proposalStatus == 'REJECTED'
                              ? 'Resend Proposal'
                              : 'Send Proposal',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00b09b),
                        ),
                      ),
                    ),
                ] else if (hodStatus == 'REJECTED')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _reprocess(studentId),
                      child: const Text('Reprocess (Reset to Pending)'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Parse error: $e',
          style: const TextStyle(fontSize: 11, color: Colors.red),
        ),
      );
    }
  }

  void _showSendProposalSheet(
    BuildContext context,
    int studentId,
    String studentName,
  ) {
    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          _SendProposalSheet(studentId: studentId, studentName: studentName),
    ).then((_) {
      ref.invalidate(hodStudentsProvider(_filter));
      ref.invalidate(hodProposalsProvider);
      ref.invalidate(hodEnhancedStatsProvider);
    });
  }
}

class _SendProposalSheet extends ConsumerStatefulWidget {
  /// For individual proposals from Students tab, pass studentId + studentName.
  /// For team proposals from Proposals tab FAB, pass studentId=0 and studentName=''.
  final int studentId;
  final String studentName;
  const _SendProposalSheet({
    required this.studentId,
    required this.studentName,
  });
  @override
  ConsumerState<_SendProposalSheet> createState() => _SendProposalSheetState();
}

class _SendProposalSheetState extends ConsumerState<_SendProposalSheet> {
  bool _isTeam = false;
  int? _selectedCompanyId;
  int? _selectedLeadStudentId;
  String _selectedLeadStudentName = '';
  Map<String, dynamic>?
  _leadStudentProposal; // latest proposal info for smart errors
  final List<Map<String, dynamic>> _teamMembers = []; // additional members
  final _teamNameCtrl = TextEditingController();
  final _outcomesCtrl = TextEditingController();
  int _weeks = 12;
  bool _loading = false;

  @override
  void dispose() {
    _outcomesCtrl.dispose();
    _teamNameCtrl.dispose();
    super.dispose();
  }

  bool get _isIndividualMode => widget.studentId > 0 && !_isTeam;

  Future<void> _submit() async {
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a company')));
      return;
    }

    if (_isTeam) {
      // Team proposal: need lead + at least 1 more member
      final leadId =
          _selectedLeadStudentId ??
          (widget.studentId > 0 ? widget.studentId : null);
      if (leadId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a lead student')),
        );
        return;
      }
      if (_teamMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one more team member')),
        );
        return;
      }
      final allIds = [leadId, ..._teamMembers.map((m) => _parseInt(m['id']))];
      setState(() => _loading = true);
      try {
        await ref
            .read(hodRepositoryProvider)
            .sendTeamProposal(
              studentIds: allIds,
              companyId: _selectedCompanyId!,
              teamName: _teamNameCtrl.text.trim().isNotEmpty
                  ? _teamNameCtrl.text.trim()
                  : 'Team Proposal',
              expectedDurationWeeks: _weeks,
              expectedOutcomes: _outcomesCtrl.text.trim().isNotEmpty
                  ? _outcomesCtrl.text.trim()
                  : null,
            );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Team proposal sent ✓')));
        }
      } catch (e) {
        if (mounted) await _handleProposalError(e, isTeam: true);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // Individual proposal
      final sid = widget.studentId > 0
          ? widget.studentId
          : _selectedLeadStudentId;
      if (sid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a student')),
        );
        return;
      }
      setState(() => _loading = true);
      try {
        await ref
            .read(hodRepositoryProvider)
            .sendProposal(
              studentId: sid,
              companyId: _selectedCompanyId!,
              expectedDurationWeeks: _weeks,
              expectedOutcomes: _outcomesCtrl.text.trim().isNotEmpty
                  ? _outcomesCtrl.text.trim()
                  : null,
            );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Proposal sent ✓')));
        }
      } catch (e) {
        if (mounted) await _handleProposalError(e, isTeam: false);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  /// Parses structured conflict errors from the backend and shows a smart dialog.
  /// Falls back to a plain snackbar for non-conflict errors.
  Future<void> _handleProposalError(Object e, {required bool isTeam}) async {
    // Try to extract structured data from DioException response
    Map<String, dynamic>? errorData;
    String errorMessage = e.toString();

    try {
      // Dio wraps the response body in the exception
      final dioError = e as dynamic;
      final response = dioError?.response?.data;
      if (response is Map) {
        errorData = Map<String, dynamic>.from(response['data'] as Map? ?? {});
        errorMessage = response['message']?.toString() ?? errorMessage;
      }
    } catch (_) {}

    if (errorData != null && errorData.containsKey('proposalStatus')) {
      final proposalStatus =
          errorData['proposalStatus']?.toString() ?? 'PENDING';
      final companyName = errorData['companyName']?.toString() ?? 'the company';
      final teamName = errorData['teamName']?.toString();
      final submittedAtRaw = errorData['submittedAt'];
      final submittedAt = submittedAtRaw != null
          ? DateTime.tryParse(submittedAtRaw.toString())
          : null;

      // Find the student name from selected data
      String studentName = _selectedLeadStudentName.isNotEmpty
          ? _selectedLeadStudentName
          : widget.studentName.isNotEmpty
          ? widget.studentName
          : 'This student';

      if (!mounted) return;
      final action = await _showSmartConflictDialog(
        context,
        studentName: studentName,
        proposalStatus: proposalStatus,
        companyName: companyName,
        teamName: teamName,
        submittedAt: submittedAt,
      );

      if (action == _ConflictAction.sendNew && mounted) {
        // User wants to send a new proposal — just close the dialog, they can resubmit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a different company to send a new proposal.'),
          ),
        );
      }
    } else {
      // Generic error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _showStudentPicker({required bool isLead}) {
    final studentsAsync = ref.read(hodStudentsProvider('approved'));
    studentsAsync.whenData((students) {
      showResponsiveSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: EdgeInsets.all(
            responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isLead ? 'Select Lead Student' : 'Add Team Member',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Disabled students have active proposals or are already placed.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    final user = s['user'] as Map<String, dynamic>? ?? {};
                    final name = user['full_name']?.toString() ?? 'Student';
                    final sid = _parseInt(s['id']);
                    final dept = s['department']?.toString() ?? '';
                    final internStatus =
                        s['internship_status']?.toString() ?? '';
                    final latestProposal =
                        s['latestProposal'] as Map<String, dynamic>?;
                    final proposalStatus = latestProposal?['status']
                        ?.toString();

                    // Determine availability
                    final isPlaced = internStatus == 'PLACED';
                    final hasPending = proposalStatus == 'PENDING';
                    final alreadyAdded =
                        _teamMembers.any((m) => _parseInt(m['id']) == sid) ||
                        sid == _selectedLeadStudentId;

                    // Disabled if placed, has pending proposal, or already in this team
                    final isDisabled = isPlaced || hasPending || alreadyAdded;

                    // Badge status
                    final badgeStatus = isPlaced
                        ? 'PLACED'
                        : hasPending
                        ? 'PENDING'
                        : proposalStatus == 'REJECTED'
                        ? 'REJECTED'
                        : 'AVAILABLE';

                    return Opacity(
                      opacity: isDisabled ? 0.45 : 1.0,
                      child: ListTile(
                        enabled: !isDisabled,
                        leading: CircleAvatar(
                          backgroundColor: isDisabled
                              ? Colors.grey.shade300
                              : Colors.teal.withOpacity(0.15),
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: TextStyle(
                              color: isDisabled ? Colors.grey : Colors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDisabled ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (dept.isNotEmpty)
                              Text(dept, style: const TextStyle(fontSize: 11)),
                            const SizedBox(height: 3),
                            _ProposalStatusBadge(badgeStatus),
                            if (hasPending && latestProposal != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '→ ${latestProposal['companyName'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: isDisabled
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                setState(() {
                                  if (isLead) {
                                    _selectedLeadStudentId = sid;
                                    _selectedLeadStudentName = name;
                                    // Store proposal info for smart error display
                                    _leadStudentProposal = latestProposal;
                                  } else {
                                    _teamMembers.add({
                                      'id': sid,
                                      'name': name,
                                      'latestProposal': latestProposal,
                                    });
                                  }
                                });
                              },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companiesAsync = ref.watch(hodCompaniesProvider(''));

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'New Proposal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            // Individual / Team toggle (only show when not pre-filled with a student)
            if (widget.studentId <= 0) ...[
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isTeam = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isTeam
                              ? const Color(0xFF00b09b)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Individual',
                            style: TextStyle(
                              color: !_isTeam ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isTeam = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isTeam
                              ? const Color(0xFFf857a6)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Team / Group',
                            style: TextStyle(
                              color: _isTeam ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Student display (pre-filled individual)
            if (widget.studentId > 0 && !_isTeam)
              Text(
                'For: ${widget.studentName}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),

            // Lead student picker (when from Proposals FAB)
            if (widget.studentId <= 0) ...[
              GestureDetector(
                onTap: () => _showStudentPicker(isLead: true),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedLeadStudentName.isNotEmpty
                              ? _selectedLeadStudentName
                              : (_isTeam
                                    ? 'Select Lead Student *'
                                    : 'Select Student *'),
                          style: TextStyle(
                            color: _selectedLeadStudentName.isNotEmpty
                                ? null
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Team name + members (team mode)
            if (_isTeam) ...[
              TextField(
                controller: _teamNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Team members list
              if (_teamMembers.isNotEmpty) ...[
                const Text(
                  'Team Members:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ..._teamMembers.map(
                  (m) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf857a6).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: Color(0xFFf857a6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m['name']?.toString() ?? 'Student',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _teamMembers.remove(m)),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              OutlinedButton.icon(
                onPressed: () => _showStudentPicker(isLead: false),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Add Team Member'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFf857a6),
                  side: const BorderSide(color: Color(0xFFf857a6)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Company picker
            companiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (companies) => DropdownButtonFormField<int>(
                isExpanded: true,
                value: _selectedCompanyId,
                decoration: InputDecoration(
                  labelText: 'Select Company',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: companies
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: _parseInt(c['id']),
                        child: Text(
                          c['name']?.toString() ?? 'Company',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCompanyId = v),
              ),
            ),
            const SizedBox(height: 12),

            // Duration
            Row(
              children: [
                const Text(
                  'Duration (weeks):',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () {
                    if (_weeks > 4) setState(() => _weeks--);
                  },
                ),
                Text(
                  '$_weeks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () {
                    if (_weeks < 52) setState(() => _weeks++);
                  },
                ),
              ],
            ),

            TextField(
              controller: _outcomesCtrl,
              decoration: InputDecoration(
                labelText: 'Expected Outcomes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _isTeam
                      ? const Color(0xFFf857a6)
                      : const Color(0xFF00b09b),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isTeam ? 'Send Team Proposal' : 'Send Proposal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HodProposalsTab extends ConsumerStatefulWidget {
  const _HodProposalsTab();
  @override
  ConsumerState<_HodProposalsTab> createState() => _HodProposalsTabState();
}

class _HodProposalsTabState extends ConsumerState<_HodProposalsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _statusFilter = 'ALL';
  static const _statuses = [
    'ALL',
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED',
    'SUSPENDED',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _transition(int proposalId, String targetState) async {
    try {
      await ref
          .read(hodRepositoryProvider)
          .transitionProposalState(proposalId, targetState);
      ref.invalidate(hodProposalsFilteredProvider(_statusFilter));
      ref.invalidate(hodEnhancedStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Proposal → $targetState ✓')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveOpenLetter(int id) async {
    try {
      await ref.read(hodRepositoryProvider).updateOpenLetter(id, 'APPROVED');
      ref.invalidate(hodProposalsFilteredProvider(_statusFilter));
      ref.invalidate(hodOpenLettersProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open letter approved — proposal forwarded to company ✓',
            ),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectOpenLetter(int id) async {
    // Ask for a rejection reason first
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Reject Open Letter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for the student (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'Reason…',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(hodRepositoryProvider)
          .updateOpenLetter(id, 'REJECTED', reason: reasonCtrl.text.trim());
      ref.invalidate(hodProposalsFilteredProvider(_statusFilter));
      ref.invalidate(hodOpenLettersProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Open letter rejected — student notified'),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showProposalDetail(Map<String, dynamic> p, bool isDark) {
    final id = _parseInt(p['id']);
    final status = (p['status'] ?? 'PENDING').toString();
    final isOpenLetter = (p['proposal_type'] ?? '').toString() == 'Open_Letter';

    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: EdgeInsets.all(
          responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Proposal Details',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text('Status: $status', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (isOpenLetter && status == 'PENDING') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _rejectOpenLetter(id);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _approveOpenLetter(id);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Approve → Forward'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (status == 'PENDING')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _transition(id, 'CANCELLED');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel Proposal'),
                  ),
                ),
              if (status == 'REJECTED' || status == 'CANCELLED')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: const Text('Resend (New Proposal)'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proposalsAsync = ref.watch(
      hodProposalsFilteredProvider(_statusFilter),
    );
    final openLettersAsync = ref.watch(hodOpenLettersProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              ModernSliverAppBar(
                title: 'Proposals',
                subtitle: 'Proposal Pipeline',
                profileName:
                    ref.watch(userProfileProvider).value?.fullName ?? 'HOD',
                gradient: const [Color(0xFFf857a6), Color(0xFFff5858)],
                backgroundIcon: Icons.send_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: const Color(0xFFf857a6),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFFf857a6),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    tabs: [
                      const Tab(text: 'All Proposals'),
                      Tab(
                        child: openLettersAsync.maybeWhen(
                          data: (letters) {
                            final pending = letters
                                .where((l) => (l['status'] ?? '') == 'PENDING')
                                .length;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Open Letters'),
                                if (pending > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$pending',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                          orElse: () => const Text('Open Letters'),
                        ),
                      ),
                    ],
                  ),
                  isDark,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Tab 1: All Proposals ──────────────────────────────────────
                Column(
                  children: [
                    // Status filter chips
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statuses.map((s) {
                            final sel = _statusFilter == s;
                            return GestureDetector(
                              onTap: () => setState(() => _statusFilter = s),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFFf857a6)
                                      : (isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFFf857a6)
                                        : Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: sel ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => ref.invalidate(
                          hodProposalsFilteredProvider(_statusFilter),
                        ),
                        child: proposalsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Error: $e')),
                          data: (proposals) {
                            if (proposals.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.work_off_rounded,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No proposals',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                8,
                                24,
                                120,
                              ),
                              itemCount: proposals.length,
                              itemBuilder: (ctx, i) =>
                                  _buildProposalCard(proposals[i], isDark),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Tab 2: Open Letters ───────────────────────────────────────
                RefreshIndicator(
                  onRefresh: () async => ref.invalidate(hodOpenLettersProvider),
                  child: openLettersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (letters) {
                      if (letters.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No open letter requests',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Students can submit open letter requests\nfrom their Placements tab.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                        itemCount: letters.length,
                        itemBuilder: (ctx, i) =>
                            _buildOpenLetterCard(letters[i], isDark),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // FAB only on All Proposals tab
          Positioned(
            bottom: 90,
            right: 24,
            child: AnimatedBuilder(
              animation: _tabCtrl,
              builder: (_, __) => _tabCtrl.index == 0
                  ? FloatingActionButton.extended(
                      heroTag: 'hod_proposals_fab',
                      onPressed: () =>
                          showResponsiveSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (ctx) => _SendProposalSheet(
                              studentId: 0,
                              studentName: 'Select Student',
                            ),
                          ).then(
                            (_) => ref.invalidate(
                              hodProposalsFilteredProvider(_statusFilter),
                            ),
                          ),
                      backgroundColor: const Color(0xFFf857a6),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text(
                        'New Proposal',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenLetterCard(Map<String, dynamic> p, bool isDark) {
    final student = p['student'] as Map<String, dynamic>? ?? {};
    final studentUser = student['user'] as Map<String, dynamic>? ?? {};
    final company = p['company'] as Map<String, dynamic>? ?? {};
    final status = (p['status'] ?? 'PENDING').toString();
    final submittedAt = p['submitted_at']?.toString();
    final coverLetter = p['expected_outcomes']?.toString() ?? '';
    final id = _parseInt(p['id']);

    Color statusColor = status == 'APPROVED'
        ? Colors.green
        : status == 'REJECTED'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == 'PENDING'
              ? Colors.orange.withOpacity(0.3)
              : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.04)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.withOpacity(0.8), Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mail_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentUser['full_name']?.toString() ?? 'Student',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '→ ${company['name']?.toString() ?? 'Company'}',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    if (submittedAt != null)
                      Text(
                        timeago.format(
                          DateTime.tryParse(submittedAt) ?? DateTime.now(),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (coverLetter.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                coverLetter.length > 120
                    ? '${coverLetter.substring(0, 120)}…'
                    : coverLetter,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (status == 'PENDING') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectOpenLetter(id),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _approveOpenLetter(id),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> p, bool isDark) {
    final student = p['student'] as Map<String, dynamic>? ?? {};
    final studentUser = student['user'] as Map<String, dynamic>? ?? {};
    final company = p['company'] as Map<String, dynamic>? ?? {};
    final status = (p['status'] ?? 'PENDING').toString();
    final type = (p['proposal_type'] ?? '').toString();
    final submittedAt = p['submitted_at']?.toString();
    final isOpenLetter = type == 'Open_Letter';

    Color statusColor = status == 'APPROVED'
        ? Colors.green
        : status == 'REJECTED'
        ? Colors.red
        : status == 'CANCELLED'
        ? Colors.grey
        : status == 'SUSPENDED'
        ? Colors.orange.shade800
        : Colors.orange;

    return GestureDetector(
      onTap: () => _showProposalDetail(p, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.8), statusColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOpenLetter ? Icons.mail_rounded : Icons.work_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentUser['full_name']?.toString() ?? 'Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    company['name']?.toString() ?? 'Company',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  if (submittedAt != null)
                    Text(
                      timeago.format(
                        DateTime.tryParse(submittedAt) ?? DateTime.now(),
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isOpenLetter) const SizedBox(height: 4),
                if (isOpenLetter)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Open Letter',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HodTrackingTab extends ConsumerStatefulWidget {
  const _HodTrackingTab();
  @override
  ConsumerState<_HodTrackingTab> createState() => _HodTrackingTabState();
}

class _HodTrackingTabState extends ConsumerState<_HodTrackingTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _forceEnd(int placementId, String studentName) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Force End — $studentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will terminate the internship. Enter a reason:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'Reason…',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Force End'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(hodRepositoryProvider)
          .forceEndPlacement(placementId, reasonCtrl.text.trim());
      ref.invalidate(hodPlacementsProvider(null));
      ref.invalidate(hodPlacementsProvider('ACTIVE'));
      ref.invalidate(hodEnhancedStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Placement terminated')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAsync = ref.watch(hodPlacementsProvider(null));

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          ModernSliverAppBar(
            title: 'Tracking',
            subtitle: 'Placement Management',
            profileName:
                ref.watch(userProfileProvider).value?.fullName ?? 'HOD',
            gradient: const [Color(0xFF1fa2ff), Color(0xFF12d8fa)],
            backgroundIcon: Icons.track_changes_rounded,
          ),
          SliverToBoxAdapter(
            child: allAsync.maybeWhen(
              data: (all) {
                final active = all.where((p) => p['status'] == 'ACTIVE').length;
                final completed = all
                    .where((p) => p['status'] == 'COMPLETED')
                    .length;
                final failed = all
                    .where((p) => p['status'] == 'TERMINATED')
                    .length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      _summaryChip('Active', active, Colors.green),
                      const SizedBox(width: 10),
                      _summaryChip('Completed', completed, Colors.blue),
                      const SizedBox(width: 10),
                      _summaryChip('Failed', failed, Colors.red),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverTabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: const Color(0xFF1fa2ff),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1fa2ff),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Failed'),
                ],
              ),
              isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildPlacementList('ACTIVE', isDark),
            _buildPlacementList('COMPLETED', isDark),
            _buildPlacementList('TERMINATED', isDark),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementList(String status, bool isDark) {
    final placementsAsync = ref.watch(hodPlacementsProvider(status));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(hodPlacementsProvider(status));
        ref.invalidate(hodPlacementsProvider(null));
      },
      child: placementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (placements) {
          if (placements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_off_rounded,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No ${status.toLowerCase()} placements',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
            itemCount: placements.length,
            itemBuilder: (ctx, i) =>
                _buildPlacementCard(placements[i], status, isDark),
          );
        },
      ),
    );
  }

  Widget _buildPlacementCard(
    Map<String, dynamic> p,
    String status,
    bool isDark,
  ) {
    final id = _parseInt(p['id']);
    final studentName = p['studentName']?.toString() ?? 'Student';
    final companyName = p['companyName']?.toString() ?? 'Company';
    final startDate = p['startDate']?.toString();
    final endDate = p['endDate']?.toString();
    final color = status == 'ACTIVE'
        ? Colors.green
        : status == 'COMPLETED'
        ? Colors.blue
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      companyName,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    if (startDate != null)
                      Text(
                        'Started: ${startDate.substring(0, 10)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    if (endDate != null)
                      Text(
                        'Ended: ${endDate.substring(0, 10)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (status == 'ACTIVE')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _forceEnd(id, studentName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Force End'),
              ),
            )
          else if (status == 'TERMINATED')
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    ref.read(dashboardIndexProvider.notifier).state = 2,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('Reassign Student'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1fa2ff),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HodReportsTab extends ConsumerStatefulWidget {
  const _HodReportsTab();
  @override
  ConsumerState<_HodReportsTab> createState() => _HodReportsTabState();
}

class _HodReportsTabState extends ConsumerState<_HodReportsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _attendanceFilter = 'ALL';
  int? _weekFilter;
  final _weekCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _weekCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(hodReportsSummaryProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          ModernSliverAppBar(
            title: 'Reports',
            subtitle: 'Department Monitoring',
            profileName:
                ref.watch(userProfileProvider).value?.fullName ?? 'HOD',
            gradient: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
            backgroundIcon: Icons.description_rounded,
          ),
          SliverToBoxAdapter(
            child: summaryAsync.maybeWhen(
              data: (summary) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _buildSummaryCard(summary, isDark),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverTabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: const Color(0xFFa18cd1),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFa18cd1),
                tabs: const [
                  Tab(text: 'Weekly Reports'),
                  Tab(text: 'Final Reports'),
                ],
              ),
              isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildWeeklyReportsView(isDark),
            _buildFinalReportsView(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary, bool isDark) {
    final attendance = summary['attendance'] as Map<String, dynamic>? ?? {};
    final present = _parseInt(attendance['PRESENT']);
    final absent = _parseInt(attendance['ABSENT']);
    final late = _parseInt(attendance['LATE']);
    final avgTech = summary['averageTechnicalScore'];
    final avgSoft = summary['averageSoftSkillScore'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Department Summary',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem(
                'Total Reports',
                '${_parseInt(summary['totalWeeklyReports'])}',
                Colors.purple,
              ),
              _summaryItem('Present', '$present', Colors.green),
              _summaryItem('Absent', '$absent', Colors.red),
              _summaryItem('Late', '$late', Colors.orange),
            ],
          ),
          if (avgTech != null || avgSoft != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (avgTech != null)
                  _summaryItem(
                    'Avg Tech',
                    '${(avgTech as num).toStringAsFixed(1)}',
                    Colors.blue,
                  ),
                if (avgSoft != null)
                  _summaryItem(
                    'Avg Soft',
                    '${(avgSoft as num).toStringAsFixed(1)}',
                    Colors.teal,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReportsView(bool isDark) {
    final filter = WeeklyReportFilter(
      weekNumber: _weekFilter,
      attendanceStatus: _attendanceFilter == 'ALL' ? null : _attendanceFilter,
    );
    final reportsAsync = ref.watch(hodWeeklyReportsProvider(filter));
    const statuses = ['ALL', 'PRESENT', 'ABSENT', 'LATE'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: statuses.map((s) {
                      final sel = _attendanceFilter == s;
                      return GestureDetector(
                        onTap: () => setState(() => _attendanceFilter = s),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFa18cd1)
                                : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFFa18cd1)
                                  : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              color: sel ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _weekCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Wk',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      setState(() => _weekFilter = int.tryParse(v)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(hodWeeklyReportsProvider(filter)),
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (reports) {
                if (reports.isEmpty)
                  return Center(
                    child: Text(
                      'No reports',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                  itemCount: reports.length,
                  itemBuilder: (ctx, i) {
                    final r = reports[i];
                    final name = r['studentName']?.toString() ?? 'Student';
                    final week = r['weekNumber'];
                    final att = r['attendanceStatus']?.toString() ?? '';
                    final attColor = att == 'PRESENT'
                        ? Colors.green
                        : att == 'ABSENT'
                        ? Colors.red
                        : Colors.orange;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                                if (week != null)
                                  Text(
                                    'Week $week',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: attColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              att,
                              style: TextStyle(
                                color: attColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalReportsView(bool isDark) {
    final reportsAsync = ref.watch(hodReportsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(hodReportsProvider),
      child: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reports) {
          if (reports.isEmpty)
            return Center(
              child: Text(
                'No final reports',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            );
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
            itemCount: reports.length,
            itemBuilder: (ctx, i) {
              final r = reports[i];
              final id = _parseInt(r['id']);
              final student = r['student'] as Map<String, dynamic>? ?? {};
              final studentUser =
                  student['user'] as Map<String, dynamic>? ?? {};
              final name = studentUser['full_name']?.toString() ?? 'Student';
              final pdfUrl = r['pdf_url']?.toString();
              final stamped = _parseBool(r['stamped']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.black.withOpacity(0.04),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_rounded,
                      color: Colors.purple,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          if (stamped)
                            const Text(
                              'Stamped ✓',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.download_rounded,
                        color: pdfUrl != null && pdfUrl.isNotEmpty
                            ? Colors.purple
                            : Colors.grey.shade300,
                      ),
                      onPressed: pdfUrl != null && pdfUrl.isNotEmpty
                          ? () async {
                              final uri = Uri.parse(pdfUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Unable to open report.'),
                                    ),
                                  );
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

