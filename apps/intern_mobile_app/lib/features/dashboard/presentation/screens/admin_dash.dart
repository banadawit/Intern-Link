part of 'dashboards.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModernDashboardScaffold(
      title: 'Admin Portal',
      roleLabel: 'ADMIN',
      tabs: [
        const _DashboardTab(
          label: 'Overview',
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          view: _AdminOverviewTab(),
        ),
        _DashboardTab(
          label: 'Orgs',
          icon: Icons.business_rounded,
          activeIcon: Icons.business_center_rounded,
          view: const _AdminOrganizationsTab(),
          secondaryFab: const _CreateOrgFab(),
        ),
        const _DashboardTab(
          label: 'Users',
          icon: Icons.manage_accounts_outlined,
          activeIcon: Icons.manage_accounts_rounded,
          view: _AdminUsersTab(),
        ),
        const _DashboardTab(
          label: 'Logs',
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          view: _AdminLogsTab(),
        ),
        const _DashboardTab(
          label: 'Config',
          icon: Icons.settings_suggest_outlined,
          activeIcon: Icons.settings_suggest_rounded,
          view: _AdminSettingsTab(),
        ),
      ],
    );
  }
}

class _AdminOverviewTab extends ConsumerStatefulWidget {
  const _AdminOverviewTab();

  @override
  ConsumerState<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends ConsumerState<_AdminOverviewTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(adminStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);

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
          data: (profile) => statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (stats) => CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                ModernSliverAppBar(
                  title: 'Admin Dashboard',
                  subtitle: 'Platform Management',
                  profileName: profile.fullName,
                  gradient: const [Color(0xFF0F2027), Color(0xFF2C5364)],
                  backgroundIcon: Icons.shield_rounded,
                ),
                SliverPadding(
                  padding: EdgeInsets.all(
                    responsiveValue(
                      context,
                      mobile: 16.0,
                      tablet: 24.0,
                      desktop: 32.0,
                    ),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (stats.pendingApprovals > 0) ...[
                        _buildSectionHeader(theme, 'Priority Alerts'),
                        const SizedBox(height: 16),
                        _buildPriorityAlerts(context, stats, ref, isDark),
                        const SizedBox(height: 32),
                      ],

                      _buildSectionHeader(theme, 'Overview Cards'),
                      const SizedBox(height: 16),
                      _buildOverviewGrid(context, stats, isDark),
                      const SizedBox(height: 32),

                      _buildSectionHeader(theme, 'Growth & Analytics'),
                      const SizedBox(height: 16),
                      // On tablet: show analytics in 2-col grid
                      if (isTablet(context)) ...[
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildGrowthAnalytics(
                                  context,
                                  ref,
                                  isDark,
                                  theme,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildOrganizationBreakdown(
                                  context,
                                  ref,
                                  stats,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildInternshipOverview(
                                  context,
                                  ref,
                                  stats,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReportsSnapshot(
                                  context,
                                  ref,
                                  stats,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        _buildGrowthAnalytics(context, ref, isDark, theme),
                        const SizedBox(height: 32),
                        _buildSectionHeader(theme, 'Organization Breakdown'),
                        const SizedBox(height: 16),
                        _buildOrganizationBreakdown(
                          context,
                          ref,
                          stats,
                          isDark,
                        ),
                        const SizedBox(height: 32),
                        _buildSectionHeader(theme, 'Internship Overview'),
                        const SizedBox(height: 16),
                        _buildInternshipOverview(context, ref, stats, isDark),
                        const SizedBox(height: 32),
                        _buildSectionHeader(theme, 'Reports Snapshot'),
                        const SizedBox(height: 16),
                        _buildReportsSnapshot(context, ref, stats, isDark),
                      ],
                      const SizedBox(height: 32),

                      _buildSectionHeader(theme, 'Recent Activity'),
                      const SizedBox(height: 16),
                      _buildRecentActivitiesPreview(context, ref, isDark),
                      const SizedBox(height: 32),

                      _buildSectionHeader(theme, 'Security / Health'),
                      const SizedBox(height: 16),
                      _buildSystemHealthWidget(context, isDark),
                      const SizedBox(height: 32),

                      _buildSectionHeader(theme, 'Quick Actions'),
                      const SizedBox(height: 16),
                      _buildQuickNavigation(context, ref, isDark),

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

  Widget _buildOverviewGrid(BuildContext context, dynamic stats, bool isDark) {
    final w = MediaQuery.of(context).size.width;
    // 4 cards — always use 4 cols on tablet/desktop, 2 on mobile
    final cols = w >= 600 ? 4 : 2;
    final ratio = w >= 1200 ? 1.3 : (w >= 600 ? 1.1 : 0.85);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: ratio,
      children: [
        _buildStatCard(
          context,
          'Total Users',
          stats.totalUsers.toString(),
          Icons.people_rounded,
          Colors.blue,
          isDark,
        ),
        _buildStatCard(
          context,
          'Institutions',
          (stats.totalUniversities + stats.totalCompanies).toString(),
          Icons.account_balance_rounded,
          Colors.orange,
          isDark,
        ),
        _buildStatCard(
          context,
          'Total Reports',
          stats.totalReports.toString(),
          Icons.insert_chart_rounded,
          Colors.green,
          isDark,
        ),
        _buildStatCard(
          context,
          'Pending Review',
          stats.pendingApprovals.toString(),
          Icons.pending_actions_rounded,
          Colors.red,
          isDark,
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
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Radial Mesh Glow
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.8), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityAlerts(
    BuildContext context,
    dynamic stats,
    WidgetRef ref,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded, color: Colors.redAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Action Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.redAccent.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending: ${stats.pendingOrganizationRequests} Orgs, ${stats.pendingCoordinators} Coords, ${stats.pendingSupervisors} Sups, ${stats.pendingHods} HODs.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(dashboardIndexProvider.notifier).state = 1,
            child: const Text(
              'Review',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthAnalytics(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ThemeData theme,
  ) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => _analyticsShimmer(isDark),
      error: (e, _) => _analyticsError(isDark, 'Growth & Analytics'),
      data: (data) {
        final userGrowth = (data['userGrowth'] as List?) ?? [];
        // Sum totals across all months for display
        int totalNew = 0, newStudents = 0, newCoords = 0, newSups = 0;
        for (final m in userGrowth) {
          totalNew += _parseInt(m['total']);
          newStudents += _parseInt(m['students']);
          newCoords += _parseInt(m['coordinators']);
          newSups += _parseInt(m['supervisors']);
        }
        // Month-over-month growth % (last vs second-to-last month)
        String growthPct = '—';
        Color growthColor = Colors.grey;
        if (userGrowth.length >= 2) {
          final last = _parseInt(userGrowth.last['total']);
          final prev = _parseInt(userGrowth[userGrowth.length - 2]['total']);
          if (prev > 0) {
            final pct = ((last - prev) / prev * 100);
            growthPct = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%';
            growthColor = pct >= 0 ? Colors.green : Colors.red;
          } else if (last > 0) {
            growthPct = '+100%';
            growthColor = Colors.green;
          }
        }
        return Container(
          padding: EdgeInsets.all(
            responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
          ),
          decoration: _cardDecor(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart_rounded, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'User Growth (6 months)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: growthColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      growthPct,
                      style: TextStyle(
                        color: growthColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Bar chart — one bar per month
              if (userGrowth.isNotEmpty) ...[
                _buildBarChart(userGrowth, isDark),
                const SizedBox(height: 16),
              ],
              _buildStatsRow([
                _StatItem('New Users', '$totalNew', Colors.purple),
                _StatItem('Students', '$newStudents', Colors.blue),
                _StatItem('Coordinators', '$newCoords', Colors.orange),
                _StatItem('Supervisors', '$newSups', Colors.teal),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarChart(List<dynamic> months, bool isDark) {
    final maxVal = months
        .map((m) => _parseInt(m['total']))
        .fold(0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: months.map((m) {
          final val = _parseInt(m['total']);
          final frac = maxVal == 0 ? 0.0 : val / maxVal;
          final isLast = m == months.last;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (val > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$val',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 1),
                  Container(
                    height: (frac * 40).clamp(3.0, 40.0),
                    decoration: BoxDecoration(
                      color: isLast
                          ? Colors.blue
                          : Colors.blue.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      m['label']?.toString() ?? '',
                      style: const TextStyle(fontSize: 8, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrganizationBreakdown(
    BuildContext context,
    WidgetRef ref,
    dynamic stats,
    bool isDark,
  ) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => _analyticsShimmer(isDark),
      error: (_, __) {
        // Fallback to stats data
        final total = stats.totalUniversities + stats.totalCompanies;
        final uniPct = total == 0 ? 0.0 : stats.totalUniversities / total;
        final compPct = total == 0 ? 0.0 : stats.totalCompanies / total;
        return _orgBreakdownCard(
          isDark,
          stats.totalUniversities,
          stats.totalCompanies,
          0,
          0,
          uniPct,
          compPct,
        );
      },
      data: (data) {
        final orgStats = data['orgStats'] as Map? ?? {};
        final unis = orgStats['universities'] as Map? ?? {};
        final comps = orgStats['companies'] as Map? ?? {};
        final totalUnis = _parseInt(unis['total']);
        final approvedUnis = _parseInt(unis['approved']);
        final totalComps = _parseInt(comps['total']);
        final approvedComps = _parseInt(comps['approved']);
        final total = totalUnis + totalComps;
        final uniPct = total == 0 ? 0.0 : totalUnis / total;
        final compPct = total == 0 ? 0.0 : totalComps / total;
        return _orgBreakdownCard(
          isDark,
          totalUnis,
          totalComps,
          approvedUnis,
          approvedComps,
          uniPct,
          compPct,
        );
      },
    );
  }

  Widget _orgBreakdownCard(
    bool isDark,
    int totalUnis,
    int totalComps,
    int approvedUnis,
    int approvedComps,
    double uniPct,
    double compPct,
  ) {
    return Container(
      padding: EdgeInsets.all(
        responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
      ),
      decoration: _cardDecor(isDark),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBreakdownItem(
                'Universities',
                '$totalUnis',
                Colors.blue,
                sub: '$approvedUnis approved',
              ),
              _buildBreakdownItem(
                'Companies',
                '$totalComps',
                Colors.purple,
                sub: '$approvedComps approved',
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: (uniPct * 100).toInt().clamp(1, 99),
                  child: Container(height: 12, color: Colors.blue),
                ),
                Expanded(
                  flex: (compPct * 100).toInt().clamp(1, 99),
                  child: Container(height: 12, color: Colors.purple),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${(uniPct * 100).toStringAsFixed(0)}% Universities',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${(compPct * 100).toStringAsFixed(0)}% Companies',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInternshipOverview(
    BuildContext context,
    WidgetRef ref,
    dynamic stats,
    bool isDark,
  ) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => _analyticsShimmer(isDark),
      error: (_, __) => _buildInternshipFallback(stats, isDark),
      data: (data) {
        final placement = data['placementStats'] as Map? ?? {};
        final proposals = data['proposalStats'] as Map? ?? {};
        final total = _parseInt(placement['total']);
        final placed = _parseInt(placement['placed']);
        final completed = _parseInt(placement['completed']);
        final pending = _parseInt(placement['pending']);
        final placedPct = total == 0 ? 0.0 : placed / total;
        return Container(
          padding: EdgeInsets.all(
            responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
          ),
          decoration: _cardDecor(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.work_history_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Internship Overview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Placement progress bar
              Row(
                children: [
                  Text(
                    'Placement rate',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  Text(
                    '${(placedPct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: placedPct,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildStatsRow([
                _StatItem('Total', '$total', Colors.grey),
                _StatItem('Placed', '$placed', Colors.orange),
                _StatItem('Completed', '$completed', Colors.green),
                _StatItem('Pending', '$pending', Colors.blue),
              ]),
              const Divider(height: 24),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Proposals:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  _proposalBadge(
                    '${proposals['approved'] ?? 0} approved',
                    Colors.green,
                  ),
                  _proposalBadge(
                    '${proposals['pending'] ?? 0} pending',
                    Colors.orange,
                  ),
                  _proposalBadge(
                    '${proposals['rejected'] ?? 0} rejected',
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInternshipFallback(dynamic stats, bool isDark) {
    return Container(
      padding: EdgeInsets.all(
        responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
      ),
      decoration: _cardDecor(isDark),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.work_history_rounded,
              color: Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Evaluations',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                Text(
                  '${stats.totalEvaluations}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _proposalBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReportsSnapshot(
    BuildContext context,
    WidgetRef ref,
    dynamic stats,
    bool isDark,
  ) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => _analyticsShimmer(isDark),
      error: (_, __) => Container(
        padding: EdgeInsets.all(
          responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
        ),
        decoration: _cardDecor(isDark),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.summarize_rounded,
                color: Colors.teal,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submitted Reports',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  Text(
                    '${stats.totalReports}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      data: (data) {
        final wpTrend = (data['weeklyPlanTrend'] as List?) ?? [];
        int totalPlans = 0, approvedPlans = 0;
        for (final m in wpTrend) {
          totalPlans += _parseInt(m['submitted']);
          approvedPlans += _parseInt(m['approved']);
        }
        final approvalRate = totalPlans == 0 ? 0.0 : approvedPlans / totalPlans;
        return Container(
          padding: EdgeInsets.all(
            responsiveValue(context, mobile: 16.0, tablet: 32.0, desktop: 48.0),
          ),
          decoration: _cardDecor(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.summarize_rounded, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    'Weekly Plans & Reports',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatsRow([
                _StatItem('Plans (6mo)', '$totalPlans', Colors.teal),
                _StatItem('Approved', '$approvedPlans', Colors.green),
                _StatItem('Reports', '${stats.totalReports}', Colors.blue),
                _StatItem(
                  'Evaluations',
                  '${stats.totalEvaluations}',
                  Colors.purple,
                ),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Plan approval rate',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  Text(
                    '${(approvalRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: approvalRate,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  BoxDecoration _cardDecor(bool isDark) => BoxDecoration(
    color: isDark
        ? const Color(0xFF1E293B).withOpacity(0.5)
        : Colors.white.withOpacity(0.8),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ],
  );

  Widget _analyticsShimmer(bool isDark) => Container(
    height: 100,
    decoration: _cardDecor(isDark),
    child: const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );

  Widget _analyticsError(bool isDark, String label) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecor(isDark),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label unavailable', style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _buildRecentActivitiesPreview(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final logs = ref.watch(auditLogsProvider).asData?.value ?? [];
    final recent = logs.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ...recent.map(
            (log) => ListTile(
              dense: true,
              leading: const CircleAvatar(
                radius: 14,
                child: Icon(Icons.history_rounded, size: 14),
              ),
              title: Text(
                log['action'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                log['timestamp'],
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No recent logs',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  /// Evenly-spaced stat items that never overflow — uses LayoutBuilder to
  /// decide between a single Row (wide) or a 2×2 grid (narrow).
  Widget _buildStatsRow(List<_StatItem> items) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Each item needs ~60px minimum; if not enough space, wrap into 2 rows
        final useGrid = constraints.maxWidth < items.length * 64;
        if (useGrid) {
          final half = (items.length / 2).ceil();
          return Column(
            children: [
              Row(
                children: items
                    .take(half)
                    .map((s) => Expanded(child: _statCell(s)))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: items
                    .skip(half)
                    .map((s) => Expanded(child: _statCell(s)))
                    .toList(),
              ),
            ],
          );
        }
        return Row(
          children: items.map((s) => Expanded(child: _statCell(s))).toList(),
        );
      },
    );
  }

  Widget _statCell(_StatItem s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: s.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          s.label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildGrowthStat(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    String label,
    String value,
    Color color, {
    String? sub,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (sub != null)
              Text(
                sub,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemHealthWidget(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHealthRow('Backend API', 'Online', Colors.green),
          const Divider(height: 24),
          _buildHealthRow('Database', 'Connected', Colors.green),
          const Divider(height: 24),
          _buildHealthRow('Email Server', 'Standby', Colors.orange),
          const Divider(height: 24),
          _buildHealthRow('Storage (S3)', 'Operational', Colors.green),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String service, String status, Color color) {
    return Row(
      children: [
        Text(service, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickNavigation(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildNavChip(context, ref, 'Orgs', Icons.business_rounded, isDark, 1),
        _buildNavChip(
          context,
          ref,
          'Audit Logs',
          Icons.receipt_long_rounded,
          isDark,
          2,
        ),
        _buildNavChip(
          context,
          ref,
          'Config',
          Icons.settings_rounded,
          isDark,
          3,
        ),
      ],
    );
  }

  Widget _buildNavChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    bool isDark,
    int targetIndex,
  ) {
    return InkWell(
      onTap: () =>
          ref.read(dashboardIndexProvider.notifier).state = targetIndex,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOrganizationsTab extends ConsumerStatefulWidget {
  const _AdminOrganizationsTab();

  @override
  ConsumerState<_AdminOrganizationsTab> createState() =>
      _AdminOrganizationsTabState();
}

class _CreateOrgFab extends ConsumerWidget {
  const _CreateOrgFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      heroTag: 'create_org_fab',
      onPressed: () => _showCreateOrgSheet(context, ref),
      backgroundColor: const Color(0xFF4286F4),
      foregroundColor: Colors.white,
      tooltip: 'Create Organization',
      child: const Icon(Icons.add_business_rounded),
    );
  }
}

class _OrgTypeChip extends StatelessWidget {
  const _OrgTypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgFormField extends StatelessWidget {
  const _OrgFormField({
    required this.ctrl,
    required this.hint,
    required this.label,
    required this.icon,
    required this.isDark,
    this.keyboardType,
  });
  final TextEditingController ctrl;
  final String hint;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminOrganizationsTabState
    extends ConsumerState<_AdminOrganizationsTab> {
  String _searchQuery = '';
  String _orgTypeFilter = 'All'; // 'All', 'University', 'Company'
  String _orgStatusFilter =
      'All'; // 'All', 'PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED', 'REQUESTS'
  final Set<int> _viewedIds = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statsAsync = ref.watch(adminStatsProvider);
    final unisAsync = ref.watch(allUniversitiesProvider);
    final compsAsync = ref.watch(allCompaniesProvider);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            slivers: [
              ModernSliverAppBar(
                title: 'Organizations',
                subtitle: 'Manage Universities & Companies',
                profileName:
                    ref.watch(userProfileProvider).value?.fullName ?? 'Admin',
                gradient: [const Color(0xFF373B44), const Color(0xFF4286F4)],
                backgroundIcon: Icons.business_rounded,
                actions: [
                  IconButton(
                    onPressed: () =>
                        _showMergeDuplicatesDialog(context, ref, isDark),
                    icon: const Icon(
                      Icons.call_merge_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Merge Duplicates',
                  ),
                  IconButton(
                    onPressed: () => _showCreateOrgDialog(context, ref, isDark),
                    icon: const Icon(
                      Icons.add_business_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Create Organization',
                  ),
                ],
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
                    _buildOrgStatsRow(statsAsync, isDark),
                    const SizedBox(height: 32),
                    _buildFilterRow(isDark),
                    const SizedBox(height: 24),
                    Text(
                      'Results',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              _buildOrgList(ref, unisAsync, compsAsync, isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrgStatsRow(AsyncValue<AdminStats> statsAsync, bool isDark) {
    final unisAsync = ref.watch(allUniversitiesProvider);
    final compsAsync = ref.watch(allCompaniesProvider);

    // Compute real counts from the full org lists
    int pending = 0, approved = 0, rejected = 0, suspended = 0;
    final unis = unisAsync.asData?.value ?? [];
    final comps = compsAsync.asData?.value ?? [];
    for (final o in [...unis, ...comps]) {
      final s = o['approval_status']?.toString() ?? '';
      if (s == 'PENDING')
        pending++;
      else if (s == 'APPROVED')
        approved++;
      else if (s == 'REJECTED')
        rejected++;
      else if (s == 'SUSPENDED')
        suspended++;
    }

    final requestsAsync = ref.watch(organizationRequestsProvider);
    final pendingRequests =
        requestsAsync.asData?.value
            .where((r) => r['status'] == 'PENDING')
            .length ??
        0;

    final isLoading = unisAsync.isLoading || compsAsync.isLoading;

    if (isLoading)
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMiniStat(
            'Pending',
            '${pending + pendingRequests}',
            Icons.pending_actions_rounded,
            Colors.orange,
            isDark,
            onTap: () => setState(
              () => _orgStatusFilter = pendingRequests > 0
                  ? 'REQUESTS'
                  : 'PENDING',
            ),
          ),
          const SizedBox(width: 12),
          _buildMiniStat(
            'Approved',
            '$approved',
            Icons.verified_rounded,
            Colors.green,
            isDark,
            onTap: () => setState(() => _orgStatusFilter = 'APPROVED'),
          ),
          const SizedBox(width: 12),
          _buildMiniStat(
            'Rejected',
            '$rejected',
            Icons.cancel_rounded,
            Colors.red,
            isDark,
            onTap: () => setState(() => _orgStatusFilter = 'REJECTED'),
          ),
          const SizedBox(width: 12),
          _buildMiniStat(
            'Suspended',
            '$suspended',
            Icons.block_rounded,
            Colors.grey,
            isDark,
            onTap: () => setState(() => _orgStatusFilter = 'SUSPENDED'),
          ),
          const SizedBox(width: 12),
          _buildMiniStat(
            'Requests',
            '$pendingRequests',
            Icons.notification_important_rounded,
            Colors.purple,
            isDark,
            onTap: () => setState(() => _orgStatusFilter = 'REQUESTS'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (_orgStatusFilter == label.toUpperCase())
                ? color.withOpacity(0.5)
                : isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: (_orgStatusFilter == label.toUpperCase()) ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search organization name...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownFilter('Type: $_orgTypeFilter', [
                'All',
                'University',
                'Company',
              ], (v) => setState(() => _orgTypeFilter = v!)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownFilter(
                'Status: $_orgStatusFilter',
                [
                  'All',
                  'PENDING',
                  'APPROVED',
                  'REJECTED',
                  'SUSPENDED',
                  'REQUESTS',
                ],
                (v) => setState(() => _orgStatusFilter = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
    String label,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label.split(': ').last,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(
                    o,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOrgList(
    WidgetRef ref,
    AsyncValue<List<dynamic>> unisAsync,
    AsyncValue<List<dynamic>> compsAsync,
    bool isDark,
  ) {
    if (_orgStatusFilter == 'REQUESTS') {
      final requestsAsync = ref.watch(organizationRequestsProvider);
      return requestsAsync.when(
        loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
        data: (requests) {
          final sQuery = _searchQuery.toLowerCase();
          final filtered = requests.where((r) {
            if (sQuery.isNotEmpty &&
                !r['name'].toString().toLowerCase().contains(sQuery))
              return false;
            if (_orgTypeFilter != 'All' &&
                r['type'] != _orgTypeFilter.toUpperCase())
              return false;
            return true;
          }).toList();

          if (filtered.isEmpty)
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No organization requests found'),
                ),
              ),
            );

          final hPad = responsiveValue(
            context,
            mobile: 16.0,
            tablet: 24.0,
            desktop: 32.0,
          );
          return SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildRequestCard(context, ref, filtered[index], isDark),
                childCount: filtered.length,
              ),
            ),
          );
        },
      );
    }

    return unisAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
      data: (unis) => compsAsync.when(
        loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
        data: (comps) {
          final sQuery = _searchQuery.toLowerCase();
          final filterByStatus = _orgStatusFilter != 'All';

          Iterable<Map<String, dynamic>> filteredUnis = [];
          if (_orgTypeFilter != 'Company') {
            filteredUnis = unis
                .where((u) {
                  if (filterByStatus &&
                      u['approval_status'] != _orgStatusFilter)
                    return false;
                  if (sQuery.isNotEmpty &&
                      !u['name'].toString().toLowerCase().contains(sQuery))
                    return false;
                  return true;
                })
                .map(
                  (u) => {
                    ...Map<String, dynamic>.from(u as Map),
                    'type': 'University',
                  },
                );
          }

          Iterable<Map<String, dynamic>> filteredComps = [];
          if (_orgTypeFilter != 'University') {
            filteredComps = comps
                .where((c) {
                  if (filterByStatus &&
                      c['approval_status'] != _orgStatusFilter)
                    return false;
                  if (sQuery.isNotEmpty &&
                      !c['name'].toString().toLowerCase().contains(sQuery))
                    return false;
                  return true;
                })
                .map(
                  (c) => {
                    ...Map<String, dynamic>.from(c as Map),
                    'type': 'Company',
                  },
                );
          }

          final optimistic = ref.watch(optimisticOrgsProvider).where((o) {
            if (filterByStatus && o['approval_status'] != _orgStatusFilter)
              return false;
            if (sQuery.isNotEmpty &&
                !o['name'].toString().toLowerCase().contains(sQuery))
              return false;
            if (_orgTypeFilter != 'All' && o['type'] != _orgTypeFilter)
              return false;
            return true;
          });

          // Include organization requests (map to same shape used by org cards)
          final requestsRaw = ref.watch(organizationRequestsProvider).asData?.value ?? [];
          final filteredReqs = requestsRaw.where((r) {
            if (filterByStatus && (r['status']?.toString() ?? 'PENDING') != _orgStatusFilter) return false;
            if (sQuery.isNotEmpty && !r['name'].toString().toLowerCase().contains(sQuery)) return false;
            if (_orgTypeFilter != 'All' && r['type'] != _orgTypeFilter.toUpperCase()) return false;
            return true;
          }).map((r) => {
                'id': 'req-${r['id']}',
                'name': r['name'],
                'official_email': r['official_email'] ?? r['requester_email'] ?? '',
                'approval_status': r['status'] ?? 'PENDING',
                'type': r['type'] == 'UNIVERSITY' ? 'University' : 'Company',
                'requester_email': r['requester_email'],
                'is_request': true,
                'request_id': r['id'],
                'document_viewed': r['document_viewed'] ?? false,
              }).toList();

          // Merge and remove duplicates by ID (include requests)
          final Map<String, dynamic> uniqueMap = {};
          for (var org in [...optimistic, ...filteredUnis, ...filteredComps, ...filteredReqs]) {
            uniqueMap[org['id'].toString()] = org;
          }
          final all = uniqueMap.values.toList();

          if (all.isEmpty)
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No organizations found'),
                ),
              ),
            );

          final hPad = responsiveValue(
            context,
            mobile: 16.0,
            tablet: 24.0,
            desktop: 32.0,
          );
          // On tablet use a 2-column grid so cards don't stretch too wide
          if (isTablet(context)) {
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildOrgCard(context, ref, all[index], isDark),
                  childCount: all.length,
                ),
              ),
            );
          }

          return SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildOrgCard(context, ref, all[index], isDark),
                childCount: all.length,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> req,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final status = req['status'] as String? ?? 'PENDING';
    final isPending = status == 'PENDING';
    final isViewed = req['document_viewed'] == true;
    final statusColor = status == 'APPROVED'
        ? Colors.green
        : (status == 'REJECTED' ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPending
              ? Colors.purple.withOpacity(0.3)
              : isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    req['type'] == 'UNIVERSITY'
                        ? Icons.account_balance_rounded
                        : Icons.business_rounded,
                    color: Colors.purple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Requested by: ${req['requester_email']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_rounded,
                          size: 16,
                          color: isViewed ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isViewed
                                ? 'Verification Document (Viewed)'
                                : 'Verification Document (New)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isViewed ? Colors.green : null,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _viewRequestDoc(context, ref, req),
                          child: const Text('View File'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            _OrgRequestActions(
              req: req,
              isDark: isDark,
              onApprove: () => _approveRequest(context, ref, req),
              onReject: () => _showRejectRequestDialog(context, ref, req),
            )
          else if (status == 'REJECTED' && req['rejection_reason'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'Reason: ${req['rejection_reason']}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.redAccent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _approveRequest(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> req,
  ) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .approveOrganizationRequest(req['id']);
      ref.invalidate(organizationRequestsProvider);
      ref.invalidate(allUniversitiesProvider);
      ref.invalidate(allCompaniesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization approved and created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectRequestDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> req,
  ) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(adminRepositoryProvider)
                    .rejectOrganizationRequest(req['id'], reason: ctrl.text);
                ref.invalidate(organizationRequestsProvider);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request rejected.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rejection failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> org,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final status = org['approval_status'] as String? ?? 'PENDING';
    final isPending = status == 'PENDING';
    final statusColor = switch (status) {
      'APPROVED' => Colors.green,
      'PENDING' => Colors.orange,
      'SUSPENDED' => Colors.red,
      'REJECTED' => Colors.grey,
      _ => Colors.grey,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(0.3)
              : isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    org['type'] == 'University'
                        ? Icons.account_balance_rounded
                        : Icons.business_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        org['official_email'] ?? 'No email',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  size: 11,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  org['type'] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (org['created_at'] != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    org['created_at'].toString().split('T')[0],
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(ref, org),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _updateStatus(ref, org, 'APPROVED'),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showOrgDetails(context, ref, org, isDark),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (status == 'APPROVED')
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showSuspendDialog(ref, org),
                        icon: const Icon(Icons.block_rounded, size: 16),
                        label: const Text('Suspend'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else if (status == 'SUSPENDED')
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _updateStatus(ref, org, 'APPROVED'),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Activate'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrgDetails(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> org,
    bool isDark,
  ) {
    final status = org['approval_status'] as String? ?? '';
    final statusColor = switch (status) {
      'APPROVED' => Colors.green,
      'PENDING' => Colors.orange,
      'SUSPENDED' => Colors.red,
      _ => Colors.grey,
    };
    final isUniversity = org['type'] == 'University';
    final orgId = _parseInt(org['id']);
    bool? studentRegEnabled; // null = inherit global

    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          snap: true,
          snapSizes: const [0.4, 0.65, 0.92],
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.all(
                responsiveValue(
                  context,
                  mobile: 16.0,
                  tablet: 32.0,
                  desktop: 48.0,
                ),
              ),
              children: [
                // Drag handle + close button row
                Row(
                  children: [
                    const Spacer(),
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
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isUniversity
                            ? Icons.account_balance_rounded
                            : Icons.business_rounded,
                        size: 28,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
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
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _detailRow(
                  Icons.category_rounded,
                  'Type',
                  org['type']?.toString() ?? '-',
                ),
                _detailRow(
                  Icons.email_rounded,
                  'Official Email',
                  org['official_email']?.toString() ?? '-',
                ),
                if (org['phone'] != null)
                  _detailRow(
                    Icons.phone_rounded,
                    'Phone',
                    org['phone'].toString(),
                  ),
                if (org['address'] != null)
                  _detailRow(
                    Icons.location_on_rounded,
                    'Address',
                    org['address'].toString(),
                  ),
                if (org['website'] != null)
                  _detailRow(
                    Icons.language_rounded,
                    'Website',
                    org['website'].toString(),
                  ),
                if (org['created_at'] != null)
                  _detailRow(
                    Icons.calendar_today_rounded,
                    'Registered',
                    org['created_at'].toString().split('T')[0],
                  ),
                // Verification document
                const SizedBox(height: 12),
                _buildDocumentRow(
                  ctx,
                  org['verification_doc']?.toString() ?? '',
                  (org['verification_doc']?.toString() ?? '').isNotEmpty,
                  isDark,
                ),
                if (org['rejection_reason'] != null &&
                    org['rejection_reason'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Rejection Reason: ${org['rejection_reason']}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Per-university student registration control (universities only)
                if (isUniversity && status == 'APPROVED') ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.indigo.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.indigo.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.how_to_reg_rounded,
                              size: 16,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Student Registration',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Override the global setting for this university only.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _regOverrideChip(
                                setModalState,
                                'Global',
                                null,
                                studentRegEnabled,
                                Colors.grey,
                                (v) async {
                                  setModalState(() => studentRegEnabled = v);
                                  if (context.mounted) Navigator.pop(context);
                                  try {
                                    await ref
                                        .read(adminRepositoryProvider)
                                        .setUniversityStudentReg(orgId, v);
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Registration set to global',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                  } catch (e) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _regOverrideChip(
                                setModalState,
                                'Open',
                                true,
                                studentRegEnabled,
                                Colors.green,
                                (v) async {
                                  setModalState(() => studentRegEnabled = v);
                                  if (context.mounted) Navigator.pop(context);
                                  try {
                                    await ref
                                        .read(adminRepositoryProvider)
                                        .setUniversityStudentReg(orgId, v);
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Registration opened'),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                  } catch (e) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _regOverrideChip(
                                setModalState,
                                'Closed',
                                false,
                                studentRegEnabled,
                                Colors.red,
                                (v) async {
                                  setModalState(() => studentRegEnabled = v);
                                  if (context.mounted) Navigator.pop(context);
                                  try {
                                    await ref
                                        .read(adminRepositoryProvider)
                                        .setUniversityStudentReg(orgId, v);
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Registration closed'),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                  } catch (e) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (status == 'SUSPENDED')
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateStatus(ref, org, 'APPROVED');
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Reactivate Organization'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _regOverrideChip(
    StateSetter setModalState,
    String label,
    bool? value,
    bool? current,
    Color color,
    void Function(bool?) onSelect,
  ) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? color : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(WidgetRef ref, Map<String, dynamic> org) {
    final reasonCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reject Organization',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    org['type'] == 'University'
                        ? Icons.account_balance_rounded
                        : Icons.business_rounded,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      org['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason for rejection',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'e.g. Incomplete documentation, invalid credentials...',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This reason will be emailed to the organization.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              Navigator.pop(ctx);
              _updateStatus(
                ref,
                org,
                'REJECTED',
                reason: reason.isEmpty ? null : reason,
              );
            },
            icon: const Icon(Icons.cancel_rounded, size: 16),
            label: const Text('Reject'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(WidgetRef ref, Map<String, dynamic> org) {
    final reasonCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Suspend Organization',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    org['type'] == 'University'
                        ? Icons.account_balance_rounded
                        : Icons.business_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      org['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason for suspension',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Policy violation, pending investigation...',
                hintStyle: const TextStyle(fontSize: 12),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.5)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The organization will lose access until reactivated.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              Navigator.pop(ctx);
              _updateStatus(
                ref,
                org,
                'SUSPENDED',
                reason: reason.isEmpty ? null : reason,
              );
            },
            icon: const Icon(Icons.block_rounded, size: 16),
            label: const Text('Suspend'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    WidgetRef ref,
    Map<String, dynamic> org,
    String status, {
    String? reason,
  }) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      final id = _parseInt(org['id']);
      if (org['type'] == 'University') {
        await repo.updateUniversityStatus(id, status, reason: reason);
      } else {
        await repo.updateCompanyStatus(id, status, reason: reason);
      }
      ref.invalidate(allUniversitiesProvider);
      ref.invalidate(allCompaniesProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(pendingUniversitiesProvider);
      ref.invalidate(pendingCompaniesProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${org['name']} → $status'),
            backgroundColor: status == 'APPROVED'
                ? Colors.green
                : status == 'REJECTED'
                ? Colors.red
                : Colors.orange,
          ),
        );
    } catch (e) {
      final msg = _extractErrorMessage(e);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $msg'), backgroundColor: Colors.red),
        );
    }
  }

  void _showCreateOrgDialog(BuildContext context, WidgetRef ref, bool isDark) {
    String orgType = 'University';
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final contactNameCtrl = TextEditingController();
    final contactEmailCtrl = TextEditingController();
    bool isSaving = false;

    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4286F4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_business_rounded,
                          color: Color(0xFF4286F4),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Organization',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Admin-created, auto-approved',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Type selector
                  Row(
                    children: [
                      Expanded(
                        child: _orgTypeChip(
                          ctx,
                          setModalState,
                          'University',
                          orgType,
                          Icons.account_balance_rounded,
                          Colors.blue,
                          (v) => orgType = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _orgTypeChip(
                          ctx,
                          setModalState,
                          'Company',
                          orgType,
                          Icons.business_rounded,
                          Colors.purple,
                          (v) => orgType = v,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _formLabel('Organization Name *'),
                  const SizedBox(height: 6),
                  _formField(
                    nameCtrl,
                    'e.g. Addis Ababa University',
                    Icons.business_rounded,
                  ),
                  const SizedBox(height: 16),
                  _formLabel('Official Email *'),
                  const SizedBox(height: 6),
                  _formField(
                    emailCtrl,
                    'e.g. info@aau.edu.et',
                    Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _formLabel('Address (optional)'),
                  const SizedBox(height: 6),
                  _formField(
                    addressCtrl,
                    'e.g. Addis Ababa, Ethiopia',
                    Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 24),
                  // Contact user section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.blue.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person_add_rounded,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Contact Person (optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Creates a ${orgType == 'University' ? 'Coordinator' : 'Supervisor'} account and sends a password setup email.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          contactNameCtrl,
                          'Full name',
                          Icons.person_rounded,
                        ),
                        const SizedBox(height: 10),
                        _formField(
                          contactEmailCtrl,
                          'Email address',
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final email = emailCtrl.text.trim();
                              if (name.isEmpty || email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Name and email are required',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSaving = true);
                              try {
                                final repo = ref.read(adminRepositoryProvider);
                                if (orgType == 'University') {
                                  await repo.createUniversity(
                                    name: name,
                                    officialEmail: email,
                                    address: addressCtrl.text.trim(),
                                    contactName: contactNameCtrl.text.trim(),
                                    contactEmail: contactEmailCtrl.text.trim(),
                                  );
                                } else {
                                  await repo.createCompany(
                                    name: name,
                                    officialEmail: email,
                                    address: addressCtrl.text.trim(),
                                    contactName: contactNameCtrl.text.trim(),
                                    contactEmail: contactEmailCtrl.text.trim(),
                                  );
                                }
                                ref.invalidate(allUniversitiesProvider);
                                ref.invalidate(allCompaniesProvider);
                                ref.invalidate(adminStatsProvider);
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$orgType "$name" created successfully${contactEmailCtrl.text.trim().isNotEmpty ? ' — setup email sent' : ''}',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        isSaving ? 'Creating...' : 'Create $orgType',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4286F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orgTypeChip(
    BuildContext ctx,
    StateSetter setModalState,
    String label,
    String current,
    IconData icon,
    Color color,
    void Function(String) onSelect,
  ) {
    final selected = current == label;
    return GestureDetector(
      onTap: () => setModalState(() => onSelect(label)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String text) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
  );

  Widget _formField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    // Replaced by _showCreateOrgDialog — kept for backward compat
    _showCreateOrgDialog(
      context,
      ref,
      Theme.of(context).brightness == Brightness.dark,
    );
  }
}

class _AdminUsersTab extends ConsumerStatefulWidget {
  const _AdminUsersTab();
  @override
  ConsumerState<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, PENDING, APPROVED, REJECTED, SUSPENDED
  final Set<int> _viewedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(adminStatsProvider);

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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            ModernSliverAppBar(
              title: 'Staff Management',
              subtitle: 'Coordinators & Supervisors',
              profileName:
                  ref.watch(userProfileProvider).value?.fullName ?? 'Admin',
              gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
              backgroundIcon: Icons.manage_accounts_rounded,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: statsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) {
                    final pendingSupsCount =
                        ref
                            .watch(pendingSupervisorsProvider)
                            .asData
                            ?.value
                            .length ??
                        0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _miniStat(
                            'Pending Coords',
                            stats.pendingCoordinators.toString(),
                            Icons.pending_rounded,
                            Colors.orange,
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _miniStat(
                            'Pending Sups',
                            stats.pendingSupervisors.toString(),
                            Icons.pending_actions_rounded,
                            Colors.purple,
                            isDark,
                          ),
                          const SizedBox(width: 12),
                          _miniStat(
                            'Total Users',
                            stats.totalUsers.toString(),
                            Icons.group_rounded,
                            Colors.grey,
                            isDark,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Material(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.school_rounded, size: 18),
                      text: 'Coordinators',
                    ),
                    Tab(
                      icon: Icon(Icons.work_rounded, size: 18),
                      text: 'Supervisors',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            [
                              'ALL',
                              'PENDING',
                              'APPROVED',
                              'REJECTED',
                              'SUSPENDED',
                            ].map((s) {
                              final selected = _statusFilter == s;
                              final color = switch (s) {
                                'APPROVED' => Colors.green,
                                'PENDING' => Colors.orange,
                                'REJECTED' => Colors.red,
                                'SUSPENDED' => Colors.grey,
                                _ => theme.colorScheme.primary,
                              };
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: selected ? Colors.white : null,
                                    ),
                                  ),
                                  selected: selected,
                                  selectedColor: color,
                                  onSelected: (_) =>
                                      setState(() => _statusFilter = s),
                                  visualDensity: VisualDensity.compact,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCoordinatorsTab(isDark),
              _buildSupervisorsTab(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinatorsTab(bool isDark) {
    final allUsersAsync = ref.watch(allUsersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allUsersProvider);
        ref.invalidate(adminStatsProvider);
      },
      child: allUsersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (users) {
                // Filter users that are coordinators
                final coords = (users as List).where((u) {
                  final role = (u['role'] ?? '').toString();
                  return role == 'COORDINATOR' || u['coordinatorProfile'] != null;
                }).toList();

                final filtered = coords.where((c) {
                  final name = (c['full_name'] ?? c['user']?['full_name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final email = (c['email'] ?? c['user']?['email'] ?? '')
                      .toString()
                      .toLowerCase();
                  final status = (c['institution_access_approval'] ?? c['user']?['institution_access_approval'] ?? 'PENDING')
                      .toString();
                  final matchesSearch = name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
                  final matchesStatus = _statusFilter == 'ALL' || status == _statusFilter;
                  return matchesSearch && matchesStatus;
                }).toList();

                if (filtered.isEmpty) return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No coordinators found', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );

                return LayoutBuilder(
                  builder: (ctx, constraints) {
                    final hPad = responsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0);
                    if (isTablet(context)) {
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 120),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _buildCoordinatorCard(context, filtered[i], isDark),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 120),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _buildCoordinatorCard(context, filtered[i], isDark),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSupervisorsTab(bool isDark) {
    final allUsersAsync = ref.watch(allUsersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allUsersProvider);
        ref.invalidate(adminStatsProvider);
      },
      child: allUsersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (users) {
                final sups = (users as List).where((u) {
                  final role = (u['role'] ?? '').toString();
                  return role == 'SUPERVISOR' || u['supervisorProfile'] != null;
                }).toList();

                final filtered = sups.where((s) {
                  final name = (s['full_name'] ?? s['user']?['full_name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final email = (s['email'] ?? s['user']?['email'] ?? '')
                      .toString()
                      .toLowerCase();
                  final status = (s['institution_access_approval'] ?? s['user']?['institution_access_approval'] ?? 'PENDING')
                      .toString();
                  final matchesSearch = name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
                  final matchesStatus = _statusFilter == 'ALL' || status == _statusFilter;
                  return matchesSearch && matchesStatus;
                }).toList();

                if (filtered.isEmpty) return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.work_rounded, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No supervisors found', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );

                return LayoutBuilder(
                  builder: (ctx, constraints) {
                    final hPad = responsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0);
                    if (isTablet(context)) {
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 120),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _buildSupervisorCard(context, filtered[i], isDark),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 120),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _buildSupervisorCard(context, filtered[i], isDark),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildCoordinatorCard(
    BuildContext context,
    dynamic coord,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final Map<String, dynamic> user = () {
      if (coord is Map<String, dynamic>) {
        if (coord['user'] is Map<String, dynamic>) return Map<String, dynamic>.from(coord['user']);
        return Map<String, dynamic>.from(coord);
      }
      return <String, dynamic>{};
    }();
    final approval =
        (user['institution_access_approval'] ?? 'PENDING') as String;
    final isPending = approval == 'PENDING';
    final rawUniName = coord['pending_university_name'] as String? ?? '';
    // Detect if coordinator selected an existing university
    final isExistingUni =
        coord['university'] != null || rawUniName.startsWith('__EXISTING__:');
    final uniName = coord['university']?['name']?.toString().isNotEmpty == true
        ? coord['university']['name'].toString()
        : rawUniName.startsWith('__EXISTING__:')
        ? rawUniName.split(':').skip(2).join(':').trim()
        : (rawUniName.isNotEmpty ? rawUniName : 'University not linked');
    final docUrl = user['verification_document']?.toString() ?? '';
    final hasDoc = docUrl.isNotEmpty;
    final userId = _parseInt(user['id']);
    final isViewed = user['document_viewed'] == true || _viewedIds.contains(userId);
    final statusColor = switch (approval) {
      'APPROVED' => Colors.green,
      'PENDING' => Colors.orange,
      'REJECTED' => Colors.red,
      'SUSPENDED' => Colors.grey,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(0.35)
              : isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                  child: Text(
                    (user['full_name'] ?? '?').toString().isNotEmpty
                        ? user['full_name'].toString()[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['full_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                              approval,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_rounded,
                            size: 11,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              uniName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Verification document row
          if (!isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _buildDocumentRow(
                context,
                docUrl,
                hasDoc,
                isDark,
                viewed: isViewed,
              ),
            ),
          // University type indicator
          if (isPending &&
              uniName.isNotEmpty &&
              uniName != 'University not linked')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isExistingUni
                      ? Colors.green.withOpacity(0.08)
                      : Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExistingUni
                        ? Colors.green.withOpacity(0.25)
                        : Colors.blue.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExistingUni
                          ? Icons.check_circle_outline_rounded
                          : Icons.add_business_rounded,
                      size: 13,
                      color: isExistingUni
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isExistingUni
                            ? 'Existing university: $uniName'
                            : 'New university request: $uniName',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isExistingUni
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isPending)
            _CoordApprovalActions(
              coord: coord,
              hasDoc: hasDoc,
              docUrl: docUrl,
              isDark: isDark,
              viewed: isViewed,
              onView: () async {
                try {
                  await ref.read(adminRepositoryProvider).markUserViewed(userId);
                  setState(() => _viewedIds.add(userId));
                } catch (_) {}
              },
              onApprove: () => _approveCoordinator(coord),
              onReject: () => _rejectCoordinator(coord),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  if (user['created_at'] != null) ...[
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user['created_at'].toString().split('T')[0],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const Spacer(),
                  ],
                  if (approval == 'APPROVED') ...[
                    TextButton.icon(
                      onPressed: () =>
                          _sendSetupLink(user['email']?.toString() ?? ''),
                      icon: const Icon(Icons.link_rounded, size: 14),
                      label: const Text(
                        'Setup Link',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _rejectCoordinator(coord),
                      icon: const Icon(Icons.block_rounded, size: 14),
                      label: const Text(
                        'Revoke',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupervisorCard(BuildContext context, dynamic sup, bool isDark) {
    final theme = Theme.of(context);
    final Map<String, dynamic> user = () {
      if (sup is Map<String, dynamic>) {
        if (sup['user'] is Map<String, dynamic>) return Map<String, dynamic>.from(sup['user']);
        return Map<String, dynamic>.from(sup);
      }
      return <String, dynamic>{};
    }();
    final Map<String, dynamic> company = () {
      if (sup is Map<String, dynamic>) {
        if (sup['company'] is Map<String, dynamic>) return Map<String, dynamic>.from(sup['company']);
        if (sup['supervisorProfile'] is Map<String, dynamic> && sup['supervisorProfile']['company'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(sup['supervisorProfile']['company']);
        }
      }
      return <String, dynamic>{};
    }();
    final approval =
        (user['institution_access_approval'] ?? 'PENDING') as String;
    final isPending = approval == 'PENDING';
    final docUrl = user['verification_document']?.toString() ?? '';
    final hasDoc = docUrl.isNotEmpty;
    final userId = _parseInt(user['id']);
    final isViewed = user['document_viewed'] == true || _viewedIds.contains(userId);
    final statusColor = switch (approval) {
      'APPROVED' => Colors.green,
      'PENDING' => Colors.orange,
      'REJECTED' => Colors.red,
      'SUSPENDED' => Colors.grey,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPending
              ? Colors.purple.withOpacity(0.35)
              : isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.purple.withOpacity(0.12),
                  child: Text(
                    (user['full_name'] ?? '?').toString().isNotEmpty
                        ? user['full_name'].toString()[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['full_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                              approval,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (company['name'] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.business_rounded,
                              size: 11,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                company['name'].toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Verification document row
          if (!isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _buildDocumentRow(
                context,
                docUrl,
                hasDoc,
                isDark,
                viewed: isViewed,
              ),
            ),
          if (isPending)
            _SupApprovalActions(
              sup: sup,
              hasDoc: hasDoc,
              docUrl: docUrl,
              isDark: isDark,
              viewed: isViewed,
              onView: () async {
                try {
                  await ref.read(adminRepositoryProvider).markUserViewed(userId);
                  setState(() => _viewedIds.add(userId));
                } catch (_) {}
              },
              onApprove: () => _approveSupervisor(sup),
              onReject: () => _rejectSupervisor(sup),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  if (user['created_at'] != null) ...[
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user['created_at'].toString().split('T')[0],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const Spacer(),
                  ],
                  if (approval == 'APPROVED') ...[
                    TextButton.icon(
                      onPressed: () =>
                          _sendSetupLink(user['email']?.toString() ?? ''),
                      icon: const Icon(Icons.link_rounded, size: 14),
                      label: const Text(
                        'Setup Link',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _rejectSupervisor(sup),
                      icon: const Icon(Icons.block_rounded, size: 14),
                      label: const Text(
                        'Revoke',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Reusable document row shown on coordinator/supervisor cards.
  Future<void> _sendSetupLink(String email) async {
    if (email.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Send Setup Link',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send a password setup email to:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The link expires in 48 hours.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send'),
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).sendSetupLink(email);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup link sent to $email'),
            backgroundColor: Colors.blue,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  Widget _miniStat(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveCoordinator(dynamic coord) async {
    final userId = _parseInt(coord['user']?['id'] ?? coord['userId']);
    if (userId == 0) return;

    final rawPendingName = coord['pending_university_name']?.toString() ?? '';
    final hasExistingUni = coord['university'] != null;
    final isNewUniRequest =
        !hasExistingUni &&
        rawPendingName.isNotEmpty &&
        !rawPendingName.startsWith('__EXISTING__:');

    // For new university requests, show a dialog so admin can correct the name
    String? universityNameOverride;
    if (isNewUniRequest) {
      final nameCtrl = TextEditingController(text: rawPendingName);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.account_balance_rounded, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'Confirm University Name',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The coordinator requested a new university. Verify or correct the name before approving.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'University Name',
                  hintText: 'e.g. Haramaya University',
                  prefixIcon: const Icon(Icons.account_balance_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      universityNameOverride = nameCtrl.text.trim().isEmpty
          ? null
          : nameCtrl.text.trim();
    }

    try {
      await ref
          .read(adminRepositoryProvider)
          .approveCoordinator(
            userId,
            universityNameOverride: universityNameOverride,
          );
      ref.invalidate(pendingCoordinatorsProvider);
      ref.invalidate(allUniversitiesProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${coord['user']?['full_name']} approved as Coordinator',
            ),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_extractErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _rejectCoordinator(dynamic coord) async {
    final userId = _parseInt(coord['user']?['id'] ?? coord['userId']);
    if (userId == 0) return;
    final name = coord['user']?['full_name'] ?? 'This coordinator';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reject Coordinator',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text('Are you sure you want to reject $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).rejectCoordinator(userId);
      ref.invalidate(pendingCoordinatorsProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name rejected'),
            backgroundColor: Colors.red,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveSupervisor(dynamic sup) async {
    final userId = _parseInt(sup['user']?['id'] ?? sup['userId']);
    if (userId == 0) return;
    try {
      await ref.read(adminRepositoryProvider).approveSupervisor(userId);
      ref.invalidate(pendingSupervisorsProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${sup['user']?['full_name']} approved as Supervisor',
            ),
            backgroundColor: Colors.purple,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _rejectSupervisor(dynamic sup) async {
    final userId = _parseInt(sup['user']?['id'] ?? sup['userId']);
    if (userId == 0) return;
    final name = sup['user']?['full_name'] ?? 'This supervisor';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reject Supervisor',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text('Are you sure you want to reject $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).rejectSupervisor(userId);
      ref.invalidate(pendingSupervisorsProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name rejected'),
            backgroundColor: Colors.red,
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

class _AdminLogsTab extends ConsumerStatefulWidget {
  const _AdminLogsTab();
  @override
  ConsumerState<_AdminLogsTab> createState() => _AdminLogsTabState();
}

class _AdminLogsTabState extends ConsumerState<_AdminLogsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _actionFilter = 'All';
  String _dateFilter = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logsAsync = ref.watch(auditLogsProvider);

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
        child: logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (logs) {
            final now = DateTime.now();
            final filtered = logs.where((l) {
              final action = (l['action'] ?? '').toString().toLowerCase();
              final details = (l['details'] ?? '').toString().toLowerCase();
              final admin = (l['admin']?['full_name'] ?? '')
                  .toString()
                  .toLowerCase();
              final q = _searchQuery.toLowerCase();
              if (q.isNotEmpty &&
                  !action.contains(q) &&
                  !details.contains(q) &&
                  !admin.contains(q))
                return false;
              if (_actionFilter != 'All' &&
                  !action.contains(_actionFilter.toLowerCase()))
                return false;
              if (_dateFilter != 'All') {
                final ts = DateTime.tryParse(l['timestamp']?.toString() ?? '');
                if (ts == null) return false;
                if (_dateFilter == 'Today' && !_sameDay(ts, now)) return false;
                if (_dateFilter == 'This Week' && now.difference(ts).inDays > 7)
                  return false;
                if (_dateFilter == 'This Month' &&
                    (ts.month != now.month || ts.year != now.year))
                  return false;
              }
              return true;
            }).toList();

            // Summary counts
            int approvals = 0, rejections = 0, suspensions = 0, creations = 0;
            for (final l in logs) {
              final a = (l['action'] ?? '').toString().toUpperCase();
              if (a.contains('APPROVE'))
                approvals++;
              else if (a.contains('REJECT'))
                rejections++;
              else if (a.contains('SUSPEND'))
                suspensions++;
              else if (a.contains('CREATE'))
                creations++;
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App bar ────────────────────────────────────────────────
                ModernSliverAppBar(
                  title: 'Audit Logs',
                  subtitle: '${logs.length} total actions recorded',
                  profileName:
                      ref.watch(userProfileProvider).value?.fullName ?? 'Admin',
                  gradient: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  backgroundIcon: Icons.receipt_long_rounded,
                  actions: [
                    IconButton(
                      onPressed: () async {
                        try {
                          final csv = await ref
                              .read(adminRepositoryProvider)
                              .exportAuditLogsCsv();
                          final filename =
                              'audit-log-${DateTime.now().millisecondsSinceEpoch}.csv';
                          downloadCsv(csv, filename);
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Audit log CSV downloaded',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Export failed: ${_extractErrorMessage(e)}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                        }
                      },
                      icon: const Icon(
                        Icons.file_download_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Export CSV',
                    ),
                  ],
                ),

                // ── Summary strip ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _logStat(
                            'Approvals',
                            approvals,
                            Colors.green,
                            Icons.check_circle_rounded,
                            isDark,
                          ),
                          const SizedBox(width: 10),
                          _logStat(
                            'Rejections',
                            rejections,
                            Colors.red,
                            Icons.cancel_rounded,
                            isDark,
                          ),
                          const SizedBox(width: 10),
                          _logStat(
                            'Suspensions',
                            suspensions,
                            Colors.orange,
                            Icons.block_rounded,
                            isDark,
                          ),
                          const SizedBox(width: 10),
                          _logStat(
                            'Creations',
                            creations,
                            Colors.blue,
                            Icons.add_circle_rounded,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Search ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search action, detail, or admin name...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Action filter chips ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip(
                            'All',
                            _actionFilter == 'All',
                            Colors.purple,
                            () => setState(() => _actionFilter = 'All'),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            'Approve',
                            _actionFilter == 'APPROVE',
                            Colors.green,
                            () => setState(() => _actionFilter = 'APPROVE'),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            'Reject',
                            _actionFilter == 'REJECT',
                            Colors.red,
                            () => setState(() => _actionFilter = 'REJECT'),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            'Suspend',
                            _actionFilter == 'SUSPEND',
                            Colors.orange,
                            () => setState(() => _actionFilter = 'SUSPEND'),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _chip(
                            'Create',
                            _actionFilter == 'CREATE',
                            Colors.blue,
                            () => setState(() => _actionFilter = 'CREATE'),
                            isDark,
                          ),
                          const SizedBox(width: 16),
                          _dateChip(
                            'All time',
                            _dateFilter == 'All',
                            () => setState(() => _dateFilter = 'All'),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _dateChip(
                            'Today',
                            _dateFilter == 'Today',
                            () => setState(() => _dateFilter = 'Today'),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _dateChip(
                            'This Week',
                            _dateFilter == 'This Week',
                            () => setState(() => _dateFilter = 'This Week'),
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _dateChip(
                            'This Month',
                            _dateFilter == 'This Month',
                            () => setState(() => _dateFilter = 'This Month'),
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Result count + clear ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timeline_rounded,
                          size: 15,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (filtered.length != logs.length) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => setState(() {
                              _actionFilter = 'All';
                              _dateFilter = 'All';
                              _searchQuery = '';
                              _searchCtrl.clear();
                            }),
                            child: Text(
                              'Clear filters',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Log list ───────────────────────────────────────────────
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 52,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No logs match your filters',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      responsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 28.0,
                        desktop: 40.0,
                      ),
                      0,
                      responsiveValue(
                        context,
                        mobile: 20.0,
                        tablet: 28.0,
                        desktop: 40.0,
                      ),
                      0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) =>
                            _logCard(filtered[i], isDark, i, filtered.length),
                        childCount: filtered.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _logStat(
    String label,
    int count,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _dateChip(
    String label,
    bool selected,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.purple.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.purple.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 11,
              color: selected ? Colors.purple : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.purple : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logCard(dynamic log, bool isDark, int index, int total) {
    final action = (log['action'] ?? '').toString();
    final color = _actionColor(action);
    final icon = _actionIcon(action);
    final adminName = (log['admin']?['full_name'] ?? 'System').toString();
    final adminEmail = (log['admin']?['email'] ?? '').toString();
    final details = (log['details'] ?? 'No details').toString();
    final ts = DateTime.tryParse(log['timestamp']?.toString() ?? '');
    final isFirst = index == 0;
    final isLast = index == total - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst
                      ? Colors.transparent
                      : Colors.grey.withOpacity(0.2),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, size: 13, color: color),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action badge + relative time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          action,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (ts != null)
                        Text(
                          _relTime(ts),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Details
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Admin row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: color.withOpacity(0.15),
                        child: Text(
                          adminName.isNotEmpty
                              ? adminName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adminName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (adminEmail.isNotEmpty)
                              Text(
                                adminEmail,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (ts != null)
                        Text(
                          '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _actionColor(String a) {
    final u = a.toUpperCase();
    if (u.contains('APPROVE')) return Colors.green;
    if (u.contains('REJECT')) return Colors.red;
    if (u.contains('SUSPEND')) return Colors.orange;
    if (u.contains('CREATE')) return Colors.blue;
    if (u.contains('DELETE')) return Colors.redAccent;
    if (u.contains('UPDATE') || u.contains('CONFIG')) return Colors.teal;
    return Colors.purple;
  }

  IconData _actionIcon(String a) {
    final u = a.toUpperCase();
    if (u.contains('APPROVE')) return Icons.check_circle_rounded;
    if (u.contains('REJECT')) return Icons.cancel_rounded;
    if (u.contains('SUSPEND')) return Icons.block_rounded;
    if (u.contains('CREATE')) return Icons.add_circle_rounded;
    if (u.contains('DELETE')) return Icons.delete_rounded;
    if (u.contains('UPDATE') || u.contains('CONFIG'))
      return Icons.settings_rounded;
    return Icons.history_rounded;
  }

  String _relTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()}w ago';
    if (d.inDays < 365) return '${(d.inDays / 30).floor()}mo ago';
    return '${(d.inDays / 365).floor()}y ago';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _AdminSettingsTab extends ConsumerStatefulWidget {
  const _AdminSettingsTab();

  @override
  ConsumerState<_AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends ConsumerState<_AdminSettingsTab> {
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastContentCtrl = TextEditingController();
  bool _isUpdating = false;
  // Optimistic local overrides — applied immediately on toggle, cleared after server confirms
  final Map<String, String> _localOverrides = {};

  @override
  void dispose() {
    _broadcastTitleCtrl.dispose();
    _broadcastContentCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateConfig(String key, String value) async {
    // Apply optimistic update immediately so the switch doesn't flip back
    setState(() {
      _localOverrides[key] = value;
      _isUpdating = true;
    });
    try {
      await ref.read(adminRepositoryProvider).updateConfig({key: value});
      // Invalidate to force a fresh fetch from server
      ref.invalidate(systemConfigProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated: $key → $value'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on failure
      if (mounted) {
        setState(() => _localOverrides.remove(key));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update $key: ${_extractErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// Returns the effective value for a config key, preferring local optimistic overrides.
  String _cfg(Map<String, String> serverConfig, String key, String fallback) {
    return _localOverrides[key] ?? serverConfig[key] ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final configAsync = ref.watch(systemConfigProvider);

    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (config) {
        final regStudent =
            _cfg(config, 'registration_student_open', 'true') == 'true';
        final regCoordinator =
            _cfg(config, 'registration_coordinator_open', 'true') == 'true';
        final regHod = _cfg(config, 'registration_hod_open', 'true') == 'true';
        final regSupervisor =
            _cfg(config, 'registration_supervisor_open', 'true') == 'true';
        final regUni =
            _cfg(config, 'registration_university_open', 'true') == 'true';
        final regComp =
            _cfg(config, 'registration_company_open', 'true') == 'true';
        final maintenance = _cfg(config, 'maintenance_mode', 'false') == 'true';
        final maintenanceMessage = _cfg(config, 'maintenance_message', '');
        final passwordMinLength = config['password_min_length'] ?? '8';
        final sessionTimeoutMin = config['session_timeout_min'] ?? '30';
        final apiRateLimitPerMin = config['api_rate_limit_per_min'] ?? '60';

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
            child: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    ModernSliverAppBar(
                      title: 'Settings',
                      subtitle: 'System Control Panel',
                      profileName:
                          ref.watch(userProfileProvider).value?.fullName ??
                          'Admin',
                      gradient: const [Color(0xFF2C3E50), Color(0xFF000000)],
                      backgroundIcon: Icons.settings_suggest_rounded,
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        responsiveValue(
                          context,
                          mobile: 20.0,
                          tablet: 32.0,
                          desktop: 48.0,
                        ),
                        20,
                        responsiveValue(
                          context,
                          mobile: 20.0,
                          tablet: 32.0,
                          desktop: 48.0,
                        ),
                        120,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // ── Registration Controls ──────────────────────────
                          _cfgCard(isDark, [
                            _cfgCardHeader(
                              'Registration Controls',
                              Icons.how_to_reg_rounded,
                              Colors.blue,
                              isDark,
                            ),
                            const SizedBox(height: 4),
                            _cfgNote(
                              'Enable or disable new registrations per role. Existing accounts are unaffected.',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _cfgLabel('USERS', isDark),
                            _switchRow(
                              'Student',
                              Icons.school_rounded,
                              Colors.blue,
                              regStudent,
                              (v) => _updateConfig(
                                'registration_student_open',
                                v.toString(),
                              ),
                              isDark,
                            ),
                            _switchRow(
                              'Coordinator',
                              Icons.account_balance_rounded,
                              Colors.indigo,
                              regCoordinator,
                              (v) => _updateConfig(
                                'registration_coordinator_open',
                                v.toString(),
                              ),
                              isDark,
                            ),
                            _switchRow(
                              'HoD',
                              Icons.supervisor_account_rounded,
                              Colors.teal,
                              regHod,
                              (v) => _updateConfig(
                                'registration_hod_open',
                                v.toString(),
                              ),
                              isDark,
                            ),
                            _switchRow(
                              'Supervisor',
                              Icons.business_center_rounded,
                              Colors.purple,
                              regSupervisor,
                              (v) => _updateConfig(
                                'registration_supervisor_open',
                                v.toString(),
                              ),
                              isDark,
                            ),
                            const Divider(height: 24),
                            _cfgLabel('INSTITUTIONS', isDark),
                            _switchRow(
                              'University',
                              Icons.account_balance_rounded,
                              Colors.blue,
                              regUni,
                              (v) => _updateConfig(
                                'registration_university_open',
                                v.toString(),
                              ),
                              isDark,
                            ),
                            _switchRow(
                              'Company',
                              Icons.business_rounded,
                              Colors.purple,
                              regComp,
                              (v) => _updateConfig(
                                'registration_company_open',
                                v.toString(),
                              ),
                              isDark,
                            ),
                            _cfgNote(
                              'Per-university student overrides → Organizations → Details.',
                              isDark,
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // ── Internship Rules ───────────────────────────────
                          _cfgCard(isDark, [
                            _cfgCardHeader(
                              'Internship Rules',
                              Icons.work_history_rounded,
                              Colors.orange,
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _cfgTapRow(
                              icon: Icons.timelapse_rounded,
                              color: Colors.orange,
                              isDark: isDark,
                              title: 'Duration Limits',
                              subtitle:
                                  'Min ${config['internship_min_weeks'] ?? '4'} weeks · Max ${config['internship_max_weeks'] ?? '24'} weeks',
                              onTap: () =>
                                  _showInternshipRulesDialog(context, config),
                            ),
                            _cfgTapRow(
                              icon: Icons.event_note_rounded,
                              color: Colors.teal,
                              isDark: isDark,
                              title: 'Weekly Plan Deadline',
                              subtitle:
                                  'Due every ${config['weekly_plan_deadline_day'] ?? 'Sunday'}',
                              onTap: () =>
                                  _showWeeklyDeadlineDialog(context, config),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // ── Maintenance Mode ───────────────────────────────
                          _cfgCard(isDark, [
                            _cfgCardHeader(
                              'Maintenance Mode',
                              Icons.construction_rounded,
                              Colors.red,
                              isDark,
                            ),
                            const SizedBox(height: 4),
                            _cfgNote(
                              'When enabled, all users see a maintenance message and cannot log in.',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                            _switchRow(
                              'Enable Maintenance',
                              Icons.construction_rounded,
                              Colors.red,
                              maintenance,
                              (v) => _updateConfig(
                                'maintenance_mode',
                                v.toString(),
                              ),
                              isDark,
                            ),
                            if (maintenance) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: TextFormField(
                                  initialValue: maintenanceMessage,
                                  onFieldSubmitted: (v) =>
                                      _updateConfig('maintenance_message', v),
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Maintenance message shown to users...',
                                    helperText: 'Press Enter to save',
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.red.withOpacity(0.04),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 16),

                          // ── Security ───────────────────────────────────────
                          _cfgCard(isDark, [
                            _cfgCardHeader(
                              'Security',
                              Icons.security_rounded,
                              Colors.green,
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _cfgTapRow(
                              icon: Icons.password_rounded,
                              color: Colors.green,
                              isDark: isDark,
                              title: 'Password Policy',
                              subtitle:
                                  'Minimum length: $passwordMinLength characters',
                              onTap: () => _showSingleValueConfigDialog(
                                context: context,
                                title: 'Password Policy',
                                label: 'Minimum password length',
                                configKey: 'password_min_length',
                                initialValue: passwordMinLength,
                                isNumber: true,
                              ),
                            ),
                            _cfgTapRow(
                              icon: Icons.timer_rounded,
                              color: Colors.blue,
                              isDark: isDark,
                              title: 'Session Timeout',
                              subtitle:
                                  '$sessionTimeoutMin minutes of inactivity',
                              onTap: () => _showSingleValueConfigDialog(
                                context: context,
                                title: 'Session Timeout',
                                label: 'Timeout (minutes)',
                                configKey: 'session_timeout_min',
                                initialValue: sessionTimeoutMin,
                                isNumber: true,
                              ),
                            ),
                            _cfgTapRow(
                              icon: Icons.speed_rounded,
                              color: Colors.purple,
                              isDark: isDark,
                              title: 'API Rate Limit',
                              subtitle:
                                  '$apiRateLimitPerMin requests per minute',
                              onTap: () => _showSingleValueConfigDialog(
                                context: context,
                                title: 'API Rate Limit',
                                label: 'Requests per minute',
                                configKey: 'api_rate_limit_per_min',
                                initialValue: apiRateLimitPerMin,
                                isNumber: true,
                              ),
                            ),
                            _cfgTapRow(
                              icon: Icons.download_rounded,
                              color: Colors.teal,
                              isDark: isDark,
                              title: 'Export Audit Logs',
                              subtitle: 'Download CSV (up to 5000 records)',
                              onTap: () async {
                                try {
                                  final csv = await ref
                                      .read(adminRepositoryProvider)
                                      .exportAuditLogsCsv();
                                  if (!mounted) return;
                                  downloadCsv(
                                    csv,
                                    'audit-log-${DateTime.now().millisecondsSinceEpoch}.csv',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Audit log CSV downloaded'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed: ${_extractErrorMessage(e)}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                }
                              },
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // ── Email / SMTP ───────────────────────────────────
                          _cfgCard(isDark, [
                            _cfgCardHeader(
                              'Email / SMTP',
                              Icons.mail_rounded,
                              Colors.blue,
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _cfgTapRow(
                              icon: Icons.settings_rounded,
                              color: Colors.blue,
                              isDark: isDark,
                              title: 'SMTP Configuration',
                              subtitle: 'Host, port, credentials',
                              onTap: () => _showSMTPDialog(context),
                            ),
                            _cfgTapRow(
                              icon: Icons.send_rounded,
                              color: Colors.green,
                              isDark: isDark,
                              title: 'Send Test Email',
                              subtitle: 'Verify SMTP connection is working',
                              onTap: () async {
                                final ok = await ref
                                    .read(adminRepositoryProvider)
                                    .testSmtp();
                                if (mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? '✓ SMTP connection successful'
                                            : '✗ SMTP connection failed',
                                      ),
                                      backgroundColor: ok
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );
                              },
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // ── Broadcast ──────────────────────────────────────
                          _cfgCard(isDark, [
                            _cfgCardHeader(
                              'Broadcast Announcement',
                              Icons.campaign_rounded,
                              Colors.deepOrange,
                              isDark,
                            ),
                            const SizedBox(height: 4),
                            _cfgNote(
                              'Sends a pinned post to the common feed and a notification to every user.',
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _broadcastTitleCtrl,
                              decoration: InputDecoration(
                                hintText: 'Announcement title...',
                                prefixIcon: const Icon(
                                  Icons.title_rounded,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.withOpacity(0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _broadcastContentCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Message content...',
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.withOpacity(0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  if (_broadcastTitleCtrl.text.trim().isEmpty ||
                                      _broadcastContentCtrl.text
                                          .trim()
                                          .isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Title and content are required',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    await ref
                                        .read(adminRepositoryProvider)
                                        .broadcast(
                                          _broadcastTitleCtrl.text.trim(),
                                          _broadcastContentCtrl.text.trim(),
                                        );
                                    _broadcastTitleCtrl.clear();
                                    _broadcastContentCtrl.clear();
                                    if (mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Announcement broadcasted to all users!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                  } catch (e) {
                                    if (mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed: ${_extractErrorMessage(e)}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                  }
                                },
                                icon: const Icon(
                                  Icons.campaign_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Send to Everyone',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // ── Onboarding shortcuts ───────────────────────────
                          _cfgCard(isDark, [
                            _cfgCardHeader(
                              'Quick Onboarding',
                              Icons.rocket_launch_rounded,
                              Colors.indigo,
                              isDark,
                            ),
                            const SizedBox(height: 4),
                            _cfgNote(
                              'Manually create organizations or resend password setup links.',
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _cfgTapRow(
                              icon: Icons.account_balance_rounded,
                              color: Colors.blue,
                              isDark: isDark,
                              title: 'Create University',
                              subtitle: 'Auto-approved · setup email sent',
                              onTap: () => _showQuickCreateDialog(
                                context,
                                'University',
                                isDark,
                              ),
                            ),
                            _cfgTapRow(
                              icon: Icons.business_rounded,
                              color: Colors.purple,
                              isDark: isDark,
                              title: 'Create Company',
                              subtitle: 'Auto-approved · setup email sent',
                              onTap: () => _showQuickCreateDialog(
                                context,
                                'Company',
                                isDark,
                              ),
                            ),
                            _cfgTapRow(
                              icon: Icons.link_rounded,
                              color: Colors.teal,
                              isDark: isDark,
                              title: 'Send Setup Link',
                              subtitle: 'Resend password setup to any user',
                              onTap: () =>
                                  _showSendSetupLinkDialog(context, isDark),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                  ],
                ),
                if (_isUpdating)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Reusable card widgets ──────────────────────────────────────────────────

  Widget _cfgCard(bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _cfgCardHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ],
    );
  }

  Widget _cfgLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _cfgNote(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _switchRow(
    String label,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _cfgTapRow({
    required IconData icon,
    required Color color,
    required bool isDark,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showInternshipRulesDialog(
    BuildContext context,
    Map<String, String> config,
  ) {
    final minWeeksCtrl = TextEditingController(
      text: config['internship_min_weeks'],
    );
    final maxWeeksCtrl = TextEditingController(
      text: config['internship_max_weeks'],
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Internship Rules'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minWeeksCtrl,
              decoration: const InputDecoration(labelText: 'Minimum Weeks'),
            ),
            TextField(
              controller: maxWeeksCtrl,
              decoration: const InputDecoration(labelText: 'Maximum Weeks'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _updateConfig('internship_min_weeks', minWeeksCtrl.text);
              _updateConfig('internship_max_weeks', maxWeeksCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save Rules'),
          ),
        ],
      ),
    );
  }

  void _showWeeklyDeadlineDialog(
    BuildContext context,
    Map<String, String> config,
  ) {
    const days = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    var selectedDay = config['weekly_plan_deadline_day'] ?? 'Sunday';
    if (!days.contains(selectedDay)) {
      selectedDay = 'Sunday';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('Weekly Plan Deadline'),
          content: DropdownButtonFormField<String>(
            isExpanded: true,
            value: selectedDay,
            items: days
                .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setLocalState(() => selectedDay = value);
              }
            },
            decoration: const InputDecoration(labelText: 'Deadline Day'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _updateConfig('weekly_plan_deadline_day', selectedDay);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Deadline'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSMTPDialog(BuildContext context) {
    final config = ref.read(systemConfigProvider).value ?? <String, String>{};
    final hostCtrl = TextEditingController(text: config['smtp_host'] ?? '');
    final portCtrl = TextEditingController(text: config['smtp_port'] ?? '');
    final userCtrl = TextEditingController(text: config['smtp_username'] ?? '');
    final passCtrl = TextEditingController(text: config['smtp_password'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SMTP Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostCtrl,
              decoration: const InputDecoration(labelText: 'Host'),
            ),
            TextField(
              controller: portCtrl,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).updateConfig({
                  'smtp_host': hostCtrl.text.trim(),
                  'smtp_port': portCtrl.text.trim(),
                  'smtp_username': userCtrl.text.trim(),
                  'smtp_password': passCtrl.text.trim(),
                });
                ref.invalidate(systemConfigProvider);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SMTP settings saved.')),
                  );
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
              }
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  void _showSingleValueConfigDialog({
    required BuildContext context,
    required String title,
    required String label,
    required String configKey,
    required String initialValue,
    bool isNumber = false,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final value = ctrl.text.trim();
              if (value.isEmpty) return;
              if (isNumber && int.tryParse(value) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number.')),
                );
                return;
              }
              await _updateConfig(configKey, value);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Quick Create Org (from Settings tab) ─────────────────────────────────

  void _showQuickCreateDialog(
    BuildContext context,
    String orgType,
    bool isDark,
  ) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final contactNameCtrl = TextEditingController();
    final contactEmailCtrl = TextEditingController();
    bool isSaving = false;
    final color = orgType == 'University' ? Colors.blue : Colors.purple;
    final icon = orgType == 'University'
        ? Icons.account_balance_rounded
        : Icons.business_rounded;

    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create $orgType',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const Text(
                            'Auto-approved, setup email sent',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Name *',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  _buildSettingsFormField(
                    nameCtrl,
                    'Organization name',
                    icon,
                    isDark,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Official Email *',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  _buildSettingsFormField(
                    emailCtrl,
                    'official@org.com',
                    Icons.email_rounded,
                    isDark,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Address (optional)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  _buildSettingsFormField(
                    addressCtrl,
                    'City, Country',
                    Icons.location_on_rounded,
                    isDark,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : color.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_add_rounded,
                              size: 15,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${orgType == 'University' ? 'Coordinator' : 'Supervisor'} Contact (optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Creates an account and sends a password setup email.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsFormField(
                          contactNameCtrl,
                          'Full name',
                          Icons.person_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingsFormField(
                          contactEmailCtrl,
                          'Email address',
                          Icons.email_outlined,
                          isDark,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final email = emailCtrl.text.trim();
                              if (name.isEmpty || email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Name and email are required',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSaving = true);
                              try {
                                final repo = ref.read(adminRepositoryProvider);
                                if (orgType == 'University') {
                                  await repo.createUniversity(
                                    name: name,
                                    officialEmail: email,
                                    address: addressCtrl.text.trim(),
                                    contactName: contactNameCtrl.text.trim(),
                                    contactEmail: contactEmailCtrl.text.trim(),
                                  );
                                } else {
                                  await repo.createCompany(
                                    name: name,
                                    officialEmail: email,
                                    address: addressCtrl.text.trim(),
                                    contactName: contactNameCtrl.text.trim(),
                                    contactEmail: contactEmailCtrl.text.trim(),
                                  );
                                }
                                ref.invalidate(allUniversitiesProvider);
                                ref.invalidate(allCompaniesProvider);
                                ref.invalidate(adminStatsProvider);
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$orgType "$name" created${contactEmailCtrl.text.trim().isNotEmpty ? ' — setup email sent' : ''}',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(isSaving ? 'Creating...' : 'Create $orgType'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsFormField(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    bool isDark, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ── Send Setup Link (from Settings tab) ──────────────────────────────────

  void _showSendSetupLinkDialog(BuildContext context, bool isDark) {
    final emailCtrl = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Send Setup Link',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the email of an existing user to send them a password setup link.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'user@example.com',
                  prefixIcon: const Icon(Icons.email_rounded, size: 18),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The link expires in 48 hours. The user must set their password before logging in.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) return;
                      setDialogState(() => isSending = true);
                      try {
                        await ref
                            .read(adminRepositoryProvider)
                            .sendSetupLink(email);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Setup link sent to $email'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSending = false);
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                      }
                    },
              icon: isSending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(isSending ? 'Sending...' : 'Send Link'),
              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}

