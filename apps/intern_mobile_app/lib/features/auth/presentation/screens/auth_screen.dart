import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../data/models/auth_models.dart';
import '../providers/auth_controller.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerFullNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerUniversityNameController = TextEditingController();
  final _registerCompanyNameController = TextEditingController();
  final _registerDepartmentController = TextEditingController();
  final _registerUniversityIdController = TextEditingController();
  final _registerHodIdController = TextEditingController();
  final _registerEmployeeIdController = TextEditingController();
  final _registerStudentIdController = TextEditingController();
  final _registerPositionController = TextEditingController();

  bool _loginObscurePassword = true;
  bool _registerObscurePassword = true;
  bool _registerObscureConfirmPassword = true;
  RegistrationRole _registerRole = RegistrationRole.student;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) {
          return;
        }

        ref
            .read(authControllerProvider.notifier)
            .setMode(
              _tabController.index == 0 ? AuthMode.login : AuthMode.register,
            );
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerFullNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _registerUniversityNameController.dispose();
    _registerCompanyNameController.dispose();
    _registerDepartmentController.dispose();
    _registerUniversityIdController.dispose();
    _registerHodIdController.dispose();
    _registerEmployeeIdController.dispose();
    _registerStudentIdController.dispose();
    _registerPositionController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _loginEmailController.text,
          password: _loginPasswordController.text,
        );

    if (!mounted || !ok) {
      return;
    }

    context.go(AppRoutes.splash);
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }

    final payload = RegisterPayload(
      fullName: _registerFullNameController.text.trim(),
      email: _registerEmailController.text.trim(),
      password: _registerPasswordController.text,
      role: _registerRole,
      universityName: _registerUniversityNameController.text.trim(),
      companyName: _registerCompanyNameController.text.trim(),
      department: _registerDepartmentController.text.trim(),
      studentId: _registerStudentIdController.text.trim(),
      position: _registerPositionController.text.trim(),
      universityId: int.tryParse(_registerUniversityIdController.text.trim()),
      hodId: int.tryParse(_registerHodIdController.text.trim()),
      employeeId: _registerEmployeeIdController.text.trim(),
    );

    final ok = await ref
        .read(authControllerProvider.notifier)
        .register(payload);

    if (!ok || !mounted) {
      return;
    }

    _registerPasswordController.clear();
    _registerConfirmPasswordController.clear();
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    final infoMessage = state.infoMessage;
    final errorMessage = state.errorMessage;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'InternLink',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or create your account to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 18),
                if (infoMessage != null) ...[
                  _MessageBanner(
                    icon: Icons.check_circle_outline_rounded,
                    background: const Color(0xFFEAF8EF),
                    foreground: const Color(0xFF1A7F45),
                    message: infoMessage,
                    onClose: () => ref
                        .read(authControllerProvider.notifier)
                        .clearMessages(),
                  ),
                  const SizedBox(height: 10),
                ],
                if (errorMessage != null) ...[
                  _MessageBanner(
                    icon: Icons.error_outline_rounded,
                    background: const Color(0xFFFFEFEF),
                    foreground: const Color(0xFFB42318),
                    message: errorMessage,
                    onClose: () => ref
                        .read(authControllerProvider.notifier)
                        .clearMessages(),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Login'),
                          Tab(text: 'Register'),
                        ],
                      ),
                      SizedBox(
                        height: 720,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: LoginForm(
                                emailController: _loginEmailController,
                                passwordController: _loginPasswordController,
                                formKey: _loginFormKey,
                                obscurePassword: _loginObscurePassword,
                                isLoading: state.isLoading,
                                onTogglePassword: () {
                                  setState(() {
                                    _loginObscurePassword =
                                        !_loginObscurePassword;
                                  });
                                },
                                onSubmit: _submitLogin,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: RegisterForm(
                                formKey: _registerFormKey,
                                fullNameController: _registerFullNameController,
                                emailController: _registerEmailController,
                                passwordController: _registerPasswordController,
                                confirmPasswordController:
                                    _registerConfirmPasswordController,
                                universityNameController:
                                    _registerUniversityNameController,
                                companyNameController:
                                    _registerCompanyNameController,
                                departmentController:
                                    _registerDepartmentController,
                                universityIdController:
                                    _registerUniversityIdController,
                                hodIdController: _registerHodIdController,
                                employeeIdController:
                                    _registerEmployeeIdController,
                                studentIdController:
                                    _registerStudentIdController,
                                positionController: _registerPositionController,
                                role: _registerRole,
                                obscurePassword: _registerObscurePassword,
                                obscureConfirmPassword:
                                    _registerObscureConfirmPassword,
                                isLoading: state.isLoading,
                                onRoleChanged: (role) {
                                  setState(() => _registerRole = role);
                                },
                                onTogglePassword: () {
                                  setState(() {
                                    _registerObscurePassword =
                                        !_registerObscurePassword;
                                  });
                                },
                                onToggleConfirmPassword: () {
                                  setState(() {
                                    _registerObscureConfirmPassword =
                                        !_registerObscureConfirmPassword;
                                  });
                                },
                                onSubmit: _submitRegister,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.message,
    required this.onClose,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: foreground),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
