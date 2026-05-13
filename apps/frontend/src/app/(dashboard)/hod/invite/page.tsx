"use client";

import { useState, useEffect, useCallback } from "react";
import { Clock, CheckCircle2, XCircle, RefreshCw, Mail } from "lucide-react";
import api from "@/lib/api/client";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodInviteCompanyForm from "@/components/hod/HodInviteCompanyForm";
import { useTranslations } from "next-intl";

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
      <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700 ring-1 ring-emerald-200">
        <CheckCircle2 className="h-3.5 w-3.5" />
        Accepted
      </span>
    );
  }
  if (status === "REJECTED") {
    return (
      <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-2.5 py-1 text-xs font-medium text-red-700 ring-1 ring-red-200">
        <XCircle className="h-3.5 w-3.5" />
        Rejected
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-medium text-amber-700 ring-1 ring-amber-200">
      <Clock className="h-3.5 w-3.5" />
      Pending
    </span>
  );
}

export default function HodInvitePage() {
  const t = useTranslations("HodPortal.invite");
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteCompanyName, setInviteCompanyName] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [invitations, setInvitations] = useState<InvitedCompany[]>([]);
  const [loadingInvitations, setLoadingInvitations] = useState(true);

  const fetchInvitations = useCallback(async () => {
    setLoadingInvitations(true);
    try {
      const res = await api.get("/hod/invited-companies");
      setInvitations(res.data?.data ?? []);
    } catch {
      // silently fail — table still shows empty state
    } finally {
      setLoadingInvitations(false);
    }
  }, []);

  useEffect(() => {
    fetchInvitations();
  }, [fetchInvitations]);

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
      setSuccess("Invitation sent successfully.");
      fetchInvitations();
    } catch (err: unknown) {
      const ax = err as { response?: { data?: { error?: string } } };
      setError(ax.response?.data?.error || "Invite failed.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 pb-8">
      <HodPageHero
        badge="Outreach"
        title="Invite company"
        description="Send an email invitation so a company can register on InternLink and appear in the verification flow."
      />

      {error && (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          {error}
        </div>
      )}
      {success && (
        <div className="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
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

      {/* Invitation tracking */}
      <section className="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-slate-100 px-5 py-4">
          <div>
            <h2 className="text-sm font-semibold text-slate-800">Sent invitations</h2>
            <p className="mt-0.5 text-xs text-slate-500">Track whether invited companies have registered</p>
          </div>
          <button
            onClick={fetchInvitations}
            disabled={loadingInvitations}
            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-50"
            aria-label="Refresh invitations"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${loadingInvitations ? "animate-spin" : ""}`} />
            Refresh
          </button>
        </div>

        {loadingInvitations ? (
          <div className="flex items-center justify-center py-12 text-sm text-slate-400">
            Loading...
          </div>
        ) : invitations.length === 0 ? (
          <div className="flex flex-col items-center justify-center gap-2 py-12 text-center">
            <Mail className="h-8 w-8 text-slate-300" />
            <p className="text-sm text-slate-500">No invitations sent yet</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50 text-left text-xs font-medium text-slate-500">
                  <th className="px-5 py-3">Company</th>
                  <th className="px-5 py-3">Email</th>
                  <th className="px-5 py-3">Invited on</th>
                  <th className="px-5 py-3">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {invitations.map((inv) => (
                  <tr key={inv.id} className="hover:bg-slate-50/50">
                    <td className="px-5 py-3 font-medium text-slate-800">{inv.name}</td>
                    <td className="px-5 py-3 text-slate-500">{inv.official_email}</td>
                    <td className="px-5 py-3 text-slate-500">
                      {new Date(inv.created_at).toLocaleDateString(undefined, {
                        year: "numeric",
                        month: "short",
                        day: "numeric",
                      })}
                    </td>
                    <td className="px-5 py-3">
                      <StatusBadge status={inv.approval_status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
