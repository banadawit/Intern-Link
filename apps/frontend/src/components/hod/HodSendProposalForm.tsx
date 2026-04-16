"use client";

import { useEffect, useRef, useState } from "react";
import { Send, Search, ChevronDown, X, Building, GraduationCap } from "lucide-react";
import { cn } from "@/lib/utils";
import type { HodCompanyRow, HodStudentRow } from "./types";

// ─── Generic searchable picker ───────────────────────────────────────────────

type PickerItem = { id: number; label: string; sub?: string };

function SearchPicker({
  items,
  value,
  onChange,
  placeholder,
  icon: Icon,
}: {
  items: PickerItem[];
  value: string;
  onChange: (v: string) => void;
  placeholder: string;
  icon: React.ComponentType<{ className?: string }>;
}) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const ref = useRef<HTMLDivElement>(null);

  const selected = items.find((i) => String(i.id) === value) ?? null;
  const filtered = items.filter(
    (i) =>
      i.label.toLowerCase().includes(search.toLowerCase()) ||
      (i.sub ?? "").toLowerCase().includes(search.toLowerCase())
  );

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
        setSearch("");
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const select = (id: number) => {
    onChange(String(id));
    setOpen(false);
    setSearch("");
  };

  const clear = (e: React.MouseEvent) => {
    e.stopPropagation();
    onChange("");
  };

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "flex w-full items-center gap-2 rounded-xl border px-3 py-2.5 text-sm transition-all",
          open
            ? "border-primary-500 ring-2 ring-primary-500/20 bg-white"
            : "border-slate-200 bg-white hover:border-slate-300"
        )}
      >
        <Icon className="h-4 w-4 shrink-0 text-slate-400" />
        {selected ? (
          <>
            <span className="flex-1 truncate text-left font-medium text-slate-900">{selected.label}</span>
            {selected.sub && <span className="hidden text-xs text-slate-400 sm:block">{selected.sub}</span>}
            <span role="button" onClick={clear} className="shrink-0 cursor-pointer text-slate-400 hover:text-slate-600">
              <X className="h-3.5 w-3.5" />
            </span>
          </>
        ) : (
          <>
            <span className="flex-1 truncate text-left text-slate-400">{placeholder}</span>
            <ChevronDown className={cn("h-4 w-4 shrink-0 text-slate-400 transition-transform", open && "rotate-180")} />
          </>
        )}
      </button>

      {open && (
        <div className="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-lg">
          <div className="flex items-center gap-2 border-b border-slate-100 px-3 py-2">
            <Search className="h-3.5 w-3.5 shrink-0 text-slate-400" />
            <input
              autoFocus
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search…"
              className="flex-1 bg-transparent text-sm text-slate-700 placeholder:text-slate-400 focus:outline-none"
            />
          </div>
          <ul className="max-h-52 overflow-y-auto py-1">
            {filtered.length === 0 ? (
              <li className="px-4 py-3 text-center text-sm text-slate-400">No results.</li>
            ) : (
              filtered.map((item) => (
                <li key={item.id}>
                  <button
                    type="button"
                    onClick={() => select(item.id)}
                    className={cn(
                      "flex w-full items-center gap-3 px-4 py-2.5 text-left transition-colors hover:bg-slate-50",
                      String(item.id) === value && "bg-primary-50"
                    )}
                  >
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold text-slate-900">{item.label}</p>
                      {item.sub && <p className="truncate text-xs text-slate-500">{item.sub}</p>}
                    </div>
                  </button>
                </li>
              ))
            )}
          </ul>
        </div>
      )}
    </div>
  );
}

// ─── Main form ────────────────────────────────────────────────────────────────

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
  const studentItems: PickerItem[] = approvedStudents.map((s) => ({
    id: s.id,
    label: s.user.full_name,
    sub: s.department ?? s.user.email,
  }));

  const companyItems: PickerItem[] = companies.map((c) => ({
    id: c.id,
    label: c.name,
    sub: c.official_email,
  }));

  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <h2 className="text-lg font-bold text-slate-900">Send placement proposal</h2>
      <p className="mt-1 text-sm text-slate-500">Only approved students and verified companies are listed.</p>

      <form onSubmit={onSubmit} className="mt-5 grid gap-5 sm:grid-cols-2">
        {/* Student picker */}
        <div>
          <label className="mb-1.5 block text-sm font-semibold text-slate-700">
            Student <span className="text-red-500">*</span>
          </label>
          <SearchPicker
            items={studentItems}
            value={proposalStudentId}
            onChange={onStudentId}
            placeholder="Search student…"
            icon={GraduationCap}
          />
          {studentItems.length === 0 && (
            <p className="mt-1 text-xs text-slate-400">No approved students yet.</p>
          )}
        </div>

        {/* Company picker */}
        <div>
          <label className="mb-1.5 block text-sm font-semibold text-slate-700">
            Company <span className="text-red-500">*</span>
          </label>
          <SearchPicker
            items={companyItems}
            value={proposalCompanyId}
            onChange={onCompanyId}
            placeholder="Search company…"
            icon={Building}
          />
          {companyItems.length === 0 && (
            <p className="mt-1 text-xs text-slate-400">No verified companies yet.</p>
          )}
        </div>

        {/* Duration */}
        <div>
          <label className="mb-1.5 block text-sm font-semibold text-slate-700">Duration (weeks)</label>
          <input
            type="number"
            min={1}
            value={proposalWeeks}
            onChange={(e) => onWeeks(e.target.value)}
            placeholder="e.g. 12"
            className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20"
          />
        </div>

        {/* Expected outcomes */}
        <div className="sm:col-span-2">
          <label className="mb-1.5 block text-sm font-semibold text-slate-700">Expected outcomes</label>
          <textarea
            value={proposalOutcomes}
            onChange={(e) => onOutcomes(e.target.value)}
            rows={3}
            placeholder="Describe the expected learning outcomes for this internship…"
            className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-none"
          />
        </div>

        {/* Submit */}
        <div className="sm:col-span-2">
          <button
            type="submit"
            disabled={submitting || !proposalStudentId || !proposalCompanyId}
            className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Send className="h-4 w-4" />
            {submitting ? "Sending…" : "Send proposal"}
          </button>
        </div>
      </form>
    </section>
  );
}
