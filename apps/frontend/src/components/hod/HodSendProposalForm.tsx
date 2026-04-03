"use client";

import { Send } from "lucide-react";
import type { HodCompanyRow, HodStudentRow } from "./types";

type Props = {
  approvedStudents: HodStudentRow[];
  companies: HodCompanyRow[];
  submitting: boolean;
  proposalStudentId: string;
  proposalCompanyId: string;
  proposalWeeks: string;
  proposalOutcomes: string;
  onStudentId: (v: string) => void;
  onCompanyId: (v: string) => void;
  onWeeks: (v: string) => void;
  onOutcomes: (v: string) => void;
  onSubmit: (e: React.FormEvent) => void;
};

export default function HodSendProposalForm({
  approvedStudents,
  companies,
  submitting,
  proposalStudentId,
  proposalCompanyId,
  proposalWeeks,
  proposalOutcomes,
  onStudentId,
  onCompanyId,
  onWeeks,
  onOutcomes,
  onSubmit,
}: Props) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <h2 className="text-lg font-bold text-slate-900">Send placement proposal</h2>
      <p className="mt-1 text-sm text-slate-500">Only approved students; verified companies only.</p>
      <form onSubmit={onSubmit} className="mt-4 grid gap-4 sm:grid-cols-2">
        <label className="text-sm font-medium text-slate-700">
          Student (approved)
          <select
            required
            value={proposalStudentId}
            onChange={(e) => onStudentId(e.target.value)}
            className="mt-1.5 w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
          >
            <option value="">Select…</option>
            {approvedStudents.map((s) => (
              <option key={s.id} value={s.id}>
                {s.user.full_name}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm font-medium text-slate-700">
          Company
          <select
            required
            value={proposalCompanyId}
            onChange={(e) => onCompanyId(e.target.value)}
            className="mt-1.5 w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
          >
            <option value="">Select…</option>
            {companies.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm font-medium text-slate-700">
          Duration (weeks)
          <input
            type="number"
            min={1}
            value={proposalWeeks}
            onChange={(e) => onWeeks(e.target.value)}
            className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
          />
        </label>
        <label className="text-sm font-medium text-slate-700 sm:col-span-2">
          Expected outcomes
          <textarea
            value={proposalOutcomes}
            onChange={(e) => onOutcomes(e.target.value)}
            rows={3}
            className="mt-1.5 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
          />
        </label>
        <div className="sm:col-span-2">
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-primary-700 disabled:opacity-50"
          >
            <Send className="h-4 w-4" />
            Send proposal
          </button>
        </div>
      </form>
    </section>
  );
}
