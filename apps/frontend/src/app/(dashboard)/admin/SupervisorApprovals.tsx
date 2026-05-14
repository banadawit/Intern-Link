"use client";

import React, { useCallback, useEffect, useState } from "react";
import { CheckCircle, XCircle, FileText, User, Building, Loader2 } from "lucide-react";
import { format } from "date-fns";
import api from "@/lib/api/client";
import { useTranslations } from "@/components/i18n/I18nProvider";
import AdminPageHero from "./AdminPageHero";
import ConfirmDialog from "@/components/shared/ConfirmDialog";
import SuccessToast from "@/components/shared/SuccessToast";
import PdfViewerModal from "@/components/shared/PdfViewerModal";

interface PendingSupervisor {
  id: number;
  userId: number;
  company: { id: number; name: string };
  user: {
    id: number;
    full_name: string;
    email: string;
    verification_document: string | null;
    created_at: string;
    institution_access_approval: string;
  };
}

interface Props {
  onActionComplete?: () => void;
  hideHero?: boolean;
}

const SupervisorApprovals = ({ onActionComplete, hideHero = false }: Props) => {
  const t = useTranslations("AdminPortal.supervisorApprovals");
  const ta = useTranslations("AdminPortal.approvals");
  const tc = useTranslations("Common");
  const [supervisors, setSupervisors] = useState<PendingSupervisor[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<number | null>(null);
  const [rejectReason, setRejectReason] = useState<{ userId: number; reason: string } | null>(null);
  const [confirmApprove, setConfirmApprove] = useState<number | null>(null);
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [documentViewedUserIds, setDocumentViewedUserIds] = useState<Set<number>>(() => new Set());

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get<PendingSupervisor[]>("/admin/pending-supervisors");
      setSupervisors(data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const handleApprove = async (userId: number) => {
    setActionLoading(userId);
    try {
      await api.post(`/admin/supervisors/${userId}/approve`);
      setConfirmApprove(null);
      setToast({ show: true, message: ta("toastApprovedSup") });
      await load();
      onActionComplete?.();
    } catch (e) {
      console.error(e);
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async () => {
    if (!rejectReason) return;
    setActionLoading(rejectReason.userId);
    try {
      await api.post(`/admin/supervisors/${rejectReason.userId}/reject`, { reason: rejectReason.reason });
      setRejectReason(null);
      setToast({ show: true, message: t("toastRejected") });
      await load();
      onActionComplete?.();
    } catch (e) {
      console.error(e);
    } finally {
      setActionLoading(null);
    }
  };


  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      {!hideHero && (
        <AdminPageHero
          badge={ta("tabs.supervisors.label")}
          title={ta("tabs.supervisors.title")}
          description={ta("tabs.supervisors.description")}
        />
      )}

      {loading && (
        <p className="text-sm text-slate-500" role="status">{t("loadingPending")}</p>
      )}

      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider dark:bg-slate-800 dark:text-slate-400">
                <th className="px-6 py-4 font-semibold">{t("tableSupervisor")}</th>
                <th className="px-6 py-4 font-semibold">{t("tableCompany")}</th>
                <th className="px-6 py-4 font-semibold">{t("tableDocument")}</th>
                <th className="px-6 py-4 font-semibold">{t("tableSubmitted")}</th>
                <th className="px-6 py-4 font-semibold text-right">{t("tableActions")}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
              {supervisors.map((s) => (
                <tr key={s.userId} className="hover:bg-slate-50 transition-colors dark:hover:bg-slate-800/50">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300">
                        <User className="w-5 h-5" />
                      </div>
                      <div>
                        <p className="font-semibold text-slate-900 dark:text-slate-100">{s.user.full_name}</p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">{s.user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2 text-sm text-slate-700 dark:text-slate-300">
                      <Building className="w-4 h-4 text-slate-400" />
                      {s.company.name}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    {s.user.verification_document ? (
                      <a
                        href={s.user.verification_document}
                        target="_blank"
                        rel="noopener noreferrer"
                        onClick={() => setDocumentViewedUserIds((prev) => new Set(prev).add(s.userId))}
                        className="inline-flex items-center gap-1.5 text-sm text-primary-600 hover:text-primary-700 font-medium"
                      >
                        <FileText className="w-4 h-4" />
                        {ta("viewDoc")}
                      </a>
                    ) : (
                      <span className="text-xs text-slate-400 italic">{ta("noDocument")}</span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">
                    {format(new Date(s.user.created_at), "MMM d, yyyy")}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => setConfirmApprove(s.userId)}
                        disabled={
                          actionLoading === s.userId ||
                          !s.user.verification_document ||
                          !documentViewedUserIds.has(s.userId)
                        }
                        title={
                          !s.user.verification_document
                            ? ta("titleApproveNoDoc")
                            : !documentViewedUserIds.has(s.userId)
                              ? ta("titleOpenDocBeforeApprove")
                              : undefined
                        }
                        className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-60 transition-colors"
                      >
                        {actionLoading === s.userId ? (
                          <Loader2 className="w-3.5 h-3.5 animate-spin" />
                        ) : (
                          <CheckCircle className="w-3.5 h-3.5" />
                        )}
                        {ta("approve")}
                      </button>
                      <button
                        onClick={() => setRejectReason({ userId: s.userId, reason: '' })}
                        disabled={
                          actionLoading === s.userId ||
                          (!!s.user.verification_document && !documentViewedUserIds.has(s.userId))
                        }
                        title={
                          s.user.verification_document && !documentViewedUserIds.has(s.userId)
                            ? ta("titleOpenDocBeforeReject")
                            : undefined
                        }
                        className="inline-flex items-center gap-1.5 rounded-lg bg-red-50 border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 disabled:opacity-60 transition-colors"
                      >
                        <XCircle className="w-3.5 h-3.5" />
                        {ta("reject")}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {!loading && supervisors.length === 0 && (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-500 dark:text-slate-400">
                    {t("emptyList")}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {rejectReason && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-2xl shadow-xl p-6 w-full max-w-md mx-4 space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">{t("rejectTitle")}</h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">{t("rejectLead")}</p>
            <textarea
              value={rejectReason.reason}
              onChange={(e) => setRejectReason({ ...rejectReason, reason: e.target.value })}
              placeholder={ta("rejectPlaceholder")}
              rows={3}
              className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-4 py-3 text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-400 resize-none"
            />
            <div className="flex gap-3 pt-1">
              <button
                onClick={() => setRejectReason(null)}
                className="flex-1 rounded-xl border border-slate-200 dark:border-slate-700 py-2.5 text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
              >
                {tc("cancel")}
              </button>
              <button
                onClick={handleReject}
                disabled={actionLoading !== null}
                className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60 transition-colors"
              >
                {actionLoading !== null ? ta("rejecting") : ta("confirmReject")}
              </button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={confirmApprove !== null}
        title={t("approveTitle")}
        message={t("approveMessage")}
        confirmLabel={t("approveLabel")}
        variant="success"
        loading={actionLoading !== null}
        onConfirm={() => confirmApprove !== null && void handleApprove(confirmApprove)}
        onCancel={() => setConfirmApprove(null)}
      />

      <SuccessToast
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ show: false, message: "" })}
      />
    </div>
  );
};

export default SupervisorApprovals;
