import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// CommonFeedScreen has been moved to:
// lib/features/feed/presentation/common_feed_screen.dart

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildNotificationsAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _notificationItem(context, 'Weekly Plan Approved', 'Your supervisor approved your Week 4 plan.', '10m ago', Icons.check_circle_rounded, Colors.green),
                  _notificationItem(context, 'New Message', 'Abebe Bikila sent you a message.', '1h ago', Icons.chat_bubble_rounded, Colors.blue),
                  _notificationItem(context, 'System Alert', 'Please complete your profile details.', '2h ago', Icons.warning_rounded, Colors.orange),
                  _notificationItem(context, 'Meeting Invite', 'Final evaluation meeting scheduled for Friday.', '1d ago', Icons.event_rounded, Colors.purple),
                  _notificationItem(context, 'Document Verified', 'Your university letter has been verified.', '2d ago', Icons.verified_rounded, Colors.teal),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: const FlexibleSpaceBar(
        title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1)),
        centerTitle: true,
      ),
      actions: [
        IconButton(icon: const Icon(Icons.done_all_rounded), onPressed: () {}),
      ],
    );
  }

  Widget _notificationItem(BuildContext context, String title, String body, String time, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10))]),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildChatHeader(context),
            _buildSearchBar(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _conversationItem(context, 'Abebe Bikila', 'Can you review my proposal?', '10:45 AM', 2, true),
                  _conversationItem(context, 'Dr. Sarah Smith', 'Your internship has been approved.', 'Yesterday', 0, false),
                  _conversationItem(context, 'Hana Worku', 'Meet you at the workshop.', 'Wed', 0, true),
                  _conversationItem(context, 'Coordinator (Admin)', 'Please update your contact info.', '24 May', 1, false),
                  _conversationItem(context, 'Supervisor Support', 'Evaluation results are ready.', '12 May', 0, false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            const Text('Messages', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const Spacer(),
            CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.add_rounded, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: const TextField(
          decoration: InputDecoration(hintText: 'Search conversations...', border: InputBorder.none, prefixIcon: Icon(Icons.search_rounded, size: 20)),
        ),
      ),
    );
  }

  Widget _conversationItem(BuildContext context, String name, String lastMsg, String time, int unread, bool isOnline) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 28, child: Text(name[0])),
              if (isOnline)
                Positioned(right: 0, bottom: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: Text(lastMsg, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (unread > 0)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)), child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
