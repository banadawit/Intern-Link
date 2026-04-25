import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../data/repositories/notifications_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/ai_assistant_repository.dart';

// NotificationsScreen
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsRepositoryProvider).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsProvider);

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
            notificationsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error loading notifications: $err'))),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No notifications', style: TextStyle(color: Colors.grey))),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final notif = notifications[index];
                        final msg = notif.message;
                        
                        IconData icon = Icons.notifications_rounded;
                        Color color = Colors.blue;
                        String title = 'Notification';
                        
                        if (msg.contains('[ADMIN_ALERT]')) {
                          icon = Icons.admin_panel_settings_rounded;
                          color = Colors.orange;
                          title = 'Admin Alert';
                        } else if (msg.contains('[SECURITY_ALERT]')) {
                          icon = Icons.security_rounded;
                          color = Colors.red;
                          title = 'Security Alert';
                        } else if (msg.contains('[SYSTEM_ALERT]')) {
                          icon = Icons.settings_suggest_rounded;
                          color = Colors.purple;
                          title = 'System Alert';
                        } else if (msg.contains('📢')) {
                          icon = Icons.campaign_rounded;
                          color = Colors.indigo;
                          title = 'Announcement';
                        }
                        
                        final cleanMsg = msg
                            .replaceFirst('[ADMIN_ALERT] ', '')
                            .replaceFirst('[SECURITY_ALERT] ', '')
                            .replaceFirst('[SYSTEM_ALERT] ', '');

                        return _notificationItem(
                          context,
                          title,
                          cleanMsg,
                          timeago.format(notif.createdAt),
                          icon,
                          color,
                          notif.isRead,
                        );
                      },
                      childCount: notifications.length,
                    ),
                  ),
                );
              },
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
        IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(notificationsProvider)),
      ],
    );
  }

  Widget _notificationItem(BuildContext context, String title, String body, String time, IconData icon, Color color, bool isRead) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead 
            ? (isDark ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.5))
            : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
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
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))), 
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10))
                ]),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: isRead ? Colors.grey : (isDark ? Colors.white : Colors.black87), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  int _currentIndex = 0; // 0 for Chats, 1 for Contacts

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final conversationsAsync = ref.watch(conversationsProvider);
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned(
            top: -100, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF0EA5E9).withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildChatHeader(context, isDark, ref),
              _buildSearchBar(context, isDark),
              _buildTabSelector(isDark),
              Expanded(
                child: _currentIndex == 0 
                  ? conversationsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (conversations) {
                        if (conversations.isEmpty) {
                           return const Center(child: Text('No conversations yet', style: TextStyle(color: Colors.grey)));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            return _conversationItem(
                              context,
                              conv.partner.fullName,
                              conv.lastMessage?.content ?? '',
                              conv.lastMessage != null ? timeago.format(conv.lastMessage!.createdAt) : '',
                              conv.unreadCount,
                              true,
                              isDark,
                              onTap: () => _openChatDetail(context, conv.partner),
                            );
                          },
                        );
                      },
                    )
                  : contactsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (contacts) {
                        if (contacts.isEmpty) {
                           return const Center(child: Text('No contacts found', style: TextStyle(color: Colors.grey)));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            return _contactItem(
                              context,
                              contact.fullName,
                              contact.role,
                              isDark,
                              onTap: () => _openChatDetail(context, contact),
                            );
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _tabButton(0, 'Recent Chats', Icons.chat_bubble_rounded, isDark),
            _tabButton(1, 'Contacts', Icons.people_rounded, isDark),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected && !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactItem(BuildContext context, String name, String role, bool isDark, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF0EA5E9).withOpacity(0.8), const Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(role, style: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatDetail(BuildContext context, ChatPartner partner) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ChatDetailScreen(partner: partner),
      ),
    );
  }

  Widget _buildChatHeader(BuildContext context, bool isDark, WidgetRef ref) {
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
            GestureDetector(
              onTap: () {
                ref.invalidate(conversationsProvider);
                ref.invalidate(contactsProvider);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
              ),
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
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
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

  Widget _conversationItem(BuildContext context, String name, String lastMsg, String time, int unread, bool isOnline, bool isDark, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [const Color(0xFF0EA5E9), const Color(0xFF6366F1).withOpacity(0.8)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF0A1628) : Colors.white, width: 2),
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
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(lastMsg, style: TextStyle(color: unread > 0 ? (isDark ? Colors.white : Colors.black) : Colors.grey, fontSize: 14, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(10)),
                  child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatPartner partner;
  const ChatDetailScreen({super.key, required this.partner});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _editingMessageId;
  bool get _isEditing => _editingMessageId != null;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.partner.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(widget.partner.fullName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.partner.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.partner.role, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(chatMessagesProvider(widget.partner.id))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('No messages yet. Say hello!', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final m = messages[i];
                    final isMe = m.senderId != widget.partner.id;
                    return _chatBubble(m, isMe, isDark);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _chatBubble(ChatMessageModel m, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: isMe ? () => _showMessageOptions(m) : null,
            onDoubleTap: isMe ? () {
              setState(() {
                _editingMessageId = m.id;
                _controller.text = m.content;
              });
            } : null,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF0EA5E9) : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                ),
                boxShadow: [if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                border: !isMe ? Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)) : null,
              ),
              child: Text(
                m.content, 
                style: TextStyle(
                  color: isMe || isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.3,
                )
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(timeago.format(m.createdAt), style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(ChatMessageModel m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            _actionTile(Icons.edit_rounded, 'Edit Message', Colors.blue, () {
              Navigator.pop(ctx);
              setState(() {
                _editingMessageId = m.id;
                _controller.text = m.content;
              });
            }),
            const SizedBox(height: 12),
            _actionTile(Icons.delete_rounded, 'Delete Message', Colors.red, () async {
              Navigator.pop(ctx);
              final confirm = await _showDeleteConfirm();
              if (confirm) {
                _delete(m.id);
              }
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirm() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1628) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0EA5E9)),
                  const SizedBox(width: 8),
                  const Text('Editing message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _editingMessageId = null;
                      _controller.clear();
                    }),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_isEditing ? Icons.check_rounded : Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    final repo = ref.read(chatRepositoryProvider);
    final editingId = _editingMessageId;
    
    _controller.clear();
    setState(() => _editingMessageId = null);
    
    try {
      if (editingId != null) {
        await repo.editMessage(editingId, text);
      } else {
        await repo.sendMessage(widget.partner.id, text);
      }
      ref.invalidate(chatMessagesProvider(widget.partner.id));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process: $e')));
    }
  }

  void _delete(int messageId) async {
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(messageId);
      ref.invalidate(chatMessagesProvider(widget.partner.id));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }
}

class AiMessagesNotifier extends AsyncNotifier<List<AiMessageModel>> {
  @override
  Future<List<AiMessageModel>> build() async {
    final repo = ref.watch(aiAssistantRepositoryProvider);
    final history = await repo.getHistory();
    if (history.isEmpty) {
      return [
        AiMessageModel(speaker: 'assistant', content: 'Hello! I am your Intern-Link AI Assistant. How can I help you today?')
      ];
    }
    return history;
  }

  Future<void> sendMessage(String text) async {
    final repo = ref.read(aiAssistantRepositoryProvider);
    
    // Optimistically add user message
    final current = state.value ?? [];
    state = AsyncData([
      ...current,
      AiMessageModel(speaker: 'user', content: text),
    ]);

    try {
      final response = await repo.sendMessage(text);
      state = AsyncData([
        ...state.value!,
        response,
      ]);
    } catch (e) {
      state = AsyncData([
        ...state.value!,
        AiMessageModel(speaker: 'assistant', content: 'Sorry, I encountered an error: $e'),
      ]);
    }
  }
}

final aiMessagesProvider = AsyncNotifierProvider<AiMessagesNotifier, List<AiMessageModel>>(() => AiMessagesNotifier());

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      ref.read(aiMessagesProvider.notifier).sendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(aiMessagesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (messages) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg.speaker == 'user';
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
                          ),
                          child: Text(
                            msg.content,
                            style: TextStyle(
                              color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
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
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _submit,
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
