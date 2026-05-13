"use client";

import React, { useCallback, useEffect, useState } from "react";
import { Clock, UserCheck, Briefcase, CheckCircle, XCircle, FileText, User, Building, Loader2, LayoutList } from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";
import VerificationList from "./VerificationList";
import CoordinatorApprovals from "./CoordinatorApprovals";
import SupervisorApprovals from "./SupervisorApprovals";
import AdminPageHero from "./AdminPageHero";
import ConfirmDialog from "@/components/shared/ConfirmDialog";
import SuccessToast from "@/components/shared/SuccessToast";
import PdfViewerModal from "@/components/shared/PdfViewerModal";
import { VerificationProposal } from "@/lib/superadmin/types";
import api from "@/lib/api/client";

type ApprovalTab = "all" | "coordinator-approvals" | "supervisor-approvals";

interface PendingCoordinator {
  id: number;
  userId: number;
  pending_university_name: string | null;
  user: { id: number; full_name: string; email: string; verification_document: string | null; created_at: string };
}

interface PendingSupervisor {
  id: number;
  userId: number;
  company: { id: number; name: string };
  user: { id: number; full_name: string; email: string; verification_document: string | null; created_at: string };
}

type UnifiedItem =
  | { kind: "org"; data: VerificationProposal }
  | { kind: "coordinator"; data: PendingCoordinator }
  | { kind: "supervisor"; data: PendingSupervisor };

interface Props {
  proposals: VerificationProposal[];
  listsLoading: boolean;
  pendingCount: number;
  pendingCoordinatorCount: number;
  pendingSupervisorCount: number;
  onReview: (p: VerificationProposal) => void;
  onActionComplete: () => void;
  initialTab?: ApprovalTab;
}

const tabs: Array<{ id: ApprovalTab; label: string; icon: React.ComponentType<{ className?: string }>; title: string; description: string }> = [
  { id: "all", label: "All", icon: LayoutList, title: "All Pending Approvals", description: "Review all pending verification requests across organizations, coordinators, and supervisors." },
  { id: "coordinator-approvals", label: "Coordinators", icon: UserCheck, title: "Pending Coordinator Approvals", description: "Review and approve university coordinator registrations." },
  { id: "supervisor-approvals", label: "Supervisors", icon: Briefcase, title: "Pending Supervisor Approvals", description: "Review and approve company supervisor registrations." },
];

function TypeBadge({ kind }: { kind: "org" | "coordinator" | "supervisor" }) {
  const map = {
    org: { label: "Organization", cls: "bg-blue-50 text-blue-700 ring-blue-200/80" },
    coordinator: { label: "Coordinator", cls: "bg-teal-50 text-teal-700 ring-teal-200/80" },
    supervisor: { label: "Supervisor", cls: "bg-violet-50 text-violet-700 ring-violet-200/80" },
  };
  const { label, cls } = map[kind];
  return <span className={cn("rounded-full px-2 py-0.5 text-[10px] font-bold ring-1", cls)}>{label}</span>;
}

function AllPendingView({
  proposals,
  orgsLoading,
  onReviewOrg,
  onActionComplete,
}: {
  proposals: VerificationProposal[];
  orgsLoading: boolean;
  onReviewOrg: (p: VerificationProposal) => void;
  onActionComplete: () => void;
}) {
  const [coordinators, setCoordinators] = useState<PendingCoordinator[]>([]);
  const [supervisors, setSupervisors] = useState<PendingSupervisor[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<number | null>(null);
  const [rejectTarget, setRejectTarget] = useState<{ userId: number; role: "coordinator" | "supervisor"; reason: string } | null>(null);
  const [confirmApprove, setConfirmApprove] = useState<{ userId: number; role: "coordinator" | "supervisor" } | null>(null);
  const [toast, setToast] = useState<{ show: boolean; message: string }>({ show: false, message: "" });
  const [docUrl, setDocUrl] = useState<string | null>(null);
  const [documentViewedUserIds, setDocumentViewedUserIds] = useState<Set<number>>(() => new Set());

  const loadPeople = useCallback(async () => {
    setLoading(true);
    try {
      const [cRes, sRes] = await Promise.all([
        api.get<PendingCoordinator[]>("/admin/pending-coordinators"),
        api.get<PendingSupervisor[]>("/admin/pending-supervisors"),
      ]);
      setCoordinators(cRes.data);
      setSupervisors(sRes.data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void loadPeople(); }, [loadPeople]);

  const handleApprove = async () => {
    if (!confirmApprove) return;
    const { userId, role } = confirmApprove;
    setActionLoading(userId);
    try {
      await api.post(`/admin/${role === "coordinator" ? "coordinators" : "supervisors"}/${userId}/approve`);
      setConfirmApprove(null);
      setToast({ show: true, message: `✅ ${role === "coordinator" ? "Coordinator" : "Supervisor"} approved successfully` });
      await loadPeople();
      onActionComplete();
    } catch (e) {
      console.error(e);
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async () => {
    if (!rejectTarget) return;
    const { userId, role, reason } = rejectTarget;
    setActionLoading(userId);
    try {
      await api.post(`/admin/${role === "coordinator" ? "coordinators" : "supervisors"}/${userId}/reject`, { reason });
      setRejectTarget(null);
      setToast({ show: true, message: `${role === "coordinator" ? "Coordinator" : "Supervisor"} registration rejected` });
      await loadPeople();
      onActionComplete();
    } catch (e) {
      console.error(e);
    } finally {
      setActionLoading(null);
    }
  };

  const pendingOrgs = proposals.filter((p) => p.status === "Pending");

  const unified: UnifiedItem[] = [
    ...pendingOrgs.map((p): UnifiedItem => ({ kind: "org", data: p })),
    ...coordinators.map((c): UnifiedItem => ({ kind: "coordinator", data: c })),
    ...supervisors.map((s): UnifiedItem => ({ kind: "supervisor", data: s })),
  ];

  const isLoading = orgsLoading || loading;

  if (isLoading) return <p className="text-sm text-slate-500">Loading pending approvals…</p>;

  if (unified.length === 0) return (
    <div className="rounded-2xl border border-slate-200 bg-white px-6 py-16 text-center text-slate-500 dark:border-slate-700 dark:bg-slate-900">
      <CheckCircle className="mx-auto mb-3 h-10 w-10 text-emerald-400" />
      <p className="font-medium">All caught up — no pending approvals.</p>
    </div>
  );

  return (
    <>
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider dark:bg-slate-800 dark:text-slate-400">
                <th className="px-6 py-4 font-semibold">Name</th>
                <th className="px-6 py-4 font-semibold">Type</th>
                <th className="px-6 py-4 font-semibold">Institution</th>
                <th className="px-6 py-4 font-semibold">Document</th>
                <th className="px-6 py-4 font-semibold">Submitted</th>
                <th className="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
              {unified.map((item, idx) => {
                if (item.kind === "org") {
                  const p = item.data;
                  return (
                    <tr key={`org-${p.id}`} className="hover:bg-slate-50 transition-colors dark:hover:bg-slate-800/50">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="p-2 rounded-lg bg-blue-50 text-blue-600"><Building className="w-5 h-5" /></div>
                          <div>
                            <p className="font-semibold text-slate-900 dark:text-slate-100">{p.organizationName}</p>
                            <p className="text-xs text-slate-500">{p.email ?? "—"}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4"><TypeBadge kind="org" /></td>
                      <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400">{p.organizationType}</td>
                      <td className="px-6 py-4">
                        {p.documents?.[0] ? (
                          <button type="button" onClick={() => setDocUrl(p.documents[0])} className="inline-flex items-center gap-1.5 text-sm text-primary-600 hover:text-primary-700 font-medium">
                            <FileText className="w-4 h-4" />View Doc
                          </button>
                        ) : <span className="text-xs text-slate-400 italic">No document</span>}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-500">
                        {p.submittedAt ? format(new Date(p.submittedAt), "MMM d, yyyy") : "—"}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end">
                          <button
                            onClick={() => onReviewOrg(p)}
                            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition-colors"
                          >
                            Review
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                }

                if (item.kind === "coordinator") {
                  const c = item.data;
                  return (
                    <tr key={`coord-${c.userId}`} className="hover:bg-slate-50 transition-colors dark:hover:bg-slate-800/50">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="p-2 rounded-lg bg-teal-50 text-teal-600"><User className="w-5 h-5" /></div>
                          <div>
                            <p className="font-semibold text-slate-900 dark:text-slate-100">{c.user.full_name}</p>
                            <p className="text-xs text-slate-500">{c.user.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4"><TypeBadge kind="coordinator" /></td>
                      <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400">{c.pending_university_name ?? <span className="italic text-slate-400">Not provided</span>}</td>
                      <td className="px-6 py-4">
                        {c.user.verification_document ? (
                          <button
                            type="button"
                            onClick={() => {
                              setDocumentViewedUserIds((prev) => new Set(prev).add(c.userId));
                              setDocUrl(c.user.verification_document);
                            }}
                            className="inline-flex items-center gap-1.5 text-sm text-primary-600 hover:text-primary-700 font-medium"
                          >
                            <FileText className="w-4 h-4" />View Doc
                          </button>
                        ) : <span className="text-xs text-slate-400 italic">No document</span>}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-500">{format(new Date(c.user.created_at), "MMM d, yyyy")}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => setConfirmApprove({ userId: c.userId, role: "coordinator" })}
                            disabled={
                              actionLoading === c.userId ||
                              !c.user.verification_document ||
                              !documentViewedUserIds.has(c.userId)
                            }
                            title={
                              !c.user.verification_document
                                ? "Cannot approve without a verification document"
                                : !documentViewedUserIds.has(c.userId)
                                  ? "Open the verification document before approving"
                                  : undefined
                            }
                            className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-60 transition-colors"
                          >
                            {actionLoading === c.userId ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <CheckCircle className="w-3.5 h-3.5" />}
                            Approve
                          </button>
                          <button
                            onClick={() => setRejectTarget({ userId: c.userId, role: "coordinator", reason: "" })}
                            disabled={
                              actionLoading === c.userId ||
                              (!!c.user.verification_document && !documentViewedUserIds.has(c.userId))
                            }
                            title={
                              c.user.verification_document && !documentViewedUserIds.has(c.userId)
                                ? "Open the verification document before rejecting"
                                : undefined
                            }
                            className="inline-flex items-center gap-1.5 rounded-lg bg-red-50 border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 disabled:opacity-60 transition-colors"
                          >
                            <XCircle className="w-3.5 h-3.5" />Reject
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                }

                // supervisor
                const s = item.data as PendingSupervisor;
                return (
                  <tr key={`sup-${s.userId}`} className="hover:bg-slate-50 transition-colors dark:hover:bg-slate-800/50">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="p-2 rounded-lg bg-violet-50 text-violet-600"><User className="w-5 h-5" /></div>
                        <div>
                          <p className="font-semibold text-slate-900 dark:text-slate-100">{s.user.full_name}</p>
                          <p className="text-xs text-slate-500">{s.user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4"><TypeBadge kind="supervisor" /></td>
                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400">{s.company.name}</td>
                    <td className="px-6 py-4">
                      {s.user.verification_document ? (
                        <button
                          type="button"
                          onClick={() => {
                            setDocumentViewedUserIds((prev) => new Set(prev).add(s.userId));
                            setDocUrl(s.user.verification_document);
                          }}
                          className="inline-flex items-center gap-1.5 text-sm text-primary-600 hover:text-primary-700 font-medium"
                        >
                          <FileText className="w-4 h-4" />View Doc
                        </button>
                      ) : <span className="text-xs text-slate-400 italic">No document</span>}
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500">{format(new Date(s.user.created_at), "MMM d, yyyy")}</td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => setConfirmApprove({ userId: s.userId, role: "supervisor" })}
                          disabled={
                            actionLoading === s.userId ||
                            !s.user.verification_document ||
                            !documentViewedUserIds.has(s.userId)
                          }
                          title={
                            !s.user.verification_document
                              ? "Cannot approve without a verification document"
                              : !documentViewedUserIds.has(s.userId)
                                ? "Open the verification document before approving"
                                : undefined
                          }
                          className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-60 transition-colors"
                        >
                          {actionLoading === s.userId ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <CheckCircle className="w-3.5 h-3.5" />}
                          Approve
                        </button>
                        <button
                          onClick={() => setRejectTarget({ userId: s.userId, role: "supervisor", reason: "" })}
                          disabled={
                            actionLoading === s.userId ||
                            (!!s.user.verification_document && !documentViewedUserIds.has(s.userId))
                          }
                          title={
                            s.user.verification_document && !documentViewedUserIds.has(s.userId)
                              ? "Open the verification document before rejecting"
                              : undefined
                          }
                          className="inline-flex items-center gap-1.5 rounded-lg bg-red-50 border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 disabled:opacity-60 transition-colors"
                        >
                          <XCircle className="w-3.5 h-3.5" />Reject
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Reject modal */}
      {rejectTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-xl p-6 w-full max-w-md mx-4 space-y-4 dark:bg-slate-900">
            <h3 className="text-lg font-bold text-slate-900 dark:text-slate-100">
              Reject {rejectTarget.role === "coordinator" ? "Coordinator" : "Supervisor"}
            </h3>
            <p className="text-sm text-slate-500">Provide a reason for rejection. This will be sent by email.</p>
            <textarea
              value={rejectTarget.reason}
              onChange={(e) => setRejectTarget({ ...rejectTarget, reason: e.target.value })}
              placeholder="e.g., Verification document is unclear or invalid..."
              rows={3}
              className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-400 resize-none dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100"
            />
            <div className="flex gap-3 pt-1">
              <button onClick={() => setRejectTarget(null)} className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 transition-colors">Cancel</button>
              <button onClick={() => void handleReject()} disabled={actionLoading !== null} className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60 transition-colors">
                {actionLoading !== null ? "Rejecting…" : "Confirm Reject"}
              </button>
            </div>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={confirmApprove !== null}
        title={`Approve ${confirmApprove?.role === "coordinator" ? "coordinator" : "supervisor"}?`}
        message={confirmApprove?.role === "coordinator"
          ? "This will create their university and grant them full coordinator access. They will be notified by email."
          : "This will grant the supervisor access to InternLink. They will be notified by email."}
        confirmLabel="Approve"
        variant="success"
        loading={actionLoading !== null}
        onConfirm={() => void handleApprove()}
        onCancel={() => setConfirmApprove(null)}
      />

      <SuccessToast show={toast.show} message={toast.message} onClose={() => setToast({ show: false, message: "" })} />
      <PdfViewerModal
        isOpen={!!docUrl}
        pdfUrl={docUrl ?? ""}
        title="Verification Document"
        onClose={() => setDocUrl(null)}
      />
    </>
  );
}

export default function ApprovalsView({
  proposals,
  listsLoading,
  pendingCount,
  pendingCoordinatorCount,
  pendingSupervisorCount,
  onReview,
  onActionComplete,
  initialTab = "all",
}: Props) {
  const [activeTab, setActiveTab] = useState<ApprovalTab>(initialTab);

  const badgeFor = (tab: ApprovalTab) => {
    if (tab === "all") return pendingCount + pendingCoordinatorCount + pendingSupervisorCount;
    if (tab === "coordinator-approvals") return pendingCoordinatorCount;
    if (tab === "supervisor-approvals") return pendingSupervisorCount;
    return 0;
  };

  const active = tabs.find((t) => t.id === activeTab)!;

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <AdminPageHero badge={active.id === "all" ? "Approvals" : active.label} title={active.title} description={active.description} />

      {/* Tab bar */}
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1 dark:border-slate-700 dark:bg-slate-800/50">
        {tabs.map((tab) => {
          const count = badgeFor(tab.id);
          const isActive = activeTab === tab.id;
          return (
            <button key={tab.id} type="button" onClick={() => setActiveTab(tab.id)}
              className={cn(
                "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
                isActive ? "bg-white text-teal-700 shadow-sm ring-1 ring-slate-200 dark:bg-slate-900 dark:ring-slate-700" : "text-slate-500 hover:text-slate-700 dark:hover:text-slate-300"
              )}>
              <tab.icon className="h-4 w-4 shrink-0" />
              <span className="hidden sm:inline">{tab.label}</span>
              {count > 0 && (
                <span className={cn("rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums",
                  isActive ? "bg-teal-100 text-teal-800 ring-1 ring-teal-200/80" : "bg-rose-100 text-rose-700 ring-1 ring-rose-200/80"
                )}>
                  {count > 99 ? "99+" : count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      <div>
        {activeTab === "all" && (
          <AllPendingView
            proposals={proposals}
            orgsLoading={listsLoading}
            onReviewOrg={onReview}
            onActionComplete={onActionComplete}
          />
        )}
        {activeTab === "coordinator-approvals" && (
          <CoordinatorApprovals onActionComplete={onActionComplete} hideHero />
        )}
        {activeTab === "supervisor-approvals" && (
          <SupervisorApprovals onActionComplete={onActionComplete} hideHero />
        )}
      </div>
    </div>
  );
}
