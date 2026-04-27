import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../features/settings/data/repositories/account_settings_repository.dart';
import '../providers/auth_controller.dart';

/// Shown when a user logs in with a temporary password (must_change_password = true).
/// They cannot access the dashboard until they set a new password.
class ForceChangePasswordScreen extends ConsumerStatefulWidget {
  /// The dashboard route to navigate to after successful password change.
  final String nextRoute;

  const ForceChangePasswordScreen({super.key, required this.nextRoute});

  @override
  ConsumerState<ForceChangePasswordScreen> createState() =>
      _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState
    extends ConsumerState<ForceChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  int _passStrength = 0;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _updateStrength(String p) {
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    setState(() => _passStrength = s);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      await ref.read(accountSettingsRepositoryProvider).changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      // Invalidate profile so dashboard fetches fresh data
      ref.invalidate(userProfileProvider);
      if (mounted) context.go(widget.nextRoute);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primary = Color(0xFF0575E6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: Colors.orange, size: 40),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Change Your Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account was created with a temporary password.\nYou must set a new password before continuing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 8),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your temporary password is 123456. Enter it in the "Current Password" field below.',
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Error
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Current password
                _label('Current Password (temporary)'),
                const SizedBox(height: 6),
                _field(
                  controller: _currentCtrl,
                  hint: 'Enter 123456',
                  obscure: _obscureCurrent,
                  isDark: isDark,
                  primary: primary,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // New password
                _label('New Password'),
                const SizedBox(height: 6),
                _field(
                  controller: _newCtrl,
                  hint: 'Min 8 characters',
                  obscure: _obscureNew,
                  isDark: isDark,
                  primary: primary,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  onChanged: _updateStrength,
                  validator: (v) {
                    if ((v ?? '').length < 8) return 'Min 8 characters';
                    if (v == '123456') return 'Choose a stronger password';
                    return null;
                  },
                ),
                if (_newCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _StrengthBar(strength: _passStrength),
                ],
                const SizedBox(height: 16),

                // Confirm password
                _label('Confirm New Password'),
                const SizedBox(height: 6),
                _field(
                  controller: _confirmCtrl,
                  hint: 'Re-enter new password',
                  obscure: _obscureConfirm,
                  isDark: isDark,
                  primary: primary,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 32),

                // Submit
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Set New Password & Continue',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required bool isDark,
    required Color primary,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.red, Colors.orange, Colors.yellow.shade700, Colors.blue, Colors.green];
    final labels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final color = colors[strength.clamp(0, 4)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: List.generate(4, (i) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < strength ? color : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ))),
        const SizedBox(height: 4),
        Text(labels[strength.clamp(0, 4)],
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
