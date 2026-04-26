"use client";

import React, { useCallback, useEffect, useState } from "react";
import { Loader2, RefreshCw, TrendingUp, Users, CheckCircle2, BarChart3 } from "lucide-react";
import api from "@/lib/api/client";
import AdminPageHero from "./AdminPageHero";
import { cn } from "@/lib/utils";

interface AnalyticsData {
  userGrowth: { label: string; students: number; coordinators: number; supervisors: number; hods: number; total: number }[];
  placementStats: { total: number; placed: number; completed: number; pending: number };
  placementTrend: { label: string; count: number }[];
  proposalStats: { total: number; approved: number; rejected: number; pending: number };
  orgStats: { universities: { total: number; approved: number }; companies: { total: number; approved: number } };
  weeklyPlanTrend: { label: string; submitted: number; approved: number }[];
}

// Simple SVG bar chart
function BarChart({
  data,
  series,
  height = 160,
}: {
  data: Record<string, number | string>[];
  series: { key: string; color: string; label: string }[];
  height?: number;
}) {
  const labels = data.map((d) => d.label as string);
  const allValues = data.flatMap((d) => series.map((s) => Number(d[s.key] ?? 0)));
  const maxVal = Math.max(...allValues, 1);
  const barW = 100 / (data.length * (series.length + 0.5));
  const gap = barW * 0.15;

  return (
    <div className="w-full">
      <svg viewBox={`0 0 100 ${height}`} className="w-full" style={{ height }}>
        {/* Grid lines */}
        {[0, 0.25, 0.5, 0.75, 1].map((f) => (
          <line key={f} x1="0" y1={height * (1 - f) * 0.85 + height * 0.05}
            x2="100" y2={height * (1 - f) * 0.85 + height * 0.05}
            stroke="#f1f5f9" strokeWidth="0.3" />
        ))}
        {data.map((d, di) => {
          const groupX = (di / data.length) * 100 + barW * 0.25;
          return series.map((s, si) => {
            const val = Number(d[s.key] ?? 0);
            const barH = (val / maxVal) * height * 0.8;
            const x = groupX + si * (barW + gap);
            const y = height * 0.9 - barH;
            return (
              <g key={`${di}-${si}`}>
                <rect x={x} y={y} width={barW} height={barH} fill={s.color} rx="0.8" opacity="0.85" />
                {val > 0 && barH > 8 && (
                  <text x={x + barW / 2} y={y - 1} textAnchor="middle" fontSize="2.5" fill="#64748b">{val}</text>
                )}
              </g>
            );
          });
        })}
        {/* X labels */}
        {labels.map((l, i) => (
          <text key={i} x={(i / data.length) * 100 + barW * (series.length / 2 + 0.25)}
            y={height * 0.97} textAnchor="middle" fontSize="3" fill="#94a3b8">{l}</text>
        ))}
      </svg>
      {/* Legend */}
      <div className="mt-2 flex flex-wrap gap-3">
        {series.map((s) => (
          <div key={s.key} className="flex items-center gap-1.5">
            <span className="h-2.5 w-2.5 rounded-sm" style={{ background: s.color }} />
            <span className="text-xs text-slate-500">{s.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function StatCard({ label, value, sub, icon: Icon, color }: { label: string; value: string | number; sub?: string; icon: React.ComponentType<{ className?: string }>; color: string }) {
  return (
    <div className="flex items-center gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className={cn("rounded-xl p-3", color)}>
        <Icon className="h-5 w-5" />
      </div>
      <div>
        <p className="text-2xl font-bold text-slate-900">{value}</p>
        <p className="text-sm font-medium text-slate-700">{label}</p>
        {sub && <p className="text-xs text-slate-400">{sub}</p>}
      </div>
    </div>
  );
}

function DonutChart({ segments, size = 80 }: { segments: { value: number; color: string; label: string }[]; size?: number }) {
  const total = segments.reduce((s, x) => s + x.value, 0) || 1;
  const r = 30;
  const cx = 40;
  const cy = 40;
  let cumAngle = -Math.PI / 2;

  const arcs = segments.map((seg) => {
    const angle = (seg.value / total) * 2 * Math.PI;
    const x1 = cx + r * Math.cos(cumAngle);
    const y1 = cy + r * Math.sin(cumAngle);
    cumAngle += angle;
    const x2 = cx + r * Math.cos(cumAngle);
    const y2 = cy + r * Math.sin(cumAngle);
    const large = angle > Math.PI ? 1 : 0;
    return { ...seg, d: `M ${cx} ${cy} L ${x1} ${y1} A ${r} ${r} 0 ${large} 1 ${x2} ${y2} Z`, pct: Math.round((seg.value / total) * 100) };
  });

  return (
    <div className="flex items-center gap-4">
      <svg viewBox="0 0 80 80" width={size} height={size}>
        {arcs.map((a, i) => <path key={i} d={a.d} fill={a.color} opacity="0.85" />)}
        <circle cx={cx} cy={cy} r={18} fill="white" />
        <text x={cx} y={cy + 1} textAnchor="middle" dominantBaseline="middle" fontSize="8" fontWeight="bold" fill="#1e293b">{total}</text>
      </svg>
      <div className="space-y-1">
        {arcs.map((a, i) => (
          <div key={i} className="flex items-center gap-2 text-xs">
            <span className="h-2 w-2 rounded-full shrink-0" style={{ background: a.color }} />
            <span className="text-slate-600">{a.label}</span>
            <span className="font-semibold text-slate-900">{a.value}</span>
            <span className="text-slate-400">({a.pct}%)</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function AnalyticsView() {
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data: res } = await api.get<AnalyticsData>("/admin/analytics");
      setData(res);
    } catch {
      setError("Failed to load analytics.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  if (loading) return (
    <div className="flex min-h-[50vh] items-center justify-center">
      <Loader2 className="h-10 w-10 animate-spin text-teal-600" />
    </div>
  );

  if (error || !data) return (
    <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700">{error ?? "No data"}</div>
  );

  const placementRate = data.placementStats.total > 0
    ? Math.round(((data.placementStats.placed + data.placementStats.completed) / data.placementStats.total) * 100)
    : 0;

  const proposalApprovalRate = data.proposalStats.total > 0
    ? Math.round((data.proposalStats.approved / data.proposalStats.total) * 100)
    : 0;

  const uniApprovalRate = data.orgStats.universities.total > 0
    ? Math.round((data.orgStats.universities.approved / data.orgStats.universities.total) * 100)
    : 0;

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-start justify-between">
        <AdminPageHero
          badge="Analytics"
          title="Platform Analytics"
          description="Real-time insights into user growth, placements, and approval rates."
        />
        <button type="button" onClick={() => void load()} disabled={loading}
          className="mt-1 inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors">
          <RefreshCw className={cn("h-4 w-4", loading && "animate-spin")} />
          Refresh
        </button>
      </div>

      {/* KPI cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Total Students" value={data.placementStats.total} sub="Registered on platform" icon={Users} color="bg-blue-50 text-blue-600" />
        <StatCard label="Placement Rate" value={`${placementRate}%`} sub={`${data.placementStats.placed + data.placementStats.completed} placed or completed`} icon={TrendingUp} color="bg-emerald-50 text-emerald-600" />
        <StatCard label="Proposal Approval" value={`${proposalApprovalRate}%`} sub={`${data.proposalStats.approved} of ${data.proposalStats.total} proposals`} icon={CheckCircle2} color="bg-teal-50 text-teal-600" />
        <StatCard label="Org Approval Rate" value={`${uniApprovalRate}%`} sub={`${data.orgStats.universities.approved} universities approved`} icon={BarChart3} color="bg-violet-50 text-violet-600" />
      </div>

      {/* User growth chart */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="mb-1 text-base font-bold text-slate-900">User Growth — Last 6 Months</h2>
        <p className="mb-4 text-xs text-slate-400">New registrations per role per month</p>
        <BarChart
          data={data.userGrowth}
          series={[
            { key: "students", color: "#3b82f6", label: "Students" },
            { key: "coordinators", color: "#0d9488", label: "Coordinators" },
            { key: "supervisors", color: "#8b5cf6", label: "Supervisors" },
            { key: "hods", color: "#f59e0b", label: "HoDs" },
          ]}
          height={180}
        />
      </div>

      {/* Placement trend + stats */}
      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="mb-1 text-base font-bold text-slate-900">Placement Trend</h2>
          <p className="mb-4 text-xs text-slate-400">New assignments created per month</p>
          <BarChart
            data={data.placementTrend}
            series={[{ key: "count", color: "#10b981", label: "Placements" }]}
            height={160}
          />
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="mb-1 text-base font-bold text-slate-900">Internship Status</h2>
          <p className="mb-4 text-xs text-slate-400">Current breakdown of all students</p>
          <DonutChart
            size={100}
            segments={[
              { value: data.placementStats.placed, color: "#10b981", label: "Placed" },
              { value: data.placementStats.completed, color: "#3b82f6", label: "Completed" },
              { value: data.placementStats.pending, color: "#e2e8f0", label: "Pending" },
            ]}
          />
        </div>
      </div>

      {/* Proposal stats + weekly plan trend */}
      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="mb-1 text-base font-bold text-slate-900">Proposal Outcomes</h2>
          <p className="mb-4 text-xs text-slate-400">All-time internship proposal results</p>
          <DonutChart
            size={100}
            segments={[
              { value: data.proposalStats.approved, color: "#10b981", label: "Approved" },
              { value: data.proposalStats.rejected, color: "#ef4444", label: "Rejected" },
              { value: data.proposalStats.pending, color: "#f59e0b", label: "Pending" },
            ]}
          />
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="mb-1 text-base font-bold text-slate-900">Weekly Plan Submissions</h2>
          <p className="mb-4 text-xs text-slate-400">Submitted vs approved per month</p>
          <BarChart
            data={data.weeklyPlanTrend}
            series={[
              { key: "submitted", color: "#94a3b8", label: "Submitted" },
              { key: "approved", color: "#0d9488", label: "Approved" },
            ]}
            height={160}
          />
        </div>
      </div>

      {/* Org stats */}
      <div className="grid gap-4 sm:grid-cols-2">
        {[
          { label: "Universities", data: data.orgStats.universities, color: "#3b82f6" },
          { label: "Companies", data: data.orgStats.companies, color: "#8b5cf6" },
        ].map((org) => (
          <div key={org.label} className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-base font-bold text-slate-900">{org.label}</h2>
            <div className="flex items-center gap-4">
              <div className="flex-1">
                <div className="mb-1 flex justify-between text-xs text-slate-500">
                  <span>Approved</span>
                  <span>{org.data.approved} / {org.data.total}</span>
                </div>
                <div className="h-2.5 w-full overflow-hidden rounded-full bg-slate-100">
                  <div
                    className="h-full rounded-full transition-all duration-700"
                    style={{ width: `${org.data.total > 0 ? (org.data.approved / org.data.total) * 100 : 0}%`, background: org.color }}
                  />
                </div>
                <p className="mt-1 text-xs text-slate-400">
                  {org.data.total > 0 ? Math.round((org.data.approved / org.data.total) * 100) : 0}% approval rate
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
