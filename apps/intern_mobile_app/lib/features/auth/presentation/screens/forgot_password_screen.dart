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
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _hasInteracted = false;

  bool get _isValidEmail {
    const pattern = r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$';
    return RegExp(pattern).hasMatch(_emailController.text.trim());
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
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
      const SnackBar(
        content: Text('Password reset link sent. Please check your email.'),
      ),
    );
    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reset your password',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your account email and we will send a secure reset link.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 20),
              if (state.errorMessage != null) ...[
                _InfoBanner(message: state.errorMessage!, isError: true),
                const SizedBox(height: 12),
              ],
              if (state.infoMessage != null) ...[
                _InfoBanner(message: state.infoMessage!, isError: false),
                const SizedBox(height: 12),
              ],
              Form(
                key: _formKey,
                autovalidateMode: _hasInteracted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'name@domain.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !state.isLoading,
                  validator: _emailValidator,
                ),
              ),
              const SizedBox(height: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F1) : const Color(0xFFECFAF3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFF7B2B2) : const Color(0xFFABEFC6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: isError ? const Color(0xFFB42318) : const Color(0xFF067647),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? const Color(0xFFB42318)
                    : const Color(0xFF067647),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
