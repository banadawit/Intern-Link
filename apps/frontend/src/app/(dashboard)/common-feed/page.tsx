'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import axios from 'axios';
import { 
  Image as ImageIcon, 
  FileText, 
  Video, 
  Calendar,
  ThumbsUp,
  MessageCircle,
  Share2,
  Send,
  MoreHorizontal,
  Globe,
  Users,
  Building,
  X
} from 'lucide-react';

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
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPost, setSelectedPost] = useState<Post | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [newPostContent, setNewPostContent] = useState('');
  const [newPostType, setNewPostType] = useState<'ANNOUNCEMENT' | 'OPPORTUNITY' | 'EXPERIENCE' | 'GENERAL_UPDATE'>('GENERAL_UPDATE');
  const [showCreatePost, setShowCreatePost] = useState(false);
  const [newComment, setNewComment] = useState('');
  const [filter, setFilter] = useState<string>('ALL');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [sharePostId, setSharePostId] = useState<number | null>(null);
  const [copyDone, setCopyDone] = useState(false);

  const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

  const getToken = () => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('token');
    }
    return null;
  };

  const getCurrentUser = () => {
    if (typeof window !== 'undefined') {
      const userStr = localStorage.getItem('user');
      if (userStr) {
        return JSON.parse(userStr);
      }
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

      setComments(response.data.data.comments || []);
    } catch (error) {
      console.error('Error fetching post details:', error);
    }
  };

  const createPost = async () => {
    if (!newPostContent.trim()) return;

    try {
      const token = getToken();
      
      // Extract title from first line or first 50 chars
      const lines = newPostContent.split('\n');
      const title = lines[0].substring(0, 100) || 'Post';
      const content = newPostContent;

      await axios.post(
        `${API_BASE}/common-feed`,
        {
          title,
          content: `<p>${content.replace(/\n/g, '<br>')}</p>`,
          postType: newPostType,
          visibility: 'PUBLIC'
        },
        {
          headers: { Authorization: `Bearer ${token}` }
        }
      );

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

      // Update local state
      setPosts(posts.map(post => {
        if (post.id === postId) {
          return {
            ...post,
            isLikedByUser: !post.isLikedByUser,
            likeCount: post.isLikedByUser ? post.likeCount - 1 : post.likeCount + 1
          };
        }
        return post;
      }));
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
      
      // Update comment count
      setPosts(posts.map(post => {
        if (post.id === postId) {
          return { ...post, commentCount: post.commentCount + 1 };
        }
        return post;
      }));
    } catch (error) {
      console.error('Error adding comment:', error);
    }
  };

  const toggleComments = (postId: number) => {
    if (selectedPost?.id === postId) {
      setSelectedPost(null);
      setComments([]);
    } else {
      const post = posts.find(p => p.id === postId);
      if (post) {
        setSelectedPost(post);
        fetchPostDetails(postId);
      }
    }
  };

  useEffect(() => {
    const user = getCurrentUser();
    setCurrentUser(user);
    fetchPosts(1);
  }, []);

  useEffect(() => {
    if (sharePostId === null) return;
    const close = () => setSharePostId(null);
    document.addEventListener('click', close);
    return () => document.removeEventListener('click', close);
  }, [sharePostId]);

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  };

  const getPostTypeLabel = (type: string) => {
    switch (type) {
      case 'ANNOUNCEMENT': return '📢 Announcement';
      case 'OPPORTUNITY': return '💼 Opportunity';
      case 'EXPERIENCE': return '✨ Experience';
      default: return '📝 Update';
    }
  };

  const getRoleBadge = (role: string) => {
    const badges: any = {
      'ADMIN': { label: 'Admin', color: 'text-red-600' },
      'COORDINATOR': { label: 'Coordinator', color: 'text-teal-600' },
      'SUPERVISOR': { label: 'Supervisor', color: 'text-emerald-600' },
      'STUDENT': { label: 'Student', color: 'text-purple-600' },
      'HOD': { label: 'HOD', color: 'text-amber-600' },
    };
    return badges[role] || { label: role, color: 'text-slate-600' };
  };

  const formatTimeAgo = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (seconds < 60) return 'Just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`;
    return date.toLocaleDateString();
  };

  const getPostUrl = (postId: number) => {
    const base = typeof window !== 'undefined' ? window.location.origin : '';
    return `${base}/common-feed?post=${postId}`;
  };

  const copyLink = async (postId: number) => {
    const url = getPostUrl(postId);
    try {
      if (navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(url);
      } else {
        const el = document.createElement('textarea');
        el.value = url;
        el.style.position = 'fixed';
        el.style.opacity = '0';
        document.body.appendChild(el);
        el.select();
        document.execCommand('copy');
        document.body.removeChild(el);
      }
    } catch { /* ignore */ }
    setCopyDone(true);
    setTimeout(() => setCopyDone(false), 2500);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-slate-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600 mx-auto"></div>
          <p className="mt-4 text-slate-600">Loading feed...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen">
      <div className="max-w-[1128px] mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Main Feed */}
          <div className="lg:col-span-9">
            {/* Create Post Card */}
            <div className="bg-white rounded-lg border border-slate-200 p-4 mb-4 sticky top-0 z-10">
              <div className="flex gap-3">
                <div className="w-12 h-12 rounded-full bg-slate-200 flex items-center justify-center text-sm font-bold text-slate-600">
                  {currentUser ? getInitials(currentUser.fullName || 'User') : 'U'}
                </div>
                <button
                  onClick={() => setShowCreatePost(true)}
                  className="flex-1 text-left px-4 py-3 rounded-full border border-slate-300 hover:bg-slate-50 text-slate-600 font-medium transition-colors"
                >
                  Start a post
                </button>
              </div>
              <div className="flex justify-between mt-3 pt-3 border-t border-slate-200">
                <button className="flex items-center gap-2 px-4 py-2 hover:bg-slate-50 rounded-lg text-slate-600 font-medium transition-colors">
                  <ImageIcon className="w-5 h-5 text-teal-500" />
                  <span className="hidden sm:inline">Photo</span>
                </button>
                <button className="flex items-center gap-2 px-4 py-2 hover:bg-slate-50 rounded-lg text-slate-600 font-medium transition-colors">
                  <Video className="w-5 h-5 text-emerald-500" />
                  <span className="hidden sm:inline">Video</span>
                </button>
                <button className="flex items-center gap-2 px-4 py-2 hover:bg-slate-50 rounded-lg text-slate-600 font-medium transition-colors">
                  <Calendar className="w-5 h-5 text-orange-500" />
                  <span className="hidden sm:inline">Event</span>
                </button>
                <button className="flex items-center gap-2 px-4 py-2 hover:bg-slate-50 rounded-lg text-slate-600 font-medium transition-colors">
                  <FileText className="w-5 h-5 text-rose-500" />
                  <span className="hidden sm:inline">Article</span>
                </button>
              </div>
            </div>

            {/* Filter Tabs */}
            <div className="bg-white rounded-lg border border-slate-200 mb-4">
              <div className="flex border-b border-slate-200 overflow-x-auto">
                {['ALL', 'ANNOUNCEMENT', 'OPPORTUNITY', 'EXPERIENCE', 'GENERAL_UPDATE'].map((type) => (
                  <button
                    key={type}
                    onClick={() => {
                      setFilter(type);
                      fetchPosts(1, type !== 'ALL' ? type : undefined);
                    }}
                    className={`px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors ${
                      filter === type
                        ? 'text-teal-600 border-b-2 border-teal-600'
                        : 'text-slate-600 hover:text-slate-900'
                    }`}
                  >
                    {type === 'ALL' ? 'All Posts' : type.replace('_', ' ')}
                  </button>
                ))}
              </div>
            </div>

            {/* Posts */}
            <div className="space-y-4">
              {posts.map((post) => (
                <div key={post.id} className="bg-white rounded-lg border border-slate-200">
                  {/* Post Header */}
                  <div className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex gap-3">
                        <div className="w-12 h-12 rounded-full bg-slate-200 flex items-center justify-center text-sm font-bold text-slate-600">
                          {getInitials(post.author.full_name)}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h3 className="font-semibold text-slate-900 hover:text-teal-600 cursor-pointer">
                              {post.author.full_name}
                            </h3>
                            <span className="text-xs text-slate-500">• 1st</span>
                          </div>
                          <p className="text-sm text-slate-600">
                            {getRoleBadge(post.author.role).label} • {getPostTypeLabel(post.postType)}
                          </p>
                          <div className="flex items-center gap-1 text-xs text-slate-500 mt-1">
                            <span>{formatTimeAgo(post.createdAt)}</span>
                            <span>•</span>
                            <Globe className="w-3 h-3" />
                          </div>
                        </div>
                      </div>
                      <button className="p-2 hover:bg-slate-100 rounded-full transition-colors">
                        <MoreHorizontal className="w-5 h-5 text-slate-600" />
                      </button>
                    </div>

                    {/* Post Content */}
                    <div className="mt-3">
                      <h4 className="font-semibold text-slate-900 mb-2">{post.title}</h4>
                      <div 
                        className="text-slate-700 text-sm leading-relaxed"
                        dangerouslySetInnerHTML={{ __html: post.content }}
                      />
                    </div>
                  </div>

                  {/* Post Stats */}
                  <div className="px-4 py-2 flex items-center justify-between text-xs text-slate-600 border-t border-slate-200">
                    <div className="flex items-center gap-1">
                      {post.likeCount > 0 && (
                        <>
                          <div className="flex -space-x-1">
                            <div className="w-4 h-4 rounded-full bg-teal-500 flex items-center justify-center">
                              <ThumbsUp className="w-2.5 h-2.5 text-white fill-white" />
                            </div>
                          </div>
                          <span className="ml-1">{post.likeCount}</span>
                        </>
                      )}
                    </div>
                    <div className="flex items-center gap-3">
                      {post.commentCount > 0 && (
                        <span>{post.commentCount} comment{post.commentCount !== 1 ? 's' : ''}</span>
                      )}
                      {post.viewCount > 0 && (
                        <span>{post.viewCount} view{post.viewCount !== 1 ? 's' : ''}</span>
                      )}
                    </div>
                  </div>

                  {/* Post Actions */}
                  <div className="px-2 py-1 flex items-center justify-around border-t border-slate-200">
                    <button
                      onClick={() => toggleLike(post.id)}
                      className={`flex items-center gap-2 px-4 py-3 hover:bg-slate-50 rounded-lg font-medium transition-colors flex-1 justify-center ${
                        post.isLikedByUser ? 'text-teal-600' : 'text-slate-600'
                      }`}
                    >
                      <ThumbsUp className={`w-5 h-5 ${post.isLikedByUser ? 'fill-teal-600' : ''}`} />
                      <span>Like</span>
                    </button>
                    <button
                      onClick={() => toggleComments(post.id)}
                      className="flex items-center gap-2 px-4 py-3 hover:bg-slate-50 rounded-lg text-slate-600 font-medium transition-colors flex-1 justify-center"
                    >
                      <MessageCircle className="w-5 h-5" />
                      <span>Comment</span>
                    </button>
                    <div className="relative flex-1">
                      <button
                        onClick={(e) => { e.stopPropagation(); setSharePostId(sharePostId === post.id ? null : post.id); }}
                        className="flex items-center gap-2 px-4 py-3 hover:bg-slate-50 rounded-lg text-slate-600 font-medium transition-colors w-full justify-center"
                      >
                        <Share2 className="w-5 h-5" />
                        <span>Share</span>
                      </button>
                      {sharePostId === post.id && (
                        <div onClick={(e) => e.stopPropagation()} className="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 z-50 w-52 rounded-xl border border-slate-200 bg-white shadow-lg overflow-hidden">
                          <button
                            onClick={() => { void copyLink(post.id); }}
                            className="flex w-full items-center gap-3 px-4 py-3 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                          >
                            <span className="text-base">🔗</span>
                            Copy link
                          </button>
                          <a
                            href={`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(getPostUrl(post.id))}`}
                            target="_blank" rel="noopener noreferrer"
                            className="flex w-full items-center gap-3 px-4 py-3 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                          >
                            <span className="text-base">📘</span> Facebook
                          </a>
                          <a
                            href={`https://t.me/share/url?url=${encodeURIComponent(getPostUrl(post.id))}`}
                            target="_blank" rel="noopener noreferrer"
                            className="flex w-full items-center gap-3 px-4 py-3 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                          >
                            <span className="text-base">✈️</span> Telegram
                          </a>
                          <a
                            href={`https://wa.me/?text=${encodeURIComponent(getPostUrl(post.id))}`}
                            target="_blank" rel="noopener noreferrer"
                            className="flex w-full items-center gap-3 px-4 py-3 text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                          >
                            <span className="text-base">💬</span> WhatsApp
                          </a>
                        </div>
                      )}
                    </div>
                    <button className="flex items-center gap-2 px-4 py-3 hover:bg-slate-50 rounded-lg text-slate-600 font-medium transition-colors flex-1 justify-center">
                      <Send className="w-5 h-5" />
                      <span>Send</span>
                    </button>
                  </div>

                  {/* Comments Section */}
                  {selectedPost?.id === post.id && (
                    <div className="border-t border-slate-200 p-4 bg-slate-50">
                      {/* Add Comment */}
                      <div className="flex gap-3 mb-4">
                        <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center text-xs font-bold text-slate-600">
                          {currentUser ? getInitials(currentUser.fullName || 'User') : 'U'}
                        </div>
                        <div className="flex-1 flex gap-2">
                          <input
                            type="text"
                            value={newComment}
                            onChange={(e) => setNewComment(e.target.value)}
                            onKeyPress={(e) => e.key === 'Enter' && newComment.trim().length >= 10 && addComment(post.id)}
                            placeholder="Add a comment (min 10 characters)..."
                            className="flex-1 px-4 py-2 rounded-full border border-slate-300 focus:outline-none focus:border-slate-400 text-sm"
                          />
                          <button
                            onClick={() => addComment(post.id)}
                            disabled={newComment.trim().length < 10}
                            className="px-4 py-2 bg-teal-600 text-white rounded-full hover:bg-teal-700 transition-colors disabled:bg-slate-300 disabled:cursor-not-allowed text-sm font-medium"
                          >
                            Post
                          </button>
                        </div>
                      </div>

                      {/* Comments List */}
                      <div className="space-y-4">
                        {comments.map((comment) => (
                          <div key={comment.id} className="flex gap-3">
                            <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center text-xs font-bold text-slate-600">
                              {getInitials(comment.author.full_name)}
                            </div>
                            <div className="flex-1">
                              <div className="bg-white rounded-lg px-4 py-2 border border-slate-200">
                                <div className="flex items-center gap-2">
                                  <span className="font-semibold text-sm text-slate-900">{comment.author.full_name}</span>
                                  <span className="text-xs text-slate-500">• {getRoleBadge(comment.author.role).label}</span>
                                </div>
                                <p className="text-sm text-slate-700 mt-1">{comment.content}</p>
                              </div>
                              <div className="flex items-center gap-4 mt-1 px-2 text-xs text-slate-600 font-medium">
                                <button className="hover:text-teal-600">Like</button>
                                <button className="hover:text-teal-600">Reply</button>
                                <span>{formatTimeAgo(comment.createdAt)}</span>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="mt-6 flex justify-center gap-2">
                <button
                  onClick={() => fetchPosts(currentPage - 1, filter !== 'ALL' ? filter : undefined)}
                  disabled={currentPage === 1}
                  className="px-4 py-2 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed font-medium text-sm"
                >
                  Previous
                </button>
                <span className="px-4 py-2 bg-white border border-slate-300 rounded-lg text-sm">
                  Page {currentPage} of {totalPages}
                </span>
                <button
                  onClick={() => fetchPosts(currentPage + 1, filter !== 'ALL' ? filter : undefined)}
                  disabled={currentPage === totalPages}
                  className="px-4 py-2 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed font-medium text-sm"
                >
                  Next
                </button>
              </div>
            )}
          </div>

          {/* Right Sidebar - News/Suggestions */}
          <div className="lg:col-span-3">
            <div className="bg-white rounded-lg border border-slate-200 p-4 sticky top-6">
              <h3 className="font-semibold text-slate-900 mb-4">InternLink News</h3>
              <div className="space-y-4">
                <div>
                  <h4 className="text-sm font-semibold text-slate-900 hover:text-teal-600 cursor-pointer">
                    New internship opportunities
                  </h4>
                  <p className="text-xs text-slate-600 mt-1">2 hours ago • 45 readers</p>
                </div>
                <div>
                  <h4 className="text-sm font-semibold text-slate-900 hover:text-teal-600 cursor-pointer">
                    Student success stories
                  </h4>
                  <p className="text-xs text-slate-600 mt-1">5 hours ago • 128 readers</p>
                </div>
                <div>
                  <h4 className="text-sm font-semibold text-slate-900 hover:text-teal-600 cursor-pointer">
                    Company partnerships
                  </h4>
                  <p className="text-xs text-slate-600 mt-1">1 day ago • 89 readers</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Copy link toast */}
      {copyDone && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-[100] flex items-center gap-3 rounded-2xl bg-slate-900 px-5 py-3.5 shadow-2xl animate-in fade-in slide-in-from-bottom-4 duration-300">
          <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-emerald-500">
            <svg className="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div>
            <p className="text-sm font-semibold text-white">Link copied!</p>
            <p className="text-xs text-slate-400">Ready to share anywhere</p>
          </div>
        </div>
      )}

      {/* Create Post Modal */}
      {showCreatePost && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between p-4 border-b border-slate-200">
              <h2 className="text-xl font-semibold text-slate-900">Create a post</h2>
              <button
                onClick={() => setShowCreatePost(false)}
                className="p-2 hover:bg-slate-100 rounded-full transition-colors"
              >
                <X className="w-5 h-5 text-slate-600" />
              </button>
            </div>

            <div className="p-4">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 rounded-full bg-slate-200 flex items-center justify-center text-sm font-bold text-slate-600">
                  {currentUser ? getInitials(currentUser.fullName || 'User') : 'U'}
                </div>
                <div>
                  <h3 className="font-semibold text-slate-900">{currentUser?.fullName || 'User'}</h3>
                  <select
                    value={newPostType}
                    onChange={(e) => setNewPostType(e.target.value as any)}
                    className="text-sm border border-slate-300 rounded px-2 py-1 mt-1"
                  >
                    <option value="GENERAL_UPDATE">📝 General Update</option>
                    <option value="ANNOUNCEMENT">📢 Announcement</option>
                    <option value="OPPORTUNITY">💼 Opportunity</option>
                    <option value="EXPERIENCE">✨ Experience</option>
                  </select>
                </div>
              </div>

              <textarea
                value={newPostContent}
                onChange={(e) => setNewPostContent(e.target.value)}
                placeholder="What do you want to talk about?"
                rows={8}
                className="w-full px-4 py-3 border-0 focus:outline-none text-slate-900 resize-none"
              />

              <div className="flex items-center gap-2 mt-4 pt-4 border-t border-slate-200">
                <button className="p-2 hover:bg-slate-100 rounded transition-colors">
                  <ImageIcon className="w-5 h-5 text-slate-600" />
                </button>
                <button className="p-2 hover:bg-slate-100 rounded transition-colors">
                  <Video className="w-5 h-5 text-slate-600" />
                </button>
                <button className="p-2 hover:bg-slate-100 rounded transition-colors">
                  <FileText className="w-5 h-5 text-slate-600" />
                </button>
              </div>
            </div>

            <div className="p-4 border-t border-slate-200">
              <button
                onClick={createPost}
                disabled={!newPostContent.trim()}
                className="w-full py-3 bg-teal-600 text-white rounded-full hover:bg-teal-700 transition-colors disabled:bg-slate-300 disabled:cursor-not-allowed font-semibold"
              >
                Post
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
