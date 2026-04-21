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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                isDark ? const Color(0xFF0F172A) : Colors.white,
              ],
            ),
          ),
          child: NestedScrollView(
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
        _buildTextField('Full Name', 'e.g. John Doe', Icons.person_outline_rounded),
        const SizedBox(height: 16),
        _buildTextField('Email Address', 'john.doe@example.com', Icons.mail_outline_rounded),
        const SizedBox(height: 16),
        _buildTextField('Phone Number', '+251 912 345 678', Icons.phone_android_rounded),
        const SizedBox(height: 32),
        _buildSectionHeader('Professional Details'),
        const SizedBox(height: 16),
        _buildTextField('Position/Title', 'Senior Software Engineer', Icons.work_outline_rounded),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(onPressed: () {}, child: const Text('Update Profile')),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2));
  }

  Widget _buildTextField(String label, String initialValue, IconData icon) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
    );
  }
}

class _SecuritySettingsView extends StatelessWidget {
  const _SecuritySettingsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
          const Icon(Icons.chevron_right_rounded, size: 18),
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
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
