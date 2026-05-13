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
import { useTranslations } from "next-intl";

export default function CoordinatorDashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<CoordinatorDashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const t = useTranslations("CoordinatorPortal.dashboard");

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get<{ success: boolean; data: CoordinatorDashboardStats }>("/coordinator-portal/dashboard-stats");
      setStats(data.data);
    } catch {
      setError(t("couldNotLoad"));
      setStats(null);
    } finally {
      setLoading(false);
    }
  }, [t]);

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
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">{error}</div>
    );
  }

  const shortcuts = [
    { href: "/coordinator/hods", label: t("shortcuts.hodManagement"), desc: t("shortcuts.hodManagementDesc") },
    { href: "/coordinator/approvals", label: t("shortcuts.approvalsHistory"), desc: t("shortcuts.approvalsHistoryDesc") },
  ];

  return (
    <div className="space-y-8 pb-8">
      <CoordinatorPageHero
        badge={t("badge")}
        title={t("welcomeBack", { name: user?.fullName ?? t("coordinatorFallback") })}
        description={t("description")}
        action={
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white disabled:opacity-60 sm:w-auto dark:bg-slate-900/90 dark:text-slate-100 dark:hover:bg-slate-900"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} aria-hidden />
            {t("refresh")}
          </button>
        }
      />

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">{error}</div>
      )}

      {loading && !stats ? (
        <div className="flex min-h-[30vh] items-center justify-center text-slate-500 dark:text-slate-400">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : stats ? (
        <>
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {[
              {
                label: t("statHodsPending"),
                value: String(stats.hods.pending),
                sub: t("statHodsApprovedRejected", { approved: stats.hods.approved, rejected: stats.hods.rejected }),
                icon: Users,
              },
              {
                label: t("statStudentsUniversity"),
                value: String(stats.students.total),
                sub: t("statStudentsAwaitingHod", { count: stats.students.hodApprovalPending }),
                icon: Users,
              },
              {
                label: t("statPendingProposals"),
                value: String(stats.proposalsPending),
                sub: t("statPendingProposalsSub"),
                icon: Send,
              },
              {
                label: t("statActivePlacements"),
                value: String(stats.activeAssignments),
                sub: t("statActivePlacementsSub", { count: stats.reportsCount }),
                icon: Briefcase,
              },
            ].map((c) => (
              <div
                key={c.label}
                className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{c.label}</p>
                    <p className="mt-2 text-lg font-bold text-slate-900 dark:text-slate-100">{c.value}</p>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{c.sub}</p>
                  </div>
                  <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600">
                    <c.icon className="h-5 w-5" aria-hidden />
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
              <div className="mb-4 flex items-center justify-between gap-2">
                <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">{t("recentNotifications")}</h2>
                <Bell className="h-5 w-5 text-slate-400 dark:text-slate-500" aria-hidden />
              </div>
              {stats.recentNotifications.length === 0 ? (
                <p className="text-sm text-slate-500 dark:text-slate-400">{t("noNotifications")}</p>
              ) : (
                <ul className="space-y-2">
                  {stats.recentNotifications.map((n) => (
                    <li
                      key={n.id}
                      className={`flex gap-3 rounded-xl border px-3 py-2 text-sm ${
                        n.is_read ? "border-slate-100 bg-slate-50/50 dark:border-slate-700 dark:bg-slate-800/60" : "border-primary-100 bg-primary-50/30 dark:border-primary-800 dark:bg-primary-900/20"
                      }`}
                    >
                      <p className="min-w-0 flex-1 text-slate-700 dark:text-slate-300">{n.message}</p>
                      {!n.is_read && (
                        <button
                          type="button"
                          onClick={() => void markRead(n.id)}
                          className="shrink-0 text-xs font-medium text-primary-600 hover:underline"
                        >
                          {t("markRead")}
                        </button>
                      )}
                    </li>
                  ))}
                </ul>
              )}
            </section>

            <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
              <h2 className="mb-4 text-lg font-bold text-slate-900 dark:text-slate-100">{t("quickLinks")}</h2>
              <ul className="space-y-2">
                {shortcuts.map((s) => (
                  <li key={s.href}>
                    <Link
                      href={s.href}
                      className="flex items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50/50 px-4 py-3 text-left transition-colors hover:border-primary-200 hover:bg-primary-50/40 dark:border-slate-700 dark:bg-slate-800/60 dark:hover:bg-primary-900/20"
                    >
                      <span>
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
