part of 'dashboards.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardScaffold(
      title: 'Student Portal',
      roleLabel: 'STUDENT',
      tabs: [
        _DashboardTab(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          view: _StudentHomeTab(),
        ),
        _DashboardTab(
          label: 'Plans',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          view: _StudentPlansTab(),
        ),
        _DashboardTab(
          label: 'Jobs',
          icon: Icons.work_outline_rounded,
          activeIcon: Icons.work_rounded,
          view: _StudentJobsTab(),
        ),
        _DashboardTab(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          view: _StudentProfileTab(),
        ),
      ],
    );
  }
}

class _StudentHomeTab extends ConsumerWidget {
  const _StudentHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(studentProfileProvider);
    final plansAsync = ref.watch(myWeeklyPlansProvider);
    final proposalsAsync = ref.watch(myProposalsProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (profile) => Stack(
            children: [
              // Mesh Background for the whole tab
              if (isDark)
                CustomPaint(
                  size: Size.infinite,
                  painter: _MeshPainter(
                    color: theme.colorScheme.primary.withOpacity(0.03),
                  ),
                ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ModernSliverAppBar(
                    title: 'Welcome,',
                    subtitle: profile.fullName.split(' ')[0],
                    profileName: profile.fullName,
                    gradient: [
                      const Color(0xFF4facfe),
                      const Color(0xFF00f2fe),
                    ],
                    backgroundIcon: Icons.rocket_launch_rounded,
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
                        _buildInternshipStatusHeader(context, profile),
                        const SizedBox(height: 20),
                        _buildKeyCards(context, isDark, plansAsync),
                        const SizedBox(height: 32),

                        _buildSectionHeader(theme, 'Learning & Growth'),
                        const SizedBox(height: 16),
                        _buildPlatformAnalytics(
                          context,
                          isDark,
                          growthTitle: 'Current Week',
                          growthTrend: 'Week ${profile.currentInternshipWeek}',
                          placementTitle: 'Attendance',
                          placementSub:
                              '${plansAsync.value?.fold<int>(0, (sum, p) => sum + p.checkins.length) ?? 0} Check-ins',
                          successTitle: 'Plan Status',
                          successRate: (plansAsync.value?.isEmpty ?? true)
                              ? 0.0
                              : (plansAsync.value!
                                            .where(
                                              (p) =>
                                                  p.status.name.toUpperCase() ==
                                                  'APPROVED',
                                            )
                                            .length /
                                        plansAsync.value!.length)
                                    .clamp(0.0, 1.0),
                          submissionTitle: 'Placements',
                          submissionSub:
                              profile.companyName ?? 'Awaiting placement',
                        ),
                        const SizedBox(height: 32),

                        _buildAttendanceCheckin(
                          context,
                          isDark,
                          plansAsync,
                          ref,
                        ),
                        const SizedBox(height: 24),
                        _buildActivityHeatmap(context, isDark, plansAsync),
                        const SizedBox(height: 24),
                        _buildActiveInternshipInfo(context, isDark, profile),
                        const SizedBox(height: 20),
                        _buildRecentActivity(
                          context,
                          isDark,
                          plansAsync,
                          proposalsAsync,
                        ),
                        const SizedBox(height: 20),
                        FeedPreviewSection(),
                        const SizedBox(height: 24),
                        _buildQuickActions(context, ref, theme, isDark),
                        const SizedBox(height: 120),
                      ]),
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

  Widget _buildAttendanceCheckin(
    BuildContext context,
    bool isDark,
    AsyncValue<List<WeeklyPlan>> plansAsync,
    WidgetRef ref,
  ) {
    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (plans) {
        // Find if today is already checked in
        final today = DateTime.now();
        final todayKey = '${today.year}-${today.month}-${today.day}';
        bool alreadyCheckedIn = false;
        WeeklyPlan? currentPlan;

        // Simple heuristic: latest plan is current
        if (plans.isNotEmpty) {
          currentPlan = plans.reduce(
            (a, b) => a.weekNumber > b.weekNumber ? a : b,
          );
          alreadyCheckedIn = currentPlan.checkins.any(
            (c) => '${c.date.year}-${c.date.month}-${c.date.day}' == todayKey,
          );
        }

        return Container(
          padding: EdgeInsets.all(
            responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
          ),
          decoration: BoxDecoration(
            gradient: alreadyCheckedIn
                ? LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
                  ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (alreadyCheckedIn ? Colors.green : Colors.blue)
                    .withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      alreadyCheckedIn
                          ? Icons.check_circle_rounded
                          : Icons.location_on_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alreadyCheckedIn
                              ? 'Checked In Today'
                              : 'Daily Attendance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          alreadyCheckedIn
                              ? 'Great job! See you tomorrow.'
                              : 'Don\'t forget to log your attendance.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!alreadyCheckedIn) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: currentPlan == null
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(progressRepositoryProvider)
                                  .submitPlanDay(
                                    currentPlan!.id,
                                    today.toIso8601String().split('T')[0],
                                  );
                              ref.invalidate(myWeeklyPlansProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Check-in successful!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2575fc),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CHECK IN NOW',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInternshipStatusHeader(
    BuildContext context,
    StudentProfile profile,
  ) {
    final theme = Theme.of(context);
    final status = _deriveInternshipStatusLabel(profile);
    final (label, color, icon) = switch (status) {
      _InternshipStatus.active => (
        'Active',
        const Color(0xFF067647),
        Icons.check_circle_rounded,
      ),
      _InternshipStatus.pending => (
        'Pending',
        const Color(0xFFB54708),
        Icons.pending_rounded,
      ),
      _InternshipStatus.notPlaced => (
        'Not placed',
        const Color(0xFFB42318),
        Icons.cancel_rounded,
      ),
    };

    return Row(
      children: [
        Expanded(
          child: Text(
            'Dashboard',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyCards(
    BuildContext context,
    bool isDark,
    AsyncValue<List<WeeklyPlan>> plansAsync,
  ) {
    return plansAsync.when(
      loading: () => _buildKeyCardsGrid(
        context,
        isDark,
        attendanceOrCheckinsValue: '—',
        weeklyPlansProgressValue: '—',
        internshipProgressValue: '—',
        latestFeedbackValue: '—',
      ),
      error: (err, _) => _buildKeyCardsGrid(
        context,
        isDark,
        attendanceOrCheckinsValue: '—',
        weeklyPlansProgressValue: '—',
        internshipProgressValue: '—',
        latestFeedbackValue: '—',
      ),
      data: (plans) {
        final totalCheckins = plans.fold<int>(
          0,
          (sum, p) => sum + p.checkins.length,
        );
        final submitted = plans.length;
        final approved = plans
            .where((p) => p.status.name.toUpperCase() == 'APPROVED')
            .length;
        final latestFeedbackPlan =
            plans.where((p) => (p.feedback ?? '').trim().isNotEmpty).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final latestFeedbackValue = latestFeedbackPlan.isEmpty
            ? 'None'
            : 'Week ${latestFeedbackPlan.first.weekNumber}';

        // We don’t have a real “weeks completed” API yet; show derived from current week when available elsewhere.
        // Keep it lightweight and consistent with “5 seconds” requirement.
        return _buildKeyCardsGrid(
          context,
          isDark,
          attendanceOrCheckinsValue: '$totalCheckins',
          weeklyPlansProgressValue: '$approved/$submitted',
          internshipProgressValue: 'Week —',
          latestFeedbackValue: latestFeedbackValue,
        );
      },
    );
  }

  Widget _buildKeyCardsGrid(
    BuildContext context,
    bool isDark, {
    required String attendanceOrCheckinsValue,
    required String weeklyPlansProgressValue,
    required String internshipProgressValue,
    required String latestFeedbackValue,
  }) {
    final double width = MediaQuery.of(context).size.width;
    int crossCount = 2;
    if (width >= 1200)
      crossCount = 4;
    else if (width >= 600)
      crossCount = 3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: responsiveValue(
        context,
        mobile: 1.1,
        tablet: 1.3,
        desktop: 1.5,
      ),
      children: [
        _buildStatCard(
          context,
          'Check-ins',
          attendanceOrCheckinsValue,
          Icons.calendar_today_rounded,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Plans Progress',
          weeklyPlansProgressValue,
          Icons.assignment_turned_in_rounded,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Internship',
          internshipProgressValue,
          Icons.timeline_rounded,
          Colors.purple,
        ),
        _buildStatCard(
          context,
          'Latest Feedback',
          latestFeedbackValue,
          Icons.star_rounded,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityHeatmap(
    BuildContext context,
    bool isDark,
    AsyncValue<List<WeeklyPlan>> plansAsync,
  ) {
    final theme = Theme.of(context);
    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => const SizedBox.shrink(),
      data: (plans) {
        final activityMap = <String, int>{};
        for (var p in plans) {
          for (var d in p.checkins) {
            final key = '${d.date.year}-${d.date.month}-${d.date.day}';
            activityMap[key] = (activityMap[key] ?? 0) + 1;
          }
        }

        final now = DateTime.now();
        final days = List.generate(
          70,
          (i) => now.subtract(Duration(days: 69 - i)),
        );

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.5)
                : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'ACTIVITY HEATMAP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 14,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: 70,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final key = '${day.year}-${day.month}-${day.day}';
                  final count = activityMap[key] ?? 0;

                  Color color = isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03);
                  if (count > 0) {
                    color = theme.colorScheme.primary.withOpacity(
                      0.3 + (count * 0.2).clamp(0.0, 0.7),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveInternshipInfo(
    BuildContext context,
    bool isDark,
    StudentProfile profile,
  ) {
    final theme = Theme.of(context);
    final company = profile.companyName ?? 'Not assigned';
    final supervisor = profile.supervisorName ?? 'Not assigned';
    final start = profile.internshipStartDate;
    final startText = start == null
        ? '—'
        : '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';

    return Container(
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
          Text(
            'Active Internship',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(context, Icons.business_rounded, 'Company', company),
          const SizedBox(height: 10),
          _infoRow(context, Icons.person_pin_rounded, 'Supervisor', supervisor),
          const SizedBox(height: 10),
          _infoRow(context, Icons.event_rounded, 'Start date', startText),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    bool isDark,
    AsyncValue<List<WeeklyPlan>> plansAsync,
    AsyncValue<List<PlacementProposal>> proposalsAsync,
  ) {
    final theme = Theme.of(context);

    final plans = plansAsync.maybeWhen(
      data: (v) => v,
      orElse: () => const <WeeklyPlan>[],
    );
    final proposals = proposalsAsync.maybeWhen(
      data: (v) => v,
      orElse: () => const <PlacementProposal>[],
    );

    String? planStatusLine;
    String? feedbackLine;
    String? proposalLine;

    if (plans.isNotEmpty) {
      final latestPlan = (List<WeeklyPlan>.from(
        plans,
      )..sort((a, b) => b.createdAt.compareTo(a.createdAt))).first;
      planStatusLine =
          'Plan week ${latestPlan.weekNumber}: ${latestPlan.status.name}';

      final feedbackPlans =
          plans.where((p) => (p.feedback ?? '').trim().isNotEmpty).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (feedbackPlans.isNotEmpty) {
        feedbackLine = 'New feedback on week ${feedbackPlans.first.weekNumber}';
      }
    }

    if (proposals.isNotEmpty) {
      final latest = proposals.first;
      proposalLine = 'Proposal: ${latest.companyName} • ${latest.status}';
    }

    final items = <_ActivityItem>[
      if (feedbackLine != null)
        _ActivityItem(Icons.forum_rounded, feedbackLine, 'Feedback'),
      if (planStatusLine != null)
        _ActivityItem(
          Icons.assignment_turned_in_rounded,
          planStatusLine,
          'Plans',
        ),
      if (proposalLine != null)
        _ActivityItem(Icons.work_outline_rounded, proposalLine, 'Jobs'),
    ];

    return Container(
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
          Text(
            'Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'No recent updates yet.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else
            ...items
                .take(3)
                .map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            i.icon,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                              Text(
                                i.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildActionRow(
          context,
          'Weekly Progress',
          'Submit your weekly report',
          Icons.edit_note_rounded,
          Colors.blue,
          () =>
              ref.read(dashboardIndexProvider.notifier).state = 1, // Plans tab
        ),
        const SizedBox(height: 12),
        _buildActionRow(
          context,
          'Placement Info',
          'View company details',
          Icons.business_rounded,
          Colors.green,
          () => ref.read(dashboardIndexProvider.notifier).state = 2, // Jobs tab
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  _InternshipStatus _deriveInternshipStatusLabel(StudentProfile profile) {
    if ((profile.internshipStatus).toUpperCase() == 'PLACED' ||
        profile.companyName != null) {
      return _InternshipStatus.active;
    }
    if ((profile.internshipStatus).toUpperCase() == 'PENDING') {
      return _InternshipStatus.pending;
    }
    return _InternshipStatus.notPlaced;
  }
}

class _ActivityItem {
  final IconData icon;
  final String text;
  final String category;
  _ActivityItem(this.icon, this.text, this.category);
}

class _StudentPlansTab extends ConsumerWidget {
  const _StudentPlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const PlansScreen();
  }
}

class _StudentJobsTab extends ConsumerStatefulWidget {
  const _StudentJobsTab();

  @override
  ConsumerState<_StudentJobsTab> createState() => _StudentJobsTabState();
}

class _StudentJobsTabState extends ConsumerState<_StudentJobsTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final proposalsAsync = ref.watch(myProposalsProvider);
    final profileAsync = ref.watch(studentProfileProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (profile) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(myProposalsProvider),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                ModernSliverAppBar(
                  title: 'Placements',
                  subtitle: 'Career Opportunities',
                  profileName: profile.fullName,
                  gradient: [const Color(0xFFF5AF19), const Color(0xFFF12711)],
                  backgroundIcon: Icons.work_rounded,
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
                      if ((profile.internshipStatus).toUpperCase() ==
                              'PLACED' ||
                          profile.companyName != null) ...[
                        _buildPlacementSummaryCard(
                          context,
                          profile,
                          isDark,
                          theme,
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildRequestPlacementCard(context, isDark, theme),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Proposal Tracking',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pending / Approved / Rejected',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 32),
                      proposalsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                        data: (proposals) => proposals.isEmpty
                            ? _buildEmptyProposals(context, isDark, theme)
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: proposals.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) =>
                                    _buildProposalCard(
                                      context,
                                      proposals[index],
                                      isDark,
                                      theme,
                                    ),
                              ),
                      ),
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

  Widget _buildEmptyProposals(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.1),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.business_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
            const SizedBox(height: 24),
            const Text(
              'No proposals yet.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementSummaryCard(
    BuildContext context,
    StudentProfile profile,
    bool isDark,
    ThemeData theme,
  ) {
    final company = profile.companyName ?? 'Assigned company';
    final supervisor = profile.supervisorName ?? 'Assigned supervisor';
    final start = profile.internshipStartDate;
    final startText = start == null
        ? '—'
        : '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OFFICIAL STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    company.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Senior Intern Program',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                _extremeInfoRow(
                  Icons.person_pin_rounded,
                  'Supervisor',
                  supervisor,
                  theme,
                ),
                const SizedBox(height: 24),
                _extremeInfoRow(
                  Icons.event_available_rounded,
                  'Started On',
                  startText,
                  theme,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'You are performing in the top 10% of interns in this organization.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _extremeInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestPlacementCard(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&q=80&w=1000',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'ELEVATE YOUR CAREER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find Your\nPerfect Match',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton(
                    onPressed: () => _showRequestPlacementBottomSheet(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'EXPLORE OPPORTUNITIES',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestPlacementBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final companyController = TextEditingController();
    final letterController = TextEditingController();
    bool isSubmitting = false;

    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            32,
            32,
            32,
            MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'OPEN LETTER REQUEST',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Request a Placement',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your HoD will review and approve or reject this request.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 32),
              _extremeTextField(
                companyController,
                'Company Name',
                Icons.business_rounded,
                theme,
              ),
              const SizedBox(height: 20),
              _extremeTextField(
                letterController,
                'Cover Letter / Motivation',
                Icons.description_rounded,
                theme,
                maxLines: 5,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final company = companyController.text.trim();
                          final letter = letterController.text.trim();
                          if (company.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a company name.'),
                              ),
                            );
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            await ref
                                .read(placementRepositoryProvider)
                                .submitOpenLetter(
                                  companyName: company,
                                  coverLetter: letter,
                                );
                            ref.invalidate(myProposalsProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Open letter submitted — awaiting HoD review ✓',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: Colors.black,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SUBMIT OPEN LETTER',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _extremeTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    ThemeData theme, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(24),
      ),
    );
  }

  Widget _buildProposalCard(
    BuildContext context,
    PlacementProposal p,
    bool isDark,
    ThemeData theme,
  ) {
    final statusColor = p.status == 'APPROVED'
        ? Colors.green
        : p.status == 'REJECTED'
        ? Colors.red
        : p.status == 'CANCELLED'
        ? Colors.grey
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(
        responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.8), statusColor],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              p.isOpenLetter ? Icons.mail_rounded : Icons.apartment_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.companyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      p.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    if (p.isOpenLetter) ...[
                      const SizedBox(width: 8),
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
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showProposalDetails(context, p),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  void _showProposalDetails(BuildContext context, PlacementProposal p) {
    final statusColor = p.status == 'APPROVED'
        ? Colors.green
        : p.status == 'REJECTED'
        ? Colors.red
        : p.status == 'CANCELLED'
        ? Colors.grey
        : Colors.orange;

    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.companyName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (p.isOpenLetter)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Open Letter',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (p.isOpenLetter) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.status == 'PENDING'
                            ? 'Awaiting HoD review. Once approved, this becomes an active proposal.'
                            : p.status == 'APPROVED'
                            ? 'Your HoD approved this open letter. The proposal is now active.'
                            : 'Your HoD reviewed this open letter.',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Cover Letter / Motivation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              p.proposalLetter?.isNotEmpty == true
                  ? p.proposalLetter!
                  : 'No cover letter attached.',
              style: const TextStyle(height: 1.5, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
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
}

class _StudentProfileTab extends ConsumerWidget {
  const _StudentProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(studentProfileProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (profile) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ModernSliverAppBar(
                title: 'Profile',
                subtitle: 'Account Settings',
                profileName: profile.fullName,
                gradient: [const Color(0xFFee9ae5), const Color(0xFF5961f9)],
                backgroundIcon: Icons.account_circle_rounded,
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
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            child: Text(
                              profile.fullName[0],
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.fullName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            profile.email,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildProfileInfoCard(theme, isDark, 'Internship Details', [
                      _ProfileInfoRow(
                        Icons.business_rounded,
                        'Company',
                        profile.companyName ?? 'Not Assigned',
                      ),
                      _ProfileInfoRow(
                        Icons.person_pin_rounded,
                        'Supervisor',
                        profile.supervisorName ?? 'Not Assigned',
                      ),
                      _ProfileInfoRow(
                        Icons.calendar_view_week_rounded,
                        'Current Week',
                        'Week ${profile.currentInternshipWeek}',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildProfileInfoCard(theme, isDark, 'Academic Status', [
                      _ProfileInfoRow(
                        Icons.verified_user_rounded,
                        'Approval Status',
                        profile.status,
                      ),
                      _ProfileInfoRow(
                        Icons.school_rounded,
                        'Internship Status',
                        profile.internshipStatus,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Final Reports & Evaluations — wired to real data
                    Consumer(
                      builder: (ctx, cref, _) {
                        final evalAsync = cref.watch(myEvaluationProvider);
                        final evalStatus = evalAsync.maybeWhen(
                          data: (e) => e != null
                              ? 'Score: ${e.overallScore.toStringAsFixed(1)}/100'
                              : 'Pending',
                          orElse: () => '...',
                        );
                        return _buildProfileInfoCard(
                          theme,
                          isDark,
                          'Final Reports & Evaluations',
                          [
                            _ProfileInfoRow(
                              Icons.description_rounded,
                              'Final Report',
                              'View Weekly Plans',
                              actionLabel: 'Open',
                              onAction: () => context.push(AppRoutes.reports),
                            ),
                            _ProfileInfoRow(
                              Icons.assignment_turned_in_rounded,
                              'Final Evaluation',
                              evalStatus,
                              actionLabel: 'View',
                              onAction: () =>
                                  context.push(AppRoutes.evaluations),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProfileInfoCard(theme, isDark, 'Account Settings', [
                      _ProfileInfoRow(
                        Icons.lock_reset_rounded,
                        'Password',
                        '********',
                        actionLabel: 'Change',
                        onAction: () => _showChangePasswordDialog(context),
                      ),
                      _ProfileInfoRow(
                        Icons.notifications_active_rounded,
                        'Notifications',
                        'Enabled',
                        actionLabel: 'Toggle',
                        onAction: () {},
                      ),
                    ]),
                    const SizedBox(height: 40),
                    OutlinedButton(
                      onPressed: () => _showLogoutConfirmation(context, ref),
                      child: const Text('Sign Out'),
                    ),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(
    ThemeData theme,
    bool isDark,
    String title,
    List<_ProfileInfoRow> rows,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      row.icon,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (row.onAction != null)
                    IconButton.filledTonal(
                      onPressed: row.onAction,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          'Security Update',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update your password to keep your account secure.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('UPDATE NOW'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow {
  final IconData icon;
  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;
  _ProfileInfoRow(
    this.icon,
    this.label,
    this.value, {
    this.actionLabel,
    this.onAction,
  });
}

