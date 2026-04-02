"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodOpenLettersPanel from "@/components/hod/HodOpenLettersPanel";
import type { HodProposalRow } from "@/components/hod/types";

export default function HodOpenLettersPage() {
  const [openLetters, setOpenLetters] = useState<HodProposalRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<HodProposalRow[]>("/hod/proposals/open-letters");
      setOpenLetters(res.data);
    } catch {
      setError("Could not load open letter proposals.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const actOpenLetter = async (id: number, status: "APPROVED" | "REJECTED") => {
    setSubmitting(true);
    try {
      await api.patch(`/hod/proposals/open-letters/${id}`, { status });
      await load();
    } catch {
      setError("Could not update open letter proposal.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 pb-8">
      <HodPageHero
        badge="Open letters"
        title="Open letter proposals"
        description="Review external internship requests submitted by students before they proceed."
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

      {loading && openLetters.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <HodOpenLettersPanel
          openLetters={openLetters}
          submitting={submitting}
          onApprove={(id) => void actOpenLetter(id, "APPROVED")}
          onReject={(id) => void actOpenLetter(id, "REJECTED")}
        />
      )}
    </div>
  );
}
