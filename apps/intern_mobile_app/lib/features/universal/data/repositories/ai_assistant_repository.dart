import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class AiMessageModel {
  final String speaker;
  final String content;

  AiMessageModel({
    required this.speaker,
    required this.content,
  });

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      speaker: json['speaker'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
    );
  }
}

class AiAssistantRepository {
  final ApiClient apiClient;

  AiAssistantRepository({required this.apiClient});

  Future<List<AiMessageModel>> getHistory() async {
    final response = await apiClient.dio.get('/ai/chat/history');
    final data = response.data;
    if (data is Map && data['messages'] is List) {
      final messages = data['messages'] as List;
      return messages
          .map((e) => AiMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<AiMessageModel> sendMessage(
    String message, {
    List<AiMessageModel> history = const [],
  }) async {
    // Build conversation history for context (exclude the welcome message)
    final historyPayload = history
        .where((m) => m.content != 'Hello! I am your Intern-Link AI Assistant. How can I help you today?')
        .map((m) => {'role': m.speaker == 'assistant' ? 'assistant' : 'user', 'content': m.content})
        .toList();

    final response = await apiClient.dio.post('/ai/chat', data: {
      'message': message,
      if (historyPayload.isNotEmpty) 'history': historyPayload,
    });

    final data = response.data;
    // After apiClient interceptor unwraps success wrapper, data = { reply: "..." }
    String? reply;
    if (data is Map) {
      reply = (data['reply'] as String?)?.trim();
      // Fallback: sometimes nested under data key
      if (reply == null || reply.isEmpty) {
        final inner = data['data'];
        if (inner is Map) reply = (inner['reply'] as String?)?.trim();
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
