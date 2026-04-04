"use client";

import { cloneElement, useCallback, useEffect, useMemo, useState } from "react";
import CalendarHeatmap from "react-calendar-heatmap";
import api from "@/lib/api/client";
import { cn } from "@/lib/utils";
import { Activity, Loader2 } from "lucide-react";

export type ActivityDay = { date: string; count: number };

export type ActivityStats = {
  totalContributions: number;
  currentStreak: number;
  longestStreak: number;
  mostActiveDate: string | null;
  mostActiveCount: number;
};

type ActivityResponse = {
  series: ActivityDay[];
  stats: ActivityStats;
};

/** Same 365-day window as backend: UTC calendar dates (inclusive range). */
function rollingOneYearUtc(): { start: Date; end: Date } {
  const now = new Date();
  const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const start = new Date(end);
  start.setUTCDate(start.getUTCDate() - 364);
  return { start, end };
}

function ymdUtcString(d: Date): string {
  return d.toISOString().slice(0, 10);
}

function parseActivityPayload(data: unknown): { series: ActivityDay[]; stats: ActivityStats | null } {
  if (Array.isArray(data)) {
    return { series: data as ActivityDay[], stats: null };
  }
  if (data && typeof data === "object") {
    const o = data as { series?: ActivityDay[]; stats?: ActivityStats };
    return {
      series: Array.isArray(o.series) ? o.series : [],
      stats: o.stats ?? null,
    };
  }
  return { series: [], stats: null };
}

/** Calendar math on UTC YYYY-MM-DD strings (matches API / Prisma @db.Date UTC). */
function dayBeforeUtcYmd(ymd: string): string {
  const [y, m, d] = ymd.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() - 1);
  return dt.toISOString().slice(0, 10);
}

function dayAfterUtcYmd(ymd: string): string {
  const [y, m, d] = ymd.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + 1);
  return dt.toISOString().slice(0, 10);
}

export default function ContributionHeatmap() {
  const [series, setSeries] = useState<ActivityDay[]>([]);
  const [stats, setStats] = useState<ActivityStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const { start, end } = useMemo(() => rollingOneYearUtc(), []);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<ActivityResponse | ActivityDay[]>("/activity");
      const { series: s, stats: st } = parseActivityPayload(res.data);
      setSeries(s);
      setStats(st);
    } catch (err: unknown) {
      const msg =
        err && typeof err === "object" && "response" in err
          ? (err as { response?: { data?: { error?: string; message?: string } } }).response?.data?.error ??
            (err as { response?: { data?: { error?: string; message?: string } } }).response?.data?.message
          : null;
      setError(msg ? `Could not load activity: ${msg}` : "Could not load activity. Check that you are signed in and the API is running.");
      setSeries([]);
      setStats(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const derivedStats = useMemo((): ActivityStats | null => {
    if (stats) return stats;
    if (!series.length) {
      return {
        totalContributions: 0,
        currentStreak: 0,
        longestStreak: 0,
        mostActiveDate: null,
        mostActiveCount: 0,
      };
    }
    const totalContributions = series.reduce((s, r) => s + r.count, 0);
    const datesWithActivity = series
      .filter((r) => r.count > 0)
      .map((r) => r.date)
      .sort();
    let longestStreak = 0;
    let run = 0;
    let prevD: string | null = null;
    for (const ds of datesWithActivity) {
      if (prevD && dayAfterUtcYmd(prevD) === ds) run += 1;
      else run = 1;
      longestStreak = Math.max(longestStreak, run);
      prevD = ds;
    }
    const byDate = new Map(series.map((r) => [r.date, r.count]));
    const rangeStartStr = ymdUtcString(start);
    const todayStr = ymdUtcString(end);
    let currentStreak = 0;
    let d = todayStr;
    while (d >= rangeStartStr) {
      const c = byDate.get(d) ?? 0;
      if (c <= 0) break;
      currentStreak += 1;
      d = dayBeforeUtcYmd(d);
    }
    let mostActiveDate: string | null = null;
    let mostActiveCount = 0;
    for (const r of series) {
      if (r.count > mostActiveCount) {
        mostActiveCount = r.count;
        mostActiveDate = r.date;
      }
    }
    return {
      totalContributions,
      currentStreak,
      longestStreak,
      mostActiveDate,
      mostActiveCount,
    };
  }, [series, stats]);

  const maxCount = useMemo(() => Math.max(1, ...series.map((s) => s.count)), [series]);

  const values = useMemo(
    () => series.map((s) => ({ date: s.date, count: s.count })),
    [series],
  );

  const classForValue = useCallback(
    (value: { date?: string | Date; count?: number } | null) => {
      if (!value?.count) return "gh-cell-0";
      const ratio = value.count / maxCount;
      if (ratio <= 0.25) return "gh-cell-1";
      if (ratio <= 0.5) return "gh-cell-2";
      if (ratio <= 0.75) return "gh-cell-3";
      return "gh-cell-4";
    },
    [maxCount],
  );

  const titleForValue = (value: { date?: string | Date; count?: number } | null) => {
    if (!value?.date) return "No activity";
    const d = typeof value.date === "string" ? value.date.slice(0, 10) : value.date.toISOString().slice(0, 10);
    const c = value.count ?? 0;
    return `Date: ${d}, Activity: ${c}`;
  };

  const monthLabels = useMemo(
    () => ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    [],
  );

  if (loading) {
    return (
      <div className="flex min-h-[140px] w-full min-w-0 items-center justify-center gap-2 rounded-2xl border border-border-default bg-white p-8 text-slate-500">
        <Loader2 className="h-5 w-5 animate-spin" aria-hidden />
        Loading activity…
      </div>
    );
  }

  if (error) {
    return (
      <div className="w-full min-w-0 rounded-2xl border border-red-200 bg-red-50/80 px-4 py-3 text-sm text-red-800" role="alert">
        {error}
      </div>
    );
  }

  return (
    <div className="w-full min-w-0 rounded-2xl border border-border-default bg-white p-5 shadow-sm">
      <div className="mb-4 flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div className="flex items-center gap-2">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-emerald-50 text-emerald-700 ring-1 ring-emerald-100">
            <Activity className="h-5 w-5" aria-hidden />
          </span>
          <div>
            <h2 className="text-lg font-bold text-slate-900">Contribution activity</h2>
            <p className="text-sm text-slate-500">
              Last 365 days (UTC). Logins, weekly plan submissions, and daily check-ins.
            </p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => void load()}
          className="self-start rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
        >
          Refresh
        </button>
      </div>

      {derivedStats && (
        <dl className="mb-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div className="rounded-xl bg-slate-50 px-3 py-2 ring-1 ring-slate-100">
            <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-500">Total</dt>
            <dd className="text-lg font-bold tabular-nums text-slate-900">{derivedStats.totalContributions}</dd>
          </div>
          <div className="rounded-xl bg-slate-50 px-3 py-2 ring-1 ring-slate-100">
            <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-500">Current streak</dt>
            <dd className="text-lg font-bold tabular-nums text-slate-900">{derivedStats.currentStreak} days</dd>
          </div>
          <div className="rounded-xl bg-slate-50 px-3 py-2 ring-1 ring-slate-100">
            <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-500">Longest streak</dt>
            <dd className="text-lg font-bold tabular-nums text-slate-900">{derivedStats.longestStreak} days</dd>
          </div>
          <div className="rounded-xl bg-slate-50 px-3 py-2 ring-1 ring-slate-100">
            <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-500">Most active day</dt>
            <dd className="text-sm font-semibold text-slate-900">
              {derivedStats.mostActiveDate ? (
                <>
                  {derivedStats.mostActiveDate}{" "}
                  <span className="text-slate-500">({derivedStats.mostActiveCount})</span>
                </>
              ) : (
                "—"
              )}
            </dd>
          </div>
        </dl>
      )}

      <div className="github-contribution-wrap mt-3 w-full min-w-0 overflow-x-auto overflow-y-hidden px-0 pb-1 sm:px-1">
        <div className="github-contribution-inner w-full min-w-0">
          <CalendarHeatmap
            startDate={start}
            endDate={end}
            values={values}
            classForValue={classForValue}
            titleForValue={titleForValue}
            monthLabels={monthLabels}
            horizontal
            showMonthLabels
            showWeekdayLabels
            gutterSize={3}
            transformDayElement={(element) =>
              cloneElement(element as React.ReactElement<React.SVGProps<SVGRectElement>>, {
                rx: 2,
                ry: 2,
              })
            }
          />
        </div>
      </div>

      <div className="mt-4 flex flex-wrap items-center justify-center gap-2 border-t border-slate-100 pt-4 text-xs text-slate-500">
        <span className="font-medium text-slate-600">Less</span>
        <span className="flex items-center gap-1">
          {[0, 1, 2, 3, 4].map((i) => (
            <span
              key={i}
              className={cn("inline-block h-3 w-3 rounded-sm", `gh-legend-${i}`)}
            />
          ))}
        </span>
        <span className="font-medium text-slate-600">More</span>
      </div>
    </div>
  );
}
