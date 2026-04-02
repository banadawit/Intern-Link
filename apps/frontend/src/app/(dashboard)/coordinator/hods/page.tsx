"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2, RefreshCw } from "lucide-react";
import api from "@/lib/api/client";
import CoordinatorPageHero from "../CoordinatorPageHero";
import type { CoordinatorHodRow } from "@/components/coordinator/types";
import { cn } from "@/lib/utils";

export default function CoordinatorHodsPage() {
  const [hods, setHods] = useState<CoordinatorHodRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get<CoordinatorHodRow[]>("/coordinator-portal/hods");
      setHods(data);
    } catch {
      setError("Could not load HOD accounts.");
      setHods([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const act = async (userId: number, action: "approve" | "reject") => {
    setSubmitting(true);
    setError(null);
    try {
      await api.post(`/coordinator-portal/hods/${userId}/${action}`);
      await load();
    } catch {
      setError(`Failed to ${action} HOD.`);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 pb-8">
      <CoordinatorPageHero
        badge="HOD management"
        title="Heads of Department"
        description="Review pending HOD registrations and monitor all department heads linked to your university."
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

      {loading && hods.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <section className="overflow-x-auto rounded-2xl border border-slate-200 bg-white shadow-sm">
          <table className="w-full min-w-[720px] text-left text-sm">
            <thead className="border-b border-slate-100 bg-slate-50/80">
              <tr>
                <th className="px-4 py-3 font-semibold text-slate-700">Name</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Email</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Department</th>
                <th className="px-4 py-3 font-semibold text-slate-700">Access</th>
                <th className="px-4 py-3 text-right font-semibold text-slate-700">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {hods.map((h) => (
                <tr key={h.id} className="hover:bg-slate-50/50">
                  <td className="px-4 py-3 font-medium text-slate-900">{h.user.full_name}</td>
                  <td className="px-4 py-3 text-slate-600">{h.user.email}</td>
                  <td className="px-4 py-3 text-slate-700">{h.department}</td>
                  <td className="px-4 py-3">
                    <span
                      className={cn(
                        "inline-flex rounded-full px-2 py-0.5 text-xs font-semibold",
                        h.user.institution_access_approval === "PENDING" && "bg-amber-100 text-amber-900",
                        h.user.institution_access_approval === "APPROVED" && "bg-emerald-100 text-emerald-900",
                        h.user.institution_access_approval === "REJECTED" && "bg-red-100 text-red-800",
                      )}
                    >
                      {h.user.institution_access_approval}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right">
                    {h.user.institution_access_approval === "PENDING" && (
                      <div className="flex justify-end gap-2">
                        <button
                          type="button"
                          disabled={submitting}
                          onClick={() => void act(h.user.id, "approve")}
                          className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                        >
                          Approve
                        </button>
                        <button
                          type="button"
                          disabled={submitting}
                          onClick={() => void act(h.user.id, "reject")}
                          className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                        >
                          Reject
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {hods.length === 0 && (
            <p className="py-10 text-center text-sm text-slate-500">No HOD accounts for your university.</p>
          )}
        </section>
      )}
    </div>
  );
}
