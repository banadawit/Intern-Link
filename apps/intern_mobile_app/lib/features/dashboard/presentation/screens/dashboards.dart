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
import '../../../auth/presentation/widgets/custom_text_field.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: widget.tabs.map((t) => t.view).toList(),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GNav(
            rippleColor: theme.colorScheme.primary.withOpacity(0.1),
            hoverColor: theme.colorScheme.primary.withOpacity(0.1),
            gap: 8,
            activeColor: theme.colorScheme.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            selectedIndex: _currentIndex,
            onTabChange: (index) => setState(() => _currentIndex = index),
            tabs: widget.tabs.map((t) {
              return GButton(
                icon: t.icon,
                text: t.label,
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
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

class _ModernSliverAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String profileName;
  final List<Color> gradient;
  final IconData backgroundIcon;
  final List<Widget>? actions;

  const _ModernSliverAppBar({
    required this.title,
    required this.subtitle,
    required this.profileName,
    required this.gradient,
    required this.backgroundIcon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 180,
      collapsedHeight: 80,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface.withOpacity(0.1),
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              profileName.isEmpty ? '?' : profileName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                ),
                Text(
                  profileName.isEmpty ? 'User' : profileName.split(' ')[0],
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: actions ?? [
        IconButton(
          onPressed: () {},
          icon: const Badge(
            child: Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(backgroundIcon, size: 200, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
          error: (err, stack) => _buildErrorState(context, ref, err),
          data: (profile) => _buildContent(context, ref, profile),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load profile',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => ref.invalidate(studentProfileProvider),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, StudentProfile profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentProfileProvider),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar replacement with Profile
          // Modern App Bar replacement with Profile
          _ModernSliverAppBar(
            title: 'Student Portal',
            subtitle: 'Welcome back,',
            profileName: profile.fullName,
            gradient: [theme.colorScheme.primary, theme.colorScheme.secondary],
            backgroundIcon: Icons.school_rounded,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats / Status Card
                _buildProgressCard(context, profile),

                const SizedBox(height: 32),

                // Internship Details Header
                if (profile.companyName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.business_center_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Your Placement',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPlacementCard(context, profile),
                  const SizedBox(height: 32),
                ],

                // Action Quick Access
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildQuickAction(context, 'Daily Log', Icons.edit_note_rounded, Colors.blue),
                    _buildQuickAction(context, 'Weekly Plan', Icons.assignment_rounded, Colors.orange),
                    _buildQuickAction(context, 'Messages', Icons.chat_bubble_rounded, Colors.green),
                    _buildQuickAction(context, 'Resources', Icons.folder_rounded, Colors.purple),
                  ],
                ),
                
                const SizedBox(height: 120), // Space for GNav
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, StudentProfile profile) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  profile.status,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Week ${profile.currentInternshipWeek} / 12',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Internship Progress',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: profile.currentInternshipWeek / 12,
              minHeight: 12,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${((profile.currentInternshipWeek / 12) * 100).toInt()}% completed',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementCard(BuildContext context, StudentProfile profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.business_rounded, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.companyName ?? 'Assigned Company',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Primary Organization',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.1), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_pin_rounded, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.supervisorName ?? 'Assigning Supervisor...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Direct Supervisor',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.1), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// STUDENT REAL PLANS TAB (API INTEGRATED)
// ---------------------------------------------------------

class _StudentPlansTab extends ConsumerWidget {
  const _StudentPlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plansAsync = ref.watch(myWeeklyPlansProvider);
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
          data: (profile) => plansAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 16),
                  Text('Failed to load plans', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(myWeeklyPlansProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  )
                ],
              ),
            ),
            data: (plans) {
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(myWeeklyPlansProvider),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _ModernSliverAppBar(
                      title: 'Weekly Plans',
                      subtitle: 'Planning & Submissions',
                      profileName: profile.fullName,
                      gradient: [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
                      backgroundIcon: Icons.calendar_today_rounded,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: plans.isEmpty
                          ? SliverToBoxAdapter(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.1)),
                                    const SizedBox(height: 24),
                                    Text('No Plans Yet', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Submit your first weekly plan to get started.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: () {
                                        // TODO: Navigate to submit plan screen
                                      },
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('New Plan'),
                                    )
                                  ],
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'My Submissions',
                                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                          ),
                                          FilledButton.tonalIcon(
                                            onPressed: () {
                                              // TODO: Navigate to submit plan screen
                                            },
                                            icon: const Icon(Icons.add_rounded, size: 18),
                                            label: const Text('Submit'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final plan = plans[index - 1];
                                  return _buildPlanCard(context, plan, isDark, theme);
                                },
                                childCount: plans.length + 1,
                              ),
                            ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, dynamic plan, bool isDark, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;

    switch (plan.status.toUpperCase()) {
      case 'APPROVED':
        statusColor = const Color(0xFF067647);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFB42318);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFFB54708);
        statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      plan.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Week ${plan.weekNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.planDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (plan.feedback != null && plan.feedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
              ),
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
                        Text(
                          plan.feedback!,
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.event_available_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text(
                '${plan.daySubmissions.length} Daily Check-ins',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// STUDENT REAL JOBS TAB (API INTEGRATED)
// ---------------------------------------------------------

class _StudentJobsTab extends ConsumerStatefulWidget {
  const _StudentJobsTab();

  @override
  ConsumerState<_StudentJobsTab> createState() => _StudentJobsTabState();
}

class _StudentJobsTabState extends ConsumerState<_StudentJobsTab> {
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  void _submitSuggestion() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Placement proposals are created by your coordinator. Contact them with these details.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _companyController.clear();
    _emailController.clear();
    _notesController.clear();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final proposalsAsync = ref.watch(myProposalsProvider);
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
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
                      Text('Placement Proposals', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'Track proposals sent by your school to partner companies.',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 32),
                      
                      proposalsAsync.when(
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                        error: (err, stack) => Center(child: Text('Error loading proposals: $err')),
                        data: (proposals) {
                          if (proposals.isEmpty) {
                            return _buildEmptyProposals(context, isDark, theme);
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: proposals.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final p = proposals[index];
                              return _buildProposalCard(context, p, isDark, theme);
                            },
                          );
                        },
                      ),
                      
                      const SizedBox(height: 48),
                      Text('Suggest a Company', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 16),
                      _buildSuggestionForm(context, isDark, theme),
                      
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
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.business_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.1)),
            const SizedBox(height: 24),
            const Text('No placement proposals yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Your coordinator will list proposals here.',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalCard(BuildContext context, dynamic p, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.apartment_rounded, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.companyName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Requested: ${p.requestedAt.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              p.status.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionForm(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _companyController,
            label: 'Company Name',
            hint: 'Enter company name',
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Contact Email',
            hint: 'HR or Supervisor email',
            prefixIcon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Additional info',
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _submitSuggestion,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Save Draft / Remind Coordinator', style: TextStyle(fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// STUDENT REAL PROFILE TAB
// ---------------------------------------------------------

class _StudentProfileTab extends ConsumerWidget {
  const _StudentProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (profile) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _ModernSliverAppBar(
                  title: 'Account',
                  subtitle: 'Profile Settings',
                  profileName: profile.fullName,
                  gradient: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                  backgroundIcon: Icons.person_rounded,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildProfileHeader(context, profile, theme),
                      const SizedBox(height: 40),
                      Text('Security & Preferences', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 16),
                      _buildSettingItem(context, Icons.security_rounded, 'Account Security', 'Manage passwords and authentication'),
                      const SizedBox(height: 16),
                      _buildSettingItem(context, Icons.notifications_active_rounded, 'Notifications', 'Manage alert preferences'),
                      const SizedBox(height: 16),
                      _buildSettingItem(context, Icons.help_outline_rounded, 'Help & Support', 'Contact coordinator or platform admin'),
                      const SizedBox(height: 40),
                      _buildSignOutButton(context),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic profile, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 32,
                offset: const Offset(0, 16),
              )
            ],
          ),
          child: Center(
            child: Text(
              profile.fullName[0].toUpperCase(),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          profile.fullName,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement logout via AuthController
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        foregroundColor: Colors.redAccent,
        side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.1))),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.1)),
        ],
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
            gradient.first.withOpacity(0.1),
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
                    color: gradient.first.withOpacity(0.1),
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
                color: theme.colorScheme.onSurface.withOpacity(0.1),
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
          view: const _StudentPlansTab(),
        ),
        _DashboardTab(
          label: 'Jobs',
          icon: Icons.work_outline_rounded,
          activeIcon: Icons.work_rounded,
          view: const _StudentJobsTab(),
        ),
        _DashboardTab(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          view: const _StudentProfileTab(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// SUPERVISOR REAL OVERVIEW TAB
// ---------------------------------------------------------

class _SupervisorOverviewTab extends ConsumerWidget {
  const _SupervisorOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final meAsync = ref.watch(supervisorMeProvider);
    final plansAsync = ref.watch(supervisorPlansProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
          data: (me) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(supervisorMeProvider);
                ref.invalidate(supervisorPlansProvider);
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _ModernSliverAppBar(
                    title: 'Supervisor Portal',
                    subtitle: 'Team Overview',
                    profileName: me.fullName,
                    gradient: const [Color(0xFFF2994A), Color(0xFFF2C94C)],
                    backgroundIcon: Icons.pie_chart_rounded,
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: theme.colorScheme.primaryContainer,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.business_rounded, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Company',
                                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      me.companyName,
                                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('Pending Plan Reviews', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 16),
                        plansAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Text('Failed to load plans: $err'),
                          data: (plans) {
                            final pending = plans.where((p) => p.status == 'PENDING').toList();
                            if (pending.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 32),
                                    const SizedBox(width: 16),
                                    const Expanded(child: Text('All student plans are reviewed!', style: TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pending.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final plan = pending[index];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFF2994A).withOpacity(0.1),
                                        child: Text(plan.studentName[0], style: const TextStyle(color: Color(0xFFF2994A), fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(plan.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text('Week ${plan.weekNumber} Plan', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      FilledButton.tonal(
                                        onPressed: () {
                                          // TODO: Navigate to plan review screen
                                        },
                                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF2994A).withOpacity(0.1), foregroundColor: const Color(0xFFD6771F)),
                                        child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        
                        const SizedBox(height: 120), // Space for GNav
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// SUPERVISOR REAL STUDENTS TAB
// ---------------------------------------------------------

class _SupervisorStudentsTab extends ConsumerWidget {
  const _SupervisorStudentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final studentsAsync = ref.watch(supervisorStudentsProvider);
    final meAsync = ref.watch(supervisorMeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
          error: (err, _) => Center(child: Text('Error loading profile: $err')),
          data: (me) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(supervisorStudentsProvider),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _ModernSliverAppBar(
                  title: 'Students',
                  subtitle: 'My Assigned Interns',
                  profileName: me.fullName,
                  gradient: const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                  backgroundIcon: Icons.group_rounded,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: studentsAsync.when(
                    loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                    error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
                    data: (students) {
                      if (students.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                                const SizedBox(height: 16),
                                Text('No students assigned yet.', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final student = students[index];
                            return _buildStudentCard(context, student, isDark, theme);
                          },
                          childCount: students.length,
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, dynamic student, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF56CCF2).withOpacity(0.1),
            child: Text(student.fullName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF2F80ED), fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(student.email, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF2F80ED).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(
              student.status.toUpperCase(),
              style: const TextStyle(color: Color(0xFF2F80ED), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// SUPERVISOR REAL SETTINGS TAB
// ---------------------------------------------------------

class _SupervisorSettingsTab extends ConsumerWidget {
  const _SupervisorSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final meAsync = ref.watch(supervisorMeProvider);

                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFE94057).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.security_rounded, color: Color(0xFFE94057)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Account Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Manage passwords and authentication', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.1))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(appSessionServiceProvider).clearSession();
                    if (context.mounted) context.go(AppRoutes.auth);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
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
          view: const _SupervisorOverviewTab(),
        ),
        _DashboardTab(
          label: 'Students',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          view: const _SupervisorStudentsTab(),
        ),
        _DashboardTab(
          label: 'Settings',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          view: const _SupervisorSettingsTab(),
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
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          view: const _CoordinatorHomeTab(),
        ),
        _DashboardTab(
          label: 'HODs',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          view: const _CoordinatorHodsTab(),
        ),
        _DashboardTab(
          label: 'Companies',
          icon: Icons.business_outlined,
          activeIcon: Icons.business_rounded,
          view: const _CoordinatorCompaniesTab(),
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

class _CoordinatorHomeTab extends ConsumerWidget {
  const _CoordinatorHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(coordinatorStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
          data: (stats) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(coordinatorStatsProvider),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _ModernSliverAppBar(
                  title: 'Coordinator Portal',
                  subtitle: 'Institutional Overview',
                  profileName: 'Coordinator', // Fallback as no specific profile provider found
                  gradient: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  backgroundIcon: Icons.dashboard_rounded,
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        stats.universityName,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Institutional Overview',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 32),
                      
                      // Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildStatCard(context, 'Total Students', stats.totalStudents.toString(), Icons.people_rounded, Colors.blue),
                          _buildStatCard(context, 'Active Placements', stats.activePlacements.toString(), Icons.assignment_turned_in_rounded, Colors.green),
                          _buildStatCard(context, 'Partner Companies', stats.totalCompanies.toString(), Icons.business_rounded, Colors.orange),
                          _buildStatCard(context, 'Pending Proposals', stats.pendingProposals.toString(), Icons.pending_actions_rounded, Colors.purple),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildQuickAction(context, 'Invite Department Head', Icons.person_add_alt_1_rounded, 'Share registration link with HODs'),
                      const SizedBox(height: 12),
                      _buildQuickAction(context, 'Generate Yearly Report', Icons.analytics_rounded, 'Export placement statistics to PDF'),
                      
                      const SizedBox(height: 120), // Space for GNav
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.1))),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _CoordinatorHodsTab extends ConsumerWidget {
  const _CoordinatorHodsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hodsAsync = ref.watch(pendingHodsProvider);

    return Container(
      color: theme.colorScheme.surface,
      child: hodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (hods) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingHodsProvider),
          child: hods.isEmpty 
            ? const Center(child: Text('No pending department heads to verify.'))
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: hods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final hod = hods[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(child: Text(hod['user']['full_name'][0])),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(hod['user']['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(hod['department'], style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
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
                                  onPressed: () => _verify(context, ref, hod['userId'], 'REJECTED'),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _verify(context, ref, hod['userId'], 'APPROVED'),
                                  child: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }

  Future<void> _verify(BuildContext context, WidgetRef ref, int userId, String status) async {
    try {
      await ref.read(coordinatorRepositoryProvider).verifyHod(userId, status);
      ref.invalidate(pendingHodsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('HOD $status successfully')));
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _CoordinatorCompaniesTab extends ConsumerWidget {
  const _CoordinatorCompaniesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Basic list for now
    return const Center(child: Text('Partner Companies List (Coming Soon)'));
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
          view: const _AdminOverviewTab(),
        ),
        _DashboardTab(
          label: 'Approvals',
          icon: Icons.verified_user_outlined,
          activeIcon: Icons.verified_user_rounded,
          view: const _AdminApprovalsTab(),
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

class _AdminOverviewTab extends ConsumerWidget {
  const _AdminOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
          data: (stats) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminStatsProvider),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  collapsedHeight: 80,
                  pinned: true,
                  stretch: true,
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.1),
                  elevation: 0,
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.error,
                        child: const Text(
                          'A',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'System Console',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Badge(
                        child: Icon(Icons.notifications_outlined, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.error, theme.colorScheme.errorContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(Icons.admin_panel_settings_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text('Global Platform Monitoring', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      const SizedBox(height: 32),
                      
                      _buildLargeStat(context, 'Total Active Users', stats.totalUsers.toString(), Icons.group_rounded, theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(child: _buildSmallStat(context, 'Universities', stats.totalUniversities.toString(), Icons.school_rounded, Colors.indigo)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSmallStat(context, 'Companies', stats.totalCompanies.toString(), Icons.business_center_rounded, Colors.teal)),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.error,
                              child: const Icon(Icons.notifications_active_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${stats.pendingApprovals} Pending Approvals', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Review institutional verification requests'),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.error),
                          ],
                        ),
                      ),

                      const SizedBox(height: 120), // Space for GNav
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

  Widget _buildLargeStat(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.1))),
              Text(value, style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          Icon(icon, size: 48, color: color.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildSmallStat(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.1))),
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
    final unisAsync = ref.watch(pendingUniversitiesProvider);
    final compsAsync = ref.watch(pendingCompaniesProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Universities'),
              Tab(text: 'Companies'),
            ],
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildApprovalList(context, ref, unisAsync, true),
                _buildApprovalList(context, ref, compsAsync, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalList(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> asyncData, bool isUni) {
    final theme = Theme.of(context);
    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(isUni ? pendingUniversitiesProvider : pendingCompaniesProvider),
        child: items.isEmpty
            ? const Center(child: Text('No pending requests.'))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: FilledButton(
                      onPressed: () => _approveAll(context, ref, items, isUni),
                      child: const Text('Approve All'),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                                      child: Icon(isUni ? Icons.school_rounded : Icons.business_rounded, color: theme.colorScheme.onSecondaryContainer),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          Text(item['official_email'], style: theme.textTheme.bodySmall),
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
                                        onPressed: () => _updateStatus(context, ref, item['id'], 'REJECTED', isUni),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () => _updateStatus(context, ref, item['id'], 'APPROVED', isUni),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _approveAll(BuildContext context, WidgetRef ref, List<dynamic> items, bool isUni) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      for (final item in items) {
        if (isUni) {
          await repo.updateUniversityStatus(item['id'], 'APPROVED');
        } else {
          await repo.updateCompanyStatus(item['id'], 'APPROVED');
        }
      }
      ref.invalidate(isUni ? pendingUniversitiesProvider : pendingCompaniesProvider);
      ref.invalidate(adminStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All pending items approved')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, int id, String status, bool isUni) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (isUni) {
        await repo.updateUniversityStatus(id, status);
      } else {
        await repo.updateCompanyStatus(id, status);
      }
      ref.invalidate(isUni ? pendingUniversitiesProvider : pendingCompaniesProvider);
      ref.invalidate(adminStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Institution ${status.toLowerCase()} successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
