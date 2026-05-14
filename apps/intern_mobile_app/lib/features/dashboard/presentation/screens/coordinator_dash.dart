part of 'dashboards.dart';

class CoordinatorDashboardScreen extends StatelessWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardScaffold(
      title: 'Coordinator Portal',
      roleLabel: 'COORDINATOR',
      tabs: [
        _DashboardTab(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          view: _CoordinatorHomeTab(),
        ),
        _DashboardTab(
          label: 'HODs',
          icon: Icons.school_outlined,
          activeIcon: Icons.school_rounded,
          view: _CoordinatorHodsTab(),
          hideGlobalFab: true,
        ),
        _DashboardTab(
          label: 'Students',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          view: _CoordinatorStudentsTab(),
        ),
        _DashboardTab(
          label: 'Placements',
          icon: Icons.business_center_outlined,
          activeIcon: Icons.business_center_rounded,
          view: _CoordinatorPlacementsTab(),
        ),
        _DashboardTab(
          label: 'Companies',
          icon: Icons.business_outlined,
          activeIcon: Icons.business_rounded,
          view: _CoordinatorCompaniesTab(),
        ),
      ],
    );
  }
}

class _CoordinatorHomeTab extends ConsumerWidget {
  const _CoordinatorHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(coordinatorStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF1F5F9),
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (profile) => statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (stats) => Stack(
            children: [
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1CB5E0).withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ModernSliverAppBar(
                    title: 'Coordinator',
                    subtitle: stats.universityName,
                    profileName: profile.fullName,
                    gradient: [
                      const Color(0xFF1CB5E0),
                      const Color(0xFF000046),
                    ],
                    backgroundIcon: Icons.assessment_rounded,
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
                        Text(
                          'Quick Stats',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              context,
                              stats.totalStudents.toString(),
                              'Students',
                              Icons.people_rounded,
                              Colors.blue,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              context,
                              stats.activePlacements.toString(),
                              'Placed',
                              Icons.check_circle_rounded,
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              context,
                              stats.totalCompanies.toString(),
                              'Companies',
                              Icons.business_rounded,
                              Colors.purple,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              context,
                              stats.pendingProposals.toString(),
                              'Proposals',
                              Icons.description_rounded,
                              Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'University Analytics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPlatformAnalytics(
                          context,
                          isDark,
                          growthTitle: 'Enrollment',
                          growthTrend: '${stats.totalStudents} Total',
                          placementTitle: 'Industry Partners',
                          placementSub: '${stats.totalCompanies} Active',
                          successTitle: 'Placement Rate',
                          successRate: stats.totalStudents > 0
                              ? (stats.activePlacements / stats.totalStudents)
                                    .clamp(0.0, 1.0)
                              : 0.0,
                          submissionTitle: 'Pending HODs',
                          submissionSub: '${stats.pendingHods} Awaiting',
                        ),
                        const SizedBox(height: 32),
                        // Quick action cards
                        Row(
                          children: [
                            _quickAction(
                              context,
                              Icons.school_rounded,
                              'HODs',
                              '${stats.pendingHods} pending',
                              Colors.orange,
                              () {},
                            ),
                            const SizedBox(width: 12),
                            _quickAction(
                              context,
                              Icons.description_rounded,
                              'Reports',
                              '${stats.reportsCount} total',
                              Colors.teal,
                              () {},
                            ),
                            const SizedBox(width: 12),
                            _quickAction(
                              context,
                              Icons.business_center_rounded,
                              'Placements',
                              '${stats.activePlacements} active',
                              Colors.blue,
                              () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        FeedPreviewSection(),
                        const SizedBox(height: 32),
                        // Recent notifications from backend
                        if (stats.recentNotifications.isNotEmpty) ...[
                          Text(
                            'Recent Activity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...stats.recentNotifications.take(5).map((n) {
                            final msg = n['message'] as String? ?? '';
                            final isRead = _parseBool(n['is_read']);
                            final createdAt = n['created_at'] as String? ?? '';
                            Color color = Colors.blue;
                            IconData icon = Icons.notifications_rounded;
                            if (msg.contains('HOD') || msg.contains('hod')) {
                              color = Colors.orange;
                              icon = Icons.school_rounded;
                            } else if (msg.contains('placement') ||
                                msg.contains('assignment')) {
                              color = Colors.green;
                              icon = Icons.work_rounded;
                            } else if (msg.contains('proposal')) {
                              color = Colors.purple;
                              icon = Icons.description_rounded;
                            } else if (msg.contains('report')) {
                              color = Colors.teal;
                              icon = Icons.assessment_rounded;
                            }
                            final timeStr = createdAt.isNotEmpty
                                ? timeago.format(
                                    DateTime.tryParse(createdAt) ??
                                        DateTime.now(),
                                  )
                                : '';
                            return _buildActivityItem(
                              context,
                              isRead ? 'Activity' : '● Activity',
                              msg,
                              timeStr,
                              color,
                            );
                          }),
                        ],
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

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
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
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: color,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoordinatorHodsTab extends ConsumerStatefulWidget {
  const _CoordinatorHodsTab();
  @override
  ConsumerState<_CoordinatorHodsTab> createState() =>
      _CoordinatorHodsTabState();
}

class _CoordinatorHodsTabState extends ConsumerState<_CoordinatorHodsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final Set<int> _viewedIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 5,
      vsync: this,
    ); // All, Pending, Approved, Rejected, Suspended
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Approve / Reject ────────────────────────────────────────────────────────
  Future<void> _verify(int userId, String status, {String? reason}) async {
    try {
      await ref
          .read(coordinatorRepositoryProvider)
          .verifyHod(userId, status, reason: reason);
      ref.invalidate(coordPendingHodsProvider);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(rejectedHodsProvider);
      ref.invalidate(allHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HOD ${status.toLowerCase()} successfully.'),
            backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  // ── Suspend / Activate ──────────────────────────────────────────────────────
  Future<void> _suspend(int userId) async {
    try {
      await ref.read(coordinatorRepositoryProvider).suspendHod(userId);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(suspendedHodsProvider);
      ref.invalidate(allHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HOD account suspended.'),
            backgroundColor: Colors.orange,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _activate(int userId) async {
    try {
      await ref.read(coordinatorRepositoryProvider).activateHod(userId);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(suspendedHodsProvider);
      ref.invalidate(allHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HOD account activated.'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  void _showRejectDialog(int userId, String name) {
    final ctrl = TextEditingController();
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
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reject HOD',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 15, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
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
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Invalid credentials, wrong department...',
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
            const SizedBox(height: 6),
            Text(
              'This reason will be shared with the HOD.',
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final reason = ctrl.text.trim();
              Navigator.pop(ctx);
              _verify(
                userId,
                'REJECTED',
                reason: reason.isEmpty ? null : reason,
              );
            },
            icon: const Icon(Icons.cancel_rounded, size: 16),
            label: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(int userId, String name) {
    final ctrl = TextEditingController();
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
              'Suspend HOD',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 15,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
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
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Policy violation, under review...',
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
            const SizedBox(height: 6),
            Text(
              'The HOD will lose access until reactivated.',
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _suspend(userId);
            },
            icon: const Icon(Icons.block_rounded, size: 16),
            label: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  // ── Add HOD form ────────────────────────────────────────────────────────────
  void _showAddHodSheet() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final empCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    String? tempPassword;

    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: tempPassword != null
                // ── Success state ──────────────────────────────────────────
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'HOD Account Created',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The account is auto-approved. Share the temporary password with the HOD.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.key_rounded, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Temporary Password',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    tempPassword!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0575E6),
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  )
                // ── Form state ─────────────────────────────────────────────
                : Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00F260),
                                    Color(0xFF0575E6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Head of Department',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Account will be auto-approved',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Full Name
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        // Email
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address *',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return 'Required';
                            if (!RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v!.trim()))
                              return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        // Department
                        TextFormField(
                          controller: deptCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Department *',
                            prefixIcon: Icon(Icons.school_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        // Password info — always 123456, no field needed
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.25),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.key_rounded,
                                color: Colors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Temporary password 123456 will be set automatically. The HOD must change it on first login.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Employee ID (optional)
                        TextFormField(
                          controller: empCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID (optional)',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.blue,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'HODs added by you are auto-approved. HODs who self-register appear in the Pending tab for your review.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: loading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;
                                    setSheetState(() => loading = true);
                                    try {
                                      await ref
                                          .read(coordinatorRepositoryProvider)
                                          .createHod(
                                            fullName: nameCtrl.text,
                                            email: emailCtrl.text,
                                            department: deptCtrl.text,
                                            employeeId:
                                                empCtrl.text.trim().isEmpty
                                                ? null
                                                : empCtrl.text,
                                          );
                                      ref.invalidate(approvedHodsProvider);
                                      ref.invalidate(coordinatorStatsProvider);
                                      setSheetState(() {
                                        loading = false;
                                        tempPassword = '123456';
                                      });
                                    } catch (e) {
                                      setSheetState(() => loading = false);
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_add_rounded),
                            label: Text(
                              loading ? 'Creating...' : 'Create HOD Account',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0575E6),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingAsync = ref.watch(coordPendingHodsProvider);
    final approvedAsync = ref.watch(approvedHodsProvider);
    final rejectedAsync = ref.watch(rejectedHodsProvider);
    final suspendedAsync = ref.watch(suspendedHodsProvider);
    final allAsync = ref.watch(allHodsProvider);

    final pendingCount = pendingAsync.value?.length ?? 0;

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              ModernSliverAppBar(
                title: 'Department Heads',
                subtitle: 'HOD Management',
                profileName:
                    ref.watch(userProfileProvider).value?.fullName ??
                    'Coordinator',
                gradient: [const Color(0xFF00F260), const Color(0xFF0575E6)],
                backgroundIcon: Icons.school_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      const Tab(text: 'All'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Pending'),
                            if (pendingCount > 0) ...[
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
                                  '$pendingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(text: 'Approved'),
                      const Tab(text: 'Rejected'),
                      const Tab(text: 'Suspended'),
                    ],
                    labelColor: const Color(0xFF0575E6),
                    indicatorColor: const Color(0xFF0575E6),
                    unselectedLabelColor: Colors.grey,
                  ),
                  isDark,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildHodList(allAsync, isDark),
                _buildHodList(pendingAsync, isDark, showActions: true),
                _buildHodList(
                  approvedAsync,
                  isDark,
                  statusColor: Colors.green,
                  statusLabel: 'Approved',
                  showSuspend: true,
                ),
                _buildHodList(
                  rejectedAsync,
                  isDark,
                  statusColor: Colors.red,
                  statusLabel: 'Rejected',
                ),
                _buildHodList(
                  suspendedAsync,
                  isDark,
                  statusColor: Colors.orange,
                  statusLabel: 'Suspended',
                  showActivate: true,
                ),
              ],
            ),
          ),
          // FAB — Add HOD
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            right: 24,
            child: FloatingActionButton.extended(
              heroTag: 'coordinator_add_hod_fab',
              onPressed: _showAddHodSheet,
              backgroundColor: const Color(0xFF0575E6),
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text(
                'Add HOD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHodList(
    AsyncValue<List<dynamic>> async,
    bool isDark, {
    bool showActions = false,
    bool showSuspend = false,
    bool showActivate = false,
    Color? statusColor,
    String? statusLabel,
  }) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: $e\n\nCheck terminal for details.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      data: (hods) {
        if (hods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  showActions
                      ? 'No pending HODs'
                      : 'No ${statusLabel?.toLowerCase() ?? ''} HODs',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (showActions) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'HODs who self-register and select your university will appear here for approval.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: showActions ? hods.length + 1 : hods.length,
          itemBuilder: (ctx, i) {
            // Info banner as first item in pending list
            if (showActions && i == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blue,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These HODs self-registered and selected your university. Review their credentials and approve or reject.',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              );
            }
            final idx = showActions ? i - 1 : i;
            final hod = hods[idx] as Map<String, dynamic>;
            final user = hod['user'] as Map<String, dynamic>? ?? {};
            final name = user['full_name'] as String? ?? 'Unknown';
            final email = user['email'] as String? ?? '';
            final dept = hod['department'] as String? ?? 'N/A';
            final userId = _parseInt(user['id']);
            final approvalStatus =
                user['institution_access_approval'] as String? ?? '';
            final docUrl = user['verification_document']?.toString() ?? '';
            final hasDoc = docUrl.isNotEmpty;
            final isViewed = user['document_viewed'] == true || _viewedIds.contains(userId);

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HodDetailScreen(userId: userId),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: showActions
                                  ? [Colors.orangeAccent, Colors.deepOrange]
                                  : [
                                      const Color(0xFF00F260),
                                      const Color(0xFF0575E6),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                email,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  dept,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (statusLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentRow(
                      context,
                      docUrl,
                      hasDoc,
                      isDark,
                      viewed: isViewed,
                      onView: () async {
                        try {
                          await ref.read(coordinatorRepositoryProvider).markHodViewed(userId);
                          setState(() => _viewedIds.add(userId));
                        } catch (_) {}
                      },
                    ),
                    if (showActions) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showRejectDialog(userId, name),
                              icon: const Icon(Icons.cancel_rounded, size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Tooltip(
                              message: (hasDoc && !isViewed) ? 'Review document first' : '',
                              child: FilledButton.icon(
                                onPressed: (hasDoc && !isViewed)
                                    ? null
                                    : () => _verify(userId, 'APPROVED'),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Approve'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0575E6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (showSuspend) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showSuspendDialog(userId, name),
                          icon: const Icon(Icons.block_rounded, size: 16),
                          label: const Text('Suspend'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (showActivate) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _activate(userId),
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                          ),
                          label: const Text('Reactivate'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HodDetailScreen extends ConsumerStatefulWidget {
  const HodDetailScreen({super.key, required this.userId});
  final int userId;

  @override
  ConsumerState<HodDetailScreen> createState() => _HodDetailScreenState();
}

class _HodDetailScreenState extends ConsumerState<HodDetailScreen> {
  Future<void> _suspend() async {
    try {
      await ref.read(coordinatorRepositoryProvider).suspendHod(widget.userId);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      ref.invalidate(hodDetailProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('HOD account suspended.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _activate() async {
    try {
      await ref.read(coordinatorRepositoryProvider).activateHod(widget.userId);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      ref.invalidate(hodDetailProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('HOD account activated.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _verify(String status, {String? reason}) async {
    try {
      await ref
          .read(coordinatorRepositoryProvider)
          .verifyHod(widget.userId, status, reason: reason);
      ref.invalidate(coordPendingHodsProvider);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(rejectedHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      ref.invalidate(hodDetailProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HOD ${status.toLowerCase()} successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showRejectDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject HOD'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _verify(
                'REJECTED',
                reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detailAsync = ref.watch(hodDetailProvider(widget.userId));

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A1628)
          : const Color(0xFFF8FAFC),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.withOpacity(0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Error: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(hodDetailProvider(widget.userId)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (hod) {
          final fullName = hod['fullName'] as String? ?? 'Unknown';
          final email = hod['email'] as String? ?? '';
          final department = hod['department'] as String? ?? 'N/A';
          final phoneNumber = hod['phoneNumber'] as String?;
          final approvalStatus = hod['approvalStatus'] as String? ?? 'PENDING';
          final createdAt = hod['createdAt'] as String? ?? '';
          final studentCount = _parseInt(hod['studentCount']);

          final statusColor = approvalStatus == 'APPROVED'
              ? Colors.green
              : approvalStatus == 'SUSPENDED'
              ? Colors.orange
              : approvalStatus == 'REJECTED'
              ? Colors.red
              : Colors.blue;

          return NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              ModernSliverAppBar(
                title: fullName,
                subtitle: 'HOD Profile',
                profileName: fullName,
                gradient: const [Color(0xFF00F260), const Color(0xFF0575E6)],
                backgroundIcon: Icons.school_rounded,
              ),
            ],
            body: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              children: [
                // Status badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      approvalStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Profile info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.black.withOpacity(0.04),
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Information',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _detailRow(
                        Icons.person_rounded,
                        'Full Name',
                        fullName,
                        isDark,
                      ),
                      _detailRow(
                        Icons.alternate_email_rounded,
                        'Email',
                        email,
                        isDark,
                      ),
                      _detailRow(
                        Icons.school_rounded,
                        'Department',
                        department,
                        isDark,
                      ),
                      if (phoneNumber != null && phoneNumber.isNotEmpty)
                        _detailRow(
                          Icons.badge_outlined,
                          'Employee ID / Phone',
                          phoneNumber,
                          isDark,
                        ),
                      _detailRow(
                        Icons.people_rounded,
                        'Students',
                        '$studentCount',
                        isDark,
                      ),
                      if (createdAt.isNotEmpty)
                        _detailRow(
                          Icons.calendar_today_rounded,
                          'Joined',
                          createdAt.substring(0, 10),
                          isDark,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons
                if (approvalStatus == 'APPROVED')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _suspend,
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Suspend Account'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                if (approvalStatus == 'SUSPENDED')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _activate,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Activate Account'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                if (approvalStatus == 'PENDING') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showRejectDialog,
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
                          onPressed: () => _verify('APPROVED'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0575E6),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _CoordinatorStudentsTab extends ConsumerStatefulWidget {
  const _CoordinatorStudentsTab();
  @override
  ConsumerState<_CoordinatorStudentsTab> createState() =>
      _CoordinatorStudentsTabState();
}

class _CoordinatorStudentsTabState
    extends ConsumerState<_CoordinatorStudentsTab>
    with TickerProviderStateMixin {
  TabController? _tabCtrl;
  List<String> _departments = [];
  String _search = '';

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  void _buildTabs(List<String> depts) {
    // Only rebuild if departments actually changed
    if (_departments.length == depts.length &&
        _departments.every((d) => depts.contains(d)))
      return;
    _tabCtrl?.dispose();
    _departments = List.from(depts);
    _tabCtrl = TabController(length: depts.length + 1, vsync: this);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(coordinatorStatsProvider);
    final studentsAsync = ref.watch(coordinatorStudentsProvider);

    return studentsAsync.when(
      loading: () => Material(
        color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Material(
        color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
        child: Center(child: Text('Error: $e')),
      ),
      data: (students) {
        // Build sorted unique department list
        final deptSet = <String>{};
        for (final s in students) {
          final dept =
              (s as Map<String, dynamic>)['department'] as String? ??
              'Unassigned';
          deptSet.add(dept);
        }
        final depts = deptSet.toList()..sort();
        _buildTabs(depts);

        if (_tabCtrl == null) return const SizedBox.shrink();

        return Material(
          color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
          child: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              ModernSliverAppBar(
                title: 'Students',
                subtitle: 'University Enrollment',
                profileName:
                    ref.watch(userProfileProvider).value?.fullName ??
                    'Coordinator',
                gradient: [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
                backgroundIcon: Icons.group_rounded,
              ),
              // Stats row
              SliverToBoxAdapter(
                child: statsAsync.maybeWhen(
                  data: (stats) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        _statCard(
                          stats.totalStudents.toString(),
                          'Total',
                          Icons.people_rounded,
                          Colors.blue,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          stats.activePlacements.toString(),
                          'Placed',
                          Icons.check_circle_rounded,
                          Colors.green,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          stats.pendingHods.toString(),
                          'Pending HOD',
                          Icons.hourglass_top_rounded,
                          Colors.orange,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          depts.length.toString(),
                          'Depts',
                          Icons.domain_rounded,
                          Colors.purple,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() => _search = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              // Department tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    controller: _tabCtrl!,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: const Color(0xFFF2994A),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFFF2994A),
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      const Tab(text: 'All'),
                      ...depts.map((d) => Tab(text: d)),
                    ],
                  ),
                  isDark,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl!,
              children: [
                // All students
                _StudentList(
                  students: students,
                  filter: null,
                  search: _search,
                  isDark: isDark,
                ),
                // Per-department
                ...depts.map(
                  (dept) => _StudentList(
                    students: students,
                    filter: dept,
                    search: _search,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(
    String value,
    String label,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.04),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: color.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentList extends ConsumerWidget {
  const _StudentList({
    required this.students,
    required this.filter,
    required this.search,
    required this.isDark,
  });

  final List<dynamic> students;
  final String? filter; // null = All
  final String search;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var filtered = students.where((s) {
      final m = s as Map<String, dynamic>;
      final dept = m['department'] as String? ?? 'Unassigned';
      if (filter != null && dept != filter) return false;
      if (search.isNotEmpty) {
        final name = (m['fullName'] as String? ?? '').toLowerCase();
        final email = (m['email'] as String? ?? '').toLowerCase();
        final sid = (m['studentId'] as String? ?? '').toLowerCase();
        if (!name.contains(search) &&
            !email.contains(search) &&
            !sid.contains(search))
          return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: Colors.grey.withOpacity(0.35),
            ),
            const SizedBox(height: 12),
            Text(
              search.isNotEmpty
                  ? 'No results for "$search"'
                  : 'No students in this department',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(coordinatorStudentsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) {
          final s = filtered[i] as Map<String, dynamic>;
          final name = s['fullName'] as String? ?? 'Unknown';
          final email = s['email'] as String? ?? '';
          final dept = s['department'] as String? ?? 'Unassigned';
          final sid = s['studentId'] as String? ?? '';
          final status = s['internshipStatus'] as String? ?? 'PENDING';
          final hodStatus = s['hodApprovalStatus'] as String? ?? 'PENDING';
          final company = s['activeCompany'] as String?;

          final statusColor = status == 'PLACED'
              ? Colors.green
              : status == 'COMPLETED'
              ? Colors.blue
              : Colors.orange;

          final hodColor = hodStatus == 'APPROVED'
              ? Colors.green
              : hodStatus == 'REJECTED'
              ? Colors.red
              : Colors.orange;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.04),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2994A), Color(0xFFF2C94C)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
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
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Department chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dept,
                              style: const TextStyle(
                                color: Colors.purple,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (sid.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              sid,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (company != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@ $company',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badges — constrained so they never overflow
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: hodColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HOD: $hodStatus',
                          style: TextStyle(
                            color: hodColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CoordinatorCompaniesTab extends ConsumerStatefulWidget {
  const _CoordinatorCompaniesTab();
  @override
  ConsumerState<_CoordinatorCompaniesTab> createState() =>
      _CoordinatorCompaniesTabState();
}

class _CoordinatorCompaniesTabState
    extends ConsumerState<_CoordinatorCompaniesTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companiesAsync = ref.watch(coordinatorCompaniesProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          ModernSliverAppBar(
            title: 'Companies',
            subtitle: 'Industry Partners',
            profileName:
                ref.watch(userProfileProvider).value?.fullName ?? 'Coordinator',
            gradient: [const Color(0xFFDA22FF), const Color(0xFF9733EE)],
            backgroundIcon: Icons.business_rounded,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search companies...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          companiesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (companies) {
              final filtered = _search.isEmpty
                  ? companies
                  : companies.where((c) {
                      final m = c as Map<String, dynamic>;
                      return (m['name'] as String? ?? '')
                              .toLowerCase()
                              .contains(_search) ||
                          (m['official_email'] as String? ?? '')
                              .toLowerCase()
                              .contains(_search);
                    }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No companies found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final c = filtered[i] as Map<String, dynamic>;
                    final name = c['name'] as String? ?? 'Unknown';
                    final email = c['official_email'] as String? ?? '';
                    final status = c['approval_status'] as String? ?? 'PENDING';
                    final address = c['address'] as String? ?? '';
                    final statusColor = status == 'APPROVED'
                        ? Colors.green
                        : status == 'REJECTED'
                        ? Colors.red
                        : Colors.orange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.05),
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDA22FF), Color(0xFF9733EE)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (address.isNotEmpty)
                                  Text(
                                    address,
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: filtered.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoordinatorPlacementsTab extends ConsumerStatefulWidget {
  const _CoordinatorPlacementsTab();
  @override
  ConsumerState<_CoordinatorPlacementsTab> createState() =>
      _CoordinatorPlacementsTabState();
}

class _CoordinatorPlacementsTabState
    extends ConsumerState<_CoordinatorPlacementsTab>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late TabController _assignmentTabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _assignmentTabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _assignmentTabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentsAsync = ref.watch(coordinatorAssignmentsProvider);
    final proposalsAsync = ref.watch(coordinatorProposalsProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // ── App bar ──────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        if (!isWideScreen(context))
                          Builder(
                            builder: (ctx) => IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Placements',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Welcome back, ${ref.watch(userProfileProvider).value?.fullName.split(' ').first ?? ''}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Top-level tabs
                  TabBar(
                    controller: _tabCtrl,
                    tabs: const [
                      Tab(text: 'Active'),
                      Tab(text: 'Proposals'),
                      Tab(text: 'Analytics'),
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                  ),
                ],
              ),
            ),
          ),

          // ── Active sub-tabs (only shown when Active tab selected) ────────────
          AnimatedBuilder(
            animation: _tabCtrl,
            builder: (_, __) => _tabCtrl.index == 0
                ? Container(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    child: TabBar(
                      controller: _assignmentTabCtrl,
                      tabs: const [
                        Tab(text: 'Active'),
                        Tab(text: 'Completed'),
                        Tab(text: 'Terminated'),
                      ],
                      labelColor: const Color(0xFFFC466B),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFFFC466B),
                      indicatorWeight: 2,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Body ─────────────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Active — sub-tabbed
                TabBarView(
                  controller: _assignmentTabCtrl,
                  children: [
                    _buildAssignmentsList(assignmentsAsync, isDark, 'ACTIVE'),
                    _buildAssignmentsList(
                      assignmentsAsync,
                      isDark,
                      'COMPLETED',
                    ),
                    _buildAssignmentsList(
                      assignmentsAsync,
                      isDark,
                      'TERMINATED',
                    ),
                  ],
                ),
                // Proposals
                _buildProposalsList(proposalsAsync, isDark),
                // Analytics
                _buildAnalytics(assignmentsAsync, proposalsAsync, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(
    AsyncValue<List<dynamic>> async,
    bool isDark,
    String statusFilter,
  ) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        final filtered = items.where((a) {
          final m = a as Map<String, dynamic>;
          return statusFilter == 'ALL' ||
              (m['status'] as String? ?? '') == statusFilter;
        }).toList();

        if (filtered.isEmpty) {
          final emptyMsg = statusFilter == 'ACTIVE'
              ? 'No active placements'
              : statusFilter == 'COMPLETED'
              ? 'No completed placements yet'
              : 'No terminated placements';
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_off_rounded,
                  size: 48,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorAssignmentsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final a = filtered[i] as Map<String, dynamic>;
              final student = a['student'] as Map<String, dynamic>? ?? {};
              final studentUser =
                  student['user'] as Map<String, dynamic>? ?? {};
              final company = a['company'] as Map<String, dynamic>? ?? {};
              final name = studentUser['full_name'] as String? ?? 'Unknown';
              final dept = student['department'] as String? ?? 'N/A';
              final companyName = company['name'] as String? ?? 'N/A';
              final status = a['status'] as String? ?? 'ACTIVE';
              final startDate = a['start_date'] as String? ?? '';
              final statusColor = status == 'ACTIVE'
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
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          Text(
                            '$companyName • $dept',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (startDate.isNotEmpty)
                            Text(
                              'Since ${startDate.substring(0, 10)}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProposalsList(AsyncValue<List<dynamic>> async, bool isDark) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (proposals) {
        if (proposals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No proposals yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorProposalsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: proposals.length,
            itemBuilder: (ctx, i) {
              final p = proposals[i] as Map<String, dynamic>;
              final student = p['student'] as Map<String, dynamic>? ?? {};
              final studentUser =
                  student['user'] as Map<String, dynamic>? ?? {};
              final company = p['company'] as Map<String, dynamic>? ?? {};
              final name = studentUser['full_name'] as String? ?? 'Unknown';
              final companyName = company['name'] as String? ?? 'N/A';
              final status = p['status'] as String? ?? 'PENDING';
              final statusColor = status == 'APPROVED'
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          Text(
                            '→ $companyName',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnalytics(
    AsyncValue<List<dynamic>> assignmentsAsync,
    AsyncValue<List<dynamic>> proposalsAsync,
    bool isDark,
  ) {
    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        final active = assignments
            .where((a) => (a as Map)['status'] == 'ACTIVE')
            .length;
        final completed = assignments
            .where((a) => (a as Map)['status'] == 'COMPLETED')
            .length;
        final terminated = assignments
            .where((a) => (a as Map)['status'] == 'TERMINATED')
            .length;

        // Company distribution
        final companyMap = <String, int>{};
        for (final a in assignments) {
          final name = (a as Map)['company']?['name'] as String? ?? 'Unknown';
          companyMap[name] = (companyMap[name] ?? 0) + 1;
        }
        final topCompanies = companyMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          children: [
            const Text(
              'Placement Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _analyticsCard(
                  'Active',
                  active.toString(),
                  Colors.green,
                  isDark,
                ),
                const SizedBox(width: 12),
                _analyticsCard(
                  'Completed',
                  completed.toString(),
                  Colors.blue,
                  isDark,
                ),
                const SizedBox(width: 12),
                _analyticsCard(
                  'Terminated',
                  terminated.toString(),
                  Colors.red,
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (topCompanies.isNotEmpty) ...[
              const Text(
                'Top Companies',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...topCompanies
                  .take(5)
                  .map(
                    (e) =>
                        _companyBar(e.key, e.value, assignments.length, isDark),
                  ),
            ],
          ],
        );
      },
    );
  }

  Widget _analyticsCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companyBar(String name, int count, int total, bool isDark) {
    final pct = total > 0 ? count / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFFFC466B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFFC466B).withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFC466B),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinatorToolsTab extends ConsumerStatefulWidget {
  const _CoordinatorToolsTab();

  @override
  ConsumerState<_CoordinatorToolsTab> createState() =>
      _CoordinatorToolsTabState();
}

class _CoordinatorToolsTabState extends ConsumerState<_CoordinatorToolsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              ModernSliverAppBar(
                title: 'Tools & Insights',
                subtitle: 'Reports & Analytics',
                profileName:
                    ref.watch(userProfileProvider).value?.fullName ??
                    'Coordinator',
                gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                backgroundIcon: Icons.apps_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF11998e),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF11998e),
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Reports'),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Analytics'),
                        ),
                      ),
                    ],
                  ),
                  isDark,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _ReportsView(isDark: isDark),
                _AnalyticsView(isDark: isDark),
              ],
            ),
          ),
          // AI Assistant FAB — bottom-left to avoid overlapping other FABs
          Positioned(
            bottom: 24,
            left: 24,
            child: FloatingActionButton.extended(
              heroTag: 'coordinator_ai_fab',
              onPressed: () => context.push(AppRoutes.aiAssistant),
              backgroundColor: const Color(0xFF11998e),
              icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
              label: const Text(
                'AI Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsView extends ConsumerWidget {
  const _ReportsView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(coordinatorReportsProvider);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: Colors.grey.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No reports yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final colors = [
          Colors.teal,
          Colors.green,
          Colors.blue,
          Colors.purple,
          Colors.orange,
        ];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorReportsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: reports.length,
            itemBuilder: (ctx, i) {
              final r = reports[i] as Map<String, dynamic>;
              final student = r['student'] as Map<String, dynamic>? ?? {};
              final studentUser =
                  student['user'] as Map<String, dynamic>? ?? {};
              final name = studentUser['full_name'] as String? ?? 'Unknown';
              final dept = student['department'] as String? ?? 'N/A';
              final stamped = _parseBool(r['stamped']);
              final generatedAt = r['generated_at'] as String? ?? '';
              final pdfUrl = r['pdf_url'] as String?;
              final color = colors[i % colors.length];

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
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: color.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Row(
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
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          Text(
                            dept,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          if (generatedAt.isNotEmpty)
                            Text(
                              generatedAt.substring(0, 10),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stamped
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stamped ? 'Stamped' : 'Pending',
                        style: TextStyle(
                          color: stamped ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.download_rounded,
                        color: pdfUrl != null && pdfUrl.isNotEmpty
                            ? color
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
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Opening report…'),
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to open report. The file may not be available.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AnalyticsView extends ConsumerWidget {
  const _AnalyticsView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(coordinatorStatsProvider);
    final assignmentsAsync = ref.watch(coordinatorAssignmentsProvider);
    final proposalsAsync = ref.watch(coordinatorProposalsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(coordinatorStatsProvider);
        ref.invalidate(coordinatorAssignmentsProvider);
        ref.invalidate(coordinatorProposalsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        children: [
          // Placement rate card
          statsAsync.maybeWhen(
            data: (stats) => _sectionCard(
              isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Placement Overview',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _metricBox(
                        'Total Students',
                        stats.totalStudents.toString(),
                        Colors.blue,
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _metricBox(
                        'Placed',
                        stats.activePlacements.toString(),
                        Colors.green,
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _metricBox(
                        'Pending',
                        (stats.totalStudents - stats.activePlacements)
                            .toString(),
                        Colors.orange,
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Placement rate bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Placement Rate',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        stats.totalStudents > 0
                            ? '${((stats.activePlacements / stats.totalStudents) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats.totalStudents > 0
                          ? (stats.activePlacements / stats.totalStudents)
                                .clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // HOD stats
          statsAsync.maybeWhen(
            data: (stats) => _sectionCard(
              isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HOD Status',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _metricBox(
                        'Total',
                        stats.totalHods.toString(),
                        Colors.blue,
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _metricBox(
                        'Pending',
                        stats.pendingHods.toString(),
                        Colors.orange,
                        isDark,
                      ),
                      const SizedBox(width: 10),
                      _metricBox(
                        'Approved',
                        (stats.totalHods - stats.pendingHods).toString(),
                        Colors.green,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Proposals breakdown
          proposalsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => const SizedBox.shrink(),
            data: (proposals) {
              final pending = proposals
                  .where((p) => (p as Map)['status'] == 'PENDING')
                  .length;
              final approved = proposals
                  .where((p) => (p as Map)['status'] == 'APPROVED')
                  .length;
              final rejected = proposals
                  .where((p) => (p as Map)['status'] == 'REJECTED')
                  .length;
              return _sectionCard(
                isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proposals Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _metricBox(
                          'Total',
                          proposals.length.toString(),
                          Colors.purple,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _metricBox(
                          'Pending',
                          pending.toString(),
                          Colors.orange,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _metricBox(
                          'Approved',
                          approved.toString(),
                          Colors.green,
                          isDark,
                        ),
                      ],
                    ),
                    if (rejected > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$rejected rejected',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Company distribution from assignments
          assignmentsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (assignments) {
              final companyMap = <String, int>{};
              for (final a in assignments) {
                final name =
                    (a as Map)['company']?['name'] as String? ?? 'Unknown';
                companyMap[name] = (companyMap[name] ?? 0) + 1;
              }
              if (companyMap.isEmpty) return const SizedBox.shrink();
              final sorted = companyMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return _sectionCard(
                isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Partner Companies',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...sorted
                        .take(5)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${e.value}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF11998e),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: assignments.isNotEmpty
                                        ? e.value / assignments.length
                                        : 0,
                                    backgroundColor: const Color(
                                      0xFF11998e,
                                    ).withOpacity(0.1),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF11998e),
                                        ),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );
  }

  Widget _metricBox(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

