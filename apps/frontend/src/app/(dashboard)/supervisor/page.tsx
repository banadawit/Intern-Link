"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import api from "@/lib/api/client";
import { useAuth } from "@/lib/hooks/useAuth";
import {
  ClipboardList, Inbox, Users, RefreshCw,
  ChevronRight, FileCheck, Clock, Send, UsersRound,
  FolderKanban, CalendarDays, MessageSquare, AlertCircle,
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
};

export default function SupervisorDashboardPage() {
  const { user } = useAuth();
  const [data, setData] = useState<MeResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
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
  };

  useEffect(() => { void load(); }, []);

  if (error) {
    return (
      <div className="flex items-center gap-2 rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800">
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

  const { supervisor, stats, recentPendingProposals = [], recentPendingPlans = [] } = data;

  if (!supervisor?.company) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
        Company profile not linked. Contact support.
      </div>
    );
  }

  const approvedProposalsCount = stats.approvedProposalsCount ?? 0;
  const reportsSubmittedCount = stats.reportsSubmittedCount ?? 0;

  const quickLinks = [
    { href: "/supervisor/proposals", label: "Proposals", desc: "Review incoming placement requests", icon: Inbox, badge: stats.pendingProposalsCount, color: "bg-violet-50 text-violet-600" },
    { href: "/supervisor/plans", label: "Weekly plans", desc: "Approve or reject student plans", icon: ClipboardList, badge: stats.pendingWeeklyPlansCount, color: "bg-amber-50 text-amber-600" },
    { href: "/supervisor/students", label: "Students", desc: "View all placed interns", icon: Users, badge: 0, color: "bg-emerald-50 text-emerald-600" },
    { href: "/supervisor/teams", label: "Teams", desc: "Manage intern groups", icon: UsersRound, badge: 0, color: "bg-blue-50 text-blue-600" },
    { href: "/supervisor/projects", label: "Projects", desc: "Assign and track projects", icon: FolderKanban, badge: 0, color: "bg-teal-50 text-teal-600" },
    { href: "/supervisor/reports", label: "Reports", desc: "Submit evaluations & generate PDFs", icon: FileCheck, badge: 0, color: "bg-rose-50 text-rose-600" },
    { href: "/supervisor/attendance/students", label: "Attendance", desc: "Student check-in heatmap", icon: CalendarDays, badge: 0, color: "bg-slate-100 text-slate-600" },
    { href: "/supervisor/chat", label: "Messages", desc: "Chat with placed students", icon: MessageSquare, badge: 0, color: "bg-primary-50 text-primary-600" },
  ];

  return (
    <div className="space-y-8 pb-8">
      {/* Hero */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-widest text-primary-600">Company portal</p>
          <h1 className="mt-1 text-2xl font-bold tracking-tight text-slate-900 md:text-3xl">
            Welcome back, {user?.fullName ?? supervisor.user.full_name}
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            {supervisor.company.name} · {supervisor.company.official_email}
          </p>
        </div>
        <button
          type="button"
          onClick={() => void load()}
          disabled={loading}
          className="inline-flex shrink-0 items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50 disabled:opacity-60"
        >
          <RefreshCw className={cn("h-4 w-4", loading && "animate-spin")} />
          Refresh
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {/* Pending proposals */}
        <Link href="/supervisor/proposals" className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:border-violet-300 hover:shadow-md">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Pending proposals</p>
              <p className={cn("mt-2 text-3xl font-bold", stats.pendingProposalsCount > 0 ? "text-violet-600" : "text-slate-900")}>
                {stats.pendingProposalsCount}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                {stats.pendingProposalsCount > 0 ? "Need your response" : "All reviewed"}
              </p>
            </div>
            <div className={cn("rounded-xl p-2.5 shrink-0", stats.pendingProposalsCount > 0 ? "bg-violet-50 text-violet-600" : "bg-slate-50 text-slate-400")}>
              <Inbox className="h-5 w-5" />
            </div>
          </div>
          {stats.pendingProposalsCount > 0 && (
            <div className="mt-3 flex items-center gap-1 text-xs font-semibold text-violet-600">
              Review now <ChevronRight className="h-3.5 w-3.5" />
            </div>
          )}
        </Link>

        {/* Pending weekly plans */}
        <Link href="/supervisor/plans" className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:border-amber-300 hover:shadow-md">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Pending plans</p>
              <p className={cn("mt-2 text-3xl font-bold", stats.pendingWeeklyPlansCount > 0 ? "text-amber-600" : "text-slate-900")}>
                {stats.pendingWeeklyPlansCount}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                {stats.pendingWeeklyPlansCount > 0 ? "Awaiting review" : "All up to date"}
              </p>
            </div>
            <div className={cn("rounded-xl p-2.5 shrink-0", stats.pendingWeeklyPlansCount > 0 ? "bg-amber-50 text-amber-600" : "bg-slate-50 text-slate-400")}>
              <ClipboardList className="h-5 w-5" />
            </div>
          </div>
          {stats.pendingWeeklyPlansCount > 0 && (
            <div className="mt-3 flex items-center gap-1 text-xs font-semibold text-amber-600">
              Review now <ChevronRight className="h-3.5 w-3.5" />
            </div>
          )}
        </Link>

        {/* Active interns */}
        <Link href="/supervisor/students" className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:border-emerald-300 hover:shadow-md">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Active interns</p>
              <p className="mt-2 text-3xl font-bold text-slate-900">{stats.placedStudentsCount}</p>
              <p className="mt-1 text-xs text-slate-500">Placed at your company</p>
            </div>
            <div className="rounded-xl bg-emerald-50 p-2.5 text-emerald-600 shrink-0">
              <Users className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-center gap-3 text-xs text-slate-500">
            <span className="flex items-center gap-1">
              <Send className="h-3 w-3 text-emerald-500" />
              {approvedProposalsCount} total approved
            </span>
          </div>
        </Link>

        {/* Reports */}
        <Link href="/supervisor/reports" className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition-all hover:border-rose-300 hover:shadow-md">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Reports submitted</p>
              <p className="mt-2 text-3xl font-bold text-slate-900">{reportsSubmittedCount}</p>
              <p className="mt-1 text-xs text-slate-500">Final evaluations sent</p>
            </div>
            <div className="rounded-xl bg-rose-50 p-2.5 text-rose-600 shrink-0">
              <FileCheck className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-center gap-1 text-xs font-semibold text-rose-600 group-hover:text-rose-700">
            Manage reports <ChevronRight className="h-3.5 w-3.5" />
          </div>
        </Link>      </div>

      {/* Action needed panels */}
      {(recentPendingProposals.length > 0 || recentPendingPlans.length > 0) && (
        <div className="grid gap-5 lg:grid-cols-2">
          {/* Pending proposals */}
          {recentPendingProposals.length > 0 && (
            <div className="rounded-2xl border border-violet-200 bg-violet-50/40 p-5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <div className="rounded-lg bg-violet-100 p-1.5 text-violet-600">
                    <Inbox className="h-4 w-4" />
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-900">Incoming proposals</h3>
                    <p className="text-xs text-slate-500">{stats.pendingProposalsCount} awaiting response</p>
                  </div>
                </div>
                <Link href="/supervisor/proposals" className="inline-flex items-center gap-1 rounded-lg bg-violet-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-violet-700 transition-colors">
                  View all <ChevronRight className="h-3.5 w-3.5" />
                </Link>
              </div>
              <div className="space-y-2">
                {recentPendingProposals.map((p) => (
                  <div key={p.id} className="flex items-center gap-3 rounded-xl border border-violet-100 bg-white px-4 py-2.5">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-bold text-violet-700">
                      {p.studentName.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold text-slate-900 truncate">{p.studentName}</p>
                      <p className="text-xs text-slate-500 truncate">{p.universityName}</p>
                    </div>
                    <span className="shrink-0 flex items-center gap-1 text-xs text-slate-400">
                      <Clock className="h-3 w-3" />
                      {formatDistanceToNow(new Date(p.submitted_at), { addSuffix: true })}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Pending weekly plans */}
          {recentPendingPlans.length > 0 && (
            <div className="rounded-2xl border border-amber-200 bg-amber-50/40 p-5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <div className="rounded-lg bg-amber-100 p-1.5 text-amber-600">
                    <ClipboardList className="h-4 w-4" />
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-900">Plans awaiting review</h3>
                    <p className="text-xs text-slate-500">{stats.pendingWeeklyPlansCount} pending</p>
                  </div>
                </div>
                <Link href="/supervisor/plans" className="inline-flex items-center gap-1 rounded-lg bg-amber-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-amber-700 transition-colors">
                  View all <ChevronRight className="h-3.5 w-3.5" />
                </Link>
              </div>
              <div className="space-y-2">
                {recentPendingPlans.map((p) => (
                  <div key={p.id} className="flex items-center gap-3 rounded-xl border border-amber-100 bg-white px-4 py-2.5">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-amber-100 text-xs font-bold text-amber-700">
                      {p.studentName.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold text-slate-900 truncate">{p.studentName}</p>
                      <p className="text-xs text-slate-500">Week {p.weekNumber}</p>
                    </div>
                    <span className="shrink-0 flex items-center gap-1 text-xs text-slate-400">
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

      {/* Quick links grid */}
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
        <h2 className="text-base font-bold text-slate-900">Quick access</h2>
        <p className="mt-0.5 text-sm text-slate-500">Jump to any section of your workspace.</p>
        <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          {quickLinks.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-3 transition-colors hover:border-primary-200 hover:bg-primary-50/40 group"
            >
              <span className="flex min-w-0 items-center gap-3">
                <span className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-xl", item.color)}>
                  <item.icon className="h-4 w-4" />
                </span>
                <span className="min-w-0">
                  <span className="block text-sm font-semibold text-slate-900">{item.label}</span>
                  <span className="block truncate text-xs text-slate-500">{item.desc}</span>
                </span>
              </span>
              <span className="flex shrink-0 items-center gap-1.5">
                {item.badge > 0 && (
                  <span className="rounded-full bg-rose-100 px-1.5 py-0.5 text-[10px] font-bold text-rose-700">
                    {item.badge}
                  </span>
                )}
                <ChevronRight className="h-4 w-4 text-slate-400 group-hover:text-primary-600 transition-colors" />
              </span>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
