import '../../domain/entities/app_role.dart';

class RoleProfile {
  const RoleProfile({
    this.phoneNumber,
    this.department,
    this.studentId,
    this.universityName,
    this.companyName,
  });

  final String? phoneNumber;
  final String? department;
  final String? studentId;
  final String? universityName;
  final String? companyName;

  factory RoleProfile.fromJson(Map<String, dynamic> json) {
    return RoleProfile(
      phoneNumber: json['phoneNumber']?.toString(),
      department: json['department']?.toString(),
      studentId: json['studentId']?.toString(),
      universityName: json['universityName']?.toString(),
      companyName: json['companyName']?.toString(),
    );
  }

  static const empty = RoleProfile();
}

class CurrentUserModel {
  const CurrentUserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.profile = RoleProfile.empty,
  });

  final int id;
  final String email;
  final String fullName;
  final AppRole role;
  final RoleProfile profile;

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json; // Handle wrapped or unwrapped
    final rawRole = (data['role'] ?? '').toString();
    final role = appRoleFromBackend(rawRole);
    if (role == null) {
      throw const FormatException('Unknown user role from backend.');
    }

    final rawProfile = data['profile'];
    final profile = (rawProfile is Map<String, dynamic>)
        ? RoleProfile.fromJson(rawProfile)
        : RoleProfile.empty;

    return CurrentUserModel(
      id: data['id'] ?? 0,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? data['full_name'] ?? 'User',
      role: role,
      profile: profile,
    );
  }
}
