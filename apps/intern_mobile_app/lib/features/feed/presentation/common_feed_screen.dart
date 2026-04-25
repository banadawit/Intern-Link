import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
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
    final picker = ImagePicker();
    List<XFile> selectedMedia = [];
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
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
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
                // Post type
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
                        child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : color)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'What\'s on your mind?',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 14),
                // Media Picker
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final files = await picker.pickMultiImage();
                        if (files.isNotEmpty) setModalState(() => selectedMedia.addAll(files));
                      },
                      icon: const Icon(Icons.image_rounded, color: Color(0xFF0EA5E9)),
                      label: const Text('Add Image', style: TextStyle(color: Color(0xFF0EA5E9))),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final file = await picker.pickVideo(source: ImageSource.gallery);
                        if (file != null) setModalState(() => selectedMedia.add(file));
                      },
                      icon: const Icon(Icons.video_collection_rounded, color: Color(0xFF8B5CF6)),
                      label: const Text('Add Video', style: TextStyle(color: Color(0xFF8B5CF6))),
                    ),
                  ],
                ),
                if (selectedMedia.isNotEmpty)
                  Container(
                    height: 80,
                    margin: const EdgeInsets.only(top: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedMedia.length,
                      itemBuilder: (ctx, i) => Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.3))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(selectedMedia[i].path), fit: BoxFit.cover),
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => selectedMedia.removeAt(i)),
                                  child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isPosting ? null : () async {
                      final content = contentCtrl.text.trim();
                      if (content.isEmpty) return;
                      setModalState(() => isPosting = true);
                      try {
                        List<String> imageUrls = [];
                        List<String> videoUrls = [];
                        
                        // Separate images and videos (simple logic by extension)
                        final images = selectedMedia.where((m) => !m.path.toLowerCase().endsWith('.mp4')).map((m) => m.path).toList();
                        final videos = selectedMedia.where((m) => m.path.toLowerCase().endsWith('.mp4')).map((m) => m.path).toList();

                        if (images.isNotEmpty) {
                          imageUrls = await ref.read(feedRepositoryProvider).uploadImages(images);
                        }
                        if (videos.isNotEmpty) {
                          videoUrls = await ref.read(feedRepositoryProvider).uploadDocuments(videos);
                        }

                        await ref.read(feedRepositoryProvider).createPost(
                          content: content,
                          title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                          postType: selectedType,
                          imageUrls: imageUrls,
                          documentUrls: videoUrls,
                        );
                        ref.invalidate(feedProvider);
                        if (context.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => isPosting = false);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]), borderRadius: BorderRadius.circular(16)),
                      child: Center(
                        child: isPosting ? const CircularProgressIndicator(color: Colors.white) : const Text('Share Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment added!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add comment: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deletePost(int postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(feedRepositoryProvider).deletePost(postId);
        ref.invalidate(feedProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showReportOptions(int postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            Text('Report Post', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _reportTile(postId, 'Inappropriate Content'),
            _reportTile(postId, 'Spam or Misleading'),
            _reportTile(postId, 'Harassment'),
            _reportTile(postId, 'Other'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(int postId, String reason) {
    return ListTile(
      title: Text(reason),
      onTap: () async {
        Navigator.pop(context);
        try {
          await ref.read(feedRepositoryProvider).reportPost(postId, reason);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Thank you for keeping the community safe.')));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
    );
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
          // Pinned/Broadcast Indicator
          if (post.isPinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.push_pin_rounded, size: 14, color: Color(0xFF0EA5E9)),
                  SizedBox(width: 8),
                  Text('BROADCAST ANNOUNCEMENT', style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
            ),
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16, post.isPinned ? 12 : 16, 12, 0),
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
                    onPressed: () => _showPostMenu(post)),
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
          _buildContent(post.content, isDark, theme),
          
          // Media Gallery
          if (post.imageUrls.isNotEmpty || post.documentUrls.isNotEmpty)
            _buildMediaGallery(post, isDark),
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
                  icon: Icons.share_outlined, label: 'Share', color: Colors.grey, onTap: () async {
                    final plainText = post.content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
                    final shareText = '${post.title ?? 'InternLink Post'}\n\n$plainText\n\nShared via InternLink Community';
                    try {
                      await Share.share(shareText);
                    } catch (e) {
                      // Fallback: Copy to clipboard if plugin fails (common in dev/web)
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Share plugin not initialized. Link copied to clipboard instead!'),
                          backgroundColor: Colors.blueAccent,
                        ));
                      }
                    }
                  }),
            ]),
          ),
          // Comments list (show top 2)
          if (post.comments.isNotEmpty)
             _buildCommentList(post.comments, isDark, theme),
          
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
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }

  void _showPostMenu(FeedPost post) {
    // Check if I am the author
    // For now, let's allow reporting and delete (delete if role matches or mock id)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            _menuItem(Icons.report_problem_rounded, 'Report Post', Colors.orange, () {
              Navigator.pop(ctx);
              _showReportOptions(post.id);
            }),
            _menuItem(Icons.delete_rounded, 'Delete Post', Colors.red, () {
              Navigator.pop(ctx);
              _deletePost(post.id);
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  Widget _buildCommentList(List<FeedComment> comments, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...comments.take(2).map((c) => _commentItem(c, isDark, theme)),
          if (comments.length > 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {}, // TODO: Open full post view
                child: Text('View all ${comments.length} comments', style: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _commentItem(FeedComment c, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(c.author.fullName[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.author.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(c.content, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(timeago.format(c.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 9)),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildMediaGallery(FeedPost post, bool isDark) {
    final media = [...post.imageUrls, ...post.documentUrls];
    if (media.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 220,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: media.length,
        itemBuilder: (ctx, i) {
          final url = media[i];
          final isVideo = url.toLowerCase().contains('.mp4');
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // For images, show network image. For videos, show a placeholder with play icon
                  isVideo 
                    ? Container(color: Colors.black87, child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48))
                    : Image.network(url, fit: BoxFit.cover, errorBuilder: (ctx, _, __) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image_rounded, color: Colors.grey))),
                  if (isVideo)
                    Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: const Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          );
        },
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
