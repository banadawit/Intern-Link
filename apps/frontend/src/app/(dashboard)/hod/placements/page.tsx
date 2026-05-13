"use client";

import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import api from "@/lib/api/client";
import { Loader2, RefreshCw, RotateCcw, CheckCircle2, Send, ClipboardList } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodSendProposalForm from "@/components/hod/HodSendProposalForm";
import HodProposalTrackerTable from "@/components/hod/HodProposalTrackerTable";
import SuccessToast from "@/components/shared/SuccessToast";
import type { HodCompanyRow, HodProposalRow, HodStudentRow } from "@/components/hod/types";
import { useTranslations } from "next-intl";
import { cn } from "@/lib/utils";

type Tab = "send" | "tracker" | "placed";

export default function HodPlacementsPage() {
  const t = useTranslations("HodPortal.placements");
  const searchParams = useSearchParams();
  const [students, setStudents] = useState<HodStudentRow[]>([]);
  const [companies, setCompanies] = useState<HodCompanyRow[]>([]);
  const [proposals, setProposals] = useState<HodProposalRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [selectedStudentIds, setSelectedStudentIds] = useState<Set<number>>(new Set());
  const [proposalCompanyId, setProposalCompanyId] = useState(searchParams.get("companyId") ?? "");
  const [proposalWeeks, setProposalWeeks] = useState("");
  const [proposalOutcomes, setProposalOutcomes] = useState("");
  const [activeTab, setActiveTab] = useState<Tab>("send");
  const [reassignStudent, setReassignStudent] = useState<HodStudentRow | null>(null);
  const [reassignCompanyId, setReassignCompanyId] = useState("");
  const [reassignWeeks, setReassignWeeks] = useState("");
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [stud, comp, prop] = await Promise.all([
        api.get<{ success: boolean; data: HodStudentRow[] }>("/hod/students", { params: { status: "all" } }),
        api.get<{ success: boolean; data: HodCompanyRow[] }>("/hod/companies", { params: { verifiedOnly: true } }),
        api.get<{ success: boolean; data: HodProposalRow[] }>("/hod/proposals"),
      ]);
      setStudents(Array.isArray(stud.data.data) ? stud.data.data : []);
      setCompanies(Array.isArray(comp.data.data) ? comp.data.data : []);
      setProposals(Array.isArray(prop.data.data) ? prop.data.data : []);
    } catch {
      setError(t("couldNotLoad"));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const approvedStudents = students.filter(
    (s) => s.hod_approval_status === "APPROVED" && s.internship_status !== "PLACED"
  );

  const placedStudents = students
    .filter((s) => s.internship_status === "PLACED")
    .map((s) => {
      const proposal = proposals.find((p) => p.status === "APPROVED" && p.student.user.email === s.user.email);
      return { ...s, companyName: proposal?.company.name ?? null };
    });

  const assignedStudentIds = new Set(
    proposals
      .filter((p) => p.status === "PENDING" || p.status === "APPROVED")
      .map((p) => { const s = students.find((st) => st.user.email === p.student.user.email); return s?.id; })
      .filter((id): id is number => id !== undefined)
  );

  const availableStudents = approvedStudents.filter((s) => !assignedStudentIds.has(s.id));

  const rejectedStudentIds = new Set(
    proposals.filter((p) => p.status === "REJECTED")
      .map((p) => { const s = students.find((st) => st.user.email === p.student.user.email); return s?.id; })
  );
  const studentsNeedingReassignment = approvedStudents.filter((s) => rejectedStudentIds.has(s.id));

  const sendProposal = async (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedStudentIds.size === 0 || !proposalCompanyId) return;
    setSubmitting(true);
    setError(null);
    try {
      const ids = Array.from(selectedStudentIds);
      for (const studentId of ids) {
        await api.post("/hod/proposals", {
          studentId,
          companyId: parseInt(proposalCompanyId, 10),
          expected_duration_weeks: proposalWeeks ? parseInt(proposalWeeks, 10) : undefined,
          expected_outcomes: proposalOutcomes || undefined,
          proposal_type: "University_Initiated",
        });
      }
      setSelectedStudentIds(new Set());
      setProposalCompanyId("");
      setProposalWeeks("");
      setProposalOutcomes("");
      setToast({
        show: true,
        message: ids.length > 1
          ? t("proposalsSentMultiple", { count: ids.length })
          : t("proposalSentOne"),
      });
      await load();
      setActiveTab("tracker");
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { message?: string; error?: string } } };
      setError(ax.response?.data?.message ?? ax.response?.data?.error ?? t("couldNotSend"));
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
      setToast({ show: true, message: t("reassignedToast") });
      await load();
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { error?: string } } };
      setError(ax.response?.data?.error || t("couldNotReassign"));
    } finally {
      setSubmitting(false);
    }
  };

  const pendingCount = proposals.filter((p) => p.status === "PENDING").length;

  const tabs: { id: Tab; label: string; icon: React.ComponentType<{ className?: string }>; badge?: number }[] = [
    { id: "send", label: "Send proposal", icon: Send },
    { id: "tracker", label: "Proposal tracker", icon: ClipboardList, badge: pendingCount || undefined },
    { id: "placed", label: "Placed students", icon: CheckCircle2, badge: placedStudents.length || undefined },
  ];

  return (
    <div className="space-y-6 pb-8">
      <HodPageHero
        badge={t("badge")}
        title={t("title")}
        description={t("description")}
        action={
          <button type="button" onClick={() => void load()} disabled={loading}
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

      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1 dark:border-slate-700 dark:bg-slate-800/50">
        {tabs.map((tab) => (
          <button key={tab.id} type="button" onClick={() => setActiveTab(tab.id)}
            className={cn(
              "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition-all",
              activeTab === tab.id
                ? "bg-white text-slate-900 shadow-sm dark:bg-slate-900 dark:text-slate-100"
                : "text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
            )}
          >
            <tab.icon className="h-4 w-4 shrink-0" />
            <span className="hidden sm:inline">{tab.label}</span>
            {tab.badge !== undefined && tab.badge > 0 && (
              <span className={cn("rounded-full px-1.5 py-0.5 text-[10px] font-bold",
                activeTab === tab.id ? "bg-primary-100 text-primary-700" : "bg-slate-200 text-slate-600 dark:bg-slate-700 dark:text-slate-300"
              )}>{tab.badge}</span>
            )}
          </button>
        ))}
      </div>

      {loading && students.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" />
        </div>
      ) : (
        <>
          {activeTab === "send" && (
            <div className="space-y-6">
              {/* Students needing reassignment */}
              {studentsNeedingReassignment.length > 0 && (
                <section className="rounded-2xl border border-amber-200 bg-amber-50 p-5 shadow-sm sm:p-6 dark:border-amber-900/50 dark:bg-amber-900/20">
                  <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">{t("needsReassignment")}</h3>
                  <p className="text-sm text-amber-700 mb-4 dark:text-amber-300">{t("needsReassignmentDesc")}</p>
                  <div className="space-y-2">
                    {studentsNeedingReassignment.map((s) => (
                      <div key={s.id} className="flex items-center justify-between gap-3 rounded-xl border border-amber-200 bg-white px-4 py-3 dark:border-amber-900/50 dark:bg-slate-900">
                        <div>
                          <p className="font-semibold text-slate-900 text-sm dark:text-slate-100">{s.user.full_name}</p>
                          <p className="text-xs text-slate-500 dark:text-slate-400">{s.user.email}</p>
                        </div>
                        <button
                          type="button"
                          onClick={() => { setReassignStudent(s); setReassignCompanyId(""); setReassignWeeks(""); }}
                          className="inline-flex items-center gap-1.5 rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700"
                        >
                          <RotateCcw className="h-3.5 w-3.5" />
                          {t("reassign")}
                        </button>
                      </div>
                    ))}
                  </div>
                </section>
              )}
              <HodSendProposalForm
                approvedStudents={availableStudents}
                companies={companies}
                submitting={submitting}
                selectedStudentIds={selectedStudentIds}
                proposalCompanyId={proposalCompanyId}
                proposalWeeks={proposalWeeks}
                proposalOutcomes={proposalOutcomes}
                onStudentIds={setSelectedStudentIds}
                onCompanyId={setProposalCompanyId}
                onWeeks={setProposalWeeks}
                onOutcomes={setProposalOutcomes}
                onSubmit={sendProposal}
              />
            </div>
          )}

          {activeTab === "tracker" && <HodProposalTrackerTable proposals={proposals} />}

          {activeTab === "placed" && (
            placedStudents.length === 0 ? (
              <div className="flex flex-col items-center justify-center rounded-2xl border-2 border-dashed border-slate-200 bg-white py-16 text-center dark:border-slate-700 dark:bg-slate-900">
                <CheckCircle2 className="h-10 w-10 text-slate-300 mb-3" />
                <p className="text-base font-semibold text-slate-600 dark:text-slate-300">No placed students yet</p>
              </div>
            ) : (
              <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 shadow-sm sm:p-6 dark:border-emerald-900/50 dark:bg-emerald-900/10">
                <div className="flex items-center gap-2 mb-4">
                  <CheckCircle2 className="h-5 w-5 text-emerald-600 dark:text-emerald-400" />
                  <h2 className="text-base font-bold text-emerald-900 dark:text-emerald-200">
                    {t("placedStudents", { count: placedStudents.length })}
                  </h2>
                </div>
                <div className="space-y-2">
                  {placedStudents.map((s) => (
                    <div key={s.id} className="flex items-center justify-between gap-3 rounded-xl border border-emerald-200 bg-white px-4 py-3 dark:border-emerald-900/50 dark:bg-slate-900">
                      <div>
                        <p className="font-semibold text-slate-900 text-sm dark:text-slate-100">{s.user.full_name}</p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">{s.user.email}</p>
                      </div>
                      <div className="text-right shrink-0">
                        {s.companyName && (
                          <p className="text-sm font-medium text-emerald-700 dark:text-emerald-400">{s.companyName}</p>
                        )}
                        <span className="inline-block rounded-full bg-emerald-100 px-2.5 py-0.5 text-[11px] font-semibold text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300">
                          {t("placed")}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )
          )}
        </>
      )}

      {reassignStudent && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl mx-4 space-y-4 dark:bg-slate-900 dark:border dark:border-slate-700">
            <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">{t("reassignTitle")}</h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              {t("reassignDesc", { name: reassignStudent.user.full_name })}
            </p>
            <form onSubmit={(e) => void sendReassignment(e)} className="space-y-3">
              <div>
                <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t("selectCompany").replace("…","")}</label>
                <select required value={reassignCompanyId} onChange={(e) => setReassignCompanyId(e.target.value)}
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100">
                  <option value="">{t("selectCompany")}</option>
                  {companies.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t("durationLabel")}</label>
                <input type="number" min={1} value={reassignWeeks} onChange={(e) => setReassignWeeks(e.target.value)}
                  placeholder="e.g. 12"
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100" />
              </div>
              <div className="flex gap-3 pt-1">
                <button type="button" onClick={() => setReassignStudent(null)}
                  className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800">
                  {t("cancel")}
                </button>
                <button type="submit" disabled={submitting}
                  className="flex-1 rounded-xl bg-primary-600 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-60">
                  {submitting ? t("sending") : t("sendProposal")}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <SuccessToast show={toast.show} message={toast.message} onClose={() => setToast({ show: false, message: "" })} />
    </div>
  );
}
