"use client";

import { useEffect, useRef, useState } from "react";
import { ChevronDown, Search, X, Check } from "lucide-react";
import { cn } from "@/lib/utils";

type Student = { id: number; user: { full_name: string; email: string } };

interface Props {
  students: Student[];
  /** Comma-separated selected IDs */
  value: string;
  onChange: (val: string) => void;
  placeholder?: string;
}

function initials(name: string) {
  return name.split(/\s+/).map((n) => n[0]).join("").toUpperCase().slice(0, 2);
}

function colorForId(id: number) {
  const colors = [
    "bg-teal-100 text-teal-700",
    "bg-blue-100 text-blue-700",
    "bg-violet-100 text-violet-700",
    "bg-amber-100 text-amber-700",
    "bg-rose-100 text-rose-700",
    "bg-emerald-100 text-emerald-700",
  ];
  return colors[id % colors.length];
}

export default function StudentPicker({ students, value, onChange, placeholder = "Add members…" }: Props) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const ref = useRef<HTMLDivElement>(null);

  // Parse selected IDs from comma-separated string
  const selectedIds = new Set(
    value.split(",").map((v) => v.trim()).filter(Boolean).map(Number)
  );

  const selectedStudents = students.filter((s) => selectedIds.has(s.id));

  const filtered = students.filter(
    (s) =>
      s.user.full_name.toLowerCase().includes(search.toLowerCase()) ||
      s.user.email.toLowerCase().includes(search.toLowerCase())
  );

  const allFilteredSelected = filtered.length > 0 && filtered.every((s) => selectedIds.has(s.id));

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
    onChange([...next].join(","));
  };

  const toggleAll = () => {
    const next = new Set(selectedIds);
    if (allFilteredSelected) {
      filtered.forEach((s) => next.delete(s.id));
    } else {
      filtered.forEach((s) => next.add(s.id));
    }
    onChange([...next].join(","));
  };

  const clearAll = (e: React.MouseEvent) => {
    e.stopPropagation();
    onChange("");
  };

  return (
    <div ref={ref} className="relative flex-1 min-w-0">
      {/* Trigger */}
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "flex w-full min-h-[38px] items-center gap-2 rounded-xl border px-3 py-1.5 text-sm transition-all",
          open
            ? "border-primary-500 ring-2 ring-primary-500/20 bg-white dark:bg-slate-900"
            : "border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 hover:border-slate-300 dark:hover:border-slate-600"
        )}
      >
        {selectedStudents.length === 0 ? (
          <>
            <span className="flex-1 truncate text-left text-slate-400 dark:text-slate-500">{placeholder}</span>
            <ChevronDown className={cn("h-4 w-4 shrink-0 text-slate-400 dark:text-slate-500 transition-transform", open && "rotate-180")} />
          </>
        ) : (
          <>
            <div className="flex flex-1 flex-wrap gap-1 py-0.5">
              {selectedStudents.slice(0, 2).map((s) => (
                <span
                  key={s.id}
                  className="inline-flex items-center gap-1 rounded-full bg-primary-100 dark:bg-primary-900/40 px-2 py-0.5 text-xs font-medium text-primary-700 dark:text-primary-300 whitespace-nowrap"
                >
                  {s.user.full_name}
                </span>
              ))}
              {selectedStudents.length > 2 && (
                <span className="rounded-full bg-slate-100 dark:bg-slate-800 px-2 py-0.5 text-xs font-medium text-slate-600 dark:text-slate-300 whitespace-nowrap">
                  +{selectedStudents.length - 2} more
                </span>
              )}
            </div>
            <span
              role="button"
              onClick={clearAll}
              className="shrink-0 cursor-pointer text-slate-400 hover:text-slate-600 dark:text-slate-500 dark:hover:text-slate-300"
            >
              <X className="h-3.5 w-3.5" />
            </span>
          </>
        )}
      </button>

      {/* Dropdown */}
      {open && (
        <div className="absolute left-0 top-full z-50 mt-1 w-72 overflow-hidden rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 shadow-lg">
          {/* Search */}
          <div className="flex items-center gap-2 border-b border-slate-100 dark:border-slate-700 px-3 py-2">
            <Search className="h-3.5 w-3.5 shrink-0 text-slate-400 dark:text-slate-500" />
            <input
              autoFocus
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name or email…"
              className="flex-1 bg-transparent text-sm text-slate-700 dark:text-slate-300 placeholder:text-slate-400 dark:placeholder:text-slate-500 focus:outline-none"
            />
          </div>

          {/* Select all row */}
          {filtered.length > 1 && (
            <button
              type="button"
              onClick={toggleAll}
              className="flex w-full items-center gap-3 border-b border-slate-100 dark:border-slate-700 px-3 py-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800"
            >
              <div className={cn(
                "flex h-4 w-4 shrink-0 items-center justify-center rounded border transition-colors",
                allFilteredSelected
                  ? "border-primary-600 bg-primary-600"
                  : "border-slate-300 dark:border-slate-600"
              )}>
                {allFilteredSelected && <Check className="h-3 w-3 text-white" />}
              </div>
              {allFilteredSelected ? "Deselect all" : `Select all (${filtered.length})`}
            </button>
          )}

          {/* Options */}
          <ul className="max-h-52 overflow-y-auto py-1">
            {filtered.length === 0 ? (
              <li className="px-4 py-3 text-sm text-slate-400 dark:text-slate-500 text-center">No students found.</li>
            ) : (
              filtered.map((s) => {
                const checked = selectedIds.has(s.id);
                return (
                  <li key={s.id}>
                    <button
                      type="button"
                      onClick={() => toggle(s.id)}
                      className={cn(
                        "flex w-full items-center gap-3 px-3 py-2.5 text-left transition-colors hover:bg-slate-50 dark:hover:bg-slate-800",
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
                      <div className={cn("flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-xs font-bold", colorForId(s.id))}>
                        {initials(s.user.full_name)}
                      </div>
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-slate-900 dark:text-slate-100">{s.user.full_name}</p>
                        <p className="truncate text-xs text-slate-500 dark:text-slate-400">{s.user.email}</p>
                      </div>
                    </button>
                  </li>
                );
              })
            )}
          </ul>

          {/* Footer count */}
          {selectedIds.size > 0 && (
            <div className="border-t border-slate-100 dark:border-slate-700 px-3 py-2">
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {selectedIds.size} student{selectedIds.size !== 1 ? "s" : ""} selected
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
