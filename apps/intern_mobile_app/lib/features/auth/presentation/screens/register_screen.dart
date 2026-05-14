import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../app/desktop_layout.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../data/models/auth_models.dart';
import '../providers/auth_controller.dart';

// ─── Data helpers ─────────────────────────────────────────────────────────────

int _safeInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

class _University {
  const _University({required this.id, required this.name, required this.hasCoordinator});
  final int id;
  final String name;
  final bool hasCoordinator;
}

class _Department {
  const _Department({required this.id, required this.department});
  final int id;
  final String department;
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _approvedUniversitiesProvider = FutureProvider<List<_University>>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;
  final res = await dio.get('/universities/approved');
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? raw['data'] ?? [] : []);
  return (list as List)
      .map((e) => _University(
            id: _safeInt(e['id']),
            name: e['name'] as String,
            hasCoordinator: e['hasCoordinator'] == true,
          ))
      .toList();
});

final _departmentsProvider =
    FutureProvider.family<List<_Department>, int>((ref, universityId) async {
  final dio = ref.watch(apiClientProvider).dio;
  final res = await dio.get('/universities/$universityId/departments');
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? raw['data'] ?? [] : []);
  return (list as List)
      .map((e) => _Department(id: _safeInt(e['id']), department: e['department'] as String))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  int _step = 1; // 1 = role, 2 = account details, 3 = role-specific
  RegistrationRole? _role;

  // Step 2 controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  int _passStrength = 0;

  // Step 3 role-specific
  final _uniNameCtrl = TextEditingController(); // coordinator
  final _companyCtrl = TextEditingController(); // supervisor
  final _positionCtrl = TextEditingController(); // supervisor
  final _departmentCtrl = TextEditingController(); // hod
  final _employeeIdCtrl = TextEditingController(); // hod
  final _studentIdCtrl = TextEditingController(); // student
  int? _selectedUniversityId;       // HOD/Student university picker
  String? _selectedUniversityName;  // HOD/Student university picker
  int? _coordinatorUniversityId;    // Coordinator: ID of selected existing university (null = new request)
  int? _selectedCompanyId;          // Supervisor: ID of selected existing company
  int? _selectedHodId;
  int? _organizationRequestId;
  bool _agreedToTerms = false;
  bool _uniSearchOpen = false;
  final _uniSearchCtrl = TextEditingController();
  // Verification file — store bytes to avoid dart:io dependency
  List<int>? _verificationFileBytes;
  String? _verificationFileName;

  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  bool _step2Touched = false;
  bool _step3Touched = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _passCtrl.addListener(_updatePassStrength);
  }

  void _updatePassStrength() {
    final p = _passCtrl.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    setState(() => _passStrength = s);
  }

  @override
  void dispose() {
    _anim.dispose();
    for (final c in [
      _nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl,
      _uniNameCtrl, _companyCtrl, _positionCtrl, _departmentCtrl,
      _employeeIdCtrl, _studentIdCtrl, _uniSearchCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_step == 1) {
      if (_role == null) return;
      _animStep(() => _step = 2);
    } else if (_step == 2) {
      setState(() => _step2Touched = true);
      if (!_step2Key.currentState!.validate()) return;

      _animStep(() => _step = 3);
    }
  }

  void _prevStep() => _animStep(() => _step = _step - 1);

  void _animStep(VoidCallback change) {
    _anim.reset();
    setState(change);
    _anim.forward();
  }

  Future<void> _submit() async {
    setState(() => _step3Touched = true);
    if (_role == RegistrationRole.coordinator && _coordinatorUniversityId == null && _organizationRequestId == null) {
      _showSnack('Please select a university or submit a request first.');
      return;
    }
    if (!_step3Key.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnack('You must agree to the Terms of Service to continue.');
      return;
    }

    final payload = RegisterPayload(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role!,
      universityName: _uniNameCtrl.text.trim().isEmpty ? null : _uniNameCtrl.text.trim(),
      companyName: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      department: _departmentCtrl.text.trim().isEmpty ? null : _departmentCtrl.text.trim(),
      studentId: _studentIdCtrl.text.trim().isEmpty ? null : _studentIdCtrl.text.trim(),
      position: _positionCtrl.text.trim().isEmpty ? null : _positionCtrl.text.trim(),
      // For coordinator: use the selected existing university ID if available
      // For HOD/Student: use the university picker selection
      universityId: _role == RegistrationRole.coordinator
          ? _coordinatorUniversityId
          : _selectedUniversityId,
      companyId: _selectedCompanyId,
      hodId: _selectedHodId,
      organizationRequestId: _organizationRequestId,
      employeeId: _employeeIdCtrl.text.trim().isEmpty ? null : _employeeIdCtrl.text.trim(),
      verificationFileBytes: _verificationFileBytes,
      verificationFileName: _verificationFileName,
    );

    final ok = await ref.read(authControllerProvider.notifier).register(payload);
    if (!mounted || !ok) return;

    HapticFeedback.selectionClick();
    final email = Uri.encodeComponent(_emailCtrl.text.trim());
    context.go('${AppRoutes.verifyEmail}?email=$email&role=${_role!.name}');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = const Color(0xFF0D9488); // teal-600 matching web

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background orbs
          Positioned(top: -80, right: -60,
            child: _Orb(color: primary.withOpacity(0.10), size: 300)),
          Positioned(bottom: -60, left: -60,
            child: _Orb(color: primary.withOpacity(0.07), size: 260)),

          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsiveValue(context, mobile: 24.0, tablet: 48.0, desktop: 64.0),
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: responsiveValue(context, mobile: double.infinity, tablet: 560.0, desktop: 640.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      // Back to Home
                      TextButton.icon(
                        onPressed: () => context.go(AppRoutes.onboarding),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                        label: const Text('Back to Home'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface.withOpacity(0.55),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Progress bar
                      _ProgressBar(step: _step, primary: primary),
                      const SizedBox(height: 28),

                      // Error banner
                      Consumer(builder: (ctx, ref, _) {
                        final err = ref.watch(authControllerProvider).errorMessage;
                        if (err == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _Banner(message: err, isError: true),
                        );
                      }),

                      // Step content
                      if (_step == 1) _buildStep1(theme, isDark, primary),
                      if (_step == 2) _buildStep2(theme, isDark, primary),
                      if (_step == 3) _buildStep3(theme, isDark, primary),

                      const SizedBox(height: 24),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.auth),
                            style: TextButton.styleFrom(foregroundColor: primary),
                            child: const Text('Sign In',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                      ),   // Column
                    ),     // ConstrainedBox
                  ),       // Center
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Role Selection ────────────────────────────────────────────────

  Widget _buildStep1(ThemeData theme, bool isDark, Color primary) {
    final roles = [
      (
        role: RegistrationRole.student,
        title: 'Student',
        desc: 'Apply for internships and track your progress',
        icon: Icons.school_rounded,
      ),
      (
        role: RegistrationRole.coordinator,
        title: 'University Coordinator',
        desc: 'Manage student placements and university partnerships',
        icon: Icons.account_balance_rounded,
      ),
      (
        role: RegistrationRole.hod,
        title: 'Head of Department',
        desc: 'Oversee departmental internship activities and approvals',
        icon: Icons.business_center_rounded,
      ),
      (
        role: RegistrationRole.supervisor,
        title: 'Company Supervisor',
        desc: 'Evaluate students and verify internship reports',
        icon: Icons.work_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose your role',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Select how you will be using the InternLink platform',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55))),
        const SizedBox(height: 24),

        ...roles.map((r) => _RoleCard(
              role: r.role,
              title: r.title,
              desc: r.desc,
              icon: r.icon,
              selected: _role == r.role,
              isDark: isDark,
              primary: primary,
              onTap: () => setState(() => _role = r.role),
            )),

        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Continue to Account Details',
          isLoading: false,
          enabled: _role != null,
          primary: primary,
          onPressed: _nextStep,
          trailingIcon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  // ─── Step 2: Account Details ───────────────────────────────────────────────

  Widget _buildStep2(ThemeData theme, bool isDark, Color primary) {
    return Form(
      key: _step2Key,
      autovalidateMode: _step2Touched
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Account Details',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Enter your official credentials',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55))),
          const SizedBox(height: 24),

          _FieldLabel('Full Name'),
          const SizedBox(height: 8),
          _InputField(
            controller: _nameCtrl,
            hint: 'John Doe',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            primary: primary,
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Full name is required';
              if ((v ?? '').trim().length < 3) return 'Name must be at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _FieldLabel('Email Address'),
          const SizedBox(height: 8),
          _InputField(
            controller: _emailCtrl,
            hint: 'name@university.edu.et',
            icon: Icons.alternate_email_rounded,
            isDark: isDark,
            primary: primary,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$').hasMatch(s)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _FieldLabel('Password'),
          const SizedBox(height: 8),
          _InputField(
            controller: _passCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isDark: isDark,
            primary: primary,
            obscureText: _obscurePass,
            suffix: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            validator: (v) {
              if ((v ?? '').isEmpty) return 'Password is required';
              if ((v ?? '').length < 8) return 'Password must be at least 8 characters';
              if (!RegExp(r'[A-Za-z]').hasMatch(v!)) return 'Must contain at least one letter';
              if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain at least one number';
              return null;
            },
          ),
          if (_passCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PasswordStrengthBar(strength: _passStrength, primary: primary),
          ],
          const SizedBox(height: 16),

          _FieldLabel('Confirm Password'),
          const SizedBox(height: 8),
          _InputField(
            controller: _confirmCtrl,
            hint: '••••••••',
            icon: Icons.lock_reset_rounded,
            isDark: isDark,
            primary: primary,
            obscureText: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if ((v ?? '').isEmpty) return 'Please confirm your password';
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),

          Row(children: [
            Expanded(
              child: _SecondaryButton(
                label: 'Back',
                leadingIcon: Icons.arrow_back_rounded,
                onPressed: _prevStep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _PrimaryButton(
                label: 'Next Step',
                isLoading: false,
                enabled: true,
                primary: primary,
                onPressed: _nextStep,
                trailingIcon: Icons.arrow_forward_rounded,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ─── Step 3: Role-Specific + Terms ────────────────────────────────────────

  Widget _buildStep3(ThemeData theme, bool isDark, Color primary) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final coordinatorUploadLocked = _role == RegistrationRole.coordinator && _coordinatorUniversityId == null;

    final stepTitle = switch (_role) {
      RegistrationRole.student => 'Student Information',
      RegistrationRole.coordinator => 'University Information',
      RegistrationRole.hod => 'Department Information',
      RegistrationRole.supervisor => 'Company Information',
      null => '',
    };

    return Form(
      key: _step3Key,
      autovalidateMode: _step3Touched
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(stepTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_step3Subtitle, style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55))),
          const SizedBox(height: 24),

          ..._buildRoleFields(isDark, primary, isLoading),

          const SizedBox(height: 20),

          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                activeColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      style: theme.textTheme.bodySmall,
                      children: [
                        TextSpan(text: 'Terms of Service',
                            style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                        const TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy',
                            style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(children: [
            Expanded(
              child: _SecondaryButton(
                label: 'Back',
                leadingIcon: Icons.arrow_back_rounded,
                onPressed: _prevStep,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _PrimaryButton(
                label: 'Complete Registration',
                isLoading: isLoading,
                enabled: !isLoading && !coordinatorUploadLocked,
                primary: primary,
                onPressed: _submit,
                leadingIcon: Icons.check_rounded,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  String get _step3Subtitle => switch (_role) {
    RegistrationRole.student =>
      'Enter your academic details',
    RegistrationRole.coordinator =>
      'Enter your university details and upload official verification letter',
    RegistrationRole.hod =>
      'Select your university and enter your department',
    RegistrationRole.supervisor =>
      'Enter your company details',
    null => '',
  };

  List<Widget> _buildRoleFields(bool isDark, Color primary, bool isLoading) {
    bool orgSelected = switch (_role) {
      RegistrationRole.coordinator => _coordinatorUniversityId != null,
      _ => _selectedUniversityId != null,
    } || _organizationRequestId != null;

    final orgType = switch (_role) {
      RegistrationRole.supervisor => 'company',
      _ => 'university',
    };

    final filePicker = _buildFilePicker(isDark, primary,
      enabled: orgSelected,
      disabledMessage: 'Select a $orgType first to enable upload',
    );

    switch (_role) {
      case RegistrationRole.coordinator:
        return [
          _FieldLabel('University *'),
          const SizedBox(height: 8),
          // Searchable university picker with autocomplete
          _CoordinatorUniversityPicker(
            nameCtrl: _uniNameCtrl,
            isDark: isDark,
            primary: primary,
            enabled: !isLoading,
            requesterEmail: _emailCtrl.text,
            onUniversitySelected: (id) => setState(() => _coordinatorUniversityId = id),
          ),
          const SizedBox(height: 20),
          _FieldLabel('Official University Letter with Stamp *'),
          const SizedBox(height: 8),
          filePicker,
        ];

      case RegistrationRole.supervisor:
        return [
          _FieldLabel('Company/Organization Name *'),
          const SizedBox(height: 8),
          _InputField(
            controller: _companyCtrl,
            hint: 'e.g., Tech Solutions Inc.',
            icon: Icons.business_rounded,
            isDark: isDark,
            primary: primary,
            enabled: !isLoading,
            validator: (v) => (v ?? '').trim().isEmpty ? 'Company name is required' : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Role/Position *'),
          const SizedBox(height: 8),
          _InputField(
            controller: _positionCtrl,
            hint: 'e.g., Senior Engineer',
            icon: Icons.work_outline_rounded,
            isDark: isDark,
            primary: primary,
            enabled: !isLoading,
            validator: (v) => (v ?? '').trim().isEmpty ? 'Position is required' : null,
          ),
        ];

      case RegistrationRole.hod:
        return [
          _FieldLabel('University *'),
          const SizedBox(height: 8),
          _UniversityPicker(
            selectedId: _selectedUniversityId,
            selectedName: _selectedUniversityName,
            searchCtrl: _uniSearchCtrl,
            isOpen: _uniSearchOpen,
            isDark: isDark,
            primary: primary,
            requesterEmail: _emailCtrl.text.trim(),
            onToggle: () => setState(() => _uniSearchOpen = !_uniSearchOpen),
            onSelect: (u) => setState(() {
              _selectedUniversityId = u.id;
              _selectedUniversityName = u.name;
              _uniSearchOpen = false;
              _uniSearchCtrl.clear();
              _organizationRequestId = null;
            }),
            validator: (_) => (_selectedUniversityId == null && _organizationRequestId == null) 
                ? 'Please select a university' : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Department *'),
          const SizedBox(height: 8),
          _InputField(
            controller: _departmentCtrl,
            hint: 'e.g., Software Engineering',
            icon: Icons.school_outlined,
            isDark: isDark,
            primary: primary,
            enabled: !isLoading,
            validator: (v) => (v ?? '').trim().isEmpty ? 'Department is required' : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Employee ID (optional)'),
          const SizedBox(height: 8),
          _InputField(
            controller: _employeeIdCtrl,
            hint: 'e.g., EMP-2024-001',
            icon: Icons.badge_outlined,
            isDark: isDark,
            primary: primary,
            enabled: !isLoading,
          ),
          const SizedBox(height: 20),
          _FieldLabel('Staff ID / Verification Document *'),
          const SizedBox(height: 8),
          filePicker,
        ];

      case RegistrationRole.student:
        return [
          _FieldLabel('University *'),
          const SizedBox(height: 8),
          _UniversityPicker(
            selectedId: _selectedUniversityId,
            selectedName: _selectedUniversityName,
            searchCtrl: _uniSearchCtrl,
            isOpen: _uniSearchOpen,
            isDark: isDark,
            primary: primary,
            requesterEmail: _emailCtrl.text.trim(),
            onToggle: () => setState(() => _uniSearchOpen = !_uniSearchOpen),
            onSelect: (u) => setState(() {
              _selectedUniversityId = u.id;
              _selectedUniversityName = u.name;
              _selectedHodId = null;
              _uniSearchOpen = false;
              _uniSearchCtrl.clear();
              _organizationRequestId = null;
            }),
            validator: (_) => (_selectedUniversityId == null && _organizationRequestId == null)
                ? 'Please select a university' : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('Department *'),
          const SizedBox(height: 8),
          if (_selectedUniversityId != null)
            _DepartmentPicker(
              universityId: _selectedUniversityId!,
              selectedHodId: _selectedHodId,
              isDark: isDark,
              primary: primary,
              onSelect: (d) => setState(() => _selectedHodId = d.id),
              validator: (_) => _selectedHodId == null ? 'Please select a department' : null,
            )
          else
            _InputField(
              controller: TextEditingController(text: ''),
              hint: 'Select a university first',
              icon: Icons.school_outlined,
              isDark: isDark,
              primary: primary,
              enabled: false,
            ),
          const SizedBox(height: 16),
          _FieldLabel('Student ID *'),
          const SizedBox(height: 8),
          _InputField(
            controller: _studentIdCtrl,
            hint: 'e.g., 2122/142',
            icon: Icons.credit_card_rounded,
            isDark: isDark,
            primary: primary,
            enabled: !isLoading,
            validator: (v) => (v ?? '').trim().isEmpty ? 'Student ID is required' : null,
          ),
          const SizedBox(height: 20),
          _FieldLabel('Student ID / Verification *'),
          const SizedBox(height: 8),
          filePicker,
        ];

      default:
        return [];
    }
  }

  Widget _buildFilePicker(bool isDark, Color primary, {required bool enabled, String? disabledMessage}) {
    return _FilePicker(
      isDark: isDark,
      primary: primary,
      enabled: enabled,
      disabledMessage: disabledMessage,
      fileName: _verificationFileName,
      onPicked: (bytes, name) => setState(() {
        _verificationFileBytes = bytes;
        _verificationFileName = name;
      }),
      onRemoved: () => setState(() {
        _verificationFileBytes = null;
        _verificationFileName = null;
      }),
    );
  }
}

// ─── File Picker Widget ───────────────────────────────────────────────────────

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.isDark,
    required this.primary,
    required this.enabled,
    required this.fileName,
    required this.onPicked,
    required this.onRemoved,
    this.disabledMessage,
  });

  final bool isDark;
  final Color primary;
  final bool enabled;
  final String? fileName;
  final String? disabledMessage;
  final void Function(List<int> bytes, String name) onPicked;
  final VoidCallback onRemoved;

  Future<void> _pick(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final file = await picker.pickImage(source: ImageSource.gallery);
                if (file != null) {
                  final bytes = await file.readAsBytes();
                  onPicked(bytes, file.name);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final file = await picker.pickImage(source: ImageSource.camera);
                if (file != null) {
                  final bytes = await file.readAsBytes();
                  onPicked(bytes, file.name);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (fileName != null) {
      // File selected — show preview card
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: primary.withOpacity(isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.insert_drive_file_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fileName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Tap × to remove',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: onRemoved,
              color: Colors.grey.shade500,
              iconSize: 20,
            ),
          ],
        ),
      );
    }

    // No file — show upload zone
    return AbsorbPointer(
      absorbing: !enabled,
      child: GestureDetector(
        onTap: enabled ? () => _pick(context) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: enabled
                ? (isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF9FAFB))
                : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? (isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFD1D5DB))
                  : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD1D5DB)),
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.upload_rounded, size: 32, color: enabled ? Colors.grey.shade400 : Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                enabled ? 'Click to upload or take a photo' : (disabledMessage ?? 'Select a university first to enable upload'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: enabled ? (isDark ? Colors.white70 : const Color(0xFF374151)) : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 4),
              Text('PDF, JPG or PNG (max. 5MB)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text('Official document with institutional stamp required',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.primary});
  final int step;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final labels = ['Role Selection', 'Account Details', 'Verification'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Step $step of 3',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.grey, letterSpacing: 1.2)),
            Text(labels[step - 1].toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.grey, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: step / 3,
            backgroundColor: Colors.grey.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(primary),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.desc,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final RegistrationRole role;
  final String title;
  final String desc;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? primary.withOpacity(isDark ? 0.15 : 0.06)
                : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB)),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              if (!isDark && !selected)
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? primary : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22,
                    color: selected ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF6B7280))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: selected ? primary : null)),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: primary, size: 22)
              else
                Icon(Icons.radio_button_unchecked_rounded,
                    color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _UniversityPicker extends ConsumerStatefulWidget {
  const _UniversityPicker({
    required this.selectedId,
    required this.selectedName,
    required this.searchCtrl,
    required this.isOpen,
    required this.isDark,
    required this.primary,
    required this.onToggle,
    required this.onSelect,
    required this.requesterEmail,
    this.validator,
  });

  final int? selectedId;
  final String? selectedName;
  final TextEditingController searchCtrl;
  final bool isOpen;
  final bool isDark;
  final Color primary;
  final VoidCallback onToggle;
  final void Function(_University) onSelect;
  final String requesterEmail;
  final String? Function(String?)? validator;

  @override
  ConsumerState<_UniversityPicker> createState() => _UniversityPickerState();
}

class _UniversityPickerState extends ConsumerState<_UniversityPicker> {
  @override
  Widget build(BuildContext context) {
    final uniAsync = ref.watch(_approvedUniversitiesProvider);
    final query = widget.searchCtrl.text.toLowerCase();

    return FormField<String>(
      validator: widget.validator,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: field.hasError
                      ? const Color(0xFFEF4444)
                      : widget.isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_rounded, size: 18,
                      color: widget.isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.selectedName ?? 'Select your university',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: widget.selectedName != null
                            ? null
                            : (widget.isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                  Icon(widget.isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: Colors.grey),
                ],
              ),
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(field.errorText!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ),
          if (widget.isOpen)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: widget.isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: widget.searchCtrl,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search universities...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  uniAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (_, __) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Failed to load universities', style: TextStyle(color: Colors.red)),
                    ),
                    data: (unis) {
                      final filtered = unis
                          .where((u) => u.name.toLowerCase().contains(query))
                          .toList();
                      if (filtered.isEmpty) {
                        return Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No universities found',
                                  style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                            ),
                            const Divider(height: 1),
                            _buildRequestOption(),
                          ],
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                itemBuilder: (ctx, i) {
                                  final u = filtered[i];
                                  final isSelected = u.id == widget.selectedId;
                                  return ListTile(
                                    dense: true,
                                    title: Text(u.name,
                                        style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? widget.primary : null)),
                                    trailing: isSelected
                                        ? Icon(Icons.check_rounded, color: widget.primary, size: 18)
                                        : null,
                                    onTap: () => widget.onSelect(u),
                                  );
                                },
                              ),
                            ),
                            const Divider(height: 1),
                            _buildRequestOption(),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestOption() {
    return ListTile(
      dense: true,
      leading: Icon(Icons.add_circle_outline_rounded, color: widget.primary, size: 18),
      title: const Text('Can\'t find your organization? Request to add it',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      onTap: () async {
        widget.onToggle(); // Close the picker
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => _RequestOrganizationDialog(
            type: 'UNIVERSITY',
            isDark: widget.isDark,
            primary: widget.primary,
            requesterEmail: widget.requesterEmail,
          ),
        );
        if (result != null && mounted) {
          final requestId = result['id'] as int?;
          final fileBytes = result['fileBytes'] as List<int>?;
          final fileName = result['fileName'] as String?;

          final parent = context.findAncestorStateOfType<_RegisterScreenState>();
          if (parent != null) {
            parent.setState(() {
              parent._organizationRequestId = requestId;
              parent._selectedUniversityId = null;
              parent._selectedUniversityName = 'Request Pending...';
              if (fileBytes != null && parent._verificationFileBytes == null) {
                parent._verificationFileBytes = fileBytes;
                parent._verificationFileName = fileName;
              }
              parent._agreedToTerms = true;
            });
            Future.microtask(() => parent._submit());
          }
        }
      },
    );
  }
}

class _DepartmentPicker extends ConsumerWidget {
  const _DepartmentPicker({
    required this.universityId,
    required this.selectedHodId,
    required this.isDark,
    required this.primary,
    required this.onSelect,
    this.validator,
  });

  final int universityId;
  final int? selectedHodId;
  final bool isDark;
  final Color primary;
  final void Function(_Department) onSelect;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptAsync = ref.watch(_departmentsProvider(universityId));

    return FormField<String>(
      validator: validator,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          deptAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
              ),
              child: const Row(children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Loading departments...', style: TextStyle(color: Colors.grey)),
              ]),
            ),
            error: (_, __) => const Text('Failed to load departments',
                style: TextStyle(color: Colors.red)),
            data: (depts) {
              if (depts.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
                  ),
                  child: const Text('No departments available',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return DropdownButtonFormField<int>(
                value: selectedHodId,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.school_outlined, size: 18),
                  hintText: 'Select your department',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: field.hasError
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB))),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                items: depts
                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.department)))
                    .toList(),
                onChanged: (id) {
                  if (id != null) {
                    final dept = depts.firstWhere((d) => d.id == id);
                    onSelect(dept);
                  }
                },
                validator: (_) => selectedHodId == null ? 'Please select a department' : null,
              );
            },
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(field.errorText!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength, required this.primary});
  final int strength;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.red, Colors.orange, Colors.yellow.shade700, primary, Colors.green];
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
    required this.primary,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final Color primary;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF), fontSize: 14),
        prefixIcon: Icon(icon, size: 18,
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.primary,
    required this.onPressed,
    this.trailingIcon,
    this.leadingIcon,
  });

  final String label;
  final bool isLoading;
  final bool enabled;
  final Color primary;
  final VoidCallback onPressed;
  final IconData? trailingIcon;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: (isLoading || !enabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailingIcon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed, this.leadingIcon});
  final String label;
  final VoidCallback onPressed;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade600,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18),
              const SizedBox(width: 6),
            ],
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
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
          Icon(Icons.error_outline_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}

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

// ── Coordinator University Picker ─────────────────────────────────────────────
/// Searchable university picker for coordinator registration.
/// Fetches suggestions from /universities/search as the user types.
/// Shows duplicate warning if a very similar name already exists.
class _CoordinatorUniversityPicker extends StatefulWidget {
  const _CoordinatorUniversityPicker({
    required this.nameCtrl,
    required this.isDark,
    required this.primary,
    required this.enabled,
    required this.requesterEmail,
    this.onUniversitySelected,
  });

  final TextEditingController nameCtrl;
  final bool isDark;
  final Color primary;
  final bool enabled;
  final String requesterEmail;
  final ValueChanged<int?>? onUniversitySelected; // null = new request, int = existing ID

  @override
  State<_CoordinatorUniversityPicker> createState() => _CoordinatorUniversityPickerState();
}

class _CoordinatorUniversityPickerState extends State<_CoordinatorUniversityPicker> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;
  bool _showDropdown = false;
  String? _duplicateWarning;
  String? _selectedName;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() { _suggestions = []; _showDropdown = false; _duplicateWarning = null; });
      return;
    }
    setState(() => _loading = true);
    try {
      final dio = ApiClient(sessionService: AppSessionService()).dio;
      final res = await dio.get('/universities/search', queryParameters: {'q': q, 'limit': '8'});
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is Map && raw['data'] is List) list = raw['data'] as List;
      else if (raw is List) list = raw;
      setState(() {
        _suggestions = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _showDropdown = _suggestions.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; _showDropdown = false; });
    }
  }

  Future<void> _checkDuplicate(String name) async {
    if (name.trim().length < 3) return;
    try {
      final dio = ApiClient(sessionService: AppSessionService()).dio;
      final res = await dio.post('/universities/check-duplicate', data: {'name': name.trim()});
      final raw = res.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      if (data is Map) {
        final isDup = data['isDuplicate'] == true;
        final suggestions = (data['suggestions'] as List?) ?? [];
        if (isDup) {
          setState(() => _duplicateWarning = '⚠️ "${data['exactMatch']?['name']}" already exists. Select it from the list or contact admin.');
        } else if (suggestions.isNotEmpty) {
          final topName = suggestions.first['name'] as String? ?? '';
          setState(() => _duplicateWarning = '💡 Did you mean "$topName"?');
        } else {
          setState(() => _duplicateWarning = null);
        }
      }
    } catch (_) {
      setState(() => _duplicateWarning = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Search field
      TextFormField(
        controller: widget.nameCtrl,
        enabled: widget.enabled,
        onChanged: (v) {
          setState(() { _selectedName = null; _duplicateWarning = null; });
          // Clear selected ID when user types manually (new org request)
          widget.onUniversitySelected?.call(null);
          _search(v);
        },
        onEditingComplete: () => _checkDuplicate(widget.nameCtrl.text),
        validator: (v) => (v ?? '').trim().isEmpty ? 'University name is required' : null,
        decoration: InputDecoration(
          hintText: 'Search or type university name...',
          prefixIcon: Icon(Icons.account_balance_rounded, color: widget.primary, size: 20),
          suffixIcon: _loading
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
              : (_selectedName != null ? Icon(Icons.check_circle_rounded, color: Colors.green, size: 20) : null),
          filled: true,
          fillColor: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),

      // Suggestions dropdown
      if (_showDropdown && _suggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              ..._suggestions.map((u) {
                final name = u['name']?.toString() ?? '';
                final address = u['address']?.toString() ?? '';
                final id = u['id'] is int ? u['id'] as int : int.tryParse(u['id']?.toString() ?? '');
                return InkWell(
                  onTap: () {
                    widget.nameCtrl.text = name;
                    setState(() { _selectedName = name; _showDropdown = false; _duplicateWarning = null; });
                    widget.onUniversitySelected?.call(id);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      Icon(Icons.account_balance_rounded, size: 16, color: widget.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        if (address.isNotEmpty)
                          Text(address, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                      ])),
                      if (_selectedName == name)
                        Icon(Icons.check_rounded, size: 16, color: widget.primary),
                    ]),
                  ),
                );
              }),
              const Divider(height: 1),
              ListTile(
                dense: true,
                leading: Icon(Icons.add_circle_outline_rounded, color: widget.primary, size: 18),
                title: Text('Can\'t find your organization? Request to add it', 
                  style: TextStyle(color: widget.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                onTap: () async {
                  setState(() => _showDropdown = false);
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (ctx) => _RequestOrganizationDialog(
                      type: 'UNIVERSITY',
                      isDark: widget.isDark,
                      primary: widget.primary,
                      requesterEmail: widget.requesterEmail,
                    ),
                  );
                  if (result != null && mounted) {
                    final requestId = result['id'] as int?;
                    final fileBytes = result['fileBytes'] as List<int>?;
                    final fileName = result['fileName'] as String?;
                    
                    final parent = context.findAncestorStateOfType<_RegisterScreenState>();
                    if (parent != null) {
                      parent.setState(() {
                        parent._organizationRequestId = requestId;
                        parent._coordinatorUniversityId = null;
                        parent._uniNameCtrl.text = 'Request Pending...';
                        if (fileBytes != null && parent._verificationFileBytes == null) {
                          parent._verificationFileBytes = fileBytes;
                          parent._verificationFileName = fileName;
                        }
                        parent._agreedToTerms = true; // Auto-agree after request
                      });
                      // Auto-submit registration
                      Future.microtask(() => parent._submit());
                    }
                    setState(() {
                      _selectedName = 'Request Pending...';
                      widget.nameCtrl.text = 'Request Pending...';
                      _duplicateWarning = '✅ Request submitted! Finalizing registration...';
                    });
                    widget.onUniversitySelected?.call(null);
                  }
                },
              ),
            ],
          ),
        ),

      // "Not found" option when no suggestions
      if (_showDropdown && _suggestions.isEmpty && widget.nameCtrl.text.trim().length >= 2)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.add_circle_outline_rounded, color: widget.primary, size: 18),
            title: Text('Can\'t find your organization? Request to add it', 
              style: TextStyle(color: widget.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            onTap: () async {
              setState(() => _showDropdown = false);
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (ctx) => _RequestOrganizationDialog(
                  type: 'UNIVERSITY',
                  isDark: widget.isDark,
                  primary: widget.primary,
                  requesterEmail: widget.requesterEmail,
                ),
              );
              if (result != null && mounted) {
                final requestId = result['id'] as int?;
                final fileBytes = result['fileBytes'] as List<int>?;
                final fileName = result['fileName'] as String?;

                final parent = context.findAncestorStateOfType<_RegisterScreenState>();
                if (parent != null) {
                  parent.setState(() {
                    parent._organizationRequestId = requestId;
                    parent._coordinatorUniversityId = null;
                    parent._uniNameCtrl.text = 'Request Pending...';
                    if (fileBytes != null && parent._verificationFileBytes == null) {
                      parent._verificationFileBytes = fileBytes;
                      parent._verificationFileName = fileName;
                    }
                    parent._agreedToTerms = true;
                  });
                  Future.microtask(() => parent._submit());
                }
                setState(() {
                  _selectedName = 'Request Pending...';
                  widget.nameCtrl.text = 'Request Pending...';
                  _duplicateWarning = '✅ Request submitted! Finalizing registration...';
                });
                widget.onUniversitySelected?.call(null);
              }
            },
          ),
        ),

      // Duplicate warning
      if (_duplicateWarning != null)
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: Text(_duplicateWarning!, style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
        ),

      // Explicit "Not Found" option when no selection and text is not empty
      if (_selectedName == null && (context.findAncestorStateOfType<_RegisterScreenState>())?._organizationRequestId == null && widget.nameCtrl.text.trim().length >= 2)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            onTap: () async {
              setState(() => _showDropdown = false);
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (ctx) => _RequestOrganizationDialog(
                  type: 'UNIVERSITY',
                  isDark: widget.isDark,
                  primary: widget.primary,
                  requesterEmail: widget.requesterEmail,
                ),
              );
              if (result != null && mounted) {
                final requestId = result['id'] as int?;
                final fileBytes = result['fileBytes'] as List<int>?;
                final fileName = result['fileName'] as String?;

                final parent = context.findAncestorStateOfType<_RegisterScreenState>();
                if (parent != null) {
                  parent.setState(() {
                    parent._organizationRequestId = requestId;
                    parent._coordinatorUniversityId = null;
                    parent._uniNameCtrl.text = 'Request Pending...';
                    if (fileBytes != null && parent._verificationFileBytes == null) {
                      parent._verificationFileBytes = fileBytes;
                      parent._verificationFileName = fileName;
                    }
                    parent._agreedToTerms = true;
                  });
                  Future.microtask(() => parent._submit());
                }
                setState(() {
                  _selectedName = 'Request Pending...';
                  widget.nameCtrl.text = 'Request Pending...';
                  _duplicateWarning = '✅ Request submitted! Finalizing registration...';
                });
                widget.onUniversitySelected?.call(null);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: widget.primary, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Can\'t find your organization? Request to add it',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: widget.primary),
                ],
              ),
            ),
          ),
        ),
    ]);
  }
}

// ── Company Search Picker ─────────────────────────────────────────────────────
/// Searchable company picker for supervisor registration.
/// Fetches suggestions from /companies/search as the user types.
class _CompanySearchPicker extends StatefulWidget {
  const _CompanySearchPicker({
    required this.nameCtrl,
    required this.isDark,
    required this.primary,
    required this.enabled,
    required this.requesterEmail,
    this.onCompanySelected,
  });

  final TextEditingController nameCtrl;
  final bool isDark;
  final Color primary;
  final bool enabled;
  final String requesterEmail;
  final ValueChanged<int?>? onCompanySelected;

  @override
  State<_CompanySearchPicker> createState() => _CompanySearchPickerState();
}

class _CompanySearchPickerState extends State<_CompanySearchPicker> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;
  bool _showDropdown = false;
  String? _duplicateWarning;
  String? _selectedName;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() { _suggestions = []; _showDropdown = false; _duplicateWarning = null; });
      return;
    }
    setState(() => _loading = true);
    try {
      final dio = ApiClient(sessionService: AppSessionService()).dio;
      final res = await dio.get('/companies/search', queryParameters: {'q': q, 'limit': '8'});
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is Map && raw['data'] is List) list = raw['data'] as List;
      else if (raw is List) list = raw;
      setState(() {
        _suggestions = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _showDropdown = _suggestions.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; _showDropdown = false; });
    }
  }

  Future<void> _checkDuplicate(String name) async {
    if (name.trim().length < 3) return;
    try {
      final dio = ApiClient(sessionService: AppSessionService()).dio;
      final res = await dio.post('/companies/check-duplicate', data: {'name': name.trim()});
      final raw = res.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      if (data is Map) {
        final isDup = data['isDuplicate'] == true;
        final suggestions = (data['suggestions'] as List?) ?? [];
        if (isDup) {
          setState(() => _duplicateWarning = '⚠️ "${data['exactMatch']?['name']}" already exists. You will be linked to it automatically.');
        } else if (suggestions.isNotEmpty) {
          final topName = suggestions.first['name'] as String? ?? '';
          setState(() => _duplicateWarning = '💡 Did you mean "$topName"?');
        } else {
          setState(() => _duplicateWarning = null);
        }
      }
    } catch (_) {
      setState(() => _duplicateWarning = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: widget.nameCtrl,
        enabled: widget.enabled,
        onChanged: (v) {
          setState(() { _selectedName = null; _duplicateWarning = null; });
          widget.onCompanySelected?.call(null);
          _search(v);
        },
        onEditingComplete: () => _checkDuplicate(widget.nameCtrl.text),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Company name is required' : null,
        decoration: InputDecoration(
          hintText: 'Search or type company name...',
          prefixIcon: Icon(Icons.business_rounded, color: widget.primary, size: 20),
          suffixIcon: _loading
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
              : (_selectedName != null ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20) : null),
          filled: true,
          fillColor: widget.isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),

      if (_showDropdown && _suggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              ..._suggestions.map((c) {
                final name = c['name']?.toString() ?? '';
                final address = c['address']?.toString() ?? '';
                final id = c['id'] is int ? c['id'] as int : int.tryParse(c['id']?.toString() ?? '');
                return InkWell(
                  onTap: () {
                    widget.nameCtrl.text = name;
                    setState(() { _selectedName = name; _showDropdown = false; _duplicateWarning = null; });
                    widget.onCompanySelected?.call(id);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      Icon(Icons.business_rounded, size: 16, color: widget.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        if (address.isNotEmpty)
                          Text(address, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                      ])),
                      if (_selectedName == name)
                        Icon(Icons.check_rounded, size: 16, color: widget.primary),
                    ]),
                  ),
                );
              }),
              const Divider(height: 1),
              ListTile(
                dense: true,
                leading: Icon(Icons.add_circle_outline_rounded, color: widget.primary, size: 18),
                title: Text('Can\'t find your organization? Request to add it', 
                  style: TextStyle(color: widget.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                onTap: () async {
                  setState(() => _showDropdown = false);
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (ctx) => _RequestOrganizationDialog(
                      type: 'COMPANY',
                      isDark: widget.isDark,
                      primary: widget.primary,
                      requesterEmail: widget.requesterEmail,
                    ),
                  );
                  if (result != null && mounted) {
                    final requestId = result['id'] as int?;
                    final fileBytes = result['fileBytes'] as List<int>?;
                    final fileName = result['fileName'] as String?;

                    final parent = context.findAncestorStateOfType<_RegisterScreenState>();
                    if (parent != null) {
                      parent.setState(() {
                        parent._organizationRequestId = requestId;
                        parent._selectedCompanyId = null;
                        parent._companyCtrl.text = 'Request Pending...';
                        if (fileBytes != null && parent._verificationFileBytes == null) {
                          parent._verificationFileBytes = fileBytes;
                          parent._verificationFileName = fileName;
                        }
                        parent._agreedToTerms = true;
                      });
                      Future.microtask(() => parent._submit());
                    }
                    setState(() {
                      _selectedName = 'Request Pending...';
                      widget.nameCtrl.text = 'Request Pending...';
                      _duplicateWarning = '✅ Request submitted! Finalizing registration...';
                    });
                    widget.onCompanySelected?.call(null);
                  }
                },
              ),
            ],
          ),
        ),

      if (_showDropdown && _suggestions.isEmpty && widget.nameCtrl.text.trim().length >= 2)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.add_circle_outline_rounded, color: widget.primary, size: 18),
            title: Text('Can\'t find your organization? Request to add it', 
              style: TextStyle(color: widget.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            onTap: () async {
              setState(() => _showDropdown = false);
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (ctx) => _RequestOrganizationDialog(
                  type: 'COMPANY',
                  isDark: widget.isDark,
                  primary: widget.primary,
                  requesterEmail: widget.requesterEmail,
                ),
              );
              if (result != null && mounted) {
                final requestId = result['id'] as int?;
                final fileBytes = result['fileBytes'] as List<int>?;
                final fileName = result['fileName'] as String?;

                final parent = context.findAncestorStateOfType<_RegisterScreenState>();
                if (parent != null) {
                  parent.setState(() {
                    parent._organizationRequestId = requestId;
                    parent._selectedCompanyId = null;
                    parent._companyCtrl.text = 'Request Pending...';
                    if (fileBytes != null && parent._verificationFileBytes == null) {
                      parent._verificationFileBytes = fileBytes;
                      parent._verificationFileName = fileName;
                    }
                    parent._agreedToTerms = true;
                  });
                  Future.microtask(() => parent._submit());
                }
                setState(() {
                  _selectedName = 'Request Pending...';
                  widget.nameCtrl.text = 'Request Pending...';
                  _duplicateWarning = '✅ Request submitted! Finalizing registration...';
                });
                widget.onCompanySelected?.call(null);
              }
            },
          ),
        ),

      if (_duplicateWarning != null)
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: Text(_duplicateWarning!, style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
        ),

      // Explicit "Not Found" option when no selection and text is not empty
      if (_selectedName == null && (context.findAncestorStateOfType<_RegisterScreenState>())?._organizationRequestId == null && widget.nameCtrl.text.trim().length >= 2)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            onTap: () async {
              setState(() => _showDropdown = false);
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (ctx) => _RequestOrganizationDialog(
                  type: 'COMPANY',
                  isDark: widget.isDark,
                  primary: widget.primary,
                  requesterEmail: widget.requesterEmail,
                ),
              );
              if (result != null && mounted) {
                final requestId = result['id'] as int?;
                final fileBytes = result['fileBytes'] as List<int>?;
                final fileName = result['fileName'] as String?;

                final parent = context.findAncestorStateOfType<_RegisterScreenState>();
                if (parent != null) {
                  parent.setState(() {
                    parent._organizationRequestId = requestId;
                    parent._selectedCompanyId = null;
                    parent._companyCtrl.text = 'Request Pending...';
                    if (fileBytes != null && parent._verificationFileBytes == null) {
                      parent._verificationFileBytes = fileBytes;
                      parent._verificationFileName = fileName;
                    }
                    parent._agreedToTerms = true;
                  });
                  Future.microtask(() => parent._submit());
                }
                setState(() {
                  _selectedName = 'Request Pending...';
                  widget.nameCtrl.text = 'Request Pending...';
                  _duplicateWarning = '✅ Request submitted! Finalizing registration...';
                });
                widget.onCompanySelected?.call(null);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: widget.primary, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Can\'t find your organization? Request to add it',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: widget.primary),
                ],
              ),
            ),
          ),
        ),
    ]);
  }
}

// ── Request Organization Dialog ──────────────────────────────────────────────
class _RequestOrganizationDialog extends ConsumerStatefulWidget {
  const _RequestOrganizationDialog({
    required this.type,
    required this.isDark,
    required this.primary,
    required this.requesterEmail,
  });

  final String type; // 'UNIVERSITY' or 'COMPANY'
  final bool isDark;
  final Color primary;
  final String requesterEmail;

  @override
  ConsumerState<_RequestOrganizationDialog> createState() => _RequestOrganizationDialogState();
}

class _RequestOrganizationDialogState extends ConsumerState<_RequestOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  List<int>? _fileBytes;
  String? _fileName;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileBytes == null) {
      setState(() => _error = 'Verification document is required');
      return;
    }

    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      
      final fields = {
        'name': _nameCtrl.text.trim(),
        'type': widget.type,
        'address': _addressCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'requester_email': widget.requesterEmail,
      };

      final formData = FormData.fromMap({
        ...fields,
        'verification_doc': MultipartFile.fromBytes(_fileBytes!, filename: _fileName),
      });

      final res = await dio.post('/request', data: formData);
      final data = res.data;
      final responseData = data is Map ? data['data'] : null;
      final requestId = responseData is Map ? responseData['id'] : null;

      if (mounted) {
        Navigator.pop(context, {
          'id': requestId,
          'fileBytes': _fileBytes,
          'fileName': _fileName,
        });
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to submit request';
      setState(() { _error = msg; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Request New ${widget.type[0]}${widget.type.substring(1).toLowerCase()}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('If you can\'t find your organization, provide details and we will verify it.',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 20),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _Banner(message: _error!, isError: true),
                ),

              const _FieldLabel('Organization Name *'),
              const SizedBox(height: 8),
              _InputField(
                controller: _nameCtrl,
                hint: 'Official Name',
                icon: Icons.business_rounded,
                isDark: widget.isDark,
                primary: widget.primary,
                validator: (v) => (v ?? '').isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              const _FieldLabel('Address'),
              const SizedBox(height: 8),
              _InputField(
                controller: _addressCtrl,
                hint: 'City, Country',
                icon: Icons.location_on_rounded,
                isDark: widget.isDark,
                primary: widget.primary,
              ),
              const SizedBox(height: 16),

              const _FieldLabel('Verification Document *'),
              const SizedBox(height: 8),
              _FilePicker(
                isDark: widget.isDark,
                primary: widget.primary,
                enabled: true,
                fileName: _fileName,
                onPicked: (b, n) => setState(() { _fileBytes = b; _fileName = n; _error = null; }),
                onRemoved: () => setState(() { _fileBytes = null; _fileName = null; }),
              ),
              const SizedBox(height: 24),

              _PrimaryButton(
                label: 'Submit Request',
                isLoading: _loading,
                enabled: !_loading,
                primary: widget.primary,
                onPressed: _submit,
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
