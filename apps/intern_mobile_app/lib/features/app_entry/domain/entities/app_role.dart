enum AppRole {
  student,
  supervisor,
  coordinator,
  admin,
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
    default:
      return null;
  }
}
