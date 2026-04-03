"use client";

import { cn } from "@/lib/utils";
import { getInternshipWeekDateStrings } from "@/lib/student/internshipWeekDates";

const DAY_LABELS = ["M", "T", "W", "T", "F", "S", "S"];

export type WeekDayStripProps = {
  assignmentStart: string;
  weekNumber: number;
  /** YYYY-MM-DD strings that have a daily submission */
  submittedYmds: string[];
  className?: string;
};

export function WeekDayStrip({ assignmentStart, weekNumber, submittedYmds, className }: WeekDayStripProps) {
  const dates = getInternshipWeekDateStrings(assignmentStart, weekNumber);
  const set = new Set(submittedYmds.map((s) => s.slice(0, 10)));

  return (
    <div className={cn("flex flex-col gap-1", className)}>
      <div className="flex gap-0.5">
        {dates.map((ymd, i) => (
          <div
            key={ymd}
            title={`${ymd} (${DAY_LABELS[i]})`}
            className={cn(
              "h-3.5 w-3.5 rounded-[3px] border",
              set.has(ymd)
                ? "border-emerald-600/90 bg-emerald-500 dark:border-emerald-500 dark:bg-emerald-600"
                : "border-slate-200 bg-slate-100 dark:border-slate-600 dark:bg-slate-800"
            )}
          />
        ))}
      </div>
      <p className="text-[10px] text-slate-400 dark:text-slate-500">Mon → Sun (internship week)</p>
    </div>
  );
}
