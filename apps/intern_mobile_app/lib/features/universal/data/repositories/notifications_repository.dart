import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class NotificationModel {
  final int id;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _safeInt(json['id']),
      message: json['message'] as String? ?? 'No message',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

int _safeInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

class NotificationsRepository {
  final ApiClient apiClient;

  NotificationsRepository({required this.apiClient});

  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.dio.get('/notifications');
    final data = response.data;
    if (data is List) {
      return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> markAllAsRead() async {
    await apiClient.dio.patch('/notifications/read-all');
  }

  Future<void> markAsRead(int id) async {
    await apiClient.dio.patch('/notifications/$id/read');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getNotifications();
});
