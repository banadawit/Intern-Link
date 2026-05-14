"use client";

import React, { useState, useMemo, useCallback, useEffect } from "react";
import {
  Briefcase, Search, XCircle, Ban,
  Loader2, Filter, UserCheck, User, CheckCircle, FileText,
  ChevronLeft, ChevronRight,
} from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";
import AdminPageHero from "./AdminPageHero";
import api from "@/lib/api/client";
import PdfViewerModal from "@/components/shared/PdfViewerModal";

type OrgTab = "coordinators" | "supervisors";
const PAGE_SIZE = 10;

interface Props {
  proposals: never[];
  loading: boolean;
  onReview: (p: never) => void;
  onActionComplete: () => void;
}

interface PersonUser {
  id: number; full_name: string; email: string;
  created_at: string; institution_access_approval?: string;
  verification_document?: string | null;
}
interface CoordinatorRow {
  id: number; userId: number;
  university: { id: number; name: string } | null;
  pending_university_name?: string | null;
  user: PersonUser;
}
interface SupervisorRow {
  id: number; userId: number;
  company: { id: number; name: string };
  user: PersonUser;
}
type PersonStatus = "approved" | "rejected" | "suspended";

function Pagination({ page, total, pageSize, onChange }: {
  page: number; total: number; pageSize: number; onChange: (p: number) => void;
}) {
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  if (totalPages <= 1) return null;
  return (
    <div className="flex items-center justify-between px-1 pt-2">
      <p className="text-xs text-slate-400">Page {page} of {totalPages} &middot; {total} total</p>
      <div className="flex items-center gap-1">
        <button type="button" disabled={page <= 1} onClick={() => onChange(page - 1)}
          className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-1.5 text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-700 disabled:opacity-40 transition-colors">
          <ChevronLeft className="h-4 w-4" />
        </button>
        {Array.from({ length: totalPages }, (_, i) => i + 1)
          .filter((n) => n === 1 || n === totalPages || Math.abs(n - page) <= 1)
          .reduce<(number | "…")[]>((acc, n, i, arr) => {
            if (i > 0 && n - (arr[i - 1] as number) > 1) acc.push("…");
            acc.push(n); return acc;
          }, [])
          .map((n, i) => n === "…"
            ? <span key={`e-${i}`} className="px-1 text-xs text-slate-400">…</span>
            : <button key={n} type="button" onClick={() => onChange(n as number)}
                className={cn("min-w-[28px] rounded-lg px-2 py-1 text-xs font-semibold transition-colors",
                  page === n ? "bg-teal-600 text-white" : "border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700")}>
                {n}
              </button>
          )}
        <button type="button" disabled={page >= totalPages} onClick={() => onChange(page + 1)}
          className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 p-1.5 text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-700 disabled:opacity-40 transition-colors">
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}

function usePersonList<T>(endpoint: string) {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get<T[]>(endpoint);
      setData(res);
    } finally { setLoading(false); }
  }, [endpoint]);
  useEffect(() => { void load(); }, [load]);
  return { data, loading };
}

function statusBadge(status: PersonStatus) {
  if (status === "approved")
    return <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-emerald-200"><CheckCircle className="w-3 h-3" /> Approved</span>;
  if (status === "rejected")
    return <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700 ring-1 ring-red-200"><XCircle className="w-3 h-3" /> Rejected</span>;
  return <span className="inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 ring-1 ring-slate-300"><Ban className="w-3 h-3" /> Suspended</span>;
}

function CoordinatorsPanel() {
  type StatusFilter = "all" | PersonStatus;
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [docUrl, setDocUrl] = useState<string | null>(null);

  const { data: approved, loading: l1 } = usePersonList<CoordinatorRow>("/admin/approved-coordinators");
  const { data: rejected, loading: l2 } = usePersonList<CoordinatorRow>("/admin/rejected-coordinators");
  const { data: suspended, loading: l3 } = usePersonList<CoordinatorRow>("/admin/suspended-coordinators");
  const loading = l1 || l2 || l3;

  const filtered = useMemo(() => {
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

  const rows = useMemo(() => filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE), [filtered, page]);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input type="text" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            placeholder="Search coordinators…"
            className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-2.5 pl-9 pr-4 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20" />
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          <Filter className="h-4 w-4 text-slate-400 shrink-0" />
          {(["all", "approved", "rejected", "suspended"] as StatusFilter[]).map((s) => (
            <button key={s} type="button" onClick={() => { setStatusFilter(s); setPage(1); }}
              className={cn("rounded-full px-3 py-1 text-xs font-semibold transition-all capitalize",
                statusFilter === s ? "bg-teal-600 text-white shadow-sm" : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700")}>
              {s}
            </button>
          ))}
        </div>
      </div>
      <div className="overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm">
        {loading ? (
          <div className="flex min-h-[20vh] items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-teal-600" /></div>
        ) : rows.length === 0 ? (
          <div className="flex min-h-[16vh] items-center justify-center text-sm text-slate-400">No coordinators match your filters.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                  <th className="px-6 py-3">Coordinator</th>
                  <th className="px-6 py-3">University</th>
                  <th className="px-6 py-3">Registered</th>
                  <th className="px-6 py-3">Document</th>
                  <th className="px-6 py-3">Status</th>
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
                      {c.university?.name ?? c.pending_university_name ?? <span className="italic text-slate-400">—</span>}
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500">{format(new Date(c.user.created_at), "MMM d, yyyy")}</td>
                    <td className="px-6 py-4">
                      {c.user.verification_document ? (
                        <button type="button" onClick={() => setDocUrl(c.user.verification_document!)}
                          className="inline-flex items-center gap-1.5 text-xs font-medium text-teal-600 hover:text-teal-700">
                          <FileText className="w-3.5 h-3.5" /> View doc
                        </button>
                      ) : <span className="text-xs text-slate-400 italic">—</span>}
                    </td>
                    <td className="px-6 py-4">{statusBadge(c._status)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
      <Pagination page={page} total={filtered.length} pageSize={PAGE_SIZE} onChange={setPage} />
      <PdfViewerModal isOpen={!!docUrl} pdfUrl={docUrl ?? ""} title="Verification Document" onClose={() => setDocUrl(null)} />
    </div>
  );
}

function SupervisorsPanel() {
  type StatusFilter = "all" | PersonStatus;
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [docUrl, setDocUrl] = useState<string | null>(null);

  const { data: approved, loading: l1 } = usePersonList<SupervisorRow>("/admin/approved-supervisors");
  const { data: rejected, loading: l2 } = usePersonList<SupervisorRow>("/admin/rejected-supervisors");
  const { data: suspended, loading: l3 } = usePersonList<SupervisorRow>("/admin/suspended-supervisors");
  const loading = l1 || l2 || l3;

  const filtered = useMemo(() => {
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

  const rows = useMemo(() => filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE), [filtered, page]);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input type="text" value={search} onChange={(e) => { setSearch(e.target.value); setPage(1); }}
            placeholder="Search supervisors…"
            className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 py-2.5 pl-9 pr-4 text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:border-teal-500 focus:outline-none focus:ring-2 focus:ring-teal-500/20" />
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          <Filter className="h-4 w-4 text-slate-400 shrink-0" />
          {(["all", "approved", "rejected", "suspended"] as StatusFilter[]).map((s) => (
            <button key={s} type="button" onClick={() => { setStatusFilter(s); setPage(1); }}
              className={cn("rounded-full px-3 py-1 text-xs font-semibold transition-all capitalize",
                statusFilter === s ? "bg-teal-600 text-white shadow-sm" : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700")}>
              {s}
            </button>
          ))}
        </div>
      </div>
      <div className="overflow-hidden rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-sm">
        {loading ? (
          <div className="flex min-h-[20vh] items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-teal-600" /></div>
        ) : rows.length === 0 ? (
          <div className="flex min-h-[16vh] items-center justify-center text-sm text-slate-400">No supervisors match your filters.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                  <th className="px-6 py-3">Supervisor</th>
                  <th className="px-6 py-3">Company</th>
                  <th className="px-6 py-3">Registered</th>
                  <th className="px-6 py-3">Document</th>
                  <th className="px-6 py-3">Status</th>
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
                    <td className="px-6 py-4">
                      {s.user.verification_document ? (
                        <button type="button" onClick={() => setDocUrl(s.user.verification_document!)}
                          className="inline-flex items-center gap-1.5 text-xs font-medium text-teal-600 hover:text-teal-700">
                          <FileText className="w-3.5 h-3.5" /> View doc
                        </button>
                      ) : <span className="text-xs text-slate-400 italic">—</span>}
                    </td>
                    <td className="px-6 py-4">{statusBadge(s._status)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
      <Pagination page={page} total={filtered.length} pageSize={PAGE_SIZE} onChange={setPage} />
      <PdfViewerModal isOpen={!!docUrl} pdfUrl={docUrl ?? ""} title="Verification Document" onClose={() => setDocUrl(null)} />
    </div>
  );
}

export default function OrganizationsView(_props: Props) {
  const [tab, setTab] = useState<OrgTab>("coordinators");

  const orgTabs: Array<{ id: OrgTab; label: string; icon: React.ComponentType<{ className?: string }> }> = [
    { id: "coordinators", label: "Coordinators", icon: UserCheck },
    { id: "supervisors",  label: "Supervisors",  icon: Briefcase },
  ];

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <AdminPageHero
        badge="Members"
        title="Coordinators & Supervisors"
        description="View all registered coordinators and supervisors on the platform."
      />
      <div className="flex gap-1 rounded-2xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900 p-1">
        {orgTabs.map((t) => (
          <button key={t.id} type="button" onClick={() => setTab(t.id)}
            className={cn(
              "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
              tab === t.id
                ? "bg-white dark:bg-slate-800 text-teal-700 dark:text-teal-300 shadow-sm ring-1 ring-slate-200 dark:ring-slate-700"
                : "text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200"
            )}>
            <t.icon className="h-4 w-4 shrink-0" />
            <span className="hidden sm:inline">{t.label}</span>
          </button>
        ))}
      </div>
      {tab === "coordinators" && <CoordinatorsPanel />}
      {tab === "supervisors" && <SupervisorsPanel />}
    </div>
  );
}
