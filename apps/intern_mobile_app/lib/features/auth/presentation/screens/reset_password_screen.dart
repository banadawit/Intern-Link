import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _tokenController.text = widget.initialToken ?? '';
    _tokenController.addListener(_refresh);
    _passwordController.addListener(_refresh);
    _confirmPasswordController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tokenController
      ..removeListener(_refresh)
      ..dispose();
    _passwordController
      ..removeListener(_refresh)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _tokenController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _submit() async {
    setState(() => _hasInteracted = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          token: _tokenController.text,
          newPassword: _passwordController.text,
        );

    if (!mounted || !ok) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset successful. Please login.')),
    );
    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Icon(Icons.lock_reset_rounded, size: 62),
              const SizedBox(height: 12),
              Text(
                'Create a New Password',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the reset token from your email and choose a strong password.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (state.errorMessage != null) ...[
                _Banner(message: state.errorMessage!, isError: true),
                const SizedBox(height: 12),
              ],
              if (state.infoMessage != null) ...[
                _Banner(message: state.infoMessage!, isError: false),
                const SizedBox(height: 12),
              ],
              Form(
                key: _formKey,
                autovalidateMode: _hasInteracted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _tokenController,
                      label: 'Reset Token',
                      hint: 'Paste your reset token',
                      prefixIcon: Icons.vpn_key_outlined,
                      enabled: !state.isLoading,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Reset token is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'New Password',
                      hint: 'Minimum 8 characters',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      enabled: !state.isLoading,
                      validator: (value) {
                        final input = value ?? '';
                        if (input.isEmpty) {
                          return 'Password is required';
                        }
                        if (input.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                      suffix: IconButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter password',
                      prefixIcon: Icons.lock_reset_rounded,
                      obscureText: _obscureConfirmPassword,
                      enabled: !state.isLoading,
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      suffix: IconButton(
                        onPressed: state.isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AuthButton(
                label: 'Reset Password',
                onPressed: _submit,
                isLoading: state.isLoading,
                enabled: _canSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F1) : const Color(0xFFECFAF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFFB42318) : const Color(0xFF067647),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
