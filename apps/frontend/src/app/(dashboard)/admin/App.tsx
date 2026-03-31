"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Sidebar from "./Sidebar";
import Dashboard from "./Dashboard";
import VerificationList from "./VerificationList";
import VerificationDetail from "./VerificationDetail";
import AuditLog from "./AuditLog";
import AdminPageHero from "./AdminPageHero";
import { MOCK_PROPOSALS, MOCK_AUDIT_LOG } from "@/lib/superadmin/mockData";
import { VerificationProposal, AuditLogEntry } from "@/lib/superadmin/types";

type ViewKey =
  | "dashboard"
  | "pending"
  | "approved"
  | "rejected"
  | "suspended"
  | "audit-log"
  | "settings";

const VALID_VIEWS: ViewKey[] = [
  "dashboard",
  "pending",
  "approved",
  "rejected",
  "suspended",
  "audit-log",
  "settings",
];

function parseViewParam(v: string | null): ViewKey {
  if (v && VALID_VIEWS.includes(v as ViewKey)) return v as ViewKey;
  return "dashboard";
}

export default function App() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialView = parseViewParam(searchParams.get("view"));

  const [proposals, setProposals] = useState<VerificationProposal[]>(MOCK_PROPOSALS);
  const [auditLogs, setAuditLogs] = useState<AuditLogEntry[]>(MOCK_AUDIT_LOG);
  const [selectedProposal, setSelectedProposal] = useState<VerificationProposal | null>(null);
  const [activeView, setActiveView] = useState<ViewKey>(initialView);

  const viewFromUrl = parseViewParam(searchParams.get("view"));
  useEffect(() => {
    setActiveView(viewFromUrl);
  }, [viewFromUrl]);

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
      adminId: "Admin_1",
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
      adminId: "Admin_1",
      timestamp: new Date().toISOString(),
      notes: `Rejected: ${reason}`,
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  const handleSuspend = (id: string) => {
    const proposal = proposals.find((p) => p.id === id);
    if (!proposal) return;
    setProposals(
      proposals.map((p) =>
        p.id === id ? { ...p, status: "Suspended" as const, reviewedAt: new Date().toISOString() } : p
      )
    );
    const newLog: AuditLogEntry = {
      id: `log_${Date.now()}`,
      action: "Suspend",
      targetId: id,
      targetName: proposal.organizationName,
      adminId: "Admin_1",
      timestamp: new Date().toISOString(),
      notes: "Organization suspended after approval — access blocked for org users.",
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  const handleReactivate = (id: string) => {
    const proposal = proposals.find((p) => p.id === id);
    if (!proposal) return;
    setProposals(
      proposals.map((p) =>
        p.id === id ? { ...p, status: "Approved" as const, reviewedAt: new Date().toISOString() } : p
      )
    );
    const newLog: AuditLogEntry = {
      id: `log_${Date.now()}`,
      action: "Reactivate",
      targetId: id,
      targetName: proposal.organizationName,
      adminId: "Admin_1",
      timestamp: new Date().toISOString(),
      notes: "Organization reactivated — Approved status restored.",
    };
    setAuditLogs([newLog, ...auditLogs]);
    setSelectedProposal(null);
  };

  const pendingVerificationCount = proposals.filter((p) => p.status === "Pending").length;

  const mainContent = useMemo(() => {
    if (activeView === "dashboard")
      return <Dashboard pendingVerificationCount={pendingVerificationCount} />;
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
      <div className="space-y-6">
        <AdminPageHero
          badge="Settings"
          title="System configuration"
          description="Global settings and platform parameters will be managed here when connected to the backend."
        />
        <div className="card p-8 text-center shadow-sm">
          <p className="text-slate-600">
            Placeholder — no settings actions in the frontend-only build.
          </p>
        </div>
      </div>
    );
  }, [activeView, proposals, auditLogs]);

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row">
      <Sidebar activeView={activeView} onNavigate={handleNavigate} pendingCount={pendingVerificationCount} />

      <main className="min-h-0 min-w-0 flex-1 px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
        <div className="mx-auto w-full max-w-7xl">
          {mainContent}
        </div>
      </main>

      <VerificationDetail
        proposal={selectedProposal}
        onClose={() => setSelectedProposal(null)}
        onApprove={handleApprove}
        onReject={handleReject}
        onSuspend={handleSuspend}
        onReactivate={handleReactivate}
      />
    </div>
  );
}
