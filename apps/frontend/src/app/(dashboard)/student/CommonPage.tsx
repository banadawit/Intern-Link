"use client";

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
import StudentPageHero from './StudentPageHero';

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
    <div className="w-full space-y-8 animate-in fade-in duration-500">
      <StudentPageHero
        badge="Common page"
        title="Common Page"
        description="Share experiences, announcements, and updates with the community."
      />

      {/* Create Post Card */}
      <div className="card p-6">
        <form onSubmit={handlePostSubmit} className="space-y-4">
          <div className="flex gap-4">
            <div className="w-12 h-12 rounded-full bg-primary-light flex items-center justify-center text-primary-base font-bold shrink-0">
              JD
            </div>
            <textarea 
              className="flex-1 bg-bg-secondary border border-border-default rounded-2xl p-4 text-sm focus:outline-none focus:ring-2 focus:ring-ring-focus focus:border-transparent transition-all min-h-[100px] resize-none"
              placeholder="Share your experience or an update..."
              value={newPostContent}
              onChange={(e) => setNewPostContent(e.target.value)}
            />
          </div>
          <div className="flex items-center justify-between pl-16">
            <div className="flex items-center gap-2">
              <button type="button" className="p-2 hover:bg-bg-tertiary rounded-lg transition-colors text-text-muted hover:text-primary-base">
                <ImageIcon className="w-5 h-5" />
              </button>
              <button type="button" className="p-2 hover:bg-bg-tertiary rounded-lg transition-colors text-text-muted hover:text-primary-base">
                <Paperclip className="w-5 h-5" />
              </button>
              <button type="button" className="p-2 hover:bg-bg-tertiary rounded-lg transition-colors text-text-muted hover:text-primary-base">
                <Smile className="w-5 h-5" />
              </button>
            </div>
            <button 
              type="submit" 
              disabled={!newPostContent.trim()}
              className="btn-primary flex items-center gap-2 disabled:opacity-50"
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
          <div key={post.id} className="card p-6 space-y-4 hover:shadow-md transition-shadow">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-bg-tertiary flex items-center justify-center text-text-muted font-bold">
                  {post.authorName.charAt(0)}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h4 className="font-bold text-text-heading">{post.authorName}</h4>
                    <span className={cn(
                      "px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider",
                      post.authorRole === 'Coordinator' ? "bg-purple-100 text-purple-700" : "bg-teal-100 text-teal-700"
                    )}>
                      {post.authorRole}
                    </span>
                  </div>
                  <div className="flex items-center gap-1 text-xs text-text-muted">
                    <Clock className="w-3 h-3" />
                    {formatDistanceToNow(new Date(post.timestamp), { addSuffix: true })}
                  </div>
                </div>
              </div>
              <button className="p-2 hover:bg-bg-tertiary rounded-lg transition-colors text-text-muted">
                <MoreHorizontal className="w-5 h-5" />
              </button>
            </div>

            <p className="text-text-body leading-relaxed whitespace-pre-wrap">
              {post.content}
            </p>

            <div className="flex items-center gap-6 pt-4 border-t border-border-default">
              <button className="flex items-center gap-2 text-sm text-text-muted hover:text-status-error transition-colors group">
                <Heart className="w-4 h-4 group-hover:fill-current" />
                <span>{post.likes}</span>
              </button>
              <button className="flex items-center gap-2 text-sm text-text-muted hover:text-primary-base transition-colors">
                <MessageSquare className="w-4 h-4" />
                <span>Reply</span>
              </button>
              <button className="flex items-center gap-2 text-sm text-text-muted hover:text-primary-base transition-colors">
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
