/** UTC epoch-ms for calendar date (year, month 1-12, day). */
export function utcDateMs(y: number, month: number, day: number): number {
    return Date.UTC(y, month - 1, day);
}

export function parseIsoDateOnly(s: string): { y: number; m: number; d: number } | null {
    const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s.trim());
    if (!m) return null;
    const y = +m[1];
    const mo = +m[2];
    const d = +m[3];
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    const t = utcDateMs(y, mo, d);
    const dt = new Date(t);
    if (dt.getUTCFullYear() !== y || dt.getUTCMonth() !== mo - 1 || dt.getUTCDate() !== d) return null;
    return { y, m: mo, d };
}

export function assignmentStartUtcDayMs(start: Date): number {
    const s = new Date(start);
    return utcDateMs(s.getUTCFullYear(), s.getUTCMonth() + 1, s.getUTCDate());
}

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

/** Internship week N (1-based): seven calendar days starting at assignment UTC day + (N-1)*7. */
export function internshipWeekBoundsUtcDayMs(
    assignmentStart: Date,
    weekNumber: number
): { start: number; endExclusive: number } {
    const base = assignmentStartUtcDayMs(assignmentStart);
    const start = base + (weekNumber - 1) * WEEK_MS;
    return { start, endExclusive: start + WEEK_MS };
}

export function isWorkDateInInternshipWeek(
    assignmentStart: Date,
    weekNumber: number,
    workDateYmd: string
): boolean {
    const parts = parseIsoDateOnly(workDateYmd);
    if (!parts) return false;
    const t = utcDateMs(parts.y, parts.m, parts.d);
    const { start, endExclusive } = internshipWeekBoundsUtcDayMs(assignmentStart, weekNumber);
    return t >= start && t < endExclusive;
}

export function ymdFromUtcMs(ms: number): string {
    const d = new Date(ms);
    const y = d.getUTCFullYear();
    const m = String(d.getUTCMonth() + 1).padStart(2, '0');
    const day = String(d.getUTCDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
}
