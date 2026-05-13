"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import api from "@/lib/api/client";
import { AlertCircle, X, ClipboardList, Calendar, UsersRound } from "lucide-react";
import { getFileUrl } from "@/lib/utils";
import { cn } from "@/lib/utils";

type DaySubmission = {
  id: number;
  workDate: string;
  notes: string | null;
  status: string;
  supervisorNote: string | null;
  reviewedAt: string | null;
};

type WeeklyPlanRow = {
  id: number;
  week_number: number;
  plan_description: string;
  status: string;
  submitted_at: string;
  feedback: string | null;
  student: {
    user: { full_name: string; email: string };
    university: { name: string };
  };
  presentation: { file_url: string } | null;
  daySubmissions?: DaySubmission[];
};

type TeamDailyPlan = {
  id: number;
  workDate: string;
  notes: string | null;
  status: string;
  supervisorNote: string | null;
  reviewedAt: string | null;
};

type TeamWeeklyPlan = {
  id: number;
  week_number: number;
  plan_description: string;
  status: string;
  submitted_at: string;
  feedback: string | null;
  team: { id: number; name: string };
  project: { id: number; name: string } | null;
  submittedBy: { user: { full_name: string; email: string } };
  dailyPlans: TeamDailyPlan[];
};

type Tab = "weekly" | "daily" | "team";

function statusBadge(status: string) {
  if (status === "APPROVED") return "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300";
  if (status === "REJECTED") return "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300";
  return "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300";
}

function statusLabel(status: string) {
  if (status === "RESUBMITTED") return "PENDING (Resubmitted)";
  return status;
}

export default function SupervisorPlansPage() {
  const [activeTab, setActiveTab] = useState<Tab>("weekly");
  const [rows, setRows] = useState<WeeklyPlanRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<"PENDING" | "ALL">("PENDING");

  // Weekly plan review modal
  const [selected, setSelected] = useState<WeeklyPlanRow | null>(null);
  const [remarks, setRemarks] = useState("");
  const [attendance, setAttendance] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  // Daily plan review
  const [dayNote, setDayNote] = useState("");
  const [reviewingDayId, setReviewingDayId] = useState<number | null>(null);
  const [selectedDay, setSelectedDay] = useState<{ day: DaySubmission; plan: WeeklyPlanRow } | null>(null);

  // Team plans
  const [teamPlans, setTeamPlans] = useState<TeamWeeklyPlan[]>([]);
  const [selectedTeamPlan, setSelectedTeamPlan] = useState<TeamWeeklyPlan | null>(null);
  const [teamRemarks, setTeamRemarks] = useState("");
  const [teamSubmitting, setTeamSubmitting] = useState(false);
  const [selectedTeamDay, setSelectedTeamDay] = useState<{ day: TeamDailyPlan; plan: TeamWeeklyPlan } | null>(null);
  const [teamDayNote, setTeamDayNote] = useState("");
  const [reviewingTeamDayId, setReviewingTeamDayId] = useState<number | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const q = filter === "PENDING" ? "?status=PENDING" : "";
      const res = await api.get<{ success: boolean; data: WeeklyPlanRow[] }>(`/supervisor/weekly-plans${q}`);
      const raw = res.data.data ?? [];
      const withDays = await Promise.all(raw.map(async (p) => {
        try {
          const dr = await api.get<{ success: boolean; data: unknown[] }>(`/progress/plan/${p.id}/days`);
          return { ...p, daySubmissions: (dr.data.data ?? []) as DaySubmission[] };
        } catch { return p; }
      }));
      setRows(withDays);
      // Also load team plans
      try {
        const tq = filter === "PENDING" ? "?status=PENDING" : "";
        const tr = await api.get<{ success: boolean; data: TeamWeeklyPlan[] }>(`/supervisor/team-plans${tq}`);
        setTeamPlans(tr.data.data ?? []);
      } catch { /* non-fatal */ }
    } catch {
      setError("Could not load plans.");
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => { void load(); }, [load]);

  const reviewTeamPlan = async (status: "APPROVED" | "REJECTED") => {
    if (!selectedTeamPlan) return;
    setTeamSubmitting(true);
    try {
      await api.patch(`/supervisor/team-plans/${selectedTeamPlan.id}/review`, {
        status,
        feedback: teamRemarks.trim() || undefined,
      });
      setSelectedTeamPlan(null);
      setTeamRemarks("");
      await load();
    } catch {
      setError("Failed to review team plan.");
    } finally {
      setTeamSubmitting(false);
    }
  };

  const reviewTeamDay = async (dailyId: number, status: "APPROVED" | "REJECTED", note?: string) => {
    setReviewingTeamDayId(dailyId);
    try {
      await api.patch(`/supervisor/team-daily-plans/${dailyId}/review`, {
        status,
        supervisorNote: note?.trim() || undefined,
      });
      setSelectedTeamDay(null);
      setTeamDayNote("");
      await load();
    } catch {
      setError("Failed to review team daily plan.");
    } finally {
      setReviewingTeamDayId(null);
    }
  };

  const review = async (status: "APPROVED" | "REJECTED") => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await api.patch(`/progress/review/${selected.id}`, {
        status,
        remarks: remarks.trim() || undefined,
        attendance: status === "APPROVED" ? attendance : undefined,
      });
      setSelected(null);
      setRemarks("");
      await load();
    } catch {
      setError("Failed to submit review.");
    } finally {
      setSubmitting(false);
    }
  };

  const reviewDay = async (submissionId: number, status: "APPROVED" | "REJECTED", note?: string) => {
    setReviewingDayId(submissionId);
    try {
      await api.patch(`/progress/day-submission/${submissionId}/review`, {
        status,
        supervisorNote: note?.trim() || undefined,
      });
      setSelectedDay(null);
      setDayNote("");
      await load();
    } catch {
      setError("Failed to review daily plan.");
    } finally {
      setReviewingDayId(null);
    }
  };

  // All daily submissions across all plans
  const allDailySubmissions = rows.flatMap((p) =>
    (p.daySubmissions ?? []).map((d) => ({ day: d, plan: p }))
  );
  const pendingDailySubmissions = allDailySubmissions.filter((x) => x.day.status === "PENDING");
  const displayedDailySubmissions = filter === "PENDING" ? pendingDailySubmissions : allDailySubmissions;

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">Plans</h1>
        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
          Review and approve student weekly and daily plans.
        </p>
      </div>

      {/* Top tab bar */}
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1 dark:border-slate-700 dark:bg-slate-800/50">
        <button
          type="button"
          onClick={() => setActiveTab("weekly")}
          className={cn(
            "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "weekly"
              ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-primary-400 dark:ring-slate-700"
              : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          )}
        >
          <ClipboardList className="h-4 w-4 shrink-0" />
          Weekly Plans
          {rows.filter((p) => p.status === "PENDING" || p.status === "RESUBMITTED").length > 0 && (
            <span className="rounded-full bg-amber-100 px-1.5 py-0.5 text-[10px] font-bold text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
              {rows.filter((p) => p.status === "PENDING" || p.status === "RESUBMITTED").length}
            </span>
          )}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("daily")}
          className={cn(
            "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "daily"
              ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-primary-400 dark:ring-slate-700"
              : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          )}
        >
          <Calendar className="h-4 w-4 shrink-0" />
          Daily Plans
          {pendingDailySubmissions.length > 0 && (
            <span className="rounded-full bg-amber-100 px-1.5 py-0.5 text-[10px] font-bold text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
              {pendingDailySubmissions.length}
            </span>
          )}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab("team")}
          className={cn(
            "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
            activeTab === "team"
              ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:text-primary-400 dark:ring-slate-700"
              : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          )}
        >
          <UsersRound className="h-4 w-4 shrink-0" />
          Team Plans
          {teamPlans.filter((p) => p.status === "PENDING" || p.status === "RESUBMITTED").length > 0 && (
            <span className="rounded-full bg-amber-100 px-1.5 py-0.5 text-[10px] font-bold text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
              {teamPlans.filter((p) => p.status === "PENDING" || p.status === "RESUBMITTED").length}
            </span>
          )}
        </button>
      </div>

      {/* Filter buttons */}
      <div className="flex gap-2">
        <button type="button" onClick={() => setFilter("PENDING")}
          className={`rounded-xl px-4 py-2 text-sm font-semibold ${filter === "PENDING" ? "bg-primary-600 text-white" : "border border-slate-200 bg-white text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"}`}>
          Pending
        </button>
        <button type="button" onClick={() => setFilter("ALL")}
          className={`rounded-xl px-4 py-2 text-sm font-semibold ${filter === "ALL" ? "bg-primary-600 text-white" : "border border-slate-200 bg-white text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"}`}>
          All
        </button>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
          <AlertCircle className="h-4 w-4 shrink-0" />{error}
        </div>
      )}

      {/* ── WEEKLY PLANS TAB ── */}
      {activeTab === "weekly" && (
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-900">
          {loading ? (
            <p className="p-8 text-center text-slate-500 dark:text-slate-400">Loading…</p>
          ) : rows.length === 0 ? (
            <p className="p-8 text-center text-slate-500 dark:text-slate-400">No plans in this view.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[720px] text-left text-sm">
                <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/70">
                  <tr>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Week</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Student</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Status</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                  {rows.map((p) => (
                    <tr key={p.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                      <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">Week {p.week_number}</td>
                      <td className="px-4 py-3">
                        <p className="font-medium text-slate-900 dark:text-slate-100">{p.student.user.full_name}</p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">{p.student.university.name}</p>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(p.status)}`}>
                          {statusLabel(p.status)}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button type="button" onClick={() => { setSelected(p); setRemarks(""); setAttendance(true); }}
                          className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700">
                          View / review
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* ── DAILY PLANS TAB ── */}
      {activeTab === "daily" && (
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-900">
          {loading ? (
            <p className="p-8 text-center text-slate-500 dark:text-slate-400">Loading…</p>
          ) : displayedDailySubmissions.length === 0 ? (
            <p className="p-8 text-center text-slate-500 dark:text-slate-400">No daily plans in this view.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[720px] text-left text-sm">
                <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/70">
                  <tr>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Date</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Student</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Week</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Status</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                  {displayedDailySubmissions.map(({ day, plan }) => {
                    const dateLabel = new Date(`${String(day.workDate).slice(0, 10)}T12:00:00.000Z`)
                      .toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });
                    return (
                      <tr key={day.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                        <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">{dateLabel}</td>
                        <td className="px-4 py-3">
                          <p className="font-medium text-slate-900 dark:text-slate-100">{plan.student.user.full_name}</p>
                          <p className="text-xs text-slate-500 dark:text-slate-400">{plan.student.university.name}</p>
                        </td>
                        <td className="px-4 py-3 text-slate-600 dark:text-slate-300">Week {plan.week_number}</td>
                        <td className="px-4 py-3">
                          <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(day.status)}`}>
                            {day.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-right">
                          <button type="button" onClick={() => { setSelectedDay({ day, plan }); setDayNote(""); }}
                            className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700">
                            View / review
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* ── TEAM PLANS TAB ── */}
      {activeTab === "team" && (
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-900">
          {loading ? (
            <p className="p-8 text-center text-slate-500 dark:text-slate-400">Loading…</p>
          ) : teamPlans.length === 0 ? (
            <p className="p-8 text-center text-slate-500 dark:text-slate-400">No team plans in this view.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[720px] text-left text-sm">
                <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/70">
                  <tr>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Team</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Project</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Week</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Submitted by</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Status</th>
                    <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                  {teamPlans.map((p) => (
                    <tr key={p.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <UsersRound className="h-4 w-4 text-primary-500 shrink-0" />
                          <span className="font-medium text-slate-900 dark:text-slate-100">{p.team.name}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-slate-600 dark:text-slate-300">{p.project?.name ?? "—"}</td>
                      <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">Week {p.week_number}</td>
                      <td className="px-4 py-3 text-slate-600 dark:text-slate-300">{p.submittedBy.user.full_name}</td>
                      <td className="px-4 py-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(p.status)}`}>
                          {statusLabel(p.status)}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button type="button" onClick={() => { setSelectedTeamPlan(p); setTeamRemarks(""); }}
                          className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700">
                          View / review
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* ── Team weekly plan review modal ── */}
      {selectedTeamPlan && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setSelectedTeamPlan(null)} />
          <div className="relative z-10 max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900">
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 dark:border-slate-700 px-6 py-5">
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <UsersRound className="h-4 w-4 text-primary-500 shrink-0" />
                  <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">{selectedTeamPlan.team.name} — Week {selectedTeamPlan.week_number}</h2>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(selectedTeamPlan.status)}`}>{statusLabel(selectedTeamPlan.status)}</span>
                </div>
                {selectedTeamPlan.project && <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">📁 {selectedTeamPlan.project.name}</p>}
                <p className="text-xs text-slate-500 dark:text-slate-400">Submitted by {selectedTeamPlan.submittedBy.user.full_name} (Team Leader)</p>
              </div>
              <button type="button" onClick={() => setSelectedTeamPlan(null)} className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:text-slate-500 dark:hover:bg-slate-800">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4 px-6 py-5">
              <div>
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Team&apos;s Plan</p>
                <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 px-4 py-4">
                  <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap leading-relaxed">{selectedTeamPlan.plan_description}</p>
                </div>
              </div>

              {/* Daily plans for this team weekly plan */}
              {selectedTeamPlan.dailyPlans.length > 0 && (
                <div>
                  <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">📆 Team Daily Plans</p>
                  <div className="space-y-2">
                    {selectedTeamPlan.dailyPlans.map((d) => {
                      const dateLabel = new Date(`${String(d.workDate).slice(0, 10)}T12:00:00.000Z`).toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });
                      return (
                        <div key={d.id} className={`rounded-xl border px-4 py-3 ${d.status === "APPROVED" ? "border-emerald-200 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-900/20" : d.status === "REJECTED" ? "border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-900/20" : "border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/60"}`}>
                          <div className="flex items-center justify-between gap-3">
                            <div>
                              <div className="flex items-center gap-2">
                                <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">{dateLabel}</span>
                                <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${statusBadge(d.status)}`}>{d.status}</span>
                              </div>
                              {d.notes && <p className="mt-0.5 text-xs text-slate-600 dark:text-slate-400">{d.notes}</p>}
                            </div>
                            {d.status === "PENDING" && (
                              <div className="flex shrink-0 gap-1.5">
                                <button type="button" disabled={reviewingTeamDayId === d.id}
                                  onClick={() => { setSelectedTeamDay({ day: d, plan: selectedTeamPlan }); setTeamDayNote(""); }}
                                  className="rounded-lg bg-primary-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50">
                                  Review
                                </button>
                              </div>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {selectedTeamPlan.status !== "PENDING" && selectedTeamPlan.status !== "RESUBMITTED" && selectedTeamPlan.feedback && (
                <div>
                  <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Feedback</p>
                  <div className={`rounded-xl border px-4 py-3 text-sm ${selectedTeamPlan.status === "APPROVED" ? "border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-200" : "border-red-200 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200"}`}>
                    {selectedTeamPlan.feedback}
                  </div>
                </div>
              )}

              {(selectedTeamPlan.status === "PENDING" || selectedTeamPlan.status === "RESUBMITTED") && (
                <>
                  <div>
                    <label className="block text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">
                      Feedback <span className="normal-case font-normal">(optional)</span>
                    </label>
                    <textarea value={teamRemarks} onChange={(e) => setTeamRemarks(e.target.value)} rows={3}
                      className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none"
                      placeholder="Feedback for the team…" />
                  </div>
                  <div className="flex gap-3 pt-1">
                    <button type="button" disabled={teamSubmitting} onClick={() => void reviewTeamPlan("REJECTED")}
                      className="flex-1 rounded-xl border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-semibold text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors dark:border-red-800 dark:bg-red-900/20 dark:text-red-300">
                      Reject
                    </button>
                    <button type="button" disabled={teamSubmitting} onClick={() => void reviewTeamPlan("APPROVED")}
                      className="flex-1 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-50 transition-colors">
                      {teamSubmitting ? "Saving…" : "Approve (auto-attendance)"}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── Team daily plan review modal ── */}
      {selectedTeamDay && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setSelectedTeamDay(null)} />
          <div className="relative z-10 w-full max-w-md rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900">
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 dark:border-slate-700 px-6 py-5">
              <div>
                <div className="flex items-center gap-2">
                  <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">
                    {new Date(`${String(selectedTeamDay.day.workDate).slice(0, 10)}T12:00:00.000Z`).toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" })}
                  </h2>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(selectedTeamDay.day.status)}`}>{selectedTeamDay.day.status}</span>
                </div>
                <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">Team: {selectedTeamDay.plan.team.name} · Week {selectedTeamDay.plan.week_number}</p>
              </div>
              <button type="button" onClick={() => setSelectedTeamDay(null)} className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:text-slate-500 dark:hover:bg-slate-800">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4 px-6 py-5">
              <div>
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Team&apos;s Daily Notes</p>
                <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 px-4 py-4">
                  <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap leading-relaxed">
                    {selectedTeamDay.day.notes || <span className="italic text-slate-400">No notes provided.</span>}
                  </p>
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">
                  Note <span className="normal-case font-normal">(optional)</span>
                </label>
                <textarea value={teamDayNote} onChange={(e) => setTeamDayNote(e.target.value)} rows={3}
                  className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none"
                  placeholder="Optional feedback…" />
              </div>
              <div className="flex gap-3 pt-1">
                <button type="button" disabled={reviewingTeamDayId === selectedTeamDay.day.id}
                  onClick={() => void reviewTeamDay(selectedTeamDay.day.id, "REJECTED", teamDayNote)}
                  className="flex-1 rounded-xl border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-semibold text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors dark:border-red-800 dark:bg-red-900/20 dark:text-red-300">
                  Reject
                </button>
                <button type="button" disabled={reviewingTeamDayId === selectedTeamDay.day.id}
                  onClick={() => void reviewTeamDay(selectedTeamDay.day.id, "APPROVED", teamDayNote)}
                  className="flex-1 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-50 transition-colors">
                  {reviewingTeamDayId === selectedTeamDay.day.id ? "Saving…" : "Approve"}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setSelected(null)} />
          <div className="relative z-10 max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900">
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 dark:border-slate-700 px-6 py-5">
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">Week {selected.week_number}</h2>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(selected.status)}`}>{statusLabel(selected.status)}</span>
                </div>
                <p className="mt-1 text-sm font-semibold text-slate-700 dark:text-slate-200">{selected.student.user.full_name}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400">{selected.student.university.name} · Submitted {new Date(selected.submitted_at).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" })}</p>
              </div>
              <button type="button" onClick={() => setSelected(null)} className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:text-slate-500 dark:hover:bg-slate-800">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4 px-6 py-5">
              <div>
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Student&apos;s Plan</p>
                <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 px-4 py-4">
                  <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap leading-relaxed">{selected.plan_description}</p>
                </div>
              </div>
              {selected.presentation?.file_url && (
                <div>
                  <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Presentation</p>
                  <a href={getFileUrl(selected.presentation.file_url)} target="_blank" rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-xl border border-primary-200 bg-primary-50 px-4 py-2.5 text-sm font-semibold text-primary-700 hover:bg-primary-100 transition-colors dark:border-primary-800 dark:bg-primary-900/20 dark:text-primary-300">
                    Open presentation file
                  </a>
                </div>
              )}
              {selected.status !== "PENDING" && selected.status !== "RESUBMITTED" && selected.feedback && (
                <div>
                  <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Supervisor Feedback</p>
                  <div className={`rounded-xl border px-4 py-3 text-sm ${selected.status === "APPROVED" ? "border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-200" : "border-red-200 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200"}`}>
                    {selected.feedback}
                  </div>
                </div>
              )}
              {(selected.status === "PENDING" || selected.status === "RESUBMITTED") && (
                <>
                  <div className="rounded-xl border border-primary-100 bg-primary-50/60 px-4 py-3 text-xs text-slate-600 dark:border-primary-900/50 dark:bg-primary-900/20 dark:text-slate-300">
                    <p className="font-semibold text-slate-800 dark:text-slate-100">AI feedback assistant</p>
                    <p className="mt-1">Draft feedback in the full chat, then copy back into remarks below.</p>
                    <Link href="/supervisor/ai" className="mt-2 inline-block font-semibold text-primary-600 hover:underline">Open AI assistant</Link>
                  </div>
                  <div>
                    <label className="block text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">
                      Feedback / remarks <span className="normal-case font-normal">(optional)</span>
                    </label>
                    <textarea value={remarks} onChange={(e) => setRemarks(e.target.value)} rows={3}
                      className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none"
                      placeholder="Optional notes for the student…" />
                  </div>
                  <label className="flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200 cursor-pointer">
                    <input type="checkbox" checked={attendance} onChange={(e) => setAttendance(e.target.checked)} className="rounded" />
                    Mark attendance present (when approving)
                  </label>
                  <div className="flex gap-3 pt-1">
                    <button type="button" disabled={submitting} onClick={() => void review("REJECTED")}
                      className="flex-1 rounded-xl border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-semibold text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors dark:border-red-800 dark:bg-red-900/20 dark:text-red-300">
                      Reject
                    </button>
                    <button type="button" disabled={submitting} onClick={() => void review("APPROVED")}
                      className="flex-1 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-50 transition-colors">
                      {submitting ? "Saving…" : "Approve"}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── Daily plan review modal ── */}
      {selectedDay && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={() => setSelectedDay(null)} />
          <div className="relative z-10 w-full max-w-md rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900">
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 dark:border-slate-700 px-6 py-5">
              <div>
                <div className="flex items-center gap-2">
                  <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">
                    {new Date(`${String(selectedDay.day.workDate).slice(0, 10)}T12:00:00.000Z`).toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" })}
                  </h2>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(selectedDay.day.status)}`}>{selectedDay.day.status}</span>
                </div>
                <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">{selectedDay.plan.student.user.full_name} · Week {selectedDay.plan.week_number}</p>
              </div>
              <button type="button" onClick={() => setSelectedDay(null)} className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:text-slate-500 dark:hover:bg-slate-800">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4 px-6 py-5">
              <div>
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Student&apos;s Daily Notes</p>
                <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 px-4 py-4">
                  <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap leading-relaxed">
                    {selectedDay.day.notes || <span className="italic text-slate-400">No notes provided.</span>}
                  </p>
                </div>
              </div>
              {selectedDay.day.supervisorNote && (
                <div>
                  <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Your previous note</p>
                  <p className="text-sm text-slate-600 dark:text-slate-400 italic">{selectedDay.day.supervisorNote}</p>
                </div>
              )}
              {selectedDay.day.status === "PENDING" && (
                <>
                  <div>
                    <label className="block text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">
                      Note <span className="normal-case font-normal">(optional)</span>
                    </label>
                    <textarea value={dayNote} onChange={(e) => setDayNote(e.target.value)} rows={3}
                      className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none"
                      placeholder="Optional feedback for the student…" />
                  </div>
                  <div className="flex gap-3 pt-1">
                    <button type="button" disabled={reviewingDayId === selectedDay.day.id}
                      onClick={() => void reviewDay(selectedDay.day.id, "REJECTED", dayNote)}
                      className="flex-1 rounded-xl border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-semibold text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors dark:border-red-800 dark:bg-red-900/20 dark:text-red-300">
                      Reject
                    </button>
                    <button type="button" disabled={reviewingDayId === selectedDay.day.id}
                      onClick={() => void reviewDay(selectedDay.day.id, "APPROVED", dayNote)}
                      className="flex-1 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-50 transition-colors">
                      {reviewingDayId === selectedDay.day.id ? "Saving…" : "Approve"}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
