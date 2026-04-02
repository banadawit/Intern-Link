"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodSendProposalForm from "@/components/hod/HodSendProposalForm";
import HodProposalTrackerTable from "@/components/hod/HodProposalTrackerTable";
import type { HodCompanyRow, HodProposalRow, HodStudentRow } from "@/components/hod/types";

export default function HodPlacementsPage() {
  const [students, setStudents] = useState<HodStudentRow[]>([]);
  const [companies, setCompanies] = useState<HodCompanyRow[]>([]);
  const [proposals, setProposals] = useState<HodProposalRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [proposalStudentId, setProposalStudentId] = useState("");
  const [proposalCompanyId, setProposalCompanyId] = useState("");
  const [proposalWeeks, setProposalWeeks] = useState("");
  const [proposalOutcomes, setProposalOutcomes] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [stud, comp, prop] = await Promise.all([
        api.get<HodStudentRow[]>("/hod/students", { params: { status: "all" } }),
        api.get<HodCompanyRow[]>("/hod/companies", { params: { verifiedOnly: true } }),
        api.get<HodProposalRow[]>("/hod/proposals"),
      ]);
      setStudents(stud.data);
      setCompanies(comp.data);
      setProposals(prop.data);
    } catch {
      setError("Could not load placement data.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const approvedStudents = students.filter((s) => s.hod_approval_status === "APPROVED");

  const sendProposal = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await api.post("/hod/proposals", {
        studentId: parseInt(proposalStudentId, 10),
        companyId: parseInt(proposalCompanyId, 10),
        expected_duration_weeks: proposalWeeks ? parseInt(proposalWeeks, 10) : undefined,
        expected_outcomes: proposalOutcomes || undefined,
        proposal_type: "University_Initiated",
      });
      setProposalStudentId("");
      setProposalCompanyId("");
      setProposalWeeks("");
      setProposalOutcomes("");
      await load();
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { error?: string } } };
      setError(ax.response?.data?.error || "Could not send proposal.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-8 pb-8">
      <HodPageHero
        badge="Placements"
        title="Placements"
        description="Send university-initiated proposals to verified companies and track responses in one place."
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

      {loading && students.length === 0 && companies.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <>
          <HodSendProposalForm
            approvedStudents={approvedStudents}
            companies={companies}
            submitting={submitting}
            proposalStudentId={proposalStudentId}
            proposalCompanyId={proposalCompanyId}
            proposalWeeks={proposalWeeks}
            proposalOutcomes={proposalOutcomes}
            onStudentId={setProposalStudentId}
            onCompanyId={setProposalCompanyId}
            onWeeks={setProposalWeeks}
            onOutcomes={setProposalOutcomes}
            onSubmit={sendProposal}
          />
          <HodProposalTrackerTable proposals={proposals} />
        </>
      )}
    </div>
  );
}
