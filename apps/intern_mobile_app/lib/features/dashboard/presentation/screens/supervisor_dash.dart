part of 'dashboards.dart';

class _SupervisorOverviewTab extends ConsumerStatefulWidget {
  const _SupervisorOverviewTab();
  @override
  ConsumerState<_SupervisorOverviewTab> createState() =>
      _SupervisorOverviewTabState();
}

class _SupervisorOverviewTabState
    extends ConsumerState<_SupervisorOverviewTab> {
  // ── Navigate to Management tab ─────────────────────────────────────────────
  void _goToManagement([int subTab = 0]) {
    ref.read(dashboardIndexProvider.notifier).state = 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashAsync = ref.watch(supervisorDashboardProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(supervisorDashboardProvider);
          ref.invalidate(supervisorStatsProvider);
        },
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) => dashAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load dashboard',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(supervisorDashboardProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (dash) => CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                ModernSliverAppBar(
                  title: 'Dashboard',
                  subtitle: profile.fullName,
                  profileName: profile.fullName,
                  gradient: [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
                  backgroundIcon: Icons.dashboard_rounded,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── 1. ALERTS ──────────────────────────────────────────
                      _buildAlerts(context, dash, isDark),

                      // ── 2. METRICS ─────────────────────────────────────────
                      const SizedBox(height: 24),
                      _sectionHeader(theme, 'Overview'),
                      const SizedBox(height: 12),
                      _buildMetricsGrid(context, dash.stats, isDark),

                      // ── 3. QUICK ACTIONS ───────────────────────────────────
                      const SizedBox(height: 24),
                      _sectionHeader(theme, 'Quick Actions'),
                      const SizedBox(height: 12),
                      _buildQuickActions(context, dash, isDark),

                      // ── 4. STUDENTS SNAPSHOT ───────────────────────────────
                      if (dash.studentsSummary.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionHeader(theme, 'Students Snapshot'),
                        const SizedBox(height: 12),
                        _buildStudentsSnapshot(
                          context,
                          dash.studentsSummary,
                          isDark,
                        ),
                      ],

                      // ── 5. ACTIVITY OVERVIEW ───────────────────────────────
                      const SizedBox(height: 24),
                      _sectionHeader(theme, 'Activity Overview'),
                      const SizedBox(height: 12),
                      _buildActivityOverview(context, dash, isDark),

                      // ── 6. RECENT ACTIVITY FEED ────────────────────────────
                      if (dash.recentActivity.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionHeader(theme, 'Recent Activity'),
                        const SizedBox(height: 12),
                        _buildActivityFeed(
                          context,
                          dash.recentActivity,
                          isDark,
                        ),
                      ],

                      // ── 7. DEADLINES ───────────────────────────────────────
                      if (dash.deadlines.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionHeader(theme, 'Upcoming Deadlines'),
                        const SizedBox(height: 12),
                        _buildDeadlines(context, dash.deadlines, isDark),
                      ],

                      // ── All clear state ────────────────────────────────────
                      if (dash.stats.pendingPlans == 0 &&
                          dash.stats.pendingProposals == 0 &&
                          dash.stats.missedCheckins == 0) ...[
                        const SizedBox(height: 24),
                        _buildAllClearCard(context, isDark),
                      ],
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

  Widget _sectionHeader(ThemeData theme, String title) => Text(
    title,
    style: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: -0.3,
    ),
  );

  // ── 1. ALERTS ──────────────────────────────────────────────────────────────
  Widget _buildAlerts(
    BuildContext context,
    SupervisorDashboardData dash,
    bool isDark,
  ) {
    final alerts = <_AlertData>[];
    if (dash.stats.pendingPlans > 0)
      alerts.add(
        _AlertData(
          Icons.assignment_late_rounded,
          '${dash.stats.pendingPlans} plan${dash.stats.pendingPlans == 1 ? '' : 's'} waiting for review',
          Colors.orange,
          () => _goToManagement(),
        ),
      );
    if (dash.stats.pendingProposals > 0)
      alerts.add(
        _AlertData(
          Icons.inbox_rounded,
          '${dash.stats.pendingProposals} proposal${dash.stats.pendingProposals == 1 ? '' : 's'} pending approval',
          Colors.purple,
          () => _goToManagement(),
        ),
      );
    if (dash.stats.missedCheckins > 0)
      alerts.add(
        _AlertData(
          Icons.warning_amber_rounded,
          '${dash.stats.missedCheckins} student${dash.stats.missedCheckins == 1 ? '' : 's'} missed today\'s check-in',
          Colors.red,
          () => ref.read(dashboardIndexProvider.notifier).state = 1,
        ),
      );
    if (dash.deadlines.isNotEmpty)
      alerts.add(
        _AlertData(
          Icons.schedule_rounded,
          '${dash.deadlines.length} deadline${dash.deadlines.length == 1 ? '' : 's'} approaching',
          Colors.blue,
          () {},
        ),
      );
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      children: alerts.map((a) => _AlertCard(data: a, isDark: isDark)).toList(),
    );
  }

  // ── 2. METRICS GRID ────────────────────────────────────────────────────────
  Widget _buildMetricsGrid(
    BuildContext context,
    SupervisorStats stats,
    bool isDark,
  ) {
    final metrics = [
      _MetricData(
        'Assigned',
        stats.totalStudents,
        Icons.people_rounded,
        Colors.blue,
        () => ref.read(dashboardIndexProvider.notifier).state = 1,
      ),
      _MetricData(
        'Proposals',
        stats.pendingProposals,
        Icons.inbox_rounded,
        Colors.purple,
        () => _goToManagement(),
      ),
      _MetricData(
        'Plan Reviews',
        stats.pendingPlans,
        Icons.assignment_rounded,
        Colors.orange,
        () => _goToManagement(),
      ),
      _MetricData(
        'Missed Today',
        stats.missedCheckins,
        Icons.event_busy_rounded,
        Colors.red,
        () => ref.read(dashboardIndexProvider.notifier).state = 1,
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: metrics
          .map((m) => _MetricCard(data: m, isDark: isDark))
          .toList(),
    );
  }

  // ── 3. QUICK ACTIONS ───────────────────────────────────────────────────────
  Widget _buildQuickActions(
    BuildContext context,
    SupervisorDashboardData dash,
    bool isDark,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (dash.stats.pendingProposals > 0)
          _QuickActionChip(
            label: 'Review Proposals',
            icon: Icons.inbox_rounded,
            color: Colors.purple,
            onTap: () => _goToManagement(),
          ),
        if (dash.stats.pendingPlans > 0)
          _QuickActionChip(
            label: 'Review Plans',
            icon: Icons.assignment_rounded,
            color: Colors.orange,
            onTap: () => _goToManagement(),
          ),
        _QuickActionChip(
          label: 'Submit Evaluation',
          icon: Icons.star_rounded,
          color: Colors.amber.shade700,
          onTap: () => ref.read(dashboardIndexProvider.notifier).state = 1,
        ),
        _QuickActionChip(
          label: 'Create Team',
          icon: Icons.groups_rounded,
          color: Colors.teal,
          onTap: () => ref.read(dashboardIndexProvider.notifier).state = 1,
        ),
      ],
    );
  }

  // ── 4. STUDENTS SNAPSHOT ───────────────────────────────────────────────────
  Widget _buildStudentsSnapshot(
    BuildContext context,
    List<SupervisorStudentSummary> students,
    bool isDark,
  ) {
    return Column(
      children: students
          .take(5)
          .map(
            (s) => _StudentSnapshotRow(
              student: s,
              isDark: isDark,
              onTap: () => ref.read(dashboardIndexProvider.notifier).state = 1,
            ),
          )
          .toList(),
    );
  }

  // ── 5. ACTIVITY OVERVIEW ───────────────────────────────────────────────────
  Widget _buildActivityOverview(
    BuildContext context,
    SupervisorDashboardData dash,
    bool isDark,
  ) {
    final total = dash.stats.totalStudents;
    final atRisk = dash.studentsSummary
        .where((s) => s.status == 'AT_RISK')
        .length;
    final inactive = dash.studentsSummary
        .where((s) => s.status == 'INACTIVE')
        .length;
    final active = total - atRisk - inactive;
    final checkinPct = total > 0
        ? ((total - dash.stats.missedCheckins) / total).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActivityPill('Active', active, Colors.green),
              const SizedBox(width: 8),
              _ActivityPill('At Risk', atRisk, Colors.orange),
              const SizedBox(width: 8),
              _ActivityPill('Inactive', inactive, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-in rate today',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                '${(checkinPct * 100).toInt()}%',
                style: TextStyle(
                  color: checkinPct > 0.7 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: checkinPct,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                checkinPct > 0.7 ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. ACTIVITY FEED ───────────────────────────────────────────────────────
  Widget _buildActivityFeed(
    BuildContext context,
    List<SupervisorActivityItem> items,
    bool isDark,
  ) {
    return Column(
      children: items.take(6).map((item) {
        final isPlan = item.type == 'PLAN';
        final color = item.status == 'APPROVED'
            ? Colors.green
            : item.status == 'REJECTED'
            ? Colors.red
            : Colors.orange;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPlan ? Icons.assignment_rounded : Icons.inbox_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timeago.format(item.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── 7. DEADLINES ───────────────────────────────────────────────────────────
  Widget _buildDeadlines(
    BuildContext context,
    List<SupervisorDeadline> deadlines,
    bool isDark,
  ) {
    return Column(
      children: deadlines.map((d) {
        final isUrgent = (d.daysLeft ?? 99) <= 3;
        final color = isUrgent
            ? Colors.red
            : (d.daysLeft ?? 99) <= 7
            ? Colors.orange
            : Colors.blue;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUrgent
                  ? Colors.red.withOpacity(0.3)
                  : (isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  d.type == 'EVALUATION_DUE'
                      ? Icons.star_rounded
                      : Icons.description_rounded,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      d.type == 'EVALUATION_DUE'
                          ? 'Evaluation due'
                          : 'Report due',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  d.daysLeft != null ? '${d.daysLeft}d left' : 'Due soon',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAllClearCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(
        responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
      ),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All caught up!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No pending tasks right now. Great work!',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupervisorStudentsTab extends ConsumerWidget {
  const _SupervisorStudentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Material(
        color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF11998e).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38ef7d).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                ModernSliverAppBar(
                  title: 'Interns',
                  subtitle: 'Manage Assigned List',
                  profileName:
                      ref.watch(userProfileProvider).value?.fullName ??
                      'Supervisor',
                  gradient: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                  backgroundIcon: Icons.people_rounded,
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverTabBarDelegate(
                    TabBar(
                      tabs: const [
                        Tab(text: 'Individual List'),
                        Tab(text: 'Group Teams'),
                      ],
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: theme.colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                    ),
                    isDark,
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _buildStudentsList(context, ref, isDark, theme),
                  const _SupervisorTeamsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ThemeData theme,
  ) {
    final studentsAsync = ref.watch(supervisorStudentsProvider);
    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text('Error: $err', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(supervisorStudentsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (students) => students.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No students assigned yet.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(supervisorStudentsProvider),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildStudentCard(
                          context,
                          students[index],
                          isDark,
                          theme,
                          ref,
                        ),
                        childCount: students.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    SupervisorStudent student,
    bool isDark,
    ThemeData theme,
    WidgetRef ref,
  ) {
    // Derive real status color
    final statusColor = student.internshipStatus == 'PLACED'
        ? Colors.green
        : student.internshipStatus == 'COMPLETED'
        ? Colors.blue
        : Colors.orange;
    final statusLabel = student.internshipStatus;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showStudentManagement(context, student, ref),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor.withOpacity(0.15),
                    child: Text(
                      student.fullName[0],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          student.email,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        if (student.department != null)
                          Text(
                            student.department!,
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
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _miniStat(
                      context,
                      'University',
                      student.universityName.length > 12
                          ? '${student.universityName.substring(0, 12)}…'
                          : student.universityName,
                    ),
                  ),
                  Expanded(
                    child: _miniStat(
                      context,
                      'Project',
                      student.projectName ?? 'Not assigned',
                    ),
                  ),
                  Expanded(
                    child: _miniStat(
                      context,
                      'Started',
                      '${student.startDate.day}/${student.startDate.month}/${student.startDate.year}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  void _showStudentManagement(
    BuildContext context,
    SupervisorStudent student,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              student.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              student.universityName,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _mgmtAction(
              context,
              Icons.assignment_turned_in_rounded,
              'Review Weekly Plans',
              'Review and provide feedback',
              () {
                Navigator.pop(ctx);
                ref.read(dashboardIndexProvider.notifier).state =
                    2; // Go to Workflow
              },
            ),
            const SizedBox(height: 16),
            _mgmtAction(
              context,
              Icons.group_add_rounded,
              'Assign Team',
              'Add student to a project group',
              () {
                Navigator.pop(ctx);
                _showAssignTeamDialog(context, student, ref);
              },
            ),
            const SizedBox(height: 16),
            _mgmtAction(
              context,
              Icons.star_rounded,
              'Final Evaluation',
              'Submit technical & soft skills grade',
              () {
                Navigator.pop(ctx);
                _showEvaluationDialog(context, student, ref);
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEvaluationDialog(
    BuildContext context,
    SupervisorStudent student,
    WidgetRef ref,
  ) {
    final technicalSkillsCtrl = TextEditingController();
    final problemSolvingCtrl = TextEditingController();
    final communicationCtrl = TextEditingController();
    final teamCollaborationCtrl = TextEditingController();
    final timeManagementCtrl = TextEditingController();
    final adaptabilityCtrl = TextEditingController();
    final professionalismCtrl = TextEditingController();
    final initiativeCreativityCtrl = TextEditingController();
    final attendancePunctualityCtrl = TextEditingController();
    final taskCompletionQualityCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    Widget scoreField(TextEditingController controller, String label) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Evaluate ${student.fullName}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                scoreField(technicalSkillsCtrl, 'Technical Skills (0-100)'),
                scoreField(problemSolvingCtrl, 'Problem Solving (0-100)'),
                scoreField(communicationCtrl, 'Communication (0-100)'),
                scoreField(teamCollaborationCtrl, 'Team Collaboration (0-100)'),
                scoreField(timeManagementCtrl, 'Time Management (0-100)'),
                scoreField(adaptabilityCtrl, 'Adaptability (0-100)'),
                scoreField(professionalismCtrl, 'Professionalism (0-100)'),
                scoreField(initiativeCreativityCtrl, 'Initiative & Creativity (0-100)'),
                scoreField(attendancePunctualityCtrl, 'Attendance & Punctuality (0-100)'),
                scoreField(taskCompletionQualityCtrl, 'Task Completion Quality (0-100)'),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Final Comments'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(supervisorRepositoryProvider).submitEvaluation(
                    studentId: student.id,
                    technicalSkills: double.parse(technicalSkillsCtrl.text),
                    problemSolving: double.parse(problemSolvingCtrl.text),
                    communication: double.parse(communicationCtrl.text),
                    teamCollaboration: double.parse(teamCollaborationCtrl.text),
                    timeManagement: double.parse(timeManagementCtrl.text),
                    adaptability: double.parse(adaptabilityCtrl.text),
                    professionalism: double.parse(professionalismCtrl.text),
                    initiativeCreativity: double.parse(initiativeCreativityCtrl.text),
                    attendancePunctuality: double.parse(attendancePunctualityCtrl.text),
                    taskCompletionQuality: double.parse(taskCompletionQualityCtrl.text),
                    comments: commentCtrl.text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Submit Evaluation'),
          ),
        ],
      ),
    );
  }

  void _showAssignTeamDialog(
    BuildContext context,
    SupervisorStudent student,
    WidgetRef ref,
  ) {
    final teamsAsync = ref.watch(supervisorTeamsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign to Team'),
        content: teamsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('Error loading teams: $err'),
          data: (teams) => Column(
            mainAxisSize: MainAxisSize.min,
            children: teams
                .map(
                  (team) => ListTile(
                    title: Text(team.name),
                    trailing: const Icon(Icons.add_rounded),
                    onTap: () async {
                      await ref
                          .read(supervisorRepositoryProvider)
                          .addTeamMember(team.id, student.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                      ref.invalidate(supervisorTeamsProvider);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _mgmtAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _SupervisorManagementTab extends ConsumerWidget {
  const _SupervisorManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Material(
        color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            ModernSliverAppBar(
              title: 'Management',
              subtitle: 'Approvals & Tracking',
              profileName:
                  ref.watch(userProfileProvider).value?.fullName ??
                  'Supervisor',
              gradient: [const Color(0xFF6a11cb), const Color(0xFF2575fc)],
              backgroundIcon: Icons.fact_check_rounded,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverTabBarDelegate(
                TabBar(
                  tabs: const [
                    Tab(text: 'Workflows'),
                    Tab(text: 'Assignments'),
                    Tab(text: 'Tracking'),
                  ],
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                ),
                isDark,
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _SupervisorWorkflowTabContent(),
              _SupervisorAssignmentScreen(),
              _SupervisorTrackingTabContent(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupervisorWorkflowTabContent extends ConsumerStatefulWidget {
  const _SupervisorWorkflowTabContent();
  @override
  ConsumerState<_SupervisorWorkflowTabContent> createState() =>
      _SupervisorWorkflowTabContentState();
}

class _SupervisorWorkflowTabContentState
    extends ConsumerState<_SupervisorWorkflowTabContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final proposalsAsync = ref.watch(supervisorIncomingProposalsProvider);
    final plansAsync = ref.watch(supervisorPendingPlansProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(
            responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader(theme, 'Placement Proposals'),
              const SizedBox(height: 16),
              proposalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (proposals) => proposals.isEmpty
                    ? const Center(child: Text('No pending proposals'))
                    : Column(
                        children: proposals
                            .map<Widget>(
                              (p) => _buildProposalWorkflowCard(
                                context,
                                p,
                                isDark,
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, 'Weekly Plan Reviews'),
              const SizedBox(height: 16),
              plansAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (plans) => plans.isEmpty
                    ? const Center(child: Text('No pending plans'))
                    : Column(
                        children: plans
                            .map<Widget>(
                              (p) => _buildPlanWorkflowCard(context, p, isDark),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProposalWorkflowCard(
    BuildContext context,
    InternshipProposal p,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(p.studentName[0])),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      p.universityName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.type,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
          if (p.durationWeeks != null)
            Text(
              'Duration: ${p.durationWeeks} weeks',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          const SizedBox(height: 12),
          // View Details button — no inline approve/reject
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showProposalDetails(context, p),
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('View Details & Decide'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanWorkflowCard(
    BuildContext context,
    WeeklyPlan p,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week ${p.weekNumber} Plan',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      p.title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          if (p.files.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  size: 13,
                  color: Colors.teal,
                ),
                const SizedBox(width: 4),
                Text(
                  '${p.files.length} attachment${p.files.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // View Details button — no inline approve/reject
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPlanDetails(context, p),
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('View Details & Decide'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProposalDetails(BuildContext context, InternshipProposal p) {
    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ReviewDetailsSheet(
        title: 'Placement Proposal',
        subtitle: p.studentName,
        badge: 'PENDING',
        badgeColor: Colors.orange,
        fields: [
          _ReviewField('Student', p.studentName, Icons.person_rounded),
          _ReviewField('University', p.universityName, Icons.school_rounded),
          _ReviewField('Proposal Type', p.type, Icons.description_rounded),
          if (p.durationWeeks != null)
            _ReviewField(
              'Duration',
              '${p.durationWeeks} weeks',
              Icons.schedule_rounded,
            ),
          _ReviewField(
            'Submitted',
            timeago.format(p.submittedAt),
            Icons.calendar_today_rounded,
          ),
        ],
        description: p.outcomes,
        descriptionLabel: 'Expected Outcomes',
        attachments: const [], // proposals don't have file attachments
        onApprove: () {
          Navigator.pop(ctx);
          _respond(p.id, true);
        },
        onReject: (reason) {
          Navigator.pop(ctx);
          _respondWithReason(p.id, false, reason);
        },
      ),
    );
  }

  void _showPlanDetails(BuildContext context, WeeklyPlan p) {
    final attachments = p.files
        .map(
          (f) => _ReviewAttachment(
            name: f.fileName,
            url: f.fileUrl,
            type: f.fileUrl.toLowerCase().endsWith('.pdf') ? 'pdf' : 'file',
          ),
        )
        .toList();

    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ReviewDetailsSheet(
        title: 'Week ${p.weekNumber} Plan',
        subtitle: p.title,
        badge: 'PENDING',
        badgeColor: Colors.orange,
        fields: [
          _ReviewField(
            'Week',
            'Week ${p.weekNumber}',
            Icons.calendar_view_week_rounded,
          ),
          _ReviewField(
            'Submitted',
            timeago.format(p.createdAt),
            Icons.calendar_today_rounded,
          ),
          if (p.hasFeedback)
            _ReviewField(
              'Previous Feedback',
              p.feedback!,
              Icons.feedback_rounded,
            ),
        ],
        description: p.objectives.isNotEmpty ? p.objectives : null,
        descriptionLabel: 'Plan Objectives',
        attachments: attachments,
        onApprove: () {
          Navigator.pop(ctx);
          _reviewPlan(p.id, true);
        },
        onReject: (reason) {
          Navigator.pop(ctx);
          _reviewPlanWithReason(p.id, false, reason);
        },
      ),
    );
  }

  Future<void> _respondWithReason(int id, bool approve, String reason) async {
    try {
      await ref
          .read(supervisorRepositoryProvider)
          .respondToProposal(
            id,
            approve: approve,
            reason: reason.isNotEmpty ? reason : null,
          );
      ref.invalidate(supervisorIncomingProposalsProvider);
      ref.invalidate(supervisorStatsProvider);
      ref.invalidate(supervisorStudentsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Proposal approved — student placed ✓'
                  : 'Proposal rejected',
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

  Future<void> _reviewPlanWithReason(
    int id,
    bool approve,
    String reason,
  ) async {
    try {
      await ref
          .read(supervisorRepositoryProvider)
          .reviewPlan(
            id,
            approve: approve,
            feedback: reason.isNotEmpty ? reason : null,
          );
      ref.invalidate(supervisorPendingPlansProvider);
      ref.invalidate(supervisorStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Plan approved ✓' : 'Plan rejected — student notified',
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

  Future<void> _respond(int id, bool approve) async {
    if (!approve) {
      // Ask for rejection reason
      final reasonCtrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Reject Proposal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Provide a reason for rejection (optional):'),
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
            .read(supervisorRepositoryProvider)
            .respondToProposal(
              id,
              approve: false,
              reason: reasonCtrl.text.trim(),
            );
        ref.invalidate(supervisorIncomingProposalsProvider);
        ref.invalidate(supervisorStatsProvider);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Proposal rejected')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      try {
        await ref
            .read(supervisorRepositoryProvider)
            .respondToProposal(id, approve: true);
        ref.invalidate(supervisorIncomingProposalsProvider);
        ref.invalidate(supervisorStatsProvider);
        ref.invalidate(supervisorStudentsProvider);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proposal approved — student placed ✓'),
            ),
          );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reviewPlan(int id, bool approve) async {
    if (!approve) {
      // Feedback is required for rejection
      final feedbackCtrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Reject Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Feedback is required when rejecting a plan:'),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackCtrl,
                decoration: const InputDecoration(
                  hintText: 'Feedback for student…',
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
              onPressed: () {
                if (feedbackCtrl.text.trim().length < 5) return; // min 5 chars
                Navigator.pop(d, true);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await ref
            .read(supervisorRepositoryProvider)
            .reviewPlan(id, approve: false, feedback: feedbackCtrl.text.trim());
        ref.invalidate(supervisorPendingPlansProvider);
        ref.invalidate(supervisorStatsProvider);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan rejected — student notified')),
          );
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      try {
        await ref
            .read(supervisorRepositoryProvider)
            .reviewPlan(id, approve: true);
        ref.invalidate(supervisorPendingPlansProvider);
        ref.invalidate(supervisorStatsProvider);
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Plan approved ✓')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _SupervisorTrackingTabContent extends ConsumerWidget {
  const _SupervisorTrackingTabContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final heatmapAsync = ref.watch(supervisorAttendanceHeatmapProvider);
    final reportsAsync = ref.watch(supervisorWeeklyReportsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(
            responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader(theme, 'Daily Check-ins'),
              const SizedBox(height: 16),
              heatmapAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (heatmap) =>
                    _buildAttendanceHeatmap(context, heatmap, isDark),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, 'Weekly Execution Reports'),
              const SizedBox(height: 16),
              reportsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (reports) => reports.isEmpty
                    ? const Center(child: Text('No reports submitted yet.'))
                    : Column(
                        children: reports
                            .map<Widget>(
                              (r) =>
                                  _buildReportTrackingCard(context, r, isDark),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceHeatmap(
    BuildContext context,
    AttendanceHeatmap heatmap,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Participation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Last 12 Months',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: heatmap.students.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final student = heatmap.students[index];
                return _buildStudentHeatmapCol(context, student, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeatmapCol(
    BuildContext context,
    StudentHeatmapData student,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          child: Text(
            student.fullName[0],
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 60,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(5, (i) {
              final active = student.submittedDates.length > (4 - i) * 2;
              return Container(
                margin: const EdgeInsets.all(2),
                width: 24,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? theme.colorScheme.primary.withOpacity(0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReportTrackingCard(
    BuildContext context,
    SupervisorAttendanceReport r,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
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
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Week ${r.weekNumber}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getReportColor(r.attendanceStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.attendanceStatus,
                  style: TextStyle(
                    color: _getReportColor(r.attendanceStatus),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (r.executionStatus != null) ...[
            const SizedBox(height: 16),
            const Text(
              'EXECUTION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
              ),
            ),
            Text(
              r.executionStatus!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Color _getReportColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return Colors.green;
      case 'ABSENT':
        return Colors.red;
      case 'LATE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _SupervisorTeamsTab extends ConsumerStatefulWidget {
  const _SupervisorTeamsTab();
  @override
  ConsumerState<_SupervisorTeamsTab> createState() =>
      _SupervisorTeamsTabState();
}

class _SupervisorTeamsTabState extends ConsumerState<_SupervisorTeamsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

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

  Future<void> _createProject() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '0');
    final skillsCtrl = TextEditingController();
    bool loading = false;
    await showDialog<void>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setS) => AlertDialog(
          title: const Text(
            'Create Project',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Capacity (0 = unlimited)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Required Skills (comma-separated)',
                    hintText: 'Flutter, Node.js',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setS(() => loading = true);
                      try {
                        final skills = skillsCtrl.text.trim().isEmpty
                            ? <String>[]
                            : skillsCtrl.text
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .toList();
                        await ref
                            .read(supervisorRepositoryProvider)
                            .createProject(
                              name: nameCtrl.text.trim(),
                              description: descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              capacity: int.tryParse(capCtrl.text.trim()) ?? 0,
                              requiredSkills: skills,
                            );
                        ref.invalidate(supervisorProjectsProvider);
                        if (d.mounted) Navigator.pop(d);
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Project created ✓')),
                          );
                      } catch (e) {
                        setS(() => loading = false);
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTeam() async {
    final nameCtrl = TextEditingController();
    int? selectedProjectId;
    bool loading = false;
    final projects = ref.read(supervisorProjectsProvider).value ?? [];
    await showDialog<void>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setS) => AlertDialog(
          title: const Text(
            'Create Team',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Team Name *',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              if (projects.isNotEmpty)
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Link to Project (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('No project'),
                    ),
                    ...projects.map(
                      (p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setS(() => selectedProjectId = v),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      setS(() => loading = true);
                      try {
                        await ref
                            .read(supervisorRepositoryProvider)
                            .createTeam(
                              nameCtrl.text.trim(),
                              projectId: selectedProjectId,
                            );
                        ref.invalidate(supervisorTeamsProvider);
                        if (d.mounted) Navigator.pop(d);
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Team created ✓')),
                          );
                      } catch (e) {
                        setS(() => loading = false);
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignFlow() async {
    final students = ref.read(supervisorStudentsProvider).value ?? [];
    final projects = ref.read(supervisorProjectsProvider).value ?? [];
    final teams = ref.read(supervisorTeamsProvider).value ?? [];
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No placed students available.')),
      );
      return;
    }
    final Set<int> selectedStudentIds = {};
    int? selectedProjectId;
    int? selectedTeamId;
    String teamName = '';
    bool createNewTeam = true;
    bool loading = false;
    await showResponsiveSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
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
                const SizedBox(height: 20),
                const Text(
                  'Assign Students',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select students, team, and project',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STEP 1: Students
                        _stepHeader('1', 'Select Students', Colors.blue),
                        const SizedBox(height: 8),
                        ...students.map(
                          (s) => CheckboxListTile(
                            value: selectedStudentIds.contains(s.id),
                            onChanged: (v) => setS(() {
                              if (v == true)
                                selectedStudentIds.add(s.id);
                              else
                                selectedStudentIds.remove(s.id);
                            }),
                            title: Text(
                              s.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              s.universityName,
                              style: const TextStyle(fontSize: 11),
                            ),
                            secondary: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Text(
                                s.fullName[0],
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // STEP 2: Team
                        _stepHeader('2', 'Team (optional)', Colors.purple),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setS(() => createNewTeam = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: createNewTeam
                                        ? Colors.purple
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'New Team',
                                      style: TextStyle(
                                        color: createNewTeam
                                            ? Colors.white
                                            : Colors.grey,
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
                                onTap: () => setS(() => createNewTeam = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !createNewTeam
                                        ? Colors.purple
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Existing',
                                      style: TextStyle(
                                        color: !createNewTeam
                                            ? Colors.white
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (createNewTeam)
                          TextField(
                            onChanged: (v) => setS(() => teamName = v),
                            decoration: const InputDecoration(
                              labelText: 'Team Name',
                              hintText: 'e.g. Alpha Team',
                              border: OutlineInputBorder(),
                            ),
                          )
                        else if (teams.isNotEmpty)
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: selectedTeamId,
                            decoration: const InputDecoration(
                              labelText: 'Select Team',
                              border: OutlineInputBorder(),
                            ),
                            items: teams
                                .map(
                                  (t) => DropdownMenuItem<int>(
                                    value: t.id,
                                    child: Text(
                                      '${t.name} (${t.members.length})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setS(() => selectedTeamId = v),
                          )
                        else
                          const Text(
                            'No teams yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 20),
                        // STEP 3: Project
                        _stepHeader(
                          '3',
                          'Link to Project (optional)',
                          Colors.teal,
                        ),
                        const SizedBox(height: 8),
                        if (projects.isEmpty)
                          const Text(
                            'No projects yet.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: selectedProjectId,
                            decoration: const InputDecoration(
                              labelText: 'Select Project',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('No project'),
                              ),
                              ...projects.map(
                                (p) => DropdownMenuItem<int>(
                                  value: p.id,
                                  child: Text(
                                    '${p.name} (${p.capacityLabel})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) => setS(() => selectedProjectId = v),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (selectedStudentIds.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Select at least one student.'),
                                ),
                              );
                              return;
                            }
                            if (createNewTeam && teamName.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter a team name.'),
                                ),
                              );
                              return;
                            }
                            if (!createNewTeam && selectedTeamId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Select an existing team.'),
                                ),
                              );
                              return;
                            }
                            setS(() => loading = true);
                            try {
                              final result = await ref
                                  .read(supervisorRepositoryProvider)
                                  .bulkAssign(
                                    studentIds: selectedStudentIds.toList(),
                                    teamId: createNewTeam
                                        ? null
                                        : selectedTeamId,
                                    teamName: createNewTeam
                                        ? teamName.trim()
                                        : null,
                                    projectId: selectedProjectId,
                                  );
                              ref.invalidate(supervisorTeamsProvider);
                              ref.invalidate(supervisorProjectsProvider);
                              ref.invalidate(supervisorStudentsProvider);
                              ref.invalidate(supervisorAssignmentsProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                              final assigned =
                                  (result['assignedStudents'] as List?)
                                      ?.length ??
                                  0;
                              final skipped =
                                  (result['skipped'] as List?)?.length ?? 0;
                              final teamN = result['team']?['name'] ?? '';
                              final projN = result['project']?['name'];
                              final msg =
                                  '$assigned student(s) assigned to "$teamN"${projN != null ? ' on "$projN"' : ''}${skipped > 0 ? ' ($skipped skipped)' : ''} ✓';
                              if (mounted)
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(msg)));
                            } catch (e) {
                              setS(() => loading = false);
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF11998e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Assign Students',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
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

  Widget _stepHeader(String num, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teamsAsync = ref.watch(supervisorTeamsProvider);
    final projectsAsync = ref.watch(supervisorProjectsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFF11998e),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF11998e),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Projects'),
                Tab(text: 'Teams'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Projects Tab ─────────────────────────────────────────────────
                RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(supervisorProjectsProvider),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            GestureDetector(
                              onTap: _createProject,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF11998e),
                                      Color(0xFF38ef7d),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF11998e,
                                      ).withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Create Project',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Define name, capacity & required skills',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            projectsAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(child: Text('Error: $e')),
                              data: (projects) {
                                if (projects.isEmpty)
                                  return Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.folder_open_rounded,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'No projects yet.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Tap above to create your first project.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                return Column(
                                  children: projects
                                      .map(
                                        (p) => Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.04)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withOpacity(
                                                      0.07,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.05,
                                                    ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.teal
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.folder_rounded,
                                                      color: Colors.teal,
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          p.name,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                fontSize: 15,
                                                              ),
                                                        ),
                                                        if (p.description !=
                                                            null)
                                                          Text(
                                                            p.description!,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 12,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: p.isFull
                                                          ? Colors.red
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                          : Colors.teal
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      p.capacityLabel,
                                                      style: TextStyle(
                                                        color: p.isFull
                                                            ? Colors.red
                                                            : Colors.teal,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (p
                                                  .requiredSkills
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: p.requiredSkills
                                                      .map(
                                                        (s) => Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 3,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue
                                                                .withOpacity(
                                                                  0.08,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            s,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .blue,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.people_rounded,
                                                    size: 13,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${p.memberCount} student${p.memberCount == 1 ? '' : 's'}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(
                                                    Icons.groups_rounded,
                                                    size: 13,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${p.teamCount} team${p.teamCount == 1 ? '' : 's'}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Teams Tab ────────────────────────────────────────────────────
                RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(supervisorTeamsProvider),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            GestureDetector(
                              onTap: _createTeam,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4568dc),
                                      Color(0xFFb06ab3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4568dc,
                                      ).withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Create Team',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Optionally link to a project',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            teamsAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(child: Text('Error: $e')),
                              data: (teams) {
                                if (teams.isEmpty)
                                  return Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.groups_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'No teams yet.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                return Column(
                                  children: teams
                                      .map(
                                        (team) => Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.04)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withOpacity(
                                                      0.07,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.05,
                                                    ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.groups_rounded,
                                                      color: Colors.purple,
                                                      size: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          team.name,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                fontSize: 15,
                                                              ),
                                                        ),
                                                        Text(
                                                          '${team.members.length} member${team.members.length == 1 ? '' : 's'}',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (team.projectName != null)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.teal
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        team.projectName!,
                                                        style: const TextStyle(
                                                          color: Colors.teal,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (team.members.isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: team.members
                                                      .map(
                                                        (m) => Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 3,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue
                                                                .withOpacity(
                                                                  0.08,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            m.fullName,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .blue,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupervisorSettingsTab extends ConsumerStatefulWidget {
  const _SupervisorSettingsTab();
  @override
  ConsumerState<_SupervisorSettingsTab> createState() =>
      _SupervisorSettingsTabState();
}

class _SupervisorSettingsTabState
    extends ConsumerState<_SupervisorSettingsTab> {
  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    await showDialog<void>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setS) => AlertDialog(
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match.'),
                          ),
                        );
                        return;
                      }
                      if (newCtrl.text.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Min 8 characters.')),
                        );
                        return;
                      }
                      setS(() => loading = true);
                      try {
                        await ref
                            .read(apiClientProvider)
                            .dio
                            .patch(
                              '/auth/change-password',
                              data: {
                                'currentPassword': currentCtrl.text,
                                'newPassword': newCtrl.text,
                              },
                            );
                        if (d.mounted) Navigator.pop(d);
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully ✓'),
                            ),
                          );
                      } catch (e) {
                        setS(() => loading = false);
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meAsync = ref.watch(supervisorMeProvider);
    final statsAsync = ref.watch(supervisorStatsProvider);
    final perfAsync = ref.watch(supervisorPerformanceProvider);
    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(supervisorMeProvider);
          ref.invalidate(supervisorStatsProvider);
          ref.invalidate(supervisorPerformanceProvider);
        },
        child: meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                Text('$e'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(supervisorMeProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (me) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ModernSliverAppBar(
                title: 'Profile',
                subtitle: 'Account & Settings',
                profileName: me.fullName,
                gradient: [const Color(0xFF8A2387), const Color(0xFFE94057)],
                backgroundIcon: Icons.person_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Identity
                    _ProfileCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8A2387), Color(0xFFE94057)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8A2387,
                                  ).withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                me.fullName.isNotEmpty
                                    ? me.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            me.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Colors.teal,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Supervisor',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            Icons.email_rounded,
                            'Email',
                            me.email,
                            isDark,
                          ),
                          if (me.phone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              Icons.phone_rounded,
                              'Phone',
                              me.phone,
                              isDark,
                            ),
                          ],
                          _InfoRow(
                            Icons.apartment_rounded,
                            'Company',
                            me.companyName,
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push(AppRoutes.accountSettings),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit Profile'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Work Info
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Work Information',
                      icon: Icons.business_rounded,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _ProfileCard(
                      isDark: isDark,
                      child: statsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text(
                          'Could not load',
                          style: TextStyle(color: Colors.grey),
                        ),
                        data: (stats) => Column(
                          children: [
                            _InfoRow(
                              Icons.people_rounded,
                              'Active Interns',
                              '${stats.totalStudents} student${stats.totalStudents == 1 ? '' : 's'}',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              Icons.inbox_rounded,
                              'Pending Proposals',
                              '${stats.pendingProposals}',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              Icons.assignment_rounded,
                              'Plans to Review',
                              '${stats.pendingPlans}',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              Icons.event_busy_rounded,
                              'Missed Check-ins Today',
                              '${stats.missedCheckins}',
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Performance
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Performance Summary',
                      icon: Icons.bar_chart_rounded,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 10),
                    perfAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => _ProfileCard(
                        isDark: isDark,
                        child: Center(
                          child: Text(
                            'No performance data',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      ),
                      data: (perf) {
                        final total =
                            (perf['totalStudentsSupervised'] as int?) ?? 0;
                        final completed =
                            (perf['completedInternships'] as int?) ?? 0;
                        final avgScore = perf['averageStudentScore'];
                        final proposalRate =
                            perf['proposalApprovalRate'] as int?;
                        final planRate = perf['planApprovalRate'] as int?;
                        final evals =
                            (perf['evaluationsSubmitted'] as int?) ?? 0;
                        if (total == 0 && evals == 0)
                          return _ProfileCard(
                            isDark: isDark,
                            child: const Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No performance data yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        return _ProfileCard(
                          isDark: isDark,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _PerfStat(
                                      'Total Supervised',
                                      '$total',
                                      Icons.people_rounded,
                                      Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _PerfStat(
                                      'Completed',
                                      '$completed',
                                      Icons.check_circle_rounded,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _PerfStat(
                                      'Avg Score',
                                      avgScore != null ? '$avgScore/100' : '--',
                                      Icons.star_rounded,
                                      Colors.amber.shade700,
                                    ),
                                  ),
                                  Expanded(
                                    child: _PerfStat(
                                      'Evaluations',
                                      '$evals',
                                      Icons.assignment_turned_in_rounded,
                                      Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              if (proposalRate != null || planRate != null) ...[
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                if (proposalRate != null) ...[
                                  _RateBar(
                                    'Proposal Approval Rate',
                                    proposalRate,
                                    Colors.teal,
                                    isDark,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (planRate != null)
                                  _RateBar(
                                    'Plan Approval Rate',
                                    planRate,
                                    Colors.orange,
                                    isDark,
                                  ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    // Security
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Security',
                      icon: Icons.security_rounded,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    _ProfileCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _ActionTile(
                            icon: Icons.lock_reset_rounded,
                            label: 'Change Password',
                            subtitle: 'Update your login password',
                            color: Colors.red,
                            isDark: isDark,
                            onTap: _changePassword,
                          ),
                          const Divider(height: 24),
                          _ActionTile(
                            icon: Icons.manage_accounts_rounded,
                            label: 'Account Settings',
                            subtitle: 'Edit profile details',
                            color: Colors.blue,
                            isDark: isDark,
                            onTap: () =>
                                context.push(AppRoutes.accountSettings),
                          ),
                        ],
                      ),
                    ),
                    // Support
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Support',
                      icon: Icons.help_rounded,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    _ProfileCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _ActionTile(
                            icon: Icons.help_outline_rounded,
                            label: 'Help & Support',
                            subtitle: 'FAQs and contact admin',
                            color: Colors.blue,
                            isDark: isDark,
                            onTap: () => context.push(AppRoutes.helpSupport),
                          ),
                          const Divider(height: 24),
                          _ActionTile(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Messages',
                            subtitle: 'Chat with students and HoDs',
                            color: Colors.teal,
                            isDark: isDark,
                            onTap: () => context.push(AppRoutes.chat),
                          ),
                        ],
                      ),
                    ),
                    // Sign out
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutConfirmation(context, ref),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardScaffold(
      title: 'Supervisor Portal',
      roleLabel: 'SUPERVISOR',
      tabs: [
        _DashboardTab(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          view: _SupervisorOverviewTab(),
        ),
        _DashboardTab(
          label: 'Interns',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          view: _SupervisorStudentsTab(),
          secondaryFab: _AssignFab(),
        ),
        _DashboardTab(
          label: 'Management',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          view: _SupervisorManagementTab(),
        ),
        _DashboardTab(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          view: _SupervisorSettingsTab(),
        ),
      ],
    );
  }
}

class _AssignFab extends ConsumerWidget {
  const _AssignFab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      heroTag: 'supervisor_assign_nav_fab',
      onPressed: () {
        // Switch to Management tab (index 2)
        ref.read(dashboardIndexProvider.notifier).state = 2;
      },
      backgroundColor: const Color(0xFF11998e),
      icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
      label: const Text(
        'Assign',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
      elevation: 4,
    );
  }
}

class _SupervisorAssignmentScreen extends ConsumerStatefulWidget {
  const _SupervisorAssignmentScreen();
  @override
  ConsumerState<_SupervisorAssignmentScreen> createState() =>
      _SupervisorAssignmentScreenState();
}

class _SupervisorAssignmentScreenState
    extends ConsumerState<_SupervisorAssignmentScreen> {
  int _step = 0;
  SupervisorProject? _selectedProject;
  SupervisorTeam? _selectedTeam;
  bool _createNewTeam = true;
  String _newTeamName = '';
  final Set<int> _selectedStudentIds = {};
  bool _loading = false;

  void _reset() => setState(() {
    _step = 0;
    _selectedProject = null;
    _selectedTeam = null;
    _createNewTeam = true;
    _newTeamName = '';
    _selectedStudentIds.clear();
  });

  int _fitScore(SupervisorStudent s) {
    if (_selectedProject == null || _selectedProject!.requiredSkills.isEmpty)
      return 0;
    final dept = (s.department ?? '').toLowerCase();
    final skills = _selectedProject!.requiredSkills
        .map((sk) => sk.toLowerCase())
        .toList();
    final matches = skills
        .where((sk) => dept.contains(sk) || sk.contains(dept))
        .length;
    if (matches == skills.length) return 0;
    if (matches > 0) return 1;
    return 2;
  }

  Color _fitColor(int score) => score == 0
      ? Colors.green
      : score == 1
      ? Colors.orange
      : Colors.red;
  IconData _fitIcon(int score) => score == 0
      ? Icons.check_circle_rounded
      : score == 1
      ? Icons.warning_rounded
      : Icons.cancel_rounded;
  String _fitLabel(int score) => score == 0
      ? 'Good fit'
      : score == 1
      ? 'Partial match'
      : 'Not suitable';
  Future<void> _moveStudentToTeam(Map<String, dynamic> assignment) async {
    final teams = ref.read(supervisorTeamsProvider).value ?? [];
    if (teams.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No teams available.')));
      return;
    }
    int? targetTeamId;
    final currentTeamId = ((assignment['teams'] as List?)?.isNotEmpty == true)
        ? _parseInt((assignment['teams'] as List).first['id'])
        : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setS) => AlertDialog(
          title: const Text(
            'Move to Team',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Team',
              border: OutlineInputBorder(),
            ),
            items: teams
                .where((t) => t.id != currentTeamId)
                .map(
                  (t) => DropdownMenuItem<int>(
                    value: t.id,
                    child: Text(t.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setS(() => targetTeamId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: targetTeamId == null
                  ? null
                  : () => Navigator.pop(d, true),
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || targetTeamId == null || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(supervisorRepositoryProvider)
          .moveStudentToTeam(_parseInt(assignment['studentId']), targetTeamId!);
      ref.invalidate(supervisorAssignmentsProvider);
      ref.invalidate(supervisorTeamsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student moved to new team ✓')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _moveTeamToProject(SupervisorTeam team) async {
    final projects = ref.read(supervisorProjectsProvider).value ?? [];
    if (projects.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No projects available.')));
      return;
    }
    int? targetProjectId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setS) => AlertDialog(
          title: Text(
            'Move "${team.name}" to Project',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Project',
              border: OutlineInputBorder(),
            ),
            items: projects
                .where((p) => p.id != team.projectId)
                .map(
                  (p) => DropdownMenuItem<int>(
                    value: p.id,
                    child: Text(
                      '${p.name} (${p.capacityLabel})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setS(() => targetProjectId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: targetProjectId == null
                  ? null
                  : () => Navigator.pop(d, true),
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || targetProjectId == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(supervisorRepositoryProvider)
          .moveTeamToProject(team.id, targetProjectId!);
      ref.invalidate(supervisorAssignmentsProvider);
      ref.invalidate(supervisorTeamsProvider);
      ref.invalidate(supervisorProjectsProvider);
      final warned = result['warned'] == true;
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              warned
                  ? 'Warning: ${result['warningMessage'] ?? 'Team moved with warnings'}'
                  : 'Team moved to new project ✓',
            ),
            backgroundColor: warned ? Colors.orange : null,
            duration: Duration(seconds: warned ? 5 : 3),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentsAsync = ref.watch(supervisorAssignmentsProvider);
    final projectsAsync = ref.watch(supervisorProjectsProvider);
    final teamsAsync = ref.watch(supervisorTeamsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(supervisorAssignmentsProvider);
        ref.invalidate(supervisorProjectsProvider);
        ref.invalidate(supervisorTeamsProvider);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FilledButton.icon(
                  onPressed: () => _showStepFlow(
                    context,
                    projectsAsync.value ?? [],
                    teamsAsync.value ?? [],
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'New Assignment',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6a11cb),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Projects Overview',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 12),
                projectsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (projects) => projects.isEmpty
                      ? _emptyCard('No projects yet', Icons.folder_open_rounded)
                      : Column(
                          children: projects
                              .map(
                                (p) => _projectDashCard(
                                  p,
                                  isDark,
                                  teamsAsync.value ?? [],
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Active Assignments',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 12),
                assignmentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (assignments) => assignments.isEmpty
                      ? _emptyCard(
                          'No assignments yet',
                          Icons.assignment_outlined,
                        )
                      : Column(
                          children: assignments
                              .map((a) => _assignmentCard(a, isDark))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Teams Overview',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 12),
                teamsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (teams) => teams.isEmpty
                      ? _emptyCard('No teams yet', Icons.groups_outlined)
                      : Column(
                          children: teams
                              .map((t) => _teamDashCard(t, isDark))
                              .toList(),
                        ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectDashCard(
    SupervisorProject p,
    bool isDark,
    List<SupervisorTeam> allTeams,
  ) {
    final linkedTeams = allTeams.where((t) => t.projectId == p.id).toList();
    final usedPct = p.capacity > 0
        ? (p.memberCount / p.capacity).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
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
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (p.description != null)
                      Text(
                        p.description!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.isFull
                      ? Colors.red.withOpacity(0.1)
                      : Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.capacityLabel,
                  style: TextStyle(
                    color: p.isFull ? Colors.red : Colors.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (p.capacity > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usedPct,
                minHeight: 6,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  p.isFull ? Colors.red : Colors.teal,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.people_rounded, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                '${p.memberCount} student${p.memberCount == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(width: 14),
              Icon(Icons.groups_rounded, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                '${linkedTeams.length} team${linkedTeams.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          if (linkedTeams.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: linkedTeams
                  .map(
                    (t) => GestureDetector(
                      onTap: () => _moveTeamToProject(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.name,
                              style: const TextStyle(
                                color: Colors.purple,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 10,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamDashCard(SupervisorTeam team, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${team.members.length} member${team.members.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _moveTeamToProject(team),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        team.projectName != null
                            ? Icons.swap_horiz_rounded
                            : Icons.link_rounded,
                        size: 13,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          team.projectName ?? 'Link Project',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (team.members.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: team.members
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        m.fullName,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _assignmentCard(Map<String, dynamic> a, bool isDark) {
    final name = a['studentName']?.toString() ?? 'Student';
    final teams = (a['teams'] as List?) ?? [];
    final projectName = a['projectName']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.indigo.withOpacity(0.12),
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
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
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (projectName != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_rounded,
                        size: 11,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          projectName,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (teams.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        size: 11,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          (teams[0] as Map)['name']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Assigned',
              style: TextStyle(
                color: Colors.green,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(
              Icons.swap_horiz_rounded,
              size: 18,
              color: Colors.indigo,
            ),
            tooltip: 'Move to different team',
            onPressed: () => _moveStudentToTeam(a),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg, IconData icon) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    ),
  );

  Future<void> _showStepFlow(
    BuildContext context,
    List<SupervisorProject> projects,
    List<SupervisorTeam> teams,
  ) async {
    _reset();
    final students = ref.read(supervisorStudentsProvider).value ?? [];
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No placed students available.')),
      );
      return;
    }
    await showResponsiveSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final stepTitles = [
            'Select Project',
            'Create / Select Team',
            'Add Students',
            'Confirm & Assign',
          ];
          final stepSubs = [
            'Choose the project',
            'Set up the team',
            'Pick students',
            'Review and confirm',
          ];
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
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
                Row(
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? const Color(0xFF6a11cb)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  stepTitles[_step],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stepSubs[_step],
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStep(_step, projects, teams, students, setS),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setS(() => _step--),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                if (_step < 3) {
                                  setS(() => _step++);
                                  return;
                                }
                                if (_selectedStudentIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Select at least one student.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (_createNewTeam &&
                                    _newTeamName.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enter a team name.'),
                                    ),
                                  );
                                  return;
                                }
                                setS(() => _loading = true);
                                try {
                                  final result = await ref
                                      .read(supervisorRepositoryProvider)
                                      .bulkAssign(
                                        studentIds: _selectedStudentIds
                                            .toList(),
                                        teamId: _createNewTeam
                                            ? null
                                            : _selectedTeam?.id,
                                        teamName: _createNewTeam
                                            ? _newTeamName.trim()
                                            : null,
                                        projectId: _selectedProject?.id,
                                      );
                                  ref.invalidate(supervisorAssignmentsProvider);
                                  ref.invalidate(supervisorTeamsProvider);
                                  ref.invalidate(supervisorProjectsProvider);
                                  ref.invalidate(supervisorStudentsProvider);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  final assigned =
                                      (result['assignedStudents'] as List?)
                                          ?.length ??
                                      0;
                                  final skipped =
                                      (result['skipped'] as List?)?.length ?? 0;
                                  final projName = _selectedProject?.name;
                                  final msg =
                                      '$assigned student(s) assigned${projName != null ? ' to "$projName"' : ''}${skipped > 0 ? ' ($skipped skipped)' : ''} ✓';
                                  if (mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                } catch (e) {
                                  setS(() => _loading = false);
                                  if (mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: _step == 3
                              ? const Color(0xFF11998e)
                              : const Color(0xFF6a11cb),
                          minimumSize: const Size(0, 50),
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
                            : Text(
                                _step == 3 ? 'Assign Now' : 'Next',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(
    int step,
    List<SupervisorProject> projects,
    List<SupervisorTeam> teams,
    List<SupervisorStudent> students,
    StateSetter setS,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setS(() {
                _selectedProject = null;
                _step = 1;
              }),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.skip_next_rounded, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Skip — no project',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (projects.isEmpty)
              const Text(
                'No projects yet. Create one in the Projects tab.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...projects.map(
                (p) => GestureDetector(
                  onTap: p.isFull
                      ? null
                      : () => setS(() {
                          _selectedProject = p;
                          _step = 1;
                        }),
                  child: Opacity(
                    opacity: p.isFull ? 0.5 : 1.0,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedProject?.id == p.id
                            ? const Color(0xFF6a11cb).withOpacity(0.08)
                            : (isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedProject?.id == p.id
                              ? const Color(0xFF6a11cb)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.folder_rounded,
                              color: Colors.teal,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  p.capacityLabel,
                                  style: TextStyle(
                                    color: p.isFull ? Colors.red : Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (p.isFull)
                            const Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          if (_selectedProject?.id == p.id)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF6a11cb),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setS(() => _createNewTeam = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _createNewTeam
                            ? const Color(0xFF6a11cb)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'New Team',
                          style: TextStyle(
                            color: _createNewTeam ? Colors.white : Colors.grey,
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
                    onTap: () => setS(() => _createNewTeam = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_createNewTeam
                            ? const Color(0xFF6a11cb)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Existing Team',
                          style: TextStyle(
                            color: !_createNewTeam ? Colors.white : Colors.grey,
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
            if (_createNewTeam)
              TextField(
                onChanged: (v) => setS(() => _newTeamName = v),
                decoration: const InputDecoration(
                  labelText: 'Team Name *',
                  hintText: 'e.g. Alpha Team',
                  border: OutlineInputBorder(),
                ),
              )
            else if (teams.isEmpty)
              const Text(
                'No teams yet. Switch to "New Team".',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...teams.map(
                (t) => GestureDetector(
                  onTap: () => setS(() => _selectedTeam = t),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedTeam?.id == t.id
                          ? const Color(0xFF6a11cb).withOpacity(0.08)
                          : (isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedTeam?.id == t.id
                            ? const Color(0xFF6a11cb)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Colors.purple,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${t.members.length} members${t.projectName != null ? " · ${t.projectName}" : ""}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedTeam?.id == t.id)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF6a11cb),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _fitLegend(0),
                const SizedBox(width: 12),
                _fitLegend(1),
                const SizedBox(width: 12),
                _fitLegend(2),
              ],
            ),
            const SizedBox(height: 12),
            ...students.map((s) {
              final fit = _fitScore(s);
              final isSelected = _selectedStudentIds.contains(s.id);
              final isAssigned = s.projectName != null;
              return GestureDetector(
                onTap: isAssigned
                    ? null
                    : () => setS(() {
                        if (isSelected)
                          _selectedStudentIds.remove(s.id);
                        else
                          _selectedStudentIds.add(s.id);
                      }),
                child: Opacity(
                  opacity: isAssigned ? 0.45 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6a11cb).withOpacity(0.07)
                          : (isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6a11cb)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _fitColor(fit),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _fitColor(fit).withOpacity(0.12),
                          child: Text(
                            s.fullName[0],
                            style: TextStyle(
                              color: _fitColor(fit),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                s.universityName,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    _fitIcon(fit),
                                    size: 11,
                                    color: _fitColor(fit),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _fitLabel(fit),
                                    style: TextStyle(
                                      color: _fitColor(fit),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isAssigned
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAssigned ? 'Assigned' : 'Available',
                            style: TextStyle(
                              color: isAssigned ? Colors.orange : Colors.green,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (!isAssigned)
                          Checkbox(
                            value: isSelected,
                            onChanged: (v) => setS(() {
                              if (v == true)
                                _selectedStudentIds.add(s.id);
                              else
                                _selectedStudentIds.remove(s.id);
                            }),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      default:
        final selectedStudents = students
            .where((s) => _selectedStudentIds.contains(s.id))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow(
              'Project',
              _selectedProject?.name ?? 'None',
              Icons.folder_rounded,
              Colors.teal,
            ),
            const SizedBox(height: 10),
            _confirmRow(
              'Team',
              _createNewTeam
                  ? '"$_newTeamName" (new)'
                  : (_selectedTeam?.name ?? 'None'),
              Icons.groups_rounded,
              Colors.purple,
            ),
            const SizedBox(height: 10),
            _confirmRow(
              'Students',
              '${selectedStudents.length} selected',
              Icons.people_rounded,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            ...selectedStudents.map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      s.universityName,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _fitLegend(int score) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(_fitIcon(score), size: 12, color: _fitColor(score)),
      const SizedBox(width: 3),
      Text(
        _fitLabel(score),
        style: TextStyle(
          color: _fitColor(score),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _confirmRow(String label, String value, IconData icon, Color color) =>
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

