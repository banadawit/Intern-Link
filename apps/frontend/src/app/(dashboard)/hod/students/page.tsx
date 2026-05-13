"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodStudentApprovalsTable from "@/components/hod/HodStudentApprovalsTable";
import type { HodStudentRow } from "@/components/hod/types";
import ConfirmDialog from "@/components/shared/ConfirmDialog";
import SuccessToast from "@/components/shared/SuccessToast";
import { useHodStore } from "@/lib/store/hodStore";
import { useTranslations } from "next-intl";

export default function HodStudentsPage() {
  const t = useTranslations("HodPortal.students");
  const [students, setStudents] = useState<HodStudentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Confirm dialog state
  const [confirm, setConfirm] = useState<{ id: number; action: "approve" | "reject" } | null>(null);
  // Success toast state
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: HodStudentRow[] }>("/hod/students", { params: { status: "all" } });
      setStudents(Array.isArray(res.data.data) ? res.data.data : []);
    } catch {
      setError(t("couldNotLoad"));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const actOnStudent = async () => {
    if (!confirm) return;
    setSubmitting(true);
    try {
      await api.patch(`/hod/students/${confirm.id}/${confirm.action}`);
      setConfirm(null);
      setToast({
        show: true,
        message: confirm.action === "approve"
          ? t("approvedToast")
          : t("rejectedToast"),
      });
      await load();
    } catch {
      setError(t("failedAction", { action: confirm.action }));
      setConfirm(null);
    } finally {
      setSubmitting(false);
    }
  };

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

      {loading && students.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <HodStudentApprovalsTable
          students={students}
          submitting={submitting}
          onApprove={(id) => setConfirm({ id, action: "approve" })}
          onReject={(id) => setConfirm({ id, action: "reject" })}
        />
      )}

      <ConfirmDialog
        open={!!confirm}
        title={confirm?.action === "approve" ? t("approveTitle") : t("rejectTitle")}
        message={confirm?.action === "approve" ? t("approveMessage") : t("rejectMessage")}
        confirmLabel={confirm?.action === "approve" ? t("approve") : t("reject")}
        variant={confirm?.action === "approve" ? "success" : "danger"}
        loading={submitting}
        onConfirm={() => void actOnStudent()}
        onCancel={() => setConfirm(null)}
      />

      <SuccessToast
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ show: false, message: "" })}
      />
    </div>
  );
}
