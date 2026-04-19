import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/student_repository.dart';

// ---------------------------------------------------------
// REUSABLE MODERN SCAFFOLD WITH BOTTOM NAVIGATION
// ---------------------------------------------------------

class _ModernDashboardScaffold extends StatefulWidget {
  const _ModernDashboardScaffold({
    required this.title,
    required this.roleLabel,
    required this.tabs,
  });

  final String title;
  final String roleLabel;
  final List<_DashboardTab> tabs;

  @override
  State<_ModernDashboardScaffold> createState() => _ModernDashboardScaffoldState();
}

class _ModernDashboardScaffoldState extends State<_ModernDashboardScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          widget.tabs[_currentIndex].label,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.7),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: widget.tabs.map((t) => t.view).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
          elevation: 0,
          indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          destinations: widget.tabs.map((t) {
            return NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon, color: theme.colorScheme.primary),
              label: t.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DashboardTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget view;

  _DashboardTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.view,
  });
}

// ---------------------------------------------------------
// STUDENT REAL HOME TAB (API INTEGRATED)
// ---------------------------------------------------------

class _StudentHomeTab extends ConsumerWidget {
  const _StudentHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(studentProfileProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.05),
          ],
        ),
      ),
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.invalidate(studentProfileProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              )
            ],
          ),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentProfileProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            children: [
              // Greeting Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      profile.fullName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          profile.fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Glassmorphic Status Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C8B83), Color(0xFF0A6E7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0C8B83).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(Icons.stars_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    profile.status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.calendar_month_rounded, color: Colors.white70),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Current Progress',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Week ${profile.currentInternshipWeek}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
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

              // Internship Details
              if (profile.companyName != null) ...[
                Text(
                  'Internship Placement',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.business_rounded, color: theme.colorScheme.secondary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Company',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                ),
                                Text(
                                  profile.companyName!,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_pin_rounded, color: Color(0xFF6C63FF)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Supervisor',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                ),
                                Text(
                                  profile.supervisorName ?? 'Not Assigned',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // If not placed yet
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: theme.colorScheme.error),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'You have not been placed in a company yet. Check the Jobs tab to request placements.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// PLACEHOLDER VIEWS FOR OTHER TABS
// ---------------------------------------------------------

class _PremiumPlaceholderView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _PremiumPlaceholderView({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            gradient.first.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradient),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
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
    return _ModernDashboardScaffold(
      title: 'Student Portal',
      roleLabel: 'STUDENT',
      tabs: [
        _DashboardTab(
          label: 'Home',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          view: const _StudentHomeTab(),
        ),
        _DashboardTab(
          label: 'Plans',
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Weekly Plans',
            subtitle: 'Manage and submit your weekly tasks',
            icon: Icons.event_note_rounded,
            gradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
        ),
        _DashboardTab(
          label: 'Jobs',
          icon: Icons.work_outline_rounded,
          activeIcon: Icons.work_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Job Requests',
            subtitle: 'Find and apply for placements',
            icon: Icons.business_center_rounded,
            gradient: [Color(0xFFF12711), Color(0xFFF5AF19)],
          ),
        ),
        _DashboardTab(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          view: const _PremiumPlaceholderView(
            title: 'My Profile',
            subtitle: 'Manage your personal details',
            icon: Icons.manage_accounts_rounded,
            gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// SUPERVISOR DASHBOARD
// ---------------------------------------------------------

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModernDashboardScaffold(
      title: 'Supervisor Portal',
      roleLabel: 'SUPERVISOR',
      tabs: [
        _DashboardTab(
          label: 'Overview',
          icon: Icons.pie_chart_outline_rounded,
          activeIcon: Icons.pie_chart_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Supervisor Dashboard',
            subtitle: 'Track overall team performance',
            icon: Icons.analytics_rounded,
            gradient: [Color(0xFFF2994A), Color(0xFFF2C94C)],
          ),
        ),
        _DashboardTab(
          label: 'Students',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          view: const _PremiumPlaceholderView(
            title: 'My Students',
            subtitle: 'Review student plans and evaluations',
            icon: Icons.groups_rounded,
            gradient: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
          ),
        ),
        _DashboardTab(
          label: 'Settings',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Settings',
            subtitle: 'Configure your preferences',
            icon: Icons.tune_rounded,
            gradient: [Color(0xFF8A2387), Color(0xFFE94057)],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// COORDINATOR DASHBOARD
// ---------------------------------------------------------

class CoordinatorDashboardScreen extends StatelessWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModernDashboardScaffold(
      title: 'Coordinator Portal',
      roleLabel: 'COORDINATOR',
      tabs: [
        _DashboardTab(
          label: 'Home',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Coordinator Dashboard',
            subtitle: 'University-wide placement overview',
            icon: Icons.domain_rounded,
            gradient: [Color(0xFF1D976C), Color(0xFF93F9B9)],
          ),
        ),
        _DashboardTab(
          label: 'Placements',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Manage Placements',
            subtitle: 'Approve and monitor student placements',
            icon: Icons.fact_check_rounded,
            gradient: [Color(0xFF4CB8C4), Color(0xFF3CD3AD)],
          ),
        ),
        _DashboardTab(
          label: 'Companies',
          icon: Icons.business_outlined,
          activeIcon: Icons.business_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Company Directory',
            subtitle: 'Partner organizations list',
            icon: Icons.corporate_fare_rounded,
            gradient: [Color(0xFF834D9B), Color(0xFFD04ED6)],
          ),
        ),
        _DashboardTab(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          view: const _PremiumPlaceholderView(
            title: 'My Profile',
            subtitle: 'Update your coordinator profile',
            icon: Icons.account_circle_rounded,
            gradient: [Color(0xFFEB5757), Color(0xFF000000)],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// ADMIN DASHBOARD
// ---------------------------------------------------------

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModernDashboardScaffold(
      title: 'Admin Portal',
      roleLabel: 'ADMIN',
      tabs: [
        _DashboardTab(
          label: 'Overview',
          icon: Icons.security_outlined,
          activeIcon: Icons.security_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Admin Console',
            subtitle: 'System health and overview',
            icon: Icons.admin_panel_settings_rounded,
            gradient: [Color(0xFF141E30), Color(0xFF243B55)],
          ),
        ),
        _DashboardTab(
          label: 'Approvals',
          icon: Icons.verified_user_outlined,
          activeIcon: Icons.verified_user_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Pending Approvals',
            subtitle: 'Review institutional registrations',
            icon: Icons.how_to_reg_rounded,
            gradient: [Color(0xFFCB2D3E), Color(0xFFEF473A)],
          ),
        ),
        _DashboardTab(
          label: 'Logs',
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Audit Logs',
            subtitle: 'Monitor platform activity',
            icon: Icons.list_alt_rounded,
            gradient: [Color(0xFF3A1C71), Color(0xFFD76D77)],
          ),
        ),
        _DashboardTab(
          label: 'Settings',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          view: const _PremiumPlaceholderView(
            title: 'Global Settings',
            subtitle: 'Configure platform parameters',
            icon: Icons.settings_applications_rounded,
            gradient: [Color(0xFF000046), Color(0xFF1CB5E0)],
          ),
        ),
      ],
    );
  }
}
