"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Sidebar from "./Sidebar";
import Dashboard, { type AdminDashboardStats } from "./Dashboard";
import VerificationList from "./VerificationList";
import VerificationDetail from "./VerificationDetail";
import AuditLog from "./AuditLog";
import AdminPageHero from "./AdminPageHero";
import CoordinatorApprovals from "./CoordinatorApprovals";
import SupervisorApprovals from "./SupervisorApprovals";
import ApprovalsView from "./ApprovalsView";
import ApprovedHistoryView from "./ApprovedHistoryView";
import RejectedHistoryView from "./RejectedHistoryView";
import SuspendedView from "./SuspendedView";
import api from "@/lib/api/client";
import {
  mapUniversityToProposal,
  mapCompanyToProposal,
  mapAuditApiToEntry,
  parseProposalId,
} from "@/lib/api/mappers";
import { VerificationProposal, AuditLogEntry } from "@/lib/superadmin/types";

type ViewKey =
  | "dashboard"
  | "approvals"
  | "approved"
  | "rejected"
  | "suspended"
  | "audit-log"
  | "settings";

const VALID_VIEWS: ViewKey[] = [
  "dashboard",
  "approvals",
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

  const [proposals, setProposals] = useState<VerificationProposal[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLogEntry[]>([]);
  const [stats, setStats] = useState<AdminDashboardStats | null>(null);
  const [statsLoading, setStatsLoading] = useState(true);
  const [listsLoading, setListsLoading] = useState(true);
  const [selectedProposal, setSelectedProposal] = useState<VerificationProposal | null>(null);
  const [activeView, setActiveView] = useState<ViewKey>(initialView);

  const viewFromUrl = parseViewParam(searchParams.get("view"));
  useEffect(() => {
    setActiveView(viewFromUrl);
  }, [viewFromUrl]);

  const loadProposals = useCallback(async () => {
    setListsLoading(true);
    try {
      const [uniRes, compRes] = await Promise.all([api.get("/admin/universities"), api.get("/admin/companies")]);
      const uniRows = uniRes.data as Record<string, unknown>[];
      const compRows = compRes.data as Record<string, unknown>[];
      const u = uniRows.map((row) => mapUniversityToProposal(row as never));
      const c = compRows.map((row) => mapCompanyToProposal(row as never));
      setProposals([...u, ...c]);
    } finally {
      setListsLoading(false);
    }
  }, []);

  const loadStats = useCallback(async () => {
    setStatsLoading(true);
    try {
      const { data } = await api.get<AdminDashboardStats>("/admin/stats");
      setStats(data);
    } finally {
      setStatsLoading(false);
    }
  }, []);

  const loadAuditLogs = useCallback(async () => {
    try {
      const { data } = await api.get("/admin/audit-logs");
      const logRows = data as Record<string, unknown>[];
      setAuditLogs(logRows.map((row) => mapAuditApiToEntry(row as never)));
    } catch {
      setAuditLogs([]);
    }
  }, []);

  useEffect(() => {
    loadProposals();
    loadStats();
    loadAuditLogs();
  }, [loadProposals, loadStats, loadAuditLogs]);

  const handleNavigate = (view: ViewKey) => {
    setActiveView(view);
    router.replace(`/admin?view=${view}`);
  };

  const patchOrgStatus = async (id: string, status: "APPROVED" | "REJECTED" | "SUSPENDED", reason?: string) => {
    const parsed = parseProposalId(id);
    if (!parsed) return;
    const body =
      status === "REJECTED" ? { status, reason: reason ?? "" } : { status, ...(reason ? { reason } : {}) };
    if (parsed.kind === "university") {
      await api.patch(`/admin/university-status/${parsed.numericId}`, body);
    } else {
      await api.patch(`/admin/company-status/${parsed.numericId}`, body);
    }
    await loadProposals();
    await loadStats();
    await loadAuditLogs();
  };

  const handleApprove = async (id: string) => {
    try {
      await patchOrgStatus(id, "APPROVED");
      setSelectedProposal(null);
    } catch (e) {
      console.error(e);
    }
  };

  const handleReject = async (id: string, reason: string) => {
    try {
      await patchOrgStatus(id, "REJECTED", reason);
      setSelectedProposal(null);
    } catch (e) {
      console.error(e);
    }
  };

  const handleSuspend = async (id: string) => {
    try {
      await patchOrgStatus(id, "SUSPENDED");
      setSelectedProposal(null);
    } catch (e) {
      console.error(e);
    }
  };

  const handleReactivate = async (id: string) => {
    try {
      await patchOrgStatus(id, "APPROVED");
      setSelectedProposal(null);
    } catch (e) {
      console.error(e);
    }
  };

  const pendingVerificationCount = proposals.filter((p) => p.status === "Pending").length;

  const mainContent = useMemo(() => {
    if (activeView === "dashboard")
      return (
        <Dashboard
          pendingVerificationCount={pendingVerificationCount}
          stats={stats}
          statsLoading={statsLoading}
        />
      );
    if (activeView === "approvals")
      return (
        <ApprovalsView
          proposals={proposals}
          listsLoading={listsLoading}
          pendingCount={pendingVerificationCount}
          pendingCoordinatorCount={stats?.pendingCoordinators ?? 0}
          pendingSupervisorCount={stats?.pendingSupervisors ?? 0}
          onReview={setSelectedProposal}
          onActionComplete={() => { loadStats(); loadAuditLogs(); loadProposals(); }}
        />
      );
    if (activeView === "approved")
      return (
        <ApprovedHistoryView
          proposals={proposals}
          listsLoading={listsLoading}
          onReview={setSelectedProposal}
        />
      );
    if (activeView === "rejected")
      return (
        <RejectedHistoryView
          proposals={proposals}
          listsLoading={listsLoading}
          onReview={setSelectedProposal}
          rejectedCoordinatorCount={stats?.rejectedCoordinators ?? 0}
          rejectedSupervisorCount={stats?.rejectedSupervisors ?? 0}
        />
      );
    if (activeView === "suspended")
      return (
        <SuspendedView
          proposals={proposals}
          listsLoading={listsLoading}
          onReview={setSelectedProposal}
          suspendedCoordinatorCount={stats?.suspendedCoordinators ?? 0}
          suspendedSupervisorCount={stats?.suspendedSupervisors ?? 0}
        />
      );
    if (activeView === "audit-log") return <AuditLog logs={auditLogs} />;
    return (
      <div className="space-y-6">
        <AdminPageHero
          badge="Settings"
          title="System configuration"
          description="Global settings and platform parameters are managed here."
        />
        <div className="card p-8 text-center shadow-sm">
          <p className="text-slate-600">Additional settings can be connected to the backend as needed.</p>
        </div>
      </div>
    );
  }, [activeView, proposals, auditLogs, pendingVerificationCount, stats, statsLoading, listsLoading]);

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row">
      <Sidebar activeView={activeView} onNavigate={handleNavigate} pendingCount={pendingVerificationCount} pendingCoordinatorCount={stats?.pendingCoordinators ?? 0} pendingSupervisorCount={stats?.pendingSupervisors ?? 0} />

      <main className="min-h-0 min-w-0 flex-1 px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
        <div className="mx-auto w-full max-w-7xl">{mainContent}</div>
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
