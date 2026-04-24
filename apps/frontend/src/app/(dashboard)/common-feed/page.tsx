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
  const [showUserProfile, setShowUserProfile] = useState(false);
  const [selectedUserId, setSelectedUserId] = useState<number | null>(null);
  const [userProfileData, setUserProfileData] = useState<any>(null);
  const [userPosts, setUserPosts] = useState<Post[]>([]);
  const [loadingProfile, setLoadingProfile] = useState(false);

  const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

  const getToken = () => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('token');
    }
    return null;
  };

  const getCurrentUser = () => {
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('token');
      if (token) {
        try {
          // Decode JWT token to get user info
          const parts = token.split('.');
          if (parts.length !== 3) {
            console.error('Invalid token format - expected 3 parts, got:', parts.length);
            return null;
          }
          
          const base64Url = parts[1];
          const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
          const jsonPayload = atob(base64);
          
          const decoded = JSON.parse(jsonPayload);
          console.log('Decoded JWT payload:', decoded);
          
          // Ensure userId is a number
          const userId = typeof decoded.userId === 'number' ? decoded.userId : parseInt(decoded.userId, 10);
          
          if (isNaN(userId)) {
            console.error('Invalid userId in token:', decoded.userId);
            return null;
          }
          
          return {
            userId: userId,
            id: userId, // Add both for compatibility
            email: decoded.email,
            role: decoded.role,
            fullName: decoded.fullName || decoded.full_name || decoded.name || 'User'
          };
        } catch (error) {
          console.error('Error decoding token:', error);
        }
      }
      
      // Fallback to localStorage user if token decode fails
      const userStr = localStorage.getItem('user');
      if (userStr) {
        const user = JSON.parse(userStr);
        console.log('User from localStorage:', user);
        return user;
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

  const openUserProfile = async (userId: number | undefined) => {
    console.log('=== openUserProfile called ===');
    console.log('userId parameter:', userId, 'type:', typeof userId);
    console.log('Current user object:', currentUser);
    
    if (!userId) {
      console.error('No userId provided to openUserProfile');
      alert('Cannot open profile: User ID is missing');
      return;
    }
    
    setSelectedUserId(userId);
    setShowUserProfile(true);
    setLoadingProfile(true);

    try {
      const token = getToken();
      const url = `${API_BASE}/common-feed/user/${userId}`;
      console.log('Fetching user profile from:', url);
      
      const response = await axios.get(url, {
        headers: { Authorization: `Bearer ${token}` }
      });

      console.log('Profile response:', response.data);
      setUserProfileData(response.data.data.user);
      setUserPosts(response.data.data.posts);
      setLoadingProfile(false);
    } catch (error: any) {
      console.error('Error fetching user profile:', error);
      console.error('Error response:', error.response?.data);
      alert(`Failed to load profile: ${error.response?.data?.message || error.message}`);
      setLoadingProfile(false);
      setShowUserProfile(false);
    }
  };

  const deleteUserPost = async (postId: number) => {
    if (!confirm('Are you sure you want to delete this post?')) return;

    try {
      const token = getToken();
      await axios.delete(`${API_BASE}/common-feed/${postId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });

      // Remove from user posts
      setUserPosts(userPosts.filter(p => p.id !== postId));
      
      // Also remove from main feed if present
      setPosts(posts.filter(p => p.id !== postId));
      
      alert('Post deleted successfully');
    } catch (error) {
      console.error('Error deleting post:', error);
      alert('Failed to delete post');
    }
  };

  useEffect(() => {
    const user = getCurrentUser();
    console.log('=== Current User from localStorage ===');
    console.log('User object:', user);
    console.log('User keys:', user ? Object.keys(user) : 'null');
    setCurrentUser(user);
    fetchPosts(1);
  }, []);

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
                <div 
                  onClick={() => {
                    const userId = currentUser?.userId || currentUser?.id;
                    if (userId) openUserProfile(userId);
                  }}
                  className="w-12 h-12 rounded-full bg-slate-200 flex items-center justify-center text-sm font-bold text-slate-600 cursor-pointer hover:bg-slate-300 transition-colors"
                >
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
                        <div 
                          onClick={() => openUserProfile(post.author.id)}
                          className="w-12 h-12 rounded-full bg-slate-200 flex items-center justify-center text-sm font-bold text-slate-600 cursor-pointer hover:bg-slate-300 transition-colors"
                        >
                          {getInitials(post.author.full_name)}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h3 
                              onClick={() => openUserProfile(post.author.id)}
                              className="font-semibold text-slate-900 hover:text-teal-600 cursor-pointer"
                            >
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
                    <button className="flex items-center gap-2 px-4 py-3 hover:bg-slate-50 rounded-lg text-slate-600 font-medium transition-colors flex-1 justify-center">
                      <Share2 className="w-5 h-5" />
                      <span>Share</span>
                    </button>
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
                            onKeyDown={(e) => e.key === 'Enter' && addComment(post.id)}
                            placeholder="Add a comment..."
                            className="flex-1 px-4 py-2 rounded-full border border-slate-300 focus:outline-none focus:border-slate-400 text-sm"
                          />
                          <button
                            onClick={() => addComment(post.id)}
                            disabled={!newComment.trim()}
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
                            <div 
                              onClick={() => openUserProfile(comment.author.id)}
                              className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center text-xs font-bold text-slate-600 cursor-pointer hover:bg-slate-300 transition-colors"
                            >
                              {getInitials(comment.author.full_name)}
                            </div>
                            <div className="flex-1">
                              <div className="bg-white rounded-lg px-4 py-2 border border-slate-200">
                                <div className="flex items-center gap-2">
                                  <span 
                                    onClick={() => openUserProfile(comment.author.id)}
                                    className="font-semibold text-sm text-slate-900 cursor-pointer hover:text-teal-600"
                                  >
                                    {comment.author.full_name}
                                  </span>
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

      {/* User Profile Modal */}
      {showUserProfile && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl max-w-4xl w-full max-h-[85vh] overflow-hidden shadow-2xl animate-in zoom-in-95 duration-200">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 bg-gradient-to-r from-teal-50 to-emerald-50">
              <h2 className="text-xl font-bold text-slate-900">User Profile</h2>
              <button
                onClick={() => {
                  setShowUserProfile(false);
                  setUserProfileData(null);
                  setUserPosts([]);
                }}
                className="p-2 hover:bg-white/80 rounded-full transition-all duration-200 hover:rotate-90"
              >
                <X className="w-5 h-5 text-slate-600" />
              </button>
            </div>

            {/* Content */}
            <div className="overflow-y-auto max-h-[calc(85vh-73px)]">
              {loadingProfile ? (
                <div className="flex flex-col items-center justify-center py-20">
                  <div className="relative">
                    <div className="animate-spin rounded-full h-16 w-16 border-4 border-slate-200"></div>
                    <div className="animate-spin rounded-full h-16 w-16 border-4 border-teal-600 border-t-transparent absolute top-0 left-0"></div>
                  </div>
                  <p className="mt-4 text-slate-600 font-medium">Loading profile...</p>
                </div>
              ) : userProfileData ? (
                <div>
                  {/* Profile Header */}
                  <div className="px-6 py-8 bg-gradient-to-br from-slate-50 to-white border-b border-slate-200">
                    <div className="flex items-center gap-6">
                      <div className="relative">
                        <div className="w-24 h-24 rounded-full bg-gradient-to-br from-teal-400 to-emerald-500 flex items-center justify-center text-3xl font-bold text-white shadow-lg ring-4 ring-white">
                          {getInitials(userProfileData.full_name)}
                        </div>
                        <div className="absolute -bottom-1 -right-1 w-8 h-8 bg-emerald-500 rounded-full border-4 border-white flex items-center justify-center">
                          <span className="text-white text-xs">✓</span>
                        </div>
                      </div>
                      <div className="flex-1">
                        <h3 className="text-3xl font-bold text-slate-900 mb-2">{userProfileData.full_name}</h3>
                        <div className="flex items-center gap-3 mb-2">
                          <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold ${getRoleBadge(userProfileData.role).color} bg-slate-100`}>
                            {getRoleBadge(userProfileData.role).label}
                          </span>
                        </div>
                        <p className="text-slate-600 flex items-center gap-2">
                          <span className="w-2 h-2 bg-emerald-500 rounded-full"></span>
                          {userProfileData.email}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Stats Bar */}
                  <div className="px-6 py-4 bg-white border-b border-slate-200">
                    <div className="flex items-center gap-8">
                      <div className="text-center">
                        <div className="text-2xl font-bold text-slate-900">{userPosts.length}</div>
                        <div className="text-sm text-slate-600">Posts</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-slate-900">
                          {userPosts.reduce((sum, post) => sum + post.likeCount, 0)}
                        </div>
                        <div className="text-sm text-slate-600">Likes</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-slate-900">
                          {userPosts.reduce((sum, post) => sum + post.commentCount, 0)}
                        </div>
                        <div className="text-sm text-slate-600">Comments</div>
                      </div>
                    </div>
                  </div>

                  {/* Posts Section */}
                  <div className="px-6 py-6 bg-slate-50">
                    <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
                      <FileText className="w-5 h-5 text-teal-600" />
                      Recent Posts
                    </h3>

                    {userPosts.length === 0 ? (
                      <div className="text-center py-16 bg-white rounded-xl border-2 border-dashed border-slate-200">
                        <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                          <FileText className="w-8 h-8 text-slate-400" />
                        </div>
                        <p className="text-slate-500 font-medium">No posts yet</p>
                        <p className="text-sm text-slate-400 mt-1">Posts will appear here when created</p>
                      </div>
                    ) : (
                      <div className="space-y-4">
                        {userPosts.map((post) => (
                          <div key={post.id} className="bg-white rounded-xl border border-slate-200 p-5 hover:shadow-md transition-all duration-200 hover:border-teal-200">
                            <div className="flex items-start justify-between mb-3">
                              <div className="flex-1">
                                <div className="flex items-center gap-2 mb-2">
                                  <span className="text-sm font-medium text-teal-600 bg-teal-50 px-3 py-1 rounded-full">
                                    {getPostTypeLabel(post.postType)}
                                  </span>
                                  <span className="text-xs text-slate-500">
                                    {formatTimeAgo(post.createdAt)}
                                  </span>
                                </div>
                                <h4 className="font-bold text-slate-900 text-lg mb-2">{post.title}</h4>
                              </div>
                              {currentUser && (currentUser.userId === post.author.id || currentUser.id === post.author.id) && (
                                <button
                                  onClick={() => deleteUserPost(post.id)}
                                  className="px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 rounded-lg transition-all duration-200 hover:shadow-sm border border-transparent hover:border-red-200"
                                >
                                  Delete
                                </button>
                              )}
                            </div>

                            <div 
                              className="text-slate-700 text-sm leading-relaxed mb-4 line-clamp-3"
                              dangerouslySetInnerHTML={{ __html: post.content }}
                            />

                            <div className="flex items-center gap-6 text-sm text-slate-600 pt-3 border-t border-slate-100">
                              <div className="flex items-center gap-2 hover:text-teal-600 transition-colors">
                                <ThumbsUp className="w-4 h-4" />
                                <span className="font-medium">{post.likeCount}</span>
                              </div>
                              <div className="flex items-center gap-2 hover:text-teal-600 transition-colors">
                                <MessageCircle className="w-4 h-4" />
                                <span className="font-medium">{post.commentCount}</span>
                              </div>
                              <div className="flex items-center gap-2">
                                <span className="font-medium">{post.viewCount} views</span>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              ) : (
                <div className="py-20 text-center">
                  <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <X className="w-8 h-8 text-red-600" />
                  </div>
                  <p className="text-slate-600 font-medium">Failed to load profile</p>
                  <p className="text-sm text-slate-400 mt-1">Please try again later</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
