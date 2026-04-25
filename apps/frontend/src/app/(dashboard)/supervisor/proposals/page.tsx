"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api/client";
import { AlertCircle, CheckCircle2, Clock, XCircle, FileText, ChevronDown, ChevronUp } from "lucide-react";

type ProposalRow = {
  id: number;
  studentId: number;
  status: string;
  submitted_at: string;
  responseDueAt: string;
  slaOverdue: boolean;
  slaRemainingMs: number;
  expected_duration_weeks: number | null;
  expected_outcomes: string | null;
  student: {
    department: string | null;
    studentId: string | null;
    user: {
      full_name: string;
      email: string;
      verification_document: string | null;
    };
  };
  university: { name: string };
};

export default function SupervisorProposalsPage() {
  const [rows, setRows] = useState<ProposalRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actingId, setActingId] = useState<number | null>(null);
  const [rejectModal, setRejectModal] = useState<{ id: number; name: string } | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [expandedId, setExpandedId] = useState<number | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.get<{ success: boolean; data: ProposalRow[] }>("/placements/incoming");
      setRows(Array.isArray(res.data.data) ? res.data.data : []);
    } catch {
      setError("Could not load proposals.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  const approve = async (id: number) => {
    setActingId(id);
    try {
      await api.patch(`/placements/respond/${id}`, { status: "APPROVED" });
      await load();
    } catch {
      setError("Failed to approve proposal.");
    } finally {
      setActingId(null);
    }
  };

  const confirmReject = async () => {
    if (!rejectModal) return;
    setActingId(rejectModal.id);
    try {
      await api.patch(`/placements/respond/${rejectModal.id}`, {
        status: "REJECTED",
        reason: rejectReason.trim() || "The company was unable to accommodate your application at this time.",
      });
      setRejectModal(null);
      setRejectReason("");
      await load();
    } catch {
      setError("Failed to reject proposal.");
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

  const toggleExpand = (id: number) => {
    setExpandedId((prev) => (prev === id ? null : id));
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
          <div className="divide-y divide-slate-100">
            {rows.map((p) => (
              <div key={p.id}>
                {/* Main row */}
                <div className="flex flex-col gap-3 px-4 py-4 sm:flex-row sm:items-center sm:gap-4">
                  {/* Student info */}
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="font-semibold text-slate-900">{p.student.user.full_name}</p>
                      {p.student.studentId && (
                        <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-500">
                          ID: {p.student.studentId}
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-slate-500">{p.student.user.email}</p>
                    <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-slate-500">
                      <span>{p.university.name}</span>
                      {p.student.department && (
                        <>
                          <span className="text-slate-300">·</span>
                          <span>{p.student.department}</span>
                        </>
                      )}
                      {p.expected_duration_weeks && (
                        <>
                          <span className="text-slate-300">·</span>
                          <span>{p.expected_duration_weeks} weeks</span>
                        </>
                      )}
                    </div>
                  </div>

                  {/* SLA badge */}
                  <span className={`inline-flex shrink-0 items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium ${
                    p.slaOverdue ? "bg-red-100 text-red-800" : "bg-amber-50 text-amber-900"
                  }`}>
                    <Clock className="h-3.5 w-3.5" />
                    {p.slaOverdue ? "Overdue" : formatRemaining(p.slaRemainingMs)}
                  </span>

                  {/* Actions */}
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      type="button"
                      onClick={() => toggleExpand(p.id)}
                      className="inline-flex items-center gap-1 rounded-lg border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-semibold text-slate-600 hover:bg-slate-100"
                    >
                      {expandedId === p.id ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />}
                      Details
                    </button>
                    <button
                      type="button"
                      disabled={actingId === p.id}
                      onClick={() => { setRejectModal({ id: p.id, name: p.student.user.full_name }); setRejectReason(""); }}
                      className="inline-flex items-center gap-1 rounded-lg border border-red-200 bg-red-50 px-3 py-1.5 text-xs font-semibold text-red-700 hover:bg-red-100 disabled:opacity-50"
                    >
                      <XCircle className="h-3.5 w-3.5" />
                      Reject
                    </button>
                    <button
                      type="button"
                      disabled={actingId === p.id}
                      onClick={() => void approve(p.id)}
                      className="inline-flex items-center gap-1 rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                    >
                      <CheckCircle2 className="h-3.5 w-3.5" />
                      Approve
                    </button>
                  </div>
                </div>

                {/* Expanded details panel */}
                {expandedId === p.id && (
                  <div className="border-t border-slate-100 bg-slate-50/60 px-4 py-4 space-y-3">
                    <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                      {p.student.department && (
                        <div>
                          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Department</p>
                          <p className="mt-0.5 text-sm text-slate-700">{p.student.department}</p>
                        </div>
                      )}
                      {p.student.studentId && (
                        <div>
                          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Student ID</p>
                          <p className="mt-0.5 text-sm text-slate-700">{p.student.studentId}</p>
                        </div>
                      )}
                      {p.expected_duration_weeks && (
                        <div>
                          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Expected Duration</p>
                          <p className="mt-0.5 text-sm text-slate-700">{p.expected_duration_weeks} weeks</p>
                        </div>
                      )}
                      <div>
                        <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Submitted</p>
                        <p className="mt-0.5 text-sm text-slate-700">
                          {new Date(p.submitted_at).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}
                        </p>
                      </div>
                    </div>

                    {p.expected_outcomes && (
                      <div>
                        <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Expected Outcomes</p>
                        <p className="mt-0.5 text-sm text-slate-700 whitespace-pre-wrap">{p.expected_outcomes}</p>
                      </div>
                    )}

                    {p.student.user.verification_document && (
                      <div>
                        <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Verification Document</p>
                        <a
                          href={p.student.user.verification_document}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="mt-1 inline-flex items-center gap-1.5 rounded-lg border border-primary-200 bg-primary-50 px-3 py-1.5 text-xs font-semibold text-primary-700 hover:bg-primary-100"
                        >
                          <FileText className="h-3.5 w-3.5" />
                          View Document
                        </a>
                      </div>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Rejection reason modal */}
      {rejectModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl mx-4 space-y-4">
            <h3 className="text-lg font-bold text-slate-900">Reject proposal</h3>
            <p className="text-sm text-slate-500">
              You are rejecting <strong>{rejectModal.name}</strong>&apos;s application.
              Please provide a reason — this will be sent to the student by email.
            </p>
            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="e.g. We have already reached our intern capacity for this period..."
              rows={4}
              className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-red-400/30 focus:border-red-400 resize-none"
            />
            <div className="flex gap-3 pt-1">
              <button
                type="button"
                onClick={() => setRejectModal(null)}
                className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => void confirmReject()}
                disabled={actingId !== null}
                className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60"
              >
                {actingId !== null ? "Rejecting…" : "Confirm Reject"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
