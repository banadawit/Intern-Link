"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import api from "@/lib/api/client";
import { AlertCircle, X } from "lucide-react";
import { getFileUrl } from "@/lib/utils";

type WeeklyPlanRow = {
  id: number;
  week_number: number;
  plan_description: string;
  status: string;
  submitted_at: string;
  feedback: string | null;
  student: {
    user: { full_name: string; email: string };
    university: { name: string };
  };
  presentation: { file_url: string } | null;
};

export default function SupervisorPlansPage() {
  const [rows, setRows] = useState<WeeklyPlanRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<"PENDING" | "ALL">("PENDING");
  const [selected, setSelected] = useState<WeeklyPlanRow | null>(null);
  const [remarks, setRemarks] = useState("");
  const [attendance, setAttendance] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const q = filter === "PENDING" ? "?status=PENDING" : "";
      const res = await api.get<{ success: boolean; data: WeeklyPlanRow[] }>(`/supervisor/weekly-plans${q}`);
      setRows(Array.isArray(res.data.data) ? res.data.data : []);
    } catch {
      setError("Could not load weekly plans.");
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    void load();
  }, [load]);

  const review = async (status: "APPROVED" | "REJECTED") => {
    if (!selected) return;
    setSubmitting(true);
    try {
      await api.patch(`/progress/review/${selected.id}`, {
        status,
        remarks: remarks.trim() || undefined,
        attendance: status === "APPROVED" ? attendance : undefined,
      });
      setSelected(null);
      setRemarks("");
      await load();
    } catch {
      setError("Failed to submit review.");
    } finally {
      setSubmitting(false);
    }
  };

  const open = (p: WeeklyPlanRow) => {
    setSelected(p);
    setRemarks("");
    setAttendance(true);
  };

  function statusBadge(status: string) {
    if (status === "APPROVED") return "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-300";
    if (status === "REJECTED") return "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300";
    return "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300";
  }

  function statusLabel(status: string) {
    if (status === "RESUBMITTED") return "PENDING (Resubmitted)";
    return status;
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-slate-100">Weekly plans</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            Review and approve student weekly plans for your company.
          </p>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setFilter("PENDING")}
            className={`rounded-xl px-4 py-2 text-sm font-semibold ${
              filter === "PENDING"
                ? "bg-primary-600 text-white"
                : "border border-slate-200 bg-white text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"
            }`}
          >
            Pending
          </button>
          <button
            type="button"
            onClick={() => setFilter("ALL")}
            className={`rounded-xl px-4 py-2 text-sm font-semibold ${
              filter === "ALL"
                ? "bg-primary-600 text-white"
                : "border border-slate-200 bg-white text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"
            }`}
          >
            All
          </button>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-900">
        {loading ? (
          <p className="p-8 text-center text-slate-500 dark:text-slate-400">Loading…</p>
        ) : rows.length === 0 ? (
          <p className="p-8 text-center text-slate-500 dark:text-slate-400">No plans in this view.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/70">
                <tr>
                  <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Week</th>
                  <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Student</th>
                  <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Status</th>
                  <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                {rows.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                    <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">Week {p.week_number}</td>
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-900 dark:text-slate-100">{p.student.user.full_name}</p>
                      <p className="text-xs text-slate-500 dark:text-slate-400">{p.student.university.name}</p>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(p.status)}`}>
                        {statusLabel(p.status)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => open(p)}
                        className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700"
                      >
                        View / review
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Review modal */}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <button
            type="button"
            className="absolute inset-0 bg-slate-900/40"
            aria-label="Close"
            onClick={() => setSelected(null)}
          />
          <div className="relative z-10 max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-slate-200 bg-white shadow-xl dark:border-slate-700 dark:bg-slate-900">

            {/* Header */}
            <div className="flex items-start justify-between gap-4 border-b border-slate-100 dark:border-slate-700 px-6 py-5">
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">
                    Week {selected.week_number}
                  </h2>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-bold ${statusBadge(selected.status)}`}>
                    {statusLabel(selected.status)}
                  </span>
                </div>
                <p className="mt-1 text-sm font-semibold text-slate-700 dark:text-slate-200">{selected.student.user.full_name}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  {selected.student.university.name} · Submitted {new Date(selected.submitted_at).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" })}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setSelected(null)}
                className="shrink-0 rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:text-slate-500 dark:hover:bg-slate-800"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Body */}
            <div className="space-y-4 px-6 py-5">

              {/* Plan content box */}
              <div>
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Student&apos;s Plan</p>
                <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/60 px-4 py-4">
                  <p className="text-sm text-slate-800 dark:text-slate-200 whitespace-pre-wrap leading-relaxed">{selected.plan_description}</p>
                </div>
              </div>

              {/* Presentation */}
              {selected.presentation?.file_url && (
                <div>
                  <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Presentation</p>
                  <a
                    href={getFileUrl(selected.presentation.file_url)}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 rounded-xl border border-primary-200 bg-primary-50 px-4 py-2.5 text-sm font-semibold text-primary-700 hover:bg-primary-100 transition-colors dark:border-primary-800 dark:bg-primary-900/20 dark:text-primary-300"
                  >
                    Open presentation file
                  </a>
                </div>
              )}

              {/* Previous feedback for reviewed plans */}
              {selected.status !== "PENDING" && selected.status !== "RESUBMITTED" && selected.feedback && (
                <div>
                  <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">Supervisor Feedback</p>
                  <div className={`rounded-xl border px-4 py-3 text-sm ${
                    selected.status === "APPROVED"
                      ? "border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-200"
                      : "border-red-200 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200"
                  }`}>
                    {selected.feedback}
                  </div>
                </div>
              )}

              {/* Review form for pending/resubmitted */}
              {(selected.status === "PENDING" || selected.status === "RESUBMITTED") && (
                <>
                  <div className="rounded-xl border border-primary-100 bg-primary-50/60 px-4 py-3 text-xs text-slate-600 dark:border-primary-900/50 dark:bg-primary-900/20 dark:text-slate-300">
                    <p className="font-semibold text-slate-800 dark:text-slate-100">AI feedback assistant</p>
                    <p className="mt-1">Draft feedback in the full chat — paste the plan or ask for review ideas, then copy text back into remarks below.</p>
                    <Link href="/supervisor/ai" className="mt-2 inline-block font-semibold text-primary-600 hover:underline">
                      Open AI assistant
                    </Link>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500 mb-2">
                      Feedback / remarks <span className="normal-case font-normal">(optional)</span>
                    </label>
                    <textarea
                      value={remarks}
                      onChange={(e) => setRemarks(e.target.value)}
                      rows={3}
                      className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-primary-500/20 focus:border-primary-500 resize-none"
                      placeholder="Optional notes for the student…"
                    />
                  </div>

                  <label className="flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={attendance}
                      onChange={(e) => setAttendance(e.target.checked)}
                      className="rounded"
                    />
                    Mark attendance present (when approving)
                  </label>

                  <div className="flex gap-3 pt-1">
                    <button
                      type="button"
                      disabled={submitting}
                      onClick={() => void review("REJECTED")}
                      className="flex-1 rounded-xl border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-semibold text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors dark:border-red-800 dark:bg-red-900/20 dark:text-red-300"
                    >
                      Reject
                    </button>
                    <button
                      type="button"
                      disabled={submitting}
                      onClick={() => void review("APPROVED")}
                      className="flex-1 rounded-xl bg-primary-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-50 transition-colors"
                    >
                      {submitting ? "Saving…" : "Approve"}
                    </button>
                  </div>
                </>
              )}

            </div>
          </div>
        </div>
      )}
    </div>
  );
}
