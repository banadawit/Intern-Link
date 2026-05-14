"use client";

import { useCallback, useEffect, useState } from "react";
import { Loader2, RefreshCw } from "lucide-react";
import api from "@/lib/api/client";
import CoordinatorPageHero from "../CoordinatorPageHero";
import { useTranslations } from "next-intl";

type ProposalRow = {
  id: number;
  status: string;
  proposal_type: string;
  submitted_at: string;
  student: { user: { full_name: string; email: string } };
  company: { id: number; name: string; official_email: string; approval_status: string };
};

type AssignmentRow = {
  id: number;
  status: string;
  start_date: string;
  end_date: string | null;
  student: { department: string | null; user: { full_name: string; email: string } };
  company: { id: number; name: string; official_email: string };
};

export default function CoordinatorPlacementsPage() {
  const [proposals, setProposals] = useState<ProposalRow[]>([]);
  const [assignments, setAssignments] = useState<AssignmentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const t = useTranslations("CoordinatorPortal.placements");

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [p, a] = await Promise.all([
        api.get<ProposalRow[]>("/coordinator-portal/proposals/overview"),
        api.get<AssignmentRow[]>("/coordinator-portal/assignments/overview"),
      ]);
      setProposals(p.data);
      setAssignments(a.data);
    } catch {
      setError(t("couldNotLoad"));
      setProposals([]);
      setAssignments([]);
    } finally {
      setLoading(false);
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <div className="space-y-8 pb-8">
      <CoordinatorPageHero
        badge={t("badge")}
        title={t("title")}
        description={t("description")}
        action={
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white disabled:opacity-60 sm:w-auto"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} aria-hidden />
            {t("refresh")}
          </button>
        }
      />

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{error}</div>
      )}

      {loading && proposals.length === 0 && assignments.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <>
          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <h2 className="text-lg font-bold text-slate-900">{t("proposalsTitle")}</h2>
            <p className="mb-4 text-sm text-slate-500">{t("proposalsSubtitle")}</p>
            <div className="overflow-x-auto rounded-xl border border-slate-100">
              <table className="w-full min-w-[720px] text-sm">
                <thead className="border-b border-slate-100 bg-slate-50/80">
                  <tr>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colStudent")}</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colCompany")}</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colType")}</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colStatus")}</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colSubmitted")}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {proposals.map((p) => (
                    <tr key={p.id} className="hover:bg-slate-50/50">
                      <td className="px-4 py-3 text-slate-900">{p.student.user.full_name}</td>
                      <td className="px-4 py-3 text-slate-700">{p.company.name}</td>
                      <td className="px-4 py-3 text-slate-600">{p.proposal_type}</td>
                      <td className="px-4 py-3 text-slate-700">{p.status}</td>
                      <td className="px-4 py-3 text-slate-500">
                        {new Date(p.submitted_at).toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {proposals.length === 0 && (
                <p className="py-8 text-center text-sm text-slate-500">{t("noProposals")}</p>
              )}
            </div>
          </section>

          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <h2 className="text-lg font-bold text-slate-900">{t("assignmentsTitle")}</h2>
            <p className="mb-4 text-sm text-slate-500">{t("assignmentsSubtitle")}</p>
            <div className="overflow-x-auto rounded-xl border border-slate-100">
              <table className="w-full min-w-[720px] text-sm">
                <thead className="border-b border-slate-100 bg-slate-50/80">
                  <tr>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colStudent")}</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colDept")}</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colCompany")}</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colStatus")}</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">{t("colStart")}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {assignments.map((a) => (
                    <tr key={a.id} className="hover:bg-slate-50/50">
                      <td className="px-4 py-3 text-slate-900">{a.student.user.full_name}</td>
                      <td className="px-4 py-3 text-slate-600">{a.student.department ?? "—"}</td>
                      <td className="px-4 py-3 text-slate-700">{a.company.name}</td>
                      <td className="px-4 py-3 text-slate-700">{a.status}</td>
                      <td className="px-4 py-3 text-slate-500">
                        {new Date(a.start_date).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {assignments.length === 0 && (
                <p className="py-8 text-center text-sm text-slate-500">{t("noAssignments")}</p>
              )}
            </div>
          </section>
        </>
      )}
    </div>
  );
}
