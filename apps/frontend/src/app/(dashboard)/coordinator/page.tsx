"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/hooks/useAuth";
import {
  Loader2, RefreshCw, Users, Briefcase, ChevronRight,
  Bell, CheckCircle2, MessageCircle,
} from "lucide-react";
import api from "@/lib/api/client";
import CoordinatorPageHero from "./CoordinatorPageHero";
import type { CoordinatorDashboardStats } from "@/components/coordinator/types";

const shortcuts = [
  { href: "/coordinator/hods",        label: "HOD management",   desc: "Approve and manage department heads", icon: Users },
  { href: "/coordinator/approvals",   label: "Approvals history", desc: "View approved and rejected HODs",    icon: CheckCircle2 },
  { href: "/coordinator/chat",        label: "Chat",              desc: "Direct messages",                    icon: MessageCircle },
  { href: "/coordinator/common-feed", label: "Common Feed",       desc: "Announcements and updates",          icon: MessageCircle },
];

const STATUS_LABELS: Record<string, string> = {
  PENDING:   "Pending placement",
  PLACED:    "Placed",
  COMPLETED: "Completed",
};
const STATUS_COLORS: Record<string, string> = {
  PENDING:   "bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300",
  PLACED:    "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300",
  COMPLETED: "bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300",
};

export default function CoordinatorDashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<CoordinatorDashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [markingAll, setMarkingAll] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get<{ success: boolean; data: CoordinatorDashboardStats }>("/coordinator-portal/dashboard-stats");
      setStats(data.data);
    } catch {
      setError("Could not load dashboard.");
      setStats(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const markRead = async (id: number) => {
    try {
      await api.patch(`/coordinator-portal/notifications/${id}/read`);
      void load();
    } catch { /* ignore */ }
  };

  const markAllRead = async () => {
    if (!stats) return;
    const unread = stats.recentNotifications.filter((n) => !n.is_read);
    if (unread.length === 0) return;
    setMarkingAll(true);
    try {
      await Promise.all(unread.map((n) => api.patch(`/coordinator-portal/notifications/${n.id}/read`)));
      void load();
    } catch { /* ignore */ } finally {
      setMarkingAll(false);
    }
  };

  if (error && !stats && !loading) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">{error}</div>
    );
  }

  const hasPendingHods = (stats?.hods.pending ?? 0) > 0;
  const unreadCount = stats?.recentNotifications.filter((n) => !n.is_read).length ?? 0;

  return (
    <div className="space-y-8 pb-8">
      <CoordinatorPageHero
        badge="University coordinator"
        title={`Welcome back, ${user?.fullName ?? "Coordinator"}`}
        description="Oversee HOD access, placements, and company activity for your institution."
        action={
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white disabled:opacity-60 sm:w-auto dark:bg-slate-900/90 dark:text-slate-100 dark:hover:bg-slate-900"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} aria-hidden />
            Refresh
          </button>
        }
      />

      {/* University name subtitle */}
      {stats?.universityName && (
        <p className="text-sm text-slate-500 dark:text-slate-400 -mt-4">
          Managing: <span className="font-semibold text-slate-700 dark:text-slate-300">{stats.universityName}</span>
        </p>
      )}

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">{error}</div>
      )}

      {loading && !stats ? (
        <div className="flex min-h-[30vh] items-center justify-center text-slate-500 dark:text-slate-400">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : stats ? (
        <>
          {/* Stat cards */}
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {/* HODs pending — clickable when there are pending */}
            {hasPendingHods ? (
              <Link
                href="/dashboard/coordinator/hods"
                className="rounded-2xl border border-amber-200 bg-amber-50 p-5 shadow-sm transition-all hover:shadow-md dark:border-amber-800/50 dark:bg-amber-950/20"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400">HODs pending</p>
                    <p className="mt-2 text-3xl font-bold text-amber-700 dark:text-amber-300">{stats.hods.pending}</p>
                    <p className="mt-1 text-xs text-amber-600/80 dark:text-amber-400/80">{stats.hods.approved} approved, {stats.hods.rejected} rejected</p>
                    <p className="mt-2 text-xs font-semibold text-amber-700 dark:text-amber-300">Review now →</p>
                  </div>
                  <div className="rounded-xl bg-amber-100 p-2.5 text-amber-600 dark:bg-amber-900/40 dark:text-amber-400">
                    <Users className="h-5 w-5" aria-hidden />
                  </div>
                </div>
              </Link>
            ) : (
              <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">HODs pending</p>
                    <p className="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100">{stats.hods.pending}</p>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{stats.hods.approved} approved, {stats.hods.rejected} rejected</p>
                  </div>
                  <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600">
                    <Users className="h-5 w-5" aria-hidden />
                  </div>
                </div>
              </div>
            )}

            {[
              { label: "Students (university)", value: stats.students.total, sub: `${stats.students.hodApprovalPending} awaiting HOD approval`, icon: Users },
              { label: "Pending proposals",     value: stats.proposalsPending, sub: "Internship proposals awaiting response", icon: Briefcase },
              { label: "Active placements",     value: stats.activeAssignments, sub: `${stats.reportsCount} final reports on file`, icon: Briefcase },
            ].map((c) => (
              <div key={c.label} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{c.label}</p>
                    <p className="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100">{c.value}</p>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{c.sub}</p>
                  </div>
                  <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600">
                    <c.icon className="h-5 w-5" aria-hidden />
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Student internship status breakdown */}
          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
            <h2 className="mb-4 text-base font-bold text-slate-900 dark:text-slate-100">Student internship status</h2>
            <div className="flex flex-wrap gap-3">
              {(["PENDING", "PLACED", "COMPLETED"] as const).map((key) => {
                const count = stats.students.byInternshipStatus[key] ?? 0;
                return (
                  <div key={key} className={`flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold ${STATUS_COLORS[key]}`}>
                    <span>{STATUS_LABELS[key]}</span>
                    <span className="rounded-full bg-white/50 px-2 py-0.5 text-xs font-bold tabular-nums">{count}</span>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            {/* Notifications */}
            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
              <div className="mb-4 flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">Recent notifications</h2>
                  <Bell className="h-5 w-5 text-slate-400 dark:text-slate-500" aria-hidden />
                </div>
                {unreadCount > 0 && (
                  <button
                    type="button"
                    onClick={() => void markAllRead()}
                    disabled={markingAll}
                    className="text-xs font-semibold text-primary-600 hover:underline disabled:opacity-50"
                  >
                    {markingAll ? "Marking…" : "Mark all as read"}
                  </button>
                )}
              </div>
              {stats.recentNotifications.length === 0 ? (
                <p className="text-sm text-slate-500 dark:text-slate-400">No notifications yet.</p>
              ) : (
                <ul className="space-y-2">
                  {stats.recentNotifications.map((n) => (
                    <li
                      key={n.id}
                      className={`flex gap-3 rounded-xl border px-3 py-2 text-sm ${
                        n.is_read
                          ? "border-slate-100 bg-slate-50/50 dark:border-slate-700 dark:bg-slate-800/60"
                          : "border-primary-100 bg-primary-50/30 dark:border-primary-800 dark:bg-primary-900/20"
                      }`}
                    >
                      <p className="min-w-0 flex-1 text-slate-700 dark:text-slate-300">{n.message}</p>
                      {!n.is_read && (
                        <button
                          type="button"
                          onClick={() => void markRead(n.id)}
                          className="shrink-0 text-xs font-medium text-primary-600 hover:underline"
                        >
                          Mark read
                        </button>
                      )}
                    </li>
                  ))}
                </ul>
              )}
            </section>

            {/* Quick links */}
            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
              <h2 className="mb-4 text-lg font-bold text-slate-900 dark:text-slate-100">Quick links</h2>
              <ul className="space-y-2">
                {shortcuts.map((s) => (
                  <li key={s.href}>
                    <Link
                      href={s.href}
                      className="flex items-center gap-3 rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-3 transition-colors hover:border-primary-200 hover:bg-primary-50/40 dark:border-slate-700 dark:bg-slate-800/60 dark:hover:bg-primary-900/20"
                    >
                      <div className="rounded-lg bg-primary-50 p-2 text-primary-600 dark:bg-primary-900/30 dark:text-primary-400 shrink-0">
                        <s.icon className="h-4 w-4" aria-hidden />
                      </div>
                      <span className="min-w-0 flex-1">
                        <span className="block font-semibold text-slate-900 dark:text-slate-100">{s.label}</span>
                        <span className="block text-xs text-slate-500 dark:text-slate-400">{s.desc}</span>
                      </span>
                      <ChevronRight className="h-5 w-5 shrink-0 text-slate-400 dark:text-slate-500" aria-hidden />
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          </div>
        </>
      ) : null}
    </div>
  );
}
