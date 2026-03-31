"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle, CheckCircle2, Clock } from "lucide-react";

type ProposalRow = {
  id: number;
  studentId: number;
  status: string;
  submitted_at: string;
  responseDueAt: string;
  slaOverdue: boolean;
  slaRemainingMs: number;
  student: { user: { full_name: string; email: string } };
  university: { name: string };
};

export default function SupervisorProposalsPage() {
  const [rows, setRows] = useState<ProposalRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actingId, setActingId] = useState<number | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<ProposalRow[]>("/placements/incoming");
      setRows(res.data);
    } catch {
      setError("Could not load proposals.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const respond = async (id: number, status: "APPROVED" | "REJECTED") => {
    setActingId(id);
    try {
      await api.patch(`/placements/respond/${id}`, { status });
      await load();
    } catch {
      setError("Failed to update proposal.");
    } finally {
      setActingId(null);
    }
  };

  const formatRemaining = (ms: number) => {
    if (ms < 0) return "Overdue";
    const h = Math.floor(ms / 3600000);
    const m = Math.floor((ms % 3600000) / 60000);
    return `${h}h ${m}m left`;
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Incoming proposals</h1>
        <p className="mt-1 text-sm text-slate-500">
          Approve or reject placement requests from universities (24h response window).
        </p>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          <AlertCircle className="h-4 w-4 shrink-0" />
          {error}
        </div>
      )}

      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
        {loading ? (
          <p className="p-8 text-center text-slate-500">Loading…</p>
        ) : rows.length === 0 ? (
          <p className="p-8 text-center text-slate-500">No pending proposals.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] text-left text-sm">
              <thead className="border-b border-slate-100 bg-slate-50/80">
                <tr>
                  <th className="px-4 py-3 font-semibold text-slate-700">Student</th>
                  <th className="px-4 py-3 font-semibold text-slate-700">University</th>
                  <th className="px-4 py-3 font-semibold text-slate-700">SLA</th>
                  <th className="px-4 py-3 font-semibold text-slate-700 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {rows.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/50">
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-900">{p.student.user.full_name}</p>
                      <p className="text-xs text-slate-500">{p.student.user.email}</p>
                    </td>
                    <td className="px-4 py-3 text-slate-700">{p.university.name}</td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium ${
                          p.slaOverdue
                            ? "bg-red-100 text-red-800"
                            : "bg-amber-50 text-amber-900"
                        }`}
                      >
                        <Clock className="h-3.5 w-3.5" />
                        {p.slaOverdue ? "Overdue" : formatRemaining(p.slaRemainingMs)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex justify-end gap-2">
                        <button
                          type="button"
                          disabled={actingId === p.id}
                          onClick={() => void respond(p.id, "REJECTED")}
                          className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                        >
                          Reject
                        </button>
                        <button
                          type="button"
                          disabled={actingId === p.id}
                          onClick={() => void respond(p.id, "APPROVED")}
                          className="inline-flex items-center gap-1 rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                        >
                          <CheckCircle2 className="h-3.5 w-3.5" />
                          Approve
                        </button>
                      </div>
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
