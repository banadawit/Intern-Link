'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import api from '@/lib/api/client';
import {
  Briefcase, Plus, Users, Clock, CheckCircle, XCircle,
  ChevronRight, TrendingUp, BarChart2, Layers
} from 'lucide-react';

interface Opportunity {
  id: number;
  status: 'OPEN' | 'CLOSED' | 'FILLED';
  deadline: string | null;
  slots: number;
  applicationCount: number;
  post: { id: number; title: string; content: string; createdAt: string };
  questions: { id: number; question: string; required: boolean }[];
}

function StatusBadge({ status }: { status: string }) {
  if (status === 'OPEN') return (
    <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
      <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />Open
    </span>
  );
  if (status === 'FILLED') return (
    <span className="inline-flex items-center gap-1 rounded-full bg-teal-100 px-2.5 py-1 text-xs font-semibold text-teal-700 dark:bg-teal-900/30 dark:text-teal-400">
      <CheckCircle className="h-3 w-3" />Filled
    </span>
  );
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">
      <XCircle className="h-3 w-3" />Closed
    </span>
  );
}

function StripHtml(html: string) {
  return html.replace(/<[^>]*>/g, '').slice(0, 120);
}

export default function SupervisorJobOpportunitiesPage() {
  const router = useRouter();
  const [opps, setOpps] = useState<Opportunity[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' } | null>(null);

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 4000);
  };

  useEffect(() => {
    api.get('/job-opportunities/mine')
      .then(({ data }) => setOpps(data.data ?? []))
      .catch(() => showToast('Failed to load opportunities.', 'error'))
      .finally(() => setLoading(false));
  }, []);

  const stats = {
    total: opps.length,
    open: opps.filter(o => o.status === 'OPEN').length,
    totalApplicants: opps.reduce((s, o) => s + o.applicationCount, 0),
  };

  if (loading) return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="flex flex-col items-center gap-3">
        <div className="animate-spin rounded-full h-10 w-10 border-2 border-teal-600 border-t-transparent" />
        <p className="text-sm text-slate-500 dark:text-slate-400">Loading opportunities…</p>
      </div>
    </div>
  );

  return (
    <div className="max-w-5xl mx-auto px-4 py-8 space-y-8">

      {/* Header */}
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-teal-600 shadow-sm shadow-teal-600/30">
              <Briefcase className="h-5 w-5 text-white" />
            </div>
            <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">Job Opportunities</h1>
          </div>
          <p className="text-sm text-slate-500 dark:text-slate-400 ml-11">Post roles, review applicants, and hire the best talent</p>
        </div>
        <button
          onClick={() => router.push('/supervisor/job-opportunities/create')}
          className="flex items-center gap-2 rounded-xl bg-teal-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-teal-700 active:scale-95 transition-all shadow-sm shadow-teal-600/30"
        >
          <Plus className="h-4 w-4" /> Post Opportunity
        </button>
      </div>

      {/* Stats row */}
      {opps.length > 0 && (
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'Total Posted', value: stats.total, icon: Layers, color: 'bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400' },
            { label: 'Currently Open', value: stats.open, icon: TrendingUp, color: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-900/20 dark:text-emerald-400' },
            { label: 'Total Applicants', value: stats.totalApplicants, icon: BarChart2, color: 'bg-violet-50 text-violet-600 dark:bg-violet-900/20 dark:text-violet-400' },
          ].map(({ label, value, icon: Icon, color }) => (
            <div key={label} className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 p-4 flex items-center gap-3">
              <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${color}`}>
                <Icon className="h-5 w-5" />
              </div>
              <div>
                <p className="text-xl font-bold text-slate-900 dark:text-slate-100">{value}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400">{label}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Empty state */}
      {opps.length === 0 ? (
        <div className="text-center py-24 bg-white dark:bg-slate-900 rounded-2xl border-2 border-dashed border-slate-200 dark:border-slate-700">
          <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-teal-50 dark:bg-teal-900/20 mx-auto mb-4">
            <Briefcase className="h-8 w-8 text-teal-600 dark:text-teal-400" />
          </div>
          <h3 className="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-1">No opportunities yet</h3>
          <p className="text-sm text-slate-500 dark:text-slate-400 mb-6 max-w-xs mx-auto">Post your first job opportunity to start receiving applications from students</p>
          <button
            onClick={() => router.push('/supervisor/job-opportunities/create')}
            className="inline-flex items-center gap-2 rounded-xl bg-teal-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-teal-700 transition-colors"
          >
            <Plus className="h-4 w-4" /> Post Your First Opportunity
          </button>
        </div>
      ) : (
        <div className="space-y-3">
          {opps.map((opp) => {
            const daysLeft = opp.deadline
              ? Math.ceil((new Date(opp.deadline).getTime() - Date.now()) / 86400000)
              : null;
            const isUrgent = daysLeft !== null && daysLeft <= 3 && daysLeft >= 0;

            return (
              <div
                key={opp.id}
                onClick={() => router.push(`/supervisor/job-opportunities/${opp.id}`)}
                className="group bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 p-5 hover:border-teal-300 dark:hover:border-teal-700 hover:shadow-lg hover:shadow-teal-500/5 transition-all cursor-pointer"
              >
                <div className="flex items-start gap-4">
                  {/* Icon */}
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-teal-500 to-teal-600 shadow-sm shadow-teal-500/30 group-hover:scale-105 transition-transform">
                    <Briefcase className="h-5 w-5 text-white" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1 flex-wrap">
                      <StatusBadge status={opp.status} />
                      {isUrgent && (
                        <span className="inline-flex items-center gap-1 rounded-full bg-red-100 px-2.5 py-1 text-xs font-semibold text-red-600 dark:bg-red-900/30 dark:text-red-400">
                          <Clock className="h-3 w-3" />{daysLeft === 0 ? 'Closes today' : `${daysLeft}d left`}
                        </span>
                      )}
                      {!isUrgent && opp.deadline && (
                        <span className="inline-flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">
                          <Clock className="h-3 w-3" />{new Date(opp.deadline).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                        </span>
                      )}
                    </div>

                    <h3 className="font-semibold text-slate-900 dark:text-slate-100 text-base group-hover:text-teal-600 dark:group-hover:text-teal-400 transition-colors">
                      {opp.post.title}
                    </h3>
                    <p className="text-sm text-slate-500 dark:text-slate-400 mt-0.5 line-clamp-1">
                      {StripHtml(opp.post.content)}
                    </p>

                    <div className="flex items-center gap-4 mt-3 text-xs text-slate-500 dark:text-slate-400">
                      <span className="flex items-center gap-1.5">
                        <Users className="h-3.5 w-3.5 text-teal-500" />
                        <strong className="text-slate-700 dark:text-slate-300">{opp.applicationCount}</strong> applicant{opp.applicationCount !== 1 ? 's' : ''}
                      </span>
                      <span className="flex items-center gap-1.5">
                        <Layers className="h-3.5 w-3.5 text-blue-500" />
                        <strong className="text-slate-700 dark:text-slate-300">{opp.slots}</strong> slot{opp.slots !== 1 ? 's' : ''}
                      </span>
                      {opp.questions.length > 0 && (
                        <span className="flex items-center gap-1.5">
                          <span className="h-3.5 w-3.5 text-center text-violet-500 font-bold text-[10px]">Q</span>
                          <strong className="text-slate-700 dark:text-slate-300">{opp.questions.length}</strong> question{opp.questions.length !== 1 ? 's' : ''}
                        </span>
                      )}
                      <span className="ml-auto text-slate-400">
                        Posted {new Date(opp.post.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                      </span>
                    </div>
                  </div>

                  <ChevronRight className="h-5 w-5 text-slate-300 dark:text-slate-600 group-hover:text-teal-500 group-hover:translate-x-0.5 transition-all shrink-0 mt-1" />
                </div>
              </div>
            );
          })}
        </div>
      )}

      {toast && (
        <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2 rounded-2xl px-5 py-3 shadow-2xl text-sm font-semibold text-white ${toast.type === 'error' ? 'bg-red-600' : 'bg-slate-900'}`}>
          {toast.type === 'error' ? <XCircle className="h-4 w-4" /> : <CheckCircle className="h-4 w-4 text-emerald-400" />}
          {toast.msg}
        </div>
      )}
    </div>
  );
}
