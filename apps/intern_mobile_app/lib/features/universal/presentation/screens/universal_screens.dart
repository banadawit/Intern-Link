import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommonFeedScreen extends ConsumerWidget {
  const CommonFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Common Feed')),
      body: const Center(child: Text('Common Feed Interface Pending')),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications Interface Pending')),
    );
  }
}

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages / Chat')),
      body: const Center(child: Text('Chat Interface Pending')),
    );
  }
}

class AiMessagesNotifier extends Notifier<List<Map<String, String>>> {
  @override
  List<Map<String, String>> build() {
    return [
      {'role': 'assistant', 'text': 'Hello! I am your Intern-Link AI Assistant. How can I help you today?'}
    ];
  }

  void sendMessage(String text) {
    state = [
      ...state,
      {'role': 'user', 'text': text},
    ];

    // Simulated "Advanced" response delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      state = [
        ...state,
        {'role': 'assistant', 'text': 'I am currently processing your request about \"$text\". As an advanced AI, I can help you find the best internships and optimize your profile!'},
      ];
    });
  }
}

final aiMessagesProvider = NotifierProvider<AiMessagesNotifier, List<Map<String, String>>>(() => AiMessagesNotifier());

class AiAssistantScreen extends ConsumerWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(aiMessagesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = TextEditingController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
              : [const Color(0xFF8E2DE2).withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Gradient Header Background for AppBar area
            Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isUser 
                          ? const Color(0xFF4A00E0) 
                          : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                          bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(20),
                        ),
                        boxShadow: [
                          if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          final text = controller.text.trim();
                          if (text.isNotEmpty) {
                            ref.read(aiMessagesProvider.notifier).sendMessage(text);
                            controller.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        ref.read(aiMessagesProvider.notifier).sendMessage(text);
                        controller.clear();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0xFF4A00E0), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
