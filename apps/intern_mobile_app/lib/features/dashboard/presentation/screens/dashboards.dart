import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/services/session_service.dart';

import '../../data/repositories/student_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/placement_repository.dart';
import '../../data/repositories/admin_repository.dart';

import '../../../supervisor/data/repositories/supervisor_repository.dart';
import '../../../supervisor/domain/entities/supervisor_entities.dart';
import '../../../plans/domain/entities/weekly_plan.dart';
import '../../../plans/presentation/screens/plans_screen.dart';

// ---------------------------------------------------------
// STATE MANAGEMENT (NAVIGATION)
// ---------------------------------------------------------

final dashboardIndexProvider = StateProvider<int>((ref) => 0);

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
    int currentIndex = ref.watch(dashboardIndexProvider);
    
    // Safety check: ensure index is within bounds of current role's tabs
    if (currentIndex >= widget.tabs.length) {
      currentIndex = 0;
      // Update state in next frame to avoid build-phase state mutations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dashboardIndexProvider.notifier).state = 0;
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context, isDark, currentIndex),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
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
                gap: widget.tabs.length > 4 ? 4 : 8,
                activeColor: theme.colorScheme.primary,
                iconSize: 20,
                padding: EdgeInsets.symmetric(horizontal: widget.tabs.length > 4 ? 8 : 12, vertical: 10),
                duration: const Duration(milliseconds: 500),
                tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                selectedIndex: currentIndex,
                onTabChange: (index) => ref.read(dashboardIndexProvider.notifier).state = index,
                tabs: widget.tabs.map((t) {
                  final isSelected = currentIndex == widget.tabs.indexOf(t);
                  return GButton(
                    icon: t.icon,
                    text: t.label,
                    leading: Icon(
                      isSelected ? t.activeIcon : t.icon,
                      color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark, int currentIndex) {
    final theme = Theme.of(context);
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
                _buildDrawerItem(
                  Icons.dashboard_rounded, 
                  'Main Dashboard', 
                  () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 0;
                  },
                  isSelected: currentIndex == 0,
                ),
                
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
                    ref.read(dashboardIndexProvider.notifier).state = 0; // Home
                  }, isSelected: currentIndex == 0),
                  _buildDrawerItem(Icons.history_edu_rounded, 'Weekly Reports', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 1; // Plans
                  }, isSelected: currentIndex == 1),
                   _buildDrawerItem(Icons.business_center_rounded, 'Placement Requests', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 2; // Jobs/Placement
                  }, isSelected: currentIndex == 2),
                  const Divider(color: Colors.black12, indent: 24, endIndent: 24),
                  _buildDrawerItem(Icons.description_rounded, 'Final Report', () {
                    Navigator.pop(context);
                    context.push(AppRoutes.reports);
                  }),
                  _buildDrawerItem(Icons.star_rounded, 'Final Evaluation', () {
                    Navigator.pop(context);
                    context.push(AppRoutes.evaluations);
                  }),
                ] else if (widget.roleLabel == 'SUPERVISOR') ...[
                  _buildDrawerItem(Icons.people_alt_rounded, 'Assigned Students', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 1; // Students & Teams
                  }, isSelected: currentIndex == 1),
                  _buildDrawerItem(Icons.group_work_rounded, 'Group Teams', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 1; // Students & Teams (Group Tab)
                  }, isSelected: currentIndex == 1),
                ] else if (widget.roleLabel == 'COORDINATOR') ...[
                  _buildDrawerItem(Icons.how_to_reg_rounded, 'HOD Approvals', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 1; // HODs Tab
                  }, isSelected: currentIndex == 1),
                  _buildDrawerItem(Icons.apartment_rounded, 'Company Directory', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 2; // Companies Tab
                  }, isSelected: currentIndex == 2),
                ] else if (widget.roleLabel == 'HEAD OF DEPARTMENT') ...[
                  _buildDrawerItem(Icons.groups_3_rounded, 'Department Students', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 0; // Home (assuming overview here)
                  }, isSelected: currentIndex == 0),
                ] else if (widget.roleLabel == 'ADMIN') ...[
                  _buildDrawerItem(Icons.manage_accounts_rounded, 'User Management', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 2; // Users Tab
                  }, isSelected: currentIndex == 2),
                  _buildDrawerItem(Icons.domain_verification_rounded, 'Institution Approvals', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 1; // Approvals Tab
                  }, isSelected: currentIndex == 1),
                  _buildDrawerItem(Icons.analytics_rounded, 'System Logs', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 3; // Logs Tab
                  }, isSelected: currentIndex == 3),
                ],

                const Divider(color: Colors.black12, height: 32),
                _buildDrawerItem(Icons.person_rounded, 'Account Settings', () {
                  Navigator.pop(context);
                  context.push(AppRoutes.accountSettings);
                }),
                _buildDrawerItem(Icons.help_outline_rounded, 'Help & Support', () {
                  Navigator.pop(context);
                  context.push(AppRoutes.helpSupport);
                }),
              ],
            ),
          ),
          _buildDrawerItem(
            Icons.logout_rounded,
            'Sign Out',
            () async {
              Navigator.pop(context);
              // Reset navigation index before clearing session
              ref.read(dashboardIndexProvider.notifier).state = 0;
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

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false, bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: isDestructive ? Colors.red.withOpacity(0.1) : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isDestructive ? Colors.red : (isSelected ? Theme.of(context).colorScheme.primary : null)),
        title: Text(title, style: TextStyle(
          color: isDestructive ? Colors.red : (isSelected ? Theme.of(context).colorScheme.primary : null), 
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600
        )),
        onTap: onTap,
      ),
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

class ModernSliverAppBar extends ConsumerWidget {
  const ModernSliverAppBar({
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
      leading: Builder(
        builder: (context) {
          final bool canPop = ModalRoute.of(context)?.canPop ?? false;
          if (canPop) {
            return IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            );
          }
          return IconButton(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      expandedHeight: 220,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: gradient.first,
      actions: [
        if (actions != null) ...actions!,
        ModernHeaderIcon(
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () => context.push(AppRoutes.chat),
        ),
        const SizedBox(width: 12),
        ModernHeaderIcon(
          icon: Icons.notifications_none_rounded,
          onTap: () => _showNotificationCenter(context),
        ),
        const SizedBox(width: 12),
        ModernHeaderIcon(
          icon: Icons.dynamic_feed_rounded,
          onTap: () => context.push(AppRoutes.commonFeed),
        ),
        const SizedBox(width: 16),
      ],
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
      ),
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(

        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Mesh Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Floating Geometric Shapes (Custom Painter)
            CustomPaint(painter: _MeshPainter(color: Colors.white.withOpacity(0.1))),
            // Subsurface Blur
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Background Icon with extreme scale
            Positioned(
              right: -30,
              bottom: -20,
              child: Opacity(
                opacity: 0.15,
                child: Icon(backgroundIcon, size: 240, color: Colors.white),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                        child: Text(
                          subtitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),

                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Welcome back, ',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                        ),
                        Text(
                          profileName.split(' ')[0],
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
}

class _MeshPainter extends CustomPainter {
  final Color color;
  _MeshPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    for (var i = 0; i < size.width; i += 40) {
      path.moveTo(i.toDouble(), 0);
      path.quadraticBezierTo(i + 20, size.height / 2, i.toDouble(), size.height);
    }
    for (var i = 0; i < size.height; i += 40) {
      path.moveTo(0, i.toDouble());
      path.quadraticBezierTo(size.width / 2, i + 20, size.width, i.toDouble());
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class ModernHeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const ModernHeaderIcon({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
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

// --- SHARED ANALYTICS WIDGETS ---

Widget _buildPlatformAnalytics(BuildContext context, bool isDark, {
  String growthTitle = 'User Growth',
  String growthTrend = '+12% this month',
  String placementTitle = 'Placements',
  String placementSub = '452 Active',
  String successTitle = 'Proposal Success',
  double successRate = 0.84,
  String submissionTitle = 'Report Submissions',
  String submissionSub = '95% Weekly Target'
}) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(child: _buildChartCard(growthTitle, growthTrend, _buildLineChart(isDark), isDark)),
          const SizedBox(width: 16),
          Expanded(child: _buildChartCard(placementTitle, placementSub, _buildBarChart(isDark), isDark)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _buildChartCard(successTitle, '${(successRate * 100).toInt()}% Rate', _buildCircularProgress(successRate, Colors.blue), isDark)),
          const SizedBox(width: 16),
          Expanded(child: _buildChartCard(submissionTitle, submissionSub, _buildBarChart(isDark, color: Colors.orange), isDark)),
        ],
      ),
    ],
  );
}

Widget _buildChartCard(String title, String subtitle, Widget chart, bool isDark) {
  return Container(
    height: 180,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const Spacer(),
        SizedBox(height: 80, child: chart),
      ],
    ),
  );
}

Widget _buildLineChart(bool isDark) {
  return CustomPaint(
    size: Size.infinite,
    painter: _LineChartPainter(isDark: isDark),
  );
}

Widget _buildBarChart(bool isDark, {Color color = Colors.green}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: List.generate(7, (index) {
      final height = [40.0, 60.0, 30.0, 80.0, 50.0, 70.0, 45.0][index];
      return Container(
        width: 8,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(index == 6 ? 1.0 : 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }),
  );
}

Widget _buildCircularProgress(double value, Color color) {
  return Center(
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
        ),
        Text('${(value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
      ],
    ),
  );
}

Widget _buildSectionHeader(ThemeData theme, String title) {
  return Text(
    title,
    style: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
    ),
  );
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
          data: (profile) => Stack(
            children: [
              // Mesh Background for the whole tab
              if (isDark)
                CustomPaint(
                  size: Size.infinite,
                  painter: _MeshPainter(color: theme.colorScheme.primary.withOpacity(0.03)),
                ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ModernSliverAppBar(
                    title: 'Welcome,',
                    subtitle: profile.fullName.split(' ')[0],
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
                        const SizedBox(height: 32),

                        _buildSectionHeader(theme, 'Learning & Growth'),
                        const SizedBox(height: 16),
                        _buildPlatformAnalytics(context, isDark, 
                          growthTitle: 'Skills Progress', growthTrend: '+15% this week',
                          placementTitle: 'Tasks Completed', placementSub: '128 total',
                          successTitle: 'Quiz Score', successRate: 0.92,
                          submissionTitle: 'Attendance', submissionSub: '98% accuracy'
                        ),
                        const SizedBox(height: 32),

                        _buildAttendanceCheckin(context, isDark, plansAsync, ref),
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
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildAttendanceCheckin(BuildContext context, bool isDark, AsyncValue<List<WeeklyPlan>> plansAsync, WidgetRef ref) {
    
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
          currentPlan = plans.reduce((a, b) => a.weekNumber > b.weekNumber ? a : b);
          alreadyCheckedIn = currentPlan.checkins.any((c) => 
            '${c.date.year}-${c.date.month}-${c.date.day}' == todayKey);
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: alreadyCheckedIn 
              ? LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600])
              : const LinearGradient(colors: [Color(0xFF6a11cb), Color(0xFF2575fc)]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (alreadyCheckedIn ? Colors.green : Colors.blue).withOpacity(0.3),
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
                      alreadyCheckedIn ? Icons.check_circle_rounded : Icons.location_on_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alreadyCheckedIn ? 'Checked In Today' : 'Daily Attendance',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        Text(
                          alreadyCheckedIn 
                            ? 'Great job! See you tomorrow.'
                            : 'Don\'t forget to log your attendance.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
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
                    onPressed: currentPlan == null ? null : () async {
                      try {
                        await ref.read(progressRepositoryProvider).submitPlanDay(
                          currentPlan!.id, 
                          today.toIso8601String().split('T')[0],
                        );
                        ref.invalidate(myWeeklyPlansProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Check-in successful!')),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('CHECK IN NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
        final totalCheckins = plans.fold<int>(0, (sum, p) => sum + p.checkins.length);
        final submitted = plans.length;
        final approved = plans.where((p) => p.status.name.toUpperCase() == 'APPROVED').length;
        final latestFeedbackPlan = plans.where((p) => (p.feedback ?? '').trim().isNotEmpty).toList()
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(context, 'Check-ins', attendanceOrCheckinsValue, Icons.calendar_today_rounded, Colors.blue),
        _buildStatCard(context, 'Plans Progress', weeklyPlansProgressValue, Icons.assignment_turned_in_rounded, Colors.orange),
        _buildStatCard(context, 'Internship', internshipProgressValue, Icons.timeline_rounded, Colors.purple),
        _buildStatCard(context, 'Latest Feedback', latestFeedbackValue, Icons.star_rounded, Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ),
                Text(
                  label, 
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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




  Widget _buildActivityHeatmap(BuildContext context, bool isDark, AsyncValue<List<WeeklyPlan>> plansAsync) {
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
        final days = List.generate(70, (i) => now.subtract(Duration(days: 69 - i)));

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('ACTIVITY HEATMAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey)),
                  const Spacer(),
                  Icon(Icons.bolt_rounded, size: 16, color: theme.colorScheme.primary),
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
                  
                  Color color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
                  if (count > 0) {
                    color = theme.colorScheme.primary.withOpacity(0.3 + (count * 0.2).clamp(0.0, 0.7));
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
      final latestPlan = (List<WeeklyPlan>.from(plans)..sort((a, b) => b.createdAt.compareTo(a.createdAt))).first;
      planStatusLine = 'Plan week ${latestPlan.weekNumber}: ${latestPlan.status.name}';

      final feedbackPlans = plans.where((p) => (p.feedback ?? '').trim().isNotEmpty).toList()
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
          () => ref.read(dashboardIndexProvider.notifier).state = 1, // Plans tab
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
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('OFFICIAL STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(company.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                ),

                const SizedBox(height: 8),
                Text('Senior Intern Program', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                _extremeInfoRow(Icons.person_pin_rounded, 'Supervisor', supervisor, theme),
                const SizedBox(height: 24),
                _extremeInfoRow(Icons.event_available_rounded, 'Started On', startText, theme),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text('You are performing in the top 10% of interns in this organization.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _extremeInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestPlacementCard(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&q=80&w=1000'),
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
                const Text('ELEVATE YOUR CAREER', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 8),
                const Text('Find Your\nPerfect Match', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton(
                    onPressed: () => _showRequestPlacementBottomSheet(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('EXPLORE OPPORTUNITIES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(32, 32, 32, MediaQuery.of(ctx).viewInsets.bottom + 40),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 40),
            const Text('NEW APPLICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text('Where to next?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 40),
            _extremeTextField(companyController, 'Company Name', Icons.business_rounded, theme),
            const SizedBox(height: 20),
            _extremeTextField(letterController, 'Cover Letter', Icons.description_rounded, theme, maxLines: 5),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 70,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application Sent!')));
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: Colors.black,
                ),
                child: const Text('SUBMIT APPLICATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _extremeTextField(TextEditingController ctrl, String label, IconData icon, ThemeData theme, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(24),
      ),
    );
  }

  Widget _buildProposalCard(BuildContext context, PlacementProposal p, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.apartment_rounded, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.companyName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(p.status.toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showProposalDetails(context, p),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary.withOpacity(0.1)),
          ),
        ],
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
              ModernSliverAppBar(
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
                        actionLabel: 'View', onAction: () => context.push(AppRoutes.reports)),
                      _ProfileInfoRow(Icons.assignment_turned_in_rounded, 'Final Evaluation', 'Pending', 
                        actionLabel: 'View', onAction: () => context.push(AppRoutes.evaluations)),
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

  Widget _buildProfileInfoCard(ThemeData theme, bool isDark, String title, List<_ProfileInfoRow> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: theme.colorScheme.primary)),
          const SizedBox(height: 32),
          ...rows.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                  child: Icon(row.icon, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(row.value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
          )),
        ],
      ),
    );
  }


  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Security Update', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update your password to keep your account secure.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            TextField(
              obscureText: true, 
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true, 
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                  colors: [const Color(0xFFF2994A).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFFF2C94C).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (stats) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ModernSliverAppBar(
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

                    _buildSectionHeader(theme, 'Student Performance'),
                    const SizedBox(height: 16),
                    _buildPlatformAnalytics(context, isDark,
                      growthTitle: 'Evaluation Trend', growthTrend: 'Upward +5%',
                      placementTitle: 'Student Activity', placementSub: '85% active',
                      successTitle: 'Avg. Grade', successRate: 0.78,
                      submissionTitle: 'Report Reviews', submissionSub: '92% completed'
                    ),
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
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, SupervisorStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _buildStatCard(context, 'Assigned Students', stats.totalStudents.toString(), Icons.people_rounded, Colors.blue),
        _buildStatCard(context, 'Pending Proposals', stats.pendingProposals.toString(), Icons.assignment_ind_rounded, Colors.purple),
        _buildStatCard(context, 'Pending Reviews', stats.pendingPlans.toString(), Icons.pending_actions_rounded, Colors.orange),
        _buildStatCard(context, 'Reports Due', stats.reportsDue.toString(), Icons.description_rounded, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white, 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Icon(Icons.trending_up_rounded, color: Colors.green, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ],
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
                    colors: [const Color(0xFF11998e).withOpacity(0.15), Colors.transparent],
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
                    colors: [const Color(0xFF38ef7d).withOpacity(0.15), Colors.transparent],
                  ),
                ),
              ),
            ),
            NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              ModernSliverAppBar(
                title: 'Interns',
                subtitle: 'Manage Assigned List',
                profileName: 'Supervisor',
                gradient: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                backgroundIcon: Icons.people_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    tabs: const [Tab(text: 'Individual List'), Tab(text: 'Group Teams')],
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

  Widget _buildStudentsList(BuildContext context, WidgetRef ref, bool isDark, ThemeData theme) {
    final studentsAsync = ref.watch(supervisorStudentsProvider);
    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (students) => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStudentCard(context, students[index], isDark, theme, ref),
                childCount: students.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, SupervisorStudent student, bool isDark, ThemeData theme, WidgetRef ref) {
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

  void _showStudentManagement(BuildContext context, SupervisorStudent student, WidgetRef ref) {
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
            Text(student.universityName, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            _mgmtAction(context, Icons.assignment_turned_in_rounded, 'Review Weekly Plans', 'Review and provide feedback', () {
              Navigator.pop(ctx);
              ref.read(dashboardIndexProvider.notifier).state = 2; // Go to Workflow
            }),
            const SizedBox(height: 16),
            _mgmtAction(context, Icons.group_add_rounded, 'Assign Team', 'Add student to a project group', () {
              Navigator.pop(ctx);
              _showAssignTeamDialog(context, student, ref);
            }),
            const SizedBox(height: 16),
            _mgmtAction(context, Icons.star_rounded, 'Final Evaluation', 'Submit technical & soft skills grade', () {
              Navigator.pop(ctx);
              _showEvaluationDialog(context, student, ref);
            }),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showEvaluationDialog(BuildContext context, SupervisorStudent student, WidgetRef ref) {
    final techCtrl = TextEditingController();
    final softCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Evaluate ${student.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: techCtrl, decoration: const InputDecoration(labelText: 'Technical Score (0-100)')),
            TextField(controller: softCtrl, decoration: const InputDecoration(labelText: 'Soft Skills Score (0-100)')),
            TextField(controller: commentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Final Comments')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(supervisorRepositoryProvider).submitEvaluation(
                studentId: student.id,
                technicalScore: double.parse(techCtrl.text),
                softSkillScore: double.parse(softCtrl.text),
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

  void _showAssignTeamDialog(BuildContext context, SupervisorStudent student, WidgetRef ref) {
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
            children: teams.map((team) => ListTile(
              title: Text(team.name),
              trailing: const Icon(Icons.add_rounded),
              onTap: () async {
                await ref.read(supervisorRepositoryProvider).addTeamMember(team.id, student.id);
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(supervisorTeamsProvider);
              },
            )).toList(),
          ),
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

class _SupervisorManagementTab extends ConsumerWidget {
  const _SupervisorManagementTab();

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
                    colors: [const Color(0xFF6a11cb).withOpacity(0.15), Colors.transparent],
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
                    colors: [const Color(0xFF2575fc).withOpacity(0.15), Colors.transparent],
                  ),
                ),
              ),
            ),
            NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              ModernSliverAppBar(
                title: 'Management',
                subtitle: 'Approvals & Tracking',
                profileName: 'Supervisor',
                gradient: [const Color(0xFF6a11cb), const Color(0xFF2575fc)],
                backgroundIcon: Icons.fact_check_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    tabs: const [Tab(text: 'Workflows'), Tab(text: 'Tracking')],
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
            body: const TabBarView(
              children: [
                _SupervisorWorkflowTabContent(),
                _SupervisorTrackingTabContent(),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupervisorWorkflowTabContent extends ConsumerWidget {
  const _SupervisorWorkflowTabContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final proposalsAsync = ref.watch(supervisorIncomingProposalsProvider);
    final plansAsync = ref.watch(supervisorPendingPlansProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader(theme, 'Placement Proposals'),
              const SizedBox(height: 16),
              proposalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (proposals) => proposals.isEmpty 
                  ? const Center(child: Text('No pending proposals'))
                  : Column(children: proposals.map<Widget>((p) => _buildProposalWorkflowCard(context, p, ref, isDark)).toList()),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, 'Weekly Plan Reviews'),
              const SizedBox(height: 16),
              plansAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (plans) => plans.isEmpty 
                  ? const Center(child: Text('No pending plans'))
                  : Column(children: plans.map<Widget>((p) => _buildPlanWorkflowCard(context, p, ref, isDark)).toList()),
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProposalWorkflowCard(BuildContext context, InternshipProposal p, WidgetRef ref, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              CircleAvatar(child: Text(p.studentName[0])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.studentName, style: const TextStyle(fontWeight: FontWeight.bold)), Text(p.universityName, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
            ],
          ),
          const SizedBox(height: 16),
          Text(p.type, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue)),
          Text('Duration: ${p.durationWeeks} Weeks', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => _respond(p.id, false, ref), child: const Text('Reject'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => _respond(p.id, true, ref), child: const Text('Approve'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanWorkflowCard(BuildContext context, WeeklyPlan p, WidgetRef ref, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Week ${p.weekNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text(p.objectives, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => _reviewPlan(p.id, false, ref), child: const Text('Reject'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => _reviewPlan(p.id, true, ref), child: const Text('Approve'))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _respond(int id, bool approve, WidgetRef ref) async {
    await ref.read(supervisorRepositoryProvider).respondToProposal(id, approve: approve);
    ref.invalidate(supervisorIncomingProposalsProvider);
    ref.invalidate(supervisorStatsProvider);
  }

  Future<void> _reviewPlan(int id, bool approve, WidgetRef ref) async {
    await ref.read(supervisorRepositoryProvider).reviewPlan(id, approve: approve);
    ref.invalidate(supervisorPendingPlansProvider);
    ref.invalidate(supervisorStatsProvider);
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
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionHeader(theme, 'Daily Check-ins'),
              const SizedBox(height: 16),
              heatmapAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (heatmap) => _buildAttendanceHeatmap(context, heatmap, isDark),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, 'Weekly Execution Reports'),
              const SizedBox(height: 16),
              reportsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
                data: (reports) => reports.isEmpty 
                  ? const Center(child: Text('No reports submitted yet.'))
                  : Column(children: reports.map<Widget>((r) => _buildReportTrackingCard(context, r, isDark)).toList()),
              ),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }


  Widget _buildAttendanceHeatmap(BuildContext context, AttendanceHeatmap heatmap, bool isDark) {
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
              const Text('Active Participation', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Last 12 Months', style: TextStyle(fontSize: 10, color: Colors.grey.withOpacity(0.5))),
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

  Widget _buildStudentHeatmapCol(BuildContext context, StudentHeatmapData student, bool isDark) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(radius: 18, child: Text(student.fullName[0], style: const TextStyle(fontSize: 12))),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
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
                  color: active ? theme.colorScheme.primary.withOpacity(0.8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReportTrackingCard(BuildContext context, SupervisorAttendanceReport r, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.description_rounded, color: Colors.blue, size: 16)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.bold)), Text('Week ${r.weekNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _getReportColor(r.attendanceStatus).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(r.attendanceStatus, style: TextStyle(color: _getReportColor(r.attendanceStatus), fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          if (r.executionStatus != null) ...[
            const SizedBox(height: 16),
            const Text('EXECUTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
            Text(r.executionStatus!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Color _getReportColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT': return Colors.green;
      case 'ABSENT': return Colors.red;
      case 'LATE': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _SupervisorTeamsTab extends ConsumerWidget {
  const _SupervisorTeamsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
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
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
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
                  colors: [const Color(0xFF8A2387).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFFE94057).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          meAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (me) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ModernSliverAppBar(
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
                    _buildModernSettingItem(
                      context, 
                      Icons.person_outline_rounded, 
                      'Profile', 
                      'Edit your details',
                      onTap: () => context.push('${AppRoutes.accountSettings}?section=profile'),
                    ),
                    const SizedBox(height: 16),
                    _buildModernSettingItem(
                      context, 
                      Icons.security_rounded, 
                      'Security', 
                      'Password & auth',
                      onTap: () => context.push('${AppRoutes.accountSettings}?section=security'),
                    ),
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
        ],
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
        _DashboardTab(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, view: _SupervisorOverviewTab()),
        _DashboardTab(label: 'Interns', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, view: _SupervisorStudentsTab()),
        _DashboardTab(label: 'Management', icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, view: _SupervisorManagementTab()),
        _DashboardTab(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, view: _SupervisorSettingsTab()),
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
        _DashboardTab(label: 'Overview', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, view: _CoordinatorHomeTab()),
        _DashboardTab(label: 'HODs', icon: Icons.school_outlined, activeIcon: Icons.school_rounded, view: _CoordinatorHodsTab()),
        _DashboardTab(label: 'Students', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, view: _CoordinatorStudentsTab()),
        _DashboardTab(label: 'Placements', icon: Icons.business_center_outlined, activeIcon: Icons.business_center_rounded, view: _CoordinatorPlacementsTab()),
        _DashboardTab(label: 'Companies', icon: Icons.business_outlined, activeIcon: Icons.business_rounded, view: _CoordinatorCompaniesTab()),
        _DashboardTab(label: 'Tools', icon: Icons.apps_rounded, activeIcon: Icons.apps_rounded, view: _CoordinatorToolsTab()),
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
                  colors: [const Color(0xFF1CB5E0).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFF000046).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ModernSliverAppBar(
              title: 'Coordinator',
              subtitle: 'University Overview',
              profileName: 'Coordinator',
              gradient: [const Color(0xFF1CB5E0), const Color(0xFF000046)],
              backgroundIcon: Icons.assessment_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Quick Stats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(context, '1,240', 'Students', Icons.people_rounded, Colors.blue),
                      const SizedBox(width: 16),
                      _buildStatCard(context, '856', 'Placed', Icons.check_circle_rounded, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(context, '12', 'Depts/HODs', Icons.domain_rounded, Colors.purple),
                      const SizedBox(width: 16),
                      _buildStatCard(context, '45', 'Proposals', Icons.description_rounded, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('University Analytics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPlatformAnalytics(context, isDark,
                    growthTitle: 'Enrollment', growthTrend: '+8% Annual',
                    placementTitle: 'Industry Partners', placementSub: '45 Active',
                    successTitle: 'Placement Rate', successRate: 0.68,
                    submissionTitle: 'System Activity', submissionSub: 'High Load'
                  ),
                  const SizedBox(height: 32),
                  Text('Recent Activity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildActivityItem(context, 'Weekly Report', 'CS Dept: 15 reports submitted', '10m ago', Colors.blue),
                  _buildActivityItem(context, 'Placement', 'Mechanical Dept: 5 students placed', '2h ago', Colors.green),
                  _buildActivityItem(context, 'New Proposal', 'Civil Dept: New request to Google', '5h ago', Colors.orange),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String subtitle, String time, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(time, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _CoordinatorHodsTab extends ConsumerWidget {
  const _CoordinatorHodsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
                  colors: [const Color(0xFF00F260).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFF0575E6).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
            ModernSliverAppBar(
              title: 'Department Heads',
              subtitle: 'HOD Management',
              profileName: 'Coordinator',
              gradient: [const Color(0xFF00F260), const Color(0xFF0575E6)],
              backgroundIcon: Icons.school_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _sectionHeader('Pending Verification'),
                  _buildHodRequestCard(context, 'Dr. Samuel Kebede', 'Computer Science', isDark),
                  const SizedBox(height: 32),
                  _sectionHeader('Verified HODs'),
                  _buildHodItem(context, 'Dr. Abebech Tadesse', 'Mechanical Engineering', true, isDark),
                  _buildHodItem(context, 'Dr. Solomon Haile', 'Civil Engineering', true, isDark),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));

  Widget _buildHodRequestCard(BuildContext context, String name, String dept, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(dept, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Reject'))),
              const SizedBox(width: 16),
              Expanded(child: FilledButton(onPressed: () {}, child: const Text('Approve'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHodItem(BuildContext context, String name, String dept, bool isVerified, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00F260), Color(0xFF0575E6)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFF0575E6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(dept, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
          if (isVerified) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_rounded, color: Colors.blue, size: 14), SizedBox(width: 4), Text('Verified', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w900))])),
        ],
      ),
    );
  }
}

class _CoordinatorStudentsTab extends ConsumerWidget {
  const _CoordinatorStudentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
                  colors: [const Color(0xFFF2994A).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFFF2C94C).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
            ModernSliverAppBar(
              title: 'Students',
              subtitle: 'University Enrollment',
              profileName: 'Coordinator',
              gradient: [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
              backgroundIcon: Icons.group_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStudentSummaryItem(context, 'Total Enrolled', '1,240', Colors.blue, isDark),
                  _buildStudentSummaryItem(context, 'Actively Placed', '856', Colors.green, isDark),
                  _buildStudentSummaryItem(context, 'Pending Placement', '384', Colors.orange, isDark),
                  const SizedBox(height: 32),
                  Text('Department Breakdown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDeptItem('Computer Science', '450 Students', '80% Placed', Colors.blue, isDark),
                  _buildDeptItem('Mechanical Engineering', '320 Students', '65% Placed', Colors.green, isDark),
                  _buildDeptItem('Electrical Engineering', '280 Students', '72% Placed', Colors.purple, isDark),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildStudentSummaryItem(BuildContext context, String label, String value, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
        ],
      ),
    );
  }

  Widget _buildDeptItem(String name, String count, String placementRate, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.domain_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(count, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(placementRate, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _CoordinatorCompaniesTab extends ConsumerWidget {
  const _CoordinatorCompaniesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
                  colors: [const Color(0xFFDA22FF).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFF9733EE).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
          slivers: [
            ModernSliverAppBar(
              title: 'Companies',
              subtitle: 'Industry Partners',
              profileName: 'Coordinator',
              gradient: [const Color(0xFFDA22FF), const Color(0xFF9733EE)],
              backgroundIcon: Icons.business_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPartnerCard('Ethio Telecom', 'Public Sector', '150 Placements', isDark),
                  _buildPartnerCard('Commercial Bank', 'Finance', '120 Placements', isDark),
                  _buildPartnerCard('Safaricom Ethiopia', 'Telecom', '85 Placements', isDark),
                  _buildPartnerCard('Orbit Health', 'Healthcare IT', '45 Placements', isDark),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(String name, String sector, String stats, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFDA22FF), Color(0xFF9733EE)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFF9733EE).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(sector, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(stats, style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _CoordinatorPlacementsTab extends ConsumerWidget {
  const _CoordinatorPlacementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
                  colors: [const Color(0xFFFC466B).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFF3F5EFB).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              ModernSliverAppBar(
                title: 'Placements',
                subtitle: 'Assigned Students',
                profileName: 'Coordinator',
                gradient: const [Color(0xFFFC466B), Color(0xFF3F5EFB)],
                backgroundIcon: Icons.business_center_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text('Recent Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    _buildPlacementItem(context, 'Abebe Kebede', 'Ethio Telecom', 'Computer Science', Colors.blue, isDark),
                    _buildPlacementItem(context, 'Tadesse Haile', 'Safaricom', 'Electrical Engineering', Colors.green, isDark),
                    _buildPlacementItem(context, 'Selamawit Yilma', 'Commercial Bank', 'Software Engineering', Colors.purple, isDark),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementItem(BuildContext context, String student, String company, String dept, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.work_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(student, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('$company • $dept', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('Assigned', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _CoordinatorToolsTab extends ConsumerStatefulWidget {
  const _CoordinatorToolsTab();

  @override
  ConsumerState<_CoordinatorToolsTab> createState() => _CoordinatorToolsTabState();
}

class _CoordinatorToolsTabState extends ConsumerState<_CoordinatorToolsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    return Material(
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
                  colors: [const Color(0xFF11998e).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFF38ef7d).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              ModernSliverAppBar(
                title: 'Tools & Insights',
                subtitle: 'Reports, AI & Messages',
                profileName: 'Coordinator',
                gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                backgroundIcon: Icons.apps_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: isDark ? Colors.white : Colors.black87,
                    unselectedLabelColor: Colors.grey,
                    indicator: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Reports'))),
                      Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Messages'))),
                      Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('AI Assistant'))),
                    ],
                  ),
                  isDark,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsView(isDark),
                _buildMessagesView(isDark),
                _buildAiAssistantView(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('University Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        _buildReportCard('University Placement Overview', 'Generated today', Icons.pie_chart_rounded, Colors.teal, isDark),
        _buildReportCard('Department Performance (Semester 2)', 'Generated last week', Icons.assessment_rounded, Colors.green, isDark),
        _buildReportCard('Industry Partner Analytics', 'Generated 1 month ago', Icons.business_rounded, Colors.blue, isDark),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
          IconButton(onPressed: () {}, icon: Icon(Icons.download_rounded, color: color)),
        ],
      ),
    );
  }

  Widget _buildMessagesView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('University Broadcasts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        _buildMessageCard('Important Update: Placement Deadline', 'All departments must finalize placements...', 'System', Colors.red, isDark),
        _buildMessageCard('New Corporate Partner Added', 'Ethio Telecom has updated their capacity...', 'Admin', Colors.blue, isDark),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.campaign_rounded), label: const Text('New Broadcast'))),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildMessageCard(String title, String preview, String sender, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(sender, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))),
              const Spacer(),
              Text('2h ago', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(preview, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAiAssistantView(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF38ef7d).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          const Text('Coordinator Smart Assistant', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          const Text('Generate university-wide placement analytics, summarize HOD performance, and draft announcements.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_rounded), label: const Text('Start New Chat'))),
        ],
      ),
    );
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
        _DashboardTab(label: 'Overview', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, view: _HodOverviewTab()),
        _DashboardTab(label: 'Students', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, view: _HodStudentsTab()),
        _DashboardTab(label: 'Placement', icon: Icons.business_center_outlined, activeIcon: Icons.business_center_rounded, view: _HodPlacementTab()),
        _DashboardTab(label: 'Directory', icon: Icons.corporate_fare_rounded, activeIcon: Icons.corporate_fare_rounded, view: _HodDirectoryTab()),
        _DashboardTab(label: 'Tools', icon: Icons.apps_rounded, activeIcon: Icons.apps_rounded, view: _HodToolsTab()),
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

    return Material(
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
                  colors: [const Color(0xFF8E2DE2).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFF4A00E0).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ModernSliverAppBar(
              title: 'Dashboard',
              subtitle: 'Department Level Insights',
              profileName: 'HOD',
              gradient: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              backgroundIcon: Icons.analytics_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatGrid(context, isDark),
                  const SizedBox(height: 32),
                  Text('Department Analytics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPlatformAnalytics(context, isDark,
                    growthTitle: 'Dept. Growth', growthTrend: '+10% Students',
                    placementTitle: 'Local Partners', placementSub: '12 Active',
                    successTitle: 'Submission Rate', successRate: 0.85,
                    submissionTitle: 'Avg. Attendance', submissionSub: '90%'
                  ),
                  const SizedBox(height: 32),
                  Text('Recent Reports', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  _buildReportItem(context, 'Desta Kasaye', 'Week 4 Report', 'Pending', Colors.orange),
                  _buildReportItem(context, 'Sara Girma', 'Final Evaluation', 'Submitted', Colors.green),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _statCard('Total Students', '124', Icons.groups_rounded, Colors.blue, isDark),
        _statCard('Pending Appr.', '12', Icons.pending_actions_rounded, Colors.orange, isDark),
        _statCard('Placed', '86', Icons.check_circle_rounded, Colors.green, isDark),
        _statCard('Reports', '45', Icons.description_rounded, Colors.purple, isDark),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, String student, String title, String status, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Text(student[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(student, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _HodStudentsTab extends ConsumerWidget {
  const _HodStudentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
                  colors: [const Color(0xFF00b09b).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFF96c93d).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
          const ModernSliverAppBar(
            title: 'Students',
            subtitle: 'Department Enrollment',
            profileName: 'HOD',
            gradient: [Color(0xFF00b09b), Color(0xFF96c93d)],
            backgroundIcon: Icons.person_search_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip('All', true, isDark),
                    _filterChip('Pending', false, isDark),
                    _filterChip('Placed', false, isDark),
                    _filterChip('Unplaced', false, isDark),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStudentItem(context, 'Abebe Bikila', 'PLACED', 'Global Tech Inc.', isDark),
                _buildStudentItem(context, 'Sara Girma', 'PENDING', 'None', isDark),
                _buildStudentItem(context, 'Desta Kasaye', 'UNPLACED', 'None', isDark),
                const SizedBox(height: 120),
              ]),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.green : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStudentItem(BuildContext context, String name, String status, String company, bool isDark) {
    Color statusColor = status == 'PLACED' ? Colors.green : (status == 'PENDING' ? Colors.orange : Colors.red);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [statusColor.withOpacity(0.8), statusColor]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(company, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (status == 'PENDING') ...[
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Reject'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: () {}, child: const Text('Approve'))),
              ] else if (status == 'UNPLACED') ...[
                Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send_rounded, size: 16), label: const Text('Send Proposal'))),
              ] else ...[
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('View Profile'))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HodPlacementTab extends ConsumerWidget {
  const _HodPlacementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
                  colors: [const Color(0xFFf857a6).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFFff5858).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
          ModernSliverAppBar(
            title: 'Placements',
            subtitle: 'Proposals & Open Letters',
            profileName: 'HOD',
            gradient: const [Color(0xFFf857a6), Color(0xFFff5858)],
            backgroundIcon: Icons.business_center_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionTitle('Active Proposals'),
                _buildProposalCard('Software Intern', 'Google Ethiopia', 'Reviewing', Colors.blue, isDark),
                const SizedBox(height: 24),
                _sectionTitle('Open Letter Requests'),
                _buildOpenLetterCard('Abebe Bikila', 'Requesting placement at Ethio Telecom', isDark),
                const SizedBox(height: 120),
              ]),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));

  Widget _buildProposalCard(String title, String company, String status, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.work_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(company, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  Widget _buildOpenLetterCard(String student, String reason, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text(student[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(student, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('Open Letter Request', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
            ],
          ),
          const SizedBox(height: 16),
          Text(reason, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Reject'))),
              const SizedBox(width: 16),
              Expanded(child: FilledButton(onPressed: () {}, child: const Text('Approve'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _HodDirectoryTab extends ConsumerWidget {
  const _HodDirectoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
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
                  colors: [const Color(0xFF1fa2ff).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFF12d8fa).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
          ModernSliverAppBar(
            title: 'Directory',
            subtitle: 'Company Partners',
            profileName: 'HOD',
            gradient: const [Color(0xFF1fa2ff), Color(0xFF12d8fa)],
            backgroundIcon: Icons.corporate_fare_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCompanyCard('Ethio Telecom', 'Telecommunications', '5 Active Interns', isDark),
                _buildCompanyCard('Commercial Bank of Ethiopia', 'Finance', '12 Active Interns', isDark),
                _buildCompanyCard('SafaryCom', 'Telecom', '8 Active Interns', isDark),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded), label: const Text('Invite New Company'))),
                const SizedBox(height: 120),
              ]),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(String name, String sector, String interns, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1fa2ff), Color(0xFF12d8fa)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(sector, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(interns, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }
}

class _HodToolsTab extends ConsumerStatefulWidget {
  const _HodToolsTab();

  @override
  ConsumerState<_HodToolsTab> createState() => _HodToolsTabState();
}

class _HodToolsTabState extends ConsumerState<_HodToolsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    return Material(
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
                  colors: [const Color(0xFFa18cd1).withOpacity(0.15), Colors.transparent],
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
                  colors: [const Color(0xFFfbc2eb).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              ModernSliverAppBar(
                title: 'Tools & Insights',
                subtitle: 'Reports, AI & Messages',
                profileName: 'HOD',
                gradient: const [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
                backgroundIcon: Icons.apps_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: isDark ? Colors.white : Colors.black87,
                    unselectedLabelColor: Colors.grey,
                    indicator: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Reports'))),
                      Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Messages'))),
                      Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('AI Assistant'))),
                    ],
                  ),
                  isDark,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsView(isDark),
                _buildMessagesView(isDark),
                _buildAiAssistantView(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Department Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        _buildReportCard('Weekly Placement Report', 'Generated 2 days ago', Icons.pie_chart_rounded, Colors.purple, isDark),
        _buildReportCard('Final Evaluations (Semester 2)', 'Generated last week', Icons.assessment_rounded, Colors.green, isDark),
        _buildReportCard('Company Feedback Summary', 'Generated 1 month ago', Icons.feedback_rounded, Colors.orange, isDark),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500))])),
          IconButton(onPressed: () {}, icon: Icon(Icons.download_rounded, color: color)),
        ],
      ),
    );
  }

  Widget _buildMessagesView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Recent Broadcasts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        _buildMessageCard('Important Update: Final Reports Due', 'Please remind all students to submit...', 'Coordinator', Colors.red, isDark),
        _buildMessageCard('New Company Added to Directory', 'SafaryCom has officially joined...', 'Admin', Colors.blue, isDark),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.campaign_rounded), label: const Text('New Broadcast'))),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildMessageCard(String title, String preview, String sender, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(sender, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))),
              const Spacer(),
              Text('2h ago', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(preview, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAiAssistantView(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFfbc2eb).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 32),
          const Text('HOD Smart Assistant', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          const Text('Generate placement reports, draft emails to companies, and analyze student performance instantly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 56, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_rounded), label: const Text('Start New Chat'))),
        ],
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
        _DashboardTab(label: 'Orgs', icon: Icons.business_rounded, activeIcon: Icons.business_center_rounded, view: _AdminOrganizationsTab()),
        _DashboardTab(label: 'Users', icon: Icons.group_outlined, activeIcon: Icons.group_rounded, view: _AdminUsersTab()),
        _DashboardTab(label: 'Logs', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, view: _AdminLogsTab()),
        _DashboardTab(label: 'Config', icon: Icons.settings_suggest_outlined, activeIcon: Icons.settings_suggest_rounded, view: _AdminSettingsTab()),
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
              ModernSliverAppBar(
                title: 'Admin Dashboard',
                subtitle: 'Platform Management',
                profileName: 'Main Admin',
                gradient: const [Color(0xFF0F2027), Color(0xFF2C5364)],
                backgroundIcon: Icons.shield_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader(theme, 'Platform Overview'),
                    const SizedBox(height: 16),
                    _buildOverviewGrid(context, stats, isDark),

                    const SizedBox(height: 32),
                    _buildSectionHeader(theme, 'Platform Analytics'),
                    const SizedBox(height: 16),
                    _buildPlatformAnalytics(context, isDark,
                      growthTitle: 'Users', growthTrend: '+12% Total',
                      placementTitle: 'Institutions', placementSub: '88 Active',
                      successTitle: 'Placement Rate', successRate: 0.72,
                      submissionTitle: 'System Status', submissionSub: 'Healthy'
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader(theme, 'Pending Approvals'),
                    const SizedBox(height: 16),
                    _buildPendingApprovalsPreview(context, ref, isDark),

                    const SizedBox(height: 32),
                    _buildSectionHeader(theme, 'Recent Audit Logs'),
                    const SizedBox(height: 16),
                    _buildRecentActivitiesPreview(context, ref, isDark),

                    const SizedBox(height: 32),
                    _buildSectionHeader(theme, 'Broadcast Announcement'),
                    const SizedBox(height: 16),
                    _buildQuickBroadcastBox(context, theme, isDark),

                    const SizedBox(height: 32),
                    _buildSectionHeader(theme, 'System Health'),
                    const SizedBox(height: 16),
                    _buildSystemHealthWidget(context, isDark),

                    const SizedBox(height: 32),
                    _buildSectionHeader(theme, 'Quick Navigation'),
                    const SizedBox(height: 16),
                    _buildQuickNavigation(context, isDark),

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

  Widget _buildOverviewGrid(BuildContext context, dynamic stats, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _buildStatCard(context, 'Total Users', stats.totalUsers.toString(), Icons.people_rounded, Colors.blue, isDark),
        _buildStatCard(context, 'Institutions', (stats.totalUniversities + stats.totalCompanies).toString(), Icons.account_balance_rounded, Colors.orange, isDark),
        _buildStatCard(context, 'Active Internships', '452', Icons.work_rounded, Colors.green, isDark),
        _buildStatCard(context, 'Pending Review', stats.pendingApprovals.toString(), Icons.pending_actions_rounded, Colors.red, isDark),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalsPreview(BuildContext context, WidgetRef ref, bool isDark) {
    final unis = ref.watch(pendingUniversitiesProvider).asData?.value ?? [];
    final comps = ref.watch(pendingCompaniesProvider).asData?.value ?? [];
    final coords = ref.watch(pendingCoordinatorsProvider).asData?.value ?? [];
    
    final allPending = [
      ...unis.map((u) => {'id': u['id'], 'title': u['name'], 'subtitle': 'University Reg.', 'type': 'UNI'}),
      ...comps.map((c) => {'id': c['id'], 'title': c['name'], 'subtitle': 'Company Reg.', 'type': 'COMP'}),
      ...coords.map((co) => {'id': co['userId'], 'title': co['user']['full_name'], 'subtitle': 'Coordinator Acc.', 'type': 'COORD'}),
    ].take(3).toList();

    if (allPending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: const Center(child: Text('All caught up! No pending approvals.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: [
        ...allPending.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                decoration: BoxDecoration(
                  color: (item['type'] == 'UNI' || item['type'] == 'COMP' ? Colors.blue : Colors.purple).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['type'] == 'UNI' ? Icons.school_rounded : (item['type'] == 'COMP' ? Icons.business_rounded : Icons.person_rounded), 
                  color: item['type'] == 'UNI' || item['type'] == 'COMP' ? Colors.blue : Colors.purple, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']! as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(item['subtitle']! as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      try {
                        final adminRepo = ref.read(adminRepositoryProvider);
                        final id = item['id'] as int;
                        final type = item['type'] as String;
                        if (type == 'UNI') await adminRepo.updateUniversityStatus(id, 'REJECTED');
                        else if (type == 'COMP') await adminRepo.updateCompanyStatus(id, 'REJECTED');
                        else if (type == 'COORD') await adminRepo.rejectCoordinator(id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected')));
                        ref.invalidate(adminStatsProvider);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                    style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      try {
                        final adminRepo = ref.read(adminRepositoryProvider);
                        final id = item['id'] as int;
                        final type = item['type'] as String;
                        if (type == 'UNI') await adminRepo.updateUniversityStatus(id, 'APPROVED');
                        else if (type == 'COMP') await adminRepo.updateCompanyStatus(id, 'APPROVED');
                        else if (type == 'COORD') await adminRepo.approveCoordinator(id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved!')));
                        ref.invalidate(adminStatsProvider);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    icon: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
                    style: IconButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.1)),
                  ),
                ],
              ),
            ],
          ),
        )),
        TextButton(
          onPressed: () {}, // Tab switching handled by user manually or through complex logic
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('View All Approvals'),
              Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesPreview(BuildContext context, WidgetRef ref, bool isDark) {
    final logs = ref.watch(auditLogsProvider).asData?.value ?? [];
    final recent = logs.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ...recent.map((log) => ListTile(
            dense: true,
            leading: const CircleAvatar(radius: 14, child: Icon(Icons.history_rounded, size: 14)),
            title: Text(log['action'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(log['timestamp'], style: const TextStyle(fontSize: 10)),
          )),
          if (recent.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No recent logs', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildQuickBroadcastBox(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Broadcast Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type message to all users...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Send to Everyone'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthWidget(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
        Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickNavigation(BuildContext context, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildNavChip(context, 'Users', Icons.group_rounded, isDark),
        _buildNavChip(context, 'Companies', Icons.business_rounded, isDark),
        _buildNavChip(context, 'Audit Logs', Icons.receipt_long_rounded, isDark),
        _buildNavChip(context, 'Settings', Icons.settings_rounded, isDark),
      ],
    );
  }

  Widget _buildNavChip(BuildContext context, String label, IconData icon, bool isDark) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AdminOrganizationsTab extends ConsumerStatefulWidget {
  const _AdminOrganizationsTab();

  @override
  ConsumerState<_AdminOrganizationsTab> createState() => _AdminOrganizationsTabState();
}

class _AdminOrganizationsTabState extends ConsumerState<_AdminOrganizationsTab> {
  String _searchQuery = '';
  String _orgTypeFilter = 'All'; // 'All', 'University', 'Company'
  String _orgStatusFilter = 'PENDING'; // 'PENDING', 'APPROVED', 'SUSPENDED'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final statsAsync = ref.watch(adminStatsProvider);
    final unisAsync = ref.watch(allUniversitiesProvider);
    final compsAsync = ref.watch(allCompaniesProvider);

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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ModernSliverAppBar(
              title: 'Organizations',
              subtitle: 'Manage Universities & Companies',
              profileName: 'Admin',
              gradient: [const Color(0xFF373B44), const Color(0xFF4286F4)],
              backgroundIcon: Icons.business_rounded,
              actions: [
                IconButton(
                  onPressed: () => _showInviteDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                  tooltip: 'Invite Organization',
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildOrgStatsRow(statsAsync, isDark),
                  const SizedBox(height: 32),
                  _buildFilterRow(isDark),
                  const SizedBox(height: 24),
                  Text('Results', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            _buildOrgList(ref, unisAsync, compsAsync, isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgStatsRow(AsyncValue<AdminStats> statsAsync, bool isDark) {
    return statsAsync.when(
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMiniStat('Pending Unis', stats.pendingApprovals.toString(), Icons.school_rounded, Colors.orange, isDark),
            const SizedBox(width: 12),
            _buildMiniStat('Verified', (stats.totalUniversities + stats.totalCompanies).toString(), Icons.verified_rounded, Colors.green, isDark),
            const SizedBox(width: 12),
            _buildMiniStat('Suspended', '3', Icons.block_rounded, Colors.red, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownFilter('Type: $_orgTypeFilter', ['All', 'University', 'Company'], (v) => setState(() => _orgTypeFilter = v!)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdownFilter('Status: $_orgStatusFilter', ['PENDING', 'APPROVED', 'SUSPENDED', 'REJECTED'], (v) => setState(() => _orgStatusFilter = v!)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(String label, List<String> options, ValueChanged<String?> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: label.split(': ').last,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOrgList(WidgetRef ref, AsyncValue<List<dynamic>> unisAsync, AsyncValue<List<dynamic>> compsAsync, bool isDark) {
    return unisAsync.when(
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
      data: (unis) => compsAsync.when(
        loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
        data: (comps) {
          final all = [
            ...unis.map((u) => {...Map<String, dynamic>.from(u), 'type': 'University'}),
            ...comps.map((c) => {...Map<String, dynamic>.from(c), 'type': 'Company'}),
          ].where((o) {
            final matchesSearch = o['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesType = _orgTypeFilter == 'All' || o['type'] == _orgTypeFilter;
            final matchesStatus = o['approval_status'] == _orgStatusFilter;
            return matchesSearch && matchesType && matchesStatus;
          }).toList();

          if (all.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No organizations found'))));

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildOrgCard(context, ref, all[index], isDark),
                childCount: all.length,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrgCard(BuildContext context, WidgetRef ref, Map<String, dynamic> org, bool isDark) {
    final theme = Theme.of(context);
    final status = org['approval_status'] as String;
    final isPending = status == 'PENDING';
    
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
                child: Icon(org['type'] == 'University' ? Icons.account_balance_rounded : Icons.business_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(org['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(
                      '${org['type']} • ${org['official_email'] ?? 'No email'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (org['created_at'] != null)
                      Text(
                        'Submitted: ${org['created_at'].toString().split('T')[0]}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (isPending) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(ref, org, 'REJECTED'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _updateStatus(ref, org, 'APPROVED'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ),
              ] else ...[
                 Expanded(
                   child: OutlinedButton(
                     onPressed: () {},
                     child: const Text('View Details'),
                   ),
                 ),
                 const SizedBox(width: 12),
                 if (status == 'APPROVED')
                   Expanded(
                     child: FilledButton(
                       onPressed: () => _updateStatus(ref, org, 'SUSPENDED'),
                       style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                       child: const Text('Suspend'),
                     ),
                   )
                 else if (status == 'SUSPENDED')
                   Expanded(
                     child: FilledButton(
                       onPressed: () => _updateStatus(ref, org, 'APPROVED'),
                       style: FilledButton.styleFrom(backgroundColor: Colors.green),
                       child: const Text('Activate'),
                     ),
                   ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, Map<String, dynamic> org, String status) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (org['type'] == 'University') {
        await repo.updateUniversityStatus(org['id'], status);
      } else {
        await repo.updateCompanyStatus(org['id'], status);
      }
      ref.invalidate(allUniversitiesProvider);
      ref.invalidate(allCompaniesProvider);
      ref.invalidate(adminStatsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Organization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Official Email')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: 'University',
              items: ['University', 'Company'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) {},
              decoration: const InputDecoration(labelText: 'Type'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Send Invitation')),
        ],
      ),
    );
  }
}

class _AdminUsersTab extends ConsumerStatefulWidget {
  const _AdminUsersTab();

  @override
  ConsumerState<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab> {
  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
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
            colors: [
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (users) {
            final filteredUsers = users.where((u) {
              final matchesSearch = (u['full_name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (u['email'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesRole = _selectedRole == 'All' || u['role'] == _selectedRole;
              final matchesStatus = _selectedStatus == 'All' || 
                  (_selectedStatus == 'Active' && u['isApproved'] == true) ||
                  (_selectedStatus == 'Suspended' && u['isApproved'] == false);
              return matchesSearch && matchesRole && matchesStatus;
            }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                ModernSliverAppBar(
                  title: 'User Management',
                  subtitle: 'Control platform access',
                  profileName: 'Admin',
                  gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                  backgroundIcon: Icons.people_rounded,
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download_rounded, color: Colors.white),
                      tooltip: 'Export CSV',
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildOverviewRow(users, isDark),
                      const SizedBox(height: 32),
                      _buildSearchAndFilters(theme, isDark),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Directory (${filteredUsers.length})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.bolt_rounded, size: 16),
                            label: const Text('Bulk Actions'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildUserCard(context, filteredUsers[index], isDark),
                      childCount: filteredUsers.length,
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

  Widget _buildOverviewRow(List<dynamic> users, bool isDark) {
    final total = users.length;
    final active = users.where((u) => u['isApproved'] == true).length;
    final suspended = users.where((u) => u['isApproved'] == false).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMiniStat('Total', total.toString(), Icons.group_rounded, Colors.blue, isDark),
          const SizedBox(width: 12),
          _buildMiniStat('Active', active.toString(), Icons.check_circle_rounded, Colors.green, isDark),
          const SizedBox(width: 12),
          _buildMiniStat('Suspended', suspended.toString(), Icons.block_rounded, Colors.red, isDark),
          const SizedBox(width: 12),
          _buildMiniStat('New Today', '12', Icons.fiber_new_rounded, Colors.orange, isDark),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme, bool isDark) {
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Role: $_selectedRole', Icons.badge_rounded, () => _showFilterDialog('Role')),
              const SizedBox(width: 8),
              _buildFilterChip('Status: $_selectedStatus', Icons.verified_user_rounded, () => _showFilterDialog('Status')),
              const SizedBox(width: 8),
              _buildFilterChip('Joined: All Time', Icons.calendar_today_rounded, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, dynamic user, bool isDark) {
    final theme = Theme.of(context);
    final statusColor = user['isApproved'] == true ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(user['full_name']?[0].toUpperCase() ?? '?', 
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user['full_name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(user['isApproved'] == true ? 'ACTIVE' : 'SUSPENDED', 
                        style: TextStyle(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user['role']} • ${user['email']}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_rounded, size: 18), SizedBox(width: 12), Text('View Details')])),
              PopupMenuItem(
                value: user['isApproved'] == true ? 'suspend' : 'activate', 
                child: Row(children: [
                  Icon(user['isApproved'] == true ? Icons.block_rounded : Icons.check_circle_rounded, size: 18), 
                  const SizedBox(width: 12), 
                  Text(user['isApproved'] == true ? 'Suspend' : 'Activate')
                ])
              ),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever_rounded, size: 18, color: Colors.redAccent), SizedBox(width: 12), Text('Delete User', style: TextStyle(color: Colors.redAccent))])),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(String type) {
    final options = type == 'Role' 
      ? ['All', 'STUDENT', 'SUPERVISOR', 'COORDINATOR', 'ADMIN', 'HOD']
      : ['All', 'Active', 'Suspended'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select $type', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((opt) {
                final isSelected = type == 'Role' ? _selectedRole == opt : _selectedStatus == opt;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (s) {
                    setState(() {
                      if (type == 'Role') _selectedRole = opt;
                      else _selectedStatus = opt;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AdminLogsTab extends ConsumerStatefulWidget {
  const _AdminLogsTab();

  @override
  ConsumerState<_AdminLogsTab> createState() => _AdminLogsTabState();
}

class _AdminLogsTabState extends ConsumerState<_AdminLogsTab> {
  String _searchQuery = '';
  String _typeFilter = 'All';
  String _roleFilter = 'All';

  @override
  Widget build(BuildContext context) {
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
            final filteredLogs = logs.where((l) {
              final action = l['action'].toString().toLowerCase();
              final matchesSearch = action.contains(_searchQuery.toLowerCase()) || 
                  l['details'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesType = _typeFilter == 'All' || l['action'].toString().contains(_typeFilter.toUpperCase());
              return matchesSearch && matchesType;
            }).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                ModernSliverAppBar(
                  title: 'Audit Logs',
                  subtitle: 'System-wide activity trace',
                  profileName: 'Admin',
                  gradient: [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                  backgroundIcon: Icons.receipt_long_rounded,
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                      tooltip: 'Export PDF',
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          final csv = await ref.read(adminRepositoryProvider).exportAuditLogsCsv();
                          // In a real mobile app, we'd use path_provider and open_file or share_plus
                          // For now, we'll show success.
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Audit Log CSV generated successfully (5000 records)'),
                              backgroundColor: Colors.green,
                            ));
                          }
                          print('CSV Data: ${csv.substring(0, 100)}...');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                          }
                        }
                      },
                      icon: const Icon(Icons.file_download_rounded, color: Colors.white),
                      tooltip: 'Export CSV',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilters(theme, isDark),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Icon(Icons.timeline_rounded, size: 20, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text('Activity Timeline (${filteredLogs.length})', 
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTimelineItem(context, filteredLogs[index], isDark, 
                        isFirst: index == 0, isLast: index == filteredLogs.length - 1),
                      childCount: filteredLogs.length,
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

  Widget _buildFilters(ThemeData theme, bool isDark) {
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search by action or detail...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Action: $_typeFilter', Icons.bolt_rounded, () => _showFilterDialog('Action')),
              const SizedBox(width: 8),
              _buildFilterChip('Role: $_roleFilter', Icons.badge_rounded, () => _showFilterDialog('Role')),
              const SizedBox(width: 8),
              _buildFilterChip('Date: Today', Icons.calendar_today_rounded, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, dynamic log, bool isDark, {bool isFirst = false, bool isLast = false}) {
    final actionColor = _getActionColor(log['action'].toString());
    
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 20,
                color: isFirst ? Colors.transparent : Colors.grey.withOpacity(0.2),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: actionColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: actionColor.withOpacity(0.2), width: 4, strokeAlign: BorderSide.strokeAlignOutside),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey.withOpacity(0.2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(log['action'], style: TextStyle(fontWeight: FontWeight.w900, color: actionColor, fontSize: 13)),
                      Text(_formatTime(log['timestamp']), style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(log['details'] ?? 'No details available', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(radius: 8, child: Text(log['admin']?['full_name']?[0] ?? '?', style: const TextStyle(fontSize: 8))),
                      const SizedBox(width: 8),
                      Text(log['admin']?['full_name'] ?? 'System', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const Spacer(),
                      const Icon(Icons.devices_rounded, size: 10, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Web/192.168.1.1', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
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

  Color _getActionColor(String action) {
    if (action.contains('APPROVE')) return Colors.green;
    if (action.contains('REJECT')) return Colors.red;
    if (action.contains('SUSPEND')) return Colors.orange;
    if (action.contains('CREATE')) return Colors.blue;
    if (action.contains('DELETE')) return Colors.redAccent;
    return Colors.purple;
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '--:--';
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}';
    } catch (_) {
      return timestamp;
    }
  }

  void _showFilterDialog(String type) {
    final options = type == 'Role' 
      ? ['All', 'ADMIN', 'COORDINATOR', 'SUPERVISOR', 'SYSTEM']
      : ['All', 'APPROVE', 'REJECT', 'SUSPEND', 'CREATE', 'UPDATE'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select $type', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((opt) {
                final isSelected = type == 'Role' ? _roleFilter == opt : _typeFilter == opt;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (s) {
                    setState(() {
                      if (type == 'Role') _roleFilter = opt;
                      else _typeFilter = opt;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSettingsTab extends ConsumerStatefulWidget {
  const _AdminSettingsTab();

  @override
  ConsumerState<_AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends ConsumerState<_AdminSettingsTab> {
  bool _regStudent = true;
  bool _regCoordinator = true;
  bool _regHod = true;
  bool _regSupervisor = true;
  bool _regUni = true;
  bool _regComp = true;
  bool _maintenance = false;
  String _maintenanceMessage = '';
  
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastContentCtrl = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _broadcastTitleCtrl.dispose();
    _broadcastContentCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateConfig(String key, String value) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(adminRepositoryProvider).updateConfig({key: value});
      ref.invalidate(systemConfigProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update $key: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _syncStateFromConfig(Map<String, String> config) {
    _regStudent = config['registration_student_open'] == 'true';
    _regCoordinator = config['registration_coordinator_open'] == 'true';
    _regHod = config['registration_hod_open'] == 'true';
    _regSupervisor = config['registration_supervisor_open'] == 'true';
    _regUni = config['registration_university_open'] == 'true';
    _regComp = config['registration_company_open'] == 'true';
    _maintenance = config['maintenance_mode'] == 'true';
    _maintenanceMessage = config['maintenance_message'] ?? '';
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
        _syncStateFromConfig(config);
        
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
                      profileName: 'Admin',
                      gradient: const [Color(0xFF2C3E50), Color(0xFF000000)],
                      backgroundIcon: Icons.settings_suggest_rounded,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSection(context, 'System Configuration', [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Manage platform-wide settings, registration controls, and operational parameters.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            _buildSectionHeaderSmall('Registration Controls'),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                'Enable or disable new registrations per role. Existing accounts are not affected.',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                            _buildSwitchTile('Student registration open', _regStudent, (v) => _updateConfig('registration_student_open', v.toString()), isDark),
                            _buildSwitchTile('Coordinator registration open', _regCoordinator, (v) => _updateConfig('registration_coordinator_open', v.toString()), isDark),
                            _buildSwitchTile('Hod registration open', _regHod, (v) => _updateConfig('registration_hod_open', v.toString()), isDark),
                            _buildSwitchTile('Supervisor registration open', _regSupervisor, (v) => _updateConfig('registration_supervisor_open', v.toString()), isDark),
                            
                            const Divider(height: 32),
                            _buildSectionHeaderSmall('Institutional Controls'),
                            _buildSwitchTile('Registration: University', _regUni, (v) => _updateConfig('registration_university_open', v.toString()), isDark),
                            _buildSwitchTile('Registration: Company', _regComp, (v) => _updateConfig('registration_company_open', v.toString()), isDark),
                            
                            const Divider(height: 32),
                            _buildSectionHeaderSmall('Operational Rules'),
                            _buildConfigItem('Internship Rules', 
                              'Min ${config['internship_min_weeks']} Weeks, Max ${config['internship_max_weeks']} Weeks', 
                              Icons.rule_rounded, isDark, 
                              onTap: () => _showInternshipRulesDialog(context, config)),
                            _buildConfigItem('Weekly Deadlines', 
                              'Deadline: ${config['weekly_plan_deadline_day']}', 
                              Icons.event_note_rounded, isDark, 
                              onTap: () {}),
                          ]),
                          const SizedBox(height: 32),
                          _buildSection(context, 'Maintenance Mode', [
                            _buildSwitchTile('Enable Maintenance', _maintenance, (v) => _updateConfig('maintenance_mode', v.toString()), isDark),
                            if (_maintenance)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: TextField(
                                  onSubmitted: (v) => _updateConfig('maintenance_message', v),
                                  decoration: InputDecoration(
                                    hintText: 'Maintenance message...',
                                    helperText: 'Press Enter to save message',
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                  controller: TextEditingController(text: _maintenanceMessage),
                                ),
                              ),
                          ]),
                          const SizedBox(height: 32),
                          _buildSection(context, 'Email / SMTP', [
                            _buildActionTile('SMTP Configuration', Icons.mail_rounded, Colors.blue, isDark, () => _showSMTPDialog(context)),
                            _buildActionTile('Send Test Email', Icons.send_rounded, Colors.green, isDark, () async {
                              final ok = await ref.read(adminRepositoryProvider).testSmtp();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? 'SMTP Connection Successful' : 'SMTP Connection Failed'),
                                  backgroundColor: ok ? Colors.green : Colors.red,
                                ));
                              }
                            }),
                          ]),
                          const SizedBox(height: 32),
                          _buildSection(context, 'Notifications / Broadcast', [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Global Announcement', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _broadcastTitleCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Announcement Title...',
                                      filled: true,
                                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _broadcastContentCtrl,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Type message here...',
                                      filled: true,
                                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('Note: This will be visible to all roles in their common feed and send a notification.', 
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                      ),
                                      const SizedBox(width: 16),
                                      FilledButton.icon(
                                        onPressed: () async {
                                          if (_broadcastTitleCtrl.text.isEmpty || _broadcastContentCtrl.text.isEmpty) return;
                                          try {
                                            await ref.read(adminRepositoryProvider).broadcast(_broadcastTitleCtrl.text, _broadcastContentCtrl.text);
                                            _broadcastTitleCtrl.clear();
                                            _broadcastContentCtrl.clear();
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement Broadcasted!')));
                                          } catch (e) {
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                                          }
                                        },
                                        icon: const Icon(Icons.campaign_rounded, size: 18),
                                        label: const Text('Broadcast'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildSection(context, 'Security', [
                            _buildActionTile('Password Policy', Icons.password_rounded, Colors.orange, isDark, () {}),
                            _buildActionTile('Session Timeout', Icons.timer_rounded, Colors.purple, isDark, () {}),
                            _buildActionTile('API Limits / Rate Limiting', Icons.speed_rounded, Colors.red, isDark, () {}),
                          ]),
                          const SizedBox(height: 120),
                        ]),
                      ),
                    ),
                  ],
                ),
                if (_isUpdating)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInternshipRulesDialog(BuildContext context, Map<String, String> config) {
    final minWeeksCtrl = TextEditingController(text: config['internship_min_weeks']);
    final maxWeeksCtrl = TextEditingController(text: config['internship_max_weeks']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Internship Rules'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: minWeeksCtrl, decoration: const InputDecoration(labelText: 'Minimum Weeks')),
            TextField(controller: maxWeeksCtrl, decoration: const InputDecoration(labelText: 'Maximum Weeks')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _updateConfig('internship_min_weeks', minWeeksCtrl.text);
              _updateConfig('internship_max_weeks', maxWeeksCtrl.text);
              Navigator.pop(ctx);
            }, 
            child: const Text('Save Rules')
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSectionHeaderSmall(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildConfigItem(String title, String value, IconData icon, bool isDark, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey, size: 20),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(value, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.edit_rounded, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  void _showSMTPDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SMTP Configuration'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Host')),
            TextField(decoration: InputDecoration(labelText: 'Port')),
            TextField(decoration: InputDecoration(labelText: 'Username')),
            TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save Settings')),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------
// TOP-LEVEL HELPERS & DELEGATES
// ---------------------------------------------------------

Future<void> _showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Row(
        children: [
          Icon(Icons.logout_rounded, color: Colors.redAccent),
          SizedBox(width: 12),
          Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
      content: const Text('Are you sure you want to sign out? Your session will be ended.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ),
        Container(
          margin: const EdgeInsets.only(left: 8),
          child: FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    // Reset navigation index before clearing session
    ref.read(dashboardIndexProvider.notifier).state = 0;
    await ref.read(appSessionServiceProvider).clearSession();
    if (context.mounted) {
      context.go(AppRoutes.auth);
    }
  }
}

Widget _buildModernSettingItem(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
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

class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  SliverTabBarDelegate(this.tabBar, this.isDark);

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
  bool shouldRebuild(SliverTabBarDelegate oldDelegate) => false;
}

// ---------------------------------------------------------
// MISSING PROVIDERS (LOCAL DERIVATIONS)
// ---------------------------------------------------------

final supervisorIncomingProposalsProvider = FutureProvider<List<InternshipProposal>>((ref) {
  return ref.watch(supervisorRepositoryProvider).getProposals();
});

final supervisorPendingPlansProvider = FutureProvider<List<WeeklyPlan>>((ref) {
  return ref.watch(supervisorRepositoryProvider).getPendingPlans();
});

final supervisorWeeklyReportsProvider = FutureProvider<List<SupervisorAttendanceReport>>((ref) {
  return ref.watch(supervisorRepositoryProvider).getWeeklyReports();
});

final supervisorAttendanceHeatmapProvider = FutureProvider<AttendanceHeatmap>((ref) {
  return ref.watch(supervisorRepositoryProvider).getAttendanceHeatmap();
});

final supervisorStatsProvider = FutureProvider<SupervisorStats>((ref) {
  return ref.watch(supervisorRepositoryProvider).getStats();
});

final supervisorTeamsProvider = FutureProvider<List<SupervisorTeam>>((ref) {
  return ref.watch(supervisorRepositoryProvider).getTeams();
});

final supervisorMeProvider = FutureProvider<SupervisorMe>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getMe();
});

final supervisorStudentsProvider = FutureProvider<List<SupervisorStudent>>((ref) {
  return ref.watch(supervisorRepositoryProvider).getStudents();
});

class _LineChartPainter extends CustomPainter {
  final bool isDark;
  _LineChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
      size.width * 0.2, size.height * 0.8,
      size.width * 0.3, size.height * 0.2,
      size.width * 0.5, size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.7, size.height * 0.6,
      size.width * 0.8, size.height * 0.1,
      size.width, size.height * 0.3,
    );

    canvas.drawPath(path, paint);

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue.withOpacity(0.3), Colors.blue.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
