"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { Loader2, RefreshCw, ChevronLeft, ChevronRight } from "lucide-react";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodStudentApprovalsTable from "@/components/hod/HodStudentApprovalsTable";
import type { HodStudentRow } from "@/components/hod/types";
import ConfirmDialog from "@/components/shared/ConfirmDialog";
import SuccessToast from "@/components/shared/SuccessToast";
import { useHodStore } from "@/lib/store/hodStore";
import { useTranslations } from "next-intl";
import { cn } from "@/lib/utils";

type FilterStatus = "all" | "pending" | "approved" | "rejected" | "placed";

const FILTER_KEYS: FilterStatus[] = ["all", "pending", "approved", "rejected", "placed"];
const PAGE_SIZE = 7;

export default function HodStudentsPage() {
  const t = useTranslations("HodPortal.students");
  const [students, setStudents] = useState<HodStudentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [activeFilter, setActiveFilter] = useState<FilterStatus>("all");
  const [page, setPage] = useState(1);

  const [confirm, setConfirm] = useState<{ id: number; action: "approve" | "reject"; reason?: string } | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });

  // Flag modal state
  const [flagTarget, setFlagTarget] = useState<number | null>(null);
  const [flagType, setFlagType] = useState<"LOW_PERFORMANCE" | "INACTIVE">("LOW_PERFORMANCE");
  const [flagNote, setFlagNote] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: HodStudentRow[] }>("/hod/students", {
        params: { status: activeFilter },
      });
      setStudents(Array.isArray(res.data.data) ? res.data.data : []);
    } catch {
      setError(t("couldNotLoad"));
    } finally {
      setLoading(false);
    }
  }, [activeFilter]); // eslint-disable-line react-hooks/exhaustive-deps

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
          ? t("approvedToast")
          : t("rejectedToast"),
      });
      await load();
    } catch {
      setError(t("failedAction", { action: confirm.action }));
      setConfirm(null);
      setRejectReason("");
    } finally {
      setSubmitting(false);
    }
  };

  const submitFlag = async () => {
    if (!flagTarget) return;
    setSubmitting(true);
    try {
      await api.patch(`/hod/students/${flagTarget}/flag`, { flagType, note: flagNote.trim() || undefined });
      setFlagTarget(null);
      setFlagNote("");
      setToast({ show: true, message: `🚩 Student flagged as ${flagType === "LOW_PERFORMANCE" ? "Low Performance" : "Inactive"}` });
      await load();
    } catch {
      setError("Failed to flag student.");
    } finally {
      setSubmitting(false);
    }
  };

  const onUnflag = async (id: number) => {
    setSubmitting(true);
    try {
      await api.delete(`/hod/students/${id}/flag`);
      setToast({ show: true, message: "Flag removed." });
      await load();
    } catch {
      setError("Failed to unflag student.");
    } finally {
      setSubmitting(false);
    }
  };

  const onReprocess = async (id: number) => {
    setSubmitting(true);
    try {
      await api.patch(`/hod/students/${id}/reprocess`);
      setToast({ show: true, message: "✅ Student moved back to pending." });
      await load();
    } catch {
      setError("Failed to reprocess student.");
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

      {/* Filter tabs */}
      <div className="flex flex-wrap gap-2">
        {FILTER_KEYS.map((value) => (
          <button
            key={value}
            type="button"
            onClick={() => { setActiveFilter(value); setPage(1); }}
            className={cn(
              "rounded-xl px-4 py-2 text-sm font-semibold transition-colors capitalize",
              activeFilter === value
                ? "bg-primary-600 text-white shadow-sm"
                : "border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
            )}
          >
            {value}
          </button>
        ))}
      </div>

      {loading && students.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center text-slate-500">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" aria-hidden />
        </div>
      ) : (
        <>
          <HodStudentApprovalsTable
            students={students.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)}
            submitting={submitting}
            onApprove={(id) => setConfirm({ id, action: "approve" })}
            onReject={(id) => { setRejectReason(""); setConfirm({ id, action: "reject" }); }}
            onFlag={(id) => { setFlagTarget(id); setFlagType("LOW_PERFORMANCE"); setFlagNote(""); }}
            onUnflag={onUnflag}
            onReprocess={onReprocess}
          />

          {/* Pagination */}
          {students.length > 0 && (() => {
            const totalPages = Math.ceil(students.length / PAGE_SIZE);
            return (
              <div className="flex flex-col items-center gap-3 pt-2">
                <p className="text-sm text-slate-500 dark:text-slate-400">
                  Showing{" "}
                  <span className="font-semibold text-slate-700 dark:text-slate-200">
                    {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, students.length)}
                  </span>{" "}
                  of <span className="font-semibold text-slate-700 dark:text-slate-200">{students.length}</span> students
                </p>
                <div className="flex items-center gap-1">
                  <button type="button" onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1}
                    className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-2 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
                    <ChevronLeft className="h-4 w-4" />
                  </button>
                  {Array.from({ length: totalPages }, (_, i) => i + 1)
                    .filter((p) => p === 1 || p === totalPages || Math.abs(p - page) <= 1)
                    .reduce<(number | "…")[]>((acc, p, i, arr) => {
                      if (i > 0 && (p as number) - (arr[i - 1] as number) > 1) acc.push("…");
                      acc.push(p);
                      return acc;
                    }, [])
                    .map((p, i) =>
                      p === "…" ? (
                        <span key={`e-${i}`} className="px-2 text-slate-400 text-sm">…</span>
                      ) : (
                        <button key={p} type="button" onClick={() => setPage(p as number)}
                          className={cn("min-w-[2rem] rounded-xl border px-3 py-1.5 text-sm font-medium transition-all",
                            page === p
                              ? "border-primary-600 bg-primary-600 text-white shadow-sm"
                              : "border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800"
                          )}>
                          {p}
                        </button>
                      )
                    )}
                  <button type="button" onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages}
                    className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-2 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors">
                    <ChevronRight className="h-4 w-4" />
                  </button>
                </div>
              </div>
            );
          })()}
        </>
      )}

      <ConfirmDialog
        open={!!confirm}
        title={confirm?.action === "approve" ? t("approveTitle") : t("rejectTitle")}
        message={confirm?.action === "approve" ? t("approveMessage") : t("rejectMessage")}
        confirmLabel={confirm?.action === "approve" ? t("approveLabel") : t("rejectLabel")}
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

      {/* Flag modal */}
      {flagTarget !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-2xl dark:bg-slate-900 dark:border dark:border-slate-700">
            <div className="flex items-center justify-between px-5 pt-5 pb-3 border-b border-slate-100 dark:border-slate-700">
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Flag student</h3>
              <button type="button" onClick={() => setFlagTarget(null)} className="rounded-lg p-1 hover:bg-slate-100 dark:hover:bg-slate-800">
                <span className="sr-only">Close</span>
                <svg className="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
              </button>
            </div>
            <div className="px-5 py-4 space-y-4">
              <div className="space-y-2">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Flag type</p>
                {(["LOW_PERFORMANCE", "INACTIVE"] as const).map((type) => (
                  <label key={type} className="flex items-center gap-3 cursor-pointer rounded-xl border border-slate-200 px-3 py-2.5 hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800">
                    <input
                      type="radio"
                      name="flagType"
                      value={type}
                      checked={flagType === type}
                      onChange={() => setFlagType(type)}
                      className="accent-amber-500"
                    />
                    <span className="text-sm font-medium text-slate-800 dark:text-slate-200">
                      {type === "LOW_PERFORMANCE" ? "Low Performance" : "Inactive"}
                    </span>
                  </label>
                ))}
              </div>
              <div>
                <label className="block text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400 mb-1">Note (optional)</label>
                <textarea
                  value={flagNote}
                  onChange={(e) => setFlagNote(e.target.value.slice(0, 300))}
                  maxLength={300}
                  rows={2}
                  placeholder="Add context for this flag..."
                  className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
                />
                <p className="mt-0.5 text-right text-xs text-slate-400">{flagNote.length}/300</p>
              </div>
            </div>
            <div className="flex gap-3 px-5 pb-5">
              <button type="button" onClick={() => setFlagTarget(null)}
                className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
                Cancel
              </button>
              <button type="button" disabled={submitting} onClick={() => void submitFlag()}
                className="flex-1 rounded-xl bg-amber-500 py-2.5 text-sm font-semibold text-white hover:bg-amber-600 disabled:opacity-60">
                {submitting ? "Flagging…" : "Flag student"}
              </button>
            </div>
          </div>
        </div>
      )}

      <SuccessToast
        show={toast.show}
        message={toast.message}
        onClose={() => setToast({ show: false, message: "" })}
      />
    </div>
  );
}
