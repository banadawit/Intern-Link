"use client";

import { useState } from "react";
import { LayoutGrid, Table2, FileText, X } from "lucide-react";
import { cn } from "@/lib/utils";
import type { HodStudentRow } from "./types";
import PdfViewerModal from "@/components/shared/PdfViewerModal";

type ViewMode = "row" | "card";

type Props = {
  students: HodStudentRow[];
  submitting: boolean;
  onApprove: (id: number) => void;
  onReject: (id: number) => void;
};

function StatusPill({ status }: { status: string }) {
  return (
    <span
      className={cn(
        "inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold",
        status === "PENDING"  && "bg-amber-100 text-amber-800",
        status === "APPROVED" && "bg-emerald-100 text-emerald-800",
        status === "REJECTED" && "bg-red-100 text-red-700",
        !["PENDING","APPROVED","REJECTED"].includes(status) && "bg-slate-100 text-slate-700",
      )}
    >
      {status}
    </span>
  );
}

function ActionButtons({
  student,
  submitting,
  onApprove,
  onReject,
  layout,
}: {
  student: HodStudentRow;
  submitting: boolean;
  onApprove: (id: number) => void;
  onReject: (id: number) => void;
  layout: "row" | "card";
}) {
  if (student.hod_approval_status !== "PENDING") return null;
  return (
    <div
      className={cn(
        "flex gap-2",
        layout === "row" ? "justify-end" : "mt-4 w-full justify-stretch sm:justify-end",
      )}
    >
      <button
        type="button"
        disabled={submitting}
        onClick={() => onApprove(student.id)}
        className={cn(
          "rounded-lg bg-primary-600 font-semibold text-white hover:bg-primary-700 disabled:opacity-50",
          layout === "card" ? "flex-1 px-3 py-2 text-sm" : "px-3 py-1.5 text-xs",
        )}
      >
        Approve
      </button>
      <button
        type="button"
        disabled={submitting}
        onClick={() => onReject(student.id)}
        className={cn(
          "rounded-lg border border-slate-200 bg-white font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50",
          layout === "card" ? "flex-1 px-3 py-2 text-sm" : "px-3 py-1.5 text-xs",
        )}
      >
        Reject
      </button>
    </div>
  );
}

export default function HodStudentApprovalsTable({ students, submitting, onApprove, onReject }: Props) {
  const [view, setView] = useState<ViewMode>("row");
  const [docUrl, setDocUrl] = useState<string | null>(null);

  const toggleView = () => setView((v) => (v === "row" ? "card" : "row"));

  return (
    <>
      <section
        className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900"
        aria-label="Student approvals"
      >
      <div className="mb-4 flex flex-col items-stretch gap-3 sm:flex-row sm:items-center sm:justify-end">
        <button
          type="button"
          onClick={toggleView}
          className="inline-flex shrink-0 items-center justify-center gap-2 self-start rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm font-medium text-slate-800 shadow-sm transition-colors hover:bg-slate-100 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
          aria-pressed={view === "card"}
          title={view === "row" ? "Switch to card layout" : "Switch to table layout"}
        >
          {view === "row" ? (
            <>
              <LayoutGrid className="h-4 w-4 text-slate-600 dark:text-slate-300" aria-hidden />
              Card view
            </>
          ) : (
            <>
              <Table2 className="h-4 w-4 text-slate-600 dark:text-slate-300" aria-hidden />
              Table view
            </>
          )}
        </button>
      </div>

      {view === "row" ? (
        <div className="overflow-x-auto rounded-xl border border-slate-100 dark:border-slate-700">
          <table className="w-full min-w-[600px] text-left text-sm">
            <thead className="border-b border-slate-100 bg-slate-50/80 dark:border-slate-700 dark:bg-slate-800/70">
              <tr>
                <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Name</th>
                <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Email</th>
                <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Dept</th>
                <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Document</th>
                <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Status</th>
                <th className="px-4 py-3 text-right font-semibold text-slate-700 dark:text-slate-200">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
              {students.map((s) => (
                <tr key={s.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                  <td className="px-4 py-3 font-medium text-slate-900 dark:text-slate-100">{s.user.full_name}</td>
                  <td className="px-4 py-3 text-slate-600 dark:text-slate-300">{s.user.email}</td>
                  <td className="px-4 py-3 text-slate-700 dark:text-slate-300">{s.department ?? "—"}</td>
                  <td className="px-4 py-3">
                    {s.user.verification_document ? (
                      <button
                        type="button"
                        onClick={() => setDocUrl(s.user.verification_document)}
                        className="inline-flex items-center gap-1 rounded-lg border border-primary-200 bg-primary-50 px-2.5 py-1 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors"
                      >
                        <FileText className="h-3.5 w-3.5" /> View
                      </button>
                    ) : (
                      <span className="text-xs text-slate-400">None</span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <StatusPill status={s.hod_approval_status} />
                  </td>
                  <td className="px-4 py-3 text-right">
                    <ActionButtons
                      student={s}
                      submitting={submitting}
                      onApprove={onApprove}
                      onReject={onReject}
                      layout="row"
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {students.length === 0 && (
            <p className="py-8 text-center text-sm text-slate-500 dark:text-slate-400">No students in scope.</p>
          )}
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {students.map((s) => (
            <article
              key={s.id}
              className="flex flex-col rounded-xl border border-slate-100 bg-slate-50/40 p-4 shadow-sm transition-shadow hover:shadow-md dark:border-slate-700 dark:bg-slate-800/60"
            >
              <div className="min-w-0 flex-1 space-y-2">
                <div className="flex items-start justify-between gap-2">
                  <h3 className="font-semibold leading-tight text-slate-900 dark:text-slate-100">{s.user.full_name}</h3>
                  <StatusPill status={s.hod_approval_status} />
                </div>
                <p className="truncate text-sm text-slate-600 dark:text-slate-300" title={s.user.email}>
                  {s.user.email}
                </p>
                <p className="text-sm text-slate-700 dark:text-slate-300">
                  <span className="text-slate-500 dark:text-slate-400">Dept:</span> {s.department ?? "—"}
                </p>
                {s.user.verification_document && (
                  <button
                    type="button"
                    onClick={() => setDocUrl(s.user.verification_document)}
                    className="inline-flex items-center gap-1 rounded-lg border border-primary-200 bg-primary-50 px-2.5 py-1 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors"
                  >
                    <FileText className="h-3.5 w-3.5" /> View document
                  </button>
                )}
              </div>
              <ActionButtons
                student={s}
                submitting={submitting}
                onApprove={onApprove}
                onReject={onReject}
                layout="card"
              />
            </article>
          ))}
          {students.length === 0 && (
            <p className="col-span-full py-8 text-center text-sm text-slate-500 dark:text-slate-400">No students in scope.</p>
          )}
        </div>
      )}
    </section>
      <PdfViewerModal
        isOpen={!!docUrl}
        pdfUrl={docUrl ?? ""}
        title="Verification Document"
        onClose={() => setDocUrl(null)}
      />
    </>
  );
}
