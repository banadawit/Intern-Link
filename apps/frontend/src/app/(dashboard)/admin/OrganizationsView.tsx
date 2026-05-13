"use client";

import React, { useState, useMemo, useCallback, useEffect } from "react";
import {
  Building,
  Briefcase,
  Search,
  CheckCircle2,
  XCircle,
  Ban,
  RotateCcw,
  Loader2,
  Filter,
  UserCheck,
  User,
  CheckCircle,
  FileText,
} from "lucide-react";
import { format } from "date-fns";
import { useTranslations } from "next-intl";
import { cn } from "@/lib/utils";
import AdminPageHero from "./AdminPageHero";
import { VerificationProposal } from "@/lib/superadmin/types";
import api from "@/lib/api/client";
import PdfViewerModal from "@/components/shared/PdfViewerModal";

type OrgTab = "universities" | "companies" | "coordinators" | "supervisors";

const STATUS_CONFIG = {
  Pending:   { bg: "bg-amber-50",   text: "text-amber-700",   ring: "ring-amber-200"   },
  Approved:  { bg: "bg-emerald-50", text: "text-emerald-700", ring: "ring-emerald-200" },
  Rejected:  { bg: "bg-red-50",     text: "text-red-700",     ring: "ring-red-200"     },
  Suspended: { bg: "bg-slate-100",  text: "text-slate-600",   ring: "ring-slate-200"   },
};

interface Props {
  proposals: VerificationProposal[];
  loading: boolean;
  onReview: (p: VerificationProposal) => void;
  onActionComplete?: () => void;
}

interface PersonUser {
  id: number;
  full_name: string;
  email: string;
  created_at: string;
  institution_access_approval?: string;
}

interface CoordinatorRow {
  id: number;
  userId: number;
  university: { id: number; name: string } | null;
  pending_university_name?: string | null;
  user: PersonUser;
}

interface SupervisorRow {
  id: number;
  userId: number;
  company: { id: number; name: string };
  user: PersonUser;
}

type PersonStatus = "approved" | "rejected" | "suspended";

type OrgNavTab = {
  id: OrgTab;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  count?: number;
  pending?: number;
};

function usePersonList<T>(endpoint: string) {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get<T[]>(endpoint);
      setData(res);
    } finally {
      setLoading(false);
    }
  }, [endpoint]);
  useEffect(() => { void load(); }, [load]);
  return { data, loading };
}

function PersonStatusBadge({ status }: { status: PersonStatus }) {
  const tc = useTranslations("Common");
  if (status === "approved")
    return (
      <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-emerald-200">
        <CheckCircle className="w-3 h-3" /> {tc("approved")}
      </span>
    );
  if (status === "rejected")
    return (
      <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700 ring-1 ring-red-200">
        <XCircle className="w-3 h-3" /> {tc("rejected")}
      </span>
    );
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 ring-1 ring-slate-300">
      <Ban className="w-3 h-3" /> {tc("suspended")}
    </span>
  );
}

function CoordinatorsPanel() {
  type StatusFilter = "all" | PersonStatus;
  const to = useTranslations("AdminPortal.organizations");
  const tc = useTranslations("Common");
  const td = useTranslations("AdminPortal.dashboard");
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [search, setSearch] = useState("");

  const { data: approved, loading: l1 } = usePersonList<CoordinatorRow>("/admin/approved-coordinators");
  const { data: rejected, loading: l2 } = usePersonList<CoordinatorRow>("/admin/rejected-coordinators");
  const { data: suspended, loading: l3 } = usePersonList<CoordinatorRow>("/admin/suspended-coordinators");

  const loading = l1 || l2 || l3;

  const rows = useMemo(() => {
    const all: (CoordinatorRow & { _status: PersonStatus })[] = [
      ...approved.map((r) => ({ ...r, _status: "approved" as PersonStatus })),
      ...rejected.map((r) => ({ ...r, _status: "rejected" as PersonStatus })),
      ...suspended.map((r) => ({ ...r, _status: "suspended" as PersonStatus })),
    ];
    const q = search.toLowerCase();
    return all.filter((r) => {
      const matchStatus = statusFilter === "all" || r._status === statusFilter;
      const matchSearch = !q || r.user.full_name.toLowerCase().includes(q) || r.user.email.toLowerCase().includes(q);
      return matchStatus && matchSearch;
    });
  }, [approved, rejected, suspended, statusFilter, search]);

  const filterLabel = (s: StatusFilter) => {
    if (s === "all") return to("statusAll");
    if (s === "approved") return tc("approved");
    if (s === "rejected") return tc("rejected");
    return tc("suspended");
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input type="text" value={search} onChange={(e) => setSearch(e.target.value)}
            placeholder={to("searchCoordinators")}
            className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-2.5 pl-9 pr-4 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20" />
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          <Filter className="h-4 w-4 text-slate-400 shrink-0" />
          {(["all", "approved", "rejected", "suspended"] as StatusFilter[]).map((s) => (
            <button key={s} type="button" onClick={() => setStatusFilter(s)}
              className={cn("rounded-full px-3 py-1 text-xs font-semibold transition-all",
                statusFilter === s ? "bg-teal-600 text-white shadow-sm" : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700")}>
              {filterLabel(s)}
            </button>
          ))}
        </div>
      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm">
        {loading ? (
          <div className="flex min-h-[20vh] items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-teal-600" /></div>
        ) : rows.length === 0 ? (
          <div className="flex min-h-[16vh] items-center justify-center text-sm text-slate-400">{to("personEmptyCoordinators")}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                  <th className="px-6 py-3">{to("personTableCoordinator")}</th>
                  <th className="px-6 py-3">{to("personTableUniversity")}</th>
                  <th className="px-6 py-3">{to("personTableDate")}</th>
                  <th className="px-6 py-3">{to("tableStatus")}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                {rows.map((c) => (
                  <tr key={`${c._status}-${c.id}`} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="p-2 rounded-lg bg-teal-50 text-teal-600"><User className="w-4 h-4" /></div>
                        <div>
                          <p className="font-semibold text-slate-900 dark:text-slate-100">{c.user.full_name}</p>
                          <p className="text-xs text-slate-500">{c.user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-300">
                      {c.university?.name ?? c.pending_university_name ?? <span className="italic text-slate-400">{td("activityDash")}</span>}
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500">{format(new Date(c.user.created_at), "MMM d, yyyy")}</td>
                    <td className="px-6 py-4"><PersonStatusBadge status={c._status} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function SupervisorsPanel() {
  type StatusFilter = "all" | PersonStatus;
  const to = useTranslations("AdminPortal.organizations");
  const tc = useTranslations("Common");
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [search, setSearch] = useState("");

  const { data: approved, loading: l1 } = usePersonList<SupervisorRow>("/admin/approved-supervisors");
  const { data: rejected, loading: l2 } = usePersonList<SupervisorRow>("/admin/rejected-supervisors");
  const { data: suspended, loading: l3 } = usePersonList<SupervisorRow>("/admin/suspended-supervisors");

  const loading = l1 || l2 || l3;

  const rows = useMemo(() => {
    const all: (SupervisorRow & { _status: PersonStatus })[] = [
      ...approved.map((r) => ({ ...r, _status: "approved" as PersonStatus })),
      ...rejected.map((r) => ({ ...r, _status: "rejected" as PersonStatus })),
      ...suspended.map((r) => ({ ...r, _status: "suspended" as PersonStatus })),
    ];
    const q = search.toLowerCase();
    return all.filter((r) => {
      const matchStatus = statusFilter === "all" || r._status === statusFilter;
      const matchSearch = !q || r.user.full_name.toLowerCase().includes(q) || r.user.email.toLowerCase().includes(q);
      return matchStatus && matchSearch;
    });
  }, [approved, rejected, suspended, statusFilter, search]);

  const filterLabel = (s: StatusFilter) => {
    if (s === "all") return to("statusAll");
    if (s === "approved") return tc("approved");
    if (s === "rejected") return tc("rejected");
    return tc("suspended");
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input type="text" value={search} onChange={(e) => setSearch(e.target.value)}
            placeholder={to("searchSupervisors")}
            className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-2.5 pl-9 pr-4 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20" />
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          <Filter className="h-4 w-4 text-slate-400 shrink-0" />
          {(["all", "approved", "rejected", "suspended"] as StatusFilter[]).map((s) => (
            <button key={s} type="button" onClick={() => setStatusFilter(s)}
              className={cn("rounded-full px-3 py-1 text-xs font-semibold transition-all",
                statusFilter === s ? "bg-teal-600 text-white shadow-sm" : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700")}>
              {filterLabel(s)}
            </button>
          ))}
        </div>
      </div>

      <div className="overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm">
        {loading ? (
          <div className="flex min-h-[20vh] items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-teal-600" /></div>
        ) : rows.length === 0 ? (
          <div className="flex min-h-[16vh] items-center justify-center text-sm text-slate-400">{to("personEmptySupervisors")}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                  <th className="px-6 py-3">{to("personTableSupervisor")}</th>
                  <th className="px-6 py-3">{to("personTableCompany")}</th>
                  <th className="px-6 py-3">{to("personTableDate")}</th>
                  <th className="px-6 py-3">{to("tableStatus")}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                {rows.map((s) => (
                  <tr key={`${s._status}-${s.id}`} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="p-2 rounded-lg bg-blue-50 text-blue-600"><User className="w-4 h-4" /></div>
                        <div>
                          <p className="font-semibold text-slate-900 dark:text-slate-100">{s.user.full_name}</p>
                          <p className="text-xs text-slate-500">{s.user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-300">{s.company.name}</td>
                    <td className="px-6 py-4 text-sm text-slate-500">{format(new Date(s.user.created_at), "MMM d, yyyy")}</td>
                    <td className="px-6 py-4"><PersonStatusBadge status={s._status} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

export default function OrganizationsView({ proposals, loading, onReview, onActionComplete: _onActionComplete }: Props) {
  const to = useTranslations("AdminPortal.organizations");
  const ta = useTranslations("AdminPortal.approvals");
  const td = useTranslations("AdminPortal.dashboard");
  const [tab, setTab] = useState<OrgTab>("universities");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"All" | "Pending" | "Approved" | "Rejected" | "Suspended">("All");
  const [docUrl, setDocUrl] = useState<string | null>(null);

  const orgStatusLabel = (s: VerificationProposal["status"]) => {
    switch (s) {
      case "Pending": return to("statusPending");
      case "Approved": return to("statusApproved");
      case "Rejected": return to("statusRejected");
      case "Suspended": return to("statusSuspended");
      default: return s;
    }
  };

  const orgListStatusLabel = (s: typeof statusFilter) => {
    switch (s) {
      case "All": return to("statusAll");
      case "Pending": return to("statusPending");
      case "Approved": return to("statusApproved");
      case "Rejected": return to("statusRejected");
      case "Suspended": return to("statusSuspended");
    }
  };

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    return proposals.filter((p) => {
      const matchesType = tab === "universities" ? p.organizationType === "University" : p.organizationType === "Company";
      const matchesSearch = !q || p.organizationName.toLowerCase().includes(q) || (p.description ?? "").toLowerCase().includes(q);
      const matchesStatus = statusFilter === "All" || p.status === statusFilter;
      return matchesType && matchesSearch && matchesStatus;
    });
  }, [proposals, tab, search, statusFilter]);

  const counts = useMemo(() => {
    const byType = (type: "University" | "Company") => proposals.filter((p) => p.organizationType === type);
    return {
      universities: byType("University").length,
      uniPending: byType("University").filter((p) => p.status === "Pending").length,
      companies: byType("Company").length,
      compPending: byType("Company").filter((p) => p.status === "Pending").length,
    };
  }, [proposals]);

  const navTabs = useMemo<OrgNavTab[]>(
    () => [
      { id: "universities", label: to("tabUniversities"), icon: Building, count: counts.universities, pending: counts.uniPending },
      { id: "companies", label: to("tabCompanies"), icon: Briefcase, count: counts.companies, pending: counts.compPending },
      { id: "coordinators", label: to("tabCoordinators"), icon: UserCheck },
      { id: "supervisors", label: to("tabSupervisors"), icon: Briefcase },
    ],
    [to, counts.universities, counts.uniPending, counts.companies, counts.compPending]
  );

  const typeTotal = proposals.filter((p) => (tab === "universities" ? p.organizationType === "University" : p.organizationType === "Company")).length;

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <AdminPageHero
        badge={to("heroBadge")}
        title={to("heroTitle")}
        description={to("heroDescription")}
      />

      <div className="flex gap-1 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 p-1">
        {navTabs.map((tabItem) => (
          <button key={tabItem.id} type="button"
            onClick={() => { setTab(tabItem.id); setSearch(""); setStatusFilter("All"); }}
            className={cn(
              "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
              tab === tabItem.id
                ? "bg-white dark:bg-slate-800 text-teal-700 dark:text-teal-300 shadow-sm ring-1 ring-slate-200 dark:ring-slate-700"
                : "text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200"
            )}>
            <tabItem.icon className="h-4 w-4 shrink-0" />
            <span className="hidden sm:inline">{tabItem.label}</span>
            {tabItem.count !== undefined && (
              <span className={cn("rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums",
                tab === tabItem.id ? "bg-teal-100 text-teal-800" : "bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300")}>
                {tabItem.count}
              </span>
            )}
            {tabItem.pending !== undefined && tabItem.pending > 0 && (
              <span className="rounded-full bg-amber-100 px-1.5 py-0.5 text-[10px] font-bold tabular-nums text-amber-800">
                {to("pendingBadge", { count: tabItem.pending })}
              </span>
            )}
          </button>
        ))}
      </div>

      {tab === "coordinators" && <CoordinatorsPanel />}
      {tab === "supervisors" && <SupervisorsPanel />}

      {(tab === "universities" || tab === "companies") && (
        <>
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input type="text" value={search} onChange={(e) => setSearch(e.target.value)}
                placeholder={tab === "universities" ? to("searchUniversities") : to("searchCompanies")}
                className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-2.5 pl-9 pr-4 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20" />
            </div>
            <div className="flex items-center gap-1.5 flex-wrap">
              <Filter className="h-4 w-4 text-slate-400 shrink-0" />
              {(["All", "Pending", "Approved", "Rejected", "Suspended"] as const).map((s) => (
                <button key={s} type="button" onClick={() => setStatusFilter(s)}
                  className={cn("rounded-full px-3 py-1 text-xs font-semibold transition-all",
                    statusFilter === s ? "bg-teal-600 text-white shadow-sm" : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700")}>
                  {orgListStatusLabel(s)}
                </button>
              ))}
            </div>
          </div>

          <div className="overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm">
            {loading ? (
              <div className="flex min-h-[30vh] items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-teal-600" />
              </div>
            ) : filtered.length === 0 ? (
              <div className="flex min-h-[20vh] items-center justify-center text-sm text-slate-400">
                {to("emptyFiltered")}
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                      <th className="px-6 py-3">{to("tableName")}</th>
                      <th className="px-6 py-3">{to("tableEmail")}</th>
                      <th className="px-6 py-3">{to("tableAddress")}</th>
                      <th className="px-6 py-3">{to("tableStatus")}</th>
                      <th className="px-6 py-3">{to("tableRegistered")}</th>
                      <th className="px-6 py-3">{to("tableDocuments")}</th>
                      <th className="px-6 py-3 text-right">{to("tableActions")}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                    {filtered.map((p) => {
                      const cfg = STATUS_CONFIG[p.status] ?? STATUS_CONFIG.Pending;
                      return (
                        <tr key={p.id} className="hover:bg-slate-50/60 dark:hover:bg-slate-800/40 transition-colors">
                          <td className="px-6 py-4">
                            <p className="font-semibold text-slate-900 dark:text-slate-100">{p.organizationName}</p>
                          </td>
                          <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-300">
                            {p.email ? (
                              <a href={`mailto:${p.email}`} className="hover:text-teal-600 hover:underline">{p.email}</a>
                            ) : (
                              <span className="text-xs text-slate-400 italic">{td("activityDash")}</span>
                            )}
                          </td>
                          <td className="px-6 py-4 text-xs text-slate-500 dark:text-slate-400 max-w-[160px] truncate">
                            {p.description || <span className="italic text-slate-400">{td("activityDash")}</span>}
                          </td>
                          <td className="px-6 py-4">
                            <span className={cn("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-bold ring-1", cfg.bg, cfg.text, cfg.ring)}>
                              {orgStatusLabel(p.status)}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-slate-500 text-xs">
                            {format(new Date(p.submittedAt), "MMM d, yyyy")}
                          </td>
                          <td className="px-6 py-4">
                          <div className="flex flex-col gap-1">
                              {p.documents?.[0] ? (
                                <button
                                  type="button"
                                  onClick={() => setDocUrl(p.documents[0])}
                                  className="inline-flex items-center gap-1 text-xs font-medium text-teal-600 hover:text-teal-700">
                                  <FileText className="h-3 w-3" /> {to("orgDocVerify")}
                                </button>
                              ) : (
                                <span className="text-xs text-slate-400 italic">{to("orgNoDoc")}</span>
                              )}
                              {p.stampImageUrl && (
                                <button
                                  type="button"
                                  onClick={() => setDocUrl(p.stampImageUrl!)}
                                  className="inline-flex items-center gap-1 text-xs font-medium text-teal-600 hover:text-teal-700">
                                  <FileText className="h-3 w-3" /> {to("orgDocStamp")}
                                </button>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4">
                            <div className="flex items-center justify-end gap-1.5">
                              <button type="button" onClick={() => onReview(p)}
                                className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-1.5 text-xs font-semibold text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
                                {ta("review")}
                              </button>
                              {p.status === "Pending" && (
                                <button type="button" onClick={() => onReview(p)}
                                  className="inline-flex items-center gap-1 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 transition-colors">
                                  <CheckCircle2 className="h-3.5 w-3.5" /> {ta("approve")}
                                </button>
                              )}
                              {p.status === "Approved" && (
                                <button type="button" onClick={() => onReview(p)}
                                  className="inline-flex items-center gap-1 rounded-lg bg-amber-50 border border-amber-200 px-3 py-1.5 text-xs font-semibold text-amber-700 hover:bg-amber-100 transition-colors">
                                  <Ban className="h-3.5 w-3.5" /> {to("actionSuspend")}
                                </button>
                              )}
                              {p.status === "Suspended" && (
                                <button type="button" onClick={() => onReview(p)}
                                  className="inline-flex items-center gap-1 rounded-lg bg-teal-50 border border-teal-200 px-3 py-1.5 text-xs font-semibold text-teal-700 hover:bg-teal-100 transition-colors">
                                  <RotateCcw className="h-3.5 w-3.5" /> {to("actionReactivate")}
                                </button>
                              )}
                              {p.status === "Rejected" && (
                                <button type="button" onClick={() => onReview(p)}
                                  className="inline-flex items-center gap-1 rounded-lg bg-emerald-50 border border-emerald-200 px-3 py-1.5 text-xs font-semibold text-emerald-700 hover:bg-emerald-100 transition-colors">
                                  <CheckCircle2 className="h-3.5 w-3.5" /> {ta("approve")}
                                </button>
                              )}
                              {(p.status === "Pending" || p.status === "Approved") && (
                                <button type="button" onClick={() => onReview(p)}
                                  className="inline-flex items-center gap-1 rounded-lg bg-red-50 border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 transition-colors">
                                  <XCircle className="h-3.5 w-3.5" /> {ta("reject")}
                                </button>
                              )}
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <p className="text-xs text-slate-400 text-right">
            {to("listFooter", { filtered: filtered.length, total: typeTotal })}
          </p>
        </>
      )}
      <PdfViewerModal
        isOpen={!!docUrl}
        pdfUrl={docUrl ?? ""}
        title={to("pdfTitle")}
        onClose={() => setDocUrl(null)}
      />
    </div>
  );
}
