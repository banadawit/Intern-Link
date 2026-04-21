import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/services/session_service.dart';

import '../../data/repositories/student_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/placement_repository.dart';
import '../../data/repositories/supervisor_repository.dart';
import '../../data/repositories/coordinator_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../../plans/presentation/screens/plans_screen.dart';

// ---------------------------------------------------------
// STATE MANAGEMENT (NAVIGATION)
// ---------------------------------------------------------

final dashboardIndexProvider = Provider((ref) => ValueNotifier<int>(0));

// ---------------------------------------------------------
// REUSABLE MODERN SCAFFOLD WITH BOTTOM NAVIGATION
// ---------------------------------------------------------

class _ModernDashboardScaffold extends ConsumerStatefulWidget {
  const _ModernDashboardScaffold({
    required this.title,
    required this.roleLabel,
    required this.tabs,
  });

  final String title;
  final String roleLabel;
  final List<_DashboardTab> tabs;

  @override
  ConsumerState<_ModernDashboardScaffold> createState() => _ModernDashboardScaffoldState();
}

class _ModernDashboardScaffoldState extends ConsumerState<_ModernDashboardScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final indexNotifier = ref.watch(dashboardIndexProvider);
    
    return ListenableBuilder(
      listenable: indexNotifier,
      builder: (context, _) {
        final currentIndex = indexNotifier.value;
        return Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          drawer: _buildDrawer(context, isDark),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Deep vibrant purple to match modern AI aesthetics
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A00E0).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(AppRoutes.aiAssistant),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          body: IndexedStack(
            index: currentIndex,
            children: widget.tabs.map((t) => t.view).toList(),
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GNav(
                    rippleColor: theme.colorScheme.primary.withOpacity(0.1),
                    hoverColor: theme.colorScheme.primary.withOpacity(0.1),
                    gap: 4,
                    activeColor: theme.colorScheme.primary,
                    iconSize: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    duration: const Duration(milliseconds: 500),
                    tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                    selectedIndex: currentIndex,
                    onTabChange: (index) => indexNotifier.value = index,
                    tabs: widget.tabs.map((t) {
                      return GButton(
                        icon: t.icon,
                        text: t.label,
                        leading: Icon(
                          currentIndex == widget.tabs.indexOf(t) ? t.activeIcon : t.icon,
                          color: currentIndex == widget.tabs.indexOf(t) ? theme.colorScheme.primary : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final indexNotifier = ref.read(dashboardIndexProvider);
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_rounded, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text('Intern-Link', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.dashboard_rounded, 'Main Dashboard', () => Navigator.pop(context)),
                
                // --- Universal Features (All Roles) ---
                _buildDrawerItem(Icons.dynamic_feed_rounded, 'Common Feed', () {
                  Navigator.pop(context);
                  context.push(AppRoutes.commonFeed);
                }),
                _buildDrawerItem(Icons.notifications_active_rounded, 'Notifications', () {
                  Navigator.pop(context);
                  context.push(AppRoutes.notifications);
                }),
                _buildDrawerItem(Icons.chat_bubble_outline_rounded, 'Messages / Chat', () {
                  Navigator.pop(context);
                  context.push(AppRoutes.chat);
                }),
                _buildDrawerItem(Icons.smart_toy_rounded, 'AI Assistant', () {
                  Navigator.pop(context);
                  context.push(AppRoutes.aiAssistant);
                }),
                const Divider(color: Colors.black12, height: 32),
                
                // --- Role-Specific Features ---
                if (widget.roleLabel == 'STUDENT') ...[
                  _buildDrawerItem(Icons.assignment_ind_rounded, 'My Internship', () {
                    Navigator.pop(context);
                    indexNotifier.value = 0; // Home
                  }),
                  _buildDrawerItem(Icons.history_edu_rounded, 'Weekly Reports', () {
                    Navigator.pop(context);
                    indexNotifier.value = 1; // Plans
                  }),
                  _buildDrawerItem(Icons.business_center_rounded, 'Placement Requests', () {
                    Navigator.pop(context);
                    indexNotifier.value = 2; // Jobs/Placement
                  }),
                ] else if (widget.roleLabel == 'SUPERVISOR') ...[
                  _buildDrawerItem(Icons.people_alt_rounded, 'Assigned Students', () {
                    Navigator.pop(context);
                    indexNotifier.value = 1; // Students
                  }),
                  _buildDrawerItem(Icons.group_work_rounded, 'Team Management', () {
                    Navigator.pop(context);
                    indexNotifier.value = 2; // Teams
                  }),
                ] else if (widget.roleLabel == 'COORDINATOR') ...[
                  _buildDrawerItem(Icons.how_to_reg_rounded, 'HOD Approvals', () {
                    Navigator.pop(context);
                    indexNotifier.value = 1; // HODs Tab
                  }),
                  _buildDrawerItem(Icons.apartment_rounded, 'Company Directory', () {
                    Navigator.pop(context);
                    indexNotifier.value = 2; // Companies Tab
                  }),
                ] else if (widget.roleLabel == 'HEAD OF DEPARTMENT') ...[
                  _buildDrawerItem(Icons.groups_3_rounded, 'Department Students', () {
                    Navigator.pop(context);
                    indexNotifier.value = 0; // Home (assuming overview here)
                  }),
                ] else if (widget.roleLabel == 'ADMIN') ...[
                  _buildDrawerItem(Icons.manage_accounts_rounded, 'User Management', () {
                    Navigator.pop(context);
                    indexNotifier.value = 2; // Users Tab
                  }),
                  _buildDrawerItem(Icons.domain_verification_rounded, 'Institution Approvals', () {
                    Navigator.pop(context);
                    indexNotifier.value = 1; // Approvals Tab
                  }),
                  _buildDrawerItem(Icons.analytics_rounded, 'System Logs', () {
                    Navigator.pop(context);
                    indexNotifier.value = 3; // Logs Tab
                  }),
                ],

                const Divider(color: Colors.black12, height: 32),
                _buildDrawerItem(Icons.person_rounded, 'Account Settings', () {
                  Navigator.pop(context);
                  indexNotifier.value = widget.tabs.length - 1; // Go to last tab (Settings/Profile)
                }),
                _buildDrawerItem(Icons.help_outline_rounded, 'Help & Support', () => Navigator.pop(context)),
              ],
            ),
          ),
          _buildDrawerItem(
            Icons.logout_rounded,
            'Sign Out',
            () async {
              Navigator.pop(context);
              await ref.read(appSessionServiceProvider).clearSession();
              if (context.mounted) context.go(AppRoutes.auth);
            },
            isDestructive: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

class _DashboardTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget view;

  const _DashboardTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.view,
  });
}

// ---------------------------------------------------------
// REUSABLE MODERN SLIVER APP BAR
// ---------------------------------------------------------

class _ModernSliverAppBar extends ConsumerWidget {
  const _ModernSliverAppBar({
    required this.title,
    required this.subtitle,
    required this.profileName,
    required this.gradient,
    required this.backgroundIcon,
    this.actions,
  });

  final String title;
  final String subtitle;
  final String profileName;
  final List<Color> gradient;
  final IconData backgroundIcon;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 240,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          final deltaExtent = settings!.maxExtent - settings.minExtent;
          final t = (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent).clamp(0.0, 1.0);
          final fadeOpacity = (1.0 - t * 1.5).clamp(0.0, 1.0); // Fades out faster than it shrinks

          return FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: -50,
                    bottom: -50,
                    child: Opacity(
                      opacity: fadeOpacity,
                      child: Icon(backgroundIcon, size: 240, color: Colors.white.withOpacity(0.15)),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Opacity(
                        opacity: fadeOpacity,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) => _buildHeaderIcon(
                                  context,
                                  Icons.menu_rounded,
                                  () => Scaffold.of(context).openDrawer(),
                                ),
                              ),
                              Row(
                                children: [
                                  _buildHeaderIcon(
                                    context,
                                    Icons.chat_bubble_outline_rounded,
                                    () => context.push(AppRoutes.chat),
                                  ),
                                  const SizedBox(width: 14),
                                  _buildHeaderIcon(
                                    context,
                                    Icons.notifications_none_rounded,
                                    () => _showNotificationCenter(context),
                                  ),
                                  const SizedBox(width: 14),
                                  IconButton(
                                    onPressed: () => ref.read(dashboardIndexProvider).value = 3,
                                    icon: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        child: Text(profileName.isNotEmpty ? profileName[0].toUpperCase() : '?',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 28,
                    left: 28,
                    right: 28,
                    child: Opacity(
                      opacity: fadeOpacity,
                      child: Transform.translate(
                        offset: Offset(0, 20 * t), // Subtle slide up as it fades
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subtitle,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 6),
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildNotificationItem(context, 'System', 'Welcome to the new dashboard!', '2m ago', Icons.info_outline_rounded),
                  _buildNotificationItem(context, 'Placement', 'Your proposal was reviewed.', '1h ago', Icons.work_outline_rounded),
                  _buildNotificationItem(context, 'Admin', 'Please update your phone number.', '3h ago', Icons.warning_amber_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, String category, String text, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: const TextStyle(fontWeight: FontWeight.w600)), Text('$category • $time', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))])),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// STUDENT DASHBOARD
// ---------------------------------------------------------

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
          data: (profile) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ModernSliverAppBar(
                title: 'Welcome,',
                subtitle: profile.fullName,
                profileName: profile.fullName,
                gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                backgroundIcon: Icons.rocket_launch_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInternshipStatusHeader(context, profile),
                    const SizedBox(height: 20),
                    _buildKeyCards(context, isDark, plansAsync),
                    const SizedBox(height: 24),
                    _buildActivityHeatmap(context, isDark, plansAsync),
                    const SizedBox(height: 24),
                    _buildActiveInternshipInfo(context, isDark, profile),
                    const SizedBox(height: 20),
                    _buildRecentActivity(context, isDark, plansAsync, proposalsAsync),
                    const SizedBox(height: 20),
                    _buildCommonFeedPreview(context, isDark),
                    const SizedBox(height: 24),
                    _buildQuickActions(context, ref, theme, isDark),
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

  Widget _buildInternshipStatusHeader(BuildContext context, StudentProfile profile) {
    final theme = Theme.of(context);
    final status = _deriveInternshipStatusLabel(profile);
    final (label, color, icon) = switch (status) {
      _InternshipStatus.active => ('Active', const Color(0xFF067647), Icons.check_circle_rounded),
      _InternshipStatus.pending => ('Pending', const Color(0xFFB54708), Icons.pending_rounded),
      _InternshipStatus.notPlaced => ('Not placed', const Color(0xFFB42318), Icons.cancel_rounded),
    };

    return Row(
      children: [
        Expanded(
          child: Text(
            'Dashboard',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
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
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyCards(BuildContext context, bool isDark, AsyncValue<List<WeeklyPlan>> plansAsync) {
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
        final totalCheckins = plans.fold<int>(0, (sum, p) => sum + p.daySubmissions.length);
        final submitted = plans.length;
        final approved = plans.where((p) => p.status.toUpperCase() == 'APPROVED').length;
        final latestFeedbackPlan = plans.where((p) => (p.feedback ?? '').trim().isNotEmpty).toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(context, 'Check-ins', attendanceOrCheckinsValue, Icons.calendar_today_rounded, Colors.blue),
        _buildStatCard(context, 'Plans Progress', weeklyPlansProgressValue, Icons.assignment_turned_in_rounded, Colors.orange),
        _buildStatCard(context, 'Internship', internshipProgressValue, Icons.timeline_rounded, Colors.purple),
        _buildStatCard(context, 'Latest Feedback', latestFeedbackValue, Icons.star_rounded, Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityHeatmap(BuildContext context, bool isDark, AsyncValue<List<WeeklyPlan>> plansAsync) {
    final theme = Theme.of(context);
    return plansAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => const SizedBox.shrink(),
      data: (plans) {
        // Simple map of date strings to "intensity" (check-in counts)
        final activityMap = <String, int>{};
        for (var p in plans) {
          for (var d in p.daySubmissions) {
            final key = '${d.workDate.year}-${d.workDate.month}-${d.workDate.day}';
            activityMap[key] = (activityMap[key] ?? 0) + 1;
          }
        }

        // Generate last 14 weeks of days (simplified heatmap)
        final now = DateTime.now();
        final days = List.generate(70, (i) => now.subtract(Duration(days: 69 - i)));

        return Container(
          padding: const EdgeInsets.all(20),
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
                  Text('Activity Tracking', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Icon(Icons.insights_rounded, size: 16, color: theme.colorScheme.primary.withOpacity(0.5)),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 14,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 70,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final key = '${day.year}-${day.month}-${day.day}';
                  final count = activityMap[key] ?? 0;
                  
                  Color color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
                  if (count > 0) {
                    color = const Color(0xFF4facfe).withOpacity(0.4 + (count * 0.2).clamp(0.0, 0.6));
                  }

                  return Tooltip(
                    message: '${day.day}/${day.month}: $count check-ins',
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Less', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  const SizedBox(width: 4),
                  ...List.generate(4, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4facfe).withOpacity(0.2 + (i * 0.2)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                  const SizedBox(width: 4),
                  Text('More', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildActiveInternshipInfo(BuildContext context, bool isDark, StudentProfile profile) {
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
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Internship', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
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

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
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

    final plans = plansAsync.maybeWhen(data: (v) => v, orElse: () => const <WeeklyPlan>[]);
    final proposals = proposalsAsync.maybeWhen(data: (v) => v, orElse: () => const <PlacementProposal>[]);

    String? planStatusLine;
    String? feedbackLine;
    String? proposalLine;

    if (plans.isNotEmpty) {
      final latestPlan = (List<WeeklyPlan>.from(plans)..sort((a, b) => b.submittedAt.compareTo(a.submittedAt))).first;
      planStatusLine = 'Plan week ${latestPlan.weekNumber}: ${latestPlan.status}';

      final feedbackPlans = plans.where((p) => (p.feedback ?? '').trim().isNotEmpty).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      if (feedbackPlans.isNotEmpty) {
        feedbackLine = 'New feedback on week ${feedbackPlans.first.weekNumber}';
      }
    }

    if (proposals.isNotEmpty) {
      final latest = proposals.first;
      proposalLine = 'Proposal: ${latest.companyName} • ${latest.status}';
    }

    final items = <_ActivityItem>[
      if (feedbackLine != null) _ActivityItem(Icons.forum_rounded, feedbackLine, 'Feedback'),
      if (planStatusLine != null) _ActivityItem(Icons.assignment_turned_in_rounded, planStatusLine, 'Plans'),
      if (proposalLine != null) _ActivityItem(Icons.work_outline_rounded, proposalLine, 'Jobs'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text('No recent updates yet.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))
          else
            ...items.take(3).map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(i.icon, size: 18, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.category, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                            Text(i.text, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildCommonFeedPreview(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Text(
                  'Common Feed',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.commonFeed),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Announcements, opportunities, and updates.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 14),
          _feedPreviewRow(context, Icons.campaign_rounded, 'New announcement posted'),
          const SizedBox(height: 10),
          _feedPreviewRow(context, Icons.work_outline_rounded, 'Opportunity shared by a company'),
          const SizedBox(height: 10),
          _feedPreviewRow(context, Icons.lightbulb_outline_rounded, 'Experience tip from a student'),
        ],
      ),
    );
  }

  Widget _feedPreviewRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, size: 18),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, ThemeData theme, bool isDark) {
    return Column(
      children: [
        _buildActionRow(
          context,
          'Weekly Progress',
          'Submit your weekly report',
          Icons.edit_note_rounded,
          Colors.blue,
          () => ref.read(dashboardIndexProvider).value = 1, // Plans tab
        ),
        const SizedBox(height: 12),
        _buildActionRow(
          context,
          'Placement Info',
          'View company details',
          Icons.business_rounded,
          Colors.green,
          () => ref.read(dashboardIndexProvider).value = 2, // Jobs tab
        ),
      ],
    );
  }

  Widget _buildActionRow(
      BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
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
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
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
}

  _InternshipStatus _deriveInternshipStatusLabel(StudentProfile profile) {
    if ((profile.internshipStatus).toUpperCase() == 'PLACED' || profile.companyName != null) {
      return _InternshipStatus.active;
    }
    if ((profile.internshipStatus).toUpperCase() == 'PENDING') {
      return _InternshipStatus.pending;
    }
    return _InternshipStatus.notPlaced;
  }

class _ActivityItem {
  final IconData icon;
  final String text;
  final String category;
  _ActivityItem(this.icon, this.text, this.category);
}

enum _InternshipStatus { active, pending, notPlaced }

class _StudentPlansTab extends ConsumerWidget {
  const _StudentPlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Delegate to production-ready Plans module.
    return const PlansScreen();
  }

  void _showSubmitPlanDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final descController = TextEditingController();
    int weekNum = 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Submit Weekly Plan', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: weekNum,
              decoration: const InputDecoration(labelText: 'Week Number'),
              items: List.generate(12, (i) => i + 1).map((i) => DropdownMenuItem(value: i, child: Text('Week $i'))).toList(),
              onChanged: (v) => weekNum = v ?? weekNum,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Plan Description',
                hintText: 'What do you intend to achieve this week?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (descController.text.isEmpty) return;
              try {
                await ref.read(progressRepositoryProvider).submitWeeklyPlan(weekNum, descController.text);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ref.invalidate(myWeeklyPlansProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan submitted successfully!')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showDaySubmissionDialog(BuildContext context, WidgetRef ref, int planId) async {
    final theme = Theme.of(context);
    DateTime selectedDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: theme.colorScheme.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      try {
        final dateStr = picked.toIso8601String().split('T')[0];
        await ref.read(progressRepositoryProvider).submitPlanDay(planId, dateStr);
        if (context.mounted) {
          ref.invalidate(myWeeklyPlansProvider);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged check-in for $dateStr')));
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildPlanCard(BuildContext context, WeeklyPlan plan, bool isDark, ThemeData theme, WidgetRef ref) {
    final statusStr = plan.status.toUpperCase();
    final statusColor = statusStr == 'APPROVED' ? const Color(0xFF067647) : (statusStr == 'REJECTED' ? const Color(0xFFB42318) : const Color(0xFFB54708));
    final statusIcon = statusStr == 'APPROVED' ? Icons.check_circle_rounded : (statusStr == 'REJECTED' ? Icons.cancel_rounded : Icons.pending_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(statusStr, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 10)),
                  ],
                ),
              ),
              const Spacer(),
              Text('Week ${plan.weekNumber}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(plan.planDescription, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.7)), maxLines: 3, overflow: TextOverflow.ellipsis),
          if ((plan.presentationFileUrl ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file_rounded, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Presentation uploaded', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(
                          plan.presentationFileUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Presentation file'),
                        content: SelectableText(plan.presentationFileUrl!),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                      ),
                    ),
                    child: const Text('View'),
                  ),
                ],
              ),
            ),
          ],
          if (plan.feedback != null && plan.feedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.forum_rounded, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Feedback', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(plan.feedback!, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (plan.daySubmissions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Daily Check-ins', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.daySubmissions.map((d) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1))),
                child: Text('${d.workDate.day}/${d.workDate.month}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              )).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.event_available_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text('${plan.daySubmissions.length} Logged Days', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
              const Spacer(),
              if (statusStr == 'APPROVED')
                TextButton.icon(
                  onPressed: () => _showDaySubmissionDialog(context, ref, plan.id),
                  icon: const Icon(Icons.add_task_rounded, size: 16),
                  label: const Text('Log Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
                _ModernSliverAppBar(
                  title: 'Placements',
                  subtitle: 'Career Opportunities',
                  profileName: profile.fullName,
                  gradient: [const Color(0xFFF5AF19), const Color(0xFFF12711)],
                  backgroundIcon: Icons.work_rounded,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if ((profile.internshipStatus).toUpperCase() == 'PLACED' || profile.companyName != null) ...[
                        _buildPlacementSummaryCard(context, profile, isDark, theme),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildRequestPlacementCard(context, isDark, theme),
                        const SizedBox(height: 24),
                      ],
                      Text('Proposal Tracking', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text('Pending / Approved / Rejected', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      const SizedBox(height: 32),
                      proposalsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                        data: (proposals) => proposals.isEmpty
                            ? _buildEmptyProposals(context, isDark, theme)
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: proposals.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) => _buildProposalCard(context, proposals[index], isDark, theme),
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

  Widget _buildEmptyProposals(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1))),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.business_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.1)),
            const SizedBox(height: 24),
            const Text('No proposals yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacementSummaryCard(BuildContext context, StudentProfile profile, bool isDark, ThemeData theme) {
    final company = profile.companyName ?? 'Assigned company';
    final supervisor = profile.supervisorName ?? 'Assigned supervisor';
    final start = profile.internshipStartDate;
    final startText = start == null
        ? '—'
        : '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Placed', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.business_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(company, style: const TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_pin_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(supervisor, style: const TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Start: $startText', style: const TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPlacementCard(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Not placed yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Request placement (Open Letter) and track its status here.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showRequestPlacementBottomSheet(context),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Request placement'),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 40),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text('Request Placement', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Submit your preferred company and an open letter for consideration.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: companyController,
              decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: letterController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Open Letter / Reason', border: OutlineInputBorder(), hintText: 'Why do you want to intern here?'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Placement request submitted successfully!')));
                },
                child: const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalCard(BuildContext context, PlacementProposal p, bool isDark, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProposalDetails(context, p),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.apartment_rounded, color: theme.colorScheme.secondary)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.companyName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text(p.status, style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold))])),
            ],
          ),
        ),
      ),
    );
  }

  void _showProposalDetails(BuildContext context, PlacementProposal p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(p.companyName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(p.status, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            const Text('Proposal Letter', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(p.proposalLetter ?? 'No proposal letter attached.', style: const TextStyle(height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
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
              _ModernSliverAppBar(
                title: 'Profile',
                subtitle: 'Account Settings',
                profileName: profile.fullName,
                gradient: [const Color(0xFFee9ae5), const Color(0xFF5961f9)],
                backgroundIcon: Icons.account_circle_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(radius: 50, child: Text(profile.fullName[0], style: const TextStyle(fontSize: 32))),
                          const SizedBox(height: 16),
                          Text(profile.fullName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text(profile.email, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildProfileInfoCard(theme, isDark, 'Internship Details', [
                      _ProfileInfoRow(Icons.business_rounded, 'Company', profile.companyName ?? 'Not Assigned'),
                      _ProfileInfoRow(Icons.person_pin_rounded, 'Supervisor', profile.supervisorName ?? 'Not Assigned'),
                      _ProfileInfoRow(Icons.calendar_view_week_rounded, 'Current Week', 'Week ${profile.currentInternshipWeek}'),
                    ]),
                    const SizedBox(height: 16),
                    _buildProfileInfoCard(theme, isDark, 'Academic Status', [
                      _ProfileInfoRow(Icons.verified_user_rounded, 'Approval Status', profile.status),
                      _ProfileInfoRow(Icons.school_rounded, 'Program', 'BSc. Computer Science'), 
                    ]),
                    const SizedBox(height: 16),
                    _buildProfileInfoCard(theme, isDark, 'Final Reports & Evaluations', [
                      _ProfileInfoRow(Icons.description_rounded, 'Final Report', 'Not Uploaded', 
                        actionLabel: 'Upload', onAction: () {}),
                      _ProfileInfoRow(Icons.assignment_turned_in_rounded, 'Final Evaluation', 'Pending', 
                        actionLabel: 'View', onAction: () {}),
                    ]),
                    const SizedBox(height: 16),
                    _buildProfileInfoCard(theme, isDark, 'Account Settings', [
                      _ProfileInfoRow(Icons.lock_reset_rounded, 'Password', '********', 
                        actionLabel: 'Change', onAction: () => _showChangePasswordDialog(context)),
                      _ProfileInfoRow(Icons.notifications_active_rounded, 'Notifications', 'Enabled', 
                        actionLabel: 'Toggle', onAction: () {}),
                    ]),
                    const SizedBox(height: 40),
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(appSessionServiceProvider).clearSession();
                        if (context.mounted) context.go(AppRoutes.auth);
                      },
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

  Widget _buildProfileInfoCard(ThemeData theme, bool isDark, String title, List<_ProfileInfoRow> rows) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 20),
          ...rows.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(row.icon, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      Text(row.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                if (row.onAction != null)
                  TextButton(
                    onPressed: row.onAction,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(row.actionLabel ?? 'Edit', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 12),
            const TextField(obscureText: true, decoration: InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Update')),
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
  _ProfileInfoRow(this.icon, this.label, this.value, {this.actionLabel, this.onAction});
}

class _SupervisorOverviewTab extends ConsumerWidget {
  const _SupervisorOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(supervisorStatsProvider);

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
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (stats) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ModernSliverAppBar(
                title: 'Overview',
                subtitle: 'Management Dashboard',
                profileName: 'Supervisor',
                gradient: [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
                backgroundIcon: Icons.dashboard_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('Quick Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    _buildStatsGrid(context, stats),
                    const SizedBox(height: 32),
                    Text('Critical Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildActionCard(context, Icons.assignment_late_rounded, 'Pending Plan Reviews', '5 plans waiting for feedback', Colors.orange),
                    const SizedBox(height: 12),
                    _buildActionCard(context, Icons.rate_review_rounded, 'Final Evaluations', '3 students ready for grading', Colors.purple),
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

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)))])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, int> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(context, 'Total Students', stats['totalStudents'].toString(), Icons.people_rounded, Colors.blue),
        _buildStatCard(context, 'Pending Plans', stats['pendingPlans'].toString(), Icons.pending_actions_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 24), const Spacer(), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))]),
        ),
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
    final studentsAsync = ref.watch(supervisorStudentsProvider);

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
        child: studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (students) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ModernSliverAppBar(
                title: 'Students',
                subtitle: 'Assigned List',
                profileName: 'Supervisor',
                gradient: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                backgroundIcon: Icons.people_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStudentCard(context, students[index], isDark, theme),
                    childCount: students.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, SupervisorStudent student, bool isDark, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showStudentManagement(context, student),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 24, child: Text(student.fullName[0], style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), 
                        Text(student.email, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('ACTIVE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniStat(context, 'Progress', 'Week 4/12'),
                  _miniStat(context, 'Plans', '3 Pending'),
                  _miniStat(context, 'Attendance', '95%'),
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
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _showStudentManagement(BuildContext context, SupervisorStudent student) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(student.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            _mgmtAction(context, Icons.assignment_turned_in_rounded, 'Review Weekly Plans', 'Review and provide feedback', () {}),
            const SizedBox(height: 16),
            _mgmtAction(context, Icons.history_rounded, 'Attendance History', 'View daily check-ins', () {}),
            const SizedBox(height: 16),
            _mgmtAction(context, Icons.star_rounded, 'Final Evaluation', 'Submit technical & soft skills grade', () {}),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _mgmtAction(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1))),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)))])),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _SupervisorTeamsTab extends ConsumerWidget {
  const _SupervisorTeamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _ModernSliverAppBar(
              title: 'Teams',
              subtitle: 'Projects & Groups',
              profileName: 'Supervisor',
              gradient: [const Color(0xFF4568dc), const Color(0xFFb06ab3)],
              backgroundIcon: Icons.group_work_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildCreateTeamCard(context, isDark, theme),
                  const SizedBox(height: 32),
                  Text('Active Teams', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  _buildTeamCard(context, 'AI Integration', '3 Students', 'Module A Optimization', Colors.blue, isDark, theme),
                  const SizedBox(height: 16),
                  _buildTeamCard(context, 'Backend Scalability', '2 Students', 'Database Sharding', Colors.purple, isDark, theme),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTeamCard(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4568dc), Color(0xFFb06ab3)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF4568dc).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Structure your projects', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Create a New Team', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4568dc)),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Build Team'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, String name, String memberCount, String project, Color color, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.groups_rounded, color: color)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text(memberCount, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12))])),
              const Icon(Icons.more_vert_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const Text('PROJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(project, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SupervisorSettingsTab extends ConsumerWidget {
  const _SupervisorSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meAsync = ref.watch(supervisorMeProvider);

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
        child: meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (me) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ModernSliverAppBar(
                title: 'Settings',
                subtitle: 'Account Management',
                profileName: me.fullName,
                gradient: [const Color(0xFF8A2387), const Color(0xFFE94057)],
                backgroundIcon: Icons.settings_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _buildModernSettingItem(context, Icons.person_outline_rounded, 'Profile', 'Edit your details'),
                    const SizedBox(height: 16),
                    _buildModernSettingItem(context, Icons.security_rounded, 'Security', 'Password & auth'),
                    const SizedBox(height: 40),
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(appSessionServiceProvider).clearSession();
                        if (context.mounted) context.go(AppRoutes.auth);
                      },
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
}

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardScaffold(
      title: 'Supervisor Portal',
      roleLabel: 'SUPERVISOR',
      tabs: [
        _DashboardTab(label: 'Overview', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, view: _SupervisorOverviewTab()),
        _DashboardTab(label: 'Students', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, view: _SupervisorStudentsTab()),
        _DashboardTab(label: 'Teams', icon: Icons.group_work_outlined, activeIcon: Icons.group_work_rounded, view: _SupervisorTeamsTab()),
        _DashboardTab(label: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, view: _SupervisorSettingsTab()),
      ],
    );
  }
}

class CoordinatorDashboardScreen extends StatelessWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardScaffold(
      title: 'Coordinator Portal',
      roleLabel: 'COORDINATOR',
      tabs: [
        _DashboardTab(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, view: _CoordinatorHomeTab()),
        _DashboardTab(label: 'HODs', icon: Icons.school_outlined, activeIcon: Icons.school_rounded, view: _CoordinatorHodsTab()),
        _DashboardTab(label: 'Companies', icon: Icons.business_outlined, activeIcon: Icons.business_rounded, view: _CoordinatorCompaniesTab()),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _ModernSliverAppBar(
              title: 'Dashboard',
              subtitle: 'School Coordination',
              profileName: 'Coordinator',
              gradient: [const Color(0xFF2193b0), const Color(0xFF6dd5ed)],
              backgroundIcon: Icons.admin_panel_settings_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinatorHodsTab extends ConsumerWidget {
  const _CoordinatorHodsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hodsAsync = ref.watch(pendingHodsProvider);

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
        child: hodsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (hods) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _ModernSliverAppBar(
                title: 'HODs',
                subtitle: 'Verification Requests',
                profileName: 'Coordinator',
                gradient: [const Color(0xFFcc2b5e), const Color(0xFF753a88)],
                backgroundIcon: Icons.how_to_reg_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildHodCard(context, ref, hods[index], isDark, theme),
                    childCount: hods.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHodCard(BuildContext context, WidgetRef ref, dynamic hod, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      child: Column(
        children: [
          Row(children: [CircleAvatar(child: Text(hod['user']['full_name'][0])), const SizedBox(width: 16), Expanded(child: Text(hod['user']['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Reject'))), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: () {}, child: const Text('Approve')))]),
        ],
      ),
    );
  }
}

class _CoordinatorCompaniesTab extends ConsumerWidget {
  const _CoordinatorCompaniesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text('Companies Tab'));
  }
}

class HodDashboardScreen extends StatelessWidget {
  const HodDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardScaffold(
      title: 'HOD Portal',
      roleLabel: 'HEAD OF DEPARTMENT',
      tabs: [
        _DashboardTab(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, view: _HodHomeTab()),
      ],
    );
  }
}

class _HodHomeTab extends ConsumerWidget {
  const _HodHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const _ModernSliverAppBar(
              title: 'Dashboard',
              subtitle: 'Department Management',
              profileName: 'HOD',
              gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              backgroundIcon: Icons.account_balance_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ModernDashboardScaffold(
      title: 'Admin Portal',
      roleLabel: 'ADMIN',
      tabs: [
        _DashboardTab(label: 'Overview', icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, view: _AdminOverviewTab()),
        _DashboardTab(label: 'Approvals', icon: Icons.verified_user_outlined, activeIcon: Icons.verified_user_rounded, view: _AdminApprovalsTab()),
        _DashboardTab(label: 'Users', icon: Icons.group_outlined, activeIcon: Icons.group_rounded, view: _AdminUsersTab()),
        _DashboardTab(label: 'Logs', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, view: _AdminLogsTab()),
      ],
    );
  }
}

class _AdminOverviewTab extends ConsumerWidget {
  const _AdminOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            colors: [isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), isDark ? const Color(0xFF0F172A) : Colors.white],
          ),
        ),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (stats) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const _ModernSliverAppBar(
                title: 'Overview',
                subtitle: 'System Statistics',
                profileName: 'Admin',
                gradient: [Color(0xFF373B44), Color(0xFF4286F4)],
                backgroundIcon: Icons.analytics_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('System Health', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildStatCard(context, 'Total Users', stats.totalUsers.toString(), Icons.people_rounded, Colors.blue, isDark),
                        _buildStatCard(context, 'Universities', stats.totalUniversities.toString(), Icons.school_rounded, Colors.orange, isDark),
                        _buildStatCard(context, 'Companies', stats.totalCompanies.toString(), Icons.business_rounded, Colors.green, isDark),
                        _buildStatCard(context, 'Pending Apprs.', stats.pendingApprovals.toString(), Icons.pending_actions_rounded, Colors.red, isDark),
                      ],
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _AdminApprovalsTab extends ConsumerWidget {
  const _AdminApprovalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unisAsync = ref.watch(pendingUniversitiesProvider);
    final compsAsync = ref.watch(pendingCompaniesProvider);
    final coordsAsync = ref.watch(pendingCoordinatorsProvider);
    final supersAsync = ref.watch(pendingSupervisorsProvider);

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
        child: DefaultTabController(
          length: 4,
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _ModernSliverAppBar(
                title: 'Approvals',
                subtitle: 'Platform Verification',
                profileName: 'Admin',
                gradient: [const Color(0xFF373B44), const Color(0xFF4286F4)],
                backgroundIcon: Icons.verified_user_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    isScrollable: true,
                    tabs: const [Tab(text: 'Universities'), Tab(text: 'Companies'), Tab(text: 'Coordinators'), Tab(text: 'Supervisors')],
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  isDark,
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _buildApprovalList(context, ref, unisAsync, type: 'university'),
                _buildApprovalList(context, ref, compsAsync, type: 'company'),
                _buildApprovalList(context, ref, coordsAsync, type: 'coordinator'),
                _buildApprovalList(context, ref, supersAsync, type: 'supervisor'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalList(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> asyncData, {required String type}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No pending approvals'));
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final name = type == 'university' || type == 'company' ? item['name'] : item['user']['full_name'];
            final email = type == 'university' || type == 'company' ? item['email'] : item['user']['email'];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.account_balance_rounded, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text(email ?? 'No email', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                               final adminRepo = ref.read(adminRepositoryProvider);
                               if (type == 'university') await adminRepo.updateUniversityStatus(item['id'], 'REJECTED');
                               if (type == 'company') await adminRepo.updateCompanyStatus(item['id'], 'REJECTED');
                               if (type == 'coordinator') await adminRepo.rejectCoordinator(item['userId']);
                               if (type == 'supervisor') await adminRepo.rejectSupervisor(item['userId']);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected')));
                            } catch (e) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            try {
                               final adminRepo = ref.read(adminRepositoryProvider);
                               if (type == 'university') await adminRepo.updateUniversityStatus(item['id'], 'APPROVED');
                               if (type == 'company') await adminRepo.updateCompanyStatus(item['id'], 'APPROVED');
                               if (type == 'coordinator') await adminRepo.approveCoordinator(item['userId']);
                               if (type == 'supervisor') await adminRepo.approveSupervisor(item['userId']);
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved!')));
                            } catch (e) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminUsersTab extends ConsumerWidget {
  const _AdminUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final usersAsync = ref.watch(allUsersProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), isDark ? const Color(0xFF0F172A) : Colors.white],
          ),
        ),
        child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (users) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const _ModernSliverAppBar(
                title: 'Users',
                subtitle: 'All Registered Users',
                profileName: 'Admin',
                gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
                backgroundIcon: Icons.people_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text(user['full_name']?[0] ?? '?')),
                          title: Text(user['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${user['role']} • ${user['email']}'),
                          trailing: const Icon(Icons.more_vert_rounded),
                        ),
                      );
                    },
                    childCount: users.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminLogsTab extends ConsumerWidget {
  const _AdminLogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final logsAsync = ref.watch(auditLogsProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), isDark ? const Color(0xFF0F172A) : Colors.white],
          ),
        ),
        child: logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (logs) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const _ModernSliverAppBar(
                title: 'Audit Logs',
                subtitle: 'System Activity',
                profileName: 'Admin',
                gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                backgroundIcon: Icons.receipt_long_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final log = logs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(log['action'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('By: ${log['userId']}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: logs.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// TOP-LEVEL HELPERS & DELEGATES
// ---------------------------------------------------------

Widget _buildModernSettingItem(BuildContext context, IconData icon, String title, String subtitle) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          ],
        ),
      ),
    ),
  );
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

// ---------------------------------------------------------
// MISSING PROVIDERS (LOCAL DERIVATIONS)
// ---------------------------------------------------------

final supervisorStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final students = await ref.watch(supervisorStudentsProvider.future);
  final plans = await ref.watch(supervisorPlansProvider.future);
  return {
    'totalStudents': students.length,
    'pendingPlans': plans.where((p) => p.status.toUpperCase() == 'PENDING').length,
  };
});
