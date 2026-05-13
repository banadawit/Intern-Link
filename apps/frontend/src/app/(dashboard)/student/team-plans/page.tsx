"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import api from "@/lib/api/client";
import {
  AlertCircle, Plus, Send, Calendar, UsersRound,
  CheckCircle2, XCircle, Clock, Crown, RefreshCw, ArrowRight,
} from "lucide-react";
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
  tl_status: string;
  tl_comment: string | null;
  submittedBy: { user: { full_name: string } };
  dailyPlans: TeamDailyPlan[];
};

type TeamInfo = { id: number; name: string; managerId: number | null };

function statusBadge(status: string) {
  if (status === "APPROVED") return "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300";
  if (status === "REJECTED") return "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300";
  return "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300";
}

/** Local calendar date as YYYY-MM-DD for the API. */
function ymdLocalToday(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

/** Display YYYY-MM-DD as mm/dd/yyyy (en-US). */
function formatYmdAsMmDdYyyy(ymd: string): string {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(ymd)) return ymd;
  const [y, mo, da] = ymd.split("-").map(Number);
  return new Date(y, mo - 1, da).toLocaleDateString("en-US", {
    month: "2-digit",
    day: "2-digit",
    year: "numeric",
  });
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
  const [showDailyForm, setShowDailyForm] = useState<number | null>(null);
  const [dailyDate, setDailyDate] = useState("");
  const [dailyNotes, setDailyNotes] = useState("");
  const [submittingDaily, setSubmittingDaily] = useState(false);

  // TL final review of compiled team plan
  const [tlReviewModal, setTlReviewModal] = useState<TeamWeeklyPlan | null>(null);
  const [tlReviewStatus, setTlReviewStatus] = useState<"APPROVED" | "REVISION_REQUESTED">("APPROVED");
  const [tlReviewComment, setTlReviewComment] = useState("");
  const [tlReviewing, setTlReviewing] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{
        success: boolean;
        data: { team: TeamInfo; isManager: boolean; plans: TeamWeeklyPlan[] };
      }>("/progress/team-plans/my");
      const d = res.data.data;
      setTeam(d.team ?? null);
      setIsManager(d.isManager ?? false);
      setPlans(d.plans ?? []);
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
        workDate: dailyDate || ymdLocalToday(),
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

  const submitTlReview = async () => {
    if (!tlReviewModal) return;
    setTlReviewing(true);
    try {
      await api.patch(`/progress/team-plans/${tlReviewModal.id}/tl-review`, {
        status: tlReviewStatus,
        comment: tlReviewComment.trim() || undefined,
      });
      setTlReviewModal(null);
      setTlReviewComment("");
      setTlReviewStatus("APPROVED");
      setToast({
        show: true,
        message:
          tlReviewStatus === "APPROVED"
            ? "📤 Team plan approved and forwarded to supervisor"
            : "🔄 Revision requested — members have been notified",
      });
      await load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Could not submit review.");
    } finally {
      setTlReviewing(false);
    }
  };

  if (loading)
    return (
      <div className="py-12 text-center text-slate-500 dark:text-slate-400">
        Loading team plans…
      </div>
    );

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
              <span className="rounded-full bg-amber-100 dark:bg-amber-900/40 px-2 py-0.5 text-xs font-bold text-amber-700 dark:text-amber-300 flex items-center gap-1">
                <Crown className="h-3 w-3" /> Team Leader
              </span>
            )}
          </div>
        </div>
        {isManager && (
          <button
            type="button"
            onClick={() => setShowWeeklyForm(true)}
            className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-primary-700"
          >
            <Plus className="h-4 w-4" />
            Submit Weekly Plan
          </button>
        )}
      </div>

      {!isManager && (
        <div className="rounded-xl border border-primary-100 bg-primary-50/60 px-4 py-3 text-sm text-slate-600 dark:border-primary-900/50 dark:bg-primary-900/20 dark:text-slate-300">
          <strong>Your weekly and daily plans:</strong> use{" "}
          <Link href="/student/plans" className="font-semibold text-primary-600 underline-offset-2 hover:underline dark:text-primary-400">
            Weekly Plans
          </Link>{" "}
          to write and submit them to your Team Leader. This tab shows the compiled team plan after your leader forwards it.
        </div>
      )}

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      {/* Plans list */}
      {plans.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-12 text-center">
          <p className="text-slate-500 dark:text-slate-400">No team plans submitted yet.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {plans.map((plan) => {
            const isTlPending = plan.status === "TL_PENDING";
            return (
              <div
                key={plan.id}
                className={cn(
                  "rounded-2xl border bg-white dark:bg-slate-900 shadow-sm overflow-hidden",
                  isTlPending
                    ? "border-amber-300 dark:border-amber-700 ring-1 ring-amber-200 dark:ring-amber-800"
                    : "border-slate-200 dark:border-slate-700"
                )}
              >
                {/* TL pending banner — only visible to TL */}
                {isTlPending && isManager && (
                  <div className="flex items-center justify-between gap-3 bg-amber-50 dark:bg-amber-900/20 border-b border-amber-200 dark:border-amber-800 px-5 py-3">
                    <div className="flex items-center gap-2 text-amber-800 dark:text-amber-300">
                      <Crown className="h-4 w-4 shrink-0 text-amber-500" />
                      <span className="text-sm font-semibold">
                        Awaiting your final review before forwarding to supervisor
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        setTlReviewModal(plan);
                        setTlReviewStatus("APPROVED");
                        setTlReviewComment("");
                      }}
                      className="shrink-0 inline-flex items-center gap-1.5 rounded-xl bg-amber-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-amber-700 transition-colors"
                    >
                      <ArrowRight className="h-3.5 w-3.5" />
                      Review &amp; Forward
                    </button>
                  </div>
                )}
                {isTlPending && !isManager && (
                  <div className="flex items-center gap-2 bg-amber-50 dark:bg-amber-900/20 border-b border-amber-200 dark:border-amber-800 px-5 py-3 text-amber-800 dark:text-amber-300">
                    <Crown className="h-4 w-4 shrink-0 text-amber-500" />
                    <span className="text-sm">Waiting for Team Leader&apos;s final review</span>
                  </div>
                )}

                {/* Plan header */}
                <div className="flex items-start justify-between gap-3 border-b border-slate-100 dark:border-slate-700 px-5 py-4">
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className={cn(
                        "rounded-xl p-2.5 shrink-0",
                        plan.status === "APPROVED"
                          ? "bg-emerald-50 text-emerald-600"
                          : plan.status === "REJECTED"
                          ? "bg-red-50 text-red-600"
                          : "bg-amber-50 text-amber-600"
                      )}
                    >
                      {plan.status === "APPROVED" ? (
                        <CheckCircle2 className="h-4 w-4" />
                      ) : plan.status === "REJECTED" ? (
                        <XCircle className="h-4 w-4" />
                      ) : (
                        <Clock className="h-4 w-4" />
                      )}
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <h3 className="font-bold text-slate-900 dark:text-slate-100">
                          Week {plan.week_number}
                        </h3>
                        <span
                          className={cn(
                            "rounded-full px-2.5 py-0.5 text-xs font-bold",
                            statusBadge(isTlPending ? "PENDING" : plan.status)
                          )}
                        >
                          {isTlPending ? "TL Review" : plan.status}
                        </span>
                        {plan.tl_status === "REVISION_REQUESTED" && !isTlPending && (
                          <span className="rounded-full px-2.5 py-0.5 text-xs font-bold bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300">
                            🔄 TL: Revision Requested
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-500 dark:text-slate-400">
                        Submitted by {plan.submittedBy.user.full_name} ·{" "}
                        {new Date(plan.submitted_at).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  {isManager && plan.status === "APPROVED" && (
                    <button
                      type="button"
                      onClick={() => {
                        setShowDailyForm(plan.id);
                        setDailyDate(ymdLocalToday());
                        setDailyNotes("");
                      }}
                      className="shrink-0 inline-flex items-center gap-1.5 rounded-xl border border-primary-200 bg-primary-50 px-3 py-1.5 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors dark:border-primary-800 dark:bg-primary-900/20 dark:text-primary-300"
                    >
                      <Calendar className="h-3.5 w-3.5" />
                      Add Daily Plan
                    </button>
                  )}
                </div>

                {/* Plan description */}
                <div className="px-5 py-4 space-y-3">
                  <p className="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-wrap leading-relaxed">
                    {plan.plan_description}
                  </p>
                  {plan.tl_comment && (
                    <div className="rounded-xl border border-orange-200 bg-orange-50 dark:border-orange-800 dark:bg-orange-900/20 px-4 py-3 text-sm text-orange-900 dark:text-orange-200">
                      <span className="font-semibold">👑 TL comment: </span>
                      {plan.tl_comment}
                    </div>
                  )}
                  {plan.feedback && (
                    <div
                      className={cn(
                        "rounded-xl border px-4 py-3 text-sm",
                        plan.status === "APPROVED"
                          ? "border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-200"
                          : "border-red-200 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200"
                      )}
                    >
                      <span className="font-semibold">Supervisor feedback: </span>
                      {plan.feedback}
                    </div>
                  )}
                </div>

                {/* Daily plans */}
                {plan.dailyPlans.length > 0 && (
                  <div className="border-t border-slate-100 dark:border-slate-700 px-5 py-3 space-y-2">
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">
                      Daily Plans
                    </p>
                    {plan.dailyPlans.map((d) => {
                      const dateLabel = new Date(
                        `${String(d.workDate).slice(0, 10)}T12:00:00.000Z`
                      ).toLocaleDateString("en-US", {
                        weekday: "short",
                        month: "short",
                        day: "numeric",
                      });
                      return (
                        <div
                          key={d.id}
                          className={cn(
                            "flex items-start justify-between gap-3 rounded-xl border px-3 py-2.5",
                            d.status === "APPROVED"
                              ? "border-emerald-200 bg-emerald-50/60 dark:border-emerald-800 dark:bg-emerald-900/10"
                              : d.status === "REJECTED"
                              ? "border-red-200 bg-red-50/60 dark:border-red-800 dark:bg-red-900/10"
                              : "border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/40"
                          )}
                        >
                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">
                                {dateLabel}
                              </span>
                              <span
                                className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${statusBadge(d.status)}`}
                              >
                                {d.status}
                              </span>
                            </div>
                            {d.notes && (
                              <p className="mt-0.5 text-xs text-slate-600 dark:text-slate-400">
                                {d.notes}
                              </p>
                            )}
                            {d.supervisorNote && (
                              <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400 italic">
                                Note: {d.supervisorNote}
                              </p>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* ── Weekly plan submit modal ── */}
      {showWeeklyForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button
            type="button"
            className="absolute inset-0 bg-slate-900/40"
            onClick={() => setShowWeeklyForm(false)}
          />
          <div className="relative z-10 w-full max-w-lg rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">
              Submit Team Weekly Plan
            </h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              As team leader, you are submitting this plan on behalf of{" "}
              <strong>{team.name}</strong>.
            </p>
            <form onSubmit={(e) => void submitWeeklyPlan(e)} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200 mb-1">
                  Week number
                </label>
                <input
                  type="number"
                  min={1}
                  value={weekNum}
                  readOnly
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 cursor-not-allowed"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200 mb-1">
                  Team plan description
                </label>
                <textarea
                  required
                  value={planDesc}
                  onChange={(e) => setPlanDesc(e.target.value)}
                  rows={5}
                  placeholder="Describe what the team will work on this week…"
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none"
                />
              </div>
              <div className="flex gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => setShowWeeklyForm(false)}
                  className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submittingWeekly || !planDesc.trim()}
                  className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60 inline-flex items-center justify-center gap-2"
                >
                  <Send className="h-4 w-4" />
                  {submittingWeekly ? "Submitting…" : "Submit plan"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Daily plan submit modal ── */}
      {showDailyForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button
            type="button"
            className="absolute inset-0 bg-slate-900/40"
            onClick={() => setShowDailyForm(null)}
          />
          <div className="relative z-10 w-full max-w-md rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">
              Submit Team Daily Plan
            </h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              Date is set to today for this entry. Use Notes to describe what the team worked on.
            </p>
            <form onSubmit={(e) => void submitDailyPlan(e)} className="space-y-4">
              <div className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 dark:border-slate-700 dark:bg-slate-800/60">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400 mb-1">
                  Date
                </p>
                <p className="text-sm font-semibold tabular-nums text-slate-900 dark:text-slate-100">
                  {formatYmdAsMmDdYyyy(dailyDate || ymdLocalToday())}
                </p>
              </div>
              <div>
                <label className="block text-sm font-semibold text-slate-700 dark:text-slate-200 mb-1">
                  Notes <span className="font-normal text-slate-400">(optional)</span>
                </label>
                <textarea
                  value={dailyNotes}
                  onChange={(e) => setDailyNotes(e.target.value)}
                  rows={4}
                  placeholder="What did the team work on today?"
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none"
                />
              </div>
              <div className="flex gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => setShowDailyForm(null)}
                  className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submittingDaily}
                  className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60"
                >
                  {submittingDaily ? "Submitting…" : "Submit"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── TL final review modal ── */}
      {tlReviewModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button
            type="button"
            className="absolute inset-0 bg-slate-900/40"
            onClick={() => setTlReviewModal(null)}
          />
          <div className="relative z-10 w-full max-w-lg rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            {/* Header */}
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-amber-100 dark:bg-amber-900/40 text-amber-600 dark:text-amber-400">
                <Crown className="h-5 w-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
                  Review Team Plan — Week {tlReviewModal.week_number}
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  Approve to forward to supervisor, or request revision from members.
                </p>
              </div>
            </div>

            {/* Plan preview */}
            <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 px-4 py-3 max-h-40 overflow-y-auto">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-1">
                Compiled Plan
              </p>
              <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap leading-relaxed">
                {tlReviewModal.plan_description}
              </p>
            </div>

            {/* Decision toggle */}
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setTlReviewStatus("APPROVED")}
                className={cn(
                  "flex-1 rounded-xl py-2.5 text-sm font-semibold transition-colors",
                  tlReviewStatus === "APPROVED"
                    ? "bg-emerald-600 text-white"
                    : "border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                )}
              >
                ✅ Approve &amp; Forward
              </button>
              <button
                type="button"
                onClick={() => setTlReviewStatus("REVISION_REQUESTED")}
                className={cn(
                  "flex-1 rounded-xl py-2.5 text-sm font-semibold transition-colors",
                  tlReviewStatus === "REVISION_REQUESTED"
                    ? "bg-orange-500 text-white"
                    : "border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                )}
              >
                🔄 Request Revision
              </button>
            </div>

            <textarea
              value={tlReviewComment}
              onChange={(e) => setTlReviewComment(e.target.value)}
              rows={3}
              placeholder={
                tlReviewStatus === "REVISION_REQUESTED"
                  ? "Explain what needs to be revised…"
                  : "Optional comment for the team…"
              }
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-none"
            />

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setTlReviewModal(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={tlReviewing}
                onClick={() => void submitTlReview()}
                className={cn(
                  "flex-1 rounded-xl py-2.5 text-sm font-semibold text-white disabled:opacity-60 inline-flex items-center justify-center gap-2",
                  tlReviewStatus === "APPROVED"
                    ? "bg-emerald-600 hover:bg-emerald-700"
                    : "bg-orange-500 hover:bg-orange-600"
                )}
              >
                {tlReviewing ? (
                  <>
                    <RefreshCw className="h-4 w-4 animate-spin" /> Saving…
                  </>
                ) : tlReviewStatus === "APPROVED" ? (
                  <>
                    <ArrowRight className="h-4 w-4" /> Forward to Supervisor
                  </>
                ) : (
                  "Request Revision"
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      <SuccessToast
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ show: false, message: "" })}
      />
    </div>
  );
}
