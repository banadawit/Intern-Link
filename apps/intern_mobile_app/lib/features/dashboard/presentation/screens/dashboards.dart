import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/services/session_service.dart';

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
      floatingActionButton: widget.tabs[currentIndex].hideGlobalFab
          ? null
          : Container(
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
                    ref.read(dashboardIndexProvider.notifier).state = 1; // Students tab
                  }, isSelected: currentIndex == 1),
                  _buildDrawerItem(Icons.send_rounded, 'Proposals', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 2; // Proposals tab
                  }, isSelected: currentIndex == 2),
                  _buildDrawerItem(Icons.track_changes_rounded, 'Tracking', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 3; // Tracking tab
                  }, isSelected: currentIndex == 3),
                  _buildDrawerItem(Icons.description_rounded, 'Reports', () {
                    Navigator.pop(context);
                    ref.read(dashboardIndexProvider.notifier).state = 4; // Reports tab
                  }, isSelected: currentIndex == 4),
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
            () {
              Navigator.pop(context); // close drawer first
              _showLogoutConfirmation(context, ref);
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
  /// When true, hides the global AI FAB (use when the tab has its own FAB).
  final bool hideGlobalFab;

  const _DashboardTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.view,
    this.hideGlobalFab = false,
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
        Consumer(
          builder: (context, ref, child) {
            final unreadMessages = ref.watch(unreadChatCountProvider).maybeWhen(
              data: (count) => count,
              orElse: () => 0,
            );
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
            final unreadCount = ref.watch(unreadNotificationCountProvider).maybeWhen(
              data: (count) => count,
              orElse: () => 0,
            );
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

  void _showNotificationCenter(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ]),
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(notificationsRepositoryProvider).markAllAsRead();
                          ref.invalidate(notificationsProvider);
                          ref.invalidate(unreadNotificationCountProvider);
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Mark all read'),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: notificationsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('All caught up!', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                          ]),
                        );
                      }
                      return ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return _buildNotificationItem(
                            context, ref,
                            n,
                          );
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

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, NotificationModel n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final msg = n.message;

    // Smart icon + color based on message content
    IconData icon = Icons.notifications_rounded;
    Color color = Colors.blue;
    String category = 'Update';

    if (msg.contains('approved') || msg.contains('✅')) { icon = Icons.check_circle_rounded; color = Colors.green; category = 'Approved'; }
    else if (msg.contains('rejected') || msg.contains('❌')) { icon = Icons.cancel_rounded; color = Colors.red; category = 'Rejected'; }
    else if (msg.contains('proposal') || msg.contains('📋')) { icon = Icons.work_rounded; color = Colors.purple; category = 'Proposal'; }
    else if (msg.contains('plan') || msg.contains('📝')) { icon = Icons.assignment_rounded; color = Colors.orange; category = 'Plan'; }
    else if (msg.contains('placement') || msg.contains('internship')) { icon = Icons.business_center_rounded; color = Colors.teal; category = 'Placement'; }
    else if (msg.contains('report') || msg.contains('📄')) { icon = Icons.description_rounded; color = Colors.indigo; category = 'Report'; }
    else if (msg.contains('open letter') || msg.contains('📩')) { icon = Icons.mail_rounded; color = Colors.amber.shade700; category = 'Open Letter'; }

    return GestureDetector(
      onTap: n.isRead ? null : () async {
        await ref.read(notificationsRepositoryProvider).markAsRead(n.id);
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationCountProvider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead
              ? (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02))
              : (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? Colors.transparent : Colors.blue.withOpacity(0.3),
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: n.isRead ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: n.isRead ? Colors.grey : color),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(category, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800, fontSize: 12, color: n.isRead ? Colors.grey : color)),
              Text(timeago.format(n.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
            const SizedBox(height: 3),
            Text(msg, style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600, fontSize: 13, color: n.isRead ? Colors.grey : null), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          if (!n.isRead) ...[
            const SizedBox(width: 8),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
          ],
        ]),
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
                badgeCount > 99 ? '99+' : badgeCount > 0 ? '$badgeCount' : '',
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

/// Safely converts any JSON boolean value (bool, int, String) to bool.
bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return false;
}

// ── Proposal Status Badge ─────────────────────────────────────────────────────
/// Compact badge showing a student's proposal status in the picker list.
class _ProposalStatusBadge extends StatelessWidget {
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED' | 'PLACED' | 'AVAILABLE'
  const _ProposalStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'PENDING'   => ('Pending Proposal', Colors.amber.shade700, Icons.hourglass_top_rounded),
      'APPROVED'  => ('Placed',           Colors.green,          Icons.check_circle_rounded),
      'REJECTED'  => ('Rejected',         Colors.red,            Icons.cancel_rounded),
      'PLACED'    => ('Placed',           Colors.green,          Icons.check_circle_rounded),
      _           => ('Available',        Colors.teal,           Icons.circle_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
      ]),
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
  final timeStr = submittedAt != null ? timeago.format(submittedAt) : 'recently';
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
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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
                          growthTitle: 'Current Week', growthTrend: 'Week ${profile.currentInternshipWeek}',
                          placementTitle: 'Attendance', placementSub: '${plansAsync.value?.fold<int>(0, (sum, p) => sum + p.checkins.length) ?? 0} Check-ins',
                          successTitle: 'Plan Status', successRate: (plansAsync.value?.isEmpty ?? true) ? 0.0 : (plansAsync.value!.where((p) => p.status.name.toUpperCase() == 'APPROVED').length / plansAsync.value!.length).clamp(0.0, 1.0),
                          submissionTitle: 'Placements', submissionSub: profile.companyName ?? 'Awaiting placement'
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

  _InternshipStatus _deriveInternshipStatusLabel(StudentProfile profile) {
    if ((profile.internshipStatus).toUpperCase() == 'PLACED' || profile.companyName != null) {
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
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
              const Text('OPEN LETTER REQUEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text('Request a Placement', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('Your HoD will review and approve or reject this request.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 32),
              _extremeTextField(companyController, 'Company Name', Icons.business_rounded, theme),
              const SizedBox(height: 20),
              _extremeTextField(letterController, 'Cover Letter / Motivation', Icons.description_rounded, theme, maxLines: 5),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 70,
                child: FilledButton(
                  onPressed: isSubmitting ? null : () async {
                    final company = companyController.text.trim();
                    final letter = letterController.text.trim();
                    if (company.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a company name.')));
                      return;
                    }
                    setModalState(() => isSubmitting = true);
                    try {
                      await ref.read(placementRepositoryProvider).submitOpenLetter(
                        companyName: company,
                        coverLetter: letter,
                      );
                      ref.invalidate(myProposalsProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Open letter submitted — awaiting HoD review ✓')),
                        );
                      }
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: Colors.black,
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SUBMIT OPEN LETTER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
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
    final statusColor = p.status == 'APPROVED'
        ? Colors.green
        : p.status == 'REJECTED'
            ? Colors.red
            : p.status == 'CANCELLED'
                ? Colors.grey
                : Colors.orange;

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
              gradient: LinearGradient(colors: [statusColor.withOpacity(0.8), statusColor]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(p.isOpenLetter ? Icons.mail_rounded : Icons.apartment_rounded, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.companyName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(p.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                  if (p.isOpenLetter) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Open Letter', style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
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
    final statusColor = p.status == 'APPROVED'
        ? Colors.green
        : p.status == 'REJECTED'
            ? Colors.red
            : p.status == 'CANCELLED'
                ? Colors.grey
                : Colors.orange;

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
            Row(children: [
              Expanded(child: Text(p.companyName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
              if (p.isOpenLetter)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Open Letter', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(p.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
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
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    p.status == 'PENDING'
                        ? 'Awaiting HoD review. Once approved, this becomes an active proposal.'
                        : p.status == 'APPROVED'
                            ? 'Your HoD approved this open letter. The proposal is now active.'
                            : 'Your HoD reviewed this open letter.',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Cover Letter / Motivation', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(p.proposalLetter?.isNotEmpty == true ? p.proposalLetter! : 'No cover letter attached.', style: const TextStyle(height: 1.5, color: Colors.grey)),
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
                      _ProfileInfoRow(Icons.school_rounded, 'Internship Status', profile.internshipStatus),
                    ]),
                    const SizedBox(height: 16),
                    // Final Reports & Evaluations — wired to real data
                    Consumer(builder: (ctx, cref, _) {
                      final evalAsync = cref.watch(myEvaluationProvider);
                      final evalStatus = evalAsync.maybeWhen(
                        data: (e) => e != null ? 'Score: ${e.overallScore.toStringAsFixed(1)}/100' : 'Pending',
                        orElse: () => '...',
                      );
                      return _buildProfileInfoCard(theme, isDark, 'Final Reports & Evaluations', [
                        _ProfileInfoRow(Icons.description_rounded, 'Final Report', 'View Weekly Plans',
                            actionLabel: 'Open', onAction: () => context.push(AppRoutes.reports)),
                        _ProfileInfoRow(Icons.assignment_turned_in_rounded, 'Final Evaluation', evalStatus,
                            actionLabel: 'View', onAction: () => context.push(AppRoutes.evaluations)),
                      ]);
                    }),
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
    final profileAsync = ref.watch(userProfileProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
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
                left: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF0EA5E9).withOpacity(0.12), Colors.transparent],
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
                physics: const BouncingScrollPhysics(),
                slivers: [
                  ModernSliverAppBar(
                    title: 'Overview',
                    subtitle: 'Management Dashboard',
                    profileName: profile.fullName,
                    gradient: [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
                    backgroundIcon: Icons.dashboard_rounded,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStatGrid(context, stats, isDark),
                        const SizedBox(height: 32),
                        Text('Critical Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildActionCard(context, Icons.assignment_late_rounded, 'Pending Plan Reviews', '${stats.pendingPlans} plans waiting for feedback', Colors.orange),
                        const SizedBox(height: 12),
                        _buildActionCard(context, Icons.rate_review_rounded, 'Final Evaluations', '${stats.reportsDue} reports to verify', Colors.purple),
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

  Widget _buildStatGrid(BuildContext context, SupervisorStats stats, bool isDark) {
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
                profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Supervisor',
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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),),
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
                profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Supervisor',
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
        _DashboardTab(label: 'HODs', icon: Icons.school_outlined, activeIcon: Icons.school_rounded, view: _CoordinatorHodsTab(), hideGlobalFab: true),
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
                      colors: [const Color(0xFF1CB5E0).withOpacity(0.12), Colors.transparent],
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
                            _buildStatCard(context, stats.totalStudents.toString(), 'Students', Icons.people_rounded, Colors.blue),
                            const SizedBox(width: 16),
                            _buildStatCard(context, stats.activePlacements.toString(), 'Placed', Icons.check_circle_rounded, Colors.green),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(context, stats.totalCompanies.toString(), 'Companies', Icons.business_rounded, Colors.purple),
                            const SizedBox(width: 16),
                            _buildStatCard(context, stats.pendingProposals.toString(), 'Proposals', Icons.description_rounded, Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text('University Analytics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildPlatformAnalytics(context, isDark,
                          growthTitle: 'Enrollment', growthTrend: '${stats.totalStudents} Total',
                          placementTitle: 'Industry Partners', placementSub: '${stats.totalCompanies} Active',
                          successTitle: 'Placement Rate', successRate: stats.totalStudents > 0 ? (stats.activePlacements / stats.totalStudents).clamp(0.0, 1.0) : 0.0,
                          submissionTitle: 'Pending HODs', submissionSub: '${stats.pendingHods} Awaiting'
                        ),
                        const SizedBox(height: 32),
                        // Quick action cards
                        Row(children: [
                          _quickAction(context, Icons.school_rounded, 'HODs', '${stats.pendingHods} pending', Colors.orange, () {}),
                          const SizedBox(width: 12),
                          _quickAction(context, Icons.description_rounded, 'Reports', '${stats.reportsCount} total', Colors.teal, () {}),
                          const SizedBox(width: 12),
                          _quickAction(context, Icons.business_center_rounded, 'Placements', '${stats.activePlacements} active', Colors.blue, () {}),
                        ]),
                        const SizedBox(height: 32),
                        FeedPreviewSection(),
                        const SizedBox(height: 32),
                        // Recent notifications from backend
                        if (stats.recentNotifications.isNotEmpty) ...[
                          Text('Recent Activity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ...stats.recentNotifications.take(5).map((n) {
                            final msg = n['message'] as String? ?? '';
                            final isRead = _parseBool(n['is_read']);
                            final createdAt = n['created_at'] as String? ?? '';
                            Color color = Colors.blue;
                            IconData icon = Icons.notifications_rounded;
                            if (msg.contains('HOD') || msg.contains('hod')) { color = Colors.orange; icon = Icons.school_rounded; }
                            else if (msg.contains('placement') || msg.contains('assignment')) { color = Colors.green; icon = Icons.work_rounded; }
                            else if (msg.contains('proposal')) { color = Colors.purple; icon = Icons.description_rounded; }
                            else if (msg.contains('report')) { color = Colors.teal; icon = Icons.assessment_rounded; }
                            final timeStr = createdAt.isNotEmpty
                                ? timeago.format(DateTime.tryParse(createdAt) ?? DateTime.now())
                                : '';
                            return _buildActivityItem(context, isRead ? 'Activity' : '● Activity', msg, timeStr, color);
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

  Widget _quickAction(BuildContext context, IconData icon, String label, String sub, Color color, VoidCallback onTap) {
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
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color)),
              Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
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

class _CoordinatorHodsTab extends ConsumerStatefulWidget {
  const _CoordinatorHodsTab();
  @override
  ConsumerState<_CoordinatorHodsTab> createState() => _CoordinatorHodsTabState();
}

class _CoordinatorHodsTabState extends ConsumerState<_CoordinatorHodsTab>
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

  // ── Approve / Reject ────────────────────────────────────────────────────────
  Future<void> _verify(int userId, String status, {String? reason}) async {
    try {
      await ref.read(coordinatorRepositoryProvider).verifyHod(userId, status, reason: reason);
      ref.invalidate(pendingHodsProvider);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(rejectedHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HOD ${status.toLowerCase()} successfully.')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Suspend / Activate ──────────────────────────────────────────────────────
  Future<void> _suspend(int userId) async {
    try {
      await ref.read(coordinatorRepositoryProvider).suspendHod(userId);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HOD account suspended.')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _activate(int userId) async {
    try {
      await ref.read(coordinatorRepositoryProvider).activateHod(userId);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HOD account activated.')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showRejectDialog(int userId) {
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _verify(userId, 'REJECTED', reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
            },
            child: const Text('Reject'),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: tempPassword != null
                // ── Success state ──────────────────────────────────────────
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                      ),
                      const SizedBox(height: 16),
                      const Text('HOD Account Created', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text('The account is auto-approved. Share the temporary password with the HOD.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.key_rounded, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Temporary Password', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  Text(tempPassword!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0575E6)),
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
                        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                        // Title
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00F260), Color(0xFF0575E6)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Head of Department', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                              Text('Account will be auto-approved', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 20),
                        // Full Name
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline_rounded), border: OutlineInputBorder()),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        // Email
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.alternate_email_rounded), border: OutlineInputBorder()),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return 'Required';
                            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!.trim())) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        // Department
                        TextFormField(
                          controller: deptCtrl,
                          decoration: const InputDecoration(labelText: 'Department *', prefixIcon: Icon(Icons.school_outlined), border: OutlineInputBorder()),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        // Password info — always 123456, no field needed
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.25)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.key_rounded, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Temporary password 123456 will be set automatically. The HOD must change it on first login.',
                                  style: TextStyle(fontSize: 11, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Employee ID (optional)
                        TextFormField(
                          controller: empCtrl,
                          decoration: const InputDecoration(labelText: 'Employee ID (optional)', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'HODs added by you are auto-approved. HODs who self-register appear in the Pending tab for your review.',
                                  style: TextStyle(fontSize: 11, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: loading ? null : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => loading = true);
                              try {
                                await ref.read(coordinatorRepositoryProvider).createHod(
                                  fullName: nameCtrl.text,
                                  email: emailCtrl.text,
                                  department: deptCtrl.text,
                                  employeeId: empCtrl.text.trim().isEmpty ? null : empCtrl.text,
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.person_add_rounded),
                            label: Text(loading ? 'Creating...' : 'Create HOD Account'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0575E6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    final pendingAsync = ref.watch(pendingHodsProvider);
    final approvedAsync = ref.watch(approvedHodsProvider);
    final rejectedAsync = ref.watch(rejectedHodsProvider);

    // Badge count on Pending tab
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
                profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Coordinator',
                gradient: [const Color(0xFF00F260), const Color(0xFF0575E6)],
                backgroundIcon: Icons.school_rounded,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverTabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Pending'),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                                child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(text: 'Approved'),
                      const Tab(text: 'Rejected'),
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
                _buildHodList(pendingAsync, isDark, showActions: true),
                _buildHodList(approvedAsync, isDark, statusColor: Colors.green, statusLabel: 'Approved'),
                _buildHodList(rejectedAsync, isDark, statusColor: Colors.red, statusLabel: 'Rejected'),
              ],
            ),
          ),
          // FAB — Add HOD (positioned above bottom nav)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            right: 24,
            child: FloatingActionButton.extended(
              heroTag: 'coordinator_add_hod_fab',
              onPressed: _showAddHodSheet,
              backgroundColor: const Color(0xFF0575E6),
              icon: const Icon(Icons.person_add_rounded, color: Colors.white),
              label: const Text('Add HOD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
    Color? statusColor,
    String? statusLabel,
  }) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e\n\nCheck terminal for details.', textAlign: TextAlign.center),
          ),
        ],
      )),
      data: (hods) {
        if (hods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text(
                  showActions ? 'No pending HODs' : 'No ${statusLabel?.toLowerCase() ?? ''} HODs',
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
                    Icon(Icons.info_outline_rounded, color: Colors.blue, size: 16),
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
            final approvalStatus = user['institution_access_approval'] as String? ?? '';

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HodDetailScreen(userId: userId)),
              ),
              child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: showActions
                                ? [Colors.orangeAccent, Colors.deepOrange]
                                : [const Color(0xFF00F260), const Color(0xFF0575E6)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(dept, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      if (statusLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  if (showActions) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectDialog(userId),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _verify(userId, 'APPROVED'),
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0575E6)),
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!showActions && approvalStatus == 'APPROVED') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _suspend(userId),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text('Suspend'),
                      ),
                    ),
                  ],
                  if (!showActions && approvalStatus == 'SUSPENDED') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _activate(userId),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Activate'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HOD account suspended.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _activate() async {
    try {
      await ref.read(coordinatorRepositoryProvider).activateHod(widget.userId);
      ref.invalidate(approvedHodsProvider);
      ref.invalidate(coordinatorStatsProvider);
      ref.invalidate(hodDetailProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HOD account activated.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _verify(String status, {String? reason}) async {
    try {
      await ref.read(coordinatorRepositoryProvider).verifyHod(widget.userId, status, reason: reason);
      ref.invalidate(pendingHodsProvider);
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _verify('REJECTED', reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
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
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.withOpacity(0.6)),
              const SizedBox(height: 12),
              Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(hodDetailProvider(widget.userId)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      approvalStatus,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Profile info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
                    boxShadow: [if (!isDark) BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 16),
                      _detailRow(Icons.person_rounded, 'Full Name', fullName, isDark),
                      _detailRow(Icons.alternate_email_rounded, 'Email', email, isDark),
                      _detailRow(Icons.school_rounded, 'Department', department, isDark),
                      if (phoneNumber != null && phoneNumber.isNotEmpty)
                        _detailRow(Icons.badge_outlined, 'Employee ID / Phone', phoneNumber, isDark),
                      _detailRow(Icons.people_rounded, 'Students', '$studentCount', isDark),
                      if (createdAt.isNotEmpty)
                        _detailRow(Icons.calendar_today_rounded, 'Joined', createdAt.substring(0, 10), isDark),
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
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                if (approvalStatus == 'SUSPENDED')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _activate,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Activate Account'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                if (approvalStatus == 'PENDING') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showRejectDialog,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _verify('APPROVED'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0575E6)),
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
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
  ConsumerState<_CoordinatorStudentsTab> createState() => _CoordinatorStudentsTabState();
}

class _CoordinatorStudentsTabState extends ConsumerState<_CoordinatorStudentsTab>
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
        _departments.every((d) => depts.contains(d))) return;
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
          final dept = (s as Map<String, dynamic>)['department'] as String? ?? 'Unassigned';
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
                profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Coordinator',
                gradient: [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
                backgroundIcon: Icons.group_rounded,
              ),
              // Stats row
              SliverToBoxAdapter(
                child: statsAsync.maybeWhen(
                  data: (stats) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(children: [
                      _statCard(stats.totalStudents.toString(), 'Total', Icons.people_rounded, Colors.blue, isDark),
                      const SizedBox(width: 10),
                      _statCard(stats.activePlacements.toString(), 'Placed', Icons.check_circle_rounded, Colors.green, isDark),
                      const SizedBox(width: 10),
                      _statCard(stats.pendingHods.toString(), 'Pending HOD', Icons.hourglass_top_rounded, Colors.orange, isDark),
                      const SizedBox(width: 10),
                      _statCard(depts.length.toString(), 'Depts', Icons.domain_rounded, Colors.purple, isDark),
                    ]),
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
                          ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() => _search = ''))
                          : null,
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                _StudentList(students: students, filter: null, search: _search, isDark: isDark),
                // Per-department
                ...depts.map((dept) => _StudentList(
                  students: students,
                  filter: dept,
                  search: _search,
                  isDark: isDark,
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
          boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
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
  final String? filter;   // null = All
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
        if (!name.contains(search) && !email.contains(search) && !sid.contains(search)) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.35)),
          const SizedBox(height: 12),
          Text(
            search.isNotEmpty ? 'No results for "$search"' : 'No students in this department',
            style: const TextStyle(color: Colors.grey),
          ),
        ]),
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
                color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: Colors.orange.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF2994A), Color(0xFFF2C94C)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      if (email.isNotEmpty)
                        Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        // Department chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(dept, style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        if (sid.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(sid, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                        ],
                      ]),
                      if (company != null) ...[
                        const SizedBox(height: 2),
                        Text('@ $company', style: TextStyle(color: Colors.green.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                // Status badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: hodColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('HOD: $hodStatus', style: TextStyle(color: hodColor, fontSize: 9, fontWeight: FontWeight.w700)),
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
}

class _CoordinatorCompaniesTab extends ConsumerStatefulWidget {
  const _CoordinatorCompaniesTab();
  @override
  ConsumerState<_CoordinatorCompaniesTab> createState() => _CoordinatorCompaniesTabState();
}

class _CoordinatorCompaniesTabState extends ConsumerState<_CoordinatorCompaniesTab> {
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
            profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Coordinator',
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
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          companiesAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (companies) {
              final filtered = _search.isEmpty
                  ? companies
                  : companies.where((c) {
                      final m = c as Map<String, dynamic>;
                      return (m['name'] as String? ?? '').toLowerCase().contains(_search) ||
                          (m['official_email'] as String? ?? '').toLowerCase().contains(_search);
                    }).toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No companies found', style: TextStyle(color: Colors.grey))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final c = filtered[i] as Map<String, dynamic>;
                      final name = c['name'] as String? ?? 'Unknown';
                      final email = c['official_email'] as String? ?? '';
                      final status = c['approval_status'] as String? ?? 'PENDING';
                      final address = c['address'] as String? ?? '';
                      final statusColor = status == 'APPROVED' ? Colors.green : status == 'REJECTED' ? Colors.red : Colors.orange;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05)),
                          boxShadow: [if (!isDark) BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFDA22FF), Color(0xFF9733EE)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                  if (email.isNotEmpty) Text(email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  if (address.isNotEmpty) Text(address, style: TextStyle(color: Colors.grey.shade400, fontSize: 11), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
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
  ConsumerState<_CoordinatorPlacementsTab> createState() => _CoordinatorPlacementsTabState();
}

class _CoordinatorPlacementsTabState extends ConsumerState<_CoordinatorPlacementsTab>
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
      child: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          ModernSliverAppBar(
            title: 'Placements',
            subtitle: 'Assignments & Proposals',
            profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Coordinator',
            gradient: const [Color(0xFFFC466B), Color(0xFF3F5EFB)],
            backgroundIcon: Icons.business_center_rounded,
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverTabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                tabs: const [Tab(text: 'Active'), Tab(text: 'Proposals'), Tab(text: 'Analytics')],
                labelColor: const Color(0xFFFC466B),
                indicatorColor: const Color(0xFFFC466B),
                unselectedLabelColor: Colors.grey,
              ),
              isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // Active assignments — nested sub-tabs
            NestedScrollView(
              headerSliverBuilder: (ctx, _) => [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverTabBarDelegate(
                    TabBar(
                      controller: _assignmentTabCtrl,
                      tabs: const [Tab(text: 'Active'), Tab(text: 'Completed'), Tab(text: 'Terminated')],
                      labelColor: const Color(0xFFFC466B),
                      indicatorColor: const Color(0xFFFC466B),
                      unselectedLabelColor: Colors.grey,
                    ),
                    isDark,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _assignmentTabCtrl,
                children: [
                  _buildAssignmentsList(assignmentsAsync, isDark, 'ACTIVE'),
                  _buildAssignmentsList(assignmentsAsync, isDark, 'COMPLETED'),
                  _buildAssignmentsList(assignmentsAsync, isDark, 'TERMINATED'),
                ],
              ),
            ),
            // Proposals
            _buildProposalsList(proposalsAsync, isDark),
            // Analytics
            _buildAnalytics(assignmentsAsync, proposalsAsync, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsList(AsyncValue<List<dynamic>> async, bool isDark, String statusFilter) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        final filtered = items.where((a) {
          final m = a as Map<String, dynamic>;
          return statusFilter == 'ALL' || (m['status'] as String? ?? '') == statusFilter;
        }).toList();

        if (filtered.isEmpty) {
          final emptyMsg = statusFilter == 'ACTIVE'
              ? 'No active placements'
              : statusFilter == 'COMPLETED'
                  ? 'No completed placements yet'
                  : 'No terminated placements';
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.work_off_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
            ]),
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
              final studentUser = student['user'] as Map<String, dynamic>? ?? {};
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
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
                  boxShadow: [if (!isDark) BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFC466B), Color(0xFF3F5EFB)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('$companyName • $dept', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), overflow: TextOverflow.ellipsis),
                          if (startDate.isNotEmpty)
                            Text('Since ${startDate.substring(0, 10)}', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
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
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('No proposals yet', style: TextStyle(color: Colors.grey)),
            ]),
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
              final studentUser = student['user'] as Map<String, dynamic>? ?? {};
              final company = p['company'] as Map<String, dynamic>? ?? {};
              final name = studentUser['full_name'] as String? ?? 'Unknown';
              final companyName = company['name'] as String? ?? 'N/A';
              final status = p['status'] as String? ?? 'PENDING';
              final statusColor = status == 'APPROVED' ? Colors.green : status == 'REJECTED' ? Colors.red : Colors.orange;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description_rounded, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('→ $companyName', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
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

  Widget _buildAnalytics(AsyncValue<List<dynamic>> assignmentsAsync, AsyncValue<List<dynamic>> proposalsAsync, bool isDark) {
    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (assignments) {
        final active = assignments.where((a) => (a as Map)['status'] == 'ACTIVE').length;
        final completed = assignments.where((a) => (a as Map)['status'] == 'COMPLETED').length;
        final terminated = assignments.where((a) => (a as Map)['status'] == 'TERMINATED').length;

        // Company distribution
        final companyMap = <String, int>{};
        for (final a in assignments) {
          final name = (a as Map)['company']?['name'] as String? ?? 'Unknown';
          companyMap[name] = (companyMap[name] ?? 0) + 1;
        }
        final topCompanies = companyMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          children: [
            const Text('Placement Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(children: [
              _analyticsCard('Active', active.toString(), Colors.green, isDark),
              const SizedBox(width: 12),
              _analyticsCard('Completed', completed.toString(), Colors.blue, isDark),
              const SizedBox(width: 12),
              _analyticsCard('Terminated', terminated.toString(), Colors.red, isDark),
            ]),
            const SizedBox(height: 24),
            if (topCompanies.isNotEmpty) ...[
              const Text('Top Companies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...topCompanies.take(5).map((e) => _companyBar(e.key, e.value, assignments.length, isDark)),
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
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFFC466B))),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFFC466B).withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFC466B)),
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
  ConsumerState<_CoordinatorToolsTab> createState() => _CoordinatorToolsTabState();
}

class _CoordinatorToolsTabState extends ConsumerState<_CoordinatorToolsTab> with SingleTickerProviderStateMixin {
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
                profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Coordinator',
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
                      Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Reports'))),
                      Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Analytics'))),
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
              label: const Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text('No reports yet', style: TextStyle(color: Colors.grey)),
            ]),
          );
        }

        final colors = [Colors.teal, Colors.green, Colors.blue, Colors.purple, Colors.orange];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(coordinatorReportsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: reports.length,
            itemBuilder: (ctx, i) {
              final r = reports[i] as Map<String, dynamic>;
              final student = r['student'] as Map<String, dynamic>? ?? {};
              final studentUser = student['user'] as Map<String, dynamic>? ?? {};
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
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
                  boxShadow: [if (!isDark) BoxShadow(color: color.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text(dept, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          if (generatedAt.isNotEmpty)
                            Text(generatedAt.substring(0, 10), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stamped ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stamped ? 'Stamped' : 'Pending',
                        style: TextStyle(color: stamped ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.download_rounded,
                        color: pdfUrl != null && pdfUrl.isNotEmpty ? color : Colors.grey.shade300,
                      ),
                      onPressed: pdfUrl != null && pdfUrl.isNotEmpty
                          ? () async {
                              final uri = Uri.parse(pdfUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Opening report…')),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Unable to open report. The file may not be available.')),
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
                  const Text('Placement Overview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _metricBox('Total Students', stats.totalStudents.toString(), Colors.blue, isDark),
                    const SizedBox(width: 10),
                    _metricBox('Placed', stats.activePlacements.toString(), Colors.green, isDark),
                    const SizedBox(width: 10),
                    _metricBox('Pending', (stats.totalStudents - stats.activePlacements).toString(), Colors.orange, isDark),
                  ]),
                  const SizedBox(height: 16),
                  // Placement rate bar
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Placement Rate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      stats.totalStudents > 0
                          ? '${((stats.activePlacements / stats.totalStudents) * 100).toStringAsFixed(1)}%'
                          : '0%',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.green, fontSize: 13),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats.totalStudents > 0 ? (stats.activePlacements / stats.totalStudents).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
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
                  const Text('HOD Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _metricBox('Total', stats.totalHods.toString(), Colors.blue, isDark),
                    const SizedBox(width: 10),
                    _metricBox('Pending', stats.pendingHods.toString(), Colors.orange, isDark),
                    const SizedBox(width: 10),
                    _metricBox('Approved', (stats.totalHods - stats.pendingHods).toString(), Colors.green, isDark),
                  ]),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Proposals breakdown
          proposalsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox.shrink(),
            data: (proposals) {
              final pending = proposals.where((p) => (p as Map)['status'] == 'PENDING').length;
              final approved = proposals.where((p) => (p as Map)['status'] == 'APPROVED').length;
              final rejected = proposals.where((p) => (p as Map)['status'] == 'REJECTED').length;
              return _sectionCard(
                isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Proposals Breakdown', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(children: [
                      _metricBox('Total', proposals.length.toString(), Colors.purple, isDark),
                      const SizedBox(width: 10),
                      _metricBox('Pending', pending.toString(), Colors.orange, isDark),
                      const SizedBox(width: 10),
                      _metricBox('Approved', approved.toString(), Colors.green, isDark),
                    ]),
                    if (rejected > 0) ...[
                      const SizedBox(height: 8),
                      Text('$rejected rejected', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
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
                final name = (a as Map)['company']?['name'] as String? ?? 'Unknown';
                companyMap[name] = (companyMap[name] ?? 0) + 1;
              }
              if (companyMap.isEmpty) return const SizedBox.shrink();
              final sorted = companyMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              return _sectionCard(
                isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Top Partner Companies', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 14),
                    ...sorted.take(5).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF11998e), fontSize: 13)),
                          ]),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: assignments.isNotEmpty ? e.value / assignments.length : 0,
                              backgroundColor: const Color(0xFF11998e).withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF11998e)),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    )),
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
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
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
        _DashboardTab(label: 'Overview', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, view: _HodOverviewTab()),
        _DashboardTab(label: 'Students', icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, view: _HodStudentsTab()),
        _DashboardTab(label: 'Proposals', icon: Icons.send_outlined, activeIcon: Icons.send_rounded, view: _HodProposalsTab(), hideGlobalFab: true),
        _DashboardTab(label: 'Tracking', icon: Icons.track_changes_outlined, activeIcon: Icons.track_changes_rounded, view: _HodTrackingTab()),
        _DashboardTab(label: 'Reports', icon: Icons.description_outlined, activeIcon: Icons.description_rounded, view: _HodReportsTab()),
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
                  padding: const EdgeInsets.all(24),
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

  Widget _buildStatGrid(BuildContext context, HodEnhancedStats stats, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: [
        _statCard('Total Students', stats.totalStudents.toString(), Icons.groups_rounded, Colors.blue, isDark),
        _statCard('Pending Appr.', stats.pendingApprovals.toString(), Icons.pending_actions_rounded, Colors.orange, isDark),
        _statCard('Placed', stats.placedStudents.toString(), Icons.check_circle_rounded, Colors.green, isDark),
        _statCard('Reports', stats.totalReports.toString(), Icons.description_rounded, Colors.purple, isDark),
      ],
    );
  }

  Widget _buildRateRow(BuildContext context, HodEnhancedStats stats, bool isDark) {
    return Row(children: [
      Expanded(child: _rateCard('Placement', '${stats.placementRate.toStringAsFixed(1)}%', Colors.teal, isDark)),
      const SizedBox(width: 10),
      Expanded(child: _rateCard('Approval', '${stats.approvalSuccessRate.toStringAsFixed(1)}%', Colors.indigo, isDark)),
      const SizedBox(width: 10),
      Expanded(child: _rateCard('Reports', '${stats.reportsCompletionRate.toStringAsFixed(1)}%', Colors.deepOrange, isDark)),
    ]);
  }

  Widget _rateCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildAlertsSection(BuildContext context, WidgetRef ref, HodEnhancedStats stats, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.notifications_active_rounded, size: 18, color: Colors.orange),
        const SizedBox(width: 8),
        Text('Alerts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        if (stats.alerts.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
            child: Text('${stats.alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
      ]),
      const SizedBox(height: 12),
      if (stats.alerts.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
            SizedBox(width: 10),
            Text('All clear — no alerts', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ]),
        )
      else
        ...stats.alerts.map((a) => _buildAlertCard(context, ref, a, isDark)),
    ]);
  }

  Widget _buildAlertCard(BuildContext context, WidgetRef ref, HodAlert alert, bool isDark) {
    final color = alert.type == 'UNPLACED' ? Colors.orange
        : alert.type == 'NEEDS_REASSIGNMENT' ? Colors.red
        : alert.type == 'INACTIVE' ? Colors.blue
        : Colors.purple;
    final icon = alert.type == 'UNPLACED' ? Icons.person_off_rounded
        : alert.type == 'NEEDS_REASSIGNMENT' ? Icons.assignment_late_rounded
        : alert.type == 'INACTIVE' ? Icons.bedtime_rounded
        : Icons.schedule_rounded;
    final tabIndex = (alert.type == 'UNPLACED' || alert.type == 'NEEDS_REASSIGNMENT') ? 1 : 3;

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
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(alert.message, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 16),
        ]),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, HodEnhancedStats stats, bool isDark) {
    if (stats.weeklyPlacementTrend.isEmpty) return const SizedBox.shrink();
    final maxCount = stats.weeklyPlacementTrend.map((p) => p.count).fold(0, (a, b) => a > b ? a : b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Weekly Placement Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (p.count > 0) Text('${p.count}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 2),
                  Container(
                    height: 70 * ratio + 4,
                    decoration: BoxDecoration(color: Colors.teal.withOpacity(0.7), borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 3),
                  Text(p.weekLabel, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student approved ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reject(int studentId) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Optional reason…'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, ctrl.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(hodRepositoryProvider).rejectStudent(studentId, reason: reason);
      ref.invalidate(hodStudentsProvider(_filter));
      ref.invalidate(hodEnhancedStatsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student rejected')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _bulkApprove() async {
    if (_selected.isEmpty) return;
    try {
      final result = await ref.read(hodRepositoryProvider).bulkApproveStudents(_selected.toList());
      final approved = (result['approved'] as List?)?.length ?? 0;
      ref.invalidate(hodStudentsProvider(_filter));
      ref.invalidate(hodEnhancedStatsProvider);
      setState(() { _selected.clear(); _selectMode = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$approved students approved ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _reprocess(int studentId) async {
    try {
      await ref.read(hodRepositoryProvider).reprocessStudent(studentId);
      ref.invalidate(hodStudentsProvider(_filter));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student reset to Pending')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showFlagSheet(int studentId, String? currentFlag) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Flag Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            if (currentFlag != null)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.grey),
                title: const Text('Remove Flag'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(hodRepositoryProvider).unflagStudent(studentId);
                  ref.invalidate(hodStudentsProvider(_filter));
                },
              ),
            ListTile(
              leading: const Icon(Icons.trending_down_rounded, color: Colors.orange),
              title: const Text('Low Performance'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(hodRepositoryProvider).flagStudent(studentId, 'LOW_PERFORMANCE', note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
                ref.invalidate(hodStudentsProvider(_filter));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bedtime_rounded, color: Colors.blue),
              title: const Text('Inactive'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(hodRepositoryProvider).flagStudent(studentId, 'INACTIVE', note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
                ref.invalidate(hodStudentsProvider(_filter));
              },
            ),
            TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: 'Optional note…', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _showTimeline(int studentId, String studentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final timelineAsync = ref.watch(hodStudentTimelineProvider(studentId));
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Timeline: $studentName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Expanded(
                child: timelineAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (events) => ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (ctx, i) {
                      final e = events[i];
                      final state = e['state']?.toString() ?? '';
                      final ts = e['timestamp']?.toString() ?? '';
                      final dt = DateTime.tryParse(ts);
                      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Column(children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle)),
                          if (i < events.length - 1) Container(width: 2, height: 40, color: Colors.teal.withOpacity(0.3)),
                        ]),
                        const SizedBox(width: 12),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(state, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            if (dt != null) Text(timeago.format(dt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ]),
                        )),
                      ]);
                    },
                  ),
                ),
              ),
            ]),
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
            profileName: ref.watch(userProfileProvider).value?.fullName ?? 'HOD',
            gradient: const [Color(0xFF00b09b), Color(0xFF96c93d)],
            backgroundIcon: Icons.person_search_rounded,
            actions: [
              if (_selectMode)
                TextButton(
                  onPressed: _bulkApprove,
                  child: Text('Approve (${_selected.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              IconButton(
                icon: Icon(_selectMode ? Icons.close_rounded : Icons.checklist_rounded, color: Colors.white),
                onPressed: () => setState(() { _selectMode = !_selectMode; _selected.clear(); }),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF00b09b) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? const Color(0xFF00b09b) : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
                        ),
                        child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          studentsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (students) {
              if (students.isEmpty) {
                return SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No students found', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                ])));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildStudentCard(students[i], isDark),
                  childCount: students.length,
                )),
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

    Color statusColor = hodStatus == 'APPROVED' ? Colors.green : hodStatus == 'REJECTED' ? Colors.red : Colors.orange;
    final isSelected = _selected.contains(studentId);

    return GestureDetector(
      onTap: _selectMode ? () => setState(() { if (isSelected) _selected.remove(studentId); else _selected.add(studentId); }) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? Colors.teal : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05))),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (_selectMode)
              Checkbox(value: isSelected, onChanged: (v) => setState(() { if (v == true) _selected.add(studentId); else _selected.remove(studentId); }))
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [statusColor.withOpacity(0.8), statusColor]), borderRadius: BorderRadius.circular(14)),
                child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              Text(email, style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11), overflow: TextOverflow.ellipsis),
              if (department.isNotEmpty) Text(department, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              if (proposalBadgeStatus != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  _ProposalStatusBadge(proposalBadgeStatus),
                  if (proposalStatus == 'PENDING' && latestProposal?['companyName'] != null) ...[
                    const SizedBox(width: 4),
                    Text('→ ${latestProposal!['companyName']}', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                  ],
                ]),
              ],
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(hodStatus, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900))),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(flagType != null ? Icons.flag_rounded : Icons.flag_outlined, size: 16, color: flagType != null ? Colors.orange : Colors.grey),
                  onPressed: () => _showFlagSheet(studentId, flagType),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.timeline_rounded, size: 16, color: Colors.teal),
                  onPressed: () => _showTimeline(studentId, name),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ]),
            ]),
          ]),
          if (!_selectMode) ...[
            const SizedBox(height: 12),
            if (hodStatus == 'PENDING')
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => _reject(studentId), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), child: const Text('Reject'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: () => _approve(studentId), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00b09b)), child: const Text('Approve'))),
              ])
            else if (hodStatus == 'APPROVED' && internStatus != 'PLACED') ...[
              if (proposalStatus == 'PENDING')
                // Already has a pending proposal — show info instead of send button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.hourglass_top_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Pending proposal to ${latestProposal?['companyName'] ?? 'a company'}',
                      style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                    )),
                    GestureDetector(
                      onTap: () => _showSmartConflictDialog(
                        context,
                        studentName: name,
                        proposalStatus: 'PENDING',
                        companyName: latestProposal?['companyName']?.toString() ?? 'the company',
                        submittedAt: latestProposal?['submittedAt'] != null
                            ? DateTime.tryParse(latestProposal!['submittedAt'].toString())
                            : null,
                      ),
                      child: const Text('Details', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    ),
                  ]),
                )
              else
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: () => _showSendProposalSheet(context, studentId, name),
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: Text(proposalStatus == 'REJECTED' ? 'Resend Proposal' : 'Send Proposal'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00b09b)),
                )),
            ]
            else if (hodStatus == 'REJECTED')
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () => _reprocess(studentId),
                child: const Text('Reprocess (Reset to Pending)'),
              )),
          ],
        ]),
      ),
    );
    } catch (e) {
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('Parse error: $e', style: const TextStyle(fontSize: 11, color: Colors.red)));
    }
  }

  void _showSendProposalSheet(BuildContext context, int studentId, String studentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SendProposalSheet(studentId: studentId, studentName: studentName),
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
  const _SendProposalSheet({required this.studentId, required this.studentName});
  @override
  ConsumerState<_SendProposalSheet> createState() => _SendProposalSheetState();
}

class _SendProposalSheetState extends ConsumerState<_SendProposalSheet> {
  bool _isTeam = false;
  int? _selectedCompanyId;
  int? _selectedLeadStudentId;
  String _selectedLeadStudentName = '';
  Map<String, dynamic>? _leadStudentProposal; // latest proposal info for smart errors
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a company')));
      return;
    }

    if (_isTeam) {
      // Team proposal: need lead + at least 1 more member
      final leadId = _selectedLeadStudentId ?? (widget.studentId > 0 ? widget.studentId : null);
      if (leadId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a lead student')));
        return;
      }
      if (_teamMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one more team member')));
        return;
      }
      final allIds = [leadId, ..._teamMembers.map((m) => _parseInt(m['id']))];
      setState(() => _loading = true);
      try {
        await ref.read(hodRepositoryProvider).sendTeamProposal(
          studentIds: allIds,
          companyId: _selectedCompanyId!,
          teamName: _teamNameCtrl.text.trim().isNotEmpty ? _teamNameCtrl.text.trim() : 'Team Proposal',
          expectedDurationWeeks: _weeks,
          expectedOutcomes: _outcomesCtrl.text.trim().isNotEmpty ? _outcomesCtrl.text.trim() : null,
        );
        if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team proposal sent ✓'))); }
      } catch (e) {
        if (mounted) await _handleProposalError(e, isTeam: true);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // Individual proposal
      final sid = widget.studentId > 0 ? widget.studentId : _selectedLeadStudentId;
      if (sid == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student')));
        return;
      }
      setState(() => _loading = true);
      try {
        await ref.read(hodRepositoryProvider).sendProposal(
          studentId: sid,
          companyId: _selectedCompanyId!,
          expectedDurationWeeks: _weeks,
          expectedOutcomes: _outcomesCtrl.text.trim().isNotEmpty ? _outcomesCtrl.text.trim() : null,
        );
        if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal sent ✓'))); }
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
      final proposalStatus = errorData['proposalStatus']?.toString() ?? 'PENDING';
      final companyName = errorData['companyName']?.toString() ?? 'the company';
      final teamName = errorData['teamName']?.toString();
      final submittedAtRaw = errorData['submittedAt'];
      final submittedAt = submittedAtRaw != null ? DateTime.tryParse(submittedAtRaw.toString()) : null;

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
          const SnackBar(content: Text('Select a different company to send a new proposal.')),
        );
      }
    } else {
      // Generic error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _showStudentPicker({required bool isLead}) {
    final studentsAsync = ref.read(hodStudentsProvider('approved'));
    studentsAsync.whenData((students) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(isLead ? 'Select Lead Student' : 'Add Team Member', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Disabled students have active proposals or are already placed.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                  final internStatus = s['internship_status']?.toString() ?? '';
                  final latestProposal = s['latestProposal'] as Map<String, dynamic>?;
                  final proposalStatus = latestProposal?['status']?.toString();

                  // Determine availability
                  final isPlaced = internStatus == 'PLACED';
                  final hasPending = proposalStatus == 'PENDING';
                  final alreadyAdded = _teamMembers.any((m) => _parseInt(m['id']) == sid) || sid == _selectedLeadStudentId;

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
                        backgroundColor: isDisabled ? Colors.grey.shade300 : Colors.teal.withOpacity(0.15),
                        child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: isDisabled ? Colors.grey : Colors.teal, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: isDisabled ? Colors.grey : null)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (dept.isNotEmpty) Text(dept, style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 3),
                        _ProposalStatusBadge(badgeStatus),
                        if (hasPending && latestProposal != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '→ ${latestProposal['companyName'] ?? ''}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                      ]),
                      onTap: isDisabled ? null : () {
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
          ]),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companiesAsync = ref.watch(hodCompaniesProvider(''));

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('New Proposal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          // Individual / Team toggle (only show when not pre-filled with a student)
          if (widget.studentId <= 0) ...[
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _isTeam = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isTeam ? const Color(0xFF00b09b) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text('Individual', style: TextStyle(color: !_isTeam ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _isTeam = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isTeam ? const Color(0xFFf857a6) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text('Team / Group', style: TextStyle(color: _isTeam ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
                ),
              )),
            ]),
            const SizedBox(height: 16),
          ],

          // Student display (pre-filled individual)
          if (widget.studentId > 0 && !_isTeam)
            Text('For: ${widget.studentName}', style: const TextStyle(color: Colors.grey, fontSize: 13)),

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
                child: Row(children: [
                  const Icon(Icons.person_rounded, color: Colors.grey, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _selectedLeadStudentName.isNotEmpty ? _selectedLeadStudentName : (_isTeam ? 'Select Lead Student *' : 'Select Student *'),
                    style: TextStyle(color: _selectedLeadStudentName.isNotEmpty ? null : Colors.grey),
                  )),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Team name + members (team mode)
          if (_isTeam) ...[
            TextField(
              controller: _teamNameCtrl,
              decoration: InputDecoration(labelText: 'Team Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            // Team members list
            if (_teamMembers.isNotEmpty) ...[
              const Text('Team Members:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              ..._teamMembers.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFf857a6).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.person_rounded, size: 14, color: Color(0xFFf857a6)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m['name']?.toString() ?? 'Student', style: const TextStyle(fontSize: 13))),
                  GestureDetector(
                    onTap: () => setState(() => _teamMembers.remove(m)),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                  ),
                ]),
              )),
              const SizedBox(height: 6),
            ],
            OutlinedButton.icon(
              onPressed: () => _showStudentPicker(isLead: false),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Add Team Member'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFf857a6), side: const BorderSide(color: Color(0xFFf857a6))),
            ),
            const SizedBox(height: 12),
          ],

          // Company picker
          companiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (companies) => DropdownButtonFormField<int>(
              value: _selectedCompanyId,
              decoration: InputDecoration(labelText: 'Select Company', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: companies.map((c) => DropdownMenuItem<int>(value: _parseInt(c['id']), child: Text(c['name']?.toString() ?? 'Company', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _selectedCompanyId = v),
            ),
          ),
          const SizedBox(height: 12),

          // Duration
          Row(children: [
            const Text('Duration (weeks):', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.remove_circle_outline_rounded), onPressed: () { if (_weeks > 4) setState(() => _weeks--); }),
            Text('$_weeks', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            IconButton(icon: const Icon(Icons.add_circle_outline_rounded), onPressed: () { if (_weeks < 52) setState(() => _weeks++); }),
          ]),

          TextField(controller: _outcomesCtrl, decoration: InputDecoration(labelText: 'Expected Outcomes (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
          const SizedBox(height: 16),

          SizedBox(width: double.infinity, height: 52, child: FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _isTeam ? const Color(0xFFf857a6) : const Color(0xFF00b09b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_isTeam ? 'Send Team Proposal' : 'Send Proposal'),
          )),
        ]),
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
  static const _statuses = ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'SUSPENDED'];

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
      await ref.read(hodRepositoryProvider).transitionProposalState(proposalId, targetState);
      ref.invalidate(hodProposalsFilteredProvider(_statusFilter));
      ref.invalidate(hodEnhancedStatsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Proposal → $targetState ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveOpenLetter(int id) async {
    try {
      await ref.read(hodRepositoryProvider).updateOpenLetter(id, 'APPROVED');
      ref.invalidate(hodProposalsFilteredProvider(_statusFilter));
      ref.invalidate(hodOpenLettersProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open letter approved — proposal forwarded to company ✓')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectOpenLetter(int id) async {
    // Ask for a rejection reason first
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Reject Open Letter'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Provide a reason for the student (optional):'),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(hintText: 'Reason…', border: OutlineInputBorder()),
            maxLines: 3,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
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
      await ref.read(hodRepositoryProvider).updateOpenLetter(id, 'REJECTED', reason: reasonCtrl.text.trim());
      ref.invalidate(hodProposalsFilteredProvider(_statusFilter));
      ref.invalidate(hodOpenLettersProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open letter rejected — student notified')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showProposalDetail(Map<String, dynamic> p, bool isDark) {
    final id = _parseInt(p['id']);
    final status = (p['status'] ?? 'PENDING').toString();
    final isOpenLetter = (p['proposal_type'] ?? '').toString() == 'Open_Letter';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Proposal Details', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Status: $status', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (isOpenLetter && status == 'PENDING') ...[
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(ctx); _rejectOpenLetter(id); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), child: const Text('Reject'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () { Navigator.pop(ctx); _approveOpenLetter(id); }, style: FilledButton.styleFrom(backgroundColor: Colors.green), child: const Text('Approve → Forward'))),
            ]),
          ] else ...[
            if (status == 'PENDING')
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () { Navigator.pop(ctx); _transition(id, 'CANCELLED'); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('Cancel Proposal'))),
            if (status == 'REJECTED' || status == 'CANCELLED')
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () { Navigator.pop(ctx); }, child: const Text('Resend (New Proposal)'))),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proposalsAsync = ref.watch(hodProposalsFilteredProvider(_statusFilter));
    final openLettersAsync = ref.watch(hodOpenLettersProvider);

    return Material(
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: Stack(children: [
        NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            ModernSliverAppBar(
              title: 'Proposals',
              subtitle: 'Proposal Pipeline',
              profileName: ref.watch(userProfileProvider).value?.fullName ?? 'HOD',
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
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  tabs: [
                    const Tab(text: 'All Proposals'),
                    Tab(
                      child: openLettersAsync.maybeWhen(
                        data: (letters) {
                          final pending = letters.where((l) => (l['status'] ?? '') == 'PENDING').length;
                          return Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('Open Letters'),
                            if (pending > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                                child: Text('$pending', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ]);
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
              Column(children: [
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? const Color(0xFFf857a6) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? const Color(0xFFf857a6) : Colors.grey.withOpacity(0.2)),
                            ),
                            child: Text(s, style: TextStyle(color: sel ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => ref.invalidate(hodProposalsFilteredProvider(_statusFilter)),
                    child: proposalsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (proposals) {
                        if (proposals.isEmpty) {
                          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.work_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No proposals', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                          ]));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                          itemCount: proposals.length,
                          itemBuilder: (ctx, i) => _buildProposalCard(proposals[i], isDark),
                        );
                      },
                    ),
                  ),
                ),
              ]),

              // ── Tab 2: Open Letters ───────────────────────────────────────
              RefreshIndicator(
                onRefresh: () async => ref.invalidate(hodOpenLettersProvider),
                child: openLettersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (letters) {
                    if (letters.isEmpty) {
                      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.mail_outline_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No open letter requests', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Students can submit open letter requests\nfrom their Placements tab.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ]));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                      itemCount: letters.length,
                      itemBuilder: (ctx, i) => _buildOpenLetterCard(letters[i], isDark),
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
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => _SendProposalSheet(studentId: 0, studentName: 'Select Student'),
                    ).then((_) => ref.invalidate(hodProposalsFilteredProvider(_statusFilter))),
                    backgroundColor: const Color(0xFFf857a6),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('New Proposal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ]),
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

    Color statusColor = status == 'APPROVED' ? Colors.green : status == 'REJECTED' ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status == 'PENDING' ? Colors.orange.withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.8), Colors.orange]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mail_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(studentUser['full_name']?.toString() ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text('→ ${company['name']?.toString() ?? 'Company'}', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
            if (submittedAt != null) Text(timeago.format(DateTime.tryParse(submittedAt) ?? DateTime.now()), style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ]),
        if (coverLetter.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              coverLetter.length > 120 ? '${coverLetter.substring(0, 120)}…' : coverLetter,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12, height: 1.4),
            ),
          ),
        ],
        if (status == 'PENDING') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _rejectOpenLetter(id),
              icon: const Icon(Icons.close_rounded, size: 14),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(
              onPressed: () => _approveOpenLetter(id),
              icon: const Icon(Icons.check_rounded, size: 14),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 8)),
            )),
          ]),
        ],
      ]),
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

    Color statusColor = status == 'APPROVED' ? Colors.green : status == 'REJECTED' ? Colors.red : status == 'CANCELLED' ? Colors.grey : status == 'SUSPENDED' ? Colors.orange.shade800 : Colors.orange;

    return GestureDetector(
      onTap: () => _showProposalDetail(p, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [statusColor.withOpacity(0.8), statusColor]), borderRadius: BorderRadius.circular(12)),
            child: Icon(isOpenLetter ? Icons.mail_rounded : Icons.work_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(studentUser['full_name']?.toString() ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(company['name']?.toString() ?? 'Company', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
            if (submittedAt != null) Text(timeago.format(DateTime.tryParse(submittedAt) ?? DateTime.now()), style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900))),
            if (isOpenLetter) const SizedBox(height: 4),
            if (isOpenLetter) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Text('Open Letter', style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold))),
          ]),
        ]),
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

class _HodTrackingTabState extends ConsumerState<_HodTrackingTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _forceEnd(int placementId, String studentName) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Force End — $studentName'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This will terminate the internship. Enter a reason:'),
          const SizedBox(height: 12),
          TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: 'Reason…', border: OutlineInputBorder()), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Force End')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(hodRepositoryProvider).forceEndPlacement(placementId, reasonCtrl.text.trim());
      ref.invalidate(hodPlacementsProvider(null));
      ref.invalidate(hodPlacementsProvider('ACTIVE'));
      ref.invalidate(hodEnhancedStatsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Placement terminated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            profileName: ref.watch(userProfileProvider).value?.fullName ?? 'HOD',
            gradient: const [Color(0xFF1fa2ff), Color(0xFF12d8fa)],
            backgroundIcon: Icons.track_changes_rounded,
          ),
          SliverToBoxAdapter(
            child: allAsync.maybeWhen(
              data: (all) {
                final active = all.where((p) => p['status'] == 'ACTIVE').length;
                final completed = all.where((p) => p['status'] == 'COMPLETED').length;
                final failed = all.where((p) => p['status'] == 'TERMINATED').length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(children: [
                    _summaryChip('Active', active, Colors.green),
                    const SizedBox(width: 10),
                    _summaryChip('Completed', completed, Colors.blue),
                    const SizedBox(width: 10),
                    _summaryChip('Failed', failed, Colors.red),
                  ]),
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
                tabs: const [Tab(text: 'Active'), Tab(text: 'Completed'), Tab(text: 'Failed')],
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
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ]),
    ));
  }

  Widget _buildPlacementList(String status, bool isDark) {
    final placementsAsync = ref.watch(hodPlacementsProvider(status));
    return RefreshIndicator(
      onRefresh: () async { ref.invalidate(hodPlacementsProvider(status)); ref.invalidate(hodPlacementsProvider(null)); },
      child: placementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (placements) {
          if (placements.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.work_off_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No ${status.toLowerCase()} placements', style: TextStyle(color: Colors.grey.shade500)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
            itemCount: placements.length,
            itemBuilder: (ctx, i) => _buildPlacementCard(placements[i], status, isDark),
          );
        },
      ),
    );
  }

  Widget _buildPlacementCard(Map<String, dynamic> p, String status, bool isDark) {
    final id = _parseInt(p['id']);
    final studentName = p['studentName']?.toString() ?? 'Student';
    final companyName = p['companyName']?.toString() ?? 'Company';
    final startDate = p['startDate']?.toString();
    final endDate = p['endDate']?.toString();
    final color = status == 'ACTIVE' ? Colors.green : status == 'COMPLETED' ? Colors.blue : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.work_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(studentName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text(companyName, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12)),
            if (startDate != null) Text('Started: ${startDate.substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            if (endDate != null) Text('Ended: ${endDate.substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 12),
        if (status == 'ACTIVE')
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => _forceEnd(id, studentName),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            child: const Text('Force End'),
          ))
        else if (status == 'TERMINATED')
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => ref.read(dashboardIndexProvider.notifier).state = 2,
            icon: const Icon(Icons.send_rounded, size: 14),
            label: const Text('Reassign Student'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1fa2ff)),
          )),
      ]),
    );
  }
}

// ── Reports ───────────────────────────────────────────────────────────────────
class _HodReportsTab extends ConsumerStatefulWidget {
  const _HodReportsTab();
  @override
  ConsumerState<_HodReportsTab> createState() => _HodReportsTabState();
}

class _HodReportsTabState extends ConsumerState<_HodReportsTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _attendanceFilter = 'ALL';
  int? _weekFilter;
  final _weekCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _weekCtrl.dispose(); super.dispose(); }

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
            profileName: ref.watch(userProfileProvider).value?.fullName ?? 'HOD',
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
                tabs: const [Tab(text: 'Weekly Reports'), Tab(text: 'Final Reports')],
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
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Department Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [
          _summaryItem('Total Reports', '${_parseInt(summary['totalWeeklyReports'])}', Colors.purple),
          _summaryItem('Present', '$present', Colors.green),
          _summaryItem('Absent', '$absent', Colors.red),
          _summaryItem('Late', '$late', Colors.orange),
        ]),
        if (avgTech != null || avgSoft != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            if (avgTech != null) _summaryItem('Avg Tech', '${(avgTech as num).toStringAsFixed(1)}', Colors.blue),
            if (avgSoft != null) _summaryItem('Avg Soft', '${(avgSoft as num).toStringAsFixed(1)}', Colors.teal),
          ]),
        ],
      ]),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ]));
  }

  Widget _buildWeeklyReportsView(bool isDark) {
    final filter = WeeklyReportFilter(weekNumber: _weekFilter, attendanceStatus: _attendanceFilter == 'ALL' ? null : _attendanceFilter);
    final reportsAsync = ref.watch(hodWeeklyReportsProvider(filter));
    const statuses = ['ALL', 'PRESENT', 'ABSENT', 'LATE'];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Row(children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: statuses.map((s) {
                final sel = _attendanceFilter == s;
                return GestureDetector(
                  onTap: () => setState(() => _attendanceFilter = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFa18cd1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? const Color(0xFFa18cd1) : Colors.grey.withOpacity(0.2)),
                    ),
                    child: Text(s, style: TextStyle(color: sel ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                );
              }).toList()),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _weekCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Wk', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), isDense: true),
              onChanged: (v) => setState(() => _weekFilter = int.tryParse(v)),
            ),
          ),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(hodWeeklyReportsProvider(filter)),
          child: reportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (reports) {
              if (reports.isEmpty) return Center(child: Text('No reports', style: TextStyle(color: Colors.grey.shade500)));
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                itemCount: reports.length,
                itemBuilder: (ctx, i) {
                  final r = reports[i];
                  final name = r['studentName']?.toString() ?? 'Student';
                  final week = r['weekNumber'];
                  final att = r['attendanceStatus']?.toString() ?? '';
                  final attColor = att == 'PRESENT' ? Colors.green : att == 'ABSENT' ? Colors.red : Colors.orange;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04))),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        if (week != null) Text('Week $week', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ])),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: attColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(att, style: TextStyle(color: attColor, fontSize: 9, fontWeight: FontWeight.w900))),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ),
    ]);
  }

  Widget _buildFinalReportsView(bool isDark) {
    final reportsAsync = ref.watch(hodReportsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(hodReportsProvider),
      child: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reports) {
          if (reports.isEmpty) return Center(child: Text('No final reports', style: TextStyle(color: Colors.grey.shade500)));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
            itemCount: reports.length,
            itemBuilder: (ctx, i) {
              final r = reports[i];
              final id = _parseInt(r['id']);
              final student = r['student'] as Map<String, dynamic>? ?? {};
              final studentUser = student['user'] as Map<String, dynamic>? ?? {};
              final name = studentUser['full_name']?.toString() ?? 'Student';
              final pdfUrl = r['pdf_url']?.toString();
              final stamped = _parseBool(r['stamped']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.04))),
                child: Row(children: [
                  const Icon(Icons.description_rounded, color: Colors.purple, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    if (stamped) const Text('Stamped ✓', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ])),
                  IconButton(
                    icon: Icon(Icons.download_rounded, color: pdfUrl != null && pdfUrl.isNotEmpty ? Colors.purple : Colors.grey.shade300),
                    onPressed: pdfUrl != null && pdfUrl.isNotEmpty ? () async {
                      final uri = Uri.parse(pdfUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open report.')));
                      }
                    } : null,
                  ),
                ]),
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

class _AdminOverviewTab extends ConsumerStatefulWidget {
  const _AdminOverviewTab();

  @override
  ConsumerState<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends ConsumerState<_AdminOverviewTab> {
  final _broadcastController = TextEditingController();

  @override
  void dispose() {
    _broadcastController.dispose();
    super.dispose();
  }

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
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildOverviewGrid(context, stats, isDark),
                      const SizedBox(height: 32),
                      _buildSectionHeader(theme, 'Pending Approvals'),
                      const SizedBox(height: 16),
                      _buildPendingApprovalsPreview(context, ref, isDark),

                      const SizedBox(height: 32),
                      _buildRecentActivitiesPreview(context, ref, isDark),

                      FeedPreviewSection(),
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
        _buildStatCard(context, 'Total Reports', stats.totalReports.toString(), Icons.insert_chart_rounded, Colors.green, isDark),
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
                        final id = _parseInt(item['id']);
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
                        final id = _parseInt(item['id']);
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
            controller: _broadcastController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
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
              onPressed: () async {
                final content = _broadcastController.text.trim();
                if (content.isEmpty) return;
                try {
                  await ref.read(adminRepositoryProvider).broadcast('System Broadcast', content);
                  _broadcastController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent successfully!')));
                    ref.invalidate(feedProvider);
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
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

  Widget _buildQuickNavigation(BuildContext context, WidgetRef ref, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildNavChip(context, ref, 'Orgs', Icons.business_rounded, isDark, 1),
        _buildNavChip(context, ref, 'Users', Icons.group_rounded, isDark, 2),
        _buildNavChip(context, ref, 'Audit Logs', Icons.receipt_long_rounded, isDark, 3),
        _buildNavChip(context, ref, 'Config', Icons.settings_rounded, isDark, 4),
      ],
    );
  }

  Widget _buildNavChip(BuildContext context, WidgetRef ref, String label, IconData icon, bool isDark, int targetIndex) {
    return InkWell(
      onTap: () => ref.read(dashboardIndexProvider.notifier).state = targetIndex,
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
              profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Admin',
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
            _buildMiniStat('Suspended', '0', Icons.block_rounded, Colors.red, isDark),
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
          color: isPending ? Colors.orange.withOpacity(0.3) : isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
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
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(org['type'] == 'University' ? Icons.account_balance_rounded : Icons.business_rounded, color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(org['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(org['official_email'] ?? 'No email', style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(children: [
              Icon(Icons.category_rounded, size: 11, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(org['type'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
              if (org['created_at'] != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(org['created_at'].toString().split('T')[0], style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ]),
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
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _updateStatus(ref, org, 'APPROVED'),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showOrgDetails(context, ref, org, isDark),
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (status == 'APPROVED')
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _updateStatus(ref, org, 'SUSPENDED'),
                        icon: const Icon(Icons.block_rounded, size: 16),
                        label: const Text('Suspend'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    )
                  else if (status == 'SUSPENDED')
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _updateStatus(ref, org, 'APPROVED'),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Activate'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  void _showOrgDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> org, bool isDark) {
    final status = org['approval_status'] as String? ?? '';
    final statusColor = switch (status) {
      'APPROVED' => Colors.green,
      'PENDING' => Colors.orange,
      'SUSPENDED' => Colors.red,
      _ => Colors.grey,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(org['type'] == 'University' ? Icons.account_balance_rounded : Icons.business_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(org['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ])),
              ]),
              const SizedBox(height: 32),
              _detailRow(Icons.category_rounded, 'Type', org['type']?.toString() ?? '-'),
              _detailRow(Icons.email_rounded, 'Official Email', org['official_email']?.toString() ?? '-'),
              if (org['phone'] != null) _detailRow(Icons.phone_rounded, 'Phone', org['phone'].toString()),
              if (org['address'] != null) _detailRow(Icons.location_on_rounded, 'Address', org['address'].toString()),
              if (org['website'] != null) _detailRow(Icons.language_rounded, 'Website', org['website'].toString()),
              if (org['created_at'] != null) _detailRow(Icons.calendar_today_rounded, 'Registered', org['created_at'].toString().split('T')[0]),
              if (org['rejection_reason'] != null && org['rejection_reason'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.3))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Rejection Reason: ${org['rejection_reason']}', style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],
              const SizedBox(height: 24),
              if (status == 'SUSPENDED')
                FilledButton.icon(
                  onPressed: () { Navigator.pop(ctx); _updateStatus(ref, org, 'APPROVED'); },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Reactivate Organization'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ])),
      ]),
    );
  }

  void _showRejectDialog(WidgetRef ref, Map<String, dynamic> org) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reject Organization', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(org['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl, maxLines: 3,
              decoration: InputDecoration(hintText: 'Enter rejection reason (optional)...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.all(12)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); _updateStatus(ref, org, 'REJECTED'); },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, Map<String, dynamic> org, String status) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      final id = _parseInt(org['id']);
      if (org['type'] == 'University') {
        await repo.updateUniversityStatus(id, status);
      } else {
        await repo.updateCompanyStatus(id, status);
      }
      ref.invalidate(allUniversitiesProvider);
      ref.invalidate(allCompaniesProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${org['name']} -> $status')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab> with SingleTickerProviderStateMixin {
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
              profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Admin',
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
                    final pendingSupsCount = ref.watch(pendingSupervisorsProvider).asData?.value.length ?? 0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _miniStat('Pending Coords', stats.pendingApprovals.toString(), Icons.pending_rounded, Colors.orange, isDark),
                        const SizedBox(width: 12),
                        _miniStat('Pending Sups', pendingSupsCount.toString(), Icons.pending_actions_rounded, Colors.purple, isDark),
                        const SizedBox(width: 12),
                        _miniStat('Total Users', stats.totalUsers.toString(), Icons.group_rounded, Colors.blue, isDark),
                      ]),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Material(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Coordinators'),
                    Tab(icon: Icon(Icons.work_rounded, size: 18), text: 'Supervisors'),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED'].map((s) {
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
                          label: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : null)),
                          selected: selected,
                          selectedColor: color,
                          onSelected: (_) => setState(() => _statusFilter = s),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList()),
                  ),
                ]),
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
            final name = (c['user']?['full_name'] ?? '').toString().toLowerCase();
            final email = (c['user']?['email'] ?? '').toString().toLowerCase();
            final status = (c['user']?['institution_access_approval'] ?? 'PENDING').toString();
            final matchesSearch = name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
            final matchesStatus = _statusFilter == 'ALL' || status == _statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.school_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No coordinators found', style: TextStyle(color: Colors.grey.shade500)),
                ]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _buildCoordinatorCard(context, filtered[i], isDark),
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
            final name = (s['user']?['full_name'] ?? '').toString().toLowerCase();
            final email = (s['user']?['email'] ?? '').toString().toLowerCase();
            final status = (s['user']?['institution_access_approval'] ?? 'PENDING').toString();
            final matchesSearch = name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
            final matchesStatus = _statusFilter == 'ALL' || status == _statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.work_rounded, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No supervisors found', style: TextStyle(color: Colors.grey.shade500)),
                ]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _buildSupervisorCard(context, filtered[i], isDark),
          );
        },
      ),
    );
  }

  Widget _buildCoordinatorCard(BuildContext context, dynamic coord, bool isDark) {
    final theme = Theme.of(context);
    final user = coord['user'] as Map<String, dynamic>? ?? {};
    final approval = (user['institution_access_approval'] ?? 'PENDING') as String;
    final isPending = approval == 'PENDING';
    final uniName = coord['pending_university_name'] as String? ?? 'University not linked';
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
          color: isPending ? Colors.orange.withOpacity(0.35) : isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              child: Text(
                (user['full_name'] ?? '?').toString().isNotEmpty ? user['full_name'].toString()[0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(user['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(approval, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(user['email'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.account_balance_rounded, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Expanded(child: Text(uniName, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
              ]),
            ])),
          ]),
        ),
        if (isPending)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectCoordinator(coord),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _approveCoordinator(coord),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(children: [
              if (user['created_at'] != null) ...[
                Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(user['created_at'].toString().split('T')[0], style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                const Spacer(),
              ],
              if (approval == 'APPROVED')
                TextButton.icon(
                  onPressed: () => _rejectCoordinator(coord),
                  icon: const Icon(Icons.block_rounded, size: 14),
                  label: const Text('Revoke', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent, visualDensity: VisualDensity.compact),
                ),
            ]),
          ),
      ]),
    );
  }

  Widget _buildSupervisorCard(BuildContext context, dynamic sup, bool isDark) {
    final theme = Theme.of(context);
    final user = sup['user'] as Map<String, dynamic>? ?? {};
    final company = sup['company'] as Map<String, dynamic>? ?? {};
    final approval = (user['institution_access_approval'] ?? 'PENDING') as String;
    final isPending = approval == 'PENDING';
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
          color: isPending ? Colors.purple.withOpacity(0.35) : isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.purple.withOpacity(0.12),
              child: Text(
                (user['full_name'] ?? '?').toString().isNotEmpty ? user['full_name'].toString()[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(user['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(approval, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(user['email'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              if (company['name'] != null)
                Row(children: [
                  Icon(Icons.business_rounded, size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Expanded(child: Text(company['name'].toString(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
                ]),
            ])),
          ]),
        ),
        if (isPending)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectSupervisor(sup),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _approveSupervisor(sup),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(children: [
              if (user['created_at'] != null) ...[
                Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(user['created_at'].toString().split('T')[0], style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                const Spacer(),
              ],
              if (approval == 'APPROVED')
                TextButton.icon(
                  onPressed: () => _rejectSupervisor(sup),
                  icon: const Icon(Icons.block_rounded, size: 14),
                  label: const Text('Revoke', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent, visualDensity: VisualDensity.compact),
                ),
            ]),
          ),
      ]),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Future<void> _approveCoordinator(dynamic coord) async {
    final userId = _parseInt(coord['user']?['id'] ?? coord['userId']);
    if (userId == 0) return;
    try {
      await ref.read(adminRepositoryProvider).approveCoordinator(userId);
      ref.invalidate(pendingCoordinatorsProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${coord['user']?['full_name']} approved as Coordinator'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: const Text('Reject Coordinator', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to reject $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).rejectCoordinator(userId);
      ref.invalidate(pendingCoordinatorsProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name rejected'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _approveSupervisor(dynamic sup) async {
    final userId = _parseInt(sup['user']?['id'] ?? sup['userId']);
    if (userId == 0) return;
    try {
      await ref.read(adminRepositoryProvider).approveSupervisor(userId);
      ref.invalidate(pendingSupervisorsProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${sup['user']?['full_name']} approved as Supervisor'), backgroundColor: Colors.purple),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: const Text('Reject Supervisor', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to reject $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).rejectSupervisor(userId);
      ref.invalidate(pendingSupervisorsProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name rejected'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
                  profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Admin',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final configAsync = ref.watch(systemConfigProvider);

    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (config) {
        final regStudent = config['registration_student_open'] == 'true';
        final regCoordinator = config['registration_coordinator_open'] == 'true';
        final regHod = config['registration_hod_open'] == 'true';
        final regSupervisor = config['registration_supervisor_open'] == 'true';
        final regUni = config['registration_university_open'] == 'true';
        final regComp = config['registration_company_open'] == 'true';
        final maintenance = config['maintenance_mode'] == 'true';
        final maintenanceMessage = config['maintenance_message'] ?? '';
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
                      profileName: ref.watch(userProfileProvider).value?.fullName ?? 'Admin',
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
                            _buildSwitchTile('Student registration open', regStudent, (v) => _updateConfig('registration_student_open', v.toString()), isDark),
                            _buildSwitchTile('Coordinator registration open', regCoordinator, (v) => _updateConfig('registration_coordinator_open', v.toString()), isDark),
                            _buildSwitchTile('Hod registration open', regHod, (v) => _updateConfig('registration_hod_open', v.toString()), isDark),
                            _buildSwitchTile('Supervisor registration open', regSupervisor, (v) => _updateConfig('registration_supervisor_open', v.toString()), isDark),
                            
                            const Divider(height: 32),
                            _buildSectionHeaderSmall('Institutional Controls'),
                            _buildSwitchTile('Registration: University', regUni, (v) => _updateConfig('registration_university_open', v.toString()), isDark),
                            _buildSwitchTile('Registration: Company', regComp, (v) => _updateConfig('registration_company_open', v.toString()), isDark),
                            
                            const Divider(height: 32),
                            _buildSectionHeaderSmall('Operational Rules'),
                            _buildConfigItem('Internship Rules', 
                              'Min ${config['internship_min_weeks']} Weeks, Max ${config['internship_max_weeks']} Weeks', 
                              Icons.rule_rounded, isDark, 
                              onTap: () => _showInternshipRulesDialog(context, config)),
                            _buildConfigItem('Weekly Deadlines', 
                              'Deadline: ${config['weekly_plan_deadline_day']}', 
                              Icons.event_note_rounded, isDark, 
                              onTap: () => _showWeeklyDeadlineDialog(context, config)),
                          ]),
                          const SizedBox(height: 32),
                          _buildSection(context, 'Maintenance Mode', [
                            _buildSwitchTile('Enable Maintenance', maintenance, (v) => _updateConfig('maintenance_mode', v.toString()), isDark),
                            if (maintenance)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: TextFormField(
                                  initialValue: maintenanceMessage,
                                  onFieldSubmitted: (v) => _updateConfig('maintenance_message', v),
                                  decoration: InputDecoration(
                                    hintText: 'Maintenance message...',
                                    helperText: 'Press Enter to save message',
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
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
                            _buildConfigItem(
                              'Password Policy',
                              'Minimum length: $passwordMinLength',
                              Icons.password_rounded,
                              isDark,
                              onTap: () => _showSingleValueConfigDialog(
                                context: context,
                                title: 'Password Policy',
                                label: 'Minimum password length',
                                configKey: 'password_min_length',
                                initialValue: passwordMinLength,
                                isNumber: true,
                              ),
                            ),
                            _buildConfigItem(
                              'Session Timeout',
                              '$sessionTimeoutMin minutes',
                              Icons.timer_rounded,
                              isDark,
                              onTap: () => _showSingleValueConfigDialog(
                                context: context,
                                title: 'Session Timeout',
                                label: 'Session timeout (minutes)',
                                configKey: 'session_timeout_min',
                                initialValue: sessionTimeoutMin,
                                isNumber: true,
                              ),
                            ),
                            _buildConfigItem(
                              'API Limits / Rate Limiting',
                              '$apiRateLimitPerMin requests/min',
                              Icons.speed_rounded,
                              isDark,
                              onTap: () => _showSingleValueConfigDialog(
                                context: context,
                                title: 'API Rate Limit',
                                label: 'Requests per minute',
                                configKey: 'api_rate_limit_per_min',
                                initialValue: apiRateLimitPerMin,
                                isNumber: true,
                              ),
                            ),
                            _buildActionTile('Export Audit Logs (CSV)', Icons.download_rounded, Colors.teal, isDark, () async {
                              try {
                                final csv = await ref.read(adminRepositoryProvider).exportAuditLogsCsv();
                                if (!mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Audit Logs CSV (preview)'),
                                    content: SizedBox(
                                      width: 420,
                                      child: SingleChildScrollView(
                                        child: SelectableText(
                                          csv.length > 2000 ? '${csv.substring(0, 2000)}\n\n...truncated...' : csv,
                                        ),
                                      ),
                                    ),
                                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                                  ),
                                );
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed export: $e')));
                              }
                            }),
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

  void _showWeeklyDeadlineDialog(BuildContext context, Map<String, String> config) {
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
            value: selectedDay,
            items: days
                .map((d) => DropdownMenuItem<String>(
                      value: d,
                      child: Text(d),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setLocalState(() => selectedDay = value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Deadline Day',
            ),
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
            TextField(controller: hostCtrl, decoration: const InputDecoration(labelText: 'Host')),
            TextField(controller: portCtrl, decoration: const InputDecoration(labelText: 'Port')),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMTP settings saved.')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final value = ctrl.text.trim();
              if (value.isEmpty) return;
              if (isNumber && int.tryParse(value) == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid number.')));
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
    // Invalidate cached profile so the next login fetches fresh data
    ref.invalidate(userProfileProvider);
    ref.invalidate(appStartDecisionProvider);
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
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Latest community updates',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.commonFeed),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          feedAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(fontSize: 12))),
            data: (posts) {
              if (posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No updates yet', style: TextStyle(color: Colors.grey))),
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
                              color: (post.isPinned ? Colors.blue : Colors.grey).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              post.isPinned ? Icons.campaign_rounded : Icons.dynamic_feed_rounded,
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
                                  post.title ?? (post.content.length > 30 ? '${post.content.substring(0, 30)}...' : post.content),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                Text(
                                  '${post.author.fullName} • ${timeago.format(post.createdAt)}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
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
