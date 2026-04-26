enum AppRole {
  student,
  supervisor,
  coordinator,
  admin,
  hod,
}

extension AppRoleX on AppRole {
  String get backendValue {
    switch (this) {
      case AppRole.student:
        return 'STUDENT';
      case AppRole.supervisor:
        return 'SUPERVISOR';
      case AppRole.coordinator:
        return 'COORDINATOR';
      case AppRole.admin:
        return 'ADMIN';
      case AppRole.hod:
        return 'HEAD_OF_DEPARTMENT';
    }
  }
}

AppRole? appRoleFromBackend(String value) {
  switch (value.toUpperCase()) {
    case 'STUDENT':
      return AppRole.student;
    case 'SUPERVISOR':
      return AppRole.supervisor;
    case 'COORDINATOR':
      return AppRole.coordinator;
    case 'ADMIN':
      return AppRole.admin;
    case 'HEAD_OF_DEPARTMENT':
    case 'HEAD OF DEPARTMENT':
    case 'HOD':
      return AppRole.hod;
    default:
      return null;
  }
}
