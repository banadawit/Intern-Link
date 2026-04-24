import '../../domain/entities/app_role.dart';

class CurrentUserModel {
  const CurrentUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final int id;
  final String email;
  final String fullName;
  final AppRole role;

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json; // Handle wrapped or unwrapped
    final rawRole = (data['role'] ?? '').toString();
    final role = appRoleFromBackend(rawRole);
    if (role == null) {
      throw const FormatException('Unknown user role from backend.');
    }

    return CurrentUserModel(
      id: data['id'] ?? 0,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? data['full_name'] ?? 'User',
      role: role,
    );
  }
}
