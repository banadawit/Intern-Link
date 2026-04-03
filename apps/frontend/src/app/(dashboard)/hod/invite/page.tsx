"use client";

import { useState } from "react";
import api from "@/lib/api/client";
import HodPageHero from "@/app/(dashboard)/hod/HodPageHero";
import HodInviteCompanyForm from "@/components/hod/HodInviteCompanyForm";

export default function HodInvitePage() {
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteCompanyName, setInviteCompanyName] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

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
      setSuccess("Invitation sent.");
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
        <div className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">{error}</div>
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
    </div>
  );
}
