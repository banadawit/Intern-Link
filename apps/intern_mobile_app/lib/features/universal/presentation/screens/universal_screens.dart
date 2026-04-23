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
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              _buildChatHeader(context, isDark),
              _buildSearchBar(context, isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _conversationItem(context, 'Abebe Bikila', 'Can you review my proposal?', '10:45 AM', 2, true, isDark),
                    _conversationItem(context, 'Dr. Sarah Smith', 'Your internship has been approved.', 'Yesterday', 0, false, isDark),
                    _conversationItem(context, 'Hana Worku', 'Meet you at the workshop.', 'Wed', 0, true, isDark),
                    _conversationItem(context, 'Coordinator (Admin)', 'Please update your contact info.', '24 May', 1, false, isDark),
                    _conversationItem(context, 'Supervisor Support', 'Evaluation results are ready.', '12 May', 0, false, isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context, bool isDark) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Messages',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 15, fontWeight: FontWeight.w500),
            border: InputBorder.none,
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.search_rounded, size: 22, color: isDark ? Colors.white54 : Colors.black45),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _conversationItem(BuildContext context, String name, String lastMsg, String time, int unread, bool isOnline, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        color: unread > 0 ? const Color(0xFF0EA5E9) : (isDark ? Colors.white54 : Colors.black45),
                        fontSize: 12,
                        fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMsg,
                        style: TextStyle(
                          color: unread > 0 ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white60 : Colors.black54),
                          fontSize: 14,
                          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
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
