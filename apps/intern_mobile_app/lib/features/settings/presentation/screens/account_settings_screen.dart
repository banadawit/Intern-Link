import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AccountSettingsScreen extends ConsumerWidget {
  final String initialSection; // 'profile' or 'security'

  const AccountSettingsScreen({super.key, this.initialSection = 'profile'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      initialIndex: initialSection == 'security' ? 1 : 0,
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
        body: Stack(
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
            NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _buildAppBar(context, isDark),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    tabs: const [Tab(text: 'Profile Details'), Tab(text: 'Security')],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelColor: Colors.grey,
                    labelColor: theme.colorScheme.primary,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                  isDark,
                ),
              ),
            ],
            body: const TabBarView(
              children: [
                _ProfileSettingsView(),
                _SecuritySettingsView(),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: const FlexibleSpaceBar(
        title: Text('Account Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
    );
  }
}

class _ProfileSettingsView extends StatelessWidget {
  const _ProfileSettingsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Personal Information'),
        const SizedBox(height: 16),
        _buildTextField(context, 'Full Name', 'e.g. John Doe', Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _buildTextField(context, 'Email Address', 'john.doe@example.com', Icons.mail_outline_rounded),
        const SizedBox(height: 16),
        _buildTextField(context, 'Phone Number', '+251 912 345 678', Icons.phone_android_rounded),
        const SizedBox(height: 32),
        _buildSectionHeader('Professional Details'),
        const SizedBox(height: 16),
        _buildTextField(context, 'Position/Title', 'Senior Software Engineer', Icons.work_outline_rounded),
        const SizedBox(height: 40),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF8A2387), Color(0xFFE94057)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFFE94057).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {},
            child: const Text('Update Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2));
  }

  Widget _buildTextField(BuildContext context, String label, String initialValue, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        initialValue: initialValue,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

class _SecuritySettingsView extends StatelessWidget {
  const _SecuritySettingsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Authentication'),
        const SizedBox(height: 16),
        _buildSecurityCard(
          context,
          'Change Password',
          'Last changed 3 months ago',
          Icons.lock_outline_rounded,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildSecurityCard(
          context,
          'Two-Factor Authentication',
          'Not enabled',
          Icons.verified_user_outlined,
          Colors.orange,
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Danger Zone'),
        const SizedBox(height: 16),
        _buildSecurityCard(
          context,
          'Deactivate Account',
          'Temporarily disable your profile',
          Icons.person_off_outlined,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildSecurityCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_right_rounded, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2));
  }
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
      color: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
