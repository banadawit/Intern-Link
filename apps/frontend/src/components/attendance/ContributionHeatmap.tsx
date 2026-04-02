"use client";

import { useMemo } from "react";
import { cn } from "@/lib/utils";

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** Accepts `YYYY-MM-DD` or ISO datetime (uses first 10 chars). */
function parseYmdUtc(s: string): number {
  const day = String(s).slice(0, 10);
  const [y, m, d] = day.split("-").map(Number);
  if (!y || !m || !d) return NaN;
  return Date.UTC(y, m - 1, d);
}

function ymdUtc(ms: number): string {
  const x = new Date(ms);
  const y = x.getUTCFullYear();
  const mo = String(x.getUTCMonth() + 1).padStart(2, "0");
  const day = String(x.getUTCDate()).padStart(2, "0");
  return `${y}-${mo}-${day}`;
}

/** Monday 00:00 UTC of the week containing this UTC day. */
function mondayOfWeekContaining(utcDayMs: number): number {
  const d = new Date(utcDayMs);
  const dow = d.getUTCDay();
  const offset = dow === 0 ? -6 : 1 - dow;
  return utcDayMs + offset * 86400000;
}

const emptyCell = "bg-slate-100 border border-slate-200/90 dark:bg-slate-800/80 dark:border-slate-700";
const filledCell = "bg-emerald-500 border border-emerald-600/90 dark:bg-emerald-600 dark:border-emerald-500/80";

export type ContributionHeatmapProps = {
  rangeStart: string;
  rangeEnd: string;
  submittedDates: string[];
  className?: string;
};

export function ContributionHeatmap({ rangeStart, rangeEnd, submittedDates, className }: ContributionHeatmapProps) {
  const submitted = useMemo(() => new Set(submittedDates), [submittedDates]);

  const { weeks, gridStart } = useMemo(() => {
    let startMs = parseYmdUtc(rangeStart);
    let endMs = parseYmdUtc(rangeEnd);
    if (!Number.isFinite(startMs) || !Number.isFinite(endMs)) {
      const today = Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), new Date().getUTCDate());
      endMs = today;
      startMs = today - 371 * 86400000;
    }
    if (startMs > endMs) {
      const t = startMs;
      startMs = endMs;
      endMs = t;
    }

    const gridStartMs = mondayOfWeekContaining(startMs);
    const lastMonday = mondayOfWeekContaining(endMs);
    const weekFlags: boolean[][] = [];
    let colStart = gridStartMs;
    let guard = 0;
    while (colStart <= lastMonday && guard < 56) {
      const col: boolean[] = [];
      for (let r = 0; r < 7; r++) {
        const cellMs = colStart + r * 86400000;
        const inRange = cellMs >= startMs && cellMs <= endMs;
        const y = ymdUtc(cellMs);
        col.push(inRange && submitted.has(y));
      }
      weekFlags.push(col);
      colStart += 7 * 86400000;
      guard++;
    }
    // Fallback: invalid range produced no columns (should be rare)
    if (weekFlags.length === 0) {
      const col: boolean[] = [];
      const mono = mondayOfWeekContaining(endMs);
      for (let r = 0; r < 7; r++) {
        const cellMs = mono + r * 86400000;
        const inRange = cellMs >= startMs && cellMs <= endMs;
        col.push(inRange && submitted.has(ymdUtc(cellMs)));
      }
      return { weeks: [col], gridStart: mono };
    }
    return { weeks: weekFlags, gridStart: gridStartMs };
  }, [rangeStart, rangeEnd, submitted]);

  return (
    <div className={cn("rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-slate-900/40", className)}>
      <div className="flex gap-2">
        <div className="flex shrink-0 flex-col justify-between pb-0.5 pt-5 text-[10px] leading-none text-slate-500 dark:text-slate-400">
          <span>Mon</span>
          <span aria-hidden className="opacity-0">
            ·
          </span>
          <span>Wed</span>
          <span aria-hidden className="opacity-0">
            ·
          </span>
          <span>Fri</span>
          <span aria-hidden className="opacity-0">
            ·
          </span>
          <span className="opacity-0">·</span>
        </div>
        <div className="min-w-0 flex-1 overflow-x-auto">
          <div className="flex min-h-4 gap-1 pb-1">
            {weeks.map((_, ci) => {
              const mondayMs = gridStart + ci * 7 * 86400000;
              const prevMs = ci > 0 ? gridStart + (ci - 1) * 7 * 86400000 : null;
              const show =
                prevMs === null ||
                new Date(mondayMs).getUTCMonth() !== new Date(prevMs).getUTCMonth();
              return (
                <div key={ci} className="flex w-3 shrink-0 justify-center">
                  {show ? (
                    <span className="text-[10px] font-medium text-slate-500 dark:text-slate-400">
                      {MONTHS[new Date(mondayMs).getUTCMonth()]}
                    </span>
                  ) : null}
                </div>
              );
            })}
          </div>
          <div className="flex min-h-[7.25rem] gap-1">
            {weeks.map((col, ci) => (
              <div key={ci} className="flex flex-col gap-1">
                {col.map((on, ri) => {
                  const cellMs = gridStart + ci * 7 * 86400000 + ri * 86400000;
                  return (
                    <div
                      key={ri}
                      title={ymdUtc(cellMs)}
                      className={cn("h-[11px] w-[11px] rounded-[2px]", on ? filledCell : emptyCell)}
                    />
                  );
                })}
              </div>
            ))}
          </div>
          <div className="mt-3 flex items-center justify-end gap-2 text-[10px] text-slate-500 dark:text-slate-400">
            <span>Less</span>
            <div className={cn("h-3 w-3 rounded-[3px]", emptyCell)} />
            <div className={cn("h-3 w-3 rounded-[3px]", filledCell)} />
            <span>More</span>
          </div>
        </div>
      </div>
    </div>
  );
}
