"use client";

import { Mail } from "lucide-react";

type Props = {
  inviteEmail: string;
  inviteCompanyName: string;
  submitting: boolean;
  onEmail: (v: string) => void;
  onCompanyName: (v: string) => void;
  onSubmit: (e: React.FormEvent) => void;
};

export default function HodInviteCompanyForm({
  inviteEmail,
  inviteCompanyName,
  submitting,
  onEmail,
  onCompanyName,
  onSubmit,
}: Props) {
  return (
    <section
      className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6"
      aria-label="Company invitation form"
    >
      <form onSubmit={onSubmit} className="flex flex-wrap items-end gap-3">
        <input
          type="email"
          required
          placeholder="Company email"
          value={inviteEmail}
          onChange={(e) => onEmail(e.target.value)}
          className="min-w-[200px] flex-1 rounded-xl border border-slate-200 px-4 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
        />
        <input
          type="text"
          required
          placeholder="Company name"
          value={inviteCompanyName}
          onChange={(e) => onCompanyName(e.target.value)}
          className="min-w-[200px] flex-1 rounded-xl border border-slate-200 px-4 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
        />
        <button
          type="submit"
          disabled={submitting}
          className="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-slate-800 disabled:opacity-50"
        >
          <Mail className="h-4 w-4" />
          Send invite
        </button>
      </form>
    </section>
  );
}
