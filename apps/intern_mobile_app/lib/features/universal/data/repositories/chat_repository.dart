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

class ChatPartner {
  final int id;
  final String fullName;
  final String role;

  ChatPartner({required this.id, required this.fullName, required this.role});

  factory ChatPartner.fromJson(Map<String, dynamic> json) {
    return ChatPartner(
      id: _safeInt(json['id']),
      fullName: json['full_name'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'USER',
    );
  }
}

class ChatMessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _safeInt(json['id']),
      senderId: _safeInt(json['senderId']),
      receiverId: _safeInt(json['receiverId']),
      content: json['content'] as String? ?? '',
      isRead: _safeBool(json['is_read']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ConversationModel {
  final ChatPartner partner;
  final ChatMessageModel? lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.partner,
    this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      partner: ChatPartner.fromJson(json['partner'] ?? {}),
      lastMessage: json['lastMessage'] != null ? ChatMessageModel.fromJson(json['lastMessage']) : null,
      unreadCount: _safeInt(json['unreadCount']),
    );
  }
}

class ChatRepository {
  final ApiClient apiClient;

  ChatRepository({required this.apiClient});

  Future<List<ConversationModel>> getConversations() async {
    final response = await apiClient.dio.get('/chat/conversations');
    final data = response.data;
    if (data is List) {
      return data.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<ChatMessageModel>> getMessages(int partnerId) async {
    final response = await apiClient.dio.get('/chat/$partnerId');
    final data = response.data;
    if (data is List) {
      return data.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<ChatPartner>> getContacts() async {
    final response = await apiClient.dio.get('/chat/contacts');
    final data = response.data;
    if (data is List) {
      return data.map((e) => ChatPartner.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> sendMessage(int partnerId, String content) async {
    await apiClient.dio.post('/chat/$partnerId', data: {'content': content});
  }

  Future<void> editMessage(int messageId, String content) async {
    await apiClient.dio.patch('/chat/message/$messageId', data: {'content': content});
  }

  Future<void> deleteMessage(int messageId) async {
    await apiClient.dio.delete('/chat/message/$messageId');
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(apiClient: ref.watch(apiClientProvider));
});

final conversationsProvider = FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  return ref.watch(chatRepositoryProvider).getConversations();
});

final contactsProvider = FutureProvider.autoDispose<List<ChatPartner>>((ref) async {
  return ref.watch(chatRepositoryProvider).getContacts();
});

final chatMessagesProvider = FutureProvider.autoDispose.family<List<ChatMessageModel>, int>((ref, partnerId) async {
  return ref.watch(chatRepositoryProvider).getMessages(partnerId);
});
