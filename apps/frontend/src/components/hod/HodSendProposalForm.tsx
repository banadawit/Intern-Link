"use client";

import { useEffect, useRef, useState } from "react";
import { Send, Search, ChevronDown, X, Building, GraduationCap, Check } from "lucide-react";
import { cn } from "@/lib/utils";
import type { HodCompanyRow, HodStudentRow } from "./types";
import { useTranslations } from "next-intl";

// ─── Company searchable picker (single select) ────────────────────────────────

type PickerItem = { id: number; label: string; sub?: string };

function CompanyPicker({
  items,
  value,
  onChange,
  searchPlaceholder,
  noResultsText,
}: {
  items: PickerItem[];
  value: string;
  onChange: (v: string) => void;
  searchPlaceholder: string;
  noResultsText: string;
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
            ? "border-primary-500 ring-2 ring-primary-500/20 bg-white dark:bg-slate-900"
            : "border-slate-200 bg-white hover:border-slate-300 dark:border-slate-700 dark:bg-slate-900 dark:hover:border-slate-600"
        )}
      >
        <Building className="h-4 w-4 shrink-0 text-slate-400 dark:text-slate-500" />
        {selected ? (
          <>
            <span className="flex-1 truncate text-left font-medium text-slate-900 dark:text-slate-100">{selected.label}</span>
            {selected.sub && <span className="hidden text-xs text-slate-400 sm:block dark:text-slate-500">{selected.sub}</span>}
            <span role="button" onClick={clear} className="shrink-0 cursor-pointer text-slate-400 hover:text-slate-600 dark:text-slate-500 dark:hover:text-slate-300">
              <X className="h-3.5 w-3.5" />
            </span>
          </>
        ) : (
          <>
            <span className="flex-1 truncate text-left text-slate-400 dark:text-slate-500">{searchPlaceholder}</span>
            <ChevronDown className={cn("h-4 w-4 shrink-0 text-slate-400 transition-transform dark:text-slate-500", open && "rotate-180")} />
          </>
        )}
      </button>

      {open && (
        <div className="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-lg dark:border-slate-700 dark:bg-slate-900">
          <div className="flex items-center gap-2 border-b border-slate-100 px-3 py-2 dark:border-slate-700">
            <Search className="h-3.5 w-3.5 shrink-0 text-slate-400 dark:text-slate-500" />
            <input
              autoFocus
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search…"
              className="flex-1 bg-transparent text-sm text-slate-700 placeholder:text-slate-400 focus:outline-none dark:text-slate-200 dark:placeholder:text-slate-500"
            />
          </div>
          <ul className="max-h-52 overflow-y-auto py-1">
            {filtered.length === 0 ? (
              <li className="px-4 py-3 text-center text-sm text-slate-400 dark:text-slate-500">{noResultsText}</li>
            ) : (
              filtered.map((item) => (
                <li key={item.id}>
                  <button
                    type="button"
                    onClick={() => { onChange(String(item.id)); setOpen(false); setSearch(""); }}
                    className={cn(
                      "flex w-full items-center gap-3 px-4 py-2.5 text-left transition-colors hover:bg-slate-50 dark:hover:bg-slate-800",
                      String(item.id) === value && "bg-primary-50 dark:bg-primary-900/30"
                    )}
                  >
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold text-slate-900 dark:text-slate-100">{item.label}</p>
                      {item.sub && <p className="truncate text-xs text-slate-500 dark:text-slate-400">{item.sub}</p>}
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

// ─── Multi-select student picker ──────────────────────────────────────────────

function StudentMultiPicker({
  students,
  selectedIds,
  onChange,
  selectPlaceholder,
  searchPlaceholder,
  noStudentsText,
  deselectAllText,
  selectAllText,
  selectedCountText,
}: {
  students: HodStudentRow[];
  selectedIds: Set<number>;
  onChange: (ids: Set<number>) => void;
  selectPlaceholder: string;
  searchPlaceholder: string;
  noStudentsText: string;
  deselectAllText: string;
  selectAllText: string;
  selectedCountText: string;
}) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const ref = useRef<HTMLDivElement>(null);

  const filtered = students.filter(
    (s) =>
      s.user.full_name.toLowerCase().includes(search.toLowerCase()) ||
      (s.department ?? "").toLowerCase().includes(search.toLowerCase()) ||
      s.user.email.toLowerCase().includes(search.toLowerCase())
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

  const toggle = (id: number) => {
    const next = new Set(selectedIds);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    onChange(next);
  };

  const toggleAll = () => {
    if (selectedIds.size === filtered.length && filtered.length > 0) {
      const next = new Set(selectedIds);
      filtered.forEach((s) => next.delete(s.id));
      onChange(next);
    } else {
      const next = new Set(selectedIds);
      filtered.forEach((s) => next.add(s.id));
      onChange(next);
    }
  };

  const clearAll = (e: React.MouseEvent) => {
    e.stopPropagation();
    onChange(new Set());
  };

  const allFilteredSelected = filtered.length > 0 && filtered.every((s) => selectedIds.has(s.id));

  const selectedNames = students
    .filter((s) => selectedIds.has(s.id))
    .map((s) => s.user.full_name);

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "flex w-full min-h-[42px] items-center gap-2 rounded-xl border px-3 py-2 text-sm transition-all",
          open
            ? "border-primary-500 ring-2 ring-primary-500/20 bg-white dark:bg-slate-900"
            : "border-slate-200 bg-white hover:border-slate-300 dark:border-slate-700 dark:bg-slate-900 dark:hover:border-slate-600"
        )}
      >
        <GraduationCap className="h-4 w-4 shrink-0 text-slate-400 dark:text-slate-500" />
        {selectedIds.size === 0 ? (
          <>
            <span className="flex-1 truncate text-left text-slate-400 dark:text-slate-500">{selectPlaceholder}</span>
            <ChevronDown className={cn("h-4 w-4 shrink-0 text-slate-400 transition-transform dark:text-slate-500", open && "rotate-180")} />
          </>
        ) : (
          <>
            <div className="flex flex-1 flex-wrap gap-1 py-0.5">
              {selectedNames.slice(0, 3).map((name) => (
                <span key={name} className="rounded-full bg-primary-100 px-2 py-0.5 text-xs font-medium text-primary-700 dark:bg-primary-900/40 dark:text-primary-300">
                  {name}
                </span>
              ))}
              {selectedIds.size > 3 && (
                <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                  +{selectedIds.size - 3} more
                </span>
              )}
            </div>
            <span role="button" onClick={clearAll} className="shrink-0 cursor-pointer text-slate-400 hover:text-slate-600 dark:text-slate-500 dark:hover:text-slate-300">
              <X className="h-3.5 w-3.5" />
            </span>
          </>
        )}
      </button>

      {open && (
        <div className="absolute left-0 right-0 top-full z-50 mt-1 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-lg dark:border-slate-700 dark:bg-slate-900">
          {/* Search */}
          <div className="flex items-center gap-2 border-b border-slate-100 px-3 py-2 dark:border-slate-700">
            <Search className="h-3.5 w-3.5 shrink-0 text-slate-400 dark:text-slate-500" />
            <input
              autoFocus
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={searchPlaceholder}
              className="flex-1 bg-transparent text-sm text-slate-700 placeholder:text-slate-400 focus:outline-none dark:text-slate-200 dark:placeholder:text-slate-500"
            />
          </div>

          {/* Select all row */}
          {filtered.length > 1 && (
            <button
              type="button"
              onClick={toggleAll}
              className="flex w-full items-center gap-3 border-b border-slate-100 px-4 py-2.5 text-left text-xs font-semibold text-slate-500 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-400 dark:hover:bg-slate-800"
            >
              <div className={cn(
                "flex h-4 w-4 shrink-0 items-center justify-center rounded border",
                allFilteredSelected
                  ? "border-primary-600 bg-primary-600"
                  : "border-slate-300 dark:border-slate-600"
              )}>
                {allFilteredSelected && <Check className="h-3 w-3 text-white" />}
              </div>
              {allFilteredSelected ? deselectAllText : selectAllText.replace("{count}", String(filtered.length))}
            </button>
          )}

          <ul className="max-h-56 overflow-y-auto py-1">
            {filtered.length === 0 ? (
              <li className="px-4 py-3 text-center text-sm text-slate-400 dark:text-slate-500">{noStudentsText}</li>
            ) : (
              filtered.map((s) => {
                const checked = selectedIds.has(s.id);
                return (
                  <li key={s.id}>
                    <button
                      type="button"
                      onClick={() => toggle(s.id)}
                      className={cn(
                        "flex w-full items-center gap-3 px-4 py-2.5 text-left transition-colors hover:bg-slate-50 dark:hover:bg-slate-800",
                        checked && "bg-primary-50 dark:bg-primary-900/20"
                      )}
                    >
                      <div className={cn(
                        "flex h-4 w-4 shrink-0 items-center justify-center rounded border transition-colors",
                        checked
                          ? "border-primary-600 bg-primary-600"
                          : "border-slate-300 dark:border-slate-600"
                      )}>
                        {checked && <Check className="h-3 w-3 text-white" />}
                      </div>
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-slate-900 dark:text-slate-100">{s.user.full_name}</p>
                        <p className="truncate text-xs text-slate-500 dark:text-slate-400">{s.department ?? s.user.email}</p>
                      </div>
                    </button>
                  </li>
                );
              })
            )}
          </ul>

          {/* Footer */}
          {selectedIds.size > 0 && (
            <div className="border-t border-slate-100 px-4 py-2 dark:border-slate-700">
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {selectedCountText.replace("{count}", String(selectedIds.size))}
              </p>
            </div>
          )}
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
  selectedStudentIds: Set<number>;
  proposalCompanyId: string;
  proposalWeeks: string;
  proposalOutcomes: string;
  onStudentIds: (ids: Set<number>) => void;
  onCompanyId: (v: string) => void;
  onWeeks: (v: string) => void;
  onOutcomes: (v: string) => void;
  onSubmit: (e: React.FormEvent) => void;
};

export default function HodSendProposalForm({
  approvedStudents,
  companies,
  submitting,
  selectedStudentIds,
  proposalCompanyId,
  proposalWeeks,
  proposalOutcomes,
  onStudentIds,
  onCompanyId,
  onWeeks,
  onOutcomes,
  onSubmit,
}: Props) {
  const t = useTranslations("HodPortal.sendProposal");

  const companyItems: PickerItem[] = companies.map((c) => ({
    id: c.id,
    label: c.name,
    sub: c.official_email,
  }));

  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6 dark:border-slate-700 dark:bg-slate-900">
      <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">{t("title")}</h2>
      <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
        {t("description")}
      </p>

      <form onSubmit={onSubmit} className="mt-5 grid gap-5 sm:grid-cols-2">
        {/* Student multi-picker */}
        <div className="sm:col-span-2">
          <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-200">
            {t("studentsLabel")} <span className="text-red-500">*</span>
          </label>
          <StudentMultiPicker
            students={approvedStudents}
            selectedIds={selectedStudentIds}
            onChange={onStudentIds}
            selectPlaceholder={t("selectStudents")}
            searchPlaceholder={t("searchStudents")}
            noStudentsText={t("noStudentsFound")}
            deselectAllText={t("deselectAll")}
            selectAllText={t("selectAll")}
            selectedCountText={t("selectedCount")}
          />
          {approvedStudents.length === 0 && (
            <p className="mt-1 text-xs text-slate-400 dark:text-slate-500">{t("noStudentsAvailable")}</p>
          )}
        </div>

        {/* Company picker */}
        <div>
          <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-200">
            {t("companyLabel")} <span className="text-red-500">*</span>
          </label>
          <CompanyPicker
            items={companyItems}
            value={proposalCompanyId}
            onChange={onCompanyId}
            searchPlaceholder={t("searchCompany")}
            noResultsText={t("noResults")}
          />
          {companyItems.length === 0 && (
            <p className="mt-1 text-xs text-slate-400 dark:text-slate-500">{t("noCompaniesAvailable")}</p>
          )}
        </div>

        {/* Duration */}
        <div>
          <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-200">{t("durationLabel")}</label>
          <input
            type="number"
            min={1}
            value={proposalWeeks}
            onChange={(e) => onWeeks(e.target.value)}
            placeholder="e.g. 12"
            className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100"
          />
        </div>

        {/* Expected outcomes */}
        <div className="sm:col-span-2">
          <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-200">{t("outcomesLabel")}</label>
          <textarea
            value={proposalOutcomes}
            onChange={(e) => onOutcomes(e.target.value)}
            rows={3}
            placeholder={t("outcomesPlaceholder")}
            className="w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 resize-none dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100"
          />
        </div>

        {/* Submit */}
        <div className="sm:col-span-2">
          <button
            type="submit"
            disabled={submitting || selectedStudentIds.size === 0 || !proposalCompanyId}
            className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Send className="h-4 w-4" />
            {submitting
              ? t("sending")
              : selectedStudentIds.size > 1
                ? t("sendProposals", { count: selectedStudentIds.size })
                : t("sendProposal")}
          </button>
        </div>
      </form>
    </section>
  );
}
