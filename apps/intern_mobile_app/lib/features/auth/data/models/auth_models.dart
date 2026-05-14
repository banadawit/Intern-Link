enum RegistrationRole { student, coordinator, hod, supervisor }

extension RegistrationRoleX on RegistrationRole {
  String get backendValue {
    switch (this) {
      case RegistrationRole.student:
        return 'STUDENT';
      case RegistrationRole.coordinator:
        return 'COORDINATOR';
      case RegistrationRole.hod:
        return 'HOD';
      case RegistrationRole.supervisor:
        return 'SUPERVISOR';
    }
  }

  String get label {
    switch (this) {
      case RegistrationRole.student:
        return 'Student';
      case RegistrationRole.coordinator:
        return 'Coordinator';
      case RegistrationRole.hod:
        return 'Head of Department';
      case RegistrationRole.supervisor:
        return 'Supervisor';
    }
  }
}

class LoginResult {
  const LoginResult({required this.token, this.mustChangePassword = false});
  final String token;
  final bool mustChangePassword;
}

class RegisterPayload {
  const RegisterPayload({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.universityName,
    this.companyName,
    this.department,
    this.studentId,
    this.position,
    this.universityId,
    this.companyId,
    this.hodId,
    this.employeeId,
    this.organizationRequestId,
    this.verificationFileBytes,
    this.verificationFileName,
  });

  final String fullName;
  final String email;
  final String password;
  final RegistrationRole role;
  final String? universityName;
  final String? companyName;
  final String? department;
  final String? studentId;
  final String? position;
  final int? universityId;
  final int? companyId;
  final int? hodId;
  final String? employeeId;
  final int? organizationRequestId;
  /// Raw bytes of the verification document
  final List<int>? verificationFileBytes;
  final String? verificationFileName;
}
