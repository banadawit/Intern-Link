import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/app_entry/domain/entities/app_role.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/repositories/account_settings_repository.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  final String initialSection;

  const AccountSettingsScreen({super.key, this.initialSection = 'profile'});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      initialIndex: widget.initialSection == 'security' ? 1 : 0,
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
              body: TabBarView(
                children: [
                  _ProfileSettingsView(parentState: this),
                  _SecuritySettingsView(parentState: this),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveProfile({
    required BuildContext context,
    required String fullName,
    String? phoneNumber,
    String? department,
    String? studentId,
  }) async {
    setState(() => _isSavingProfile = true);
    try {
      await ref.read(accountSettingsRepositoryProvider).updateProfile(
            fullName: fullName,
            phoneNumber: phoneNumber,
            department: department,
            studentId: studentId,
          );
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> changePassword({
    required BuildContext context,
    required String currentPassword,
    required String newPassword,
  }) async {
    setState(() => _isChangingPassword = true);
    try {
      await ref.read(accountSettingsRepositoryProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
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

// ---------------------------------------------------------------------------
// PROFILE SETTINGS VIEW — role-aware fields
// ---------------------------------------------------------------------------

class _ProfileSettingsView extends ConsumerStatefulWidget {
  const _ProfileSettingsView({required this.parentState});
  final _AccountSettingsScreenState parentState;

  @override
  ConsumerState<_ProfileSettingsView> createState() => _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends ConsumerState<_ProfileSettingsView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _studentIdCtrl;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _departmentCtrl = TextEditingController();
    _studentIdCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _departmentCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Failed to load profile: $err')),
      data: (profile) {
        if (!_didInit) {
          _didInit = true;
          _nameCtrl.text = profile.fullName;
          _emailCtrl.text = profile.email;
          _phoneCtrl.text = profile.profile.phoneNumber ?? '';
          _departmentCtrl.text = profile.profile.department ?? '';
          _studentIdCtrl.text = profile.profile.studentId ?? '';
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 16),
            _buildTextField(context, 'Full Name', _nameCtrl, Icons.person_outline_rounded),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              'Email Address',
              _emailCtrl,
              Icons.mail_outline_rounded,
              enabled: false,
              helperText: 'Email change disabled by policy.',
            ),
            ..._buildRoleFields(context, profile.role),
            const SizedBox(height: 40),
            _buildSaveButton(context, profile.role),
          ],
        );
      },
    );
  }

  /// Returns the extra fields that are specific to each role.
  List<Widget> _buildRoleFields(BuildContext context, AppRole role) {
    switch (role) {
      case AppRole.student:
        return [
          const SizedBox(height: 16),
          _buildSectionHeader('Academic Information'),
          const SizedBox(height: 16),
          _buildTextField(context, 'Student ID', _studentIdCtrl, Icons.badge_outlined),
          const SizedBox(height: 16),
          _buildTextField(context, 'Department', _departmentCtrl, Icons.school_outlined),
        ];

      case AppRole.supervisor:
        return [
          const SizedBox(height: 16),
          _buildSectionHeader('Work Information'),
          const SizedBox(height: 16),
          _buildTextField(context, 'Phone Number', _phoneCtrl, Icons.phone_outlined),
        ];

      case AppRole.coordinator:
        return [
          const SizedBox(height: 16),
          _buildSectionHeader('Contact Information'),
          const SizedBox(height: 16),
          _buildTextField(context, 'Phone Number', _phoneCtrl, Icons.phone_outlined),
        ];

      case AppRole.hod:
        return [
          const SizedBox(height: 16),
          _buildSectionHeader('Department Information'),
          const SizedBox(height: 16),
          _buildTextField(context, 'Phone Number', _phoneCtrl, Icons.phone_outlined),
          const SizedBox(height: 16),
          _buildTextField(context, 'Department', _departmentCtrl, Icons.school_outlined),
        ];

      case AppRole.admin:
        // Admin only has full name — no role-specific profile table
        return [];
    }
  }

  Widget _buildSaveButton(BuildContext context, AppRole role) {
    final isSaving = widget.parentState._isSavingProfile;
    return Container(
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
        onPressed: isSaving
            ? null
            : () => widget.parentState.saveProfile(
                  context: context,
                  fullName: _nameCtrl.text.trim(),
                  phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
                  department: _departmentCtrl.text.trim().isEmpty ? null : _departmentCtrl.text.trim(),
                  studentId: _studentIdCtrl.text.trim().isEmpty ? null : _studentIdCtrl.text.trim(),
                ),
        child: Text(
          isSaving ? 'Updating...' : 'Update Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    String? helperText,
  }) {
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
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SECURITY SETTINGS VIEW
// ---------------------------------------------------------------------------

class _SecuritySettingsView extends ConsumerWidget {
  const _SecuritySettingsView({required this.parentState});
  final _AccountSettingsScreenState parentState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSectionHeader('Authentication'),
        const SizedBox(height: 16),
        _buildSecurityCard(
          context,
          'Change Password',
          'Update your account password',
          Icons.lock_outline_rounded,
          Colors.blue,
          onTap: parentState._isChangingPassword
              ? null
              : () => _showChangePasswordDialog(context, parentState),
        ),
        const SizedBox(height: 16),
        _buildSecurityCard(
          context,
          'Two-Factor Authentication',
          'Coming soon',
          Icons.verified_user_outlined,
          Colors.orange,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Two-factor auth will be available soon.')),
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Danger Zone'),
        const SizedBox(height: 16),
        _buildSecurityCard(
          context,
          'Deactivate Account',
          'Contact admin to deactivate your account',
          Icons.person_off_outlined,
          Colors.red,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please contact support/admin for deactivation.')),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context, _AccountSettingsScreenState parent) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 12),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final current = currentCtrl.text.trim();
              final newPass = newCtrl.text.trim();
              final confirm = confirmCtrl.text.trim();
              if (current.isEmpty || newPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all password fields.')));
                return;
              }
              if (newPass.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 8 characters.')));
                return;
              }
              if (newPass != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password confirmation does not match.')));
                return;
              }
              Navigator.pop(ctx);
              await parent.changePassword(context: context, currentPassword: current, newPassword: newPass);
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2));
  }
}

// ---------------------------------------------------------------------------
// SLIVER TAB BAR DELEGATE
// ---------------------------------------------------------------------------

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
