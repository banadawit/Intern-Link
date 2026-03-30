import type { WeeklyPlan } from "@/lib/superadmin/types";

/** Shown in UI — aligns with demo “weekly cutoff” copy. */
export const WEEKLY_SUBMISSION_DEADLINE_LABEL = "Sunday 11:59 PM (local time)";

export const WEEKLY_DEADLINE_POLICY = {
  deadlineLabel: WEEKLY_SUBMISSION_DEADLINE_LABEL,
  points: [
    "Submit your plan before the weekly cutoff so your supervisor can review on schedule.",
    "If you miss a deadline, the week stays overdue until you submit. Your supervisor may be notified and you should submit as soon as possible.",
    "Repeated missed deadlines may be escalated per your university or host company policy.",
    "If you have technical problems, contact your coordinator and note the time of the issue.",
  ],
} as const;

export function getSubmittedWeekNumbers(plans: WeeklyPlan[]): Set<number> {
  return new Set(plans.map((p) => p.weekNumber));
}

/** Weeks strictly before `currentInternshipWeek` that have no plan row at all. */
export function getMissedInternshipWeeks(plans: WeeklyPlan[], currentInternshipWeek: number): number[] {
  if (currentInternshipWeek <= 1) return [];
  const submitted = getSubmittedWeekNumbers(plans);
  const missed: number[] = [];
  for (let w = 1; w < currentInternshipWeek; w++) {
    if (!submitted.has(w)) missed.push(w);
  }
  return missed;
}

export function hasPlanForInternshipWeek(plans: WeeklyPlan[], week: number): boolean {
  return plans.some((p) => p.weekNumber === week);
}
