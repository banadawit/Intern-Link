"use client";

import { Suspense, useCallback, useEffect, useState } from "react";
import { UsersRound, ClipboardList, Crown, CheckCircle2, XCircle, Clock, ChevronDown, ChevronUp, AlertCircle, Send, RefreshCw, ArrowRight, Check, Calendar, Trash2 } from "lucide-react";
import { cn } from "@/lib/utils";
import api from "@/lib/api/client";
import MyTeamView from "../my-team/page";
import TeamPlansView from "../team-plans/page";
import SuccessToast from "@/components/shared/SuccessToast";

type Tab = "my-team" | "team-plans" | "collect" | "collect-daily";

type DaySub = {
  id: number; workDate: string; notes: string | null;
  status: string; tl_status: string; tl_comment: string | null;
};
type MemberWeeklyPlan = {
  id: number; weekNumber: number; description: string;
  status: string; feedback: string | null; submittedAt: string;
  tl_status: string; tl_comment: string | null;
  dailySubmissions: DaySub[];
};
type MemberData = {
  studentId: number; fullName: string; email: string;
  isMe: boolean; weeklyPlans: MemberWeeklyPlan[];
};
type TeamMembersData = { teamId: number; teamName: string; members: MemberData[] };

function tlBadge(status: string) {
  if (status === "APPROVED") return "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300";
  if (status === "REVISION_REQUESTED") return "bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300";
  return "bg-orange-50 text-orange-600 dark:bg-orange-900/20 dark:text-orange-400";
}
function statusIcon(status: string) {
  if (status === "APPROVED") return <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />;
  if (status === "REJECTED" || status === "REVISION_REQUESTED") return <XCircle className="h-3.5 w-3.5 text-red-600" />;
  return <Clock className="h-3.5 w-3.5 text-amber-600" />;
}
function initials(name: string) { return name.split(/\s+/).map((n) => n[0]).join("").toUpperCase().slice(0, 2); }
const COLORS = ["bg-teal-100 text-teal-700","bg-blue-100 text-blue-700","bg-violet-100 text-violet-700","bg-amber-100 text-amber-700","bg-rose-100 text-rose-700","bg-emerald-100 text-emerald-700"];
function colorForId(id: number) { return COLORS[id % COLORS.length]; }

/** TL actions still pending for this member in a given internship week. */
function tlPendingForWeek(member: MemberData, weekNum: number): number {
  const plan = member.weeklyPlans.find((p) => p.weekNumber === weekNum);
  if (!plan) return 0;
  let n = plan.tl_status === "PENDING" ? 1 : 0;
  for (const d of plan.dailySubmissions) {
    if (d.tl_status === "PENDING") n++;
  }
  return n;
}

function weekAllTlWeeklyApproved(roster: MemberData[], weekNum: number): boolean {
  if (roster.length === 0) return false;
  return roster.every((m) => {
    const plan = m.weeklyPlans.find((p) => p.weekNumber === weekNum);
    // Must have submitted AND be TL-approved
    return plan != null && plan.tl_status === "APPROVED";
  });
}

function CollectPlansView() {
  const [data, setData] = useState<TeamMembersData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [expandedRow, setExpandedRow] = useState<string | null>(null);

  // TL review state
  const [reviewModal, setReviewModal] = useState<{ type: "weekly" | "daily"; id: number; name: string; week?: number; date?: string } | null>(null);
  const [reviewStatus, setReviewStatus] = useState<"APPROVED" | "REVISION_REQUESTED">("APPROVED");
  const [reviewComment, setReviewComment] = useState("");
  const [reviewing, setReviewing] = useState(false);

  // Forward to supervisor state
  const [forwardModal, setForwardModal] = useState<{ week: number; draft: string } | null>(null);
  const [forwardDesc, setForwardDesc] = useState("");
  const [forwardTitle, setForwardTitle] = useState("");
  const [forwarding, setForwarding] = useState(false);
  const [loadingDraft, setLoadingDraft] = useState(false);

  // Delete week state
  const [deletingWeek, setDeletingWeek] = useState<number | null>(null);
  const [confirmDeleteWeek, setConfirmDeleteWeek] = useState<number | null>(null);

  // Track which weeks have already been forwarded to supervisor (status PENDING/APPROVED/REJECTED)
  const [forwardedWeeks, setForwardedWeeks] = useState<Set<number>>(new Set());
  // Track supervisor review status per week
  const [weekPlanStatus, setWeekPlanStatus] = useState<Record<number, string>>({});

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const res = await api.get<{ success: boolean; data: TeamMembersData }>("/progress/team-plans/members");
      setData(res.data.data ?? null);
      // Also fetch compiled team plans to know which weeks are already forwarded
      try {
        const myRes = await api.get<{ success: boolean; data: { plans?: { week_number: number; status: string }[] } | null }>("/progress/team-plans/my");
        const plans = myRes.data.data?.plans ?? [];
        const forwarded = new Set(
          plans
            .filter((p) => p.status === "PENDING" || p.status === "APPROVED" || p.status === "REJECTED" || p.status === "RESUBMITTED")
            .map((p) => p.week_number)
        );
        setForwardedWeeks(forwarded);
        // Build status map per week
        const statusMap: Record<number, string> = {};
        for (const p of plans) {
          statusMap[p.week_number] = p.status;
        }
        setWeekPlanStatus(statusMap);
      } catch {
        setForwardedWeeks(new Set());
      }
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Could not load team members' plans. Make sure you are the Team Leader.");
    } finally { setLoading(false); }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const submitReview = async () => {
    if (!reviewModal) return;
    setReviewing(true);
    try {
      if (reviewModal.type === "weekly") {
        await api.patch(`/progress/team-plans/tl-review/weekly/${reviewModal.id}`, { status: reviewStatus, comment: reviewComment.trim() || undefined });
      } else {
        await api.patch(`/progress/team-plans/tl-review/daily/${reviewModal.id}`, { status: reviewStatus, comment: reviewComment.trim() || undefined });
      }
      setReviewModal(null); setReviewComment(""); setReviewStatus("APPROVED");
      setToast({ show: true, message: reviewStatus === "APPROVED" ? "Plan approved" : "Revision requested" });
      await load();
    } catch { setError("Failed to submit review."); }
    finally { setReviewing(false); }
  };

  const loadDraftAndForward = async (weekNum: number) => {
    setLoadingDraft(true);
    try {
      const res = await api.get<{ success: boolean; data: { compiledDraft: string; approvedMembersCount: number; totalMembers: number } }>(`/progress/team-plans/compiled-draft?week=${weekNum}`);
      const d = res.data.data;
      setForwardDesc(d.compiledDraft);
      setForwardTitle("");
      setForwardModal({ week: weekNum, draft: d.compiledDraft });
    } catch { setError("Could not load compiled draft."); }
    finally { setLoadingDraft(false); }
  };

  const submitForward = async () => {
    if (!forwardModal) return;
    setForwarding(true);
    try {
      await api.post("/progress/team-plans/forward", { week_number: forwardModal.week, plan_description: forwardDesc.trim(), title: forwardTitle.trim() || undefined });
      setForwardModal(null); setForwardDesc(""); setForwardTitle("");
      setToast({ show: true, message: "Team weekly plan forwarded to supervisor successfully" });
      await load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Failed to forward plan.");
    } finally { setForwarding(false); }
  };

  const deleteWeek = async (weekNum: number) => {
    setDeletingWeek(weekNum);
    try {
      await api.delete(`/progress/team-week/${weekNum}`);
      setToast({ show: true, message: `🗑️ Week ${weekNum} plans deleted for all members` });
      await load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Failed to delete week plans.");
    } finally {
      setDeletingWeek(null);
    }
  };

  if (loading) return <div className="py-12 text-center text-slate-500 dark:text-slate-400"><RefreshCw className="h-6 w-6 animate-spin text-primary-600 mx-auto" /></div>;
  if (error) return <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300"><AlertCircle className="h-4 w-4 shrink-0" />{error}</div>;
  if (!data) return <div className="rounded-2xl border border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-12 text-center"><p className="text-slate-500 dark:text-slate-400">No team data found.</p></div>;

  const roster = data.members.filter((m) => !m.isMe); // exclude TL themselves
  const allWeeks = new Set(roster.flatMap((m) => m.weeklyPlans.map((p) => p.weekNumber)));
  const sortedWeeks = [...allWeeks].sort((a, b) => a - b);

  return (
    <>
    <div className="card overflow-hidden p-0 shadow-lg ring-1 ring-slate-200 dark:ring-slate-700">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-600 to-emerald-600 px-6 py-5 text-white shadow-md">
        <div className="flex items-center gap-3">
          <div className="rounded-lg bg-white/20 p-2 backdrop-blur-sm">
            <Crown className="h-6 w-6 text-white" />
          </div>
          <div>
            <h2 className="text-xl font-bold tracking-tight">Team Leader Dashboard</h2>
            <p className="text-green-100 text-sm mt-0.5">
              Review teammate submissions and forward compiled plans to supervisor
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-6 space-y-6">
        {/* Workflow info */}
        <div className="rounded-xl bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 border border-green-200 dark:border-green-800/50 px-5 py-4">
          <div className="flex items-start gap-3">
            <div className="mt-0.5 shrink-0">
              <Crown className="h-5 w-5 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <h3 className="font-semibold text-green-900 dark:text-green-200 mb-1">Team Leader Workflow</h3>
              <p className="text-sm text-green-800 dark:text-green-300 leading-relaxed">
                Review each teammate's weekly and daily plans → Approve or request revision → Click "Forward to Supervisor" to submit the compiled team plan. Members who haven't submitted will be marked absent.
              </p>
              <p className="text-xs text-green-700 dark:text-green-400 mt-2 italic">
                Note: Your own plans are submitted separately under "Weekly Plans".
              </p>
            </div>
          </div>
        </div>

        {roster.length === 0 ? (
          <div className="rounded-2xl border-2 border-dashed border-slate-300 dark:border-slate-700 bg-slate-50/50 dark:bg-slate-900/30 py-16 text-center">
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-slate-200 dark:bg-slate-800">
              <UsersRound className="h-8 w-8 text-slate-400" />
            </div>
            <h3 className="text-lg font-semibold text-slate-700 dark:text-slate-300">No teammates yet</h3>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400 max-w-md mx-auto">
              When students join your team, their submissions will appear here for your review.
            </p>
          </div>
        ) : sortedWeeks.length === 0 ? (
          <div className="rounded-2xl border-2 border-dashed border-slate-300 dark:border-slate-700 bg-slate-50/50 dark:bg-slate-900/30 py-16 text-center">
            <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-slate-200 dark:bg-slate-800">
              <ClipboardList className="h-8 w-8 text-slate-400" />
            </div>
            <h3 className="text-lg font-semibold text-slate-700 dark:text-slate-300">No submissions yet</h3>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400 max-w-md mx-auto">
              Teammates will submit their weekly plans here. Week cards appear once submissions start.
            </p>
          </div>
        ) : (
          <div className="space-y-6">
            {sortedWeeks.map((weekNum) => {
              const allWeeklyTlApproved = weekAllTlWeeklyApproved(roster, weekNum);
              const membersSorted = [...roster].sort((a, b) => {
                const pa = tlPendingForWeek(a, weekNum) > 0;
                const pb = tlPendingForWeek(b, weekNum) > 0;
                if (pa !== pb) return pa ? 1 : -1;
                return a.fullName.localeCompare(b.fullName);
              });

              return (
                <div key={weekNum} className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm overflow-hidden transition-shadow hover:shadow-md">
                  {/* Week header */}
                  <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between px-6 py-5 border-b border-slate-100 dark:border-slate-800 bg-gradient-to-r from-slate-50 to-white dark:from-slate-900 dark:to-slate-900">
                    <div>
                      <div className="flex items-center gap-3">
                        <div className={cn(
                          "flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-lg font-bold",
                          allWeeklyTlApproved
                            ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300"
                            : "bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400"
                        )}>
                          {allWeeklyTlApproved ? <Check className="h-6 w-6" /> : <Clock className="h-6 w-6" />}
                        </div>
                        <div>
                          <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">
                            Week {weekNum}
                          </h3>
                          <div className="flex items-center gap-2 mt-0.5 flex-wrap">
                            <p className="text-xs text-slate-500 dark:text-slate-400">
                              {roster.length} teammates · {membersSorted.filter((m) => tlPendingForWeek(m, weekNum) === 0).length} approved
                            </p>
                            {weekPlanStatus[weekNum] === "APPROVED" && (
                              <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 dark:bg-emerald-900/30 px-2 py-0.5 text-[10px] font-bold text-emerald-700 dark:text-emerald-300">
                                <CheckCircle2 className="h-3 w-3" /> Supervisor Approved
                              </span>
                            )}
                            {weekPlanStatus[weekNum] === "REJECTED" && (
                              <span className="inline-flex items-center gap-1 rounded-full bg-red-100 dark:bg-red-900/30 px-2 py-0.5 text-[10px] font-bold text-red-700 dark:text-red-300">
                                <XCircle className="h-3 w-3" /> Supervisor Rejected
                              </span>
                            )}
                            {(weekPlanStatus[weekNum] === "PENDING" || weekPlanStatus[weekNum] === "RESUBMITTED") && (
                              <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 dark:bg-amber-900/30 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:text-amber-300">
                                <Clock className="h-3 w-3" /> Awaiting Supervisor
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                    <button
                      type="button"
                      disabled={loadingDraft || forwardedWeeks.has(weekNum)}
                      onClick={() => !forwardedWeeks.has(weekNum) && void loadDraftAndForward(weekNum)}
                      className={cn(
                        "inline-flex shrink-0 items-center justify-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold transition-all shadow-sm",
                        forwardedWeeks.has(weekNum)
                          ? "bg-emerald-100 text-emerald-700 cursor-not-allowed dark:bg-emerald-900/30 dark:text-emerald-300"
                          : "bg-green-600 text-white hover:bg-green-700 hover:shadow-green-200/50 dark:hover:shadow-green-900/30 disabled:opacity-60"
                      )}
                      title={forwardedWeeks.has(weekNum) ? `Week ${weekNum} already forwarded to supervisor` : `Forward Week ${weekNum} to supervisor`}
                    >
                      {forwardedWeeks.has(weekNum) ? (
                        <><CheckCircle2 className="h-4 w-4" /> Forwarded</>
                      ) : (
                        <><ArrowRight className="h-4 w-4" /> Forward to Supervisor</>
                      )}
                    </button>
                    <button
                      type="button"
                      disabled={deletingWeek === weekNum}
                      onClick={() => setConfirmDeleteWeek(weekNum)}
                      className="inline-flex items-center justify-center rounded-xl border border-red-200 bg-red-50 p-2.5 text-red-600 hover:bg-red-100 dark:border-red-800 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/40 transition-colors disabled:opacity-50"
                      title={`Delete all Week ${weekNum} plans`}
                    >
                      {deletingWeek === weekNum
                        ? <RefreshCw className="h-4 w-4 animate-spin" />
                        : <Trash2 className="h-4 w-4" />
                      }
                    </button>
                  </div>

                  {/* Member plan cards — with all actions inline */}
                  <div className="px-6 py-4">
                    <p className="mb-3 text-[11px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                      Member Plans
                    </p>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      {membersSorted.map((member) => {
                        const plan = member.weeklyPlans.find((p) => p.weekNumber === weekNum);
                        const rowKey = `${weekNum}:${member.studentId}`;
                        const isOpen = expandedRow === rowKey;
                        const pending = tlPendingForWeek(member, weekNum);

                        return (
                          <div
                            key={member.studentId}
                            className={cn(
                              "rounded-xl border transition-colors",
                              !plan
                                ? "border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"
                                : plan.tl_status === "APPROVED"
                                ? "border-emerald-200 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-900/20"
                                : plan.tl_status === "REVISION_REQUESTED"
                                ? "border-orange-200 bg-orange-50 dark:border-orange-800 dark:bg-orange-900/20"
                                : "border-amber-200 bg-amber-50 dark:border-amber-800 dark:bg-amber-900/20"
                            )}
                          >
                            {/* Card header row */}
                            <div className="flex items-center gap-3 px-4 py-3">
                              <div className={cn(
                                "flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold ring-2 ring-white dark:ring-slate-800 shadow-sm",
                                colorForId(member.studentId)
                              )}>
                                {initials(member.fullName)}
                              </div>
                              <div className="min-w-0 flex-1">
                                <div className="flex flex-wrap items-center gap-2">
                                  <p className="font-semibold text-sm text-slate-900 dark:text-slate-100">{member.fullName}</p>
                                  {pending > 0 && (
                                    <span className="inline-flex items-center gap-1 rounded-full bg-orange-500 px-2 py-0.5 text-[10px] font-bold text-white">
                                      <Clock className="h-3 w-3" />{pending} pending
                                    </span>
                                  )}
                                </div>
                                {plan
                                  ? <p className="text-xs text-slate-500 dark:text-slate-400 line-clamp-1 mt-0.5">{plan.description}</p>
                                  : <p className="text-xs text-slate-400 dark:text-slate-500 italic mt-0.5">No submission yet</p>
                                }
                              </div>
                              {/* Status badge */}
                              <span className="shrink-0">
                                {!plan
                                  ? <span className="rounded-full bg-slate-100 dark:bg-slate-800 px-2 py-0.5 text-[10px] font-bold text-slate-500 dark:text-slate-400">No plan</span>
                                  : plan.tl_status === "APPROVED"
                                  ? <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 dark:bg-emerald-900/30 px-2 py-0.5 text-[10px] font-bold text-emerald-700 dark:text-emerald-300"><CheckCircle2 className="h-3 w-3" />Approved</span>
                                  : plan.tl_status === "REVISION_REQUESTED"
                                  ? <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 dark:bg-orange-900/30 px-2 py-0.5 text-[10px] font-bold text-orange-700 dark:text-orange-300"><XCircle className="h-3 w-3" />Revise</span>
                                  : <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 dark:bg-amber-900/30 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:text-amber-300"><Clock className="h-3 w-3" />Pending</span>
                                }
                              </span>
                            </div>

                            {/* Action row */}
                            {plan && (
                              <div className="flex flex-wrap items-center gap-2 px-4 pb-3 border-t border-black/5 dark:border-white/5 pt-2">
                                <button
                                  type="button"
                                  onClick={() => setExpandedRow(isOpen ? null : rowKey)}
                                  className="inline-flex items-center gap-1 text-xs font-semibold text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 transition-colors"
                                >
                                  {isOpen ? "Hide details" : "View plan & dailies"}
                                  {isOpen ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />}
                                </button>
                                {plan.tl_status === "PENDING" && (
                                  <span className="flex gap-1.5 ml-auto">
                                    <button
                                      type="button"
                                      onClick={() => { setReviewModal({ type: "weekly", id: plan.id, name: member.fullName, week: plan.weekNumber }); setReviewStatus("REVISION_REQUESTED"); setReviewComment(""); }}
                                      className="inline-flex items-center gap-1 rounded-lg border border-orange-200 bg-orange-50 px-2.5 py-1 text-xs font-semibold text-orange-700 hover:bg-orange-100 dark:border-orange-800 dark:bg-orange-900/20 dark:text-orange-300 transition-colors"
                                    >
                                      <XCircle className="h-3 w-3" />Revise
                                    </button>
                                    <button
                                      type="button"
                                      onClick={() => { setReviewModal({ type: "weekly", id: plan.id, name: member.fullName, week: plan.weekNumber }); setReviewStatus("APPROVED"); setReviewComment(""); }}
                                      className="inline-flex items-center gap-1 rounded-lg bg-emerald-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-emerald-700 shadow-sm transition-colors"
                                    >
                                      <CheckCircle2 className="h-3 w-3" />Approve
                                    </button>
                                  </span>
                                )}
                              </div>
                            )}

                            {/* Expanded detail */}
                            {plan && isOpen && (
                              <div className="space-y-3 border-t border-black/5 dark:border-white/5 bg-white/60 dark:bg-slate-900/40 px-4 py-3">
                                <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3">
                                  <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">Weekly plan</p>
                                  <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap leading-relaxed">{plan.description}</p>
                                </div>
                                {plan.tl_comment && (
                                  <div className="rounded-xl border border-orange-200 bg-orange-50 dark:border-orange-800 dark:bg-orange-900/20 px-4 py-3">
                                    <div className="flex items-center gap-2 mb-1">
                                      <Crown className="h-3.5 w-3.5 text-orange-600 dark:text-orange-400" />
                                      <span className="text-xs font-semibold uppercase tracking-wide text-orange-700 dark:text-orange-300">Team Leader Feedback</span>
                                    </div>
                                    <p className="text-sm text-orange-900 dark:text-orange-200 leading-relaxed">{plan.tl_comment}</p>
                                  </div>
                                )}
                                <p className="text-xs text-slate-400 dark:text-slate-500 italic">
                                  Daily plans are reviewed separately in the "Collect Daily Plans" tab.
                                </p>
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>

      {/* TL Review modal */}
      {reviewModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setReviewModal(null)} />
          <div className="relative z-10 w-full max-w-md rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
              Review {reviewModal.type === "weekly" ? `Week ${reviewModal.week}` : reviewModal.date} — {reviewModal.name}
            </h3>
            <div className="flex gap-2">
              <button type="button" onClick={() => setReviewStatus("APPROVED")}
                className={cn("flex-1 rounded-xl py-2.5 text-sm font-semibold transition-colors", reviewStatus === "APPROVED" ? "bg-emerald-600 text-white" : "border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800")}>
                Approve
              </button>
              <button type="button" onClick={() => setReviewStatus("REVISION_REQUESTED")}
                className={cn("flex-1 rounded-xl py-2.5 text-sm font-semibold transition-colors", reviewStatus === "REVISION_REQUESTED" ? "bg-orange-500 text-white" : "border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800")}>
                Request revision
              </button>
            </div>
            <textarea value={reviewComment} onChange={(e) => setReviewComment(e.target.value)} rows={3}
              placeholder={reviewStatus === "REVISION_REQUESTED" ? "Explain what needs to be revised…" : "Optional comment…"}
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-none" />
            <div className="flex gap-3">
              <button type="button" onClick={() => setReviewModal(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800">
                Cancel
              </button>
              <button type="button" disabled={reviewing} onClick={() => void submitReview()}
                className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60">
                {reviewing ? "Saving…" : "Submit"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Forward to supervisor modal */}
      {forwardModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setForwardModal(null)} />
          <div className="relative z-10 w-full max-w-lg rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary-100 dark:bg-primary-900/40 text-primary-600 dark:text-primary-400">
                <Send className="h-5 w-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Forward Week {forwardModal.week} to Supervisor</h3>
                <p className="text-xs text-slate-500 dark:text-slate-400">Add a title and review the compiled plan before submitting</p>
              </div>
            </div>

            {/* Title — shown to supervisor as the plan headline */}
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">
                Plan Title <span className="normal-case font-normal text-slate-400">(shown to supervisor)</span>
              </label>
              <input
                type="text"
                value={forwardTitle}
                onChange={(e) => setForwardTitle(e.target.value)}
                placeholder={`e.g. Week ${forwardModal.week} — API integration & testing`}
                className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-2.5 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-400"
              />
            </div>

            {/* Compiled description — collapsible */}
            <details className="group">
              <summary className="flex cursor-pointer list-none items-center justify-between rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 px-4 py-2.5 text-xs font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors [&::-webkit-details-marker]:hidden">
                <span>Team Plan Description (compiled from all members)</span>
                <span className="text-slate-400 group-open:rotate-180 transition-transform">▾</span>
              </summary>
              <div className="mt-2">
                <textarea
                  value={forwardDesc}
                  onChange={(e) => setForwardDesc(e.target.value)}
                  rows={8}
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-y"
                />
              </div>
            </details>

            <div className="flex gap-3">
              <button type="button" onClick={() => setForwardModal(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800">
                Cancel
              </button>
              <button type="button" disabled={forwarding || !forwardDesc.trim()} onClick={() => void submitForward()}
                className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60 inline-flex items-center justify-center gap-2">
                <Send className="h-4 w-4" />
                {forwarding ? "Forwarding…" : "Submit to Supervisor"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirm delete week dialog */}
      {confirmDeleteWeek !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" onClick={() => setConfirmDeleteWeek(null)} />
          <div className="relative z-10 w-full max-w-sm rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            <div className="flex items-start gap-4">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-red-50 dark:bg-red-900/30">
                <Trash2 className="h-5 w-5 text-red-600 dark:text-red-400" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Delete Week {confirmDeleteWeek}?</h3>
                <p className="mt-1 text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
                  This will permanently delete <strong>all members' Week {confirmDeleteWeek} plans</strong>, their daily submissions, and the compiled team plan for this week. This cannot be undone.
                </p>
              </div>
            </div>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setConfirmDeleteWeek(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={deletingWeek !== null}
                onClick={() => {
                  const wk = confirmDeleteWeek;
                  setConfirmDeleteWeek(null);
                  void deleteWeek(wk);
                }}
                className="flex-1 inline-flex items-center justify-center gap-2 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60 transition-colors"
              >
                <Trash2 className="h-4 w-4" />
                {deletingWeek !== null ? "Deleting…" : "Delete"}
              </button>
            </div>
          </div>
        </div>
      )}

      <SuccessToast show={toast.show} message={toast.message} onClose={() => setToast({ show: false, message: "" })} />
    </>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Collect Daily Plans View — TL reviews members' daily submissions per week
// ─────────────────────────────────────────────────────────────────────────────

type DailyMember = {
  studentId: number; fullName: string; email: string;
  weeklyPlanId: number | null; weeklyPlanApproved: boolean;
  dailySubmissions: { id: number; workDate: string; notes: string | null; tl_status: string; tl_comment: string | null }[];
};
type DailyWeekData = {
  weekNumber: number;
  teamWeeklyPlanApproved: boolean;
  teamWeeklyPlanId: number | null;
  teamWeeklyPlanDescription: string | null;
  forwardedDailyDates: Record<string, string>;
  members: DailyMember[];
};
type DailyTeamData = { teamId: number; teamName: string; weeks: DailyWeekData[] };

function allDatesForWeek(members: DailyMember[]): string[] {
  const dates = new Set<string>();
  for (const m of members) for (const d of m.dailySubmissions) dates.add(d.workDate);
  return [...dates].sort();
}

/** At least one member submitted for this date — enough to enable forwarding */
function anyMemberSubmittedDate(members: DailyMember[], date: string): boolean {
  return members.some((m) => m.dailySubmissions.some((d) => d.workDate === date));
}

/** Count of members who submitted AND were TL-approved for this date */
function approvedCountForDate(members: DailyMember[], date: string): number {
  return members.filter((m) =>
    m.dailySubmissions.some((d) => d.workDate === date && d.tl_status === "APPROVED")
  ).length;
}

/** Count of members who submitted (regardless of TL status) for this date */
function submittedCountForDate(members: DailyMember[], date: string): number {
  return members.filter((m) => m.dailySubmissions.some((d) => d.workDate === date)).length;
}

function CollectDailyPlansView() {
  const [data, setData] = useState<DailyTeamData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [expandedWeek, setExpandedWeek] = useState<number | null>(null);

  // TL review state for daily submissions
  const [reviewModal, setReviewModal] = useState<{ id: number; name: string; date: string; weekNum: number } | null>(null);
  const [reviewStatus, setReviewStatus] = useState<"APPROVED" | "REVISION_REQUESTED">("APPROVED");
  const [reviewComment, setReviewComment] = useState("");
  const [reviewing, setReviewing] = useState(false);

  // Forward state
  const [forwarding, setForwarding] = useState<string | null>(null); // "weekNum:date"

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const res = await api.get<{ success: boolean; data: DailyTeamData }>("/progress/team-plans/members/daily");
      setData(res.data.data ?? null);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Could not load daily plans. Make sure you are the Team Leader.");
    } finally { setLoading(false); }
  }, []);

  // Forward daily modal state — per-member editable entries
  const [forwardDailyModal, setForwardDailyModal] = useState<{ weekNum: number; date: string; dateLabel: string } | null>(null);
  const [forwardDailyEntries, setForwardDailyEntries] = useState<{ studentId: number; fullName: string; notes: string; tl_status: string }[]>([]);

  useEffect(() => { void load(); }, [load]);

  const submitReview = async () => {
    if (!reviewModal) return;
    setReviewing(true);
    try {
      await api.patch(`/progress/team-plans/tl-review/daily/${reviewModal.id}`, {
        status: reviewStatus,
        comment: reviewComment.trim() || undefined,
      });
      setReviewModal(null); setReviewComment(""); setReviewStatus("APPROVED");
      setToast({ show: true, message: reviewStatus === "APPROVED" ? "Daily plan approved" : "Revision requested" });
      await load();
    } catch { setError("Failed to submit review."); }
    finally { setReviewing(false); }
  };

  const openForwardModal = (weekNum: number, date: string, roster: DailyMember[]) => {
    const dateLabel = new Date(`${date}T12:00:00.000Z`).toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" });
    // Build per-member entries — all members shown, absent ones have empty notes
    const entries = roster.map((m) => {
      const sub = m.dailySubmissions.find((d) => d.workDate === date);
      return {
        studentId: m.studentId,
        fullName: m.fullName,
        notes: sub?.notes ?? "",
        tl_status: sub?.tl_status ?? "NOT_SUBMITTED",
      };
    });
    setForwardDailyEntries(entries);
    setForwardDailyModal({ weekNum, date, dateLabel });
  };

  const submitForwardDaily = async () => {
    if (!forwardDailyModal) return;
    const key = `${forwardDailyModal.weekNum}:${forwardDailyModal.date}`;
    setForwarding(key);
    try {
      // Compile notes from all entries that have content
      const compiledNotes = forwardDailyEntries
        .filter((e) => e.notes.trim())
        .map((e) => `**${e.fullName}:**\n${e.notes.trim()}`)
        .join("\n\n");
      await api.post("/progress/team-plans/forward-daily", {
        week_number: forwardDailyModal.weekNum,
        work_date: forwardDailyModal.date,
        notes: compiledNotes || undefined,
      });
      setForwardDailyModal(null);
      setForwardDailyEntries([]);
      setToast({ show: true, message: `Daily plan for ${forwardDailyModal.date} forwarded to supervisor` });
      await load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Failed to forward daily plan.");
    } finally { setForwarding(null); }
  };

  if (loading) return <div className="py-12 text-center"><RefreshCw className="h-6 w-6 animate-spin text-primary-600 mx-auto" /></div>;
  if (error) return <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300"><AlertCircle className="h-4 w-4 shrink-0" />{error}</div>;
  if (!data) return <div className="rounded-2xl border border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-12 text-center"><p className="text-slate-500 dark:text-slate-400">No team data found.</p></div>;

  const approvedWeeks = data.weeks.filter((w) => w.teamWeeklyPlanApproved);

  return (
    <>
      <div className="card overflow-hidden p-0 shadow-lg ring-1 ring-slate-200 dark:ring-slate-700">
        {/* Header */}
        <div className="bg-gradient-to-r from-green-600 to-emerald-600 px-6 py-5 text-white shadow-md">
          <div className="flex items-center gap-3">
            <div className="rounded-lg bg-white/20 p-2 backdrop-blur-sm">
              <Calendar className="h-6 w-6 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold tracking-tight">Collect Daily Plans</h2>
              <p className="text-green-100 text-sm mt-0.5">
                Review teammates' daily submissions and forward to supervisor after all are approved
              </p>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {/* Workflow info */}
          <div className="rounded-xl bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 border border-green-200 dark:border-green-800/50 px-5 py-4">
            <div className="flex items-start gap-3">
              <Calendar className="h-5 w-5 text-green-600 dark:text-green-400 mt-0.5 shrink-0" />
              <div>
                <h3 className="font-semibold text-green-900 dark:text-green-200 mb-1">Daily Plan Workflow</h3>
                <p className="text-sm text-green-800 dark:text-green-300 leading-relaxed">
                  Daily plans are only available after the team weekly plan is approved by the supervisor. Review each teammate's daily submission → Approve or request revision → Forward each date to the supervisor once all members are approved.
                </p>
              </div>
            </div>
          </div>

          {approvedWeeks.length === 0 ? (
            <div className="rounded-2xl border-2 border-dashed border-slate-300 dark:border-slate-700 bg-slate-50/50 dark:bg-slate-900/30 py-16 text-center">
              <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-slate-200 dark:bg-slate-800">
                <Clock className="h-8 w-8 text-slate-400" />
              </div>
              <h3 className="text-lg font-semibold text-slate-700 dark:text-slate-300">No approved weekly plans yet</h3>
              <p className="mt-1 text-sm text-slate-500 dark:text-slate-400 max-w-md mx-auto">
                Daily plans unlock once the supervisor approves the team weekly plan. Go to "Collect Weekly Plans" to forward the weekly plan first.
              </p>
            </div>
          ) : (
            <div className="space-y-6">
              {approvedWeeks.map((week) => {
                const roster = week.members;
                const allDates = allDatesForWeek(roster);
                const isOpen = expandedWeek === week.weekNumber;

                return (
                  <div key={week.weekNumber} className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
                    {/* Week header */}
                    <button
                      type="button"
                      onClick={() => setExpandedWeek(isOpen ? null : week.weekNumber)}
                      className="w-full flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800 bg-gradient-to-r from-slate-50 to-white dark:from-slate-900 dark:to-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300 font-bold">
                          <CheckCircle2 className="h-5 w-5" />
                        </div>
                        <div className="text-left">
                          <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Week {week.weekNumber}</h3>
                          <p className="text-xs text-slate-500 dark:text-slate-400">
                            Weekly plan approved · {allDates.length} date{allDates.length !== 1 ? "s" : ""} submitted
                          </p>
                        </div>
                      </div>
                      {isOpen ? <ChevronUp className="h-4 w-4 text-slate-400" /> : <ChevronDown className="h-4 w-4 text-slate-400" />}
                    </button>

                    {/* Approved weekly plan reference */}
                    {isOpen && week.teamWeeklyPlanDescription && (
                      <div className="px-6 py-3 bg-emerald-50/60 dark:bg-emerald-900/10 border-b border-emerald-100 dark:border-emerald-900/30">
                        <p className="text-[10px] font-bold uppercase tracking-widest text-emerald-600 dark:text-emerald-400 mb-1">📋 Approved Weekly Plan (Reference)</p>
                        <p className="text-xs text-slate-700 dark:text-slate-300 whitespace-pre-wrap line-clamp-3 leading-relaxed">
                          {week.teamWeeklyPlanDescription}
                        </p>
                      </div>
                    )}

                    {/* Dates */}
                    {isOpen && (
                      <div className="divide-y divide-slate-100 dark:divide-slate-800">
                        {allDates.length === 0 ? (
                          <div className="px-6 py-8 text-center text-sm text-slate-500 dark:text-slate-400">
                            No daily submissions yet for this week.
                          </div>
                        ) : (
                          allDates.map((date) => {
                            const approvedCount = approvedCountForDate(roster, date);
                            const submittedCount = submittedCountForDate(roster, date);
                            const canForward = anyMemberSubmittedDate(roster, date);
                            const fwdKey = `${week.weekNumber}:${date}`;
                            const isForwarding = forwarding === fwdKey;
                            const dateLabel = new Date(`${date}T12:00:00.000Z`).toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });
                            const dailyStatus = week.forwardedDailyDates?.[date]; // PENDING | APPROVED | REJECTED | undefined
                            const isForwarded = !!dailyStatus;

                            return (
                              <div key={date} className="px-6 py-4">
                                {/* Date row header */}
                                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-3">
                                  <div className="flex items-center gap-2">
                                    <div className={cn(
                                      "flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-xs font-bold",
                                      dailyStatus === "APPROVED"
                                        ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300"
                                        : dailyStatus === "PENDING"
                                        ? "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300"
                                        : approvedCount === submittedCount && submittedCount > 0                                        ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300"
                                        : submittedCount > 0
                                        ? "bg-orange-100 text-orange-600 dark:bg-orange-900/20 dark:text-orange-400"
                                        : "bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"
                                    )}>
                                      {dailyStatus === "APPROVED"
                                        ? <CheckCircle2 className="h-4 w-4" />
                                        : dailyStatus === "PENDING"
                                        ? <Clock className="h-4 w-4" />
                                        : approvedCount === submittedCount && submittedCount > 0
                                        ? <CheckCircle2 className="h-4 w-4" />
                                        : <Clock className="h-4 w-4" />}
                                    </div>
                                    <div>
                                      <p className="font-semibold text-sm text-slate-900 dark:text-slate-100">{dateLabel}</p>
                                      <div className="flex items-center gap-2 flex-wrap mt-0.5">
                                        <p className="text-xs text-slate-500 dark:text-slate-400">
                                          {submittedCount}/{roster.length} submitted · {approvedCount} approved
                                          {roster.length - submittedCount > 0 && (
                                            <span className="ml-1 text-slate-400 dark:text-slate-500">
                                              · {roster.length - submittedCount} absent
                                            </span>
                                          )}
                                        </p>
                                        {dailyStatus === "APPROVED" && (
                                          <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 dark:bg-emerald-900/30 px-2 py-0.5 text-[10px] font-bold text-emerald-700 dark:text-emerald-300">
                                            <CheckCircle2 className="h-3 w-3" /> Supervisor Approved
                                          </span>
                                        )}
                                        {dailyStatus === "PENDING" && (
                                          <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 dark:bg-amber-900/30 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:text-amber-300">
                                            <Clock className="h-3 w-3" /> Waiting Approval
                                          </span>
                                        )}
                                        {dailyStatus === "REJECTED" && (
                                          <span className="inline-flex items-center gap-1 rounded-full bg-red-100 dark:bg-red-900/30 px-2 py-0.5 text-[10px] font-bold text-red-700 dark:text-red-300">
                                            <XCircle className="h-3 w-3" /> Supervisor Rejected
                                          </span>
                                        )}
                                      </div>
                                    </div>
                                  </div>
                                  {!isForwarded ? (
                                    <button
                                      type="button"
                                      disabled={!canForward || isForwarding}
                                      onClick={() => openForwardModal(week.weekNumber, date, roster)}
                                      className={cn(
                                        "inline-flex shrink-0 items-center gap-2 rounded-xl px-4 py-2 text-xs font-semibold transition-all shadow-sm",
                                        canForward
                                          ? "bg-green-600 text-white hover:bg-green-700"
                                          : "border border-slate-200 bg-slate-50 text-slate-400 cursor-not-allowed dark:border-slate-700 dark:bg-slate-800 dark:text-slate-500"
                                      )}
                                      title={canForward
                                        ? `Forward ${dateLabel} to supervisor`
                                        : "No submissions yet for this date"}
                                    >
                                      <ArrowRight className="h-3.5 w-3.5" />
                                      {isForwarding ? "Forwarding…" : "Forward to Supervisor"}
                                      {canForward && approvedCount < submittedCount && (
                                        <span className="rounded-full bg-white/20 px-1.5 py-0.5 text-[10px] font-bold">
                                          {approvedCount}/{submittedCount} approved
                                        </span>
                                      )}
                                    </button>
                                  ) : (
                                    <span className={cn(
                                      "inline-flex shrink-0 items-center gap-1.5 rounded-xl px-4 py-2 text-xs font-semibold",
                                      dailyStatus === "APPROVED"
                                        ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300"
                                        : dailyStatus === "REJECTED"
                                        ? "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300"
                                        : "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300"
                                    )}>
                                      {dailyStatus === "APPROVED"
                                        ? <><CheckCircle2 className="h-3.5 w-3.5" /> Supervisor Approved</>
                                        : dailyStatus === "REJECTED"
                                        ? <><XCircle className="h-3.5 w-3.5" /> Supervisor Rejected</>
                                        : <><Clock className="h-3.5 w-3.5" /> Waiting Approval</>
                                      }
                                    </span>
                                  )}
                                </div>

                                {/* Member submissions for this date */}
                                <div className="space-y-2 ml-10">
                                  {roster.map((member) => {
                                    const sub = member.dailySubmissions.find((d) => d.workDate === date);
                                    return (
                                      <div key={member.studentId} className={cn(
                                        "flex items-center justify-between gap-3 rounded-lg border px-3 py-2",
                                        !sub
                                          ? "border-slate-200 bg-slate-50/50 dark:border-slate-700 dark:bg-slate-800/20 opacity-60"
                                          : "border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/40"
                                      )}>
                                        <div className="flex items-center gap-2 min-w-0">
                                          <div className={cn(
                                            "flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[10px] font-bold ring-1 ring-white dark:ring-slate-800",
                                            colorForId(member.studentId)
                                          )}>
                                            {initials(member.fullName)}
                                          </div>
                                          <div className="min-w-0">
                                            <p className="text-xs font-semibold text-slate-900 dark:text-slate-100 truncate">{member.fullName}</p>
                                            {sub?.notes && <p className="text-[10px] text-slate-500 dark:text-slate-400 truncate max-w-[200px]">{sub.notes}</p>}
                                          </div>
                                        </div>
                                        <div className="flex items-center gap-2 shrink-0">
                                          {!sub ? (
                                            <span className="inline-flex items-center gap-1 rounded-full bg-slate-200 px-2 py-0.5 text-[10px] font-bold text-slate-500 dark:bg-slate-700 dark:text-slate-400">
                                              <XCircle className="h-3 w-3" /> Absent
                                            </span>
                                          ) : sub.tl_status === "APPROVED" ? (
                                            <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-[10px] font-bold text-green-700 dark:bg-green-900/30 dark:text-green-300">
                                              <CheckCircle2 className="h-3 w-3" /> Approved
                                            </span>
                                          ) : sub.tl_status === "REVISION_REQUESTED" ? (
                                            <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 px-2 py-0.5 text-[10px] font-bold text-orange-700 dark:bg-orange-900/30 dark:text-orange-300">
                                              <XCircle className="h-3 w-3" /> Needs Revision
                                            </span>
                                          ) : (
                                            <span className="inline-flex items-center gap-1 rounded-full bg-orange-50 px-2 py-0.5 text-[10px] font-bold text-orange-600 dark:bg-orange-900/20 dark:text-orange-400">
                                              <Clock className="h-3 w-3" /> Pending
                                            </span>
                                          )}
                                          {sub && sub.tl_status === "PENDING" && (
                                            <div className="flex gap-1">
                                              <button type="button"
                                                onClick={() => { setReviewModal({ id: sub.id, name: member.fullName, date, weekNum: week.weekNumber }); setReviewStatus("REVISION_REQUESTED"); setReviewComment(""); }}
                                                className="rounded border border-orange-200 bg-orange-50 px-2 py-0.5 text-[10px] font-bold text-orange-700 hover:bg-orange-100 dark:border-orange-800 dark:bg-orange-900/20 dark:text-orange-300 transition-colors">
                                                Revise
                                              </button>
                                              <button type="button"
                                                onClick={() => { setReviewModal({ id: sub.id, name: member.fullName, date, weekNum: week.weekNumber }); setReviewStatus("APPROVED"); setReviewComment(""); }}
                                                className="inline-flex items-center gap-1 rounded bg-emerald-600 px-2 py-0.5 text-[10px] font-bold text-white hover:bg-emerald-700 shadow-sm transition-colors">
                                                <Check className="h-3 w-3" /> Approve
                                              </button>
                                            </div>
                                          )}
                                        </div>
                                      </div>
                                    );
                                  })}
                                </div>
                              </div>
                            );
                          })
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Forward Daily Plan modal — TL edits each member's plan individually */}
      {forwardDailyModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setForwardDailyModal(null)} />
          <div className="relative z-10 w-full max-w-xl rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 overflow-hidden max-h-[90vh] flex flex-col">
            {/* Modal header */}
            <div className="bg-gradient-to-r from-green-600 to-emerald-600 px-6 py-4 text-white shrink-0">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-white/20 p-1.5">
                  <Send className="h-4 w-4 text-white" />
                </div>
                <div>
                  <h3 className="text-base font-bold">Forward Daily Plan to Supervisor</h3>
                  <p className="text-green-100 text-xs mt-0.5">{forwardDailyModal.dateLabel}</p>
                </div>
              </div>
            </div>

            {/* Scrollable body */}
            <div className="overflow-y-auto flex-1 p-6 space-y-4">
              <div className="rounded-xl bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800/50 px-4 py-3">
                <p className="text-xs text-green-700 dark:text-green-300 leading-relaxed">
                  Review and edit each member's daily plan below. Members marked <strong>Absent</strong> didn't submit — their attendance will not be recorded. You can still add notes for them if needed.
                </p>
              </div>

              {/* Per-member editable entries */}
              <div className="space-y-3">
                {forwardDailyEntries.map((entry, idx) => (
                  <div key={entry.studentId} className={cn(
                    "rounded-xl border px-4 py-3",
                    entry.tl_status === "APPROVED"
                      ? "border-green-200 bg-green-50/50 dark:border-green-800/50 dark:bg-green-900/10"
                      : entry.tl_status === "NOT_SUBMITTED"
                      ? "border-slate-200 bg-slate-50/50 dark:border-slate-700 dark:bg-slate-800/20 opacity-70"
                      : "border-orange-200 bg-orange-50/50 dark:border-orange-800/50 dark:bg-orange-900/10"
                  )}>
                    {/* Member header */}
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <div className={cn(
                          "flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[10px] font-bold ring-1 ring-white dark:ring-slate-800",
                          colorForId(entry.studentId)
                        )}>
                          {initials(entry.fullName)}
                        </div>
                        <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">{entry.fullName}</span>
                      </div>
                      {entry.tl_status === "APPROVED" ? (
                        <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-[10px] font-bold text-green-700 dark:bg-green-900/30 dark:text-green-300">
                          <CheckCircle2 className="h-3 w-3" /> Approved
                        </span>
                      ) : entry.tl_status === "NOT_SUBMITTED" ? (
                        <span className="inline-flex items-center gap-1 rounded-full bg-slate-200 px-2 py-0.5 text-[10px] font-bold text-slate-500 dark:bg-slate-700 dark:text-slate-400">
                          <XCircle className="h-3 w-3" /> Absent
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 px-2 py-0.5 text-[10px] font-bold text-orange-700 dark:bg-orange-900/30 dark:text-orange-300">
                          <Clock className="h-3 w-3" /> Pending
                        </span>
                      )}
                    </div>
                    {/* Editable notes */}
                    <textarea
                      value={entry.notes}
                      onChange={(e) => {
                        const updated = [...forwardDailyEntries];
                        updated[idx] = { ...updated[idx], notes: e.target.value };
                        setForwardDailyEntries(updated);
                      }}
                      rows={3}
                      placeholder={entry.tl_status === "NOT_SUBMITTED" ? "No submission — add a note if needed…" : "Edit daily plan notes…"}
                      className="w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-green-500/20 focus:border-green-400 resize-none leading-relaxed"
                    />
                  </div>
                ))}
              </div>
            </div>

            {/* Footer buttons */}
            <div className="shrink-0 flex gap-3 px-6 py-4 border-t border-slate-100 dark:border-slate-800">
              <button
                type="button"
                onClick={() => setForwardDailyModal(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={!!forwarding}
                onClick={() => void submitForwardDaily()}
                className="flex-1 inline-flex items-center justify-center gap-2 rounded-xl bg-green-600 py-2.5 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-60 transition-colors"
              >
                <Send className="h-4 w-4" />
                {forwarding ? "Forwarding…" : "Submit to Supervisor"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* TL Review modal for daily */}
      {reviewModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setReviewModal(null)} />
          <div className="relative z-10 w-full max-w-md rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900 p-6 space-y-4">
            <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
              Review {reviewModal.date} — {reviewModal.name}
            </h3>
            <div className="flex gap-2">
              <button type="button" onClick={() => setReviewStatus("APPROVED")}
                className={cn("flex-1 rounded-xl py-2.5 text-sm font-semibold transition-colors", reviewStatus === "APPROVED" ? "bg-emerald-600 text-white" : "border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800")}>
                Approve
              </button>
              <button type="button" onClick={() => setReviewStatus("REVISION_REQUESTED")}
                className={cn("flex-1 rounded-xl py-2.5 text-sm font-semibold transition-colors", reviewStatus === "REVISION_REQUESTED" ? "bg-orange-500 text-white" : "border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800")}>
                Request Revision
              </button>
            </div>
            <textarea
              value={reviewComment}
              onChange={(e) => setReviewComment(e.target.value)}
              placeholder="Optional comment for the student…"
              rows={3}
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-none"
            />
            <div className="flex gap-2">
              <button type="button" onClick={() => setReviewModal(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800">
                Cancel
              </button>
              <button type="button" disabled={reviewing} onClick={() => void submitReview()}
                className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60">
                {reviewing ? "Saving…" : "Submit"}
              </button>
            </div>
          </div>
        </div>
      )}

      <SuccessToast show={toast.show} message={toast.message} onClose={() => setToast({ show: false, message: "" })} />
    </>
  );
}

export default function StudentTeamPage() {
  const [activeTab, setActiveTab] = useState<Tab>("my-team");
  const [isLeader, setIsLeader] = useState(false);

  useEffect(() => {
    api.get<{ success: boolean; data: { isManager?: boolean } | null }>("/progress/team-plans/my")
      .then(({ data }) => { setIsLeader(data.data?.isManager ?? false); })
      .catch(() => {});
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1 dark:border-slate-700 dark:bg-slate-800/50">
        <button type="button" onClick={() => setActiveTab("my-team")}
          className={cn("flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "my-team" ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-primary-400 dark:ring-slate-700" : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200")}>
          <UsersRound className="h-4 w-4 shrink-0" />My Team
        </button>
        <button type="button" onClick={() => setActiveTab("team-plans")}
          className={cn("flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "team-plans" ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-primary-400 dark:ring-slate-700" : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200")}>
          <ClipboardList className="h-4 w-4 shrink-0" />Team Plans
        </button>
        {isLeader && (
          <button type="button" onClick={() => setActiveTab("collect")}
            className={cn("flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
              activeTab === "collect" ? "bg-white text-amber-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-amber-400 dark:ring-slate-700" : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200")}>
            <Crown className="h-4 w-4 shrink-0 text-amber-500" />Collect Weekly Plans
          </button>
        )}
        {isLeader && (
          <button type="button" onClick={() => setActiveTab("collect-daily")}
            className={cn("flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
              activeTab === "collect-daily" ? "bg-white text-amber-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-amber-400 dark:ring-slate-700" : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200")}>
            <Calendar className="h-4 w-4 shrink-0 text-amber-500" />Collect Daily Plans
          </button>
        )}
      </div>
      <Suspense fallback={<div className="py-12 text-center text-sm text-slate-500">Loading…</div>}>
        {activeTab === "my-team" && <MyTeamView />}
        {activeTab === "team-plans" && <TeamPlansView />}
        {activeTab === "collect" && isLeader && <CollectPlansView />}
        {activeTab === "collect-daily" && isLeader && <CollectDailyPlansView />}
      </Suspense>
    </div>
  );
}
