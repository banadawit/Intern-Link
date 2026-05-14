"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { mapWeeklyPlanRow } from "@/lib/api/mappers";
import type { WeeklyPlan } from "@/lib/superadmin/types";
import { cn } from "@/lib/utils";
import {
  Calendar, CheckCircle2, Loader2, ChevronDown, ChevronUp,
} from "lucide-react";

export default function DailyPlanView() {
  const [plans, setPlans] = useState<WeeklyPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get("/progress/my-plans");
      const raw = res.data as { success?: boolean; data?: unknown[] } | unknown[];
      const rows = ((raw as { success?: boolean; data?: unknown[] })?.data ?? raw) as Record<string, unknown>[];
      const mapped = (Array.isArray(rows) ? rows : []).map((row) =>
        mapWeeklyPlanRow(row as Parameters<typeof mapWeeklyPlanRow>[0])
      );
      setPlans(mapped);
    } catch {
      setError("Could not load plans. Make sure you have an active internship placement.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const approvedPlans = plans.filter((p) => p.status === "Approved");

  if (loading) {
    return (
      <div className="flex min-h-[30vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
        {error}
      </div>
    );
  }

  if (approvedPlans.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-16 text-center">
        <CheckCircle2 className="h-12 w-12 text-slate-300 dark:text-slate-600 mb-3" />
        <p className="text-base font-semibold text-slate-600 dark:text-slate-400">No approved plans yet</p>
        <p className="text-sm text-slate-400 dark:text-slate-500 mt-1">
          Daily attendance is recorded automatically when your supervisor approves a weekly plan.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">Daily Attendance</h2>
        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
          Your daily attendance is recorded automatically when your supervisor approves your weekly plan.
        </p>
      </div>

      {approvedPlans.map((plan) => {
        const submittedDates = (plan.daySubmissions ?? [])
          .map((d) => {
            const raw = typeof d.workDate === "string" ? d.workDate : new Date(d.workDate).toISOString();
            return raw.slice(0, 10);
          })
          .sort();

        const isExpanded = expanded === plan.id;

        return (
          <div
            key={plan.id}
            className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm overflow-hidden"
          >
            {/* Plan header */}
            <button
              type="button"
              onClick={() => setExpanded(isExpanded ? null : plan.id)}
              className="flex w-full items-center gap-3 px-5 py-4 text-left hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors"
            >
              <div className="rounded-xl bg-emerald-50 dark:bg-emerald-900/30 p-2.5 text-emerald-600 dark:text-emerald-400 shrink-0">
                <Calendar className="h-5 w-5" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-bold text-slate-900 dark:text-slate-100">Week {plan.weekNumber}</p>
                {plan.tasks && (
                  <p className="text-xs text-slate-600 dark:text-slate-300 mt-0.5 line-clamp-1">{plan.tasks}</p>
                )}
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  {submittedDates.length} day{submittedDates.length !== 1 ? "s" : ""} recorded
                </p>
              </div>
              {/* Progress bar */}
              <div className="hidden sm:flex items-center gap-3">
                <div className="w-24">
                  <div className="h-1.5 w-full rounded-full bg-slate-100 dark:bg-slate-800">
                    <div
                      className="h-full rounded-full bg-emerald-500 transition-all"
                      style={{ width: `${Math.min(100, Math.round((submittedDates.length / 5) * 100))}%` }}
                    />
                  </div>
                </div>
                <span className="text-xs text-slate-400 dark:text-slate-500 w-8 text-right">
                  {submittedDates.length}/5
                </span>
              </div>
              {isExpanded ? (
                <ChevronUp className="h-4 w-4 text-slate-400 shrink-0" />
              ) : (
                <ChevronDown className="h-4 w-4 text-slate-400 shrink-0" />
              )}
            </button>

            {/* Day list — read-only */}
            {isExpanded && (
              <div className="border-t border-slate-100 dark:border-slate-700 divide-y divide-slate-100 dark:divide-slate-700">
                {plan.tasks && (
                  <div className="px-5 py-3 bg-slate-50/60 dark:bg-slate-800/40">
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-1">
                      This week&apos;s plan
                    </p>
                    <p className="text-sm text-slate-600 dark:text-slate-300 whitespace-pre-wrap">{plan.tasks}</p>
                  </div>
                )}

                {submittedDates.length === 0 ? (
                  <div className="px-5 py-6 text-center text-sm text-slate-400 dark:text-slate-500">
                    No attendance recorded yet for this week.
                  </div>
                ) : (
                  submittedDates.map((ymd) => {
                    const label = new Date(`${ymd}T12:00:00.000Z`).toLocaleDateString(undefined, {
                      weekday: "long", month: "short", day: "numeric",
                    });
                    const sub = plan.daySubmissions?.find((d) => d.workDate?.slice(0, 10) === ymd);
                    return (
                      <div key={ymd} className="px-5 py-4 bg-emerald-50/40 dark:bg-emerald-900/10">
                        <div className="flex items-center gap-2 mb-1">
                          <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500 text-white">
                            <CheckCircle2 className="h-4 w-4" />
                          </div>
                          <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">{label}</span>
                        </div>
                        {sub?.notes && (
                          <p className="ml-8 text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                            {sub.notes}
                          </p>
                        )}
                      </div>
                    );
                  })
                )}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
