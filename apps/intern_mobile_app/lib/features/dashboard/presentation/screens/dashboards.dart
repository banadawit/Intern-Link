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
import '../../../plans/domain/entities/weekly_plan.dart';
import '../../../plans/presentation/screens/plans_screen.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../feed/data/feed_repository.dart';
import '../../../app_entry/presentation/providers/app_entry_providers.dart';

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
  bool isDark,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: hasDoc
          ? Colors.blue.withOpacity(0.07)
          : (isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.grey.withOpacity(0.07)),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: hasDoc
            ? Colors.blue.withOpacity(0.2)
            : Colors.grey.withOpacity(0.15),
      ),
    ),
    child: Row(
      children: [
        Icon(
          hasDoc ? Icons.description_rounded : Icons.description_outlined,
          size: 16,
          color: hasDoc ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasDoc
                ? 'Verification document uploaded'
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
                color: Colors.blue,
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
  });

  final dynamic coord;
  final bool hasDoc;
  final String docUrl;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  State<_CoordApprovalActions> createState() => _CoordApprovalActionsState();
}

class _CoordApprovalActionsState extends State<_CoordApprovalActions> {
  bool _docViewed = false;

  Future<void> _openDoc() async {
    final uri = Uri.tryParse(widget.docUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _docViewed = true);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApprove = widget.hasDoc && _docViewed;

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
                color: _docViewed
                    ? Colors.green.withOpacity(0.08)
                    : Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _docViewed
                      ? Colors.green.withOpacity(0.3)
                      : Colors.amber.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _docViewed
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 15,
                    color: _docViewed ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _docViewed
                          ? 'Document verified.'
                          : 'Open the verification document before approving.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _docViewed ? Colors.green : Colors.amber,
                      ),
                    ),
                  ),
                  if (!_docViewed)
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
  });
  final dynamic sup;
  final bool hasDoc;
  final String docUrl;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  State<_SupApprovalActions> createState() => _SupApprovalActionsState();
}

class _SupApprovalActionsState extends State<_SupApprovalActions> {
  bool _docViewed = false;

  Future<void> _openDoc() async {
    final uri = Uri.tryParse(widget.docUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _docViewed = true);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApprove = widget.hasDoc && _docViewed;
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
                color: _docViewed
                    ? Colors.green.withOpacity(0.08)
                    : Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _docViewed
                      ? Colors.green.withOpacity(0.3)
                      : Colors.amber.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _docViewed
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 15,
                    color: _docViewed ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _docViewed
                          ? 'Document verified.'
                          : 'Open the verification document before approving.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _docViewed ? Colors.green : Colors.amber,
                      ),
                    ),
                  ),
                  if (!_docViewed)
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
            TextField(
              controller: techCtrl,
              decoration: const InputDecoration(
                labelText: 'Technical Score (0-100)',
              ),
            ),
            TextField(
              controller: softCtrl,
              decoration: const InputDecoration(
                labelText: 'Soft Skills Score (0-100)',
              ),
            ),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Final Comments'),
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
              await ref
                  .read(supervisorRepositoryProvider)
                  .submitEvaluation(
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

/// Assign FAB — navigates to the Management tab (Assignments sub-tab).
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

class _CoordinatorHodsTab extends ConsumerStatefulWidget {
  const _CoordinatorHodsTab();
  @override
  ConsumerState<_CoordinatorHodsTab> createState() =>
      _CoordinatorHodsTabState();
}

class _CoordinatorHodsTabState extends ConsumerState<_CoordinatorHodsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

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
                            child: FilledButton.icon(
                              onPressed: () => _verify(userId, 'APPROVED'),
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

// ── HOD Detail Screen ─────────────────────────────────────────────────────────
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

// ── Per-department student list ───────────────────────────────────────────────
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

// ── Reports sub-view ──────────────────────────────────────────────────────────
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

// ── Analytics sub-view ────────────────────────────────────────────────────────
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

// ══════════════════════════════════════════════════════════════════════════════
// HOD TABS — fully wired to real backend

// ══════════════════════════════════════════════════════════════════════════════
// HOD TABS — fully wired to real backend
// ══════════════════════════════════════════════════════════════════════════════

// ── Overview ──────────────────────────────────────────────────────────────────
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
          height: 90,
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

// ── Students ──────────────────────────────────────────────────────────────────
class _HodStudentsTab extends ConsumerStatefulWidget {
  const _HodStudentsTab();
  @override
  ConsumerState<_HodStudentsTab> createState() => _HodStudentsTabState();
}

class _HodStudentsTabState extends ConsumerState<_HodStudentsTab> {
  String _filter = 'all';
  bool _selectMode = false;
  final Set<int> _selected = {};
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
                if (hodStatus == 'PENDING')
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
                        child: FilledButton(
                          onPressed: () => _approve(studentId),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00b09b),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  )
                else if (hodStatus == 'APPROVED' &&
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

// ── Send Proposal Bottom Sheet ────────────────────────────────────────────────
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

// ── Proposals ─────────────────────────────────────────────────────────────────
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

// ── Tracking ──────────────────────────────────────────────────────────────────
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

// ── Reports ───────────────────────────────────────────────────────────────────
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

final optimisticOrgsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);

// ── Standalone FAB — lives in the scaffold FAB slot, has its own ref ──────────
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

          // Merge and remove duplicates by ID
          final Map<String, dynamic> uniqueMap = {};
          for (var org in [...optimistic, ...filteredUnis, ...filteredComps]) {
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
    final pendingAsync = ref.watch(pendingCoordinatorsProvider);
    // We merge pending + others using the allUsers data for approved/rejected/suspended
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pendingCoordinatorsProvider);
        ref.invalidate(adminStatsProvider);
      },
      child: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (coordinators) {
          final filtered = coordinators.where((c) {
            final name = (c['user']?['full_name'] ?? '')
                .toString()
                .toLowerCase();
            final email = (c['user']?['email'] ?? '').toString().toLowerCase();
            final status =
                (c['user']?['institution_access_approval'] ?? 'PENDING')
                    .toString();
            final matchesSearch =
                name.contains(_searchQuery.toLowerCase()) ||
                email.contains(_searchQuery.toLowerCase());
            final matchesStatus =
                _statusFilter == 'ALL' || status == _statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No coordinators found',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (ctx, constraints) {
              final hPad = responsiveValue(
                context,
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              );
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
                  itemBuilder: (context, i) =>
                      _buildCoordinatorCard(context, filtered[i], isDark),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 120),
                itemCount: filtered.length,
                itemBuilder: (context, i) =>
                    _buildCoordinatorCard(context, filtered[i], isDark),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSupervisorsTab(bool isDark) {
    final pendingAsync = ref.watch(pendingSupervisorsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pendingSupervisorsProvider);
        ref.invalidate(adminStatsProvider);
      },
      child: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (supervisors) {
          final filtered = supervisors.where((s) {
            final name = (s['user']?['full_name'] ?? '')
                .toString()
                .toLowerCase();
            final email = (s['user']?['email'] ?? '').toString().toLowerCase();
            final status =
                (s['user']?['institution_access_approval'] ?? 'PENDING')
                    .toString();
            final matchesSearch =
                name.contains(_searchQuery.toLowerCase()) ||
                email.contains(_searchQuery.toLowerCase());
            final matchesStatus =
                _statusFilter == 'ALL' || status == _statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.work_rounded,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No supervisors found',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (ctx, constraints) {
              final hPad = responsiveValue(
                context,
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              );
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
                  itemBuilder: (context, i) =>
                      _buildSupervisorCard(context, filtered[i], isDark),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 120),
                itemCount: filtered.length,
                itemBuilder: (context, i) =>
                    _buildSupervisorCard(context, filtered[i], isDark),
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
    final user = coord['user'] as Map<String, dynamic>? ?? {};
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _buildDocumentRow(context, docUrl, hasDoc, isDark),
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
    final user = sup['user'] as Map<String, dynamic>? ?? {};
    final company = sup['company'] as Map<String, dynamic>? ?? {};
    final approval =
        (user['institution_access_approval'] ?? 'PENDING') as String;
    final isPending = approval == 'PENDING';
    final docUrl = user['verification_document']?.toString() ?? '';
    final hasDoc = docUrl.isNotEmpty;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _buildDocumentRow(context, docUrl, hasDoc, isDark),
          ),
          if (isPending)
            _SupApprovalActions(
              sup: sup,
              hasDoc: hasDoc,
              docUrl: docUrl,
              isDark: isDark,
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
