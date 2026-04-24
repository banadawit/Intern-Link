import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class ChatPartner {
  final int id;
  final String fullName;
  final String role;

  ChatPartner({required this.id, required this.fullName, required this.role});

  factory ChatPartner.fromJson(Map<String, dynamic> json) {
    return ChatPartner(
      id: json['id'] as int,
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
      id: json['id'] as int? ?? 0,
      senderId: json['senderId'] as int? ?? 0,
      receiverId: json['receiverId'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
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
      unreadCount: json['unreadCount'] as int? ?? 0,
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

  Future<void> sendMessage(int partnerId, String content) async {
    await apiClient.dio.post('/chat/$partnerId', data: {'content': content});
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(apiClient: ref.watch(apiClientProvider));
});

final conversationsProvider = FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  return ref.watch(chatRepositoryProvider).getConversations();
});
