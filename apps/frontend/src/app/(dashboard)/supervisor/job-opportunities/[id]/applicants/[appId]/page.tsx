'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import api from '@/lib/api/client';
import {
  ArrowLeft, User, GraduationCap, CheckCircle, XCircle,
  AlertCircle, MessageSquare, Star, Briefcase, Calendar,
  TrendingUp, Award
} from 'lucide-react';

interface Application {
  id: number; status: 'PENDING' | 'ACCEPTED' | 'REJECTED';
  appliedAt: string; reviewedAt: string | null;
  opportunity: { post: { title: string } };
  student: {
    id: number; department: string | null; studentId: string | null; internship_status: string;
    user: { id: number; full_name: string; email: string };
    university: { name: string } | null;
    weeklyPlans: { week_number: number; status: string; submitted_at: string }[];
    assignments: { project_name: string | null; start_date: string; end_date: string | null; status: string }[];
    finalEvaluation: {
      technical_skills: number; communication: number; team_collaboration: number;
      time_management: number; professionalism: number; comments: string | null;
    } | null;
  };
  answers: { id: number; answer: string; question: { question: string; order: number } }[];
}

function ScoreBar({ label, value, color }: { label: string; value: number; color: string }) {
  const pct = Math.min(100, Math.round((Number(value) / 10) * 100));
  return (
    <div>
      <div className="flex justify-between text-xs mb-1">
        <span className="text-slate-600 dark:text-slate-400">{label}</span>
        <span className="font-bold text-slate-800 dark:text-slate-200">{Number(value).toFixed(1)}/10</span>
      </div>
      <div className="h-2 w-full rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
        <div className="h-full rounded-full transition-all duration-700" style={{ width: `${pct}%`, background: color }} />
      </div>
    </div>
  );
}

export default function ApplicantReviewPage() {
  const { id, appId } = useParams<{ id: string; appId: string }>();
  const router = useRouter();
  const [app, setApp] = useState<Application | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' } | null>(null);

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 5000);
  };

  useEffect(() => {
    api.get(`/job-opportunities/${id}/applications/${appId}`)
      .then(({ data }) => setApp(data.data))
      .catch(() => showToast('Failed to load application.', 'error'))
      .finally(() => setLoading(false));
  }, [id, appId]);

  const handleDecision = async (status: 'ACCEPTED' | 'REJECTED') => {
    setSubmitting(true);
    try {
      const { data } = await api.patch(`/job-opportunities/${id}/applications/${appId}`, { status });
      setApp(prev => prev ? { ...prev, status: data.data.status, reviewedAt: data.data.reviewedAt } : prev);
      showToast(status === 'ACCEPTED'
        ? '🎉 Application accepted! Student notified and a congratulation post has been published.'
        : 'Application rejected. Student has been notified.');
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      showToast(err.response?.data?.message ?? 'Failed to update.', 'error');
    } finally { setSubmitting(false); }
  };

  const evalAvg = (ev: Application['student']['finalEvaluation']) => {
    if (!ev) return null;
    const vals = [ev.technical_skills, ev.communication, ev.team_collaboration, ev.time_management, ev.professionalism];
    return (vals.reduce((s, v) => s + Number(v), 0) / vals.length).toFixed(1);
  };

  if (loading) return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="animate-spin rounded-full h-10 w-10 border-2 border-teal-600 border-t-transparent" />
    </div>
  );
  if (!app) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-3">
      <AlertCircle className="h-10 w-10 text-slate-400" />
      <p className="text-slate-500">Application not found.</p>
    </div>
  );

  const s = app.student;
  const approvedPlans = (s.weeklyPlans ?? []).filter(p => p.status === 'APPROVED').length;

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 space-y-5">
      <button onClick={() => router.back()} className="flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400 hover:text-teal-600 dark:hover:text-teal-400 transition-colors">
        <ArrowLeft className="h-4 w-4" /> Back to applicants
      </button>

      {/* Decision status banner */}
      {app.status !== 'PENDING' && (
        <div className={`flex items-center gap-3 rounded-2xl border px-5 py-4 ${app.status === 'ACCEPTED' ? 'bg-emerald-50 border-emerald-200 dark:bg-emerald-900/20 dark:border-emerald-800/40' : 'bg-red-50 border-red-200 dark:bg-red-900/20 dark:border-red-800/40'}`}>
          {app.status === 'ACCEPTED' ? <CheckCircle className="h-5 w-5 text-emerald-600 dark:text-emerald-400 shrink-0" /> : <XCircle className="h-5 w-5 text-red-600 dark:text-red-400 shrink-0" />}
          <div>
            <p className={`font-semibold ${app.status === 'ACCEPTED' ? 'text-emerald-700 dark:text-emerald-400' : 'text-red-700 dark:text-red-400'}`}>
              {app.status === 'ACCEPTED' ? 'Application Accepted — A congratulation post was published' : 'Application Rejected'}
            </p>
            {app.reviewedAt && <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Reviewed on {new Date(app.reviewedAt).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}</p>}
          </div>
        </div>
      )}

      {/* Student profile card */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 overflow-hidden shadow-sm">
        {/* Header gradient */}
        <div className="bg-gradient-to-r from-slate-800 to-slate-700 dark:from-slate-800 dark:to-slate-900 px-6 py-5">
          <div className="flex items-center gap-4">
            <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-white/10 text-white text-xl font-bold ring-2 ring-white/20">
              {s.user.full_name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)}
            </div>
            <div>
              <h2 className="text-xl font-bold text-white">{s.user.full_name}</h2>
              <p className="text-sm text-slate-300">{s.user.email}</p>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-5">
          {/* Info grid */}
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { icon: GraduationCap, label: 'University', value: s.university?.name ?? '—', color: 'text-blue-500' },
              { icon: User, label: 'Department', value: s.department ?? '—', color: 'text-violet-500' },
              { icon: Briefcase, label: 'Status', value: s.internship_status.charAt(0) + s.internship_status.slice(1).toLowerCase(), color: 'text-teal-500' },
              { icon: Award, label: 'Student ID', value: s.studentId ?? '—', color: 'text-amber-500' },
            ].map(({ icon: Icon, label, value, color }) => (
              <div key={label} className="rounded-xl bg-slate-50 dark:bg-slate-800 p-3">
                <div className="flex items-center gap-1.5 mb-1">
                  <Icon className={`h-3.5 w-3.5 ${color}`} />
                  <span className="text-[10px] text-slate-400 uppercase tracking-wide">{label}</span>
                </div>
                <p className="text-sm font-semibold text-slate-800 dark:text-slate-200 truncate">{value}</p>
              </div>
            ))}
          </div>

          {/* Weekly plans summary */}
          {s.weeklyPlans.length > 0 && (
            <div>
              <h3 className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                <Calendar className="h-3.5 w-3.5" /> Weekly Plans ({approvedPlans}/{s.weeklyPlans.length} approved)
              </h3>
              <div className="flex gap-1.5 flex-wrap">
                {s.weeklyPlans.slice(0, 8).map((p) => (
                  <div key={p.week_number} className={`rounded-lg px-2.5 py-1.5 text-xs font-medium ${p.status === 'APPROVED' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' : p.status === 'PENDING' ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400' : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400'}`}>
                    W{p.week_number}
                  </div>
                ))}
                {s.weeklyPlans.length > 8 && <span className="text-xs text-slate-400 self-center">+{s.weeklyPlans.length - 8} more</span>}
              </div>
            </div>
          )}

          {/* Final evaluation */}
          {s.finalEvaluation && (
            <div>
              <h3 className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-3 flex items-center gap-1.5">
                <Star className="h-3.5 w-3.5 text-amber-500" /> Final Evaluation
                <span className="ml-auto text-sm font-bold text-slate-800 dark:text-slate-200">Avg: {evalAvg(s.finalEvaluation)}/10</span>
              </h3>
              <div className="space-y-2.5">
                <ScoreBar label="Technical Skills" value={s.finalEvaluation.technical_skills} color="#3b82f6" />
                <ScoreBar label="Communication" value={s.finalEvaluation.communication} color="#8b5cf6" />
                <ScoreBar label="Team Collaboration" value={s.finalEvaluation.team_collaboration} color="#0d9488" />
                <ScoreBar label="Time Management" value={s.finalEvaluation.time_management} color="#f59e0b" />
                <ScoreBar label="Professionalism" value={s.finalEvaluation.professionalism} color="#10b981" />
              </div>
              {s.finalEvaluation.comments && (
                <p className="mt-3 text-sm text-slate-600 dark:text-slate-400 italic bg-slate-50 dark:bg-slate-800 rounded-xl px-4 py-3">
                  "{s.finalEvaluation.comments}"
                </p>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Q&A Answers */}
      {app.answers.length > 0 && (
        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 p-6 shadow-sm">
          <h3 className="font-semibold text-slate-900 dark:text-slate-100 flex items-center gap-2 mb-5">
            <MessageSquare className="h-4 w-4 text-teal-600" /> Application Answers
          </h3>
          <div className="space-y-5">
            {[...app.answers].sort((a, b) => a.question.order - b.question.order).map((ans, i) => (
              <div key={ans.id} className="flex gap-3">
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-teal-100 dark:bg-teal-900/30 text-teal-700 dark:text-teal-400 text-xs font-bold mt-0.5">{i + 1}</span>
                <div className="flex-1">
                  <p className="text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1.5">{ans.question.question}</p>
                  <p className="text-sm text-slate-600 dark:text-slate-400 bg-slate-50 dark:bg-slate-800 rounded-xl px-4 py-3 leading-relaxed">{ans.answer}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Decision buttons */}
      {app.status === 'PENDING' && (
        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 p-5 shadow-sm">
          <p className="text-sm font-semibold text-slate-700 dark:text-slate-300 mb-1">Make a Decision</p>
          <p className="text-xs text-slate-500 dark:text-slate-400 mb-4">
            Accepting will notify the student and publish a congratulation post on the common feed visible to everyone.
          </p>
          <div className="flex gap-3">
            <button
              onClick={() => handleDecision('REJECTED')}
              disabled={submitting}
              className="flex-1 flex items-center justify-center gap-2 rounded-xl border-2 border-red-200 dark:border-red-800/40 py-3 text-sm font-semibold text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 active:scale-[0.98] transition-all disabled:opacity-50"
            >
              <XCircle className="h-4 w-4" /> Reject
            </button>
            <button
              onClick={() => handleDecision('ACCEPTED')}
              disabled={submitting}
              className="flex-1 flex items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-teal-600 to-teal-500 py-3 text-sm font-semibold text-white hover:from-teal-700 hover:to-teal-600 active:scale-[0.98] transition-all disabled:opacity-50 shadow-sm shadow-teal-500/30"
            >
              {submitting ? (
                <><div className="h-4 w-4 rounded-full border-2 border-white border-t-transparent animate-spin" />Processing…</>
              ) : (
                <><CheckCircle className="h-4 w-4" /> Accept & Congratulate</>
              )}
            </button>
          </div>
          <div className="flex items-start gap-2 mt-3 rounded-xl bg-teal-50 dark:bg-teal-900/20 border border-teal-200 dark:border-teal-800/40 px-4 py-3">
            <TrendingUp className="h-4 w-4 text-teal-600 dark:text-teal-400 shrink-0 mt-0.5" />
            <p className="text-xs text-teal-700 dark:text-teal-300">
              Accepting will automatically post a public congratulation on the common feed mentioning the student's name and the job title.
            </p>
          </div>
        </div>
      )}

      {toast && (
        <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2 rounded-2xl px-5 py-3.5 shadow-2xl text-sm font-semibold text-white max-w-sm ${toast.type === 'error' ? 'bg-red-600' : 'bg-slate-900'}`}>
          {toast.type === 'error' ? <XCircle className="h-4 w-4 shrink-0" /> : <CheckCircle className="h-4 w-4 shrink-0 text-emerald-400" />}
          <span>{toast.msg}</span>
        </div>
      )}
    </div>
  );
}
