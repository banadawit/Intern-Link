import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/desktop_layout.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/download_helper.dart';

import '../../data/repositories/student_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/placement_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/coordinator_repository.dart';
import '../../data/repositories/hod_repository.dart';
import '../../data/repositories/evaluation_repository.dart';
import '../../../universal/data/repositories/notifications_repository.dart';
import '../../../universal/data/repositories/chat_repository.dart';

import '../../../supervisor/data/repositories/supervisor_repository.dart';
import '../../../supervisor/domain/entities/supervisor_entities.dart';
import '../../../supervisor/presentation/providers/supervisor_providers.dart';
import '../../../plans/domain/entities/weekly_plan.dart';
import '../../../plans/presentation/screens/plans_screen.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../feed/data/feed_repository.dart';
import '../../../app_entry/presentation/providers/app_entry_providers.dart';

part 'admin_dash.dart';
part 'coordinator_dash.dart';
part 'hod_dash.dart';
part 'supervisor_dash.dart';
part 'student_dash.dart';


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
  ConsumerState<_ModernDashboardScaffold> createState() =>
      _ModernDashboardScaffoldState();
}

class _ModernDashboardScaffoldState
    extends ConsumerState<_ModernDashboardScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    int currentIndex = ref.watch(dashboardIndexProvider);

    // Safety check: ensure index is within bounds of current role's tabs
    if (currentIndex >= widget.tabs.length) {
      currentIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dashboardIndexProvider.notifier).state = 0;
      });
    }

    // ── Desktop / wide-screen layout ────────────────────────────────────────
    if (isWideScreen(context)) {
      final currentTab = widget.tabs[currentIndex];
      final destinations = widget.tabs
          .map(
            (t) => DesktopNavDestination(
              label: t.label,
              icon: t.icon,
              activeIcon: t.activeIcon,
            ),
          )
          .toList();

      // Build the FAB column same as mobile
      Widget? fab;
      if (!currentTab.hideGlobalFab) {
        final aiFab = Container(
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
                padding: EdgeInsets.all(16),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        );
        if (currentTab.secondaryFab != null) {
          fab = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              currentTab.secondaryFab!,
              const SizedBox(height: 12),
              aiFab,
            ],
          );
        } else {
          fab = aiFab;
        }
      }

      return DesktopScaffold(
        selectedIndex: currentIndex,
        destinations: destinations,
        onDestinationSelected: (i) =>
            ref.read(dashboardIndexProvider.notifier).state = i,
        title: widget.title,
        floatingActionButton: fab,
        body: IndexedStack(
          index: currentIndex,
          children: widget.tabs.map((t) => t.view).toList(),
        ),
      );
    }

    // ── Mobile / narrow layout (original) ───────────────────────────────────
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context, isDark, currentIndex),
      floatingActionButton: widget.tabs[currentIndex].hideGlobalFab
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Secondary FAB (e.g. Assign) shown above AI FAB
                if (widget.tabs[currentIndex].secondaryFab != null) ...[
                  widget.tabs[currentIndex].secondaryFab!,
                  const SizedBox(height: 12),
                ],
                // Global AI FAB
                Container(
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
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: IndexedStack(
        index: currentIndex,
        children: widget.tabs.map((t) => t.view).toList(),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
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
                padding: EdgeInsets.symmetric(
                  horizontal: widget.tabs.length > 4 ? 8 : 12,
                  vertical: 10,
                ),
                duration: const Duration(milliseconds: 500),
                tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.black.withOpacity(0.3),
                selectedIndex: currentIndex,
                onTabChange: (index) =>
                    ref.read(dashboardIndexProvider.notifier).state = index,
                tabs: widget.tabs.map((t) {
                  final isSelected = currentIndex == widget.tabs.indexOf(t);
                  return GButton(
                    icon: t.icon,
                    text: t.label,
                    leading: Icon(
                      isSelected ? t.activeIcon : t.icon,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.black.withOpacity(0.3)),
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
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Intern-Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
                _buildDrawerItem(
                  Icons.notifications_active_rounded,
                  'Notifications',
                  () {
                    Navigator.pop(context);
                    context.push(AppRoutes.notifications);
                  },
                ),
                _buildDrawerItem(
                  Icons.chat_bubble_outline_rounded,
                  'Messages / Chat',
                  () {
                    Navigator.pop(context);
                    context.push(AppRoutes.chat);
                  },
                ),
                _buildDrawerItem(Icons.smart_toy_rounded, 'AI Assistant', () {
                  Navigator.pop(context);
                  context.push(AppRoutes.aiAssistant);
                }),
                const Divider(color: Colors.black12, height: 32),

                // --- Role-Specific Features ---
                if (widget.roleLabel == 'STUDENT') ...[
                  _buildDrawerItem(
                    Icons.assignment_ind_rounded,
                    'My Internship',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          0; // Home
                    },
                    isSelected: currentIndex == 0,
                  ),
                  _buildDrawerItem(
                    Icons.history_edu_rounded,
                    'Weekly Reports',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          1; // Plans
                    },
                    isSelected: currentIndex == 1,
                  ),
                  _buildDrawerItem(
                    Icons.business_center_rounded,
                    'Placement Requests',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          2; // Jobs/Placement
                    },
                    isSelected: currentIndex == 2,
                  ),
                  const Divider(
                    color: Colors.black12,
                    indent: 24,
                    endIndent: 24,
                  ),
                  _buildDrawerItem(
                    Icons.description_rounded,
                    'Final Report',
                    () {
                      Navigator.pop(context);
                      context.push(AppRoutes.reports);
                    },
                  ),
                  _buildDrawerItem(Icons.star_rounded, 'Final Evaluation', () {
                    Navigator.pop(context);
                    context.push(AppRoutes.evaluations);
                  }),
                ] else if (widget.roleLabel == 'SUPERVISOR') ...[
                  _buildDrawerItem(
                    Icons.people_alt_rounded,
                    'Assigned Students',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          1; // Students & Teams
                    },
                    isSelected: currentIndex == 1,
                  ),
                  _buildDrawerItem(
                    Icons.group_work_rounded,
                    'Group Teams',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          1; // Students & Teams (Group Tab)
                    },
                    isSelected: currentIndex == 1,
                  ),
                ] else if (widget.roleLabel == 'COORDINATOR') ...[
                  _buildDrawerItem(
                    Icons.how_to_reg_rounded,
                    'HOD Approvals',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          1; // HODs Tab
                    },
                    isSelected: currentIndex == 1,
                  ),
                  _buildDrawerItem(
                    Icons.apartment_rounded,
                    'Company Directory',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          2; // Companies Tab
                    },
                    isSelected: currentIndex == 2,
                  ),
                ] else if (widget.roleLabel == 'HEAD OF DEPARTMENT') ...[
                  _buildDrawerItem(
                    Icons.groups_3_rounded,
                    'Department Students',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          1; // Students tab
                    },
                    isSelected: currentIndex == 1,
                  ),
                  _buildDrawerItem(Icons.send_rounded, 'Proposals', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state =
                        2; // Proposals tab
                  }, isSelected: currentIndex == 2),
                  _buildDrawerItem(
                    Icons.track_changes_rounded,
                    'Tracking',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          3; // Tracking tab
                    },
                    isSelected: currentIndex == 3,
                  ),
                  _buildDrawerItem(
                    Icons.description_rounded,
                    'Reports',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          4; // Reports tab
                    },
                    isSelected: currentIndex == 4,
                  ),
                ] else if (widget.roleLabel == 'ADMIN') ...[
                  _buildDrawerItem(
                    Icons.business_rounded,
                    'Organizations',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          1; // Orgs Tab
                    },
                    isSelected: currentIndex == 1,
                  ),
                  _buildDrawerItem(
                    Icons.receipt_long_rounded,
                    'System Logs',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          2; // Logs Tab
                    },
                    isSelected: currentIndex == 2,
                  ),
                  _buildDrawerItem(
                    Icons.settings_suggest_rounded,
                    'Config',
                    () {
                      Navigator.pop(context);
                      ref.read(dashboardIndexProvider.notifier).state =
                          3; // Config Tab
                    },
                    isSelected: currentIndex == 3,
                  ),
                ],

                const Divider(color: Colors.black12, height: 32),
                _buildDrawerItem(Icons.person_rounded, 'Account Settings', () {
                  Navigator.pop(context);
                  context.push(AppRoutes.accountSettings);
                }),
                _buildDrawerItem(
                  Icons.help_outline_rounded,
                  'Help & Support',
                  () {
                    Navigator.pop(context);
                    context.push(AppRoutes.helpSupport);
                  },
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.logout_rounded, 'Sign Out', () {
            Navigator.pop(context); // close drawer first
            _showLogoutConfirmation(context, ref);
          }, isDestructive: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: isDestructive
            ? Colors.red.withOpacity(0.1)
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isDestructive
              ? Colors.red
              : (isSelected ? Theme.of(context).colorScheme.primary : null),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive
                ? Colors.red
                : (isSelected ? Theme.of(context).colorScheme.primary : null),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
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

  /// When true, hides the global AI FAB (use when the tab has its own FAB).
  final bool hideGlobalFab;

  /// Optional second FAB shown above the AI FAB.
  final Widget? secondaryFab;

  const _DashboardTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.view,
    this.hideGlobalFab = false,
    this.secondaryFab,
  });
}

// ---------------------------------------------------------
// REUSABLE MODERN SLIVER APP BAR
// ---------------------------------------------------------

class ModernSliverAppBar extends ConsumerWidget {
  ModernSliverAppBar({
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
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            );
          }
          // On wide screens (tablet/desktop) the sidebar IS the navigation —
          // hide the hamburger so it doesn't try to open a non-existent drawer.
          if (isWideScreen(context)) return const SizedBox.shrink();
          return IconButton(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      expandedHeight: responsiveValue(
        context,
        mobile: 200.0,
        tablet: 240.0,
        desktop: 280.0,
      ),
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: gradient.first,
      actions: [
        if (actions != null) ...actions!,
        Consumer(
          builder: (context, ref, child) {
            final unreadMessages = ref
                .watch(unreadChatCountProvider)
                .maybeWhen(data: (count) => count, orElse: () => 0);
            return ModernHeaderIcon(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => context.push(AppRoutes.chat),
              hasBadge: unreadMessages > 0,
              badgeCount: unreadMessages,
            );
          },
        ),
        const SizedBox(width: 12),
        Consumer(
          builder: (context, ref, child) {
            final unreadCount = ref
                .watch(unreadNotificationCountProvider)
                .maybeWhen(data: (count) => count, orElse: () => 0);
            return ModernHeaderIcon(
              icon: Icons.notifications_none_rounded,
              onTap: () => _showNotificationCenter(context, ref),
              hasBadge: unreadCount > 0,
              badgeCount: unreadCount,
            );
          },
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
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
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
            CustomPaint(
              painter: _MeshPainter(color: Colors.white.withOpacity(0.1)),
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsiveValue(
                            context,
                            mobile: 32.0,
                            tablet: 38.0,
                            desktop: 44.0,
                          ),
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
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          profileName.split(' ')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  void _showNotificationCenter(BuildContext context, WidgetRef ref) {
    showResponsiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final notificationsAsync = ref.watch(notificationsProvider);
          final unreadCount = notificationsAsync.maybeWhen(
            data: (notifs) => notifs.where((n) => !n.isRead).length,
            orElse: () => 0,
          );

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(
              responsiveValue(
                context,
                mobile: 16.0,
                tablet: 32.0,
                desktop: 48.0,
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: () async {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .markAllAsRead();
                          ref.invalidate(notificationsProvider);
                          ref.invalidate(unreadNotificationCountProvider);
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Mark all read'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: notificationsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'All caught up!',
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
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return _buildNotificationItem(context, ref, n);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    NotificationModel n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final msg = n.message;

    // Smart icon + color based on message content
    IconData icon = Icons.notifications_rounded;
    Color color = Colors.blue;
    String category = 'Update';

    if (msg.contains('approved') || msg.contains('✅')) {
      icon = Icons.check_circle_rounded;
      color = Colors.green;
      category = 'Approved';
    } else if (msg.contains('rejected') || msg.contains('❌')) {
      icon = Icons.cancel_rounded;
      color = Colors.red;
      category = 'Rejected';
    } else if (msg.contains('proposal') || msg.contains('📋')) {
      icon = Icons.work_rounded;
      color = Colors.purple;
      category = 'Proposal';
    } else if (msg.contains('plan') || msg.contains('📝')) {
      icon = Icons.assignment_rounded;
      color = Colors.orange;
      category = 'Plan';
    } else if (msg.contains('placement') || msg.contains('internship')) {
      icon = Icons.business_center_rounded;
      color = Colors.teal;
      category = 'Placement';
    } else if (msg.contains('report') || msg.contains('📄')) {
      icon = Icons.description_rounded;
      color = Colors.indigo;
      category = 'Report';
    } else if (msg.contains('open letter') || msg.contains('📩')) {
      icon = Icons.mail_rounded;
      color = Colors.amber.shade700;
      category = 'Open Letter';
    }

    return GestureDetector(
      onTap: n.isRead
          ? null
          : () async {
              await ref.read(notificationsRepositoryProvider).markAsRead(n.id);
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead
              ? (isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02))
              : (isDark
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? Colors.transparent : Colors.blue.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: n.isRead
                    ? Colors.grey.withOpacity(0.1)
                    : color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: n.isRead ? Colors.grey : color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.w500
                              : FontWeight.w800,
                          fontSize: 12,
                          color: n.isRead ? Colors.grey : color,
                        ),
                      ),
                      Text(
                        timeago.format(n.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    msg,
                    style: TextStyle(
                      fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600,
                      fontSize: 13,
                      color: n.isRead ? Colors.grey : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!n.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
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
      path.quadraticBezierTo(
        i + 20,
        size.height / 2,
        i.toDouble(),
        size.height,
      );
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
  final bool hasBadge;
  final int badgeCount;

  const ModernHeaderIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
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
        ),
        if (hasBadge)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                badgeCount > 99
                    ? '99+'
                    : badgeCount > 0
                    ? '$badgeCount'
                    : '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// --- SHARED ANALYTICS WIDGETS ---

/// Safely converts any JSON numeric value (int, double, String) to int.
int _parseInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Extracts a human-readable error message from a DioException or any other error.
String _extractErrorMessage(Object e) {
  // Try to get the server-side message from DioException
  try {
    // DioException stores the server message in .message (set by our interceptor)
    // or in .response.data
    final dynamic dio = e;
    final msg = dio.message as String?;
    if (msg != null && msg.isNotEmpty && !msg.startsWith('DioException'))
      return msg;
    final data = dio.response?.data;
    if (data is Map) {
      final serverMsg = (data['error'] ?? data['message'] ?? data['msg'])
          ?.toString();
      if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
    }
    final statusCode = dio.response?.statusCode;
    if (statusCode != null) return 'Server error ($statusCode)';
  } catch (_) {}
  final str = e.toString();
  // Strip the "Exception: " prefix if present
  if (str.startsWith('Exception: ')) return str.substring(11);
  if (str.contains('DioException'))
    return 'Network error — check your connection';
  return str;
}

/// Safely converts any JSON boolean value (bool, int, String) to bool.
bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return false;
}

/// Shows a modal bottom sheet that is constrained to a sensible max width
/// on tablet/desktop so it doesn't stretch edge-to-edge.
Future<T?> showResponsiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
}) {
  final w = MediaQuery.of(context).size.width;
  // On tablet/desktop, cap the sheet width and center it
  final maxW = w >= 1200 ? 640.0 : (w >= 600 ? 560.0 : double.infinity);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? Colors.transparent,
    constraints: maxW < double.infinity ? BoxConstraints(maxWidth: maxW) : null,
    builder: builder,
  );
}

/// Top-level reusable verification document row.
/// Shows a tappable "Open" button when a URL exists, or a muted "No document" label.
Widget _buildDocumentRow(
  BuildContext context,
  String docUrl,
  bool hasDoc,
  bool isDark, {
  bool viewed = false,
  VoidCallback? onView,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: hasDoc
          ? (viewed ? Colors.green.withOpacity(0.07) : Colors.blue.withOpacity(0.07))
          : (isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.grey.withOpacity(0.07)),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: hasDoc
            ? (viewed ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2))
            : Colors.grey.withOpacity(0.15),
      ),
    ),
    child: Row(
      children: [
        Icon(
          hasDoc ? Icons.description_rounded : Icons.description_outlined,
          size: 16,
          color: hasDoc ? (viewed ? Colors.green : Colors.blue) : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasDoc
                ? (viewed ? 'Verification document (Viewed ✓)' : 'Verification document (New)')
                : 'No verification document',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasDoc ? Colors.blue.shade700 : Colors.grey,
            ),
          ),
        ),
        if (hasDoc)
          GestureDetector(
            onTap: () async {
              if (onView != null) onView();
              final uri = Uri.tryParse(docUrl);
              if (uri != null) {
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open document')),
                    );
                  }
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: viewed ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

/// Coordinator approval action bar with document-viewed gate.
/// The Approve button is disabled until the admin opens the verification document.
class _CoordApprovalActions extends StatefulWidget {
  const _CoordApprovalActions({
    required this.coord,
    required this.hasDoc,
    required this.docUrl,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
    this.viewed = false,
    this.onView,
  });

  final dynamic coord;
  final bool hasDoc;
  final String docUrl;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool viewed;
  final VoidCallback? onView;

  @override
  State<_CoordApprovalActions> createState() => _CoordApprovalActionsState();
}

class _CoordApprovalActionsState extends State<_CoordApprovalActions> {
  Future<void> _openDoc() async {
    final uri = Uri.tryParse(widget.docUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      widget.onView?.call();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isViewed = widget.viewed;
    final canApprove = widget.hasDoc && isViewed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Document gate notice
          if (widget.hasDoc)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isViewed
                    ? Colors.green.withOpacity(0.08)
                    : Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isViewed
                      ? Colors.green.withOpacity(0.3)
                      : Colors.amber.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isViewed
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 15,
                    color: isViewed ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isViewed
                          ? 'Document verified.'
                          : 'Open the verification document before approving.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isViewed ? Colors.green : Colors.amber,
                      ),
                    ),
                  ),
                  if (!isViewed)
                    TextButton(
                      onPressed: _openDoc,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber.shade800,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 15,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Missing verification document. Approval disabled.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onReject,
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
                child: Tooltip(
                  message: canApprove
                      ? ''
                      : (widget.hasDoc
                            ? 'Open the document first'
                            : 'Document missing'),
                  child: FilledButton.icon(
                    onPressed: canApprove ? widget.onApprove : null,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: canApprove
                          ? Colors.green
                          : Colors.grey.shade400,
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
      ),
    );
  }
}

/// Supervisor approval action bar — same document-viewed gate, purple approve button.
class _SupApprovalActions extends StatefulWidget {
  const _SupApprovalActions({
    required this.sup,
    required this.hasDoc,
    required this.docUrl,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
    this.viewed = false,
    this.onView,
  });
  final dynamic sup;
  final bool hasDoc;
  final String docUrl;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool viewed;
  final VoidCallback? onView;

  @override
  State<_SupApprovalActions> createState() => _SupApprovalActionsState();
}

class _SupApprovalActionsState extends State<_SupApprovalActions> {
  Future<void> _openDoc() async {
    final uri = Uri.tryParse(widget.docUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      widget.onView?.call();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isViewed = widget.viewed;
    final canApprove = widget.hasDoc && isViewed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.hasDoc)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isViewed
                    ? Colors.green.withOpacity(0.08)
                    : Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isViewed
                      ? Colors.green.withOpacity(0.3)
                      : Colors.amber.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isViewed
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 15,
                    color: isViewed ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isViewed
                          ? 'Document verified.'
                          : 'Open the verification document before approving.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isViewed ? Colors.green : Colors.amber,
                      ),
                    ),
                  ),
                  if (!isViewed)
                    TextButton(
                      onPressed: _openDoc,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber.shade800,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 15,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Missing verification document. Approval disabled.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onReject,
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
                child: Tooltip(
                  message: canApprove ? '' : 'Open the document first',
                  child: FilledButton.icon(
                    onPressed: canApprove ? widget.onApprove : null,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: canApprove
                          ? Colors.purple
                          : Colors.grey.shade400,
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
      ),
    );
  }
}

/// Simple data holder for analytics stat cells.
class _StatItem {
  const _StatItem(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

// ── Proposal Status Badge ─────────────────────────────────────────────────────
/// Compact badge showing a student's proposal status in the picker list.
class _ProposalStatusBadge extends StatelessWidget {
  final String
  status; // 'PENDING' | 'APPROVED' | 'REJECTED' | 'PLACED' | 'AVAILABLE'
  const _ProposalStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'PENDING' => (
        'Pending Proposal',
        Colors.amber.shade700,
        Icons.hourglass_top_rounded,
      ),
      'APPROVED' => ('Placed', Colors.green, Icons.check_circle_rounded),
      'REJECTED' => ('Rejected', Colors.red, Icons.cancel_rounded),
      'PLACED' => ('Placed', Colors.green, Icons.check_circle_rounded),
      _ => ('Available', Colors.teal, Icons.circle_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Smart Conflict Dialog ─────────────────────────────────────────────────────
/// Shows a contextual dialog when a student already has a proposal conflict.
Future<_ConflictAction?> _showSmartConflictDialog(
  BuildContext context, {
  required String studentName,
  required String proposalStatus,
  required String companyName,
  String? teamName,
  DateTime? submittedAt,
}) {
  final timeStr = submittedAt != null
      ? timeago.format(submittedAt)
      : 'recently';
  final (title, body, color) = switch (proposalStatus) {
    'APPROVED' => (
      '🟢 Already Placed',
      '$studentName is already placed at $companyName.',
      Colors.green,
    ),
    'REJECTED' => (
      '🔴 Previously Rejected',
      '$studentName had a proposal to $companyName that was rejected $timeStr. You can send a new proposal.',
      Colors.red,
    ),
    _ => (
      '🟡 Active Proposal Exists',
      teamName != null
          ? '$studentName is already in team "$teamName" with a pending proposal to $companyName (sent $timeStr).'
          : '$studentName already has a pending proposal to $companyName (sent $timeStr).',
      Colors.amber.shade700,
    ),
  };

  return showDialog<_ConflictAction>(
    context: context,
    builder: (d) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      content: Text(body, style: const TextStyle(height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, _ConflictAction.cancel),
          child: const Text('Cancel'),
        ),
        if (proposalStatus == 'REJECTED')
          FilledButton(
            onPressed: () => Navigator.pop(d, _ConflictAction.sendNew),
            style: FilledButton.styleFrom(backgroundColor: color),
            child: const Text('Send New Proposal'),
          ),
        if (proposalStatus == 'PENDING')
          OutlinedButton(
            onPressed: () => Navigator.pop(d, _ConflictAction.viewProposal),
            style: OutlinedButton.styleFrom(foregroundColor: color),
            child: const Text('View Proposal'),
          ),
      ],
    ),
  );
}

enum _ConflictAction { cancel, sendNew, viewProposal }

Widget _buildPlatformAnalytics(
  BuildContext context,
  bool isDark, {
  String growthTitle = 'User Growth',
  String growthTrend = '+12% this month',
  String placementTitle = 'Placements',
  String placementSub = '452 Active',
  String successTitle = 'Proposal Success',
  double successRate = 0.84,
  String submissionTitle = 'Report Submissions',
  String submissionSub = '95% Weekly Target',
}) {
  final double width = MediaQuery.of(context).size.width;
  final bool wide = width >= 900;
  final bool mid = width >= 600 && width < 900;

  return Column(
    children: [
      if (wide)
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                growthTitle,
                growthTrend,
                _buildLineChart(isDark),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                placementTitle,
                placementSub,
                _buildBarChart(isDark),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                successTitle,
                '${(successRate * 100).toInt()}% Rate',
                _buildCircularProgress(successRate, Colors.blue),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                submissionTitle,
                submissionSub,
                _buildBarChart(isDark, color: Colors.orange),
                isDark,
              ),
            ),
          ],
        )
      else if (mid) ...[
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                growthTitle,
                growthTrend,
                _buildLineChart(isDark),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                placementTitle,
                placementSub,
                _buildBarChart(isDark),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                successTitle,
                '${(successRate * 100).toInt()}% Rate',
                _buildCircularProgress(successRate, Colors.blue),
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          submissionTitle,
          submissionSub,
          _buildBarChart(isDark, color: Colors.orange),
          isDark,
        ),
      ] else ...[
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                growthTitle,
                growthTrend,
                _buildLineChart(isDark),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                placementTitle,
                placementSub,
                _buildBarChart(isDark),
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                successTitle,
                '${(successRate * 100).toInt()}% Rate',
                _buildCircularProgress(successRate, Colors.blue),
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                submissionTitle,
                submissionSub,
                _buildBarChart(isDark, color: Colors.orange),
                isDark,
              ),
            ),
          ],
        ),
      ],
    ],
  );
}

Widget _buildChartCard(
  String title,
  String subtitle,
  Widget chart,
  bool isDark,
) {
  return Container(
    height: 180,
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
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
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
        Text(
          '${(value * 100).toInt()}%',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
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

// ── Reusable Review Components ────────────────────────────────────────────────

/// Data class for a single info field in the review sheet
class _ReviewField {
  final String label;
  final String value;
  final IconData icon;
  const _ReviewField(this.label, this.value, this.icon);
}

/// Data class for an attachment in the review sheet
class _ReviewAttachment {
  final String name;
  final String url;
  final String type; // 'pdf' | 'image' | 'file'
  const _ReviewAttachment({
    required this.name,
    required this.url,
    required this.type,
  });
}

/// Universal review details bottom sheet.
/// Shows full context (fields, description, attachments) before approve/reject.
class _ReviewDetailsSheet extends StatefulWidget {
  const _ReviewDetailsSheet({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.fields,
    required this.attachments,
    required this.onApprove,
    required this.onReject,
    this.description,
    this.descriptionLabel,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final List<_ReviewField> fields;
  final String? description;
  final String? descriptionLabel;
  final List<_ReviewAttachment> attachments;
  final VoidCallback onApprove;
  final void Function(String reason) onReject;

  @override
  State<_ReviewDetailsSheet> createState() => _ReviewDetailsSheetState();
}

class _ReviewDetailsSheetState extends State<_ReviewDetailsSheet> {
  bool _descExpanded = false;
  bool _showRejectInput = false;
  final _rejectCtrl = TextEditingController();

  @override
  void dispose() {
    _rejectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                  color: widget.badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.badge,
                  style: TextStyle(
                    color: widget.badgeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info fields
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: widget.fields
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    f.icon,
                                    size: 15,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    f.label,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Flexible(
                                    child: Text(
                                      f.value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  // Description
                  if (widget.description != null &&
                      widget.description!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      widget.descriptionLabel ?? 'Description',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.description!,
                              maxLines: _descExpanded ? null : 3,
                              overflow: _descExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                            if (widget.description!.length > 120) ...[
                              const SizedBox(height: 6),
                              Text(
                                _descExpanded ? 'Show less ▲' : 'Show more ▼',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Attachments
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Attachments',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (widget.attachments.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'None',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...widget.attachments.map(
                      (a) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                a.type == 'pdf'
                                    ? Icons.picture_as_pdf_rounded
                                    : a.type == 'image'
                                    ? Icons.image_rounded
                                    : Icons.attach_file_rounded,
                                color: Colors.teal,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    a.type.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                                color: Colors.teal,
                              ),
                              tooltip: 'Open file',
                              onPressed: () async {
                                final uri = Uri.tryParse(a.url);
                                if (uri != null) {
                                  try {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (_) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Could not open file'),
                                        ),
                                      );
                                  }
                                }
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.folder_off_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No files uploaded',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Reject reason input
                  if (_showRejectInput) ...[
                    TextField(
                      controller: _rejectCtrl,
                      decoration: InputDecoration(
                        labelText: 'Rejection reason (required)',
                        hintText: 'Explain why this is being rejected…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.04)
                            : const Color(0xFFF8FAFC),
                      ),
                      maxLines: 3,
                      autofocus: true,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _showRejectInput = false;
                              _rejectCtrl.clear();
                            }),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (_rejectCtrl.text.trim().length < 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please provide a reason (min 5 characters)',
                                    ),
                                  ),
                                );
                                return;
                              }
                              widget.onReject(_rejectCtrl.text.trim());
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Confirm Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action bar (only shown when not in reject input mode)
          if (!_showRejectInput) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showRejectInput = true),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
}

// ---------------------------------------------------------
// STUDENT DASHBOARD
// ---------------------------------------------------------







enum _InternshipStatus { active, pending, notPlaced }















// ── Reusable components ───────────────────────────────────────────────────────

class _AlertData {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback onTap;
  const _AlertData(this.icon, this.message, this.color, this.onTap);
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.data, required this.isDark});
  final _AlertData data;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: data.color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(data.icon, color: data.color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.message,
                style: TextStyle(
                  color: data.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: data.color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MetricData(this.label, this.value, this.icon, this.color, this.onTap);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data, required this.isDark});
  final _MetricData data;
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: data.color.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon, color: data.color, size: 18),
                ),
                if (data.value > 0)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: data.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.value}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: data.value > 0 ? data.color : null,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  data.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentSnapshotRow extends StatelessWidget {
  const _StudentSnapshotRow({
    required this.student,
    required this.isDark,
    required this.onTap,
  });
  final SupervisorStudentSummary student;
  final bool isDark;
  final VoidCallback onTap;

  Color get _statusColor => student.status == 'ACTIVE'
      ? Colors.green
      : student.status == 'AT_RISK'
      ? Colors.orange
      : Colors.red;
  IconData get _statusIcon => student.status == 'ACTIVE'
      ? Icons.check_circle_rounded
      : student.status == 'AT_RISK'
      ? Icons.warning_rounded
      : Icons.cancel_rounded;
  String get _statusLabel => student.status == 'AT_RISK'
      ? 'At Risk'
      : student.status == 'INACTIVE'
      ? 'Inactive'
      : 'Active';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: student.status != 'ACTIVE'
                ? _statusColor.withOpacity(0.25)
                : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04)),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _statusColor.withOpacity(0.12),
              child: Text(
                student.studentName.isNotEmpty ? student.studentName[0] : '?',
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    student.lastPlanWeek != null
                        ? 'Week ${student.lastPlanWeek} plan · ${student.lastPlanStatus ?? ''}'
                        : 'No plan submitted',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon, size: 10, color: _statusColor),
                  const SizedBox(width: 3),
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPill extends StatelessWidget {
  const _ActivityPill(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}



















// ── Profile Hub reusable components ──────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.05),
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
      ],
    ),
    child: child,
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });
  final String title;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value, this.isDark);
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey.shade400),
      const SizedBox(width: 10),
      Text(
        '$label: ',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
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
  );
}

class _PerfStat extends StatelessWidget {
  const _PerfStat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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
  );
}

class _RateBar extends StatelessWidget {
  const _RateBar(this.label, this.rate, this.color, this.isDark);
  final String label;
  final int rate;
  final Color color;
  final bool isDark;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$rate%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: rate / 100,
          minHeight: 7,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ],
  );
}



/// Assign FAB — navigates to the Management tab (Assignments sub-tab).






Widget _buildActivityItem(
  BuildContext context,
  String title,
  String subtitle,
  String time,
  Color color,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
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
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.flash_on_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}





// ── HOD Detail Screen ─────────────────────────────────────────────────────────








// ── Per-department student list ───────────────────────────────────────────────














// ── Reports sub-view ──────────────────────────────────────────────────────────


// ── Analytics sub-view ────────────────────────────────────────────────────────




// ══════════════════════════════════════════════════════════════════════════════
// HOD TABS — fully wired to real backend

// ══════════════════════════════════════════════════════════════════════════════
// HOD TABS — fully wired to real backend
// ══════════════════════════════════════════════════════════════════════════════

// ── Overview ──────────────────────────────────────────────────────────────────


// ── Students ──────────────────────────────────────────────────────────────────




// ── Send Proposal Bottom Sheet ────────────────────────────────────────────────




// ── Proposals ─────────────────────────────────────────────────────────────────




// ── Tracking ──────────────────────────────────────────────────────────────────




// ── Reports ───────────────────────────────────────────────────────────────────












final optimisticOrgsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

// ── Standalone FAB — lives in the scaffold FAB slot, has its own ref ──────────


String _getReadableError(dynamic e) {
  if (e.runtimeType.toString() == 'DioException' ||
      e.runtimeType.toString() == '_DioException') {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map) {
        return data['message'] ?? data['error'] ?? 'Server error';
      }
    } catch (_) {}
    return 'Network connection failed.';
  }
  return e.toString().replaceAll('Exception: ', '');
}

/// Top-level function — no dependency on any State, works from any context.
void _showCreateOrgSheet(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  String orgType = 'University';
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final contactNameCtrl = TextEditingController();
  final contactEmailCtrl = TextEditingController();
  bool isSaving = false;

  showResponsiveSheet(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final color = orgType == 'University'
            ? const Color(0xFF3B82F6)
            : const Color(0xFF8B5CF6);
        final icon = orgType == 'University'
            ? Icons.account_balance_rounded
            : Icons.business_rounded;
        final roleLabel = orgType == 'University'
            ? 'Coordinator'
            : 'Supervisor';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 16),
                  child: Column(
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Create Organization',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  'Auto-approved · setup email sent to contact',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
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
                    ],
                  ),
                ),

                // ── Scrollable body ──────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _typeToggle(
                                'University',
                                Icons.account_balance_rounded,
                                const Color(0xFF3B82F6),
                                orgType,
                                (v) => setModalState(() => orgType = v),
                              ),
                              _typeToggle(
                                'Company',
                                Icons.business_rounded,
                                const Color(0xFF8B5CF6),
                                orgType,
                                (v) => setModalState(() => orgType = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Organization details section
                        _sectionLabel('Organization Details', isDark),
                        const SizedBox(height: 12),
                        _formField(
                          nameCtrl,
                          'Name *',
                          'e.g. Addis Ababa University',
                          icon,
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _formField(
                          emailCtrl,
                          'Official Email *',
                          'e.g. info@aau.edu.et',
                          Icons.email_rounded,
                          isDark,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _formField(
                          addressCtrl,
                          'Address',
                          'e.g. Addis Ababa, Ethiopia',
                          Icons.location_on_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 24),

                        // Contact person section
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? color.withOpacity(0.06)
                                : color.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: color.withOpacity(0.18)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.person_add_rounded,
                                      size: 14,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$roleLabel Contact',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'optional',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Creates an account and sends a password setup email.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _formField(
                                contactNameCtrl,
                                'Full Name',
                                'Contact person\'s name',
                                Icons.person_rounded,
                                isDark,
                              ),
                              const SizedBox(height: 10),
                              _formField(
                                contactEmailCtrl,
                                'Email',
                                'Contact person\'s email',
                                Icons.email_outlined,
                                isDark,
                                keyboard: TextInputType.emailAddress,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = nameCtrl.text.trim();
                                    final email = emailCtrl.text.trim();
                                    if (name.isEmpty || email.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                      final repo = ref.read(
                                        adminRepositoryProvider,
                                      );
                                      Map<String, dynamic> createdOrg;
                                      if (orgType == 'University') {
                                        createdOrg = await repo
                                            .createUniversity(
                                              name: name,
                                              officialEmail: email,
                                              address: addressCtrl.text.trim(),
                                              contactName: contactNameCtrl.text
                                                  .trim(),
                                              contactEmail: contactEmailCtrl
                                                  .text
                                                  .trim(),
                                            );
                                        createdOrg['type'] = 'University';
                                      } else {
                                        createdOrg = await repo.createCompany(
                                          name: name,
                                          officialEmail: email,
                                          address: addressCtrl.text.trim(),
                                          contactName: contactNameCtrl.text
                                              .trim(),
                                          contactEmail: contactEmailCtrl.text
                                              .trim(),
                                        );
                                        createdOrg['type'] = 'Company';
                                      }
                                      createdOrg['approval_status'] =
                                          'APPROVED';
                                      ref
                                          .read(optimisticOrgsProvider.notifier)
                                          .update(
                                            (state) => [createdOrg, ...state],
                                          );
                                      ref.invalidate(allUniversitiesProvider);
                                      ref.invalidate(allCompaniesProvider);
                                      ref.invalidate(adminStatsProvider);
                                      if (context.mounted) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    '$orgType "$name" created successfully.'
                                                    '${contactEmailCtrl.text.trim().isNotEmpty ? ' Setup email sent.' : ''}',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    _getReadableError(e),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
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
                                : const Icon(Icons.add_rounded, size: 20),
                            label: Text(
                              isSaving ? 'Creating...' : 'Create $orgType',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
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
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Segmented type toggle button for University / Company.
Widget _typeToggle(
  String label,
  IconData icon,
  Color color,
  String current,
  ValueChanged<String> onTap,
) {
  final selected = current == label;
  return Expanded(
    child: GestureDetector(
      onTap: () => onTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Section label for the create org form.
Widget _sectionLabel(String text, bool isDark) {
  return Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 13,
      color: isDark ? Colors.white70 : Colors.black87,
    ),
  );
}

/// Compact form field for the create org sheet.
Widget _formField(
  TextEditingController ctrl,
  String label,
  String hint,
  IconData icon,
  bool isDark, {
  TextInputType? keyboard,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty) ...[
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 5),
      ],
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: Icon(icon, size: 17, color: Colors.grey.shade400),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    ],
  );
}

// ── Small reusable widgets for the create-org sheet ──────────────────────────



















// ---------------------------------------------------------
// TOP-LEVEL HELPERS & DELEGATES
// ---------------------------------------------------------

Future<void> _showLogoutConfirmation(
  BuildContext context,
  WidgetRef ref,
) async {
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
      content: const Text(
        'Are you sure you want to sign out? Your session will be ended.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 8),
          child: FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
    // Invalidate cached profile so the next login fetches fresh data
    ref.invalidate(userProfileProvider);
    ref.invalidate(appStartDecisionProvider);
    if (context.mounted) {
      context.go(AppRoutes.auth);
    }
  }
}

Widget _buildModernSettingItem(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle, {
  VoidCallback? onTap,
}) {
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
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
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
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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

final supervisorIncomingProposalsProvider =
    FutureProvider<List<InternshipProposal>>((ref) {
      return ref.watch(supervisorRepositoryProvider).getProposals();
    });

final supervisorPendingPlansProvider = FutureProvider<List<WeeklyPlan>>((ref) {
  return ref.watch(supervisorRepositoryProvider).getPendingPlans();
});

final supervisorWeeklyReportsProvider =
    FutureProvider<List<SupervisorAttendanceReport>>((ref) {
      return ref.watch(supervisorRepositoryProvider).getWeeklyReports();
    });

final supervisorAttendanceHeatmapProvider = FutureProvider<AttendanceHeatmap>((
  ref,
) {
  return ref.watch(supervisorRepositoryProvider).getAttendanceHeatmap();
});

final supervisorStatsProvider = FutureProvider<SupervisorStats>((ref) {
  return ref.watch(supervisorRepositoryProvider).getStats();
});

final supervisorDashboardProvider = FutureProvider<SupervisorDashboardData>((
  ref,
) {
  return ref.watch(supervisorRepositoryProvider).getDashboard();
});

final supervisorPerformanceProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(supervisorRepositoryProvider).getPerformance();
});

final supervisorTeamsProvider = FutureProvider<List<SupervisorTeam>>((ref) {
  return ref.watch(supervisorRepositoryProvider).getTeams();
});

final supervisorProjectsProvider = FutureProvider<List<SupervisorProject>>((
  ref,
) {
  return ref.watch(supervisorRepositoryProvider).getProjects();
});

final supervisorAssignmentsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
      return ref.watch(supervisorRepositoryProvider).getAssignments();
    });

final supervisorMeProvider = FutureProvider<SupervisorMe>((ref) async {
  return ref.watch(supervisorRepositoryProvider).getMe();
});

final supervisorStudentsProvider = FutureProvider<List<SupervisorStudent>>((
  ref,
) {
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
      size.width * 0.2,
      size.height * 0.8,
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.7,
      size.height * 0.6,
      size.width * 0.8,
      size.height * 0.1,
      size.width,
      size.height * 0.3,
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

// --- COMMON FEED PREVIEW SECTION ---

class FeedPreviewSection extends ConsumerWidget {
  const FeedPreviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final feedAsync = ref.watch(feedProvider);

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Feed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Latest community updates',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.commonFeed),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          feedAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Text('Error: $err', style: const TextStyle(fontSize: 12)),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No updates yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              final previewPosts = posts.take(3).toList();
              return Column(
                children: previewPosts.map((post) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.commonFeed),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (post.isPinned ? Colors.blue : Colors.grey)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              post.isPinned
                                  ? Icons.campaign_rounded
                                  : Icons.dynamic_feed_rounded,
                              size: 16,
                              color: post.isPinned ? Colors.blue : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title ??
                                      (post.content.length > 30
                                          ? '${post.content.substring(0, 30)}...'
                                          : post.content),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${post.author.fullName} • ${timeago.format(post.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── _SupervisorAssignmentScreen ───────────────────────────────────────────────




void _viewRequestDoc(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> req, {
  VoidCallback? onOpened,
}) async {
  final url = req['verification_doc'];
  if (url == null) return;

  try {
    await ref.read(adminRepositoryProvider).markRequestAsViewed(req['id']);
  } catch (_) {}

  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (onOpened != null) onOpened();
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document link.')),
      );
    }
  }
}

class _OrgRequestActions extends ConsumerStatefulWidget {
  final Map<String, dynamic> req;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _OrgRequestActions({
    required this.req,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
  });

  @override
  ConsumerState<_OrgRequestActions> createState() => _OrgRequestActionsState();
}

class _OrgRequestActionsState extends ConsumerState<_OrgRequestActions> {
  bool _docViewed = false;

  @override
  void initState() {
    super.initState();
    _docViewed = widget.req['document_viewed'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _docViewed
                  ? Colors.green.withOpacity(0.05)
                  : Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _docViewed
                    ? Colors.green.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _docViewed
                          ? Icons.fact_check_rounded
                          : Icons.rule_rounded,
                      size: 16,
                      color: _docViewed ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Verification Checklist',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _viewRequestDoc(
                        context,
                        ref,
                        widget.req,
                        onOpened: () => setState(() => _docViewed = true),
                      ),
                      child: const Text(
                        'View Document',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildCheckItem(
                  'Review organization name: "${widget.req['name']}"',
                  true,
                  widget.isDark,
                ),
                _buildCheckItem(
                  'Review uploaded document',
                  _docViewed,
                  widget.isDark,
                ),
                _buildCheckItem(
                  'Confirm name matches document',
                  _docViewed,
                  widget.isDark,
                ),
                if (!_docViewed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠ Open document to enable approval',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onReject,
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
                  onPressed: !_docViewed ? null : widget.onApprove,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String label, bool checked, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            checked
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 12,
            color: checked ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Merge Duplicates Dialog ─────────────────────────────────────────────────────

void _showMergeDuplicatesDialog(
  BuildContext context,
  WidgetRef ref,
  bool isDark,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MergeDuplicatesDialog(isDark: isDark),
  );
}

class _MergeDuplicatesDialog extends ConsumerStatefulWidget {
  const _MergeDuplicatesDialog({required this.isDark});
  final bool isDark;

  @override
  ConsumerState<_MergeDuplicatesDialog> createState() =>
      _MergeDuplicatesDialogState();
}

class _MergeDuplicatesDialogState
    extends ConsumerState<_MergeDuplicatesDialog> {
  int _tabIndex = 0; // 0: Universities, 1: Companies

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF4286F4);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.call_merge_rounded, color: primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merge Duplicates',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Combine duplicate organizations into one',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Tabs
              Row(
                children: [
                  Expanded(
                    child: _buildTab(
                      0,
                      'Universities',
                      Icons.account_balance_rounded,
                      primary,
                    ),
                  ),
                  Expanded(
                    child: _buildTab(
                      1,
                      'Companies',
                      Icons.business_rounded,
                      primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),

              // Content
              Expanded(
                child: _tabIndex == 0
                    ? _buildDuplicatesList(
                        ref.watch(duplicateUniversitiesProvider),
                        'Universities',
                        primary,
                      )
                    : _buildDuplicatesList(
                        ref.watch(duplicateCompaniesProvider),
                        'Companies',
                        primary,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(int index, String label, IconData icon, Color primary) {
    final isSelected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? primary : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuplicatesList(
    AsyncValue<List<dynamic>> asyncValue,
    String type,
    Color primary,
  ) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Colors.green.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No duplicates found!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'The system looks clean.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final group = groups[index] as Map<String, dynamic>;
            final records = (group['records'] as List)
                .cast<Map<String, dynamic>>();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Potential Duplicates (${records.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...records
                      .map(
                        (record) =>
                            _buildRecordCard(record, records, type, primary),
                      )
                      .toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecordCard(
    Map<String, dynamic> record,
    List<Map<String, dynamic>> allRecords,
    String type,
    Color primary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record['name']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: ${record['id']}',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (record['address'] != null &&
              record['address'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                record['address'],
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showMergeDialog(context, record, allRecords, type, primary),
              icon: const Icon(Icons.call_merge_rounded, size: 16),
              label: const Text('Keep this & Merge others into it'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(
    BuildContext context,
    Map<String, dynamic> targetRecord,
    List<Map<String, dynamic>> allRecords,
    String type,
    Color primary,
  ) {
    final sourceRecords = allRecords
        .where((r) => r['id'] != targetRecord['id'])
        .toList();
    if (sourceRecords.isEmpty) return;

    int? selectedSourceId = sourceRecords.first['id'] as int?;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            bool isMerging = false;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.call_merge_rounded, color: primary),
                  const SizedBox(width: 10),
                  const Text('Merge Confirm'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target (Will be kept):',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    targetRecord['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Source (Will be deleted, contents moved to target):',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedSourceId,
                        isExpanded: true,
                        items: sourceRecords
                            .map(
                              (r) => DropdownMenuItem<int>(
                                value: r['id'] as int,
                                child: Text(r['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedSourceId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'This action cannot be undone. All users and data will be migrated.',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isMerging ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isMerging
                      ? null
                      : () async {
                          setDialogState(() => isMerging = true);
                          try {
                            if (type == 'Universities') {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .mergeUniversities(
                                    selectedSourceId!,
                                    targetRecord['id'],
                                  );
                              ref.invalidate(duplicateUniversitiesProvider);
                              ref.invalidate(allUniversitiesProvider);
                            } else {
                              await ref
                                  .read(adminRepositoryProvider)
                                  .mergeCompanies(
                                    selectedSourceId!,
                                    targetRecord['id'],
                                  );
                              ref.invalidate(duplicateCompaniesProvider);
                              ref.invalidate(allCompaniesProvider);
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Merge successful!'),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isMerging = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Merge failed: $e')),
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isMerging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Merge & Delete Source'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
