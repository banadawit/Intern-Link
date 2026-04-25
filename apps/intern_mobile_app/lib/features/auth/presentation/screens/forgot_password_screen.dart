import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _hasInteracted = false;

  late final AnimationController _animController;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final AnimationController _bgAnimationController;

  bool get _isValidEmail {
    const pattern = r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$';
    return RegExp(pattern).hasMatch(_emailController.text.trim());
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refresh);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _bgAnimationController.dispose();
    _emailController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required';

    const pattern = r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$';
    if (!RegExp(pattern).hasMatch(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _hasInteracted = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(_emailController.text);

    if (!mounted || !ok) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password reset link sent. Please check your email.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(authControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Stack(
          children: [
            // Animated Gradient Background
            AnimatedBuilder(
              animation: _bgAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        Color.lerp(
                              theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.05),
                              theme.colorScheme.secondary.withValues(alpha: isDark ? 0.3 : 0.15),
                              _bgAnimationController.value,
                            ) ??
                            theme.colorScheme.surface,
                      ],
                    ),
                  ),
                );
              },
            ),
            // Background Orbs
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Hero(
                          tag: 'internlink-auth-logo',
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(alpha: 0.8)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Reset Password',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your email address to receive a secure reset link.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Glassmorphic Form Container
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.white.withValues(alpha: 0.7),
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (state.errorMessage != null) ...[
                                      _InfoBanner(message: state.errorMessage!, isError: true),
                                      const SizedBox(height: 16),
                                    ],
                                    if (state.infoMessage != null) ...[
                                      _InfoBanner(message: state.infoMessage!, isError: false),
                                      const SizedBox(height: 16),
                                    ],
                                    Form(
                                      key: _formKey,
                                      autovalidateMode: _hasInteracted
                                          ? AutovalidateMode.onUserInteraction
                                          : AutovalidateMode.disabled,
                                      child: CustomTextField(
                                        controller: _emailController,
                                        label: 'Email Address',
                                        hint: 'name@university.edu',
                                        prefixIcon: Icons.alternate_email_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        enabled: !state.isLoading,
                                        validator: _emailValidator,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    AuthButton(
                                      label: 'Send Reset Link',
                                      onPressed: _submit,
                                      isLoading: state.isLoading,
                                      enabled: _isValidEmail,
                                    ),
                                  ],
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1) : const Color(0xFFECFAF3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3) : const Color(0xFFABEFC6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: isError ? Theme.of(context).colorScheme.error : const Color(0xFF067647),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Theme.of(context).colorScheme.error : const Color(0xFF067647),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
