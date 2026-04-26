import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
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

  late final AnimationController _animController;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }

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
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
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
    _animController.dispose();
    _bgAnimationController.dispose();
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
    if (_passwordController.text != _confirmPasswordController.text) return false;

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

    HapticFeedback.selectionClick();
    final roleParam = _role.name;
    final email = Uri.encodeComponent(_emailController.text.trim());
    context.go('${AppRoutes.verifyEmail}?email=$email&role=$roleParam');
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
            // Animated Background
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
              top: -50,
              right: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
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
                        const SizedBox(height: 12),
                        Hero(
                          tag: 'internlink-auth-logo',
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
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
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Create Account',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join InternLink and elevate your internship experience.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Glassmorphic Form
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
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final state = ref.watch(authControllerProvider);
                                          return DropdownButtonFormField<RegistrationRole>(
                                            value: _role,
                                            onChanged: state.isLoading
                                                ? null
                                                : (role) {
                                                    if (role != null) {
                                                      setState(() => _role = role);
                                                    }
                                                  },
                                            decoration: InputDecoration(
                                              labelText: 'Role',
                                              prefixIcon: const Icon(Icons.badge_outlined),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              filled: true,
                                              fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                                            ),
                                            items: RegistrationRole.values
                                                .map(
                                                  (role) => DropdownMenuItem(
                                                    value: role,
                                                    child: Text(role.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  ),
                                                )
                                                .toList(),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final state = ref.watch(authControllerProvider);
                                          return CustomTextField(
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
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final state = ref.watch(authControllerProvider);
                                          return CustomTextField(
                                            controller: _emailController,
                                            label: 'Email',
                                            hint: 'name@university.edu',
                                            prefixIcon: Icons.alternate_email_rounded,
                                            keyboardType: TextInputType.emailAddress,
                                            enabled: !state.isLoading,
                                            validator: _emailValidator,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final state = ref.watch(authControllerProvider);
                                          return CustomTextField(
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
                                                        _obscurePassword = !_obscurePassword;
                                                      });
                                                    },
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final state = ref.watch(authControllerProvider);
                                          return CustomTextField(
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
                                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                                      });
                                                    },
                                              icon: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final state = ref.watch(authControllerProvider);
                                          return Column(
                                            children: _buildRoleFields(state.isLoading),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final state = ref.watch(authControllerProvider);
                                          return SizedBox(
                                            height: 56,
                                            child: AuthButton(
                                              label: 'Create Account',
                                              onPressed: _submit,
                                              isLoading: state.isLoading,
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () => context.pushReplacement(AppRoutes.auth),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                              ),
                              child: const Text(
                                'Login',
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoleFields(bool isLoading) {
    switch (_role) {
      case RegistrationRole.coordinator:
        return [
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          CustomTextField(
            controller: _universityIdController,
            label: 'University ID',
            hint: 'e.g. 1',
            prefixIcon: Icons.tag_rounded,
            keyboardType: TextInputType.number,
            enabled: !isLoading,
            validator: _positiveIntValidator,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          CustomTextField(
            controller: _universityIdController,
            label: 'University ID',
            hint: 'e.g. 1',
            prefixIcon: Icons.tag_rounded,
            keyboardType: TextInputType.number,
            enabled: !isLoading,
            validator: _positiveIntValidator,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _hodIdController,
            label: 'HoD ID (optional)',
            hint: 'e.g. 3',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            enabled: !isLoading,
            validator: _optionalPositiveIntValidator,
          ),
          const SizedBox(height: 16),
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
