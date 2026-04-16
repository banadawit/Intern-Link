"use client";

import { cn } from "@/lib/utils";
import type { HodProposalRow } from "./types";

type Props = {
  openLetters: HodProposalRow[];
  submitting: boolean;
  onApprove: (id: number) => void;
  onReject: (id: number) => void;
};

export default function HodOpenLettersPanel({ openLetters, submitting, onApprove, onReject }: Props) {
  return (
    <section
      className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6"
      aria-label="Open letter proposals list"
    >
      <div className="space-y-2">
        {openLetters.map((p) => (
          <div
            key={p.id}
            className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50/80 px-4 py-3"
          >
            <div className="text-sm text-slate-800">
              <span className="font-semibold">{p.student.user.full_name}</span>
              <span className="text-slate-500"> → {p.company.name} </span>
              <span className={cn(
                "rounded-full px-2 py-0.5 text-xs font-semibold",
                p.status === "PENDING"  && "bg-amber-100 text-amber-800",
                p.status === "APPROVED" && "bg-emerald-100 text-emerald-800",
                p.status === "REJECTED" && "bg-red-100 text-red-700",
                !["PENDING","APPROVED","REJECTED"].includes(p.status) && "bg-slate-200 text-slate-700",
              )}>
                {p.status}
              </span>
            </div>
            {p.status === "PENDING" && (
              <div className="flex gap-2">
                <button
                  type="button"
                  disabled={submitting}
                  className="rounded-lg bg-primary-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
                  onClick={() => onApprove(p.id)}
                >
                  Accept
                </button>
                <button
                  type="button"
                  disabled={submitting}
                  className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50"
                  onClick={() => onReject(p.id)}
                >
                  Reject
                </button>
              </div>
            )}
          </div>
        ))}
        {openLetters.length === 0 && <p className="text-sm text-slate-500">No open letter items.</p>}
      </div>
    </section>
  );
}
