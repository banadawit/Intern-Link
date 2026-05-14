"use client";

import { useState, useEffect } from "react";
import { LayoutGrid, Table2, FileText, X, Clock, Loader2, History } from "lucide-react";
import { cn } from "@/lib/utils";
import api from "@/lib/api/client";
import type { HodStudentRow } from "./types";
import PdfViewerModal from "@/components/shared/PdfViewerModal";

type ViewMode = "row" | "card";

type TimelineEntry = { state: string; timestamp: string; actor: string };

function stateColor(state: string): string {
  if (["APPROVED", "PLACED", "COMPLETED", "ACTIVE"].includes(state)) return "bg-emerald-500";
  if (["REJECTED", "TERMINATED"].includes(state)) return "bg-red-500";
  if (["PENDING", "REGISTERED"].includes(state)) return "bg-amber-400";
  return "bg-slate-400";
}

function stateTextColor(state: string): string {
  if (["APPROVED", "PLACED", "COMPLETED", "ACTIVE"].includes(state)) return "text-emerald-700 dark:text-emerald-300";
  if (["REJECTED", "TERMINATED"].includes(state)) return "text-red-700 dark:text-red-300";
  if (["PENDING", "REGISTERED"].includes(state)) return "text-amber-700 dark:text-amber-300";
  return "text-slate-600 dark:text-slate-300";
}

function TimelineModal({ studentName, studentId, onClose }: { studentName: string; studentId: number; onClose: () => void }) {
  const [entries, setEntries] = useState<TimelineEntry[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch on mount
  useEffect(() => {
    (async () => {
      try {
        const res = await api.get<{ success: boolean; data: TimelineEntry[] }>(`/hod/students/${studentId}/timeline`);
        setEntries(Array.isArray(res.data.data) ? res.data.data : []);
      } catch {
        setError("Could not load timeline.");
      } finally {
        setLoading(false);
      }
    })();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [studentId]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div className="w-full max-w-md rounded-2xl bg-white shadow-2xl dark:bg-slate-900 dark:border dark:border-slate-700 flex flex-col max-h-[80vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-5 pt-5 pb-3 border-b border-slate-100 dark:border-slate-700 shrink-0">
          <div>
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">{studentName}</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400">Student timeline</p>
          </div>
          <button type="button" onClick={onClose} className="rounded-lg p-1.5 hover:bg-slate-100 dark:hover:bg-slate-800">
            <X className="h-4 w-4 text-slate-500" />
          </button>
        </div>

        {/* Body */}
        <div className="overflow-y-auto px-5 py-4 flex-1">
          {loading ? (
            <div className="flex items-center justify-center py-10">
              <Loader2 className="h-6 w-6 animate-spin text-primary-600" />
            </div>
          ) : error ? (
            <p className="text-sm text-red-600 dark:text-red-400 py-4 text-center">{error}</p>
          ) : !entries || entries.length === 0 ? (
            <p className="text-sm text-slate-500 dark:text-slate-400 py-4 text-center">No timeline events yet.</p>
          ) : (
            <ol className="relative border-l border-slate-200 dark:border-slate-700 ml-3 space-y-6">
              {entries.map((entry, i) => (
                <li key={i} className="ml-5">
                  {/* Dot */}
                  <span className={cn("absolute -left-[9px] flex h-4 w-4 items-center justify-center rounded-full ring-2 ring-white dark:ring-slate-900", stateColor(entry.state))} />
                  <div>
                    <p className={cn("text-sm font-bold", stateTextColor(entry.state))}>{entry.state}</p>
                    <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                      {new Date(entry.timestamp).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                    </p>
                    <span className="inline-block mt-1 rounded-full bg-slate-100 dark:bg-slate-800 px-2 py-0.5 text-[11px] font-medium text-slate-600 dark:text-slate-300 capitalize">
                      {entry.actor}
                    </span>
                  </div>
                </li>
              ))}
            </ol>
          )}
        </div>
      </div>
    </div>
  );
}



type Props = {
  students: HodStudentRow[];
  submitting: boolean;
  onApprove: (id: number) => void;
  onReject: (id: number) => void;
  onFlag: (id: number) => void;
  onUnflag: (id: number) => void;
  onReprocess: (id: number) => void;
};

function StatusPill({ status }: { status: string }) {
  return (
    <span
      className={cn(
        "inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold",
        status === "PENDING" && "bg-amber-100 text-amber-800",
        status === "APPROVED" && "bg-emerald-100 text-emerald-800",
        status === "REJECTED" && "bg-red-100 text-red-700",
        !["PENDING", "APPROVED", "REJECTED"].includes(status) && "bg-slate-100 text-slate-700",
      )}
    >
      {status}
    </span>
  );
}

function ProposalPill({ status }: { status: string }) {
  const colors: Record<string, string> = {
    PENDING: "bg-amber-100 text-amber-800",
    APPROVED: "bg-emerald-100 text-emerald-800",
    REJECTED: "bg-red-100 text-red-700",
    CANCELLED: "bg-slate-100 text-slate-600",
  };
  return (
    <span className={cn("inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold", colors[status] ?? "bg-slate-100 text-slate-600")}>
      {status}
    </span>
  );
}
function ActionButtons({
  student,
  submitting,
  onApprove,
  onReject,
  onFlag,
  onUnflag,
  onReprocess,
  layout,
}: {
  student: HodStudentRow;
  submitting: boolean;
  onApprove: (id: number) => void;
  onReject: (id: number) => void;
  onFlag: (id: number) => void;
  onUnflag: (id: number) => void;
  onReprocess: (id: number) => void;
  layout: "row" | "card";
  viewedIds: Set<number>;
}) {
  const status = student.hod_approval_status;
  const isApprovedOrPlaced = status === "APPROVED" || student.internship_status === "PLACED";
  const isRejected = status === "REJECTED";
  const isPending = status === "PENDING";

  return (
    <div className={cn("flex flex-wrap gap-1.5", layout === "row" ? "justify-end" : "mt-4 w-full")}>
      {/* Approve / Reject for PENDING */}
      {isPending && (
        <>
          <button
            type="button"
            disabled={
              submitting || 
              (!!student.user.verification_document && !student.user.document_viewed && !viewedIds.has(student.id))
            }
            onClick={() => onApprove(student.id)}
            title={
              !!student.user.verification_document && !student.user.document_viewed && !viewedIds.has(student.id)
                ? "Review verification document first"
                : ""
            }
            className={cn(
              "rounded-lg bg-primary-600 font-semibold text-white hover:bg-primary-700 disabled:opacity-50 transition-all",
              layout === "card" ? "flex-1 px-3 py-2 text-sm" : "px-3 py-1.5 text-xs",
            )}
          >
            Approve
          </button>
          <button
            type="button"
            disabled={
              submitting || 
              (!!student.user.verification_document && !student.user.document_viewed && !viewedIds.has(student.id))
            }
            onClick={() => onReject(student.id)}
            className={cn(
              "rounded-lg border border-slate-200 bg-white font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50 transition-all",
              layout === "card" ? "flex-1 px-3 py-2 text-sm" : "px-3 py-1.5 text-xs",
            )}
          >
            Reject
          </button>
        </>
      )}

      {/* Flag / Unflag for APPROVED or PLACED */}
      {isApprovedOrPlaced && (
        student.flag_type ? (
          <button
            type="button"
            disabled={submitting}
            onClick={() => onUnflag(student.id)}
            className="rounded-lg border border-red-200 bg-white px-2.5 py-1 text-xs font-semibold text-red-600 hover:bg-red-50 disabled:opacity-50"
          >
            Unflag
          </button>
        ) : (
          <button
            type="button"
            disabled={submitting}
            onClick={() => onFlag(student.id)}
            className="rounded-lg border border-amber-200 bg-white px-2.5 py-1 text-xs font-semibold text-amber-600 hover:bg-amber-50 disabled:opacity-50"
          >
            Flag
          </button>
        )
      )}

      {/* Reprocess for REJECTED */}
      {isRejected && (
        <button
          type="button"
          disabled={submitting}
          onClick={() => onReprocess(student.id)}
          className="rounded-lg border border-blue-200 bg-white px-2.5 py-1 text-xs font-semibold text-blue-600 hover:bg-blue-50 disabled:opacity-50"
        >
          Reprocess
        </button>
      )}
    </div>
  );
}

export default function HodStudentApprovalsTable({ students, submitting, onApprove, onReject, onFlag, onUnflag, onReprocess }: Props) {
  const [view, setView] = useState<ViewMode>("row");
  const [docUrl, setDocUrl] = useState<string | null>(null);
  const [viewedIds, setViewedIds] = useState<Set<number>>(() => new Set());
  const [timeline, setTimeline] = useState<{ id: number; name: string } | null>(null);

  const handleOpenDoc = async (id: number, url: string) => {
    setDocUrl(url);
    try {
      await api.patch(`/hod/students/${id}/mark-viewed`);
      setViewedIds((prev) => new Set(prev).add(id));
    } catch (e) {
      console.error("Failed to mark student document as viewed", e);
    }
  };

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
                  <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Student ID</th>
                  <th className="px-4 py-3 font-semibold text-slate-700 dark:text-slate-200">Proposal</th>
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
                    <td className="px-4 py-3 text-slate-600 dark:text-slate-300 text-xs">{s.studentId ?? "—"}</td>
                    <td className="px-4 py-3">
                      {s.latestProposal ? (
                        <div className="flex flex-col gap-0.5">
                          <span className="text-xs font-medium text-slate-800 dark:text-slate-200 truncate max-w-[120px]">{s.latestProposal.companyName}</span>
                          <ProposalPill status={s.latestProposal.status} />
                        </div>
                      ) : (
                        <span className="text-xs text-slate-400">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {s.user.verification_document ? (
                        <button
                          type="button"
                          onClick={() => handleOpenDoc(s.id, s.user.verification_document!)}
                          className="inline-flex items-center gap-1 rounded-lg border border-primary-200 bg-primary-50 px-2.5 py-1 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors"
                        >
                          <FileText className="h-3.5 w-3.5" /> View
                          {(s.user.document_viewed || viewedIds.has(s.id)) && <CheckCircle className="h-3 w-3 text-emerald-500 ml-0.5" />}
                        </button>
                      ) : (
                        <span className="text-xs text-slate-400">None</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <StatusPill status={s.hod_approval_status} />
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          type="button"
                          onClick={() => setTimeline({ id: s.id, name: s.user.full_name })}
                          className="rounded-lg border border-slate-200 bg-white px-2.5 py-1 text-xs font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800 inline-flex items-center gap-1"
                        >
                          <History className="h-3 w-3" /> Timeline
                        </button>
                        <ActionButtons student={s} submitting={submitting} onApprove={onApprove} onReject={onReject} onFlag={onFlag} onUnflag={onUnflag} onReprocess={onReprocess} layout="row" viewedIds={viewedIds} />
                      </div>
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
                  {s.studentId && (
                    <p className="text-xs text-slate-500 dark:text-slate-400">
                      <span className="font-medium">Student ID:</span> {s.studentId}
                    </p>
                  )}
                  {s.latestProposal ? (
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-slate-500 dark:text-slate-400">Proposal:</span>
                      <span className="text-xs font-medium text-slate-700 dark:text-slate-200 truncate max-w-[120px]">{s.latestProposal.companyName}</span>
                      <ProposalPill status={s.latestProposal.status} />
                    </div>
                  ) : (
                    <p className="text-xs text-slate-400 dark:text-slate-500">No proposal yet</p>
                  )}
                  {s.user.verification_document && (
                    <button
                      type="button"
                      onClick={() => handleOpenDoc(s.id, s.user.verification_document!)}
                      className="inline-flex items-center gap-1 rounded-lg border border-primary-200 bg-primary-50 px-2.5 py-1 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors"
                    >
                      <FileText className="h-3.5 w-3.5" /> View document
                      {(s.user.document_viewed || viewedIds.has(s.id)) && <CheckCircle className="h-3 w-3 text-emerald-500 ml-0.5" />}
                    </button>
                  )}
                </div>
                <ActionButtons
                  student={s}
                  submitting={submitting}
                  onApprove={onApprove}
                  onReject={onReject}
                  onFlag={onFlag}
                  onUnflag={onUnflag}
                  onReprocess={onReprocess}
                  layout="card"
                  viewedIds={viewedIds}
                />
                <button
                  type="button"
                  onClick={() => setTimeline({ id: s.id, name: s.user.full_name })}
                  className="mt-2 w-full rounded-lg border border-slate-200 bg-white py-1.5 text-xs font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800 inline-flex items-center justify-center gap-1"
                >
                  <History className="h-3 w-3" /> View timeline
                </button>
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
      {timeline && (
        <TimelineModal
          studentId={timeline.id}
          studentName={timeline.name}
          onClose={() => setTimeline(null)}
        />
      )}
    </>
  );
}
