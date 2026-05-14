"use client";

import { Mail } from "lucide-react";
import { useTranslations } from "next-intl";

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
  const t = useTranslations("HodPortal.invite");

  return (
    <section
      className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900"
      aria-label="Company invitation form"
    >
      <form onSubmit={onSubmit} className="flex flex-wrap items-end gap-3">
        <input
          type="email"
          required
          placeholder={t("emailPlaceholder")}
          value={inviteEmail}
          onChange={(e) => onEmail(e.target.value)}
          className="min-w-[200px] flex-1 rounded-xl border border-slate-200 px-4 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500"
        />
        <input
          type="text"
          required
          placeholder={t("companyNamePlaceholder")}
          value={inviteCompanyName}
          onChange={(e) => onCompanyName(e.target.value)}
          className="min-w-[200px] flex-1 rounded-xl border border-slate-200 px-4 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:placeholder:text-slate-500"
        />
        <button
          type="submit"
          disabled={submitting}
          className="inline-flex items-center gap-2 rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-slate-800 disabled:opacity-50"
        >
          <Mail className="h-4 w-4" />
          {t("sendInvite")}
        </button>
      </form>
    </section>
  );
}
