"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2, RefreshCw } from "lucide-react";
import api from "@/lib/api/client";
import CoordinatorPageHero from "../CoordinatorPageHero";
import type { CoordinatorCompanyRow } from "@/components/coordinator/types";
import { cn } from "@/lib/utils";

export default function CoordinatorCompaniesPage() {
  const [companies, setCompanies] = useState<CoordinatorCompanyRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get<CoordinatorCompanyRow[]>("/coordinator-portal/companies");
      setCompanies(data);
    } catch {
      setError("Could not load companies.");
      setCompanies([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <div className="space-y-6 pb-8">
      <CoordinatorPageHero
        badge="Companies"
        title="Company directory"
        description="Read-only view of all organizations on InternLink. Use this to monitor verification status and outreach."
        action={
          <button
            type="button"
            onClick={() => void load()}
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

      {loading && companies.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <section className="overflow-x-auto rounded-2xl border border-slate-200 bg-white shadow-sm">
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead className="border-b border-slate-100 bg-slate-50/80">
              <tr>
                <th className="px-4 py-3 font-semibold text-slate-700">Company</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Email</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Status</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Registered</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {companies.map((c) => (
                <tr key={c.id} className="hover:bg-slate-50/50">
                  <td className="px-4 py-3 font-medium text-slate-900">{c.name}</td>
                  <td className="px-4 py-3 text-slate-600">{c.official_email}</td>
                  <td className="px-4 py-3">
                    <span
                      className={cn(
                        "inline-flex rounded-full px-2 py-0.5 text-xs font-semibold",
                        c.approval_status === "APPROVED" && "bg-emerald-100 text-emerald-900",
                        c.approval_status === "PENDING" && "bg-amber-100 text-amber-900",
                        (c.approval_status === "REJECTED" || c.approval_status === "SUSPENDED") &&
                          "bg-slate-200 text-slate-800",
                      )}
                    >
                      {c.approval_status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-slate-500">
                    {new Date(c.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {companies.length === 0 && (
            <p className="py-10 text-center text-sm text-slate-500">No companies found.</p>
          )}
        </section>
      )}
    </div>
  );
}
