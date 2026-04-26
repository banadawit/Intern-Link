import 'package:flutter/material.dart';

import '../../data/models/auth_models.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.universityNameController,
    required this.companyNameController,
    required this.departmentController,
    required this.universityIdController,
    required this.hodIdController,
    required this.employeeIdController,
    required this.studentIdController,
    required this.positionController,
    required this.role,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onRoleChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController universityNameController;
  final TextEditingController companyNameController;
  final TextEditingController departmentController;
  final TextEditingController universityIdController;
  final TextEditingController hodIdController;
  final TextEditingController employeeIdController;
  final TextEditingController studentIdController;
  final TextEditingController positionController;
  final RegistrationRole role;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final ValueChanged<RegistrationRole> onRoleChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<RegistrationRole>(
            value: role,
            onChanged: isLoading
                ? null
                : (value) {
                    if (value != null) {
                      onRoleChanged(value);
                    }
                  },
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: RegistrationRole.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: fullNameController,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: isLoading ? null : onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                onPressed: isLoading ? null : onToggleConfirmPassword,
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if ((value ?? '').isEmpty) {
                return 'Please confirm your password';
              }
              if (value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          ..._buildRoleFields(),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Register'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRoleFields() {
    switch (role) {
      case RegistrationRole.coordinator:
        return [
          const SizedBox(height: 14),
          TextFormField(
            controller: universityNameController,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'University name',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'University name is required for coordinator';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: positionController,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Position (optional)',
              prefixIcon: Icon(Icons.work_outline_rounded),
            ),
          ),
        ];
      case RegistrationRole.supervisor:
        return [
          const SizedBox(height: 14),
          TextFormField(
            controller: companyNameController,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Company name',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Company name is required for supervisor';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: positionController,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Position (optional)',
              prefixIcon: Icon(Icons.work_outline_rounded),
            ),
          ),
        ];
      case RegistrationRole.hod:
        return [
          const SizedBox(height: 14),
          TextFormField(
            controller: universityIdController,
            enabled: !isLoading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'University ID',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
            validator: _validatePositiveInt,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: departmentController,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Department',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Department is required for HOD';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: employeeIdController,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Employee ID (optional)',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
        ];
      case RegistrationRole.student:
        return [
          const SizedBox(height: 14),
          TextFormField(
            controller: universityIdController,
            enabled: !isLoading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'University ID',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
            validator: _validatePositiveInt,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: hodIdController,
            enabled: !isLoading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'HoD ID (optional)',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: _validateOptionalPositiveInt,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: studentIdController,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Student ID (optional)',
              prefixIcon: Icon(Icons.credit_card_rounded),
            ),
          ),
        ];
    }
  }

  String? _validateEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Email is required';
    }

    const pattern = r'^[^\s@]+@([^\s@]+\.)+[^\s@]+$';
    if (!RegExp(pattern).hasMatch(input)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Password is required';
    }
    if (input.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validatePositiveInt(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'This field is required';
    }

    final parsed = int.tryParse(input);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  String? _validateOptionalPositiveInt(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(input);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }
}
