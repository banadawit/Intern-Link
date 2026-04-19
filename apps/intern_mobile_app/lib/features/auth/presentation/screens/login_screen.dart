import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _hasInteracted = false;

  late final AnimationController _animController;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final AnimationController _bgAnimationController;

  bool get _isFormReady =>
      _isEmailValid(_emailController.text.trim()) &&
      _passwordController.text.length >= 8;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);

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

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _bgAnimationController.dispose();
    _emailController
      ..removeListener(_onFieldChanged)
      ..dispose();
    _passwordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  bool _isEmailValid(String value) {
    if (value.isEmpty) {
      return false;
    }
    const pattern = r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$';
    return RegExp(pattern).hasMatch(value);
  }

  String? _emailValidator(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Email is required';
    }
    if (!_isEmailValid(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Password is required';
    }
    if (input.length < 8) {
      return 'Password must be at least 8 characters';
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
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    if (!ok) {
      final state = ref.read(authControllerProvider);

      if (state.requiresVerification) {
        final email =
            state.emailForVerification ?? _emailController.text.trim();
        context.go(
          '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(email)}',
        );
        return;
      }

      const pendingCodes = {
        'PENDING_ADMIN_REVIEW',
        'PENDING_COORDINATOR_REVIEW',
        'PENDING_HOD_REVIEW',
        'INSTITUTION_NOT_APPROVED',
        'INSTITUTION_MEMBER_NOT_APPROVED',
        'HOD_APPROVAL_PENDING',
      };
      if (state.errorCode != null && pendingCodes.contains(state.errorCode)) {
        final message =
            state.errorMessage ??
            'Your account is waiting for institutional approval.';
        context.go(
          '${AppRoutes.pendingReview}?message=${Uri.encodeComponent(message)}',
        );
      }
      return;
    }

    HapticFeedback.selectionClick();
    context.go(AppRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
            Positioned(
              bottom: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome Back',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue your journey',
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
                                  child: Form(
                                    key: _formKey,
                                    autovalidateMode: _hasInteracted
                                        ? AutovalidateMode.onUserInteraction
                                        : AutovalidateMode.disabled,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final state = ref.watch(authControllerProvider);
                                            if (state.errorMessage != null) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 20),
                                                child: _InlineError(message: state.errorMessage!),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                        CustomTextField(
                                          controller: _emailController,
                                          label: 'Email Address',
                                          hint: 'name@university.edu',
                                          prefixIcon: Icons.alternate_email_rounded,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autofillHints: const [AutofillHints.email],
                                          validator: _emailValidator,
                                        ),
                                        const SizedBox(height: 20),
                                        CustomTextField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          hint: 'Enter your password',
                                          prefixIcon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [AutofillHints.password],
                                          onFieldSubmitted: (_) => _submit(),
                                          validator: _passwordValidator,
                                          suffix: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () => context.push(AppRoutes.forgotPassword),
                                            style: TextButton.styleFrom(
                                              foregroundColor: theme.colorScheme.primary,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final isLoading = ref.watch(authControllerProvider).isLoading;
                                            return SizedBox(
                                              height: 56,
                                              child: AuthButton(
                                                label: 'Sign In',
                                                onPressed: _submit,
                                                isLoading: isLoading,
                                                enabled: _isFormReady,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () => context.push(AppRoutes.register),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
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
