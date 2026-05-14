'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api/client';
import {
  Briefcase, Clock, Users, ChevronRight, CheckCircle,
  Search, Sparkles, Building2, Filter
} from 'lucide-react';

interface Opportunity {
  id: number;
  status: 'OPEN' | 'CLOSED' | 'FILLED';
  deadline: string | null;
  slots: number;
  applicationCount: number;
  hasApplied: boolean;
  post: {
    id: number; title: string; content: string; createdAt: string;
    author: { id: number; full_name: string; role: string };
  };
  questions: { id: number; question: string; required: boolean }[];
}

function stripHtml(html: string) {
  return html.replace(/<[^>]*>/g, '').trim();
}

function DeadlinePill({ deadline }: { deadline: string }) {
  const days = Math.ceil((new Date(deadline).getTime() - Date.now()) / 86400000);
  if (days < 0) return <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-500 dark:bg-slate-800 dark:text-slate-400">Expired</span>;
  if (days === 0) return <span className="inline-flex items-center gap-1 rounded-full bg-red-100 px-2 py-0.5 text-xs font-semibold text-red-600 dark:bg-red-900/30 dark:text-red-400"><Clock className="h-3 w-3" />Closes today</span>;
  if (days <= 3) return <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 px-2 py-0.5 text-xs font-semibold text-orange-600 dark:bg-orange-900/30 dark:text-orange-400"><Clock className="h-3 w-3" />{days}d left</span>;
  return <span className="inline-flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500"><Clock className="h-3 w-3" />{new Date(deadline).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>;
}

export default function StudentJobOpportunitiesPage() {
  const router = useRouter();
  const [opps, setOpps] = useState<Opportunity[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'OPEN' | 'ALL'>('OPEN');
  const [search, setSearch] = useState('');

  useEffect(() => {
    setLoading(true);
    api.get(`/job-opportunities?status=${filter}&limit=50`)
      .then(({ data }) => setOpps(data.data.opportunities ?? []))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [filter]);

  const filtered = opps.filter((o) =>
    o.post.title.toLowerCase().includes(search.toLowerCase()) ||
    o.post.author.full_name.toLowerCase().includes(search.toLowerCase()) ||
    stripHtml(o.post.content).toLowerCase().includes(search.toLowerCase())
  );

  const openCount = opps.filter(o => o.status === 'OPEN').length;
  const appliedCount = opps.filter(o => o.hasApplied).length;

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 space-y-6">

      {/* Hero header */}
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-teal-600 to-teal-700 p-6 text-white shadow-lg shadow-teal-600/20">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute -top-4 -right-4 h-32 w-32 rounded-full bg-white" />
          <div className="absolute -bottom-8 -left-8 h-40 w-40 rounded-full bg-white" />
        </div>
        <div className="relative">
          <div className="flex items-center gap-2 mb-2">
            <Sparkles className="h-5 w-5 text-teal-200" />
            <span className="text-sm font-medium text-teal-100">Opportunities for you</span>
          </div>
          <h1 className="text-2xl font-bold mb-1">Job Opportunities</h1>
          <p className="text-sm text-teal-100 mb-4">Browse and apply for internship roles posted by supervisors</p>
          <div className="flex items-center gap-4 text-sm">
            <span className="flex items-center gap-1.5 bg-white/20 rounded-full px-3 py-1">
              <span className="h-2 w-2 rounded-full bg-emerald-300 animate-pulse" />
              {openCount} open now
            </span>
            {appliedCount > 0 && (
              <span className="flex items-center gap-1.5 bg-white/20 rounded-full px-3 py-1">
                <CheckCircle className="h-3.5 w-3.5 text-teal-200" />
                {appliedCount} applied
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Search + filter */}
      <div className="flex gap-3 flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by title, company, or keyword…"
            className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 pl-10 pr-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 shadow-sm"
          />
        </div>
        <div className="flex items-center gap-1 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-1 shadow-sm">
          <Filter className="h-4 w-4 text-slate-400 ml-2" />
          {(['OPEN', 'ALL'] as const).map((s) => (
            <button
              key={s}
              onClick={() => setFilter(s)}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-all ${filter === s ? 'bg-teal-600 text-white shadow-sm' : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'}`}
            >
              {s === 'OPEN' ? 'Open' : 'All'}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      {loading ? (
        <div className="space-y-3">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-32 animate-pulse rounded-2xl bg-slate-100 dark:bg-slate-800" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-20 bg-white dark:bg-slate-900 rounded-2xl border-2 border-dashed border-slate-200 dark:border-slate-700">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 dark:bg-slate-800 mx-auto mb-4">
            <Briefcase className="h-8 w-8 text-slate-400" />
          </div>
          <h3 className="font-semibold text-slate-900 dark:text-slate-100 mb-1">
            {search ? 'No results found' : 'No opportunities available'}
          </h3>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            {search ? 'Try a different search term' : 'Check back later for new postings'}
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((opp) => {
            const preview = stripHtml(opp.post.content).slice(0, 140);
            const isNew = (Date.now() - new Date(opp.post.createdAt).getTime()) < 86400000 * 2;

            return (
              <div
                key={opp.id}
                onClick={() => router.push(`/student/job-opportunities/${opp.id}`)}
                className="group relative bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 p-5 hover:border-teal-300 dark:hover:border-teal-700 hover:shadow-lg hover:shadow-teal-500/5 transition-all cursor-pointer"
              >
                {/* Applied ribbon */}
                {opp.hasApplied && (
                  <div className="absolute top-0 right-0 overflow-hidden rounded-tr-2xl w-16 h-16 pointer-events-none">
                    <div className="absolute top-3 right-[-14px] rotate-45 bg-teal-500 text-white text-[9px] font-bold px-5 py-0.5 shadow-sm">
                      Applied
                    </div>
                  </div>
                )}

                <div className="flex items-start gap-4">
                  {/* Company avatar */}
                  <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-teal-500 to-teal-600 text-white font-bold text-lg shadow-sm shadow-teal-500/30 group-hover:scale-105 transition-transform">
                    {opp.post.author.full_name.charAt(0).toUpperCase()}
                  </div>

                  <div className="flex-1 min-w-0">
                    {/* Badges row */}
                    <div className="flex items-center gap-2 mb-1.5 flex-wrap">
                      {opp.status === 'OPEN' && !opp.hasApplied && (
                        <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-semibold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                          <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />Open
                        </span>
                      )}
                      {opp.status === 'CLOSED' && <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">Closed</span>}
                      {opp.status === 'FILLED' && <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">Filled</span>}
                      {isNew && opp.status === 'OPEN' && !opp.hasApplied && (
                        <span className="inline-flex items-center gap-1 rounded-full bg-violet-100 px-2 py-0.5 text-xs font-semibold text-violet-700 dark:bg-violet-900/30 dark:text-violet-400">
                          <Sparkles className="h-3 w-3" />New
                        </span>
                      )}
                      {opp.deadline && <DeadlinePill deadline={opp.deadline} />}
                    </div>

                    <h3 className="font-semibold text-slate-900 dark:text-slate-100 text-base leading-snug group-hover:text-teal-600 dark:group-hover:text-teal-400 transition-colors">
                      {opp.post.title}
                    </h3>

                    <div className="flex items-center gap-1.5 mt-0.5 text-xs text-slate-500 dark:text-slate-400">
                      <Building2 className="h-3.5 w-3.5" />
                      <span>{opp.post.author.full_name}</span>
                    </div>

                    {preview && (
                      <p className="text-sm text-slate-500 dark:text-slate-400 mt-2 line-clamp-2 leading-relaxed">
                        {preview}{preview.length === 140 ? '…' : ''}
                      </p>
                    )}

                    <div className="flex items-center gap-4 mt-3 text-xs text-slate-400 dark:text-slate-500">
                      <span className="flex items-center gap-1">
                        <Users className="h-3.5 w-3.5" />{opp.applicationCount} applied
                      </span>
                      <span>{opp.slots} slot{opp.slots !== 1 ? 's' : ''}</span>
                      {opp.questions.length > 0 && (
                        <span>{opp.questions.length} question{opp.questions.length !== 1 ? 's' : ''}</span>
                      )}
                    </div>
                  </div>

                  <div className="flex flex-col items-end gap-2 shrink-0">
                    <ChevronRight className="h-5 w-5 text-slate-300 dark:text-slate-600 group-hover:text-teal-500 group-hover:translate-x-0.5 transition-all" />
                    {opp.status === 'OPEN' && !opp.hasApplied && (
                      <span className="text-xs font-semibold text-teal-600 dark:text-teal-400 opacity-0 group-hover:opacity-100 transition-opacity">
                        Apply →
                      </span>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
