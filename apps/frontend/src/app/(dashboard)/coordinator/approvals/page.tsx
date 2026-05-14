"use client";

import { useCallback, useEffect, useState } from "react";
import { CheckCircle, XCircle, User, Building, FileText } from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";
import api from "@/lib/api/client";
import CoordinatorPageHero from "../CoordinatorPageHero";
import { useTranslations } from "next-intl";

interface HodRecord {
  id: number;
  userId: number;
  department: string;
  university: { name: string };
  user: {
    id: number;
    full_name: string;
    email: string;
    verification_document: string | null;
    created_at: string;
    institution_access_approval: string;
  };
}

type Tab = "approved" | "rejected";

export default function CoordinatorApprovalsPage() {
  const [activeTab, setActiveTab] = useState<Tab>("approved");
  const [approved, setApproved] = useState<HodRecord[]>([]);
  const [rejected, setRejected] = useState<HodRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [rejectTarget, setRejectTarget] = useState<{ userId: number; name: string } | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const t = useTranslations("CoordinatorPortal.approvals");

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [approvedRes, rejectedRes] = await Promise.all([
        api.get<HodRecord[]>("/coordinator/approved-hods"),
        api.get<HodRecord[]>("/coordinator/rejected-hods"),
      ]);
      setApproved(approvedRes.data);
      setRejected(rejectedRes.data);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error;
      setError(msg || t("couldNotLoad"));
    } finally {
      setLoading(false);
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { void load(); }, [load]);

  const handleReject = async () => {
    if (!rejectTarget) return;
    setActionLoading(rejectTarget.userId);
    try {
      await api.patch("/coordinator/verify-hod", {
        userId: rejectTarget.userId,
        status: "REJECTED",
        reason: rejectReason.trim() || undefined,
      });
      setRejectTarget(null);
      setRejectReason("");
      setToast({ show: true, message: `HOD ${rejectTarget.name} has been rejected.` });
      void load();
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error;
      setError(msg || "Failed to reject HOD.");
    } finally {
      setActionLoading(null);
    }
  };

  const rows = activeTab === "approved" ? approved : rejected;

  return (
    <>
      <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
        <CoordinatorPageHero
          badge={t("badge")}
          title={t("title")}
          description={t("description")}
        />

        {error && (
          <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
            {error}
          </div>
        )}

        {/* Tab bar */}
        <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1">
          {(["approved", "rejected"] as Tab[]).map((tab) => {
            const isActive = activeTab === tab;
            const count = tab === "approved" ? approved.length : rejected.length;
            return (
              <button
                key={tab}
                type="button"
                onClick={() => setActiveTab(tab)}
                className={cn(
                  "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
                  isActive ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200" : "text-slate-500 hover:text-slate-700"
                )}
              >
                {tab === "approved"
                  ? <CheckCircle className="h-4 w-4 shrink-0" />
                  : <XCircle className="h-4 w-4 shrink-0" />}
                <span>{tab === "approved" ? t("tabApproved") : t("tabRejected")}</span>
                {!loading && count > 0 && (
                  <span className={cn(
                    "rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums",
                    isActive
                      ? "bg-primary-100 text-primary-800 ring-1 ring-primary-200/80"
                      : tab === "approved"
                        ? "bg-emerald-100 text-emerald-700 ring-1 ring-emerald-200/80"
                        : "bg-red-100 text-red-700 ring-1 ring-red-200/80"
                  )}>
                    {count > 99 ? "99+" : count}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        <div className="card overflow-hidden">
          {loading ? (
            <p className="p-6 text-sm text-slate-500">{t("loading")}</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead>
                  <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider">
                    <th className="px-6 py-4 font-semibold">{t("colHod")}</th>
                    <th className="px-6 py-4 font-semibold">{t("colDepartment")}</th>
                    <th className="px-6 py-4 font-semibold">{t("colDocument")}</th>
                    <th className="px-6 py-4 font-semibold">{t("colDate")}</th>
                    <th className="px-6 py-4 font-semibold">{t("colStatus")}</th>
                    {activeTab === "approved" && <th className="px-6 py-4 font-semibold text-right">Actions</th>}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200">
                  {rows.length === 0 && (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-sm text-slate-500">
                        {activeTab === "approved" ? t("noApprovedYet") : t("noRejectedYet")}
                      </td>
                    </tr>
                  )}
                  {rows.map((h) => (
                    <tr key={h.userId} className="hover:bg-slate-50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className={cn("p-2 rounded-lg", activeTab === "approved" ? "bg-emerald-50 text-emerald-600" : "bg-red-50 text-red-500")}>
                            <User className="w-4 h-4" />
                          </div>
                          <div>
                            <p className="font-semibold text-slate-900 text-sm">{h.user.full_name}</p>
                            <p className="text-xs text-slate-500">{h.user.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2 text-sm text-slate-600">
                          <Building className="w-4 h-4 text-slate-400" />
                          {h.department || <span className="italic text-slate-400">—</span>}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        {h.user.verification_document ? (
                          <a
                            href={h.user.verification_document}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1.5 text-sm text-primary-600 hover:text-primary-700 font-medium"
                          >
                            <FileText className="w-4 h-4" />
                            {t("viewDoc")}
                          </a>
                        ) : (
                          <span className="text-xs text-slate-400 italic">{t("noDocument")}</span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-500">
                        {format(new Date(h.user.created_at), "MMM d, yyyy")}
                      </td>
                      <td className="px-6 py-4">
                        {activeTab === "approved" ? (
                          <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-emerald-200">
                            <CheckCircle className="w-3 h-3" />{t("statusApproved")}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700 ring-1 ring-red-200">
                            <XCircle className="w-3 h-3" />{t("statusRejected")}
                          </span>
                        )}
                      </td>
                      {activeTab === "approved" && (
                        <td className="px-6 py-4 text-right">
                          <button
                            type="button"
                            disabled={actionLoading === h.userId}
                            onClick={() => { setRejectTarget({ userId: h.userId, name: h.user.full_name }); setRejectReason(""); }}
                            className="inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 disabled:opacity-50 transition-colors"
                          >
                            <XCircle className="w-3.5 h-3.5" />
                            Reject
                          </button>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Reject confirmation modal */}
      {rejectTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-xl dark:bg-slate-900 dark:border dark:border-slate-700 space-y-4 p-6">
            <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Reject HOD access</h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              You are about to revoke access for <span className="font-semibold text-slate-700 dark:text-slate-200">{rejectTarget.name}</span>. They will be notified.
            </p>
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400 mb-1">Reason (optional)</label>
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value.slice(0, 300))}
                maxLength={300}
                rows={3}
                placeholder="e.g. Credentials could not be verified..."
                className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-sm text-slate-900 dark:text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-400 resize-none"
              />
              <p className="mt-0.5 text-right text-xs text-slate-400">{rejectReason.length}/300</p>
            </div>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setRejectTarget(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={actionLoading !== null}
                onClick={() => void handleReject()}
                className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60 transition-colors"
              >
                {actionLoading !== null ? "Rejecting…" : "Confirm reject"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      {toast.show && (
        <div className="fixed bottom-6 right-6 z-50 rounded-xl bg-slate-900 px-4 py-3 text-sm font-medium text-white shadow-lg">
          {toast.message}
          <button type="button" onClick={() => setToast({ show: false, message: "" })} className="ml-3 text-slate-400 hover:text-white">✕</button>
        </div>
      )}
    </>
  );
}

interface HodRecord {
  id: number;
  userId: number;
  department: string;
  university: { name: string };
  user: {
    id: number;
    full_name: string;
    email: string;
    verification_document: string | null;
    created_at: string;
    institution_access_approval: string;
  };
}

type Tab = "approved" | "rejected";
