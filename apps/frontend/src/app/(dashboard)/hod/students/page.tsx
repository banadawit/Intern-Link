"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodStudentApprovalsTable from "@/components/hod/HodStudentApprovalsTable";
import type { HodStudentRow } from "@/components/hod/types";
import ConfirmDialog from "@/components/shared/ConfirmDialog";
import SuccessToast from "@/components/shared/SuccessToast";
import { cn } from "@/lib/utils";

type FilterStatus = "all" | "pending" | "approved" | "rejected" | "placed";

const FILTER_TABS: { label: string; value: FilterStatus }[] = [
  { label: "All", value: "all" },
  { label: "Pending", value: "pending" },
  { label: "Approved", value: "approved" },
  { label: "Rejected", value: "rejected" },
  { label: "Placed", value: "placed" },
];

export default function HodStudentsPage() {
  const [students, setStudents] = useState<HodStudentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [activeFilter, setActiveFilter] = useState<FilterStatus>("all");

  const [confirm, setConfirm] = useState<{ id: number; action: "approve" | "reject"; reason?: string } | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: HodStudentRow[] }>("/hod/students", {
        params: { status: activeFilter },
      });
      setStudents(Array.isArray(res.data.data) ? res.data.data : []);
    } catch {
      setError("Could not load students.");
    } finally {
      setLoading(false);
    }
  }, [activeFilter]);

  useEffect(() => { void load(); }, [load]);

  const actOnStudent = async () => {
    if (!confirm) return;
    setSubmitting(true);
    try {
      if (confirm.action === "reject") {
        await api.patch(`/hod/students/${confirm.id}/reject`, {
          reason: rejectReason.trim() || undefined,
        });
      } else {
        await api.patch(`/hod/students/${confirm.id}/approve`);
      }
      setConfirm(null);
      setRejectReason("");
      setToast({
        show: true,
        message: confirm.action === "approve"
          ? "✅ Student approved successfully"
          : "Student registration rejected",
      });
      await load();
    } catch {
      setError(`Failed to ${confirm.action} student.`);
      setConfirm(null);
      setRejectReason("");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 pb-8">
      <HodPageHero
        badge="Student approvals"
        title="Student approvals"
        description="Approve or reject student registrations in your department."
        action={
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex w-full shrink-0 items-center justify-center gap-2 rounded-xl border border-border-default bg-white/90 px-4 py-3 text-sm font-medium text-slate-800 shadow-sm backdrop-blur-sm transition-colors hover:bg-white disabled:opacity-60 sm:w-auto dark:bg-slate-900/90 dark:text-slate-100 dark:hover:bg-slate-900"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} aria-hidden />
            Refresh
          </button>
        }
      />

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">{error}</div>
      )}

      {/* Filter tabs */}
      <div className="flex flex-wrap gap-2">
        {FILTER_TABS.map((tab) => (
          <button
            key={tab.value}
            type="button"
            onClick={() => setActiveFilter(tab.value)}
            className={cn(
              "rounded-xl px-4 py-2 text-sm font-semibold transition-colors",
              activeFilter === tab.value
                ? "bg-primary-600 text-white shadow-sm"
                : "border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {loading && students.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <HodStudentApprovalsTable
          students={students}
          submitting={submitting}
          onApprove={(id) => setConfirm({ id, action: "approve" })}
          onReject={(id) => { setRejectReason(""); setConfirm({ id, action: "reject" }); }}
        />
      )}

      <ConfirmDialog
        open={!!confirm}
        title={confirm?.action === "approve" ? "Approve student?" : "Reject student?"}
        message={
          confirm?.action === "approve"
            ? "This will grant the student access to InternLink features. You can review their profile before confirming."
            : "This will reject the student's registration. Optionally provide a reason — it will be included in their notification email."
        }
        confirmLabel={confirm?.action === "approve" ? "Approve" : "Reject"}
        variant={confirm?.action === "approve" ? "success" : "danger"}
        loading={submitting}
        onConfirm={() => void actOnStudent()}
        onCancel={() => { setConfirm(null); setRejectReason(""); }}
        extra={
          confirm?.action === "reject" ? (
            <div className="mt-3">
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1">
                Reason (optional)
              </label>
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value.slice(0, 300))}
                maxLength={300}
                rows={3}
                placeholder="e.g. Missing required documents..."
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100 dark:placeholder-slate-500"
              />
              <p className="mt-1 text-right text-xs text-slate-400">{rejectReason.length}/300</p>
            </div>
          ) : undefined
        }
      />

      <SuccessToast
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ show: false, message: "" })}
      />
    </div>
  );
}
