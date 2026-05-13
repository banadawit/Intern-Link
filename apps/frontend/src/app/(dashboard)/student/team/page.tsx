"use client";

import { Suspense, useCallback, useEffect, useState } from "react";
import { UsersRound, ClipboardList, Crown, CheckCircle2, XCircle, Clock, ChevronDown, ChevronUp, AlertCircle } from "lucide-react";
import { cn } from "@/lib/utils";
import api from "@/lib/api/client";
import MyTeamView from "../my-team/page";
import TeamPlansView from "../team-plans/page";

type Tab = "my-team" | "team-plans" | "collect";

// ── Types for member plans ────────────────────────────────────────────────────
type DaySub = { id: number; workDate: string; notes: string | null; status: string };
type MemberWeeklyPlan = {
  id: number; weekNumber: number; description: string;
  status: string; feedback: string | null; submittedAt: string;
  dailySubmissions: DaySub[];
};
type MemberData = {
  studentId: number; fullName: string; email: string;
  isMe: boolean; weeklyPlans: MemberWeeklyPlan[];
};
type TeamMembersData = { teamId: number; teamName: string; members: MemberData[] };

function statusBadge(status: string) {
  if (status === "APPROVED") return "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300";
  if (status === "REJECTED") return "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300";
  return "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300";
}
function statusIcon(status: string) {
  if (status === "APPROVED") return <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />;
  if (status === "REJECTED") return <XCircle className="h-3.5 w-3.5 text-red-600" />;
  return <Clock className="h-3.5 w-3.5 text-amber-600" />;
}

function initials(name: string) {
  return name.split(/\s+/).map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}
const COLORS = [
  "bg-teal-100 text-teal-700 dark:bg-teal-900/40 dark:text-teal-300",
  "bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300",
  "bg-violet-100 text-violet-700 dark:bg-violet-900/40 dark:text-violet-300",
  "bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300",
  "bg-rose-100 text-rose-700 dark:bg-rose-900/40 dark:text-rose-300",
  "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300",
];
function colorForId(id: number) { return COLORS[id % COLORS.length]; }

// ── Collect Plans View ────────────────────────────────────────────────────────
function CollectPlansView() {
  const [data, setData] = useState<TeamMembersData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedMember, setExpandedMember] = useState<number | null>(null);
  const [expandedPlan, setExpandedPlan] = useState<string | null>(null); // `${memberId}-${planId}`

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: TeamMembersData }>("/progress/team-plans/members");
      setData(res.data.data ?? null);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? "Could not load team members' plans. Make sure you are the Team Leader.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  if (loading) return <div className="py-12 text-center text-slate-500 dark:text-slate-400">Loading team plans…</div>;

  if (error) return (
    <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
      <AlertCircle className="h-4 w-4 shrink-0" />{error}
    </div>
  );

  if (!data) return (
    <div className="rounded-2xl border border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-12 text-center">
      <p className="text-slate-500 dark:text-slate-400">No team data found.</p>
    </div>
  );

  // Group all plans by week across all members
  const allWeeks = new Set(data.members.flatMap((m) => m.weeklyPlans.map((p) => p.weekNumber)));
  const sortedWeeks = [...allWeeks].sort((a, b) => a - b);

  return (
    <div className="space-y-6">
      <div className="rounded-xl border border-amber-200 bg-amber-50/60 dark:border-amber-800 dark:bg-amber-900/20 px-4 py-3 text-sm text-amber-800 dark:text-amber-300">
        <span className="font-semibold">👑 Team Leader view</span> — Review each member&apos;s individual plans before compiling the team submission.
      </div>

      {/* Per-member view */}
      <div className="space-y-4">
        {data.members.map((member) => {
          const isExpanded = expandedMember === member.studentId;
          const pendingCount = member.weeklyPlans.filter((p) => p.status === "PENDING" || p.status === "RESUBMITTED").length;

          return (
            <div key={member.studentId} className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
              {/* Member header */}
              <button
                type="button"
                onClick={() => setExpandedMember(isExpanded ? null : member.studentId)}
                className="flex w-full items-center gap-3 px-5 py-4 text-left hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors"
              >
                <div className={cn("flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-sm font-bold ring-2 ring-white dark:ring-slate-900", colorForId(member.studentId))}>
                  {initials(member.fullName)}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="font-bold text-slate-900 dark:text-slate-100">{member.fullName}</p>
                    {member.isMe && <span className="rounded-full bg-slate-200 dark:bg-slate-700 px-2 py-0.5 text-[10px] font-bold text-slate-600 dark:text-slate-300">You</span>}
                  </div>
                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    {member.weeklyPlans.length} plan{member.weeklyPlans.length !== 1 ? "s" : ""}
                    {pendingCount > 0 && <span className="ml-1.5 text-amber-600 dark:text-amber-400 font-semibold">· {pendingCount} pending</span>}
                  </p>
                </div>
                {isExpanded ? <ChevronUp className="h-4 w-4 text-slate-400 shrink-0" /> : <ChevronDown className="h-4 w-4 text-slate-400 shrink-0" />}
              </button>

              {/* Member plans */}
              {isExpanded && (
                <div className="border-t border-slate-100 dark:border-slate-700 divide-y divide-slate-100 dark:divide-slate-700">
                  {member.weeklyPlans.length === 0 ? (
                    <p className="px-5 py-4 text-sm text-slate-400 dark:text-slate-500 italic">No plans submitted yet.</p>
                  ) : (
                    member.weeklyPlans.map((plan) => {
                      const planKey = `${member.studentId}-${plan.id}`;
                      const isPlanExpanded = expandedPlan === planKey;
                      return (
                        <div key={plan.id}>
                          <button
                            type="button"
                            onClick={() => setExpandedPlan(isPlanExpanded ? null : planKey)}
                            className="flex w-full items-center gap-3 px-5 py-3 text-left hover:bg-slate-50/50 dark:hover:bg-slate-800/40 transition-colors"
                          >
                            <div className="flex items-center gap-2 flex-1 min-w-0">
                              {statusIcon(plan.status)}
                              <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">Week {plan.weekNumber}</span>
                              <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${statusBadge(plan.status)}`}>{plan.status}</span>
                              <span className="text-xs text-slate-400 dark:text-slate-500 ml-auto">
                                {plan.dailySubmissions.length} daily · {new Date(plan.submittedAt).toLocaleDateString()}
                              </span>
                            </div>
                            {isPlanExpanded ? <ChevronUp className="h-3.5 w-3.5 text-slate-400 shrink-0" /> : <ChevronDown className="h-3.5 w-3.5 text-slate-400 shrink-0" />}
                          </button>

                          {isPlanExpanded && (
                            <div className="bg-slate-50/60 dark:bg-slate-800/40 px-5 py-4 space-y-3">
                              {/* Plan description */}
                              <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-4 py-3">
                                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-1">Plan Description</p>
                                <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap leading-relaxed">{plan.description}</p>
                              </div>
                              {plan.feedback && (
                                <div className={`rounded-xl border px-4 py-3 text-sm ${plan.status === "APPROVED" ? "border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-200" : "border-red-200 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200"}`}>
                                  <span className="font-semibold">Supervisor feedback: </span>{plan.feedback}
                                </div>
                              )}
                              {/* Daily submissions */}
                              {plan.dailySubmissions.length > 0 && (
                                <div>
                                  <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">Daily Check-ins</p>
                                  <div className="grid grid-cols-1 gap-1.5 sm:grid-cols-2">
                                    {plan.dailySubmissions.map((d) => (
                                      <div key={d.id} className={`flex items-start gap-2 rounded-lg border px-3 py-2 text-xs ${d.status === "APPROVED" ? "border-emerald-200 bg-emerald-50/60 dark:border-emerald-800 dark:bg-emerald-900/10" : d.status === "REJECTED" ? "border-red-200 bg-red-50/60 dark:border-red-800 dark:bg-red-900/10" : "border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900"}`}>
                                        <div className="shrink-0 mt-0.5">{statusIcon(d.status)}</div>
                                        <div className="min-w-0">
                                          <p className="font-semibold text-slate-900 dark:text-slate-100">{d.workDate}</p>
                                          {d.notes && <p className="text-slate-600 dark:text-slate-400 truncate">{d.notes}</p>}
                                        </div>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}
                            </div>
                          )}
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

      {/* Weekly summary table */}
      {sortedWeeks.length > 0 && (
        <div className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
          <div className="border-b border-slate-100 dark:border-slate-700 px-5 py-4">
            <h3 className="font-bold text-slate-900 dark:text-slate-100">📊 Team Progress Summary</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Overview of all members' plan statuses by week</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="border-b border-slate-100 dark:border-slate-700 bg-slate-50/80 dark:bg-slate-800/70">
                <tr>
                  <th className="px-4 py-3 text-left font-semibold text-slate-700 dark:text-slate-200">Member</th>
                  {sortedWeeks.map((w) => (
                    <th key={w} className="px-3 py-3 text-center font-semibold text-slate-700 dark:text-slate-200">W{w}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                {data.members.map((member) => (
                  <tr key={member.studentId} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/40">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <div className={cn("flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-[10px] font-bold", colorForId(member.studentId))}>
                          {initials(member.fullName)}
                        </div>
                        <span className="font-medium text-slate-900 dark:text-slate-100 truncate max-w-[120px]">{member.fullName}</span>
                        {member.isMe && <span className="text-[10px] text-slate-400">(you)</span>}
                      </div>
                    </td>
                    {sortedWeeks.map((w) => {
                      const plan = member.weeklyPlans.find((p) => p.weekNumber === w);
                      return (
                        <td key={w} className="px-3 py-3 text-center">
                          {plan ? (
                            <span className={`inline-flex items-center justify-center rounded-full px-2 py-0.5 text-[10px] font-bold ${statusBadge(plan.status)}`}>
                              {plan.status === "APPROVED" ? "✅" : plan.status === "REJECTED" ? "❌" : "⏳"}
                            </span>
                          ) : (
                            <span className="text-slate-300 dark:text-slate-600">—</span>
                          )}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Main page ─────────────────────────────────────────────────────────────────
export default function StudentTeamPage() {
  const [activeTab, setActiveTab] = useState<Tab>("my-team");
  const [isLeader, setIsLeader] = useState(false);

  // Check if student is TL to show the Collect tab
  useEffect(() => {
    api.get<{ success: boolean; data: { isManager?: boolean } | null }>("/progress/team-plans/my")
      .then(({ data }) => { setIsLeader(data.data?.isManager ?? false); })
      .catch(() => {});
  }, []);

  return (
    <div className="space-y-6">
      {/* Top tab navbar */}
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1 dark:border-slate-700 dark:bg-slate-800/50">
        <button
          type="button"
          onClick={() => setActiveTab("my-team")}
          className={cn(
            "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "my-team"
              ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-primary-400 dark:ring-slate-700"
              : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          )}
        >
          <UsersRound className="h-4 w-4 shrink-0" />
          My Team
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("team-plans")}
          className={cn(
            "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "team-plans"
              ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-primary-400 dark:ring-slate-700"
              : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          )}
        >
          <ClipboardList className="h-4 w-4 shrink-0" />
          Team Plans
        </button>
        {isLeader && (
          <button
            type="button"
            onClick={() => setActiveTab("collect")}
            className={cn(
              "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
              activeTab === "collect"
                ? "bg-white text-amber-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-amber-400 dark:ring-slate-700"
                : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
            )}
          >
            <Crown className="h-4 w-4 shrink-0 text-amber-500" />
            Collect Plans
          </button>
        )}
      </div>

      {/* Tab content */}
      <Suspense fallback={<div className="py-12 text-center text-sm text-slate-500">Loading…</div>}>
        {activeTab === "my-team" && <MyTeamView />}
        {activeTab === "team-plans" && <TeamPlansView />}
        {activeTab === "collect" && isLeader && <CollectPlansView />}
      </Suspense>
    </div>
  );
}
