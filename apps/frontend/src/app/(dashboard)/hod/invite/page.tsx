"use client";

import { useState, useEffect, useCallback } from "react";
import { Clock, CheckCircle2, XCircle, RefreshCw, Mail, Send, Building2, Users, Trash2 } from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import Link from "next/link";
import api from "@/lib/api/client";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodInviteCompanyForm from "@/components/hod/HodInviteCompanyForm";
import { cn } from "@/lib/utils";

type InvitedCompany = {
  id: number;
  name: string;
  official_email: string;
  approval_status: string;
  created_at: string;
};

function StatusBadge({ status }: { status: string }) {
  if (status === "APPROVED") {
    return (
      <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-900/20 dark:text-emerald-300 dark:ring-emerald-800">
        <CheckCircle2 className="h-3.5 w-3.5" />
        Accepted
      </span>
    );
  }
  if (status === "REJECTED") {
    return (
      <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-2.5 py-1 text-xs font-medium text-red-700 ring-1 ring-red-200 dark:bg-red-900/20 dark:text-red-300 dark:ring-red-800">
        <XCircle className="h-3.5 w-3.5" />
        Rejected
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-medium text-amber-700 ring-1 ring-amber-200 dark:bg-amber-900/20 dark:text-amber-300 dark:ring-amber-800">
      <Clock className="h-3.5 w-3.5" />
      Pending
    </span>
  );
}

export default function HodInvitePage() {
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteCompanyName, setInviteCompanyName] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [invitations, setInvitations] = useState<InvitedCompany[]>([]);
  const [loadingInvitations, setLoadingInvitations] = useState(true);
  const [filter, setFilter] = useState<"all" | "pending" | "accepted">("all");

  const fetchInvitations = useCallback(async () => {
    setLoadingInvitations(true);
    try {
      const res = await api.get("/hod/invited-companies");
      setInvitations(res.data?.data ?? []);
    } catch {
      // silently fail
    } finally {
      setLoadingInvitations(false);
    }
  }, []);

  useEffect(() => { fetchInvitations(); }, [fetchInvitations]);

  // Auto-dismiss success after 4s
  useEffect(() => {
    if (!success) return;
    const t = setTimeout(() => setSuccess(null), 4000);
    return () => clearTimeout(t);
  }, [success]);

  const deleteInvitation = async (id: number) => {
    try {
      await api.delete(`/hod/invited-companies/${id}`);
      setInvitations((prev) => prev.filter((inv) => inv.id !== id));
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { message?: string; error?: string } } };
      const d = ax.response?.data;
      setError(d?.message ?? d?.error ?? "Could not remove invitation.");
    }
  };

  const sendInvite = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    setSuccess(null);
    try {
      await api.post("/hod/invite-company", {
        email: inviteEmail,
        company_name: inviteCompanyName,
      });
      setInviteEmail("");
      setInviteCompanyName("");
      setSuccess(`Invitation sent to ${inviteCompanyName}.`);
      fetchInvitations();
    } catch (err: unknown) {
      const ax = err as { response?: { data?: unknown } };
      const d = ax.response?.data as { message?: string; error?: string } | undefined;
      setError(d?.message ?? d?.error ?? "Invite failed.");
    } finally {
      setSubmitting(false);
    }
  };

  const accepted = invitations.filter((i) => i.approval_status === "APPROVED");
  const pending = invitations.filter((i) => i.approval_status === "PENDING");
  const rejected = invitations.filter((i) => i.approval_status === "REJECTED");

  const filtered = filter === "pending"
    ? pending
    : filter === "accepted"
      ? accepted
      : invitations;

  return (
    <div className="space-y-6 pb-8">
      <HodPageHero
        badge="Outreach"
        title="Invite company"
        description="Send an email invitation so a company can register on InternLink and appear in the verification flow."
      />

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800 dark:border-red-900/50 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </div>
      )}
      {success && (
        <div className="flex items-center gap-2 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800 dark:border-emerald-900/50 dark:bg-emerald-900/20 dark:text-emerald-300">
          <CheckCircle2 className="h-4 w-4 shrink-0" />
          {success}
        </div>
      )}

      <HodInviteCompanyForm
        inviteEmail={inviteEmail}
        inviteCompanyName={inviteCompanyName}
        submitting={submitting}
        onEmail={setInviteEmail}
        onCompanyName={setInviteCompanyName}
        onSubmit={sendInvite}
      />

      {/* Summary stat cards */}
      {invitations.length > 0 && (
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: "Total invited", value: invitations.length, icon: Users, color: "bg-primary-50 text-primary-600 dark:bg-primary-900/20 dark:text-primary-400" },
            { label: "Accepted", value: accepted.length, icon: CheckCircle2, color: "bg-emerald-50 text-emerald-600 dark:bg-emerald-900/20 dark:text-emerald-400" },
            { label: "Pending", value: pending.length, icon: Clock, color: "bg-amber-50 text-amber-600 dark:bg-amber-900/20 dark:text-amber-400" },
          ].map((s) => (
            <div key={s.label} className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-900">
              <div className={cn("rounded-xl p-2.5 shrink-0", s.color)}>
                <s.icon className="h-4 w-4" />
              </div>
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">{s.label}</p>
                <p className="text-xl font-bold text-slate-900 dark:text-slate-100">{s.value}</p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Invitation history */}
      <section className="rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-900">
        <div className="flex flex-col gap-3 border-b border-slate-100 px-5 py-4 sm:flex-row sm:items-center sm:justify-between dark:border-slate-700">
          <div>
            <h2 className="text-sm font-bold text-slate-800 dark:text-slate-100">Invitation history</h2>
            <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-400">
              {accepted.length > 0
                ? `${accepted.length} of ${invitations.length} companies have accepted`
                : "Track whether invited companies have registered"}
            </p>
          </div>
          <div className="flex items-center gap-2">
            {/* Filter tabs */}
            <div className="flex gap-1 rounded-lg border border-slate-200 bg-slate-50 p-0.5 dark:border-slate-700 dark:bg-slate-800">
              {(["all", "pending", "accepted"] as const).map((f) => (
                <button key={f} type="button" onClick={() => setFilter(f)}
                  className={cn("rounded-md px-2.5 py-1 text-xs font-semibold capitalize transition-colors",
                    filter === f
                      ? "bg-white text-slate-900 shadow-sm dark:bg-slate-900 dark:text-slate-100"
                      : "text-slate-500 hover:text-slate-700 dark:text-slate-400"
                  )}>
                  {f}
                </button>
              ))}
            </div>
            <button onClick={fetchInvitations} disabled={loadingInvitations}
              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800">
              <RefreshCw className={`h-3.5 w-3.5 ${loadingInvitations ? "animate-spin" : ""}`} />
              Refresh
            </button>
          </div>
        </div>

        {loadingInvitations ? (
          <div className="flex items-center justify-center py-12 text-sm text-slate-400">Loading...</div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center gap-2 py-12 text-center">
            <Mail className="h-8 w-8 text-slate-300 dark:text-slate-600" />
            <p className="text-sm text-slate-500 dark:text-slate-400">
              {filter === "all" ? "No invitations sent yet" : `No ${filter} invitations`}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50/80 text-left text-xs font-semibold text-slate-500 dark:border-slate-700 dark:bg-slate-800/70 dark:text-slate-400">
                  <th className="px-5 py-3">Company</th>
                  <th className="px-5 py-3">Email</th>
                  <th className="px-5 py-3">Invited</th>
                  <th className="px-5 py-3">Status</th>
                  <th className="px-5 py-3">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-700">
                {filtered.map((inv) => {
                  const daysSince = Math.floor((Date.now() - new Date(inv.created_at).getTime()) / 86400000);
                  const isOverdue = inv.approval_status === "PENDING" && daysSince > 7;
                  return (
                    <tr key={inv.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/60">
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-slate-100 dark:bg-slate-800">
                            <Building2 className="h-3.5 w-3.5 text-slate-500 dark:text-slate-400" />
                          </div>
                          <span className="font-medium text-slate-800 dark:text-slate-100">{inv.name}</span>
                        </div>
                      </td>
                      <td className="px-5 py-3 text-slate-500 dark:text-slate-400">{inv.official_email}</td>
                      <td className="px-5 py-3">
                        <p className="text-slate-600 dark:text-slate-300">
                          {new Date(inv.created_at).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" })}
                        </p>
                        <p className={cn("text-xs mt-0.5", isOverdue ? "text-red-500" : "text-slate-400 dark:text-slate-500")}>
                          {formatDistanceToNow(new Date(inv.created_at), { addSuffix: true })}
                          {isOverdue && " · overdue"}
                        </p>
                      </td>
                      <td className="px-5 py-3">
                        <StatusBadge status={inv.approval_status} />
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-2">
                          {inv.approval_status === "APPROVED" ? (
                            <Link
                              href={`/hod/placements?companyId=${inv.id}`}
                              className="inline-flex items-center gap-1.5 rounded-lg border border-primary-200 bg-primary-50 px-2.5 py-1 text-xs font-semibold text-primary-700 hover:bg-primary-100 transition-colors dark:border-primary-800 dark:bg-primary-900/20 dark:text-primary-400"
                            >
                              <Send className="h-3 w-3" />
                              Send proposal
                            </Link>
                          ) : inv.approval_status === "PENDING" ? (
                            <span className="text-xs text-slate-400 dark:text-slate-500">Awaiting registration</span>
                          ) : (
                            <span className="text-xs text-slate-400 dark:text-slate-500">—</span>
                          )}
                          {inv.approval_status !== "APPROVED" && (
                            <button
                              type="button"
                              onClick={() => void deleteInvitation(inv.id)}
                              title="Remove from history"
                              className="rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600 transition-colors dark:hover:bg-red-900/20 dark:hover:text-red-400"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
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

        {/* Accepted companies highlight */}
        {accepted.length > 0 && filter === "all" && (
          <div className="border-t border-slate-100 bg-emerald-50/50 px-5 py-3 dark:border-slate-700 dark:bg-emerald-900/10">
            <p className="text-xs font-medium text-emerald-700 dark:text-emerald-400 flex items-center gap-1.5">
              <CheckCircle2 className="h-3.5 w-3.5" />
              {accepted.length} company{accepted.length !== 1 ? "ies" : ""} accepted your invitation and joined InternLink.
              {accepted.length > 0 && (
                <Link href="/hod/placements" className="underline hover:no-underline ml-1">Send proposals →</Link>
              )}
            </p>
          </div>
        )}
      </section>
    </div>
  );
}
