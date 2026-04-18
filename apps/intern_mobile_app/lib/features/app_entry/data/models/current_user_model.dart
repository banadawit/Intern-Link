import '../../domain/entities/app_role.dart';

class CurrentUserModel {
  const CurrentUserModel({required this.role});

  final AppRole role;

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] ?? '').toString();
    final role = appRoleFromBackend(rawRole);
    if (role == null) {
      throw const FormatException('Unknown user role from backend.');
    }

    return CurrentUserModel(role: role);
  }
}
