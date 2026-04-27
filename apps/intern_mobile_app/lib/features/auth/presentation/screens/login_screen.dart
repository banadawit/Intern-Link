import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _touched = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$').hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _touched = true);
    if (!_formKey.currentState!.validate()) return;

    final route = await ref.read(authControllerProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    if (route == null) {
      final state = ref.read(authControllerProvider);
      if (state.requiresVerification) {
        final email = state.emailForVerification ?? _emailCtrl.text.trim();
        context.go('${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(email)}');
        return;
      }
      const pendingCodes = {
        'PENDING_ADMIN_REVIEW', 'PENDING_COORDINATOR_REVIEW',
        'PENDING_HOD_REVIEW', 'INSTITUTION_NOT_APPROVED',
        'INSTITUTION_MEMBER_NOT_APPROVED', 'HOD_APPROVAL_PENDING',
      };
      if (state.errorCode != null && pendingCodes.contains(state.errorCode)) {
        final msg = state.errorMessage ?? 'Your account is waiting for approval.';
        context.go('${AppRoutes.pendingReview}?message=${Uri.encodeComponent(msg)}');
      }
      return;
    }

    HapticFeedback.selectionClick();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background orbs
          Positioned(top: -100, right: -60,
            child: _Orb(color: theme.colorScheme.primary.withOpacity(0.12), size: 320)),
          Positioned(bottom: -80, left: -60,
            child: _Orb(color: theme.colorScheme.secondary.withOpacity(0.10), size: 280)),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back to Home
                      TextButton.icon(
                        onPressed: () => context.go(AppRoutes.onboarding),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                        label: const Text('Back to Home'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Header
                      Text('Welcome Back',
                          style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Please enter your credentials to access your dashboard',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.55))),
                      const SizedBox(height: 28),

                      // Error banner
                      if (state.errorMessage != null) ...[
                        _Banner(
                          icon: Icons.error_outline_rounded,
                          message: state.errorMessage!,
                          isError: true,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form card
                      _Card(
                        isDark: isDark,
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _touched
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email
                              _FieldLabel('Email Address'),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _emailCtrl,
                                hint: 'name@university.edu.et',
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 20),

                              // Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const _FieldLabel('Password'),
                                  TextButton(
                                    onPressed: () => context.push(AppRoutes.forgotPassword),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.primary,
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Forgot password?',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _InputField(
                                controller: _passwordCtrl,
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                validator: _validatePassword,
                                isDark: isDark,
                                suffix: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Submit
                              _PrimaryButton(
                                label: 'Sign In to InternLink',
                                isLoading: state.isLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.register),
                            style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary),
                            child: const Text('Create an account',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared UI Widgets ────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffix,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final void Function(String)? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.35), fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.45)),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.isLoading, required this.onPressed});
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.message, required this.isError});
  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final bg = isError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
