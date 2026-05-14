'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import api from '@/lib/api/client';
import {
  ArrowLeft, Briefcase, Clock, Users, CheckCircle, AlertCircle,
  Send, Building2, Calendar, HelpCircle, Sparkles, ChevronDown, ChevronUp
} from 'lucide-react';

interface Question {
  id: number; question: string; required: boolean; order: number;
}
interface Opportunity {
  id: number; status: 'OPEN' | 'CLOSED' | 'FILLED';
  deadline: string | null; slots: number; applicationCount: number;
  hasApplied: boolean;
  myApplication: { id: number; status: string; appliedAt: string } | null;
  post: { title: string; content: string; createdAt: string; author: { id: number; full_name: string; role: string } };
  questions: Question[];
}

function StatusBanner({ app }: { app: { status: string; appliedAt: string } }) {
  const cfg = {
    ACCEPTED: { bg: 'bg-emerald-50 border-emerald-200 dark:bg-emerald-900/20 dark:border-emerald-800/40', text: 'text-emerald-700 dark:text-emerald-400', icon: <CheckCircle className="h-5 w-5" />, label: 'Accepted — Congratulations! 🎉' },
    REJECTED: { bg: 'bg-red-50 border-red-200 dark:bg-red-900/20 dark:border-red-800/40', text: 'text-red-700 dark:text-red-400', icon: <AlertCircle className="h-5 w-5" />, label: 'Not selected this time' },
    PENDING:  { bg: 'bg-amber-50 border-amber-200 dark:bg-amber-900/20 dark:border-amber-800/40', text: 'text-amber-700 dark:text-amber-400', icon: <Clock className="h-5 w-5" />, label: 'Under review' },
  }[app.status] ?? { bg: '', text: '', icon: null, label: app.status };

  return (
    <div className={`flex items-center gap-3 rounded-2xl border px-4 py-3 ${cfg.bg}`}>
      <span className={cfg.text}>{cfg.icon}</span>
      <div className="flex-1">
        <p className={`font-semibold text-sm ${cfg.text}`}>{cfg.label}</p>
        <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
          Applied {new Date(app.appliedAt).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
        </p>
      </div>
    </div>
  );
}

export default function StudentOpportunityDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [opp, setOpp] = useState<Opportunity | null>(null);
  const [loading, setLoading] = useState(true);
  const [answers, setAnswers] = useState<Record<number, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [expandedDesc, setExpandedDesc] = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' } | null>(null);

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 5000);
  };

  useEffect(() => {
    api.get(`/job-opportunities/${id}`)
      .then(({ data }) => {
        setOpp(data.data);
        const init: Record<number, string> = {};
        (data.data.questions as Question[]).forEach((q) => { init[q.id] = ''; });
        setAnswers(init);
      })
      .catch(() => showToast('Failed to load opportunity.', 'error'))
      .finally(() => setLoading(false));
  }, [id]);

  const handleApply = async () => {
    if (!opp) return;
    const missing = opp.questions.filter((q) => q.required && !answers[q.id]?.trim());
    if (missing.length > 0) { showToast('Please answer all required questions.', 'error'); return; }
    setSubmitting(true);
    try {
      await api.post(`/job-opportunities/${id}/apply`, {
        answers: opp.questions.filter((q) => answers[q.id]?.trim()).map((q) => ({ questionId: q.id, answer: answers[q.id].trim() })),
      });
      showToast('Application submitted! The supervisor has been notified. 🎉');
      setShowForm(false);
      const { data } = await api.get(`/job-opportunities/${id}`);
      setOpp(data.data);
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      showToast(err.response?.data?.message ?? 'Failed to submit.', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const isPastDeadline = opp?.deadline ? new Date() > new Date(opp.deadline) : false;
  const canApply = opp?.status === 'OPEN' && !opp.hasApplied && !isPastDeadline;
  const daysLeft = opp?.deadline ? Math.ceil((new Date(opp.deadline).getTime() - Date.now()) / 86400000) : null;

  if (loading) return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="flex flex-col items-center gap-3">
        <div className="animate-spin rounded-full h-10 w-10 border-2 border-teal-600 border-t-transparent" />
        <p className="text-sm text-slate-500 dark:text-slate-400">Loading…</p>
      </div>
    </div>
  );

  if (!opp) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-3">
      <AlertCircle className="h-10 w-10 text-slate-400" />
      <p className="text-slate-500 dark:text-slate-400">Opportunity not found.</p>
    </div>
  );

  const descText = opp.post.content.replace(/<[^>]*>/g, '').trim();
  const isLong = descText.length > 300;

  return (
    <div className="max-w-2xl mx-auto px-4 py-8 space-y-5">
      <button onClick={() => router.back()} className="flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400 hover:text-teal-600 dark:hover:text-teal-400 transition-colors">
        <ArrowLeft className="h-4 w-4" /> Back to opportunities
      </button>

      {/* Hero card */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 overflow-hidden shadow-sm">
        {/* Gradient top bar */}
        <div className="h-2 bg-gradient-to-r from-teal-500 via-teal-400 to-emerald-400" />

        <div className="p-6">
          {/* Status badges */}
          <div className="flex items-center gap-2 mb-4 flex-wrap">
            {opp.status === 'OPEN' && !opp.hasApplied && (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />Accepting Applications
              </span>
            )}
            {opp.hasApplied && (
              <span className="inline-flex items-center gap-1.5 rounded-full bg-teal-100 px-3 py-1 text-xs font-semibold text-teal-700 dark:bg-teal-900/30 dark:text-teal-400">
                <CheckCircle className="h-3.5 w-3.5" />You Applied
              </span>
            )}
            {opp.status === 'CLOSED' && <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">Closed</span>}
            {opp.status === 'FILLED' && <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400">Position Filled</span>}
            {isPastDeadline && !opp.hasApplied && <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-semibold text-red-600 dark:bg-red-900/30 dark:text-red-400">Deadline Passed</span>}
            {daysLeft !== null && daysLeft >= 0 && daysLeft <= 3 && !opp.hasApplied && (
              <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 px-3 py-1 text-xs font-semibold text-orange-600 dark:bg-orange-900/30 dark:text-orange-400">
                <Clock className="h-3 w-3" />{daysLeft === 0 ? 'Closes today' : `${daysLeft} days left`}
              </span>
            )}
          </div>

          <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100 mb-4">{opp.post.title}</h1>

          {/* Meta grid */}
          <div className="grid grid-cols-2 gap-3 mb-5">
            <div className="flex items-center gap-2.5 rounded-xl bg-slate-50 dark:bg-slate-800 px-3 py-2.5">
              <Building2 className="h-4 w-4 text-teal-500 shrink-0" />
              <div>
                <p className="text-[10px] text-slate-400 uppercase tracking-wide">Posted by</p>
                <p className="text-sm font-semibold text-slate-800 dark:text-slate-200">{opp.post.author.full_name}</p>
              </div>
            </div>
            <div className="flex items-center gap-2.5 rounded-xl bg-slate-50 dark:bg-slate-800 px-3 py-2.5">
              <Users className="h-4 w-4 text-blue-500 shrink-0" />
              <div>
                <p className="text-[10px] text-slate-400 uppercase tracking-wide">Applicants</p>
                <p className="text-sm font-semibold text-slate-800 dark:text-slate-200">{opp.applicationCount} / {opp.slots} slots</p>
              </div>
            </div>
            {opp.deadline && (
              <div className="flex items-center gap-2.5 rounded-xl bg-slate-50 dark:bg-slate-800 px-3 py-2.5">
                <Clock className="h-4 w-4 text-orange-500 shrink-0" />
                <div>
                  <p className="text-[10px] text-slate-400 uppercase tracking-wide">Deadline</p>
                  <p className="text-sm font-semibold text-slate-800 dark:text-slate-200">
                    {new Date(opp.deadline).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                  </p>
                </div>
              </div>
            )}
            <div className="flex items-center gap-2.5 rounded-xl bg-slate-50 dark:bg-slate-800 px-3 py-2.5">
              <Calendar className="h-4 w-4 text-violet-500 shrink-0" />
              <div>
                <p className="text-[10px] text-slate-400 uppercase tracking-wide">Posted</p>
                <p className="text-sm font-semibold text-slate-800 dark:text-slate-200">
                  {new Date(opp.post.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                </p>
              </div>
            </div>
          </div>

          {/* Description */}
          <div>
            <h2 className="text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2 uppercase tracking-wide">About this role</h2>
            <div
              className={`prose prose-sm dark:prose-invert max-w-none text-slate-600 dark:text-slate-400 leading-relaxed overflow-hidden transition-all duration-300 ${!expandedDesc && isLong ? 'max-h-32' : 'max-h-[2000px]'}`}
              dangerouslySetInnerHTML={{ __html: opp.post.content }}
            />
            {isLong && (
              <button
                onClick={() => setExpandedDesc(!expandedDesc)}
                className="flex items-center gap-1 mt-2 text-xs font-semibold text-teal-600 dark:text-teal-400 hover:underline"
              >
                {expandedDesc ? <><ChevronUp className="h-3.5 w-3.5" />Show less</> : <><ChevronDown className="h-3.5 w-3.5" />Read more</>}
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Application status */}
      {opp.myApplication && <StatusBanner app={opp.myApplication} />}

      {/* Questions preview (when not yet applied) */}
      {canApply && !showForm && opp.questions.length > 0 && (
        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 p-5">
          <h2 className="font-semibold text-slate-900 dark:text-slate-100 flex items-center gap-2 mb-3">
            <HelpCircle className="h-4 w-4 text-teal-600" />
            Application Questions
            <span className="ml-auto text-xs text-slate-400">{opp.questions.filter(q => q.required).length} required</span>
          </h2>
          <div className="space-y-2">
            {[...opp.questions].sort((a, b) => a.order - b.order).map((q, i) => (
              <div key={q.id} className="flex items-start gap-2.5 text-sm">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-teal-100 dark:bg-teal-900/30 text-teal-700 dark:text-teal-400 text-xs font-bold mt-0.5">{i + 1}</span>
                <span className="text-slate-700 dark:text-slate-300 flex-1">{q.question}
                  {q.required && <span className="text-red-500 ml-1">*</span>}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Apply CTA */}
      {canApply && !showForm && (
        <button
          onClick={() => setShowForm(true)}
          className="w-full flex items-center justify-center gap-2 rounded-2xl bg-gradient-to-r from-teal-600 to-teal-500 py-4 text-sm font-semibold text-white hover:from-teal-700 hover:to-teal-600 active:scale-[0.98] transition-all shadow-lg shadow-teal-500/25"
        >
          <Sparkles className="h-4 w-4" /> Apply for this Position
        </button>
      )}

      {/* Application form */}
      {showForm && (
        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 overflow-hidden shadow-sm">
          <div className="bg-gradient-to-r from-teal-50 to-emerald-50 dark:from-teal-900/20 dark:to-emerald-900/20 px-6 py-4 border-b border-slate-200 dark:border-slate-700">
            <h2 className="font-bold text-slate-900 dark:text-slate-100 flex items-center gap-2">
              <Send className="h-4 w-4 text-teal-600" /> Your Application
            </h2>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              {opp.questions.length === 0 ? 'No questions — just submit to apply.' : `Answer ${opp.questions.filter(q => q.required).length} required question${opp.questions.filter(q => q.required).length !== 1 ? 's' : ''} below`}
            </p>
          </div>

          <div className="p-6 space-y-5">
            {[...opp.questions].sort((a, b) => a.order - b.order).map((q, i) => (
              <div key={q.id}>
                <label className="flex items-start gap-2 text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-teal-100 dark:bg-teal-900/30 text-teal-700 dark:text-teal-400 text-xs font-bold mt-0.5">{i + 1}</span>
                  <span>{q.question}{q.required && <span className="text-red-500 ml-1">*</span>}{!q.required && <span className="text-slate-400 text-xs font-normal ml-1">(optional)</span>}</span>
                </label>
                <textarea
                  value={answers[q.id] ?? ''}
                  onChange={(e) => setAnswers(prev => ({ ...prev, [q.id]: e.target.value }))}
                  placeholder="Write your answer here…"
                  rows={3}
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent resize-none transition-colors"
                />
              </div>
            ))}

            <div className="flex gap-3 pt-2">
              <button
                onClick={() => setShowForm(false)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-3 text-sm font-semibold text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleApply}
                disabled={submitting}
                className="flex-1 flex items-center justify-center gap-2 rounded-xl bg-teal-600 py-3 text-sm font-semibold text-white hover:bg-teal-700 active:scale-[0.98] transition-all disabled:opacity-50 shadow-sm shadow-teal-500/30"
              >
                {submitting ? (
                  <><div className="h-4 w-4 rounded-full border-2 border-white border-t-transparent animate-spin" />Submitting…</>
                ) : (
                  <><Send className="h-4 w-4" />Submit Application</>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {toast && (
        <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2 rounded-2xl px-5 py-3.5 shadow-2xl text-sm font-semibold text-white max-w-sm text-center ${toast.type === 'error' ? 'bg-red-600' : 'bg-slate-900'}`}>
          {toast.type === 'error' ? <AlertCircle className="h-4 w-4 shrink-0" /> : <CheckCircle className="h-4 w-4 shrink-0 text-emerald-400" />}
          {toast.msg}
        </div>
      )}
    </div>
  );
}
