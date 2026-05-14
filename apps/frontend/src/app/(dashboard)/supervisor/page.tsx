"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import api from "@/lib/api/client";
import { useAuth } from "@/lib/hooks/useAuth";
import {
  ClipboardList, Inbox, Users, RefreshCw,
  ChevronRight, FileCheck, Clock, UsersRound,
  FolderKanban, CalendarDays, MessageSquare, AlertCircle,
  TrendingUp,
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import { cn } from "@/lib/utils";

type MeResponse = {
  supervisor: {
    id: number;
    companyId: number;
    company: { id: number; name: string; official_email: string };
    user: { full_name: string; email: string };
  };
  stats: {
    pendingProposalsCount: number;
    pendingWeeklyPlansCount: number;
    placedStudentsCount: number;
    approvedProposalsCount: number;
    reportsSubmittedCount: number;
    missedCheckinsCount: number;
  };
  recentPendingProposals: {
    id: number;
    studentName: string;
    studentEmail: string;
    universityName: string;
    submitted_at: string;
  }[];
  recentPendingPlans: {
    id: number;
    studentName: string;
    weekNumber: number;
    submitted_at: string;
  }[];
  studentsSummary: {
    studentId: number;
    studentName: string;
    studentEmail: string;
    status: "ACTIVE" | "AT_RISK" | "INACTIVE";
    lastPlanStatus: string | null;
    lastPlanWeek: number | null;
    daysSinceLastPlan: number | null;
    startDate: string;
  }[];
  recentActivity: {
    type: "PLAN" | "PROPOSAL";
    id: number;
    title: string;
    status: string;
    timestamp: string;
  }[];
  deadlines: {
    type: "EVALUATION_DUE" | "REPORT_DUE";
    studentName: string;
    dueDate: string | null;
    daysLeft: number | null;
  }[];
};

type PerformanceData = {
  totalStudentsSupervised: number;
  completedInternships: number;
  averageStudentScore: number | null;
  planApprovalRate: number | null;
};

export default function SupervisorDashboardPage() {
  const { user } = useAuth();
  const [data, setData] = useState<MeResponse | null>(null);
  const [performance, setPerformance] = useState<PerformanceData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: MeResponse }>("/supervisor/me");
      setData(res.data.data);
    } catch (e: unknown) {
      const msg = e && typeof e === "object" && "response" in e
        ? String((e as { response?: { data?: { message?: string } } }).response?.data?.message)
        : "Failed to load dashboard.";
      setError(msg || "Failed to load dashboard.");
    } finally {
      setLoading(false);
    }
    // Performance fetch — non-blocking
    try {
      const perf = await api.get<{ success: boolean; data: PerformanceData }>("/supervisor/performance");
      setPerformance(perf.data.data ?? perf.data as unknown as PerformanceData);
    } catch { /* optional */ }
  }, []);

  useEffect(() => { void load(); }, [load]);

  if (error) {
    return (
      <div className="flex items-center gap-2 rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
        <AlertCircle className="h-5 w-5 shrink-0" />{error}
      </div>
    );
  }

  if (loading || !data) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center">
        <RefreshCw className="h-8 w-8 animate-spin text-primary-600" />
      </div>
    );
  }

  const {
    supervisor, stats,
    recentPendingProposals = [],
    recentPendingPlans = [],
    studentsSummary = [],
    recentActivity = [],
    deadlines = [],
  } = data;

  if (!supervisor?.company) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center text-slate-500 dark:text-slate-400">
        Company profile not linked. Contact support.
      </div>
    );
  }

  const missedCheckinsCount = stats.missedCheckinsCount ?? 0;

  const quickLinks = [
    { href: "/supervisor/proposals",           label: "Proposals",  desc: "Review incoming placement requests", icon: Inbox,        badge: stats.pendingProposalsCount,  color: "bg-primary-50 text-primary-600" },
    { href: "/supervisor/plans",               label: "Weekly plans", desc: "Approve or reject student plans",  icon: ClipboardList, badge: stats.pendingWeeklyPlansCount, color: "bg-primary-50 text-primary-600" },
    { href: "/supervisor/students",            label: "Students",   desc: "View all placed interns",            icon: Users,        badge: 0,                             color: "bg-primary-50 text-primary-600" },
    { href: "/supervisor/teams",               label: "Teams",      desc: "Manage intern groups",               icon: UsersRound,   badge: 0,                             color: "bg-primary-50 text-primary-600" },
    { href: "/supervisor/projects",            label: "Projects",   desc: "Assign and track projects",          icon: FolderKanban, badge: 0,                             color: "bg-primary-50 text-primary-600" },
    { href: "/supervisor/reports",             label: "Reports",    desc: "Submit evaluations & generate PDFs", icon: FileCheck,    badge: 0,                             color: "bg-primary-50 text-primary-600" },
    { href: "/supervisor/attendance/students", label: "Attendance", desc: "Student check-in heatmap",           icon: CalendarDays, badge: 0,                             color: "bg-primary-50 text-primary-600" },
    { href: "/supervisor/chat",                label: "Messages",   desc: "Chat with placed students",          icon: MessageSquare, badge: 0,                            color: "bg-primary-50 text-primary-600" },
  ];

  const statusBadge = (status: "ACTIVE" | "AT_RISK" | "INACTIVE") => {
    if (status === "ACTIVE")   return <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-[10px] font-bold text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300">Active</span>;
    if (status === "AT_RISK")  return <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:bg-amber-900/40 dark:text-amber-300">At risk</span>;
    return <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-bold text-red-700 dark:bg-red-900/40 dark:text-red-300">Inactive</span>;
  };

  const activityStatusBadge = (status: string) => {
    if (status === "APPROVED") return <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-[10px] font-bold text-emerald-700">Approved</span>;
    if (status === "REJECTED") return <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-bold text-red-700">Rejected</span>;
    return <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-bold text-amber-700">Pending</span>;
  };

  const deadlineBadge = (daysLeft: number | null) => {
    if (daysLeft === null) return <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-600">Unknown</span>;
    if (daysLeft <= 3)  return <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-bold text-red-700">{daysLeft}d left</span>;
    if (daysLeft <= 7)  return <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-bold text-amber-700">{daysLeft}d left</span>;
    return <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-600">{daysLeft}d left</span>;
  };

  return (
    <div className="space-y-8 pb-8">
      {/* Hero */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-widest text-primary-600">Company portal</p>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-slate-900 md:text-3xl dark:text-slate-100">
            Welcome back, {user?.fullName ?? supervisor.user.full_name}
          </h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {supervisor.company.name} · {supervisor.company.official_email}
          </p>
        </div>
        <button
          type="button"
          onClick={() => void load()}
          disabled={loading}
          className="inline-flex shrink-0 items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50 disabled:opacity-60 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200 dark:hover:bg-slate-800"
        >
          <RefreshCw className={cn("h-4 w-4", loading && "animate-spin")} />
          Refresh
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {[
          { href: "/supervisor/proposals",           label: "Pending proposals", value: stats.pendingProposalsCount,  sub: stats.pendingProposalsCount > 0 ? "Need your response" : "All reviewed",    icon: Inbox,        accent: "bg-violet-50 text-violet-700 ring-violet-100" },
          { href: "/supervisor/plans",               label: "Pending plans",     value: stats.pendingWeeklyPlansCount, sub: stats.pendingWeeklyPlansCount > 0 ? "Awaiting review" : "All up to date",  icon: ClipboardList, accent: "bg-amber-50 text-amber-700 ring-amber-100" },
          { href: "/supervisor/students",            label: "Active interns",    value: stats.placedStudentsCount,    sub: "Placed at your company",                                                     icon: Users,        accent: "bg-emerald-50 text-emerald-700 ring-emerald-100" },
          { href: "/supervisor/attendance/students", label: "Missed check-ins",  value: missedCheckinsCount,          sub: missedCheckinsCount > 0 ? "Students didn't check in today" : "All checked in today", icon: CalendarDays, accent: "bg-orange-50 text-orange-700 ring-orange-100" },
        ].map((s) => (
          <Link
            key={s.href}
            href={s.href}
            className="group flex items-center gap-4 rounded-2xl border border-border-default bg-white p-5 shadow-sm transition-all duration-200 hover:border-primary-200 hover:shadow-md dark:bg-slate-900 dark:border-slate-700"
          >
            <div className={cn("flex h-12 w-12 shrink-0 items-center justify-center rounded-xl ring-1 transition-transform duration-200 group-hover:scale-105", s.accent)}>
              <s.icon className="h-6 w-6" />
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">{s.label}</p>
              <p className="text-2xl font-bold tabular-nums text-slate-900 dark:text-slate-100">{s.value}</p>
              <p className="text-xs text-slate-500 dark:text-slate-400">{s.sub}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Action needed panels */}
      {(recentPendingProposals.length > 0 || recentPendingPlans.length > 0) && (
        <div className="grid gap-5 lg:grid-cols-2">
          {recentPendingProposals.length > 0 && (
            <div className="rounded-2xl border border-primary-200 bg-primary-50/40 p-5 dark:border-primary-900/50 dark:bg-primary-900/20">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <div className="rounded-lg bg-primary-100 p-1.5 text-primary-600"><Inbox className="h-4 w-4" /></div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Incoming proposals</h3>
                    <p className="text-xs text-slate-500 dark:text-slate-400">{stats.pendingProposalsCount} awaiting response</p>
                  </div>
                </div>
                <Link href="/supervisor/proposals" className="inline-flex items-center gap-1 rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700 transition-colors">
                  View all <ChevronRight className="h-3.5 w-3.5" />
                </Link>
              </div>
              <div className="space-y-2">
                {recentPendingProposals.map((p) => (
                  <div key={p.id} className="flex items-center gap-3 rounded-xl border border-primary-100 bg-white px-4 py-2.5 dark:border-primary-900/50 dark:bg-slate-900">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary-100 text-xs font-bold text-primary-700">
                      {p.studentName.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold text-slate-900 truncate dark:text-slate-100">{p.studentName}</p>
                      <p className="text-xs text-slate-500 truncate dark:text-slate-400">{p.universityName}</p>
                    </div>
                    <span className="shrink-0 flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">
                      <Clock className="h-3 w-3" />
                      {formatDistanceToNow(new Date(p.submitted_at), { addSuffix: true })}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {recentPendingPlans.length > 0 && (
            <div className="rounded-2xl border border-primary-200 bg-primary-50/40 p-5 dark:border-primary-900/50 dark:bg-primary-900/20">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <div className="rounded-lg bg-primary-100 p-1.5 text-primary-600"><ClipboardList className="h-4 w-4" /></div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Plans awaiting review</h3>
                    <p className="text-xs text-slate-500 dark:text-slate-400">{stats.pendingWeeklyPlansCount} pending</p>
                  </div>
                </div>
                <Link href="/supervisor/plans" className="inline-flex items-center gap-1 rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700 transition-colors">
                  View all <ChevronRight className="h-3.5 w-3.5" />
                </Link>
              </div>
              <div className="space-y-2">
                {recentPendingPlans.map((p) => (
                  <div key={p.id} className="flex items-center gap-3 rounded-xl border border-primary-100 bg-white px-4 py-2.5 dark:border-primary-900/50 dark:bg-slate-900">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary-100 text-xs font-bold text-primary-700">
                      {p.studentName.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold text-slate-900 truncate dark:text-slate-100">{p.studentName}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">Week {p.weekNumber}</p>
                    </div>
                    <span className="shrink-0 flex items-center gap-1 text-xs text-slate-400 dark:text-slate-500">
                      <Clock className="h-3 w-3" />
                      {formatDistanceToNow(new Date(p.submitted_at), { addSuffix: true })}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Deadlines alert panel */}
      {deadlines.length > 0 && (
        <div className="rounded-2xl border border-rose-200 bg-rose-50/40 p-5 dark:border-rose-900/50 dark:bg-rose-900/20">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="rounded-lg bg-rose-100 p-1.5 text-rose-600 dark:bg-rose-900/40 dark:text-rose-400">
                <AlertCircle className="h-4 w-4" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Upcoming deadlines</h3>
            </div>
            <Link href="/supervisor/reports" className="text-xs font-semibold text-rose-600 hover:underline dark:text-rose-400">
              View reports →
            </Link>
          </div>
          <div className="space-y-2">
            {deadlines.map((d, i) => (
              <div key={i} className="flex items-center gap-3 rounded-xl border border-rose-100 bg-white px-4 py-2.5 dark:border-rose-900/40 dark:bg-slate-900">
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-slate-900 truncate dark:text-slate-100">{d.studentName}</p>
                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    {d.type === "EVALUATION_DUE" ? "Evaluation due" : "Report due"}
                  </p>
                </div>
                {deadlineBadge(d.daysLeft)}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Student health */}
      {studentsSummary.length > 0 && (
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-bold text-slate-900 dark:text-slate-100">Intern status overview</h2>
            <Link href="/supervisor/students" className="text-xs font-semibold text-primary-600 hover:underline">
              View all →
            </Link>
          </div>
          <div className="space-y-2">
            {studentsSummary.slice(0, 5).map((s) => (
              <div key={s.studentId} className="flex items-center gap-3 rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-2.5 dark:border-slate-700 dark:bg-slate-800/60">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary-100 text-xs font-bold text-primary-700 dark:bg-primary-900/40 dark:text-primary-300">
                  {s.studentName.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-slate-900 truncate dark:text-slate-100">{s.studentName}</p>
                  <p className="text-xs text-slate-500 truncate dark:text-slate-400">
                    {s.daysSinceLastPlan !== null ? `Last plan: ${s.daysSinceLastPlan}d ago` : "No plan yet"}
                  </p>
                </div>
                {statusBadge(s.status)}
              </div>
            ))}
            {studentsSummary.length > 5 && (
              <Link href="/supervisor/students" className="block pt-1 text-center text-xs font-semibold text-primary-600 hover:underline">
                View all {studentsSummary.length} students →
              </Link>
            )}
          </div>
        </div>
      )}

      {/* Recent activity */}
      {recentActivity.length > 0 && (
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <h2 className="mb-4 text-base font-bold text-slate-900 dark:text-slate-100">Recent activity</h2>
          <div className="space-y-2">
            {recentActivity.slice(0, 6).map((a) => (
              <div key={`${a.type}-${a.id}`} className="flex items-center gap-3 rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-2.5 dark:border-slate-700 dark:bg-slate-800/60">
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-slate-900 truncate dark:text-slate-100">{a.title}</p>
                  <p className="text-xs text-slate-400 dark:text-slate-500">
                    {formatDistanceToNow(new Date(a.timestamp), { addSuffix: true })}
                  </p>
                </div>
                <div className="flex shrink-0 items-center gap-1.5">
                  <span className={cn("rounded-full px-2 py-0.5 text-[10px] font-bold",
                    a.type === "PLAN" ? "bg-blue-100 text-blue-700" : "bg-violet-100 text-violet-700")}>
                    {a.type === "PLAN" ? "Plan" : "Proposal"}
                  </span>
                  {activityStatusBadge(a.status)}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Quick links grid */}
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
        <h2 className="text-base font-bold text-slate-900 dark:text-slate-100">Quick access</h2>
        <p className="mt-0.5 text-sm text-slate-500 dark:text-slate-400">Jump to any section of your workspace.</p>
        <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {quickLinks.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-3 transition-colors hover:border-primary-200 hover:bg-primary-50/40 group dark:border-slate-700 dark:bg-slate-800/60 dark:hover:bg-primary-900/20"
            >
              <span className="flex min-w-0 items-center gap-3">
                <span className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-xl", item.color)}>
                  <item.icon className="h-4 w-4" />
                </span>
                <span className="min-w-0">
                  <span className="block text-sm font-semibold text-slate-900 dark:text-slate-100">{item.label}</span>
                  <span className="block truncate text-xs text-slate-500 dark:text-slate-400">{item.desc}</span>
                </span>
              </span>
              <span className="flex shrink-0 items-center gap-1.5">
                {item.badge > 0 && (
                  <span className="rounded-full bg-rose-100 px-1.5 py-0.5 text-[10px] font-bold text-rose-700">
                    {item.badge}
                  </span>
                )}
                <ChevronRight className="h-4 w-4 text-slate-400 group-hover:text-primary-600 transition-colors dark:text-slate-500" />
              </span>
            </Link>
          ))}
        </div>
      </div>

      {/* Performance summary */}
      {performance && (
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="h-4 w-4 text-primary-600" />
            <h2 className="text-base font-bold text-slate-900 dark:text-slate-100">Performance summary</h2>
          </div>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { label: "Total supervised",    value: String(performance.totalStudentsSupervised) },
              { label: "Completed",           value: String(performance.completedInternships) },
              { label: "Avg. student score",  value: performance.averageStudentScore !== null ? `${performance.averageStudentScore.toFixed(1)}%` : "—" },
              { label: "Plan approval rate",  value: performance.planApprovalRate !== null ? `${performance.planApprovalRate.toFixed(0)}%` : "—" },
            ].map((s) => (
              <div key={s.label} className="rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-3 dark:border-slate-700 dark:bg-slate-800/60">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{s.label}</p>
                <p className="mt-1 text-xl font-bold tabular-nums text-slate-900 dark:text-slate-100">{s.value}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
