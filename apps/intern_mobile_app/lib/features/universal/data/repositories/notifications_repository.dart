import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

int _safeInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

bool _safeBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return false;
}

class NotificationModel {
  final int id;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _safeInt(json['id']),
      message: json['message']?.toString() ?? 'No message',
      isRead: _safeBool(json['is_read']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationsRepository {
  final ApiClient apiClient;

  NotificationsRepository({required this.apiClient});

  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.dio.get('/notifications');
    final raw = response.data;
    // After interceptor unwrap: raw = [...] (list)
    final list = raw is List ? raw : (raw is Map ? raw['data'] ?? [] : []);
    return (list as List)
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await apiClient.dio.get('/notifications/unread-count');
    final raw = response.data;
    // After interceptor unwrap: raw = { count: N }
    return _safeInt(raw is Map ? raw['count'] : raw);
  }

  Future<void> markAllAsRead() async {
    await apiClient.dio.patch('/notifications/read-all');
  }

  Future<void> markAsRead(int id) async {
    await apiClient.dio.patch('/notifications/$id/read');
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});

/// Full notification list — used by the notifications screen
final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getNotifications();
});

/// Unread count only — used for the badge in the app bar
/// Kept separate so marking as read can update it cheaply
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getUnreadCount();
});
