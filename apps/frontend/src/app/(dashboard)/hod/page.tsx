"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { useAuth } from "@/lib/hooks/useAuth";
import { Loader2, RefreshCw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodStatCards from "@/components/hod/HodStatCards";
import HodQuickLinks from "@/components/hod/HodQuickLinks";
import type { HodStats } from "@/components/hod/types";
import { useTranslations } from "next-intl";

export default function HodDashboardPage() {
  const { user } = useAuth();
  const t = useTranslations("HodPortal.dashboard");
  const [stats, setStats] = useState<HodStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadStats = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const st = await api.get<{ success: boolean; data: HodStats }>("/hod/dashboard-stats");
      setStats(st.data.data ?? null);
    } catch {
      setError(t("couldNotLoad"));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadStats();
  }, [loadStats]);

  if (error && !stats && !loading) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">{error}</div>
    );
  }

  return (
    <div className="space-y-8 pb-8">
      <HodPageHero
        badge={t("badge")}
        title={t("welcomeBack", { name: user?.fullName ?? t("hodFallback") })}
        description={t("description")}
        action={
          <button
            type="button"
            onClick={() => void loadStats()}
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
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500 dark:text-slate-400">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <>
          <HodStatCards stats={stats} />
          <HodQuickLinks />
        </>
      )}
    </div>
  );
}
