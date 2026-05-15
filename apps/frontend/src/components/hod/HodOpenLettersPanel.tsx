"use client";

import { useState } from "react";
import { cn } from "@/lib/utils";
import {
  ArrowRight, Mail, Inbox, MapPin, FileText, ImageIcon,
  ChevronDown, ChevronUp,
} from "lucide-react";
import type { HodProposalRow } from "./types";
import PdfViewerModal from "@/components/shared/PdfViewerModal";

type Props = {
  openLetters: HodProposalRow[];
  submitting: boolean;
  onApprove: (id: number) => void;
  onReject: (id: number, reason?: string) => void;
};

function StatusBadge({ status }: { status: string }) {
  return (
    <span className={cn(
      "rounded-full px-2.5 py-0.5 text-xs font-semibold",
      status === "PENDING"  && "bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300",
      status === "APPROVED" && "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300",
      status === "REJECTED" && "bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300",
      !["PENDING","APPROVED","REJECTED"].includes(status) && "bg-slate-200 text-slate-700 dark:bg-slate-700 dark:text-slate-300",
    )}>
      {status}
    </span>
  );
}

function OpenLetterRow({
  p,
  submitting,
  onApprove,
  onReject,
}: {
  p: HodProposalRow;
  submitting: boolean;
  onApprove: (id: number) => void;
  onReject: (id: number, reason?: string) => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const [rejectOpen, setRejectOpen] = useState(false);
  const [reason, setReason] = useState("");
  const [docUrl, setDocUrl] = useState<string | null>(null);
  const [docTitle, setDocTitle] = useState("");

  return (
    <>
    <div className="rounded-xl border border-slate-100 dark:border-slate-700 bg-slate-50/80 dark:bg-slate-800/60 overflow-hidden">
      {/* Header row */}
      <div className="flex flex-wrap items-center justify-between gap-3 px-4 py-3">
        <div className="flex items-center gap-2 text-sm min-w-0">
          <div className="min-w-0">
            <span className="font-semibold text-slate-800 dark:text-slate-100">
              {p.student.user.full_name}
            </span>
            <div className="flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
              <Mail className="w-3 h-3 shrink-0" />
              <span className="truncate">{p.student.user.email}</span>
            </div>
          </div>
          <ArrowRight className="w-4 h-4 shrink-0 text-slate-400 dark:text-slate-500" />
          <div className="min-w-0">
            <span className="font-semibold text-slate-800 dark:text-slate-100">{p.company.name}</span>
            <div className="text-xs text-slate-500 dark:text-slate-400">
              {new Date(p.submitted_at).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })}
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          <StatusBadge status={p.status} />
          <button
            type="button"
            onClick={() => setExpanded((v) => !v)}
            className="rounded-lg border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 p-1.5 text-slate-500 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors"
            title={expanded ? "Collapse" : "View details"}
          >
            {expanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          {p.status === "PENDING" && (
            <>
              <button
                type="button"
                disabled={submitting}
                className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50 transition-colors"
                onClick={() => onApprove(p.id)}
              >
                Accept
              </button>
              <button
                type="button"
                disabled={submitting}
                className="rounded-lg border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-50 transition-colors"
                onClick={() => setRejectOpen((v) => !v)}
              >
                Reject
              </button>
            </>
          )}
        </div>
      </div>

      {/* Expanded company + cover letter details */}
      {expanded && (
        <div className="border-t border-slate-200 dark:border-slate-700 px-4 py-4 space-y-4 bg-white dark:bg-slate-900/50">
          {/* Company info */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-2">Company details</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm">
              <div className="flex items-center gap-2 text-slate-700 dark:text-slate-300">
                <Mail className="w-4 h-4 text-slate-400 shrink-0" />
                <span className="truncate">{p.company.official_email}</span>
              </div>
              {p.company.address && (
                <div className="flex items-center gap-2 text-slate-700 dark:text-slate-300">
                  <MapPin className="w-4 h-4 text-slate-400 shrink-0" />
                  <span>{p.company.address}</span>
                </div>
              )}
            </div>
          </div>

          {/* Documents */}
          {(p.company.stamp_image_url || p.company.verification_doc) && (
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-2">Documents</p>
              <div className="flex flex-wrap gap-2">
                {p.company.stamp_image_url && (
                  <button
                    type="button"
                    onClick={() => { setDocTitle("Company Stamp"); setDocUrl(p.company.stamp_image_url!); }}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 dark:border-slate-600 bg-slate-50 dark:bg-slate-800 px-3 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
                  >
                    <ImageIcon className="w-3.5 h-3.5" />
                    Company stamp
                  </button>
                )}
                {p.company.verification_doc && (
                  <button
                    type="button"
                    onClick={() => { setDocTitle("Verification Document"); setDocUrl(p.company.verification_doc!); }}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 dark:border-slate-600 bg-slate-50 dark:bg-slate-800 px-3 py-1.5 text-xs font-medium text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors"
                  >
                    <FileText className="w-3.5 h-3.5" />
                    Verification document
                  </button>
                )}
              </div>
            </div>
          )}

          {/* Cover letter */}
          {p.expected_outcomes && (
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500 mb-2">Cover letter</p>
              <p className="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-wrap leading-relaxed">
                {p.expected_outcomes}
              </p>
            </div>
          )}
        </div>
      )}

      {/* Inline rejection reason */}
      {rejectOpen && (
        <div className="border-t border-slate-200 dark:border-slate-700 px-4 py-3 space-y-2 bg-white dark:bg-slate-900/50">
          <label className="text-xs font-semibold text-slate-600 dark:text-slate-300">
            Rejection reason (optional)
          </label>
          <textarea
            className="w-full rounded-lg border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-2 text-sm text-slate-800 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-primary-500 min-h-[72px] resize-none"
            placeholder="Explain why this request is being rejected..."
            value={reason}
            onChange={(e) => setReason(e.target.value)}
          />
          <div className="flex gap-2">
            <button
              type="button"
              disabled={submitting}
              className="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-red-700 disabled:opacity-50 transition-colors"
              onClick={() => {
                onReject(p.id, reason.trim() || undefined);
                setRejectOpen(false);
                setReason("");
              }}
            >
              Confirm reject
            </button>
            <button
              type="button"
              className="rounded-lg border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-700 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 transition-colors"
              onClick={() => { setRejectOpen(false); setReason(""); }}
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
    <PdfViewerModal
      isOpen={!!docUrl}
      pdfUrl={docUrl ?? ""}
      title={docTitle}
      onClose={() => setDocUrl(null)}
    />
    </>
  );
}
export default function HodOpenLettersPanel({ openLetters, submitting, onApprove, onReject }: Props) {
  return (
    <section
      className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5 shadow-sm sm:p-6"
      aria-label="Open letter proposals list"
    >
      {openLetters.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-slate-400 dark:text-slate-500">
          <Inbox className="w-12 h-12 mb-4 opacity-40" aria-hidden />
          <p className="text-sm font-medium">No open letter proposals yet.</p>
          <p className="text-xs mt-1">When students submit open letters, they will appear here.</p>
        </div>
      ) : (
        <div className="space-y-2">
          {openLetters.map((p) => (
            <OpenLetterRow
              key={p.id}
              p={p}
              submitting={submitting}
              onApprove={onApprove}
              onReject={onReject}
            />
          ))}
        </div>
      )}
    </section>
  );
}
