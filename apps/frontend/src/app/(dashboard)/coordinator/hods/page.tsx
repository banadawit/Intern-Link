"use client";

import { useCallback, useEffect, useState } from "react";
import {
  CheckCircle,
  XCircle,
  FileText,
  User,
  Building,
  Loader2,
  ExternalLink,
  RefreshCw,
} from "lucide-react";
import { format } from "date-fns";
import api from "@/lib/api/client";
import CoordinatorPageHero from "../CoordinatorPageHero";

interface PendingHod {
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

export default function CoordinatorHodsPage() {
  const [hods, setHods] = useState<PendingHod[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<number | null>(null);
  const [rejectReason, setRejectReason] = useState<{ userId: number; reason: string } | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get<PendingHod[]>("/coordinator/pending-hods");
      setHods(data);
    } catch {
      setError("Could not load pending HoD accounts.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const handleApprove = async (userId: number) => {
    setActionLoading(userId);
    setError(null);
    try {
      await api.patch("/coordinator/verify-hod", { userId, status: "APPROVED" });
      await load();
    } catch {
      setError("Failed to approve HoD.");
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async () => {
    if (!rejectReason) return;
    setActionLoading(rejectReason.userId);
    setError(null);
    try {
      await api.patch("/coordinator/verify-hod", {
        userId: rejectReason.userId,
        status: "REJECTED",
        reason: rejectReason.reason,
      });
      setRejectReason(null);
      await load();
    } catch {
      setError("Failed to reject HoD.");
    } finally {
      setActionLoading(null);
    }
  };

  const backendUrl = process.env.NEXT_PUBLIC_API_URL?.replace("/api", "") || "http://localhost:5000";

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <CoordinatorPageHero
        badge="HoD Approvals"
        title="Pending Head of Department Approvals"
        description="Review and approve Head of Department registrations for your university."
        action={
          <button
            type="button"
            onClick={() => void load()}
            disabled={loading}
            className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50 disabled:opacity-60 transition-colors"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
            Refresh
          </button>
        }
      />

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          {error}
        </div>
      )}

      {loading && hods.length === 0 ? (
        <div className="flex min-h-[40vh] items-center justify-center">
          <Loader2 className="h-10 w-10 animate-spin text-primary-600" />
        </div>
      ) : (
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-slate-100 text-slate-500 text-xs uppercase tracking-wider">
                  <th className="px-6 py-4 font-semibold">Head of Department</th>
                  <th className="px-6 py-4 font-semibold">Department</th>
                  <th className="px-6 py-4 font-semibold">Document</th>
                  <th className="px-6 py-4 font-semibold">Submitted</th>
                  <th className="px-6 py-4 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {hods.map((h) => (
                  <tr key={h.userId} className="hover:bg-slate-50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="p-2 rounded-lg bg-violet-50 text-violet-600">
                          <User className="w-5 h-5" />
                        </div>
                        <div>
                          <p className="font-semibold text-slate-900">{h.user.full_name}</p>
                          <p className="text-xs text-slate-500">{h.user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2 text-sm text-slate-700">
                        <Building className="w-4 h-4 text-slate-400" />
                        {h.department || <span className="italic text-slate-400">Not provided</span>}
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
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleApprove(h.user.id)}
                          disabled={actionLoading === h.user.id}
                          className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-60 transition-colors"
                        >
                          {actionLoading === h.user.id ? (
                            <Loader2 className="w-3.5 h-3.5 animate-spin" />
                          ) : (
                            <CheckCircle className="w-3.5 h-3.5" />
                          )}
                          Approve
                        </button>
                        <button
                          onClick={() => setRejectReason({ userId: h.user.id, reason: "" })}
                          disabled={actionLoading === h.user.id}
                          className="inline-flex items-center gap-1.5 rounded-lg bg-red-50 border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-100 disabled:opacity-60 transition-colors"
                        >
                          <XCircle className="w-3.5 h-3.5" />
                          Reject
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!loading && hods.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-slate-500">
                      No pending HoD approvals.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Reject Modal */}
      {rejectReason && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-xl p-6 w-full max-w-md mx-4 space-y-4">
            <h3 className="text-lg font-bold text-slate-900">Reject Head of Department</h3>
            <p className="text-sm text-slate-500">
              Provide a reason for rejection. This will be sent to the HoD by email.
            </p>
            <textarea
              value={rejectReason.reason}
              onChange={(e) => setRejectReason({ ...rejectReason, reason: e.target.value })}
              placeholder="e.g., Staff ID document is unclear or invalid..."
              rows={3}
              className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-400 resize-none"
            />
            <div className="flex gap-3 pt-1">
              <button
                onClick={() => setRejectReason(null)}
                className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={actionLoading !== null}
                className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60 transition-colors"
              >
                {actionLoading !== null ? "Rejecting…" : "Confirm Reject"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
