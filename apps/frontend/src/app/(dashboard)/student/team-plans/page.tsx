"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle, Plus, Send, Calendar, UsersRound, CheckCircle2, XCircle, Clock } from "lucide-react";
import { cn } from "@/lib/utils";
import SuccessToast from "@/components/shared/SuccessToast";

type TeamDailyPlan = {
  id: number;
  workDate: string;
  notes: string | null;
  status: string;
  supervisorNote: string | null;
};

type TeamWeeklyPlan = {
  id: number;
  week_number: number;
  plan_description: string;
  status: string;
  submitted_at: string;
  feedback: string | null;
  submittedBy: { user: { full_name: string } };
  dailyPlans: TeamDailyPlan[];
};

type TeamInfo = { id: number; name: string; managerId: number | null };

function statusBadge(status: string) {
  if (status === "APPROVED") return "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300";
  if (status === "REJECTED") return "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300";
  return "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300";
}

function statusIcon(status: string) {
  if (status === "APPROVED") return <CheckCircle2 className="h-4 w-4 text-emerald-600" />;
  if (status === "REJECTED") return <XCircle className="h-4 w-4 text-red-600" />;
  return <Clock className="h-4 w-4 text-amber-600" />;
}

export default function StudentTeamPlansPage() {
  const [team, setTeam] = useState<TeamInfo | null>(null);
  const [isManager, setIsManager] = useState(false);
  const [plans, setPlans] = useState<TeamWeeklyPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });

  // Weekly plan form
  const [showWeeklyForm, setShowWeeklyForm] = useState(false);
  const [weekNum, setWeekNum] = useState(1);
  const [planDesc, setPlanDesc] = useState("");
  const [submittingWeekly, setSubmittingWeekly] = useState(false);

  // Daily plan form
  const [showDailyForm, setShowDailyForm] = useState<number | null>(null); // planId
  const [dailyDate, setDailyDate] = useState("");
  const [dailyNotes, setDailyNotes] = useState("");
  const [submittingDaily, setSubmittingDaily] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: { team: TeamInfo; isManager: boolean; plans: TeamWeeklyPlan[] } }>("/progress/team-plans/my");
      const d = res.data.data;
      setTeam(d.team ?? null);
      setIsManager(d.isManager ?? false);
      setPlans(d.plans ?? []);
      // Auto-set next week number
      const submitted = new Set((d.plans ?? []).map((p: TeamWeeklyPlan) => p.week_number));
      let next = 1;
      while (submitted.has(next)) next++;
      setWeekNum(next);
    } catch {
      setError("Could not load team plans.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const submitWeeklyPlan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!team) return;
    setSubmittingWeekly(true);
    try {
      await api.post("/progress/team-plans", {
        teamId: team.id,
        week_number: weekNum,
        plan_description: planDesc.trim(),
      });
      setShowWeeklyForm(false);
      setPlanDesc("");
      setToast({ show: true, message: "✅ Team weekly plan submitted successfully" });
      await load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Could not submit team plan.");
    } finally {
      setSubmittingWeekly(false);
    }
  };

  const submitDailyPlan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!showDailyForm) return;
    setSubmittingDaily(true);
    try {
      await api.post(`/progress/team-plans/${showDailyForm}/daily`, {
        workDate: dailyDate,
        notes: dailyNotes.trim() || undefined,
      });
      setShowDailyForm(null);
      setDailyDate("");
      setDailyNotes("");
      setToast({ show: true, message: "✅ Team daily plan submitted" });
      await load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Could not submit daily plan.");
    } finally {
      setSubmittingDaily(false);
    }
  };

  if (loading) return <div className="py-12 text-center text-slate-500 dark:text-slate-400">Loading team plans…</div>;

  if (!team) {
    return (
      <div className="flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-16 text-center">
        <UsersRound className="h-12 w-12 text-slate-300 dark:text-slate-600 mb-3" />
        <p className="text-base font-semibold text-slate-600 dark:text-slate-400">You are not in a team yet</p>
        <p className="text-sm text-slate-400 dark:text-slate-500 mt-1">Ask your supervisor to add you to a team.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Team Plans</h1>
          <div className="mt-1 flex items-center gap-2">
            <UsersRound className="h-4 w-4 text-primary-500" />
            <span className="text-sm text-slate-600 dark:text-slate-300 font-medium">{team.name}</span>
            {isManager && (
              <span className="rounded-full bg-primary-100 dark:bg-primary-900/40 px-2 py-0.5 text-xs font-bold text-primary-700 dark:text-primary-300">
                📋 Team Leader
              </span>
            )}
          </div>
        </div>
        {isManager && (
          <button type="button" onClick={() => setShowWeeklyForm(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-primary-700">
            <Plus className="h-4 w-4" />
            Submit Weekly Plan
          </button>
        )}
      </div>

      {!isManager && (
        <div className="rounded-xl border border-primary-100 bg-primary-50/60 px-4 py-3 text-sm text-slate-600 dark:border-primary-900/50 dark:bg-primary-900/20 dark:text-slate-300">
          👀 You can view your team&apos;s plans here. Only the <strong>Team Leader</strong> can submit plans on behalf of the team.
        </div>
      )}

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
          <AlertCircle className="h-4 w-4 shrink-0" />{error}
        </div>
      )}

      {/* Plans list */}
      {plans.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-12 text-center">
          <p className="text-slate-500 dark:text-slate-400">No team plans submitted yet.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {plans.map((plan) => (
            <div key={plan.id} className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
              {/* Plan header */}
              <div className="flex items-start justify-between gap-3 border-b border-slate-100 dark:border-slate-700 px-5 py-4">
                <div className="flex items-center gap-3 min-w-0">
                  <div className={cn("rounded-xl p-2.5 shrink-0", plan.status === "APPROVED" ? "bg-emerald-50 text-emerald-600" : plan.status === "REJECTED" ? "bg-red-50 text-red-600" : "bg-amber-50 text-amber-600")}>
                    {statusIcon(plan.status)}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <h3 className="font-bold text-slate-900 dark:text-slate-100">Week {plan.week_number}</h3>
                      <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(plan.status)}`}>{plan.status}</span>
                    </div>
                    <p className="text-xs text-slate-500 dark:text-slate-400">
                      Submitted by {plan.submittedBy.user.full_name} · {new Date(plan.submitted_at).toLocaleDateString()}
                    </p>
                  </div>
                </div>
                {isManager && plan.status === "APPROVED" && (
                  <button type="button" onClick={() => { setShowDailyForm(plan.id); setDailyDate(""); setDailyNotes(""); }}
                    className="shrink-0 inline-flex items-center gap-1.5 rounded-xl border border-primary-200 bg-primary-50 px-3 py-1.5 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors dark:border-primary-800 dark:bg-primary-900/20 dark:text-primary-300">
                    <Calendar className="h-3.5 w-3.5" />
                    Add Daily Plan
                  </button>
                )}
              </div>

              {/* Plan description */}
              <div className="px-5 py-4">
                <p className="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-wrap leading-relaxed">{plan.plan_description}</p>
                {plan.feedback && (
                  <div className={`mt-3 rounded-xl border px-4 py-3 text-sm ${plan.status === "APPROVED" ? "border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-200" : "border-red-200 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200"}`}>
                    <span className="font-semibold">Supervisor feedback: </span>{plan.feedback}
                  </div>
                )}
              </div>

              {/* Daily plans */}
              {plan.dailyPlans.length > 0 && (
                <div className="border-t border-slate-100 dark:border-slate-700 px-5 py-3 space-y-2">
                  <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Daily Plans</p>
                  {plan.dailyPlans.map((d) => {
                    const dateLabel = new Date(`${String(d.workDate).slice(0, 10)}T12:00:00.000Z`).toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });
                    return (
                      <div key={d.id} className={`flex items-start justify-between gap-3 rounded-xl border px-3 py-2.5 ${d.status === "APPROVED" ? "border-emerald-200 bg-emerald-50/60 dark:border-emerald-800 dark:bg-emerald-900/10" : d.status === "REJECTED" ? "border-red-200 bg-red-50/60 dark:border-red-800 dark:bg-red-900/10" : "border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/40"}`}>
                        <div className="min-w-0">
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">{dateLabel}</span>
                            <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${statusBadge(d.status)}`}>{d.status}</span>
                          </div>
                          {d.notes && <p className="mt-0.5 text-xs text-slate-600 dark:text-slate-400">{d.notes}</p>}
                          {d.supervisorNote && <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400 italic">Note: {d.supervisorNote}</p>}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Weekly plan submit modal */}
      {showWeeklyForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setShowWeeklyForm(false)} />
          <div className="relative z-10 w-full max-w-lg rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">Submit Team Weekly Plan</h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">As team leader, you are submitting this plan on behalf of <strong>{team.name}</strong>.</p>
            <form onSubmit={(e) => void submitWeeklyPlan(e)} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200 mb-1">Week number</label>
                <input type="number" min={1} value={weekNum} onChange={(e) => setWeekNum(parseInt(e.target.value, 10))} readOnly
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 cursor-not-allowed" />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200 mb-1">Team plan description</label>
                <textarea required value={planDesc} onChange={(e) => setPlanDesc(e.target.value)} rows={5}
                  placeholder="Describe what the team will work on this week…"
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none" />
              </div>
              <div className="flex gap-3 pt-1">
                <button type="button" onClick={() => setShowWeeklyForm(false)}
                  className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800">
                  Cancel
                </button>
                <button type="submit" disabled={submittingWeekly || !planDesc.trim()}
                  className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60 inline-flex items-center justify-center gap-2">
                  <Send className="h-4 w-4" />
                  {submittingWeekly ? "Submitting…" : "Submit plan"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Daily plan submit modal */}
      {showDailyForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setShowDailyForm(null)} />
          <div className="relative z-10 w-full max-w-md rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">Submit Team Daily Plan</h3>
            <form onSubmit={(e) => void submitDailyPlan(e)} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200 mb-1">Date</label>
                <input type="date" required value={dailyDate} onChange={(e) => setDailyDate(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500" />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200 mb-1">Notes <span className="font-normal text-slate-400">(optional)</span></label>
                <textarea value={dailyNotes} onChange={(e) => setDailyNotes(e.target.value)} rows={4}
                  placeholder="What did the team work on today?"
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none" />
              </div>
              <div className="flex gap-3 pt-1">
                <button type="button" onClick={() => setShowDailyForm(null)}
                  className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800">
                  Cancel
                </button>
                <button type="submit" disabled={submittingDaily || !dailyDate}
                  className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60">
                  {submittingDaily ? "Submitting…" : "Submit"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <SuccessToast show={toast.show} message={toast.message} onClose={() => setToast({ show: false, message: "" })} />
    </div>
  );
}
