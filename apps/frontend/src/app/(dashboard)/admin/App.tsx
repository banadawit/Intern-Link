"use client";

import React, { useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Sidebar from "./Sidebar";
import Dashboard from "./Dashboard";
import VerificationList from "./VerificationList";
import VerificationDetail from "./VerificationDetail";
import AuditLog from "./AuditLog";
import { MOCK_PROPOSALS, MOCK_AUDIT_LOG } from "@/lib/superadmin/mockData";
import { VerificationProposal, AuditLogEntry } from "@/lib/superadmin/types";

type ViewKey =
  | "dashboard"
  | "pending"
  | "approved"
  | "rejected"
  | "audit-log"
  | "settings";

export default function App() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialView = (searchParams.get("view") as ViewKey) || "dashboard";

  const [proposals, setProposals] = useState<VerificationProposal[]>(MOCK_PROPOSALS);
  const [auditLogs, setAuditLogs] = useState<AuditLogEntry[]>(MOCK_AUDIT_LOG);
  const [selectedProposal, setSelectedProposal] = useState<VerificationProposal | null>(null);
  const [activeView, setActiveView] = useState<ViewKey>(initialView);

  const handleNavigate = (view: ViewKey) => {
    setActiveView(view);
    router.replace(`/admin?view=${view}`);
  };

  const handleApprove = (id: string) => {
    const proposal = proposals.find((p) => p.id === id);
    if (!proposal) return;

    const updatedProposals = proposals.map((p) =>
      p.id === id ? { ...p, status: "Approved" as const, reviewedAt: new Date().toISOString() } : p
    );
    setProposals(updatedProposals);

    const newLog: AuditLogEntry = {
      id: `log_${Date.now()}`,
      action: "Approve",
      targetId: id,
      targetName: proposal.organizationName,
      adminId: "SuperAdmin_1",
      timestamp: new Date().toISOString(),
      notes: "Organization credentials verified and approved.",
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  const handleReject = (id: string, reason: string) => {
    const proposal = proposals.find((p) => p.id === id);
    if (!proposal) return;

    const updatedProposals = proposals.map((p) =>
      p.id === id
        ? { ...p, status: "Rejected" as const, rejectionReason: reason, reviewedAt: new Date().toISOString() }
        : p
    );
    setProposals(updatedProposals);

    const newLog: AuditLogEntry = {
      id: `log_${Date.now()}`,
      action: "Reject",
      targetId: id,
      targetName: proposal.organizationName,
      adminId: "SuperAdmin_1",
      timestamp: new Date().toISOString(),
      notes: `Rejected: ${reason}`,
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  const mainContent = useMemo(() => {
    if (activeView === "dashboard") return <Dashboard />;
    if (activeView === "pending")
      return (
        <VerificationList
          title="Pending Approvals"
          proposals={proposals.filter((p) => p.status === "Pending")}
          onReview={setSelectedProposal}
        />
      );
    if (activeView === "approved")
      return (
        <VerificationList
          title="Approved History"
          proposals={proposals.filter((p) => p.status === "Approved")}
          onReview={setSelectedProposal}
        />
      );
    if (activeView === "rejected")
      return (
        <VerificationList
          title="Rejected History"
          proposals={proposals.filter((p) => p.status === "Rejected")}
          onReview={setSelectedProposal}
        />
      );
    if (activeView === "audit-log") return <AuditLog logs={auditLogs} />;
    return (
      <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center">
        <h1 className="text-2xl font-bold mb-4">System Configuration</h1>
        <p className="text-slate-500">Global settings and platform parameters management.</p>
      </div>
    );
  }, [activeView, proposals, auditLogs]);

  return (
    <div className="flex min-h-screen bg-slate-50 text-slate-600">
      <Sidebar activeView={activeView} onNavigate={handleNavigate} />

      <main className="flex-1 p-8">
        <div className="max-w-7xl mx-auto">{mainContent}</div>
      </main>

      <VerificationDetail proposal={selectedProposal} onClose={() => setSelectedProposal(null)} onApprove={handleApprove} onReject={handleReject} />
    </div>
  );
}
