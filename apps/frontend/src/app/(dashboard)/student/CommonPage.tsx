'use client';

import React, { useState } from 'react';
import { 
  MessageSquare, 
  Send, 
  Heart, 
  Share2, 
  MoreHorizontal,
  User,
  Clock,
  TrendingUp,
  Image as ImageIcon,
  Smile,
  Paperclip
} from 'lucide-react';
import { MOCK_POSTS } from '@/lib/superadmin/mockData';
import { Post } from '@/lib/superadmin/types';
import { cn } from '@/lib/utils';
import { formatDistanceToNow } from 'date-fns';

const CommonPage = () => {
  const [posts, setPosts] = useState<Post[]>(MOCK_POSTS);
  const [newPostContent, setNewPostContent] = useState('');

  const handlePostSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPostContent.trim()) return;

    const newPost: Post = {
      id: `p${Date.now()}`,
      authorName: 'John Doe',
      authorRole: 'Student',
      content: newPostContent,
      timestamp: new Date().toISOString(),
      likes: 0,
    };
    setPosts([newPost, ...posts]);
    setNewPostContent('');
  };

  return (
    <div className="max-w-4xl mx-auto space-y-8 animate-in fade-in duration-500">
      <header>
        <h1 className="text-3xl font-bold mb-2 text-slate-900">Common Page</h1>
        <p className="text-slate-600">Share experiences, announcements, and updates with the community.</p>
      </header>

      {/* Create Post Card */}
      <div className="card p-6 bg-white border border-slate-200">
        <form onSubmit={handlePostSubmit} className="space-y-4">
          <div className="flex gap-4">
            <div className="w-12 h-12 rounded-full bg-teal-50 flex items-center justify-center text-teal-600 font-bold shrink-0">
              JD
            </div>
            <textarea 
              className="flex-1 bg-slate-50 border border-slate-200 rounded-2xl p-4 text-sm focus:outline-none focus:ring-2 focus:ring-teal-600 focus:border-transparent transition-all min-h-[100px] resize-none text-slate-900"
              placeholder="Share your experience or an update..."
              value={newPostContent}
              onChange={(e) => setNewPostContent(e.target.value)}
            />
          </div>
          <div className="flex items-center justify-between pl-16">
            <div className="flex items-center gap-2">
              <button type="button" className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-500 hover:text-teal-600">
                <ImageIcon className="w-5 h-5" />
              </button>
              <button type="button" className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-500 hover:text-teal-600">
                <Paperclip className="w-5 h-5" />
              </button>
              <button type="button" className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-500 hover:text-teal-600">
                <Smile className="w-5 h-5" />
              </button>
            </div>
            <button 
              type="submit" 
              disabled={!newPostContent.trim()}
              className="bg-teal-600 hover:bg-teal-700 text-white font-medium py-2 px-4 rounded-lg transition-all flex items-center gap-2 disabled:opacity-50"
            >
              <Send className="w-4 h-4" />
              Post
            </button>
          </div>
        </form>
      </div>

      {/* Posts Feed */}
      <div className="space-y-6">
        {posts.map((post) => (
          <div key={post.id} className="card p-6 space-y-4 hover:shadow-md transition-shadow bg-white border border-slate-200">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 font-bold">
                  {post.authorName.charAt(0)}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h4 className="font-bold text-slate-900">{post.authorName}</h4>
                    <span className={cn(
                      "px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider",
                      post.authorRole === 'Coordinator' ? "bg-purple-50 text-purple-600" : "bg-teal-50 text-teal-600"
                    )}>
                      {post.authorRole}
                    </span>
                  </div>
                  <div className="flex items-center gap-1 text-xs text-slate-500">
                    <Clock className="w-3 h-3 text-slate-500" />
                    {formatDistanceToNow(new Date(post.timestamp), { addSuffix: true })}
                  </div>
                </div>
              </div>
              <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors text-slate-500">
                <MoreHorizontal className="w-5 h-5" />
              </button>
            </div>

            <p className="text-slate-600 leading-relaxed whitespace-pre-wrap">
              {post.content}
            </p>

            <div className="flex items-center gap-6 pt-4 border-t border-slate-200">
              <button className="flex items-center gap-2 text-sm text-slate-500 hover:text-red-500 transition-colors group">
                <Heart className="w-4 h-4 group-hover:fill-current" />
                <span>{post.likes}</span>
              </button>
              <button className="flex items-center gap-2 text-sm text-slate-500 hover:text-teal-600 transition-colors">
                <MessageSquare className="w-4 h-4" />
                <span>Reply</span>
              </button>
              <button className="flex items-center gap-2 text-sm text-slate-500 hover:text-teal-600 transition-colors">
                <Share2 className="w-4 h-4" />
                <span>Share</span>
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default CommonPage;
