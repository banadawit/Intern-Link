"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodCompanyDirectory from "@/components/hod/HodCompanyDirectory";
import type { HodCompanyRow } from "@/components/hod/types";
import { cn } from "@/lib/utils";

export default function HodCompaniesPage() {
  const [companies, setCompanies] = useState<HodCompanyRow[]>([]);
  const [hodInvitedIds, setHodInvitedIds] = useState<Set<number>>(new Set());
  const [verifiedOnly, setVerifiedOnly] = useState(true);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [companiesRes, invitedRes] = await Promise.all([
        api.get<{ success: boolean; data: HodCompanyRow[] }>("/hod/companies", {
          params: { verifiedOnly },
        }),
        api.get<{ success: boolean; data: { id: number }[] }>("/hod/invited-companies"),
      ]);
      setCompanies(Array.isArray(companiesRes.data.data) ? companiesRes.data.data : []);
      const invited = Array.isArray(invitedRes.data.data) ? invitedRes.data.data : [];
      setHodInvitedIds(new Set(invited.map((c) => c.id)));
    } catch {
      setError("Could not load companies.");
    } finally {
      setLoading(false);
    }
  }, [verifiedOnly]);

  useEffect(() => { void load(); }, [load]);

  return (
    <div className="space-y-6 pb-8">
      <HodPageHero
        badge="Companies"
        title="Company directory"
        description="Browse platform-approved organizations you can use when sending placement proposals."
        action={
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white disabled:opacity-60 sm:w-auto dark:bg-slate-900/90 dark:text-slate-100 dark:hover:bg-slate-900"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} aria-hidden />
            Refresh
          </button>
        }
      />

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">{error}</div>
      )}

      {/* Filter tabs */}
      <div className="flex gap-2">
        {([true, false] as const).map((v) => (
          <button
            key={String(v)}
            type="button"
            onClick={() => setVerifiedOnly(v)}
            className={cn(
              "rounded-xl px-4 py-2 text-sm font-semibold transition-colors",
              verifiedOnly === v
                ? "bg-primary-600 text-white shadow-sm"
                : "border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
            )}
          >
            {v ? "Verified" : "All"}
          </button>
        ))}
      </div>

      {loading && companies.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500 dark:text-slate-400">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <HodCompanyDirectory companies={companies} hodInvitedIds={hodInvitedIds} />
      )}
    </div>
  );
}
