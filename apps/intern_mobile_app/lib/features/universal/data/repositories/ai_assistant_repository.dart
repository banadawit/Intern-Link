import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class AiMessageModel {
  final String speaker; // 'user' | 'assistant'
  final String content;

  AiMessageModel({required this.speaker, required this.content});

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    // Backend history uses 'role' field; in-memory messages use 'speaker'
    final speaker = (json['speaker'] ?? json['role'] ?? 'user').toString();
    return AiMessageModel(
      speaker: speaker == 'assistant' ? 'assistant' : 'user',
      content: json['content']?.toString() ?? '',
    );
  }
}

class AiAssistantRepository {
  final ApiClient apiClient;

  AiAssistantRepository({required this.apiClient});

  Future<List<AiMessageModel>> getHistory() async {
    try {
      final response = await apiClient.dio.get('/ai/chat/history');
      final data = response.data;
      // After interceptor unwrap: data = { messages: [...] }
      List? messages;
      if (data is Map) {
        messages = (data['messages'] ?? data['data']?['messages']) as List?;
      }
      if (messages == null || messages.isEmpty) return [];
      return messages
          .map((e) => AiMessageModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<AiMessageModel> sendMessage(
    String message, {
    List<AiMessageModel> history = const [],
  }) async {
    // Build history payload — exclude the welcome message and the current message
    // (the current message is sent separately as 'message', not in history)
    final historyPayload = history
        .where((m) =>
            m.content != 'Hello! I am your Intern-Link AI Assistant. How can I help you today?' &&
            m.content != message)
        .map((m) => {
              'role': m.speaker == 'assistant' ? 'assistant' : 'user',
              'content': m.content,
            })
        .toList();

    final response = await apiClient.dio.post('/ai/chat', data: {
      'message': message,
      if (historyPayload.isNotEmpty) 'history': historyPayload,
    });

    final data = response.data;
    // After interceptor unwrap: data = { reply: "..." }
    String? reply;
    if (data is Map) {
      reply = data['reply']?.toString()?.trim();
      if (reply == null || reply.isEmpty) {
        reply = data['data']?['reply']?.toString()?.trim();
      }
    }

    return AiMessageModel(
      speaker: 'assistant',
      content: (reply != null && reply.isNotEmpty)
          ? reply
          : 'I could not generate a response right now. Please try again.',
    );
  }

  Future<void> clearHistory() async {
    await apiClient.dio.delete('/ai/chat/history');
  }
}

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepository(apiClient: ref.watch(apiClientProvider));
});

final aiChatHistoryProvider = FutureProvider.autoDispose<List<AiMessageModel>>((ref) async {
  return ref.watch(aiAssistantRepositoryProvider).getHistory();
});
