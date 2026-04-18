import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_text_field.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    this.email,
    this.role,
    this.initialToken,
  });

  final String? email;
  final String? role;
  final String? initialToken;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email ?? '';
    _tokenController.text = widget.initialToken ?? '';
    _tokenController.addListener(_refresh);
    _emailController.addListener(_refresh);

    if ((widget.initialToken?.trim().isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _verify();
        }
      });
    }
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
    _emailController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  bool get _canVerify => _tokenController.text.trim().isNotEmpty;

  bool get _canResend {
    const pattern = r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$';
    return RegExp(pattern).hasMatch(_emailController.text.trim());
  }

  Future<void> _verify() async {
    setState(() => _hasInteracted = true);
    if (!_canVerify) {
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(_tokenController.text);

    if (!mounted || !ok) {
      return;
    }

    final role = widget.role?.toLowerCase();
    final needsPending =
        role == 'coordinator' ||
        role == 'hod' ||
        role == 'student' ||
        role == 'supervisor';

    context.go(needsPending ? AppRoutes.pendingReview : AppRoutes.auth);
  }

  Future<void> _resend() async {
    if (!_canResend) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .resendVerification(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              const Icon(Icons.mark_email_read_rounded, size: 62),
              const SizedBox(height: 12),
              Text(
                'Email Verification',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paste the verification token from your email to activate your account.',
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
              CustomTextField(
                controller: _tokenController,
                label: 'Verification Token',
                hint: 'Paste token here',
                prefixIcon: Icons.vpn_key_outlined,
                enabled: !state.isLoading,
                maxLines: 2,
                validator: (_) {
                  if (!_hasInteracted || _canVerify) {
                    return null;
                  }
                  return 'Verification token is required';
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emailController,
                label: 'Email (for resend)',
                hint: 'name@domain.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                enabled: !state.isLoading,
              ),
              const SizedBox(height: 18),
              AuthButton(
                label: 'Verify Email',
                onPressed: _verify,
                isLoading: state.isLoading,
                enabled: _canVerify,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: state.isLoading || !_canResend ? null : _resend,
                child: const Text('Resend Verification Email'),
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
