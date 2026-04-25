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

  Future<AiMessageModel> sendMessage(String message) async {
    final response = await apiClient.dio.post('/ai/chat', data: {'message': message});
    final data = response.data;
    final reply = data is Map ? (data['reply'] as String?) : null;
    return AiMessageModel(
      speaker: 'assistant',
      content: (reply != null && reply.trim().isNotEmpty)
          ? reply
          : 'I could not generate a response right now.',
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
