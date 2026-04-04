"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useAuth } from "@/lib/hooks/useAuth";
import {
  Loader2,
  RefreshCw,
  Users,
  Briefcase,
  Send,
  ChevronRight,
  Bell,
} from "lucide-react";
import api from "@/lib/api/client";
import CoordinatorPageHero from "./CoordinatorPageHero";
import type { CoordinatorDashboardStats } from "@/components/coordinator/types";

export default function CoordinatorDashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<CoordinatorDashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get<CoordinatorDashboardStats>("/coordinator-portal/dashboard-stats");
      setStats(data);
    } catch {
      setError("Could not load dashboard.");
      setStats(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const markRead = async (id: number) => {
    try {
      await api.patch(`/coordinator-portal/notifications/${id}/read`);
      void load();
    } catch {
      /* ignore */
    }
  };

  if (error && !stats && !loading) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800">{error}</div>
    );
  }

  const shortcuts = [
    { href: "/coordinator/hods", label: "HOD management", desc: "Approve HOD accounts and view all heads" },
    { href: "/coordinator/companies", label: "Companies", desc: "Monitor platform company verification" },
    { href: "/coordinator/placements", label: "Placements", desc: "Proposals and active assignments" },
    { href: "/coordinator/reports", label: "Reports", desc: "Final reports from your students" },
  ];

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
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white disabled:opacity-60 sm:w-auto"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} aria-hidden />
            Refresh
          </button>
        }
      />

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{error}</div>
      )}

      {loading && !stats ? (
        <div className="flex min-h-[30vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : stats ? (
        <>
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {[
              {
                label: "HODs pending",
                value: String(stats.hods.pending),
                sub: `${stats.hods.approved} approved, ${stats.hods.rejected} rejected`,
                icon: Users,
              },
              {
                label: "Students (university)",
                value: String(stats.students.total),
                sub: `${stats.students.hodApprovalPending} awaiting HOD approval`,
                icon: Users,
              },
              {
                label: "Pending proposals",
                value: String(stats.proposalsPending),
                sub: "Internship proposals awaiting response",
                icon: Send,
              },
              {
                label: "Active placements",
                value: String(stats.activeAssignments),
                sub: `${stats.reportsCount} final reports on file`,
                icon: Briefcase,
              },
            ].map((c) => (
              <div
                key={c.label}
                className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">{c.label}</p>
                    <p className="mt-2 text-lg font-bold text-slate-900">{c.value}</p>
                    <p className="mt-1 text-xs text-slate-500">{c.sub}</p>
                  </div>
                  <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600">
                    <c.icon className="h-5 w-5" aria-hidden />
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
              <div className="mb-4 flex items-center justify-between gap-2">
                <h2 className="text-lg font-bold text-slate-900">Recent notifications</h2>
                <Bell className="h-5 w-5 text-slate-400" aria-hidden />
              </div>
              {stats.recentNotifications.length === 0 ? (
                <p className="text-sm text-slate-500">No notifications yet.</p>
              ) : (
                <ul className="space-y-2">
                  {stats.recentNotifications.map((n) => (
                    <li
                      key={n.id}
                      className={`flex gap-3 rounded-xl border px-3 py-2 text-sm ${
                        n.is_read ? "border-slate-100 bg-slate-50/50" : "border-primary-100 bg-primary-50/30"
                      }`}
                    >
                      <p className="min-w-0 flex-1 text-slate-700">{n.message}</p>
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

            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
              <h2 className="mb-4 text-lg font-bold text-slate-900">Quick links</h2>
              <ul className="space-y-2">
                {shortcuts.map((s) => (
                  <li key={s.href}>
                    <Link
                      href={s.href}
                      className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-3 text-left transition-colors hover:border-primary-200 hover:bg-primary-50/40"
                    >
                      <span>
                        <span className="block font-semibold text-slate-900">{s.label}</span>
                        <span className="block text-xs text-slate-500">{s.desc}</span>
                      </span>
                      <ChevronRight className="h-5 w-5 shrink-0 text-slate-400" aria-hidden />
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
