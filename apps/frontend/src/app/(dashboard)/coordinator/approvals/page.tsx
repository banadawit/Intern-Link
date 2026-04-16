"use client";

import { useCallback, useEffect, useState } from "react";
import { CheckCircle, XCircle, User, Building, FileText, ExternalLink } from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";
import api from "@/lib/api/client";
import CoordinatorPageHero from "../CoordinatorPageHero";

interface HodRecord {
  id: number;
  userId: number;
  department: string;
  university: { name: string };
  user: {
    id: number;
    full_name: string;
    email: string;
    verification_document: string | null;
    created_at: string;
    institution_access_approval: string;
  };
}

type Tab = "approved" | "rejected";

export default function CoordinatorApprovalsPage() {
  const [activeTab, setActiveTab] = useState<Tab>("approved");
  const [approved, setApproved] = useState<HodRecord[]>([]);
  const [rejected, setRejected] = useState<HodRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const backendUrl = process.env.NEXT_PUBLIC_API_URL?.replace("/api", "") || "http://localhost:5000";

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [approvedRes, rejectedRes] = await Promise.all([
        api.get<HodRecord[]>("/coordinator/approved-hods"),
        api.get<HodRecord[]>("/coordinator/rejected-hods"),
      ]);
      setApproved(approvedRes.data);
      setRejected(rejectedRes.data);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error;
      setError(msg || "Could not load approval history.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const rows = activeTab === "approved" ? approved : rejected;

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <CoordinatorPageHero
        badge="Approvals"
        title="HOD Approval History"
        description="View all approved and rejected Head of Department registrations for your university."
      />

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          {error}
        </div>
      )}

      {/* Tab bar */}
      <div className="flex gap-1 rounded-2xl border border-slate-200 bg-slate-50 p-1">
        {(["approved", "rejected"] as Tab[]).map((tab) => {
          const isActive = activeTab === tab;
          const count = tab === "approved" ? approved.length : rejected.length;
          return (
            <button
              key={tab}
              type="button"
              onClick={() => setActiveTab(tab)}
              className={cn(
                "flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition-all duration-200",
                isActive ? "bg-white text-primary-700 shadow-sm ring-1 ring-slate-200" : "text-slate-500 hover:text-slate-700"
              )}
            >
              {tab === "approved"
                ? <CheckCircle className="h-4 w-4 shrink-0" />
                : <XCircle className="h-4 w-4 shrink-0" />}
              <span className="capitalize">{tab}</span>
              {!loading && count > 0 && (
                <span className={cn(
                  "rounded-full px-1.5 py-0.5 text-[10px] font-bold tabular-nums",
                  isActive
                    ? "bg-primary-100 text-primary-800 ring-1 ring-primary-200/80"
                    : tab === "approved"
                      ? "bg-emerald-100 text-emerald-700 ring-1 ring-emerald-200/80"
                      : "bg-red-100 text-red-700 ring-1 ring-red-200/80"
                )}>
                  {count > 99 ? "99+" : count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      <div className="card overflow-hidden">
        {loading ? (
          <p className="p-6 text-sm text-slate-500">Loading…</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider">
                  <th className="px-6 py-4 font-semibold">Head of Department</th>
                  <th className="px-6 py-4 font-semibold">Department</th>
                  <th className="px-6 py-4 font-semibold">Document</th>
                  <th className="px-6 py-4 font-semibold">Date</th>
                  <th className="px-6 py-4 font-semibold">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {rows.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-sm text-slate-500">
                      No {activeTab} HoDs yet.
                    </td>
                  </tr>
                )}
                {rows.map((h) => (
                  <tr key={h.userId} className="hover:bg-slate-50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className={cn("p-2 rounded-lg", activeTab === "approved" ? "bg-emerald-50 text-emerald-600" : "bg-red-50 text-red-500")}>
                          <User className="w-4 h-4" />
                        </div>
                        <div>
                          <p className="font-semibold text-slate-900 text-sm">{h.user.full_name}</p>
                          <p className="text-xs text-slate-500">{h.user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Building className="w-4 h-4 text-slate-400" />
                        {h.department || <span className="italic text-slate-400">—</span>}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {h.user.verification_document ? (
                        <a
                          href={`${backendUrl}/${h.user.verification_document.replace(/\\/g, "/")}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center gap-1.5 text-sm text-primary-600 hover:text-primary-700 font-medium"
                        >
                          <FileText className="w-4 h-4" />
                          View Doc
                          <ExternalLink className="w-3 h-3" />
                        </a>
                      ) : (
                        <span className="text-xs text-slate-400 italic">No document</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {format(new Date(h.user.created_at), "MMM d, yyyy")}
                    </td>
                    <td className="px-6 py-4">
                      {activeTab === "approved" ? (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-emerald-200">
                          <CheckCircle className="w-3 h-3" />Approved
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700 ring-1 ring-red-200">
                          <XCircle className="w-3 h-3" />Rejected
                        </span>
                      )}
                    </td>
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
