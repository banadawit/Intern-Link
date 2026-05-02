import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Platform helpers ──────────────────────────────────────────────────────────

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

bool get isWindows => !kIsWeb && Platform.isWindows;
bool get isMacOS   => !kIsWeb && Platform.isMacOS;
bool get isLinux   => !kIsWeb && Platform.isLinux;

/// True when running in a wide window (desktop or tablet landscape).
bool isWideScreen(BuildContext context) =>
    MediaQuery.of(context).size.width >= 720;

// ── Desktop scaffold ──────────────────────────────────────────────────────────

/// A desktop-optimised scaffold with a persistent sidebar navigation.
/// Replaces the bottom nav bar on wide screens.
class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.body,
    this.title = 'InternLink',
    this.actions,
    this.floatingActionButton,
  });

  final int selectedIndex;
  final List<DesktopNavDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Platform-specific sidebar style
    final sidebarBg = _sidebarColor(isDark);
    final sidebarWidth = isWindows ? 220.0 : isMacOS ? 200.0 : 210.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────────
          _DesktopSidebar(
            width: sidebarWidth,
            backgroundColor: sidebarBg,
            isDark: isDark,
            title: title,
            selectedIndex: selectedIndex,
            destinations: destinations,
            onDestinationSelected: onDestinationSelected,
          ),
          // Divider
          Container(width: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
          // ── Main content ───────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                body,
                if (floatingActionButton != null)
                  Positioned(
                    bottom: 32,
                    right: 32,
                    child: floatingActionButton!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _sidebarColor(bool isDark) {
    if (isWindows) {
      // Windows: slightly translucent acrylic-like
      return isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F3F3);
    }
    if (isMacOS) {
      // macOS: vibrancy-like sidebar
      return isDark ? const Color(0xFF1C1C1E) : const Color(0xFFECECEC);
    }
    // Linux: clean Material sidebar
    return isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFFFFFF);
  }
}

// ── Sidebar widget ────────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.width,
    required this.backgroundColor,
    required this.isDark,
    required this.title,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final double width;
  final Color backgroundColor;
  final bool isDark;
  final String title;
  final int selectedIndex;
  final List<DesktopNavDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Container(
      width: width,
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App title / logo area ──────────────────────────────────────────
          _SidebarHeader(isDark: isDark, title: title),

          const SizedBox(height: 8),

          // ── Nav items ─────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: destinations.length,
              itemBuilder: (context, i) {
                final dest = destinations[i];
                final selected = i == selectedIndex;
                return _SidebarItem(
                  destination: dest,
                  selected: selected,
                  isDark: isDark,
                  accentColor: accentColor,
                  onTap: () => onDestinationSelected(i),
                );
              },
            ),
          ),

          // ── Bottom: platform badge ─────────────────────────────────────────
          _SidebarFooter(isDark: isDark),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.isDark, required this.title});
  final bool isDark;
  final String title;

  @override
  Widget build(BuildContext context) {
    // macOS: leave space for traffic lights (28px title bar)
    final topPadding = isMacOS ? 52.0 : 20.0;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 16),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C8B83), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.link_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'InternLink',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  final DesktopNavDestination destination;
  final bool selected;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? accentColor.withOpacity(isDark ? 0.18 : 0.12)
        : Colors.transparent;
    final fg = selected
        ? accentColor
        : (isDark ? Colors.white70 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(color: accentColor.withOpacity(0.25))
                  : null,
            ),
            child: Row(children: [
              // Selected indicator bar (Windows Fluent style)
              if (isWindows)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 3,
                  height: selected ? 20 : 0,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Icon(
                selected ? destination.activeIcon : destination.icon,
                size: 18,
                color: fg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (destination.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${destination.badge}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final platformName = isWindows ? 'Windows' : isMacOS ? 'macOS' : 'Linux';
    final platformIcon = isWindows
        ? Icons.window_rounded
        : isMacOS
            ? Icons.laptop_mac_rounded
            : Icons.computer_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(children: [
        Icon(platformIcon, size: 14, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(width: 6),
        Text(
          platformName,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white24 : Colors.black26,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class DesktopNavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int? badge;

  const DesktopNavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge,
  });
}
