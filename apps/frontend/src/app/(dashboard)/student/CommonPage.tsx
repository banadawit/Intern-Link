"use client";

import React, { useEffect, useMemo, useState } from 'react';
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
import api from '@/lib/api/client';
import { mapFeedAnnouncement } from '@/lib/api/mappers';
import { Post } from '@/lib/superadmin/types';
import { cn } from '@/lib/utils';
import { formatDistanceToNow } from 'date-fns';
import StudentPageHero from './StudentPageHero';
import { useAuth } from '@/lib/hooks/useAuth';

const CommonPage = () => {
  const { user } = useAuth();
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [newPostContent, setNewPostContent] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const loadFeed = async () => {
    try {
      const { data } = await api.get('/feed');
      const rows = (data as Record<string, unknown>[]) ?? [];
      setPosts(
        rows.map((row) =>
          mapFeedAnnouncement(row as Parameters<typeof mapFeedAnnouncement>[0])
        )
      );
    } catch {
      setPosts([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadFeed();
  }, []);

  const postsChronological = useMemo(
    () =>
      [...posts].sort(
        (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
      ),
    [posts]
  );

  const handlePostSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPostContent.trim()) return;
    setSubmitting(true);
    try {
      await api.post('/feed', {
        title: 'Post',
        content: newPostContent.trim(),
      });
      setNewPostContent('');
      await loadFeed();
    } catch {
      /* ignore */
    } finally {
      setSubmitting(false);
    }
  };

  const authorInitials =
    user?.fullName
      ?.split(/\s+/)
      .map((p) => p[0])
      .join('')
      .slice(0, 2)
      .toUpperCase() ?? 'ST';

  return (
    <div className="w-full space-y-8 animate-in fade-in duration-500">
      <StudentPageHero
        badge="Common page"
        title="Common Page"
        description="Share experiences, announcements, and updates with the community."
      />

      {loading && <p className="text-sm text-text-muted">Loading feed…</p>}

      <div className="card p-6">
        <form onSubmit={handlePostSubmit} className="space-y-4">
          <div className="flex gap-4">
            <div className="w-12 h-12 rounded-full bg-primary-light flex items-center justify-center text-primary-base font-bold shrink-0">
              {authorInitials}
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
              disabled={submitting}
              className="btn-primary flex items-center gap-2 px-6 py-2.5 rounded-xl disabled:opacity-60"
            >
              <Send className="w-4 h-4" />
              Post
            </button>
          </div>
        </form>
      </div>

      <div className="space-y-6">
        {postsChronological.map((post) => (
          <div key={post.id} className="card p-6 space-y-4">
            <div className="flex items-start justify-between gap-4">
              <div className="flex gap-3 min-w-0">
                <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-600 font-bold shrink-0 text-sm">
                  {post.authorName
                    .split(/\s+/)
                    .map((n) => n[0])
                    .join('')
                    .slice(0, 2)
                    .toUpperCase()}
                </div>
                <div className="min-w-0">
                  <p className="font-bold text-text-heading truncate">{post.authorName}</p>
                  <p className="text-xs text-text-muted">
                    {post.authorRole} · {formatDistanceToNow(new Date(post.timestamp), { addSuffix: true })}
                  </p>
                </div>
              </div>
              <button type="button" className="text-text-muted hover:text-text-body p-1">
                <MoreHorizontal className="w-5 h-5" />
              </button>
            </div>
            <p className="text-sm text-text-body whitespace-pre-wrap leading-relaxed">{post.content}</p>
            <div className="flex items-center gap-6 pt-2 border-t border-border-default">
              <button type="button" className="flex items-center gap-2 text-sm text-text-muted hover:text-red-500 transition-colors">
                <Heart className="w-4 h-4" />
                {post.likes > 0 ? post.likes : 'Like'}
              </button>
              <button type="button" className="flex items-center gap-2 text-sm text-text-muted hover:text-primary-base transition-colors">
                <MessageSquare className="w-4 h-4" />
                Comment
              </button>
              <button type="button" className="flex items-center gap-2 text-sm text-text-muted hover:text-primary-base transition-colors">
                <Share2 className="w-4 h-4" />
                Share
              </button>
            </div>
          </div>
        ))}
        {!loading && postsChronological.length === 0 && (
          <p className="text-center text-text-muted py-12">No posts yet. Be the first to share an update.</p>
        )}
      </div>
    </div>
  );
};

export default CommonPage;
