import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/feed_repository.dart';

class CommonFeedScreen extends ConsumerStatefulWidget {
  const CommonFeedScreen({super.key});

  @override
  ConsumerState<CommonFeedScreen> createState() => _CommonFeedScreenState();
}

class _CommonFeedScreenState extends ConsumerState<CommonFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _commentControllers = <int, TextEditingController>{};
  final _expandedComments = <int>{};


  static const _tabs = ['All Posts', 'Announcement', 'Opportunity', 'Experience', 'General'];
  static const _tabTypes = [null, 'ANNOUNCEMENT', 'OPPORTUNITY', 'EXPERIENCE', 'GENERAL_UPDATE'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      ref.read(feedPostTypeFilterProvider.notifier).state = _tabTypes[_tabController.index];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _commentControllers.values) c.dispose();
    super.dispose();
  }



  Future<void> _openCreatePostSheet() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedType = 'GENERAL_UPDATE';
    bool isPosting = false;

    const types = {
      'GENERAL_UPDATE': 'General',
      'ANNOUNCEMENT': 'Announcement',
      'OPPORTUNITY': 'Opportunity',
      'EXPERIENCE': 'Experience',
    };
    const typeColors = {
      'GENERAL_UPDATE': Color(0xFF0EA5E9),
      'ANNOUNCEMENT': Color(0xFFF59E0B),
      'OPPORTUNITY': Color(0xFF10B981),
      'EXPERIENCE': Color(0xFF8B5CF6),
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Create Post', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 20),
                // Post type chips
                Text('Post Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types.entries.map((e) {
                    final isSelected = selectedType == e.key;
                    final color = typeColors[e.key]!;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedType = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(isSelected ? 1 : 0.3)),
                        ),
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),
                // Content
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'What\'s on your mind?',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isPosting ? null : () async {
                      final content = contentCtrl.text.trim();
                      if (content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please write something first!')),
                        );
                        return;
                      }
                      setModalState(() => isPosting = true);
                      try {
                        await ref.read(feedRepositoryProvider).createPost(
                          content: content,
                          title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                          postType: selectedType,
                        );
                        ref.invalidate(feedProvider);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Post shared with the community! 🎉'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isPosting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: isPosting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Share Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _toggleLike(FeedPost post) async {
    try {
      await ref.read(feedRepositoryProvider).toggleLike(post.id);
      ref.invalidate(feedProvider);
    } catch (_) {}
  }

  Future<void> _submitComment(FeedPost post) async {
    final ctrl = _commentControllers[post.id];
    final text = ctrl?.text.trim() ?? '';
    if (text.isEmpty) return;
    try {
      await ref.read(feedRepositoryProvider).addComment(post.id, text);
      ctrl?.clear();
      ref.invalidate(feedProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF0A1628) : const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          _buildAppBar(theme, isDark),
        ],
        body: Column(
          children: [
            _buildTabBar(theme, isDark),
            Expanded(
              child: Consumer(
                builder: (ctx, ref, _) {
                  final feed = ref.watch(feedProvider);
                  return feed.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _buildError(e.toString()),
                    data: (posts) => RefreshIndicator(
                      onRefresh: () async => ref.invalidate(feedProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        itemCount: posts.isEmpty ? 1 : posts.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) return _buildCreatePost(isDark, theme);
                          if (posts.isEmpty) return _buildEmpty();
                          return _buildPostCard(posts[i - 1], isDark, theme);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100,
      backgroundColor: isDark ? const Color(0xFF0A1628) : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dynamic_feed_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Community Feed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => ref.invalidate(feedProvider),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0A1628) : Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFF0EA5E9),
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
        indicatorColor: const Color(0xFF0EA5E9),
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: _tabs.map((t) => Tab(text: t.toUpperCase())).toList(),
      ),
    );
  }

  Widget _buildCreatePost(bool isDark, ThemeData theme) {
    return GestureDetector(
      onTap: _openCreatePostSheet,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.15),
              child: const Icon(Icons.person_rounded, color: Color(0xFF0EA5E9), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Share something with the community...',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPostCard(FeedPost post, bool isDark, ThemeData theme) {
    final commentCtrl =
        _commentControllers.putIfAbsent(post.id, () => TextEditingController());
    final showComments = _expandedComments.contains(post.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: post.isPinned
            ? Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.4))
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
            child: Row(
              children: [
                _avatar(post.author.fullName, post.postType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _roleBadge(post.author.role, isDark),
                          _typeBadge(post.postType),
                          Text(
                            timeago.format(post.createdAt),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                    onPressed: () {}),
              ],
            ),
          ),
          // Content
          if (post.title != null && post.title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(post.title!,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          // Render HTML or plain text
          _buildContent(post.content, isDark, theme),
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              Icon(Icons.visibility_outlined, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${post.viewCount} views',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ]),
          ),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Divider(height: 1)),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(children: [
              _actionButton(
                icon: post.isLikedByUser
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                label: post.likeCount > 0 ? '${post.likeCount} Like' : 'Like',
                color: post.isLikedByUser ? const Color(0xFF0EA5E9) : Colors.grey,
                onTap: () => _toggleLike(post),
              ),
              _actionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: post.commentCount > 0 ? '${post.commentCount} Comment' : 'Comment',
                color: Colors.grey,
                onTap: () => setState(() {
                  if (showComments) {
                    _expandedComments.remove(post.id);
                  } else {
                    _expandedComments.add(post.id);
                  }
                }),
              ),
              _actionButton(
                  icon: Icons.share_outlined, label: 'Share', color: Colors.grey, onTap: () {}),
            ]),
          ),
          // Comment input
          if (showComments)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(children: [
                CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF6366F1), size: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: commentCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                          hintText: 'Write a comment...', border: InputBorder.none),
                      onSubmitted: (_) => _submitComment(post),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _submitComment(post),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _avatar(String name, String postType) {
    final color = _typeColor(postType);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }

  Widget _roleBadge(String role, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.replaceAll('_', ' ').toLowerCase().split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        }).join(' '),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54),
      ),
    );
  }

  Widget _typeBadge(String type) {
    final color = _typeColor(type);
    final label = type.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'ANNOUNCEMENT':
        return const Color(0xFFF59E0B);
      case 'OPPORTUNITY':
        return const Color(0xFF10B981);
      case 'EXPERIENCE':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  Widget _actionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
      ),
    );
  }

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Could not load feed', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(feedProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ]),
        ),
      );

  Widget _buildContent(String content, bool isDark, ThemeData theme) {
    // If content contains HTML tags, render with flutter_html, else plain Text
    final trimmed = content.trim();
    final isHtml = trimmed.contains('<') && trimmed.contains('>');
    
    if (isHtml) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Html(
          data: content,
          style: {
            "body": Style(
              fontSize: FontSize(14),
              lineHeight: LineHeight.em(1.55),
              color: isDark ? Colors.white70 : Colors.black87,
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
          },
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.feed_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            SizedBox(height: 8),
            Text('Be the first to share something!',
                style: TextStyle(color: Colors.grey)),
          ]),
        ),
      );
}
