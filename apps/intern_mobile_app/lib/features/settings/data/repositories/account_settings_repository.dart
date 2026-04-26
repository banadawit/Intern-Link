import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../app_entry/data/models/current_user_model.dart';

class AccountSettingsRepository {
  AccountSettingsRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<CurrentUserModel> getCurrentUser() async {
    final response = await apiClient.dio.get('/auth/me');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CurrentUserModel.fromJson(data);
    }
    throw Exception('Invalid profile response');
  }

  Future<CurrentUserModel> updateProfile({required String fullName, String? email}) async {
    final payload = <String, String>{
      'fullName': fullName.trim(),
    };
    if (email != null && email.trim().isNotEmpty) {
      payload['email'] = email.trim();
    }

    final response = await apiClient.dio.patch('/auth/me', data: payload);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return CurrentUserModel.fromJson(data);
    }
    throw Exception('Invalid update profile response');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

final accountSettingsRepositoryProvider = Provider<AccountSettingsRepository>((ref) {
  return AccountSettingsRepository(apiClient: ref.watch(apiClientProvider));
});
