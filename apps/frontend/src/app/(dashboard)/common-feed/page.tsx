'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import axios from 'axios';
import {
  Eye,
  FileText,
  Image as ImageIcon,
  MessageSquare,
  MoreHorizontal,
  Send,
  Sparkles,
  ThumbsUp,
  TrendingUp,
  X,
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { useAuth } from '@/lib/hooks/useAuth';

interface Post {
  id: number;
  title: string;
  content: string;
  postType: 'ANNOUNCEMENT' | 'OPPORTUNITY' | 'EXPERIENCE' | 'GENERAL_UPDATE';
  author: {
    id: number;
    full_name: string;
    role: string;
  };
  likeCount: number;
  commentCount: number;
  viewCount: number;
  isLikedByUser: boolean;
  createdAt: string;
  imageUrls?: string[];
  documentUrls?: string[];
}

interface Comment {
  id: number;
  content: string;
  author: {
    id: number;
    full_name: string;
    role: string;
  };
  createdAt: string;
  replies?: Comment[];
}

export default function CommonFeedPage() {
  const router = useRouter();
  const { user } = useAuth();
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPost, setSelectedPost] = useState<Post | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [newPostTitle, setNewPostTitle] = useState('');
  const [newPostContent, setNewPostContent] = useState('');
  const [newPostType, setNewPostType] = useState<'ANNOUNCEMENT' | 'OPPORTUNITY' | 'EXPERIENCE' | 'GENERAL_UPDATE'>('GENERAL_UPDATE');
  const [showCreatePost, setShowCreatePost] = useState(false);
  const [newComment, setNewComment] = useState('');
  const [filter, setFilter] = useState<string>('ALL');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

  const getToken = () => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('token');
    }
    return null;
  };

  const fetchPosts = async (page = 1, postType?: string) => {
    try {
      const token = getToken();
      if (!token) {
        router.push('/login');
        return;
      }

      let url = `${API_BASE}/common-feed?page=${page}&limit=10`;
      if (postType && postType !== 'ALL') {
        url += `&postType=${postType}`;
      }

      const response = await axios.get(url, {
        headers: { Authorization: `Bearer ${token}` }
      });

      setPosts(response.data.data.posts);
      setTotalPages(response.data.data.pagination.totalPages);
      setCurrentPage(page);
      setLoading(false);
    } catch (error) {
      console.error('Error fetching posts:', error);
      setLoading(false);
    }
  };

  const fetchPostDetails = async (postId: number) => {
    try {
      const token = getToken();
      const response = await axios.get(`${API_BASE}/common-feed/${postId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });

      setSelectedPost(response.data.data);
      setComments(response.data.data.comments || []);
    } catch (error) {
      console.error('Error fetching post details:', error);
    }
  };

  const createPost = async () => {
    try {
      const token = getToken();
      await axios.post(
        `${API_BASE}/common-feed`,
        {
          title: newPostTitle,
          content: `<p>${newPostContent}</p>`,
          postType: newPostType,
          visibility: 'PUBLIC'
        },
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      setNewPostTitle('');
      setNewPostContent('');
      setShowCreatePost(false);
      fetchPosts(currentPage, filter !== 'ALL' ? filter : undefined);
    } catch (error) {
      console.error('Error creating post:', error);
      alert('Failed to create post');
    }
  };

  const toggleLike = async (postId: number) => {
    try {
      const token = getToken();
      await axios.post(
        `${API_BASE}/common-feed/${postId}/like`,
        {},
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      fetchPosts(currentPage, filter !== 'ALL' ? filter : undefined);
    } catch (error) {
      console.error('Error toggling like:', error);
    }
  };

  const addComment = async (postId: number) => {
    if (!newComment.trim()) return;

    try {
      const token = getToken();
      await axios.post(
        `${API_BASE}/common-feed/${postId}/comments`,
        { content: newComment },
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

      setNewComment('');
      fetchPostDetails(postId);
      fetchPosts(currentPage, filter !== 'ALL' ? filter : undefined);
    } catch (error) {
      console.error('Error adding comment:', error);
    }
  };

  useEffect(() => {
    fetchPosts(1);
  }, []);

  const getPostTypePill = (type: string) => {
    switch (type) {
      case 'ANNOUNCEMENT':
        return 'bg-info-50 text-info-700 border border-info-200';
      case 'OPPORTUNITY':
        return 'bg-success-50 text-success-700 border border-success-200';
      case 'EXPERIENCE':
        return 'bg-warning-50 text-warning-700 border border-warning-200';
      default:
        return 'bg-slate-50 text-slate-700 border border-slate-200';
    }
  };

  const getRolePill = (role: string) => {
    switch (role) {
      case 'ADMIN':
        return 'bg-error-50 text-error-700 border border-error-200';
      case 'COORDINATOR':
        return 'bg-info-50 text-info-700 border border-info-200';
      case 'SUPERVISOR':
        return 'bg-success-50 text-success-700 border border-success-200';
      case 'STUDENT':
        return 'bg-slate-50 text-slate-700 border border-slate-200';
      case 'HOD':
        return 'bg-warning-50 text-warning-700 border border-warning-200';
      default:
        return 'bg-slate-50 text-slate-700 border border-slate-200';
    }
  };

  const authorName = user?.fullName ?? 'You';
  const authorRole = user?.role ?? 'MEMBER';
  const authorInitials = useMemo(() => {
    const raw = (user?.fullName ?? 'You')
      .split(/\s+/)
      .filter(Boolean)
      .map((p) => p[0])
      .join('')
      .slice(0, 2)
      .toUpperCase();
    return raw || 'U';
  }, [user?.fullName]);

  const displayedPosts = posts;

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="text-center">
          <div className="mx-auto h-12 w-12 animate-spin rounded-full border-b-2 border-primary-600" />
          <p className="mt-4 text-sm text-text-muted">Loading Common Feed…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full animate-in fade-in duration-500">
      <div className="mx-auto w-full max-w-7xl">
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
          {/* Left rail */}
          <aside className="hidden lg:col-span-3 lg:block">
            <div className="sticky top-6 space-y-4">
              <div className="card overflow-hidden">
                <div className="h-16 bg-gradient-to-br from-primary-600 to-primary-800" />
                <div className="p-5">
                  <div className="-mt-10 mb-3 flex items-end justify-between">
                    <div className="flex h-14 w-14 items-center justify-center rounded-full border-4 border-white bg-primary-light text-lg font-bold text-primary-base shadow-card">
                      {authorInitials}
                    </div>
                    <span className="inline-flex items-center gap-1 rounded-full bg-primary-50 px-3 py-1 text-xs font-semibold text-primary-700 border border-primary-200">
                      <Sparkles className="h-3.5 w-3.5" />
                      Community
                    </span>
                  </div>
                  <p className="truncate text-sm font-bold text-text-heading">{authorName}</p>
                  <p className="mt-0.5 text-xs text-text-muted">{authorRole}</p>
                </div>
              </div>

              <div className="card p-5">
                <p className="text-sm font-bold text-text-heading">Quick links</p>
                <div className="mt-3 space-y-2 text-sm">
                  <div className="flex items-center gap-2 text-text-muted">
                    <TrendingUp className="h-4 w-4 text-primary-600" />
                    <span>See what’s trending in InternLink</span>
                  </div>
                  <div className="flex items-center gap-2 text-text-muted">
                    <FileText className="h-4 w-4 text-primary-600" />
                    <span>Share an opportunity</span>
                  </div>
                </div>
              </div>
            </div>
          </aside>

          {/* Center feed */}
          <section className="lg:col-span-6">
            {/* Sticky navigation header (LinkedIn-style, solid) */}
            <div className="sticky top-6 z-50 -mx-4 mb-5 bg-bg-main shadow-sm border border-border-default sm:-mx-6 lg:mx-0">
              <div className="px-4 py-3 sm:px-6 lg:px-4">
                <div className="flex flex-wrap gap-2">
                  {['ALL', 'ANNOUNCEMENT', 'OPPORTUNITY', 'EXPERIENCE', 'GENERAL_UPDATE'].map((type) => {
                    const active = filter === type;
                    return (
                      <button
                        key={type}
                        onClick={() => {
                          setFilter(type);
                          fetchPosts(1, type !== 'ALL' ? type : undefined);
                        }}
                        className={[
                          'rounded-xl px-3 py-2 text-sm font-semibold transition-colors',
                          active
                            ? 'bg-primary-600 text-white shadow-sm'
                            : 'text-text-muted hover:bg-bg-tertiary hover:text-text-body',
                        ].join(' ')}
                        type="button"
                      >
                        {type === 'GENERAL_UPDATE' ? 'GENERAL UPDATE' : type}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Spacer so header shadow doesn't "touch" composer */}
            <div className="h-3" />

            {/* Composer */}
            <div className="card p-5 sm:p-6">
              <div className="flex gap-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-full bg-primary-light text-sm font-bold text-primary-base">
                  {authorInitials}
                </div>
                <button
                  type="button"
                  onClick={() => setShowCreatePost(true)}
                  className="flex-1 rounded-2xl border border-border-default bg-bg-secondary px-4 py-3 text-left text-sm text-text-muted transition-colors hover:bg-bg-tertiary focus:outline-none focus:ring-2 focus:ring-ring-focus/20"
                >
                  Start a post…
                </button>
              </div>
              <div className="mt-4 flex flex-wrap items-center gap-2 pl-14">
                <button
                  type="button"
                  onClick={() => setShowCreatePost(true)}
                  className="inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-text-muted hover:bg-bg-tertiary hover:text-primary-700 transition-colors"
                >
                  <ImageIcon className="h-4 w-4 text-primary-600" />
                  Photo
                </button>
                <button
                  type="button"
                  onClick={() => setShowCreatePost(true)}
                  className="inline-flex items-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-text-muted hover:bg-bg-tertiary hover:text-primary-700 transition-colors"
                >
                  <FileText className="h-4 w-4 text-primary-600" />
                  Document
                </button>
              </div>
            </div>

            {/* Create post panel */}
            {showCreatePost && (
              <div className="mt-4 card p-5 sm:p-6">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <p className="text-sm font-bold text-text-heading">Create a post</p>
                    <p className="mt-1 text-xs text-text-muted">Your post will be visible to everyone in InternLink.</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => setShowCreatePost(false)}
                    className="rounded-lg p-2 text-text-muted hover:bg-bg-tertiary hover:text-text-body"
                    aria-label="Close"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </div>

                <div className="mt-5 grid gap-4">
                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
                    <div className="sm:col-span-1">
                      <label className="block text-xs font-semibold text-text-muted mb-2">Post type</label>
                      <select
                        value={newPostType}
                        onChange={(e) => setNewPostType(e.target.value as any)}
                        className="input-field"
                      >
                        <option value="GENERAL_UPDATE">General update</option>
                        <option value="ANNOUNCEMENT">Announcement</option>
                        <option value="OPPORTUNITY">Opportunity</option>
                        <option value="EXPERIENCE">Experience</option>
                      </select>
                    </div>
                    <div className="sm:col-span-2">
                      <label className="block text-xs font-semibold text-text-muted mb-2">Title</label>
                      <input
                        type="text"
                        value={newPostTitle}
                        onChange={(e) => setNewPostTitle(e.target.value)}
                        placeholder="Give it a clear title…"
                        className="input-field"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-text-muted mb-2">Content</label>
                    <textarea
                      value={newPostContent}
                      onChange={(e) => setNewPostContent(e.target.value)}
                      placeholder="What do you want to talk about?"
                      rows={5}
                      className="input-field min-h-[140px] resize-none"
                    />
                  </div>

                  <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex items-center gap-2 text-xs text-text-muted">
                      <span className={`inline-flex items-center rounded-full px-2.5 py-1 font-semibold ${getPostTypePill(newPostType)}`}>
                        {newPostType.replace('_', ' ')}
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={createPost}
                      disabled={!newPostTitle.trim() || !newPostContent.trim()}
                      className="btn-primary inline-flex items-center gap-2 rounded-xl px-6 py-2.5 disabled:opacity-60"
                    >
                      <Send className="h-4 w-4" />
                      Publish
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Feed */}
            <div className="mt-4 space-y-4">
              {displayedPosts.map((post) => {
                const isOpen = selectedPost?.id === post.id;
                const createdLabel = (() => {
                  try {
                    return formatDistanceToNow(new Date(post.createdAt), { addSuffix: true });
                  } catch {
                    return new Date(post.createdAt).toLocaleDateString();
                  }
                })();

                const authorInitialsPost =
                  post.author?.full_name
                    ?.split(/\s+/)
                    .filter(Boolean)
                    .map((p) => p[0])
                    .join('')
                    .slice(0, 2)
                    .toUpperCase() ?? 'MB';

                return (
                  <article key={post.id} className="card p-5 sm:p-6">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex min-w-0 gap-3">
                        <div className="flex h-11 w-11 items-center justify-center rounded-full bg-slate-100 text-sm font-bold text-slate-600">
                          {authorInitialsPost}
                        </div>
                        <div className="min-w-0">
                          <div className="flex flex-wrap items-center gap-2">
                            <p className="truncate text-sm font-extrabold text-text-heading">
                              {post.author?.full_name ?? 'Unknown'}
                            </p>
                            <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[11px] font-semibold ${getRolePill(post.author?.role ?? '')}`}>
                              {post.author?.role ?? 'MEMBER'}
                            </span>
                            <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[11px] font-semibold ${getPostTypePill(post.postType)}`}>
                              {post.postType.replace('_', ' ')}
                            </span>
                          </div>
                          <p className="mt-0.5 text-xs text-text-muted">{createdLabel}</p>
                        </div>
                      </div>
                      <button
                        type="button"
                        className="rounded-lg p-2 text-text-muted hover:bg-bg-tertiary hover:text-text-body"
                        aria-label="More"
                      >
                        <MoreHorizontal className="h-5 w-5" />
                      </button>
                    </div>

                    <h3 className="mt-4 text-base font-bold text-text-heading">{post.title}</h3>
                    <div
                      className="prose prose-slate mt-2 max-w-none text-sm text-text-body"
                      dangerouslySetInnerHTML={{ __html: post.content }}
                    />

                    {/* Stats row */}
                    <div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-border-default pt-3 text-xs text-text-muted">
                      <div className="flex items-center gap-4">
                        <span className="inline-flex items-center gap-1">
                          <ThumbsUp className="h-3.5 w-3.5" />
                          {post.likeCount}
                        </span>
                        <span className="inline-flex items-center gap-1">
                          <MessageSquare className="h-3.5 w-3.5" />
                          {post.commentCount}
                        </span>
                      </div>
                      <span className="inline-flex items-center gap-1">
                        <Eye className="h-3.5 w-3.5" />
                        {post.viewCount} views
                      </span>
                    </div>

                    {/* Actions row */}
                    <div className="mt-2 grid grid-cols-2 gap-2 sm:grid-cols-3">
                      <button
                        type="button"
                        onClick={() => toggleLike(post.id)}
                        className={[
                          'inline-flex items-center justify-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold transition-colors',
                          post.isLikedByUser
                            ? 'bg-primary-50 text-primary-700 border border-primary-200'
                            : 'text-text-muted hover:bg-bg-tertiary hover:text-text-body',
                        ].join(' ')}
                      >
                        <ThumbsUp className="h-4 w-4" />
                        Like
                      </button>
                      <button
                        type="button"
                        onClick={() => fetchPostDetails(post.id)}
                        className="inline-flex items-center justify-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-text-muted transition-colors hover:bg-bg-tertiary hover:text-text-body"
                      >
                        <MessageSquare className="h-4 w-4" />
                        Comment
                      </button>
                      <button
                        type="button"
                        className="hidden sm:inline-flex items-center justify-center gap-2 rounded-xl px-3 py-2 text-sm font-semibold text-text-muted transition-colors hover:bg-bg-tertiary hover:text-text-body"
                      >
                        <Send className="h-4 w-4" />
                        Share
                      </button>
                    </div>

                    {/* Comments */}
                    {isOpen && (
                      <div className="mt-5 rounded-2xl border border-border-default bg-bg-secondary p-4">
                        <p className="text-sm font-bold text-text-heading">
                          Comments <span className="text-text-muted font-semibold">({comments.length})</span>
                        </p>

                        <div className="mt-3">
                          <textarea
                            value={newComment}
                            onChange={(e) => setNewComment(e.target.value)}
                            placeholder="Write a comment…"
                            rows={2}
                            className="input-field min-h-[76px] resize-none"
                          />
                          <div className="mt-2 flex justify-end">
                            <button
                              type="button"
                              onClick={() => addComment(post.id)}
                              disabled={!newComment.trim()}
                              className="btn-primary rounded-xl px-5 py-2 disabled:opacity-60"
                            >
                              Post
                            </button>
                          </div>
                        </div>

                        <div className="mt-4 space-y-3">
                          {comments.map((comment) => {
                            const commentWhen = (() => {
                              try {
                                return formatDistanceToNow(new Date(comment.createdAt), { addSuffix: true });
                              } catch {
                                return new Date(comment.createdAt).toLocaleDateString();
                              }
                            })();

                            const commentInitials =
                              comment.author?.full_name
                                ?.split(/\s+/)
                                .filter(Boolean)
                                .map((p) => p[0])
                                .join('')
                                .slice(0, 2)
                                .toUpperCase() ?? 'MB';

                            return (
                              <div key={comment.id} className="rounded-2xl bg-white p-4 border border-border-default">
                                <div className="flex items-start gap-3">
                                  <div className="flex h-9 w-9 items-center justify-center rounded-full bg-slate-100 text-xs font-bold text-slate-600">
                                    {commentInitials}
                                  </div>
                                  <div className="min-w-0 flex-1">
                                    <div className="flex flex-wrap items-center gap-2">
                                      <span className="text-sm font-bold text-text-heading">
                                        {comment.author?.full_name ?? 'Unknown'}
                                      </span>
                                      <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[11px] font-semibold ${getRolePill(comment.author?.role ?? '')}`}>
                                        {comment.author?.role ?? 'MEMBER'}
                                      </span>
                                      <span className="text-xs text-text-muted">{commentWhen}</span>
                                    </div>
                                    <p className="mt-1 text-sm text-text-body whitespace-pre-wrap">{comment.content}</p>
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </article>
                );
              })}

              {displayedPosts.length === 0 && (
                <div className="card p-10 text-center">
                  <p className="text-sm font-bold text-text-heading">No posts found</p>
                  <p className="mt-1 text-sm text-text-muted">
                    Be the first to share an update.
                  </p>
                </div>
              )}
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="mt-6 flex flex-wrap items-center justify-center gap-2">
                <button
                  type="button"
                  onClick={() => fetchPosts(currentPage - 1, filter !== 'ALL' ? filter : undefined)}
                  disabled={currentPage === 1}
                  className="rounded-xl border border-border-default bg-white px-4 py-2 text-sm font-semibold text-text-body hover:bg-bg-tertiary disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Previous
                </button>
                <span className="rounded-xl border border-border-default bg-white px-4 py-2 text-sm text-text-muted">
                  Page <span className="font-semibold text-text-heading">{currentPage}</span> of{' '}
                  <span className="font-semibold text-text-heading">{totalPages}</span>
                </span>
                <button
                  type="button"
                  onClick={() => fetchPosts(currentPage + 1, filter !== 'ALL' ? filter : undefined)}
                  disabled={currentPage === totalPages}
                  className="rounded-xl border border-border-default bg-white px-4 py-2 text-sm font-semibold text-text-body hover:bg-bg-tertiary disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Next
                </button>
              </div>
            )}
          </section>

          {/* Right rail */}
          <aside className="hidden lg:col-span-3 lg:block">
            <div className="sticky top-6 space-y-4">
              <div className="card p-5">
                <p className="text-sm font-bold text-text-heading">Add to your feed</p>
                <div className="mt-3 space-y-3">
                  {[
                    { name: 'Internship Opportunities', subtitle: 'Company updates' },
                    { name: 'University Announcements', subtitle: 'Academic updates' },
                    { name: 'Supervisor Tips', subtitle: 'Mentorship' },
                  ].map((i) => (
                    <div key={i.name} className="flex items-center justify-between gap-3">
                      <div className="min-w-0">
                        <p className="truncate text-sm font-bold text-text-heading">{i.name}</p>
                        <p className="truncate text-xs text-text-muted">{i.subtitle}</p>
                      </div>
                      <button type="button" className="rounded-full border border-border-default px-3 py-1.5 text-xs font-semibold text-text-body hover:bg-bg-tertiary">
                        Follow
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </aside>
        </div>
      </div>
    </div>
  );
}
