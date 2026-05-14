"use client";

import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import {
  Users, GraduationCap, Briefcase, Building2, CheckCircle2,
  FileText, Star, Activity, AlertTriangle, Clock, ArrowRight,
  RefreshCw, Wifi, WifiOff, ChevronLeft, ChevronRight,
} from "lucide-react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, AreaChart, Area, Legend,
} from "recharts";
import api from "@/lib/api/client";
import AdminPageHero from "./AdminPageHero";
import { cn } from "@/lib/utils";
import { useTranslations } from "next-intl";

// ─── Types ────────────────────────────────────────────────────────────────────

export type AdminDashboardStats = {
  pendingUniversities: number;
  pendingCompanies: number;
  approvedUniversities: number;
  approvedCompanies: number;
  totalStudents: number;
  activeInternships: number;
  pendingCoordinators?: number;
  pendingSupervisors?: number;
};

interface AnalyticsData {
  userGrowth: { label: string; students: number; coordinators: number; supervisors: number; hods: number; total: number }[];
  placementStats: { total: number; placed: number; completed: number; pending: number };
  placementTrend: { label: string; count: number }[];
  proposalStats: { total: number; approved: number; rejected: number; pending: number };
  orgStats: { universities: { total: number; approved: number }; companies: { total: number; approved: number } };
  weeklyPlanTrend: { label: string; submitted: number; approved: number }[];
  totalUsers: number;
  totalEvaluations: number;
  totalReports: number;
  newUsersThisMonth: number;
  pendingApprovals: { universities: number; companies: number; coordinators: number; supervisors: number; total: number };
  evalStats: { count: number; avgTechnical: number; avgSoftSkill: number };
  recentActivity: { id: number; action: string; details: string | null; adminName: string; timestamp: string }[];
  totalActivity: number;
  activityPage: number;
  activityLimit: number;
  generatedAt: string;
}

const COLORS = {
  blue: "#3b82f6", teal: "#0d9488", emerald: "#10b981",
  violet: "#8b5cf6", amber: "#f59e0b", rose: "#f43f5e",
  slate: "#94a3b8", indigo: "#6366f1",
};
const PIE_COLORS = [COLORS.emerald, COLORS.blue, COLORS.slate];
const PROPOSAL_COLORS = [COLORS.emerald, COLORS.rose, COLORS.amber];
const REFRESH_INTERVAL = 30_000;

// ─── Sub-components ───────────────────────────────────────────────────────────

function KpiCard({ label, value, sub, icon: Icon, color, trend }: {
  label: string; value: string | number; sub?: string;
  icon: React.ComponentType<{ className?: string }>; color: string;
  trend?: { value: number; label: string };
}) {
  return (
    <div className="flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition-shadow hover:shadow-md dark:border-slate-700 dark:bg-slate-900">
      <div className="flex items-start justify-between">
        <div className={cn("rounded-xl p-2.5", color)}><Icon className="h-5 w-5" /></div>
        {trend && (
          <span className={cn("rounded-full px-2 py-0.5 text-xs font-semibold",
            trend.value >= 0
              ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"
              : "bg-rose-50 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400"
          )}>
            {trend.value >= 0 ? "+" : ""}{trend.value} {trend.label}
          </span>
        )}
      </div>
      <div>
        <p className="text-2xl font-bold text-slate-900 dark:text-slate-100">{value}</p>
        <p className="text-sm font-medium text-slate-600 dark:text-slate-400">{label}</p>
        {sub && <p className="mt-0.5 text-xs text-slate-400 dark:text-slate-500">{sub}</p>}
      </div>
    </div>
  );
}

function SectionCard({ title, subtitle, children }: { title: string; subtitle?: string; children: React.ReactNode }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-900">
      <h2 className="text-base font-bold text-slate-900 dark:text-slate-100">{title}</h2>
      {subtitle && <p className="mb-4 mt-0.5 text-xs text-slate-400">{subtitle}</p>}
      {!subtitle && <div className="mb-4" />}
      {children}
    </div>
  );
}

function ActionBadge({ action }: { action: string }) {
  const lower = action.toLowerCase();
  const cls = lower.includes("approve")
    ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"
    : lower.includes("reject")
    ? "bg-rose-50 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400"
    : lower.includes("suspend")
    ? "bg-amber-50 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
    : "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400";
  return <span className={cn("rounded-full px-2 py-0.5 text-xs font-medium", cls)}>{action.replace(/_/g, " ")}</span>;
}

// ─── Main Component ───────────────────────────────────────────────────────────

type DashboardProps = {
  pendingVerificationCount: number;
  stats: AdminDashboardStats | null;
  statsLoading?: boolean;
};

export default function Dashboard({ pendingVerificationCount, stats, statsLoading }: DashboardProps) {
  const t = useTranslations("AdminPortal.dashboard");
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [online, setOnline] = useState(true);
  const [activityPage, setActivityPage] = useState(1);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  // Keep a ref so `load` can always read the latest page without being a dep
  const activityPageRef = useRef(activityPage);
  const loadingRef = useRef(false);

  const ACTIVITY_LIMIT = 5;

  const quickLinks = useMemo(
    () => [
      { href: "/admin?view=approvals", label: t("quickReviewPending"), icon: Clock, accent: "bg-amber-50 text-amber-700 ring-amber-100" },
      { href: "/admin?view=organizations", label: t("quickOrganizations"), icon: Building2, accent: "bg-blue-50 text-blue-700 ring-blue-100" },
      { href: "/admin?view=audit-log", label: t("quickAuditLog"), icon: FileText, accent: "bg-slate-100 text-slate-700 ring-slate-200" },
      { href: "/admin?view=settings", label: t("quickSettings"), icon: CheckCircle2, accent: "bg-teal-50 text-teal-700 ring-teal-100" },
    ],
    [t] // eslint-disable-line react-hooks/exhaustive-deps
  );

  // Stable load function — never changes reference, reads page from ref
  const load = useCallback(async (silent = false, page?: number) => {
    // Prevent concurrent requests
    if (loadingRef.current) return;
    const targetPage = page ?? activityPageRef.current;
    loadingRef.current = true;
    if (!silent) setLoading(true);
    else setRefreshing(true);
    setError(null);
    try {
      const { data: res } = await api.get<AnalyticsData>(
        `/admin/analytics?activityPage=${targetPage}&activityLimit=${ACTIVITY_LIMIT}`
      );
      setData(res);
      setLastUpdated(new Date());
      setOnline(true);
    } catch {
      setError(t("failedAnalytics"));
      setOnline(false);
    } finally {
      loadingRef.current = false;
      setLoading(false);
      setRefreshing(false);
    }
  }, [t]); // no activityPage dep — uses ref instead

  // Initial load — runs once on mount
  useEffect(() => {
    void load();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Auto-refresh interval — stable, never recreated
  useEffect(() => {
    intervalRef.current = setInterval(() => void load(true), REFRESH_INTERVAL);
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleActivityPageChange = (page: number) => {
    activityPageRef.current = page;
    setActivityPage(page);
    void load(false, page);
  };

  // Derived values
  const placementRate = data && data.placementStats.total > 0
    ? Math.round(((data.placementStats.placed + data.placementStats.completed) / data.placementStats.total) * 100)
    : 0;
  const proposalApprovalRate = data && data.proposalStats.total > 0
    ? Math.round((data.proposalStats.approved / data.proposalStats.total) * 100)
    : 0;
  const internshipPieData = useMemo(() => {
    if (!data) return [];
    return [
      { name: t("chartPlaced"), value: data.placementStats.placed },
      { name: t("chartCompleted"), value: data.placementStats.completed },
      { name: t("chartPending"), value: data.placementStats.pending },
    ];
  }, [data]); // eslint-disable-line react-hooks/exhaustive-deps

  const proposalPieData = useMemo(() => {
    if (!data) return [];
    return [
      { name: t("chartApproved"), value: data.proposalStats.approved },
      { name: t("chartRejected"), value: data.proposalStats.rejected },
      { name: t("chartPending"), value: data.proposalStats.pending },
    ];
  }, [data]); // eslint-disable-line react-hooks/exhaustive-deps

  const pendingBreakdown = useMemo(() => {
    if (!data?.pendingApprovals) return "";
    const pa = data.pendingApprovals;
    const parts: string[] = [];
    if (pa.universities > 0) parts.push(t("universitiesCount", { count: pa.universities }));
    if (pa.companies > 0) parts.push(t("companiesCount", { count: pa.companies }));
    if (pa.coordinators > 0) parts.push(t("coordinatorsCount", { count: pa.coordinators }));
    if (pa.supervisors > 0) parts.push(t("supervisorsCount", { count: pa.supervisors }));
    return parts.join(" · ");
  }, [data, t]);

  const totalPending = (data?.pendingApprovals.total ?? 0) || pendingVerificationCount;

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">

      {/* Header */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <AdminPageHero
          badge={t("heroBadge")}
          title={t("heroTitle")}
          description={t("heroDescription")}
        />
        <div className="flex items-center gap-2 shrink-0">
          <div className={cn("flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium",
            online ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400"
                   : "bg-rose-50 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400"
          )}>
            {online ? <Wifi className="h-3 w-3" /> : <WifiOff className="h-3 w-3" />}
            {online ? t("live") : t("offline")}
          </div>
          {lastUpdated && (
            <span className="text-xs text-slate-400">
              {lastUpdated.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
            </span>
          )}
          <button
            type="button"
            onClick={() => void load(true)}
            disabled={refreshing}
            className="inline-flex items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
          >
            <RefreshCw className={cn("h-4 w-4", refreshing && "animate-spin")} />
            {t("refresh")}
          </button>
        </div>
      </div>

      {/* Pending approvals alert */}
      {totalPending > 0 && (
        <div className="flex flex-col gap-3 rounded-2xl border border-amber-200 bg-amber-50/90 p-4 sm:flex-row sm:items-center sm:justify-between dark:border-amber-800/40 dark:bg-amber-900/20">
          <div className="flex gap-3">
            <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400" />
            <div>
              <p className="font-semibold text-amber-800 dark:text-amber-300">
                {t("pendingAlertTitle", { count: totalPending })}
              </p>
              {pendingBreakdown && (
                <p className="text-xs text-amber-600 dark:text-amber-400">
                  {pendingBreakdown}
                </p>
              )}
            </div>
          </div>
          <Link
            href="/admin?view=approvals"
            className="inline-flex shrink-0 items-center justify-center gap-2 rounded-xl bg-amber-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-amber-700"
          >
            {t("openQueue")} <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      )}

      {/* KPI row 1 — from analytics */}
      {loading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="h-28 animate-pulse rounded-2xl bg-slate-100 dark:bg-slate-800" />
          ))}
        </div>
      ) : error ? (
        <div className="rounded-2xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-800/40 dark:bg-rose-900/20 dark:text-rose-400">
          {error}
        </div>
      ) : data ? (
        <>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <KpiCard label={t("kpiTotalUsers")} value={data.totalUsers.toLocaleString()} sub={t("kpiTotalUsersSub")}
              icon={Users} color="bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400"
              trend={{ value: data.newUsersThisMonth, label: t("kpiThisMonth") }} />
            <KpiCard label={t("kpiTotalStudents")} value={data.placementStats.total.toLocaleString()} sub={t("kpiPlacementRateSub", { rate: placementRate })}
              icon={GraduationCap} color="bg-teal-50 text-teal-600 dark:bg-teal-900/30 dark:text-teal-400" />
            <KpiCard label={t("kpiActiveInternships")} value={data.placementStats.placed.toLocaleString()} sub={t("kpiCompleted", { count: data.placementStats.completed })}
              icon={Briefcase} color="bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400" />
            <KpiCard label={t("kpiProposalApproval")} value={`${proposalApprovalRate}%`} sub={t("kpiProposalSub", { approved: data.proposalStats.approved, total: data.proposalStats.total })}
              icon={CheckCircle2} color="bg-violet-50 text-violet-600 dark:bg-violet-900/30 dark:text-violet-400" />
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <KpiCard label={t("kpiUniversities")} value={data.orgStats.universities.approved} sub={t("kpiUniversitiesSub", { total: data.orgStats.universities.total })}
              icon={Building2} color="bg-indigo-50 text-indigo-600 dark:bg-indigo-900/30 dark:text-indigo-400" />
            <KpiCard label={t("kpiCompanies")} value={data.orgStats.companies.approved} sub={t("kpiCompaniesSub", { total: data.orgStats.companies.total })}
              icon={Briefcase} color="bg-amber-50 text-amber-600 dark:bg-amber-900/30 dark:text-amber-400" />
            <KpiCard label={t("kpiEvaluationsDone")} value={data.totalEvaluations.toLocaleString()}
              sub={data.evalStats.count > 0 ? t("kpiEvaluationsAvg", { tech: data.evalStats.avgTechnical, soft: data.evalStats.avgSoftSkill }) : t("kpiNoEvaluationsYet")}
              icon={Star} color="bg-rose-50 text-rose-600 dark:bg-rose-900/30 dark:text-rose-400" />
            <KpiCard label={t("kpiFinalReports")} value={data.totalReports.toLocaleString()} sub={t("kpiFinalReportsSub")}
              icon={FileText} color="bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400" />
          </div>

          {/* Quick navigation */}
          <section>
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">{t("quickNavTitle")}</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
              {quickLinks.map((q) => (
                <Link key={q.href} href={q.href}
                  className={cn("card group flex items-center justify-between gap-3 p-4 transition-all hover:border-teal-200 hover:shadow-md ring-1 ring-transparent hover:ring-teal-100")}
                >
                  <span className="flex min-w-0 items-center gap-3">
                    <span className={cn("rounded-xl p-2.5 ring-1", q.accent)}><q.icon className="h-5 w-5" /></span>
                    <span className="font-semibold text-slate-900 dark:text-slate-100">{q.label}</span>
                  </span>
                  <ArrowRight className="h-4 w-4 shrink-0 text-slate-400 transition-transform group-hover:translate-x-0.5 group-hover:text-teal-600" />
                </Link>
              ))}
            </div>
          </section>

          {/* User growth chart */}
          <SectionCard title={t("chartUserGrowthTitle")} subtitle={t("chartUserGrowthSubtitle")}>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={data.userGrowth} barSize={10} barGap={2}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis dataKey="label" tick={{ fontSize: 12, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 12, fill: "#94a3b8" }} axisLine={false} tickLine={false} allowDecimals={false} />
                <Tooltip contentStyle={{ borderRadius: 12, border: "1px solid #e2e8f0", fontSize: 12 }} />
                <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: 12 }} />
                <Bar dataKey="students" name={t("chartStudents")} fill={COLORS.blue} radius={[4, 4, 0, 0]} />
                <Bar dataKey="coordinators" name={t("chartCoordinators")} fill={COLORS.teal} radius={[4, 4, 0, 0]} />
                <Bar dataKey="supervisors" name={t("chartSupervisors")} fill={COLORS.violet} radius={[4, 4, 0, 0]} />
                <Bar dataKey="hods" name={t("chartHods")} fill={COLORS.amber} radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </SectionCard>

          {/* Placement trend + internship status */}
          <div className="grid gap-6 lg:grid-cols-2">
            <SectionCard title={t("chartPlacementTrendTitle")} subtitle={t("chartPlacementTrendSubtitle")}>
              <ResponsiveContainer width="100%" height={200}>
                <AreaChart data={data.placementTrend}>
                  <defs>
                    <linearGradient id="placementGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={COLORS.emerald} stopOpacity={0.2} />
                      <stop offset="95%" stopColor={COLORS.emerald} stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                  <XAxis dataKey="label" tick={{ fontSize: 12, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 12, fill: "#94a3b8" }} axisLine={false} tickLine={false} allowDecimals={false} />
                  <Tooltip contentStyle={{ borderRadius: 12, border: "1px solid #e2e8f0", fontSize: 12 }} />
                  <Area type="monotone" dataKey="count" name={t("chartPlacements")} stroke={COLORS.emerald} strokeWidth={2} fill="url(#placementGrad)" dot={{ r: 4, fill: COLORS.emerald }} />
                </AreaChart>
              </ResponsiveContainer>
            </SectionCard>

            <SectionCard title={t("chartInternshipStatusTitle")} subtitle={t("chartInternshipStatusSubtitle")}>
              <div className="flex items-center justify-center gap-8">
                <PieChart width={160} height={160}>
                  <Pie data={internshipPieData} cx={75} cy={75} innerRadius={45} outerRadius={70} paddingAngle={3} dataKey="value">
                    {internshipPieData.map((_, i) => <Cell key={i} fill={PIE_COLORS[i]} />)}
                  </Pie>
                  <Tooltip contentStyle={{ borderRadius: 12, border: "1px solid #e2e8f0", fontSize: 12 }} />
                </PieChart>
                <div className="space-y-2">
                  {internshipPieData.map((d, i) => (
                    <div key={d.name} className="flex items-center gap-2 text-sm">
                      <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: PIE_COLORS[i] }} />
                      <span className="text-slate-600 dark:text-slate-400">{d.name}</span>
                      <span className="font-bold text-slate-900 dark:text-slate-100">{d.value}</span>
                    </div>
                  ))}
                </div>
              </div>
            </SectionCard>
          </div>

          {/* Proposal outcomes + weekly plan trend */}
          <div className="grid gap-6 lg:grid-cols-2">
            <SectionCard title={t("chartProposalOutcomesTitle")} subtitle={t("chartProposalOutcomesSubtitle")}>
              <div className="flex items-center justify-center gap-8">
                <PieChart width={160} height={160}>
                  <Pie data={proposalPieData} cx={75} cy={75} innerRadius={45} outerRadius={70} paddingAngle={3} dataKey="value">
                    {proposalPieData.map((_, i) => <Cell key={i} fill={PROPOSAL_COLORS[i]} />)}
                  </Pie>
                  <Tooltip contentStyle={{ borderRadius: 12, border: "1px solid #e2e8f0", fontSize: 12 }} />
                </PieChart>
                <div className="space-y-2">
                  {proposalPieData.map((d, i) => (
                    <div key={d.name} className="flex items-center gap-2 text-sm">
                      <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: PROPOSAL_COLORS[i] }} />
                      <span className="text-slate-600 dark:text-slate-400">{d.name}</span>
                      <span className="font-bold text-slate-900 dark:text-slate-100">{d.value}</span>
                    </div>
                  ))}
                </div>
              </div>
            </SectionCard>

            <SectionCard title={t("chartWeeklyPlansTitle")} subtitle={t("chartWeeklyPlansSubtitle")}>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={data.weeklyPlanTrend} barSize={12} barGap={4}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                  <XAxis dataKey="label" tick={{ fontSize: 12, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 12, fill: "#94a3b8" }} axisLine={false} tickLine={false} allowDecimals={false} />
                  <Tooltip contentStyle={{ borderRadius: 12, border: "1px solid #e2e8f0", fontSize: 12 }} />
                  <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: 12 }} />
                  <Bar dataKey="submitted" name={t("chartSubmitted")} fill={COLORS.slate} radius={[4, 4, 0, 0]} />
                  <Bar dataKey="approved" name={t("chartApproved")} fill={COLORS.teal} radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </SectionCard>
          </div>

          {/* Org approval rates + evaluation scores */}
          <div className="grid gap-6 lg:grid-cols-2">
            <SectionCard title={t("chartOrgApprovalTitle")} subtitle={t("chartOrgApprovalSubtitle")}>
              <div className="space-y-5">
                {[
                  { label: t("kpiUniversities"), approved: data.orgStats.universities.approved, total: data.orgStats.universities.total, color: COLORS.blue },
                  { label: t("kpiCompanies"), approved: data.orgStats.companies.approved, total: data.orgStats.companies.total, color: COLORS.violet },
                ].map((org) => {
                  const pct = org.total > 0 ? Math.round((org.approved / org.total) * 100) : 0;
                  return (
                    <div key={org.label}>
                      <div className="mb-1.5 flex justify-between text-sm">
                        <span className="font-medium text-slate-700 dark:text-slate-300">{org.label}</span>
                        <span className="text-slate-500">{org.approved} / {org.total} ({pct}%)</span>
                      </div>
                      <div className="h-2.5 w-full overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
                        <div className="h-full rounded-full transition-all duration-700" style={{ width: `${pct}%`, background: org.color }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            </SectionCard>

            <SectionCard title={t("chartEvaluationScoresTitle")} subtitle={t("chartEvaluationScoresSubtitle")}>
              {data.evalStats.count === 0 ? (
                <div className="flex h-24 items-center justify-center text-sm text-slate-400">{t("chartNoEvaluationsBlock")}</div>
              ) : (
                <div className="space-y-5">
                  {[
                    { label: t("chartTechnicalScore"), value: data.evalStats.avgTechnical, color: COLORS.blue },
                    { label: t("chartSoftSkillScore"), value: data.evalStats.avgSoftSkill, color: COLORS.violet },
                  ].map((s) => (
                    <div key={s.label}>
                      <div className="mb-1.5 flex justify-between text-sm">
                        <span className="font-medium text-slate-700 dark:text-slate-300">{s.label}</span>
                        <span className="font-bold text-slate-900 dark:text-slate-100">{s.value} / 100</span>
                      </div>
                      <div className="h-2.5 w-full overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
                        <div className="h-full rounded-full transition-all duration-700" style={{ width: `${s.value}%`, background: s.color }} />
                      </div>
                    </div>
                  ))}
                  <p className="text-xs text-slate-400">{t("evaluationBasedOn", { count: data.evalStats.count })}</p>
                </div>
              )}
            </SectionCard>
          </div>

          {/* Recent activity */}
          <SectionCard title={t("activityTitle")} subtitle={t("activitySubtitle")}>
            {data.recentActivity.length === 0 ? (
              <div className="flex h-16 items-center justify-center text-sm text-slate-400">{t("activityNoRows")}</div>
            ) : (
              <>
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm">
                    <thead>
                      <tr className="border-b border-slate-100 dark:border-slate-800 text-xs font-semibold uppercase tracking-wider text-slate-400">
                        <th className="pb-3 pr-4">{t("activityColAction")}</th>
                        <th className="pb-3 pr-4">{t("activityColAdmin")}</th>
                        <th className="pb-3 pr-4">{t("activityColDetails")}</th>
                        <th className="pb-3 text-right">{t("activityColDate")}</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                      {data.recentActivity.map((entry) => (
                        <tr key={entry.id} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition-colors">
                          <td className="py-3 pr-4">
                            <ActionBadge action={entry.action} />
                          </td>
                          <td className="py-3 pr-4">
                            <div className="flex items-center gap-2">
                              <div className="rounded-lg bg-slate-100 p-1.5 dark:bg-slate-800">
                                <Activity className="h-3.5 w-3.5 text-slate-500" />
                              </div>
                              <span className="text-xs font-medium text-slate-700 dark:text-slate-300">{entry.adminName}</span>
                            </div>
                          </td>
                          <td className="py-3 pr-4 max-w-[220px]">
                            <p className="truncate text-xs text-slate-500 dark:text-slate-400">
                              {entry.details ?? t("activityDash")}
                            </p>
                          </td>
                          <td className="py-3 text-right text-xs text-slate-400 whitespace-nowrap">
                            {new Date(entry.timestamp).toLocaleDateString([], { month: "short", day: "numeric", year: "numeric" })}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Pagination */}
                {data.totalActivity > ACTIVITY_LIMIT && (() => {
                  const totalPages = Math.ceil(data.totalActivity / ACTIVITY_LIMIT);
                  return (
                    <div className="mt-4 flex items-center justify-between border-t border-slate-100 pt-4 dark:border-slate-800">
                      <span className="text-xs text-slate-400">
                        {t("activityPageRange", {
                          start: ((activityPage - 1) * ACTIVITY_LIMIT) + 1,
                          end: Math.min(activityPage * ACTIVITY_LIMIT, data.totalActivity),
                          total: data.totalActivity,
                        })}
                      </span>
                      <div className="flex items-center gap-1">
                        <button
                          type="button"
                          onClick={() => handleActivityPageChange(activityPage - 1)}
                          disabled={activityPage <= 1}
                          className="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
                        >
                          <ChevronLeft className="h-3.5 w-3.5" /> {t("paginationPrev")}
                        </button>
                        {Array.from({ length: totalPages }, (_, i) => i + 1)
                          .filter(p => p === 1 || p === totalPages || Math.abs(p - activityPage) <= 1)
                          .reduce<(number | "…")[]>((acc, p, i, arr) => {
                            if (i > 0 && (p as number) - (arr[i - 1] as number) > 1) acc.push("…");
                            acc.push(p);
                            return acc;
                          }, [])
                          .map((p, i) =>
                            p === "…" ? (
                              <span key={`ellipsis-${i}`} className="px-1 text-xs text-slate-400">…</span>
                            ) : (
                              <button
                                key={p}
                                type="button"
                                onClick={() => handleActivityPageChange(p as number)}
                                className={cn(
                                  "min-w-[28px] rounded-lg border px-2 py-1.5 text-xs font-medium transition-colors",
                                  activityPage === p
                                    ? "border-teal-500 bg-teal-600 text-white"
                                    : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
                                )}
                              >
                                {p}
                              </button>
                            )
                          )}
                        <button
                          type="button"
                          onClick={() => handleActivityPageChange(activityPage + 1)}
                          disabled={activityPage >= totalPages}
                          className="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
                        >
                          {t("paginationNext")} <ChevronRight className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </div>
                  );
                })()}
              </>
            )}
          </SectionCard>
        </>
      ) : null}

      <p className="text-center text-xs text-slate-400">
        {t("autoRefresh", {
          time: lastUpdated?.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" }) ?? t("autoRefreshUnknown"),
        })}
      </p>
    </div>
  );
}
