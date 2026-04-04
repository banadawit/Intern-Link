"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { useAuth } from "@/lib/hooks/useAuth";
import { Loader2, RefreshCw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodStatCards from "@/components/hod/HodStatCards";
import HodQuickLinks from "@/components/hod/HodQuickLinks";
import type { HodStats } from "@/components/hod/types";

export default function HodDashboardPage() {
  const { user } = useAuth();
  const [stats, setStats] = useState<HodStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadStats = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const st = await api.get<HodStats>("/hod/dashboard-stats");
      setStats(st.data);
    } catch {
      setError("Could not load dashboard data.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadStats();
  }, [loadStats]);

  if (error && !stats && !loading) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-sm text-red-800">{error}</div>
    );
  }

  return (
    <div className="space-y-8 pb-8">
      <HodPageHero
        badge="Department portal"
        title={`Welcome back, ${user?.fullName ?? "Head of Department"}`}
        description="Overview of your department. Use the sidebar or the links below to manage students, placements, and reports."
        action={
          <button
            type="button"
            onClick={() => void loadStats()}
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
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
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
