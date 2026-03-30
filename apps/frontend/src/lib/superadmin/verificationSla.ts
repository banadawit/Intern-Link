/** Response Time Policy: Admin must Approve/Reject within this window of submission. */
export const VERIFICATION_RESPONSE_HOURS = 24;
const MS_PER_HOUR = 60 * 60 * 1000;
export const VERIFICATION_RESPONSE_MS = VERIFICATION_RESPONSE_HOURS * MS_PER_HOUR;

export type PendingSlaState = {
  deadline: Date;
  isOverdue: boolean;
  /** Milliseconds remaining until deadline (negative if overdue) */
  remainingMs: number;
  /** Human-readable, e.g. "18h 30m left" or "Overdue by 2h" */
  label: string;
};

function formatDuration(ms: number, overdue: boolean): string {
  const abs = Math.abs(ms);
  const h = Math.floor(abs / MS_PER_HOUR);
  const m = Math.floor((abs % MS_PER_HOUR) / (60 * 1000));
  if (overdue) {
    if (h > 0) return `Overdue by ${h}h ${m}m`;
    return `Overdue by ${m}m`;
  }
  if (h > 0) return `${h}h ${m}m left`;
  return `${m}m left`;
}

export function getPendingVerificationSla(submittedAtIso: string, now: Date = new Date()): PendingSlaState {
  const submitted = new Date(submittedAtIso);
  const deadline = new Date(submitted.getTime() + VERIFICATION_RESPONSE_MS);
  const remainingMs = deadline.getTime() - now.getTime();
  const isOverdue = remainingMs < 0;
  return {
    deadline,
    isOverdue,
    remainingMs,
    label: formatDuration(remainingMs, isOverdue),
  };
}
