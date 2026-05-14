"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw, TrendingUp } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodReportsTable from "@/components/hod/HodReportsTable";
import type { HodReportRow } from "@/components/hod/types";
import { useTranslations } from "next-intl";

type ReportsSummary = {
  averageScore: number | null;
  studentsWithFinalReport: number;
};

export default function HodReportsPage() {
  const t = useTranslations("HodPortal.reports");
  const [reports, setReports] = useState<HodReportRow[]>([]);
  const [summary, setSummary] = useState<ReportsSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [reportsRes, summaryRes] = await Promise.all([
        api.get<{ success: boolean; data: HodReportRow[] }>("/hod/reports"),
        api.get<{ success: boolean; data: ReportsSummary }>("/hod/reports/summary"),
      ]);
      setReports(Array.isArray(reportsRes.data.data) ? reportsRes.data.data : []);
      setSummary(summaryRes.data.data ?? null);
    } catch {
      setError(t("couldNotLoad"));
    } finally {
      setLoading(false);
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <div className="space-y-6 pb-8">
      <HodPageHero
        badge={t("badge")}
        title={t("title")}
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

      {summary && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div className="flex items-center gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-teal-50 text-teal-600 dark:bg-teal-900/30 dark:text-teal-400">
              <TrendingUp className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Avg Score</p>
              <p className="text-2xl font-bold tabular-nums text-slate-900 dark:text-slate-100">
                {summary.averageScore !== null ? summary.averageScore : "—"}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-900">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
              <Loader2 className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">{t("title")}</p>
              <p className="text-2xl font-bold tabular-nums text-slate-900 dark:text-slate-100">{summary.studentsWithFinalReport}</p>
            </div>
          </div>
        </div>
      )}

      {loading && reports.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500 dark:text-slate-400">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <HodReportsTable reports={reports} />
      )}
    </div>
  );
}
