"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Sidebar, { ViewKey } from "./Sidebar";
import Dashboard, { type AdminDashboardStats } from "./Dashboard";
import VerificationList from "./VerificationList";
import VerificationDetail from "./VerificationDetail";
import AuditLog from "./AuditLog";
import AdminPageHero from "./AdminPageHero";
import CoordinatorApprovals from "./CoordinatorApprovals";
import SupervisorApprovals from "./SupervisorApprovals";
import ApprovalsView from "./ApprovalsView";
import SystemSettings from "./SystemSettings";
import OrganizationsView from "./OrganizationsView";
import api from "@/lib/api/client";
import NotificationBell from "@/components/shared/NotificationBell";
import ThemeToggle from "@/components/theme/ThemeToggle";
import {
  mapUniversityToProposal,
  mapCompanyToProposal,
  mapAuditApiToEntry,
  parseProposalId,
} from "@/lib/api/mappers";
import { VerificationProposal, AuditLogEntry } from "@/lib/superadmin/types";


const VALID_VIEWS: ViewKey[] = [
  "dashboard",
  "approvals",
  "organizations",
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
      const uniRaw = (uniRes.data as { data?: unknown[] })?.data ?? uniRes.data;
      const compRaw = (compRes.data as { data?: unknown[] })?.data ?? compRes.data;
      const uniRows = Array.isArray(uniRaw) ? uniRaw as Record<string, unknown>[] : [];
      const compRows = Array.isArray(compRaw) ? compRaw as Record<string, unknown>[] : [];
      const u = uniRows.map((row) => mapUniversityToProposal(row as never));
      const c = compRows.map((row) => mapCompanyToProposal(row as never));
      setProposals([...u, ...c]);
    } catch (e) {
      console.error("Failed to load organizations:", e);
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
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { error?: string } } })?.response?.data?.error ?? "";
      // Already suspended — just close the modal and refresh
      if (msg.toLowerCase().includes("only approved")) {
        setSelectedProposal(null);
        await loadProposals();
      } else {
        console.error(e);
      }
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

  const handleReview = useCallback(async (p: VerificationProposal) => {
    try {
      const parsed = parseProposalId(p.id);
      if (parsed) {
        const endpoint = parsed.kind === "university"
          ? `/admin/universities`
          : `/admin/companies`;
        const res = await api.get(endpoint);
        const raw = (res.data as { data?: unknown[] })?.data ?? res.data;
        const rows = Array.isArray(raw) ? raw as Record<string, unknown>[] : [];
        const fresh = rows.find((r) => Number(r.id) === parsed.numericId);
        if (fresh) {
          const mapped = parsed.kind === "university"
            ? mapUniversityToProposal(fresh as never)
            : mapCompanyToProposal(fresh as never);
          setSelectedProposal(mapped);
          return;
        }
      }
    } catch {
      // fall through to use cached data
    }
    setSelectedProposal(p);
  }, []);



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
          onReview={handleReview}
          onActionComplete={() => { loadStats(); loadAuditLogs(); loadProposals(); }}
        />
      );
    if (activeView === "organizations")
      return (
        <OrganizationsView
          proposals={proposals}
          loading={listsLoading}
          onReview={handleReview}
          onActionComplete={() => { loadProposals(); loadStats(); }}
        />
      );
    if (activeView === "audit-log") return <AuditLog logs={auditLogs} />;
    if (activeView === "settings") return <SystemSettings />;
  }, [activeView, proposals, auditLogs, pendingVerificationCount, stats, statsLoading, listsLoading, handleReview]);

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 text-slate-600 antialiased lg:flex-row dark:bg-slate-950 dark:text-slate-300">
      <Sidebar activeView={activeView} onNavigate={handleNavigate} pendingCount={pendingVerificationCount} pendingCoordinatorCount={stats?.pendingCoordinators ?? 0} pendingSupervisorCount={stats?.pendingSupervisors ?? 0} />

      <div className="flex min-h-0 min-w-0 flex-1 flex-col">
        {/* Top bar — matches other dashboards */}
        <div className="flex items-center justify-end gap-2 border-b border-border-default bg-bg-main/95 dark:bg-slate-900/95 dark:border-slate-700 px-4 py-3 backdrop-blur-sm sm:px-6 lg:px-8">
          <ThemeToggle variant="inline" className="px-2.5 py-2 [&>span]:hidden" />
          <NotificationBell />
        </div>
        <main className="min-h-0 min-w-0 flex-1 px-4 py-6 sm:px-6 sm:py-8 lg:px-8 lg:py-10">
          <div className="mx-auto w-full max-w-7xl">{mainContent}</div>
        </main>
      </div>

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
