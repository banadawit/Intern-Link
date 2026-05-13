"use client";

import { Suspense, useCallback, useEffect, useState } from "react";
import { UsersRound, ClipboardList, Crown, CheckCircle2, XCircle, Clock, ChevronDown, ChevronUp, AlertCircle, Send, RefreshCw, ArrowRight, Check } from "lucide-react";
import { cn } from "@/lib/utils";
import api from "@/lib/api/client";
import MyTeamView from "../my-team/page";
import TeamPlansView from "../team-plans/page";
import SuccessToast from "@/components/shared/SuccessToast";

type Tab = "my-team" | "team-plans" | "collect";

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

function statusBadge(status: string) {
  if (status === "APPROVED") return "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300";
  if (status === "REJECTED" || status === "REVISION_REQUESTED") return "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300";
  return "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300";
}
function tlBadge(status: string) {
  if (status === "APPROVED") return "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300";
  if (status === "REVISION_REQUESTED") return "bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300";
  return "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400";
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
  return roster.every((m) => {
    const plan = m.weeklyPlans.find((p) => p.weekNumber === weekNum);
    return !plan || plan.tl_status === "APPROVED";
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
  const [forwarding, setForwarding] = useState(false);
  const [loadingDraft, setLoadingDraft] = useState(false);

  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try {
      const res = await api.get<{ success: boolean; data: TeamMembersData }>("/progress/team-plans/members");
      setData(res.data.data ?? null);
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
      setForwardModal({ week: weekNum, draft: d.compiledDraft });
    } catch { setError("Could not load compiled draft."); }
    finally { setLoadingDraft(false); }
  };

  const submitForward = async () => {
    if (!forwardModal) return;
    setForwarding(true);
    try {
      await api.post("/progress/team-plans/forward", { week_number: forwardModal.week, plan_description: forwardDesc.trim() });
      setForwardModal(null); setForwardDesc("");
      setToast({ show: true, message: "Team plan forwarded to supervisor successfully" });
      await load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Failed to forward plan.");
    } finally { setForwarding(false); }
  };

  if (loading) return <div className="py-12 text-center text-slate-500 dark:text-slate-400"><RefreshCw className="h-6 w-6 animate-spin text-primary-600 mx-auto" /></div>;
  if (error) return <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300"><AlertCircle className="h-4 w-4 shrink-0" />{error}</div>;
  if (!data) return <div className="rounded-2xl border border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-12 text-center"><p className="text-slate-500 dark:text-slate-400">No team data found.</p></div>;

  const roster = data.members;
  const allWeeks = new Set(roster.flatMap((m) => m.weeklyPlans.map((p) => p.weekNumber)));
  const sortedWeeks = [...allWeeks].sort((a, b) => a - b);

  return (
    <>
    <div className="card overflow-hidden p-0">
      <div className="border-b border-slate-200 bg-gradient-to-r from-slate-50 to-white px-5 py-4 sm:px-6 dark:border-slate-800 dark:from-slate-900 dark:to-slate-950">
        <h2 className="text-lg font-bold tracking-tight text-slate-900 dark:text-slate-100">Collect Plans</h2>
        <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
          Review teammate weekly and daily submissions, then forward each week&apos;s compiled plan to your supervisor.
        </p>
      </div>

      <div className="space-y-6 p-5 sm:p-6">
        <div className="rounded-xl border border-amber-200 bg-amber-50/60 px-4 py-3 text-sm text-amber-900 dark:border-amber-800 dark:bg-amber-900/20 dark:text-amber-200">
          <span className="font-semibold">Team Leader workflow:</span> Approve or request revision on each item below, then use Forward when every teammate&apos;s week is TL-approved. Your own plans stay under Weekly Plans.
        </div>

        {roster.length === 0 ? (
          <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50/50 py-12 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-800/30 dark:text-slate-400">
            No other teammates to show. When students join your team, their submissions appear here.
          </div>
        ) : sortedWeeks.length === 0 ? (
          <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50/50 py-12 text-center text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-800/30 dark:text-slate-400">
            No weekly plans yet. Week cards appear here once teammates submit Week 1, 2, and so on.
          </div>
        ) : (
          <div className="space-y-5">
            {sortedWeeks.map((weekNum) => {
              const allWeeklyTlApproved = weekAllTlWeeklyApproved(roster, weekNum);
              const membersSorted = [...roster].sort((a, b) => {
                const pa = tlPendingForWeek(a, weekNum) > 0;
                const pb = tlPendingForWeek(b, weekNum) > 0;
                if (pa !== pb) return pa ? 1 : -1;
                return a.fullName.localeCompare(b.fullName);
              });

              return (
                <div key={weekNum} className="card overflow-hidden p-0 shadow-sm">
                  <div className="flex flex-col gap-3 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-white px-4 py-3 sm:flex-row sm:items-center sm:justify-between sm:px-5 dark:border-slate-800 dark:from-slate-900 dark:to-slate-950">
                    <div>
                      <h3 className="text-base font-bold tracking-tight text-slate-900 dark:text-slate-100">
                        Week {weekNum}
                      </h3>
                      <p className="text-xs text-slate-500 dark:text-slate-400">
                        Teammate submissions for this internship week · cleared rows first, then items awaiting your review
                      </p>
                    </div>
                    <button
                      type="button"
                      disabled={!allWeeklyTlApproved || loadingDraft}
                      onClick={() => void loadDraftAndForward(weekNum)}
                      className={cn(
                        "inline-flex shrink-0 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition-colors",
                        allWeeklyTlApproved
                          ? "bg-primary-600 text-white hover:bg-primary-700 shadow-sm"
                          : "border border-slate-200 bg-white text-slate-400 cursor-not-allowed dark:border-slate-600 dark:bg-slate-900",
                      )}
                      title={
                        allWeeklyTlApproved
                          ? `Forward Week ${weekNum} to supervisor`
                          : "Approve every teammate weekly plan (TL) for this week first"
                      }
                    >
                      <ArrowRight className="h-4 w-4" />
                      Forward to supervisor
                      {!allWeeklyTlApproved && (
                        <span className="text-[10px] font-normal opacity-90">(pending)</span>
                      )}
                    </button>
                  </div>

                  <div className="divide-y divide-slate-100 dark:divide-slate-800">
                    {membersSorted.map((member) => {
                      const plan = member.weeklyPlans.find((p) => p.weekNumber === weekNum);
                      const rowKey = `${weekNum}:${member.studentId}`;
                      const isOpen = expandedRow === rowKey;
                      const pending = tlPendingForWeek(member, weekNum);

                      return (
                        <div key={member.studentId} className="bg-white dark:bg-slate-900/40">
                          <div className="flex items-start gap-3 px-4 py-3 sm:px-5">
                            <div
                              className={cn(
                                "mt-0.5 flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-bold ring-2 ring-slate-100 dark:ring-slate-800",
                                colorForId(member.studentId),
                              )}
                            >
                              {initials(member.fullName)}
                            </div>
                            <div className="min-w-0 flex-1">
                              <div className="flex flex-wrap items-center gap-2">
                                <p className="font-semibold text-slate-900 dark:text-slate-100">{member.fullName}</p>
                                {!plan && (
                                  <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                                    No submission
                                  </span>
                                )}
                                {plan && (
                                  <>
                                    <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${statusBadge(plan.status)}`}>
                                      {plan.status}
                                    </span>
                                    <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${tlBadge(plan.tl_status)}`}>
                                      TL: {plan.tl_status}
                                    </span>
                                    {pending > 0 && (
                                      <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-bold text-amber-800 dark:bg-amber-900/40 dark:text-amber-200">
                                        Action needed
                                      </span>
                                    )}
                                  </>
                                )}
                              </div>
                              {plan && (
                                <div className="mt-2 flex flex-wrap items-center gap-2">
                                  <button
                                    type="button"
                                    onClick={() => setExpandedRow(isOpen ? null : rowKey)}
                                    className="inline-flex items-center gap-1 text-xs font-semibold text-primary-600 hover:underline dark:text-primary-400"
                                  >
                                    {isOpen ? "Hide details" : "View plan & dailies"}
                                    {isOpen ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />}
                                  </button>
                                  {plan.tl_status === "PENDING" && (
                                    <span className="flex gap-1.5" onClick={(e) => e.stopPropagation()}>
                                      <button
                                        type="button"
                                        onClick={() => {
                                          setReviewModal({
                                            type: "weekly",
                                            id: plan.id,
                                            name: member.fullName,
                                            week: plan.weekNumber,
                                          });
                                          setReviewStatus("REVISION_REQUESTED");
                                          setReviewComment("");
                                        }}
                                        className="rounded-lg border border-orange-200 bg-orange-50 px-2.5 py-1 text-xs font-semibold text-orange-700 hover:bg-orange-100 dark:border-orange-800 dark:bg-orange-900/20 dark:text-orange-300"
                                      >
                                        Revise
                                      </button>
                                      <button
                                        type="button"
                                        onClick={() => {
                                          setReviewModal({
                                            type: "weekly",
                                            id: plan.id,
                                            name: member.fullName,
                                            week: plan.weekNumber,
                                          });
                                          setReviewStatus("APPROVED");
                                          setReviewComment("");
                                        }}
                                        className="rounded-lg bg-emerald-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-emerald-700"
                                      >
                                        Approve weekly
                                      </button>
                                    </span>
                                  )}
                                </div>
                              )}
                            </div>
                          </div>

                          {plan && isOpen && (
                            <div className="space-y-3 border-t border-slate-100 bg-slate-50/70 px-4 py-4 sm:px-5 dark:border-slate-800 dark:bg-slate-800/30">
                              <div className="rounded-xl border border-slate-200 bg-white px-4 py-3 dark:border-slate-700 dark:bg-slate-900">
                                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-1">
                                  Weekly plan
                                </p>
                                <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap">
                                  {plan.description}
                                </p>
                              </div>
                              {plan.tl_comment && (
                                <div className="rounded-xl border border-orange-200 bg-orange-50 px-4 py-3 text-sm text-orange-900 dark:border-orange-800 dark:bg-orange-900/20 dark:text-orange-200">
                                  <span className="font-semibold">TL comment: </span>
                                  {plan.tl_comment}
                                </div>
                              )}
                              {plan.dailySubmissions.length > 0 && (
                                <div>
                                  <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">
                                    Daily plans
                                  </p>
                                  <div className="space-y-1.5">
                                    {plan.dailySubmissions.map((d) => (
                                      <div
                                        key={d.id}
                                        className="flex items-center justify-between gap-3 rounded-lg border border-slate-200 bg-white px-3 py-2 dark:border-slate-700 dark:bg-slate-900"
                                      >
                                        <div className="flex min-w-0 items-center gap-2">
                                          {statusIcon(d.tl_status)}
                                          <span className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                                            {d.workDate}
                                          </span>
                                          <span className={`rounded-full px-1.5 py-0.5 text-[10px] font-bold ${tlBadge(d.tl_status)}`}>
                                            TL: {d.tl_status}
                                          </span>
                                          {d.notes && (
                                            <span className="truncate text-xs text-slate-500 dark:text-slate-400 max-w-[140px]">
                                              {d.notes}
                                            </span>
                                          )}
                                        </div>
                                        {d.tl_status === "PENDING" && (
                                          <div className="flex shrink-0 gap-1">
                                            <button
                                              type="button"
                                              onClick={() => {
                                                setReviewModal({
                                                  type: "daily",
                                                  id: d.id,
                                                  name: member.fullName,
                                                  date: d.workDate,
                                                });
                                                setReviewStatus("REVISION_REQUESTED");
                                                setReviewComment("");
                                              }}
                                              className="rounded border border-orange-200 bg-orange-50 px-2 py-0.5 text-[10px] font-bold text-orange-700 dark:border-orange-800 dark:bg-orange-900/20 dark:text-orange-300"
                                            >
                                              Revise
                                            </button>
                                            <button
                                              type="button"
                                              onClick={() => {
                                                setReviewModal({
                                                  type: "daily",
                                                  id: d.id,
                                                  name: member.fullName,
                                                  date: d.workDate,
                                                });
                                                setReviewStatus("APPROVED");
                                                setReviewComment("");
                                              }}
                                              className="inline-flex items-center justify-center rounded bg-emerald-600 px-2 py-0.5 text-[10px] font-bold text-white hover:bg-emerald-700"
                                              aria-label="Approve daily"
                                            >
                                              <Check className="h-3 w-3" aria-hidden />
                                            </button>
                                          </div>
                                        )}
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
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
                <p className="text-xs text-slate-500 dark:text-slate-400">Edit the compiled plan before submitting</p>
              </div>
            </div>
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">Team Plan Description</label>
              <textarea value={forwardDesc} onChange={(e) => setForwardDesc(e.target.value)} rows={8}
                className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-y" />
            </div>
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
            <Crown className="h-4 w-4 shrink-0 text-amber-500" />Collect Plans
          </button>
        )}
      </div>
      <Suspense fallback={<div className="py-12 text-center text-sm text-slate-500">Loading…</div>}>
        {activeTab === "my-team" && <MyTeamView />}
        {activeTab === "team-plans" && <TeamPlansView />}
        {activeTab === "collect" && isLeader && <CollectPlansView />}
      </Suspense>
    </div>
  );
}
