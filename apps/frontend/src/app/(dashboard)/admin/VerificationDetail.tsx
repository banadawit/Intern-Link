import React, { useState } from "react";
import { X, FileText, ExternalLink, CheckCircle, XCircle, Info } from "lucide-react";
import { VerificationProposal } from "@/lib/superadmin/types";
import { cn } from "@/lib/utils";

interface Props {
  proposal: VerificationProposal | null;
  onClose: () => void;
  onApprove: (id: string) => void;
  onReject: (id: string, reason: string) => void;
}

const VerificationDetail = ({ proposal, onClose, onApprove, onReject }: Props) => {
  const [rejectionReason, setRejectionReason] = useState("");
  const [showRejectionInput, setShowRejectionInput] = useState(false);

  if (!proposal) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        <header className="p-6 border-b border-slate-200 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={cn("p-2 rounded-lg", proposal.organizationType === "University" ? "bg-teal-50 text-teal-600" : "bg-blue-50 text-blue-600")}>
              <FileText className="w-6 h-6" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-slate-900">{proposal.organizationName}</h2>
              <p className="text-sm text-slate-500">Verification Proposal #{proposal.id}</p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-full transition-colors">
            <X className="w-6 h-6 text-slate-500" />
          </button>
        </header>

        <div className="flex-1 overflow-y-auto p-6 space-y-8">
          <section>
            <h3 className="text-sm font-bold text-slate-500 uppercase tracking-wider mb-4">Organization Overview</h3>
            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-1">
                <p className="text-xs text-slate-500">Type</p>
                <p className="font-medium text-slate-900">{proposal.organizationType}</p>
              </div>
              <div className="space-y-1">
                <p className="text-xs text-slate-500">Submitted On</p>
                <p className="font-medium text-slate-900">{new Date(proposal.submittedAt).toLocaleString()}</p>
              </div>
            </div>
            <div className="mt-6 space-y-1">
              <p className="text-xs text-slate-500">Description</p>
              <p className="text-sm leading-relaxed text-slate-600">{proposal.description}</p>
            </div>
          </section>

          <section>
            <h3 className="text-sm font-bold text-slate-500 uppercase tracking-wider mb-4">Verification Documents</h3>
            <div className="space-y-3">
              {proposal.documents.map((doc, index) => (
                <a key={index} href={doc} target="_blank" rel="noopener noreferrer" className="flex items-center justify-between p-4 rounded-xl border border-slate-200 hover:border-teal-600 hover:bg-teal-50 transition-all group">
                  <div className="flex items-center gap-3">
                    <div className="bg-slate-100 p-2 rounded-lg group-hover:bg-teal-50">
                      <FileText className="w-5 h-5 text-slate-500 group-hover:text-teal-600" />
                    </div>
                    <span className="text-sm font-medium text-slate-900">Verification_Credential_{index + 1}.pdf</span>
                  </div>
                  <ExternalLink className="w-4 h-4 text-slate-500 group-hover:text-teal-600" />
                </a>
              ))}
            </div>
          </section>

          {proposal.status !== "Pending" && (
            <section className={cn("p-4 rounded-xl border", proposal.status === "Approved" ? "bg-green-50 border-green-100" : "bg-red-50 border-red-100")}>
              <div className="flex items-start gap-3">
                {proposal.status === "Approved" ? <CheckCircle className="w-5 h-5 text-green-600 mt-0.5" /> : <XCircle className="w-5 h-5 text-red-500 mt-0.5" />}
                <div>
                  <p className={cn("font-bold", proposal.status === "Approved" ? "text-green-900" : "text-red-900")}>Decision: {proposal.status}</p>
                  {proposal.rejectionReason && <p className="text-sm text-red-700 mt-1">Reason: {proposal.rejectionReason}</p>}
                  <p className="text-xs text-slate-500 mt-2">Reviewed on {new Date(proposal.reviewedAt!).toLocaleString()}</p>
                </div>
              </div>
            </section>
          )}
        </div>

        {proposal.status === "Pending" && (
          <footer className="p-6 border-t border-slate-200 bg-slate-50 space-y-4">
            {showRejectionInput ? (
              <div className="space-y-3 animate-in fade-in slide-in-from-bottom-2 duration-300">
                <label className="text-sm font-bold text-slate-500">Reason for Rejection</label>
                <textarea className="w-full min-h-[100px] rounded-lg border border-slate-200 bg-white p-3 text-sm text-slate-600 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500" placeholder="Provide a clear explanation for the rejection..." value={rejectionReason} onChange={(e) => setRejectionReason(e.target.value)} />
                <div className="flex gap-3">
                  <button onClick={() => onReject(proposal.id, rejectionReason)} disabled={!rejectionReason.trim()} className="flex-1 bg-red-500 hover:bg-red-600 text-white py-2 rounded-lg font-medium disabled:opacity-50 transition-colors">
                    Confirm Rejection
                  </button>
                  <button onClick={() => setShowRejectionInput(false)} className="px-4 py-2 border border-slate-200 rounded-lg hover:bg-slate-100 text-slate-600 transition-colors">
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              <div className="flex gap-3">
                <button onClick={() => onApprove(proposal.id)} className="flex-1 bg-teal-600 hover:bg-teal-700 active:bg-teal-800 text-white py-2 rounded-lg font-medium flex items-center justify-center gap-2">
                  <CheckCircle className="w-5 h-5" />
                  Approve Organization
                </button>
                <button onClick={() => setShowRejectionInput(true)} className="flex-1 border border-red-500 text-red-500 hover:bg-red-50 py-2 rounded-lg font-medium transition-all flex items-center justify-center gap-2">
                  <XCircle className="w-5 h-5" />
                  Reject Proposal
                </button>
              </div>
            )}
            <div className="flex items-center gap-2 text-xs text-slate-500 justify-center">
              <Info className="w-3 h-3 text-blue-500" />
              <span>Decision will be logged in the audit history and the organization will be notified.</span>
            </div>
          </footer>
        )}
      </div>
    </div>
  );
};

export default VerificationDetail;
