"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw, RotateCcw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodSendProposalForm from "@/components/hod/HodSendProposalForm";
import HodProposalTrackerTable from "@/components/hod/HodProposalTrackerTable";
import { cn } from "@/lib/utils";
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
  // Reassign modal state
  const [reassignStudent, setReassignStudent] = useState<HodStudentRow | null>(null);
  const [reassignCompanyId, setReassignCompanyId] = useState("");
  const [reassignWeeks, setReassignWeeks] = useState("");

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

  useEffect(() => { void load(); }, [load]);

  const approvedStudents = students.filter((s) => s.hod_approval_status === "APPROVED");

  // Students whose latest proposal was rejected (internship_status reset to PENDING)
  const rejectedProposals = proposals.filter((p) => p.status === "REJECTED");
  const rejectedStudentIds = new Set(rejectedProposals.map((p) => {
    const s = students.find((st) => st.user.email === p.student.user.email);
    return s?.id;
  }));
  const studentsNeedingReassignment = approvedStudents.filter((s) => rejectedStudentIds.has(s.id));

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

  const sendReassignment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reassignStudent) return;
    setSubmitting(true);
    setError(null);
    try {
      await api.post("/hod/proposals", {
        studentId: reassignStudent.id,
        companyId: parseInt(reassignCompanyId, 10),
        expected_duration_weeks: reassignWeeks ? parseInt(reassignWeeks, 10) : undefined,
        proposal_type: "University_Initiated",
      });
      setReassignStudent(null);
      setReassignCompanyId("");
      setReassignWeeks("");
      await load();
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { error?: string } } };
      setError(ax.response?.data?.error || "Could not reassign student.");
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
          <button type="button" onClick={() => void load()} disabled={loading}
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

      {loading && students.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <>
          {/* Students needing reassignment */}
          {studentsNeedingReassignment.length > 0 && (
            <section className="rounded-2xl border border-amber-200 bg-amber-50 p-5 shadow-sm sm:p-6">
              <h2 className="text-base font-bold text-amber-900 mb-1">⚠️ Students needing reassignment</h2>
              <p className="text-sm text-amber-700 mb-4">These students were rejected by a company. Assign them to a new company.</p>
              <div className="space-y-2">
                {studentsNeedingReassignment.map((s) => (
                  <div key={s.id} className="flex items-center justify-between gap-3 rounded-xl border border-amber-200 bg-white px-4 py-3">
                    <div>
                      <p className="font-semibold text-slate-900 text-sm">{s.user.full_name}</p>
                      <p className="text-xs text-slate-500">{s.user.email}</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => { setReassignStudent(s); setReassignCompanyId(""); setReassignWeeks(""); }}
                      className="inline-flex items-center gap-1.5 rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700"
                    >
                      <RotateCcw className="h-3.5 w-3.5" />
                      Reassign
                    </button>
                  </div>
                ))}
              </div>
            </section>
          )}

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

      {/* Reassign modal */}
      {reassignStudent && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl mx-4 space-y-4">
            <h3 className="text-lg font-bold text-slate-900">Reassign student</h3>
            <p className="text-sm text-slate-500">
              Assign <strong>{reassignStudent.user.full_name}</strong> to a new company.
            </p>
            <form onSubmit={(e) => void sendReassignment(e)} className="space-y-3">
              <div>
                <label className="text-sm font-medium text-slate-700">Company</label>
                <select
                  required
                  value={reassignCompanyId}
                  onChange={(e) => setReassignCompanyId(e.target.value)}
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                >
                  <option value="">Select company…</option>
                  {companies.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-sm font-medium text-slate-700">Duration (weeks, optional)</label>
                <input
                  type="number"
                  min={1}
                  value={reassignWeeks}
                  onChange={(e) => setReassignWeeks(e.target.value)}
                  placeholder="e.g. 12"
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500"
                />
              </div>
              <div className="flex gap-3 pt-1">
                <button type="button" onClick={() => setReassignStudent(null)}
                  className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50">
                  Cancel
                </button>
                <button type="submit" disabled={submitting}
                  className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60">
                  {submitting ? "Sending…" : "Send Proposal"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

