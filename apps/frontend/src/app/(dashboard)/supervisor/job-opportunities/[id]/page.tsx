'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import api from '@/lib/api/client';
import {
  ArrowLeft, Users, Clock, CheckCircle, XCircle, Eye,
  Megaphone, AlertCircle, Briefcase, TrendingUp, ChevronRight,
  ToggleLeft, ToggleRight, GraduationCap
} from 'lucide-react';

interface Application {
  id: number; status: 'PENDING' | 'ACCEPTED' | 'REJECTED'; appliedAt: string;
  student: {
    id: number;
    user: { id: number; full_name: string; email: string };
    university: { name: string } | null;
    assignments: { project_name: string | null; start_date: string }[];
  };
  answers: { id: number; answer: string; question: { question: string; order: number } }[];
}
interface Opportunity {
  id: number; status: 'OPEN' | 'CLOSED' | 'FILLED';
  deadline: string | null; slots: number;
  post: { id: number; title: string; content: string };
  questions: { id: number; question: string; required: boolean }[];
}

function AppStatusBadge({ status }: { status: string }) {
  if (status === 'ACCEPTED') return <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"><CheckCircle className="h-3 w-3" />Accepted</span>;
  if (status === 'REJECTED') return <span className="inline-flex items-center gap-1 rounded-full bg-red-100 px-2.5 py-1 text-xs font-semibold text-red-700 dark:bg-red-900/30 dark:text-red-400"><XCircle className="h-3 w-3" />Rejected</span>;
  return <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 px-2.5 py-1 text-xs font-semibold text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"><Clock className="h-3 w-3" />Pending</span>;
}

export default function SupervisorOpportunityDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [opp, setOpp] = useState<Opportunity | null>(null);
  const [applications, setApplications] = useState<Application[]>([]);
  const [loading, setLoading] = useState(true);
  const [announcing, setAnnouncing] = useState(false);
  const [announceMsg, setAnnounceMsg] = useState('');
  const [showAnnounceModal, setShowAnnounceModal] = useState(false);
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'PENDING' | 'ACCEPTED' | 'REJECTED'>('ALL');
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' } | null>(null);

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchData = async () => {
    try {
      const { data } = await api.get(`/job-opportunities/${id}/applications`);
      setOpp(data.data.opportunity);
      setApplications(data.data.applications ?? []);
    } catch { showToast('Failed to load.', 'error'); }
    finally { setLoading(false); }
  };

  useEffect(() => { fetchData(); }, [id]);

  const toggleStatus = async () => {
    if (!opp) return;
    const newStatus = opp.status === 'OPEN' ? 'CLOSED' : 'OPEN';
    try {
      await api.patch(`/job-opportunities/${id}/status`, { status: newStatus });
      setOpp(prev => prev ? { ...prev, status: newStatus } : prev);
      showToast(`Opportunity ${newStatus.toLowerCase()}.`);
    } catch { showToast('Failed to update status.', 'error'); }
  };

  const handleAnnounce = async () => {
    setAnnouncing(true);
    try {
      await api.post(`/job-opportunities/${id}/announce`, { message: announceMsg });
      showToast('Winner announcement posted to the common feed! 🎉');
      setShowAnnounceModal(false);
      fetchData();
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      showToast(err.response?.data?.message ?? 'Failed to announce.', 'error');
    } finally { setAnnouncing(false); }
  };

  const acceptedCount = applications.filter(a => a.status === 'ACCEPTED').length;
  const pendingCount  = applications.filter(a => a.status === 'PENDING').length;
  const filteredApps  = statusFilter === 'ALL' ? applications : applications.filter(a => a.status === statusFilter);

  if (loading) return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="animate-spin rounded-full h-10 w-10 border-2 border-teal-600 border-t-transparent" />
    </div>
  );
  if (!opp) return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] gap-3">
      <AlertCircle className="h-10 w-10 text-slate-400" />
      <p className="text-slate-500">Opportunity not found.</p>
    </div>
  );

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 space-y-6">
      <button onClick={() => router.back()} className="flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400 hover:text-teal-600 dark:hover:text-teal-400 transition-colors">
        <ArrowLeft className="h-4 w-4" /> Back to opportunities
      </button>

      {/* Opportunity header card */}
      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 overflow-hidden shadow-sm">
        <div className="h-1.5 bg-gradient-to-r from-teal-500 to-emerald-400" />
        <div className="p-6">
          <div className="flex items-start justify-between gap-4 flex-wrap">
            <div className="flex items-start gap-4 flex-1 min-w-0">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-teal-500 to-teal-600 shadow-sm shadow-teal-500/30">
                <Briefcase className="h-6 w-6 text-white" />
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-2 mb-1 flex-wrap">
                  {opp.status === 'OPEN' && <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-semibold text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"><span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />Open</span>}
                  {opp.status === 'CLOSED' && <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500 dark:bg-slate-800 dark:text-slate-400"><XCircle className="h-3 w-3" />Closed</span>}
                  {opp.status === 'FILLED' && <span className="inline-flex items-center gap-1 rounded-full bg-teal-100 px-2.5 py-1 text-xs font-semibold text-teal-700 dark:bg-teal-900/30 dark:text-teal-400"><CheckCircle className="h-3 w-3" />Filled</span>}
                  {opp.deadline && <span className="inline-flex items-center gap-1 text-xs text-slate-400"><Clock className="h-3 w-3" />{new Date(opp.deadline).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</span>}
                </div>
                <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100">{opp.post.title}</h1>
              </div>
            </div>

            <div className="flex items-center gap-2 flex-wrap shrink-0">
              {opp.status !== 'FILLED' && (
                <button
                  onClick={toggleStatus}
                  className="flex items-center gap-1.5 rounded-xl border border-slate-200 dark:border-slate-700 px-3 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
                >
                  {opp.status === 'OPEN' ? <ToggleRight className="h-4 w-4 text-emerald-500" /> : <ToggleLeft className="h-4 w-4 text-slate-400" />}
                  {opp.status === 'OPEN' ? 'Close' : 'Reopen'}
                </button>
              )}
              {acceptedCount > 0 && (
                <button
                  onClick={() => setShowAnnounceModal(true)}
                  className="flex items-center gap-1.5 rounded-xl bg-gradient-to-r from-teal-600 to-teal-500 px-4 py-2 text-sm font-semibold text-white hover:from-teal-700 hover:to-teal-600 transition-all shadow-sm shadow-teal-500/30"
                >
                  <Megaphone className="h-4 w-4" /> Announce Winners
                </button>
              )}
            </div>
          </div>

          {/* Stats row */}
          <div className="grid grid-cols-4 gap-3 mt-5">
            {[
              { label: 'Total', value: applications.length, color: 'text-slate-700 dark:text-slate-300', bg: 'bg-slate-50 dark:bg-slate-800' },
              { label: 'Pending', value: pendingCount, color: 'text-amber-700 dark:text-amber-400', bg: 'bg-amber-50 dark:bg-amber-900/20' },
              { label: 'Accepted', value: acceptedCount, color: 'text-emerald-700 dark:text-emerald-400', bg: 'bg-emerald-50 dark:bg-emerald-900/20' },
              { label: 'Slots', value: `${acceptedCount}/${opp.slots}`, color: 'text-teal-700 dark:text-teal-400', bg: 'bg-teal-50 dark:bg-teal-900/20' },
            ].map(({ label, value, color, bg }) => (
              <div key={label} className={`rounded-xl ${bg} px-3 py-2.5 text-center`}>
                <p className={`text-lg font-bold ${color}`}>{value}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400">{label}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Applicants section */}
      <div>
        <div className="flex items-center justify-between mb-4 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <Users className="h-5 w-5 text-teal-600" /> Applicants
          </h2>
          {/* Filter tabs */}
          <div className="flex rounded-xl border border-slate-200 dark:border-slate-700 overflow-hidden bg-white dark:bg-slate-900">
            {(['ALL', 'PENDING', 'ACCEPTED', 'REJECTED'] as const).map((s) => (
              <button
                key={s}
                onClick={() => setStatusFilter(s)}
                className={`px-3 py-1.5 text-xs font-medium transition-colors ${statusFilter === s ? 'bg-teal-600 text-white' : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'}`}
              >
                {s === 'ALL' ? `All (${applications.length})` : s === 'PENDING' ? `Pending (${pendingCount})` : s === 'ACCEPTED' ? `Accepted (${acceptedCount})` : `Rejected (${applications.filter(a => a.status === 'REJECTED').length})`}
              </button>
            ))}
          </div>
        </div>

        {filteredApps.length === 0 ? (
          <div className="text-center py-16 bg-white dark:bg-slate-900 rounded-2xl border-2 border-dashed border-slate-200 dark:border-slate-700">
            <Users className="h-10 w-10 text-slate-300 dark:text-slate-600 mx-auto mb-3" />
            <p className="text-slate-500 dark:text-slate-400 font-medium">
              {statusFilter === 'ALL' ? 'No applications yet' : `No ${statusFilter.toLowerCase()} applications`}
            </p>
          </div>
        ) : (
          <div className="space-y-2">
            {filteredApps.map((app) => (
              <div
                key={app.id}
                className="group bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-700 p-4 flex items-center gap-4 hover:border-teal-300 dark:hover:border-teal-700 hover:shadow-md transition-all cursor-pointer"
                onClick={() => router.push(`/supervisor/job-opportunities/${id}/applicants/${app.id}`)}
              >
                {/* Avatar */}
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-700 dark:to-slate-800 text-sm font-bold text-slate-600 dark:text-slate-300 group-hover:from-teal-50 group-hover:to-teal-100 dark:group-hover:from-teal-900/30 dark:group-hover:to-teal-900/20 transition-all">
                  {app.student.user.full_name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="font-semibold text-slate-900 dark:text-slate-100 group-hover:text-teal-600 dark:group-hover:text-teal-400 transition-colors">{app.student.user.full_name}</p>
                    <AppStatusBadge status={app.status} />
                  </div>
                  <div className="flex items-center gap-3 mt-0.5 text-xs text-slate-500 dark:text-slate-400">
                    {app.student.university && (
                      <span className="flex items-center gap-1"><GraduationCap className="h-3 w-3" />{app.student.university.name}</span>
                    )}
                    <span>Applied {new Date(app.appliedAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
                    {app.answers.length > 0 && <span>{app.answers.length} answer{app.answers.length !== 1 ? 's' : ''}</span>}
                  </div>
                </div>

                <div className="flex items-center gap-2 shrink-0">
                  <span className="hidden sm:flex items-center gap-1 text-xs font-medium text-teal-600 dark:text-teal-400 opacity-0 group-hover:opacity-100 transition-opacity">
                    <Eye className="h-3.5 w-3.5" /> Review
                  </span>
                  <ChevronRight className="h-5 w-5 text-slate-300 dark:text-slate-600 group-hover:text-teal-500 group-hover:translate-x-0.5 transition-all" />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Announce modal */}
      {showAnnounceModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-white dark:bg-slate-900 rounded-2xl max-w-md w-full shadow-2xl overflow-hidden">
            <div className="bg-gradient-to-r from-teal-600 to-teal-500 px-6 py-4">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Megaphone className="h-5 w-5" /> Announce Winners
              </h3>
              <p className="text-sm text-teal-100 mt-0.5">
                Post a public announcement for {acceptedCount} accepted candidate{acceptedCount !== 1 ? 's' : ''}
              </p>
            </div>
            <div className="p-6">
              <div className="flex items-center gap-2 rounded-xl bg-teal-50 dark:bg-teal-900/20 border border-teal-200 dark:border-teal-800/40 px-4 py-3 mb-4">
                <TrendingUp className="h-4 w-4 text-teal-600 dark:text-teal-400 shrink-0" />
                <p className="text-xs text-teal-700 dark:text-teal-300">This will create a public post visible to everyone on the platform</p>
              </div>
              <label className="block text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">Custom message (optional)</label>
              <textarea
                value={announceMsg}
                onChange={(e) => setAnnounceMsg(e.target.value)}
                placeholder="Add a personal message, or leave blank for the default announcement…"
                rows={3}
                className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 resize-none mb-4"
              />
              <div className="flex gap-3">
                <button onClick={() => setShowAnnounceModal(false)} className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">Cancel</button>
                <button onClick={handleAnnounce} disabled={announcing} className="flex-1 rounded-xl bg-teal-600 py-2.5 text-sm font-semibold text-white hover:bg-teal-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
                  {announcing ? <><div className="h-4 w-4 rounded-full border-2 border-white border-t-transparent animate-spin" />Posting…</> : <><Megaphone className="h-4 w-4" />Post Announcement</>}
                </button>
              </div>
            </div>
          </div>
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
