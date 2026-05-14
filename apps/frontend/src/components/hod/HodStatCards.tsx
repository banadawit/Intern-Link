"use client";

import Link from "next/link";
import {
  Users, FileCheck, Building2, FileText, Clock, CheckCircle2,
  XCircle, Send, ChevronRight, AlertTriangle, TrendingUp, BarChart2,
} from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from "recharts";
import { cn } from "@/lib/utils";
import type { HodStats } from "./types";
import { useTranslations } from "next-intl";

type Props = { stats: HodStats | null };

export default function HodStatCards({ stats }: Props) {
  const t = useTranslations("HodPortal.stats");
  if (!stats) return null;

  const proposals = stats.proposals ?? { pending: 0, approved: 0, rejected: 0 };
  const placementRate = stats.placementRate ?? (
    stats.approvedStudents > 0
      ? Math.round((stats.placedStudents / stats.approvedStudents) * 100)
      : 0
  );
  const approvalRate = stats.totalStudents > 0
    ? Math.round(((stats.approvedStudents ?? 0) / stats.totalStudents) * 100)
    : 0;
  const approvedNotPlaced = stats.approvedNotPlaced ?? 0;
  const approvedStudents = stats.approvedStudents ?? 0;
  const rejectedStudents = stats.rejectedStudents ?? 0;
  const recentPending = stats.recentPendingStudents ?? [];
  const alerts = stats.alerts ?? [];
  const trend = stats.weeklyPlacementTrend ?? [];

  return (
    <div className="space-y-6">
      {/* Context line */}
      <p className="text-sm text-slate-500 dark:text-slate-400">
        <span className="font-semibold text-slate-700 dark:text-slate-200">{stats.university?.name}</span>
        {stats.department && (
          <> &mdash; <span className="font-medium">{stats.department}</span> Department</>
        )}
      </p>

      {/* Primary stat cards */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {/* Total students */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{t("departmentStudents")}</p>
              <p className="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100">{stats.totalStudents}</p>
              <div className="mt-2 flex items-center gap-2 flex-wrap">
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-700">
                  <CheckCircle2 className="h-3 w-3" />{approvedStudents} {t("approved")}
                </span>
                {rejectedStudents > 0 && (
                  <span className="inline-flex items-center gap-1 rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700">
                    <XCircle className="h-3 w-3" />{rejectedStudents} {t("rejected")}
                  </span>
                )}
              </div>
            </div>
            <div className="rounded-xl bg-primary-50 p-2.5 text-primary-600 shrink-0">
              <Users className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4">
            <div className="flex items-center justify-between text-xs text-slate-500 mb-1 dark:text-slate-400">
              <span>{t("approvalRate")}</span>
              <span className="font-semibold text-slate-700 dark:text-slate-300">{approvalRate}%</span>
            </div>
            <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-800">
              <div className="h-full rounded-full bg-emerald-500 transition-all" style={{ width: `${approvalRate}%` }} />
            </div>
          </div>
        </div>

        {/* Pending approvals */}
        <Link href="/hod/students?status=pending" className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm hover:border-amber-300 hover:shadow-md transition-all dark:border-slate-700 dark:bg-slate-900">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{t("pendingApprovals")}</p>
              <p className={cn("mt-2 text-3xl font-bold", stats.pendingApprovals > 0 ? "text-amber-600" : "text-slate-900 dark:text-slate-100")}>
                {stats.pendingApprovals}
              </p>
              <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                {stats.pendingApprovals > 0 ? t("awaitingReview") : t("allCaughtUp")}
              </p>
            </div>
            <div className={cn("rounded-xl p-2.5 shrink-0", stats.pendingApprovals > 0 ? "bg-amber-50 text-amber-600 dark:bg-amber-900/30 dark:text-amber-300" : "bg-slate-50 text-slate-400 dark:bg-slate-800 dark:text-slate-500")}>
              <Clock className="h-5 w-5" />
            </div>
          </div>
          {stats.pendingApprovals > 0 && (
            <div className="mt-4 flex items-center gap-1 text-xs font-semibold text-amber-600 group-hover:text-amber-700">
              {t("reviewNow")} <ChevronRight className="h-3.5 w-3.5" />
            </div>
          )}
        </Link>

        {/* Placements */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{t("placements")}</p>
              <p className="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100">{stats.placedStudents}</p>
              <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                {approvedNotPlaced > 0
                  ? t("approvedNotPlaced", { count: approvedNotPlaced })
                  : t("allPlaced")}
              </p>
            </div>
            <div className="rounded-xl bg-emerald-50 p-2.5 text-emerald-600 shrink-0">
              <Building2 className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4">
            <div className="flex items-center justify-between text-xs text-slate-500 mb-1 dark:text-slate-400">
              <span>{t("placementRate")}</span>
              <span className="font-semibold text-slate-700 dark:text-slate-300">{placementRate}%</span>
            </div>
            <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-800">
              <div className="h-full rounded-full bg-emerald-500 transition-all" style={{ width: `${placementRate}%` }} />
            </div>
          </div>
        </div>

        {/* Proposals & Reports */}
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{t("proposals")}</p>
              <p className="mt-2 text-3xl font-bold text-slate-900 dark:text-slate-100">{proposals.pending + proposals.approved + proposals.rejected}</p>
            </div>
            <div className="rounded-xl bg-blue-50 p-2.5 text-blue-600 shrink-0">
              <Send className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 space-y-1.5">
            <div className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-1.5 text-amber-600"><span className="h-2 w-2 rounded-full bg-amber-400" />{t("pending")}</span>
              <span className="font-semibold text-slate-700 dark:text-slate-300">{proposals.pending}</span>
            </div>
            <div className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-1.5 text-emerald-600"><span className="h-2 w-2 rounded-full bg-emerald-400" />{t("approved")}</span>
              <span className="font-semibold text-slate-700 dark:text-slate-300">{proposals.approved}</span>
            </div>
            <div className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-1.5 text-slate-500 dark:text-slate-400"><FileText className="h-3 w-3" />{t("finalReports")}</span>
              <span className="font-semibold text-slate-700 dark:text-slate-300">{stats.reports}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Secondary rate cards */}
      <div className="grid gap-4 sm:grid-cols-3">
        {[
          {
            label: "Placement Rate",
            value: `${stats.placementRate ?? placementRate}%`,
            icon: Building2,
            color: "text-emerald-600",
            bg: "bg-emerald-50 dark:bg-emerald-900/20",
          },
          {
            label: "Reports Completion",
            value: `${stats.reportsCompletionRate ?? 0}%`,
            icon: FileCheck,
            color: "text-blue-600",
            bg: "bg-blue-50 dark:bg-blue-900/20",
          },
          {
            label: "Proposal Success Rate",
            value: `${stats.approvalSuccessRate ?? 0}%`,
            icon: TrendingUp,
            color: "text-violet-600",
            bg: "bg-violet-50 dark:bg-violet-900/20",
          },
        ].map((card) => (
          <div key={card.label} className="flex items-center gap-4 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-900">
            <div className={cn("flex h-10 w-10 shrink-0 items-center justify-center rounded-xl", card.bg, card.color)}>
              <card.icon className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{card.label}</p>
              <p className="text-2xl font-bold text-slate-900 dark:text-slate-100">{card.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Weekly placement trend chart */}
      {trend.length > 0 && (
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
          <div className="flex items-center gap-2 mb-4">
            <BarChart2 className="h-4 w-4 text-primary-600" />
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Weekly placement trend</h3>
            <span className="text-xs text-slate-400 dark:text-slate-500">(last 8 weeks)</span>
          </div>
          <ResponsiveContainer width="100%" height={140}>
            <BarChart data={trend} barSize={20} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
              <XAxis dataKey="weekLabel" tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
              <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 12 }}
                cursor={{ fill: "#f1f5f9" }}
                formatter={(v: any) => [v, "Placements"]}
              />
              <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                {trend.map((_, i) => (
                  <Cell key={i} fill={i === trend.length - 1 ? "#6366f1" : "#a5b4fc"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      {/* Alerts panel */}
      {alerts.length > 0 && (
        <div className="rounded-2xl border border-orange-200 bg-orange-50/50 p-5 shadow-sm dark:border-orange-900/50 dark:bg-orange-900/10">
          <h3 className="mb-3 text-sm font-bold text-slate-900 dark:text-slate-100 flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 text-orange-500" />
            Attention needed
            <span className="ml-1 rounded-full bg-orange-100 px-2 py-0.5 text-xs font-semibold text-orange-700 dark:bg-orange-900/40 dark:text-orange-300">
              {alerts.length}
            </span>
          </h3>
          <div className="space-y-2">
            {alerts.map((alert, i) => {
              const Icon =
                alert.type === "UNPLACED" ? Clock :
                alert.type === "NEEDS_REASSIGNMENT" ? XCircle :
                AlertTriangle;
              const iconColor =
                alert.type === "UNPLACED" ? "text-amber-500" :
                alert.type === "NEEDS_REASSIGNMENT" ? "text-red-500" :
                "text-orange-500";
              return (
                <div key={i} className="flex items-center gap-3 rounded-xl border border-orange-100 bg-white px-4 py-2.5 dark:border-orange-900/30 dark:bg-slate-900">
                  <Icon className={cn("h-4 w-4 shrink-0", iconColor)} />
                  <p className="flex-1 text-xs text-slate-700 dark:text-slate-300">{alert.message}</p>
                  <Link
                    href={`/hod/students`}
                    className="shrink-0 text-xs font-semibold text-primary-600 hover:text-primary-700 hover:underline"
                  >
                    View student
                  </Link>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Recent pending students */}
      {recentPending.length > 0 && (
        <div className="rounded-2xl border border-amber-200 bg-amber-50/50 p-5 shadow-sm dark:border-amber-900/50 dark:bg-amber-900/20">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="rounded-lg bg-amber-100 p-1.5 text-amber-600">
                <Clock className="h-4 w-4" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">{t("studentsAwaitingApproval")}</h3>
                <p className="text-xs text-slate-500 dark:text-slate-400">{t("needsReview", { count: stats.pendingApprovals })}</p>
              </div>
            </div>
            <Link
              href="/hod/students?status=pending"
              className="inline-flex items-center gap-1 rounded-lg bg-amber-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-amber-700 transition-colors"
            >
              {t("reviewAll")} <ChevronRight className="h-3.5 w-3.5" />
            </Link>
          </div>
          <div className="space-y-2">
            {recentPending.map((s) => (
              <div key={s.id} className="flex items-center gap-3 rounded-xl border border-amber-100 bg-white px-4 py-2.5 dark:border-amber-900/50 dark:bg-slate-900">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-amber-100 text-xs font-bold text-amber-700">
                  {s.full_name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-slate-900 truncate dark:text-slate-100">{s.full_name}</p>
                  <p className="text-xs text-slate-500 truncate dark:text-slate-400">{s.email}</p>
                </div>
                <Link
                  href="/hod/students?status=pending"
                  className="shrink-0 rounded-lg border border-amber-200 bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700 hover:bg-amber-100 transition-colors"
                >
                  {t("reviewNow")}
                </Link>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
