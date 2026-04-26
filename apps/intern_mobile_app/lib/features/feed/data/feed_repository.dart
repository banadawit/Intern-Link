import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/api_client.dart';

// ─── Models ───────────────────────────────────────────────────────────────

class FeedAuthor {
  final int id;
  final String fullName;
  final String role;

  const FeedAuthor({required this.id, required this.fullName, required this.role});

  factory FeedAuthor.fromJson(Map<String, dynamic> j) => FeedAuthor(
        id: j['id'] as int,
        fullName: j['full_name'] as String? ?? 'Unknown',
        role: j['role'] as String? ?? '',
      );
}

class FeedPost {
  final int id;
  final String? title;
  final String content;
  final String postType;
  final String visibility;
  final FeedAuthor author;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isLikedByUser;
  final bool isPinned;
  final DateTime createdAt;
  final List<FeedComment> comments;
  final List<String> imageUrls;
  final List<String> documentUrls;

  const FeedPost({
    required this.id,
    this.title,
    required this.content,
    required this.postType,
    required this.visibility,
    required this.author,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.isLikedByUser,
    required this.isPinned,
    required this.createdAt,
    required this.comments,
    this.imageUrls = const [],
    this.documentUrls = const [],
  });

  factory FeedPost.fromJson(Map<String, dynamic> j) {
    final count = j['_count'] as Map<String, dynamic>?;
    return FeedPost(
      id: j['id'] as int,
      title: j['title'] as String?,
      content: j['content'] as String? ?? '',
      postType: j['postType'] as String? ?? 'GENERAL_UPDATE',
      visibility: j['visibility'] as String? ?? 'PUBLIC',
      author: FeedAuthor.fromJson(j['author'] as Map<String, dynamic>),
      likeCount: (j['likeCount'] ?? count?['likes'] ?? 0) as int,
      commentCount: (j['commentCount'] ?? count?['comments'] ?? 0) as int,
      viewCount: (j['viewCount'] ?? count?['views'] ?? 0) as int,
      isLikedByUser: j['isLikedByUser'] as bool? ?? false,
      isPinned: j['isPinned'] as bool? ?? false,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      comments: (j['comments'] as List<dynamic>?)
              ?.map((c) => FeedComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      imageUrls: (j['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      documentUrls: (j['documentUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  FeedPost copyWith({
    bool? isLikedByUser,
    int? likeCount,
    List<FeedComment>? comments,
    List<String>? imageUrls,
    List<String>? documentUrls,
  }) =>
      FeedPost(
        id: id,
        title: title,
        content: content,
        postType: postType,
        visibility: visibility,
        author: author,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount,
        viewCount: viewCount,
        isLikedByUser: isLikedByUser ?? this.isLikedByUser,
        isPinned: isPinned,
        createdAt: createdAt,
        comments: comments ?? this.comments,
        imageUrls: imageUrls ?? this.imageUrls,
        documentUrls: documentUrls ?? this.documentUrls,
      );
}

class FeedComment {
  final int id;
  final String content;
  final FeedAuthor author;
  final DateTime createdAt;
  final List<FeedComment> replies;

  const FeedComment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.replies,
  });

  factory FeedComment.fromJson(Map<String, dynamic> j) => FeedComment(
        id: j['id'] as int,
        content: j['content'] as String? ?? '',
        author: FeedAuthor.fromJson(j['author'] as Map<String, dynamic>),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? 
                   DateTime.tryParse(j['created_at'] as String? ?? '') ?? 
                   DateTime.now(),
        replies: (j['replies'] as List<dynamic>?)
                ?.map((r) => FeedComment.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ─── Repository ────────────────────────────────────────────────────────────

class FeedRepository {
  FeedRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<List<FeedPost>> getFeed({int page = 1, String? postType}) async {
    final query = <String, dynamic>{'page': page, 'limit': 20};
    if (postType != null) query['postType'] = postType;

    final response = await apiClient.dio.get('/common-feed', queryParameters: query);
    final data = response.data;

    List<dynamic> posts;
    if (data is Map && data['posts'] != null) {
      posts = data['posts'] as List;
    } else if (data is Map && data['data'] != null) {
      final inner = data['data'];
      posts = (inner is Map ? inner['posts'] : inner) as List;
    } else {
      posts = [];
    }

    return posts.map((p) => FeedPost.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<FeedPost> getPostDetails(int postId) async {
    final response = await apiClient.dio.get('/common-feed/$postId');
    final raw = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return FeedPost.fromJson(raw as Map<String, dynamic>);
  }

  Future<List<String>> uploadImages(List<String> filePaths) async {
    final formData = FormData();
    for (final path in filePaths) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(path, filename: path.split('/').last),
      ));
    }
    final response = await apiClient.dio.post('/common-feed/upload/images', data: formData);
    return (response.data['urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  }

  Future<List<String>> uploadDocuments(List<String> filePaths) async {
    final formData = FormData();
    for (final path in filePaths) {
      formData.files.add(MapEntry(
        'documents',
        await MultipartFile.fromFile(path, filename: path.split('/').last),
      ));
    }
    final response = await apiClient.dio.post('/common-feed/upload/documents', data: formData);
    return (response.data['urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  }

  Future<bool> toggleLike(int postId) async {
    final response = await apiClient.dio.post('/common-feed/$postId/like');
    return response.data['liked'] as bool? ?? false;
  }

  Future<void> deletePost(int postId) async {
    await apiClient.dio.delete('/common-feed/$postId');
  }

  Future<void> reportPost(int postId, String reason) async {
    await apiClient.dio.post('/common-feed/$postId/report', data: {'reason': reason});
  }

  Future<FeedComment> addComment(int postId, String content) async {
    final response = await apiClient.dio.post(
      '/common-feed/$postId/comments',
      data: {'content': content},
    );
    final raw = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return FeedComment.fromJson(raw as Map<String, dynamic>);
  }

  Future<FeedPost> createPost({
    required String content,
    String? title,
    String postType = 'GENERAL_UPDATE',
    List<String> imageUrls = const [],
    List<String> documentUrls = const [],
  }) async {
    final response = await apiClient.dio.post('/common-feed', data: {
      'content': content,
      if (title != null) 'title': title,
      'postType': postType,
      'visibility': 'PUBLIC',
      'imageUrls': imageUrls,
      'documentUrls': documentUrls,
    });

    dynamic raw = response.data;
    if (raw is Map) {
      raw = raw['data'] ?? raw['post'] ?? raw;
    }

    if (raw is! Map<String, dynamic>) {
      return FeedPost(
        id: DateTime.now().millisecondsSinceEpoch,
        content: content,
        title: title,
        postType: postType,
        visibility: 'PUBLIC',
        author: const FeedAuthor(id: 0, fullName: 'You', role: 'STUDENT'),
        likeCount: 0,
        commentCount: 0,
        viewCount: 0,
        isLikedByUser: false,
        isPinned: false,
        createdAt: DateTime.now(),
        comments: [],
      );
    }

    return FeedPost.fromJson(raw);
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(apiClient: ref.watch(apiClientProvider));
});

// ─── Providers ─────────────────────────────────────────────────────────────

final feedPostTypeFilterProvider = StateProvider<String?>((ref) => null);

final feedProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) async {
  final postType = ref.watch(feedPostTypeFilterProvider);
  return ref.read(feedRepositoryProvider).getFeed(postType: postType);
});
