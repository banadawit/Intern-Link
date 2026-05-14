import React, { useState } from "react";
import { X, FileText, CheckCircle, XCircle, Info, Sparkles, Timer, Ban, RotateCcw } from "lucide-react";
import { format } from "date-fns";
import { VerificationProposal } from "@/lib/superadmin/types";
import { getPendingVerificationSla } from "@/lib/superadmin/verificationSla";
import { cn } from "@/lib/utils";
import PdfViewerModal from "@/components/shared/PdfViewerModal";

interface Props {
  proposal: VerificationProposal | null;
  onClose: () => void;
  onApprove: (id: string) => void;
  onReject: (id: string, reason: string) => void;
  /** Suspend an already-approved organization (blocks org users until reactivated). */
  onSuspend?: (id: string) => void;
  /** Restore an approved organization from suspended state. */
  onReactivate?: (id: string) => void;
}

const VerificationDetail = ({ proposal, onClose, onApprove, onReject, onSuspend, onReactivate }: Props) => {
  const [rejectionReason, setRejectionReason] = useState("");
  const [showRejectionInput, setShowRejectionInput] = useState(false);
  const [docUrl, setDocUrl] = useState<string | null>(null);
  const [documentViewed, setDocumentViewed] = useState(false);

  // Reset local state whenever the proposal changes
  const proposalId = proposal?.id;
  React.useEffect(() => {
    setRejectionReason("");
    setShowRejectionInput(false);
    setDocUrl(null);
    setDocumentViewed(proposal?.document_viewed ?? false);
  }, [proposalId, proposal?.document_viewed]);

  if (!proposal) return null;

  const handleOpenDoc = async (url: string) => {
    setDocUrl(url);
    if (!documentViewed) {
      try {
        const { parseProposalId } = await import("@/lib/api/mappers");
        const api = (await import("@/lib/api/client")).default;
        const parsed = parseProposalId(proposal.id);
        if (parsed) {
          if (parsed.kind === "university") {
            await api.patch(`/admin/universities/${parsed.numericId}/mark-viewed`);
          } else {
            await api.patch(`/admin/companies/${parsed.numericId}/mark-viewed`);
          }
          setDocumentViewed(true);
        }
      } catch (e) {
        console.error("Failed to mark document as viewed:", e);
      }
    }
  };

  const sla = proposal.status === "Pending" ? getPendingVerificationSla(proposal.submittedAt) : null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6">
      <button
        type="button"
        aria-label="Close dialog"
        className="absolute inset-0 bg-slate-900/55 backdrop-blur-md"
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="verification-detail-title"
        className="relative z-10 flex max-h-[90vh] w-full max-w-2xl flex-col overflow-hidden rounded-3xl border border-white/60 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-[0_25px_50px_-12px_rgba(15,23,42,0.35)] ring-1 ring-slate-900/5 dark:ring-slate-700"
        onClick={(e) => e.stopPropagation()}
      >
        <header className="relative overflow-hidden border-b border-slate-200/80 dark:border-slate-700 bg-gradient-to-br from-teal-50/90 via-white to-slate-50 dark:from-teal-950/30 dark:via-slate-900 dark:to-slate-900 px-6 pb-5 pt-6 sm:px-8">
          <div className="pointer-events-none absolute -right-10 -top-10 h-36 w-36 rounded-full bg-teal-200/35 blur-3xl" aria-hidden />
          <div className="pointer-events-none absolute -bottom-8 left-1/4 h-24 w-40 rounded-full bg-sky-100/40 blur-2xl" aria-hidden />
          <div className="relative flex items-start justify-between gap-4">
            <div className="min-w-0 space-y-3">
              <p className="inline-flex items-center gap-2 rounded-full bg-white/90 dark:bg-slate-800/90 px-3 py-1 text-[11px] font-semibold uppercase tracking-wider text-teal-800 dark:text-teal-300 shadow-sm ring-1 ring-teal-100 dark:ring-teal-800 sm:text-xs">
                <Sparkles className="h-3.5 w-3.5 shrink-0" />
                Verification review
              </p>
              <div className="flex items-start gap-3">
                <div
                  className={cn(
                    "shrink-0 rounded-xl p-2.5",
                    proposal.organizationType === "University" ? "bg-teal-100 text-teal-700" : "bg-blue-100 text-blue-700"
                  )}
                >
                  <FileText className="h-6 w-6" />
                </div>
                <div className="min-w-0">
                  <h2 id="verification-detail-title" className="text-xl font-bold tracking-tight text-slate-900 dark:text-slate-100 sm:text-2xl">
                    {proposal.organizationName}
                  </h2>
                  <p className="text-sm text-slate-600 dark:text-slate-400">Proposal #{proposal.id}</p>
                </div>
              </div>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="shrink-0 rounded-xl border border-slate-200 bg-white/80 p-2 text-slate-500 shadow-sm transition-all hover:bg-white hover:text-slate-800 hover:shadow-md active:scale-95"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </header>

        <div className="flex-1 overflow-y-auto p-6 space-y-8">
          <section>
            <h3 className="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Organization Overview</h3>
            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-1">
                <p className="text-xs text-slate-500 dark:text-slate-400">Type</p>
                <p className="font-medium text-slate-900 dark:text-slate-100">{proposal.organizationType}</p>
              </div>
              <div className="space-y-1">
                <p className="text-xs text-slate-500 dark:text-slate-400">Submitted On</p>
                <p className="font-medium text-slate-900 dark:text-slate-100">{new Date(proposal.submittedAt).toLocaleString()}</p>
              </div>
            </div>
            <div className="mt-6 space-y-1">
              <p className="text-xs text-slate-500 dark:text-slate-400">Description</p>
              <p className="text-sm leading-relaxed text-slate-600 dark:text-slate-300">{proposal.description}</p>
            </div>
            {sla && (
              <div
                className={cn(
                  "mt-4 flex flex-col gap-1 rounded-xl border p-3 text-sm",
                  sla.isOverdue ? "border-red-200 bg-red-50/90 text-red-950" : "border-amber-200 bg-amber-50/80 text-amber-950"
                )}
              >
                <p className="flex items-center gap-2 font-semibold">
                  <Timer className="h-4 w-4 shrink-0" aria-hidden />
                  24-hour response policy
                </p>
                <p className="text-sm opacity-90">
                  Admin or system must Approve or Reject within 24 hours of submission.{" "}
                  <span className="font-medium">{sla.label}</span> · Due {format(sla.deadline, "MMM d, yyyy HH:mm")}
                </p>
              </div>
            )}
          </section>

          <section>
            <h3 className="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">Verification Documents</h3>
            <div className="space-y-3">
              {proposal.documents.length === 0 ? (
                <div className="flex items-center gap-3 rounded-xl border border-dashed border-slate-200 bg-slate-50 p-4 text-sm text-slate-400 dark:border-slate-700 dark:bg-slate-800/50">
                  <FileText className="h-5 w-5 shrink-0" />
                  No verification document was uploaded.
                </div>
              ) : (
                proposal.documents.map((doc, index) => (
                  <a
                    key={index}
<<<<<<< HEAD
                    type="button"
                    onClick={() => handleOpenDoc(doc)}
=======
                    href={doc}
                    target="_blank"
                    rel="noopener noreferrer"
>>>>>>> 1e7b041ea3cf082cc98956529ec7d63582c8501b
                    className="w-full flex items-center justify-between gap-3 rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-4 py-3 hover:border-teal-300 hover:bg-teal-50 dark:hover:bg-teal-900/20 transition-colors group"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="rounded-lg bg-teal-100 p-2 text-teal-600 dark:bg-teal-900/40 dark:text-teal-400 shrink-0">
                        <FileText className="h-4 w-4" />
                      </div>
                      <span className="truncate text-sm font-medium text-slate-900 dark:text-slate-100">
                        Verification_Document_{index + 1}.pdf
                      </span>
                    </div>
<<<<<<< HEAD
                    <div className="flex items-center gap-2">
                       {documentViewed && <CheckCircle className="w-4 h-4 text-emerald-500" />}
                       <span className="shrink-0 text-xs font-semibold text-teal-700 dark:text-teal-400">View</span>
                    </div>
                  </button>
=======
                    <span className="shrink-0 text-xs font-semibold text-teal-700 dark:text-teal-400">Open</span>
                  </a>
>>>>>>> 1e7b041ea3cf082cc98956529ec7d63582c8501b
                ))
              )}
            </div>
          </section>

          {proposal.status !== "Pending" && (
            <section
              className={cn(
                "p-4 rounded-xl border",
                proposal.status === "Approved" && "bg-green-50 border-green-100 dark:bg-green-900/20 dark:border-green-800",
                proposal.status === "Rejected" && "bg-red-50 border-red-100 dark:bg-red-900/20 dark:border-red-800",
                proposal.status === "Suspended" && "bg-slate-100 border-slate-200 dark:bg-slate-800 dark:border-slate-700"
              )}
            >
              <div className="flex items-start gap-3">
                {proposal.status === "Approved" && <CheckCircle className="w-5 h-5 text-green-600 mt-0.5 shrink-0" />}
                {proposal.status === "Rejected" && <XCircle className="w-5 h-5 text-red-500 mt-0.5 shrink-0" />}
                {proposal.status === "Suspended" && <Ban className="w-5 h-5 text-slate-600 dark:text-slate-400 mt-0.5 shrink-0" />}
                <div>
                  <p
                    className={cn(
                      "font-bold",
                      proposal.status === "Approved" && "text-green-900 dark:text-green-300",
                      proposal.status === "Rejected" && "text-red-900 dark:text-red-300",
                      proposal.status === "Suspended" && "text-slate-900 dark:text-slate-100"
                    )}
                  >
                    Decision: {proposal.status}
                  </p>
                  {proposal.status === "Suspended" && (
                    <p className="text-sm text-slate-600 dark:text-slate-400 mt-1">
                      Organization access is deactivated. Coordinators, supervisors, and students linked to this org cannot
                      sign in until reactivated.
                    </p>
                  )}
                  {proposal.rejectionReason && <p className="text-sm text-red-700 dark:text-red-400 mt-1">Reason: {proposal.rejectionReason}</p>}
                  {proposal.reviewedAt && (
                    <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">Reviewed on {new Date(proposal.reviewedAt).toLocaleString()}</p>
                  )}
                </div>
              </div>
            </section>
          )}
        </div>

        {proposal.status === "Pending" && (
          <footer className="p-6 border-t border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 space-y-4">
            {showRejectionInput ? (
              <div className="space-y-3 animate-in fade-in slide-in-from-bottom-2 duration-300">
                <label className="text-sm font-bold text-slate-500 dark:text-slate-400">Reason for Rejection</label>
                <textarea className="w-full min-h-[100px] rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-3 text-sm text-slate-600 dark:text-slate-300 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500" placeholder="Provide a clear explanation for the rejection..." value={rejectionReason} onChange={(e) => setRejectionReason(e.target.value)} />
                <div className="flex gap-3">
                  <button onClick={() => onReject(proposal.id, rejectionReason)} disabled={!rejectionReason.trim() || (!documentViewed && proposal.documents.length > 0)} className="flex-1 bg-red-500 hover:bg-red-600 text-white py-2 rounded-lg font-medium disabled:opacity-50 transition-colors">
                    Confirm Rejection
                  </button>
                  <button onClick={() => { setShowRejectionInput(false); setRejectionReason(""); }} className="px-4 py-2 border border-slate-200 dark:border-slate-700 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 transition-colors">
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              <div className="flex gap-3">
                <button 
                  onClick={() => onApprove(proposal.id)} 
                  disabled={!documentViewed && proposal.documents.length > 0}
                  title={!documentViewed && proposal.documents.length > 0 ? "Review the verification document before approving." : ""}
                  className="flex-1 bg-teal-600 hover:bg-teal-700 active:bg-teal-800 text-white py-2 rounded-lg font-medium flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed transition-all"
                >
                  <CheckCircle className="w-5 h-5" />
                  Approve Organization
                </button>
                <button 
                  onClick={() => setShowRejectionInput(true)} 
                  disabled={!documentViewed && proposal.documents.length > 0}
                  className="flex-1 border border-red-500 text-red-500 hover:bg-red-50 py-2 rounded-lg font-medium transition-all flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  <XCircle className="w-5 h-5" />
                  Reject Proposal
                </button>
              </div>
            )}
            {!documentViewed && proposal.documents.length > 0 && (
              <p className="text-center text-[10px] text-amber-600 font-semibold animate-pulse uppercase tracking-tight">
                ⚠️ Review the verification document to enable approval/rejection
              </p>
            )}
            <div className="flex items-start gap-2 text-xs text-slate-500 justify-center text-center">
              <Info className="mt-0.5 w-3 h-3 shrink-0 text-blue-500" />
              <span>
                Organization account is either activated (Approved) or request is removed (Rejected). Decisions are
                logged in the audit history; the organization is notified by email.
              </span>
            </div>
          </footer>
        )}

        {proposal.status === "Rejected" && (
          <footer className="p-6 border-t border-emerald-200/80 bg-emerald-50/60 space-y-3">
            <p className="text-xs text-emerald-900/80">
              This organization was previously rejected. You can approve it if the issue has been resolved — they will be notified by email.
            </p>
            <button
              type="button"
              onClick={() => onApprove(proposal.id)}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-emerald-600 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-emerald-700"
            >
              <CheckCircle className="h-5 w-5" aria-hidden />
              Approve organization
            </button>
          </footer>
        )}

        {proposal.status === "Approved" && onSuspend && (
          <footer className="p-6 border-t border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-800/50 space-y-3">
            {showRejectionInput ? (
              <div className="space-y-3 animate-in fade-in slide-in-from-bottom-2 duration-300">
                <label className="text-sm font-bold text-slate-500">Reason for Rejection</label>
                <textarea
                  className="w-full min-h-[80px] rounded-lg border border-slate-200 bg-white p-3 text-sm text-slate-600 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-red-400 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300"
                  placeholder="Provide a clear reason for rejection..."
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                />
                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={() => { onReject(proposal.id, rejectionReason); }}
                    disabled={!rejectionReason.trim()}
                    className="flex-1 bg-red-600 hover:bg-red-700 text-white py-2 rounded-lg font-medium disabled:opacity-50 transition-colors"
                  >
                    Confirm Rejection
                  </button>
                  <button
                    type="button"
                    onClick={() => { setShowRejectionInput(false); setRejectionReason(""); }}
                    className="px-4 py-2 border border-slate-200 rounded-lg hover:bg-slate-100 text-slate-600 transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => onSuspend(proposal.id)}
                  className="flex-1 flex items-center justify-center gap-2 rounded-lg border border-slate-700 bg-slate-800 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-slate-900"
                >
                  <Ban className="h-4 w-4" aria-hidden />
                  Suspend
                </button>
                <button
                  type="button"
                  onClick={() => setShowRejectionInput(true)}
                  className="flex-1 flex items-center justify-center gap-2 rounded-lg border border-red-200 bg-red-50 py-2.5 text-sm font-semibold text-red-700 transition-colors hover:bg-red-100"
                >
                  <XCircle className="h-4 w-4" aria-hidden />
                  Reject
                </button>
              </div>
            )}
          </footer>
        )}

        {proposal.status === "Suspended" && onReactivate && (
          <footer className="space-y-3 border-t border-amber-200/80 bg-amber-50/60 p-6">
            <p className="text-xs text-amber-950/90">
              Reactivating restores <strong>Approved</strong> status so organization users can access the system again.
            </p>
            <button
              type="button"
              onClick={() => onReactivate(proposal.id)}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-teal-600 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-teal-700"
            >
              <RotateCcw className="h-5 w-5" aria-hidden />
              Reactivate organization
            </button>
          </footer>
        )}
      </div>
    </div>
  );
};

export default VerificationDetail;
