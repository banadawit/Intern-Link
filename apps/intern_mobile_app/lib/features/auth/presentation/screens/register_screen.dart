import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../data/models/auth_models.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _universityNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _hodIdController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _positionController = TextEditingController();

  RegistrationRole _role = RegistrationRole.student;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasInteracted = false;

  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  List<TextEditingController> get _controllers => [
    _fullNameController,
    _emailController,
    _passwordController,
    _confirmPasswordController,
    _universityNameController,
    _companyNameController,
    _departmentController,
    _universityIdController,
    _hodIdController,
    _employeeIdController,
    _studentIdController,
    _positionController,
  ];

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _controllers) {
      controller
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  bool get _isFormReady {
    if (_fullNameController.text.trim().isEmpty) return false;
    if (!_isEmailValid(_emailController.text.trim())) return false;
    if (_passwordController.text.length < 8) return false;
    if (_passwordController.text != _confirmPasswordController.text)
      return false;

    switch (_role) {
      case RegistrationRole.coordinator:
        return _universityNameController.text.trim().isNotEmpty;
      case RegistrationRole.supervisor:
        return _companyNameController.text.trim().isNotEmpty;
      case RegistrationRole.hod:
        return _isPositiveInt(_universityIdController.text) &&
            _departmentController.text.trim().isNotEmpty;
      case RegistrationRole.student:
        return _isPositiveInt(_universityIdController.text);
    }
  }

  bool _isEmailValid(String value) {
    if (value.isEmpty) return false;
    const pattern = r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$';
    return RegExp(pattern).hasMatch(value);
  }

  bool _isPositiveInt(String raw) {
    final parsed = int.tryParse(raw.trim());
    return parsed != null && parsed > 0;
  }

  String? _emailValidator(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required';
    if (!_isEmailValid(input)) return 'Enter a valid email address';
    return null;
  }

  String? _passwordValidator(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required';
    if (input.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Please confirm your password';
    if (input != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _positiveIntValidator(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'This field is required';
    if (!_isPositiveInt(input)) return 'Enter a valid positive number';
    return null;
  }

  String? _optionalPositiveIntValidator(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    if (!_isPositiveInt(input)) return 'Enter a valid positive number';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _hasInteracted = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payload = RegisterPayload(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
      universityName: _universityNameController.text.trim(),
      companyName: _companyNameController.text.trim(),
      department: _departmentController.text.trim(),
      studentId: _studentIdController.text.trim(),
      position: _positionController.text.trim(),
      universityId: int.tryParse(_universityIdController.text.trim()),
      hodId: int.tryParse(_hodIdController.text.trim()),
      employeeId: _employeeIdController.text.trim(),
    );

    final ok = await ref
        .read(authControllerProvider.notifier)
        .register(payload);
    if (!mounted || !ok) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration submitted. Please verify your email.'),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0C8B83).withValues(alpha: 0.10),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton.filledTonal(
                          onPressed: state.isLoading
                              ? null
                              : () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Hero(
                        tag: 'internlink-auth-logo',
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0C8B83), Color(0xFF0A6E7A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Create Account',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Set up your InternLink profile to get started.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.92,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _hasInteracted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (state.errorMessage != null) ...[
                                    _InlineError(message: state.errorMessage!),
                                    const SizedBox(height: 14),
                                  ],
                                  DropdownButtonFormField<RegistrationRole>(
                                    value: _role,
                                    onChanged: state.isLoading
                                        ? null
                                        : (role) {
                                            if (role != null) {
                                              setState(() => _role = role);
                                            }
                                          },
                                    decoration: const InputDecoration(
                                      labelText: 'Role',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: RegistrationRole.values
                                        .map(
                                          (role) => DropdownMenuItem(
                                            value: role,
                                            child: Text(role.label),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 14),
                                  CustomTextField(
                                    controller: _fullNameController,
                                    label: 'Full Name',
                                    hint: 'Your full name',
                                    prefixIcon: Icons.person_outline_rounded,
                                    enabled: !state.isLoading,
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Full name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  CustomTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'name@university.edu',
                                    prefixIcon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !state.isLoading,
                                    validator: _emailValidator,
                                  ),
                                  const SizedBox(height: 14),
                                  CustomTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Minimum 8 characters',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    enabled: !state.isLoading,
                                    validator: _passwordValidator,
                                    suffix: IconButton(
                                      onPressed: state.isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  CustomTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter password',
                                    prefixIcon: Icons.lock_reset_rounded,
                                    obscureText: _obscureConfirmPassword,
                                    enabled: !state.isLoading,
                                    validator: _confirmPasswordValidator,
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
                                  ..._buildRoleFields(state.isLoading),
                                  const SizedBox(height: 18),
                                  AuthButton(
                                    label: 'Create Account',
                                    onPressed: _submit,
                                    isLoading: state.isLoading,
                                    enabled: _isFormReady,
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: state.isLoading
                                        ? null
                                        : () => context.pushReplacement(
                                            AppRoutes.auth,
                                          ),
                                    child: const Text(
                                      'Already have an account? Login',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoleFields(bool isLoading) {
    switch (_role) {
      case RegistrationRole.coordinator:
        return [
          const SizedBox(height: 14),
          CustomTextField(
            controller: _universityNameController,
            label: 'University Name',
            hint: 'Enter institution name',
            prefixIcon: Icons.school_outlined,
            enabled: !isLoading,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'University name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _positionController,
            label: 'Position (optional)',
            hint: 'Coordinator position',
            prefixIcon: Icons.work_outline_rounded,
            enabled: !isLoading,
          ),
        ];
      case RegistrationRole.supervisor:
        return [
          const SizedBox(height: 14),
          CustomTextField(
            controller: _companyNameController,
            label: 'Company Name',
            hint: 'Enter company name',
            prefixIcon: Icons.business_outlined,
            enabled: !isLoading,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Company name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _positionController,
            label: 'Position (optional)',
            hint: 'Supervisor position',
            prefixIcon: Icons.work_outline_rounded,
            enabled: !isLoading,
          ),
        ];
      case RegistrationRole.hod:
        return [
          const SizedBox(height: 14),
          CustomTextField(
            controller: _universityIdController,
            label: 'University ID',
            hint: 'e.g. 1',
            prefixIcon: Icons.tag_rounded,
            keyboardType: TextInputType.number,
            enabled: !isLoading,
            validator: _positiveIntValidator,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _departmentController,
            label: 'Department',
            hint: 'e.g. Software Engineering',
            prefixIcon: Icons.apartment_rounded,
            enabled: !isLoading,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Department is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _employeeIdController,
            label: 'Employee ID (optional)',
            hint: 'Employee identifier',
            prefixIcon: Icons.badge_rounded,
            enabled: !isLoading,
          ),
        ];
      case RegistrationRole.student:
        return [
          const SizedBox(height: 14),
          CustomTextField(
            controller: _universityIdController,
            label: 'University ID',
            hint: 'e.g. 1',
            prefixIcon: Icons.tag_rounded,
            keyboardType: TextInputType.number,
            enabled: !isLoading,
            validator: _positiveIntValidator,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _hodIdController,
            label: 'HoD ID (optional)',
            hint: 'e.g. 3',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            enabled: !isLoading,
            validator: _optionalPositiveIntValidator,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _studentIdController,
            label: 'Student ID (optional)',
            hint: 'Enter student identifier',
            prefixIcon: Icons.credit_card_rounded,
            enabled: !isLoading,
          ),
        ];
    }
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF7B2B2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
