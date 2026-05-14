/** Seven calendar days (UTC) for internship week index `weekNumber` (1-based) from placement start. */
export function getInternshipWeekDateStrings(assignmentStartIso: string, weekNumber: number): string[] {
  const start = new Date(assignmentStartIso);
  const base = Date.UTC(start.getUTCFullYear(), start.getUTCMonth(), start.getUTCDate());
  const dayMs = 24 * 60 * 60 * 1000;
  const weekStart = base + (weekNumber - 1) * 7 * dayMs;
  const dates: string[] = [];
  for (let i = 0; i < 7; i++) {
    const t = weekStart + i * dayMs;
    const d = new Date(t);
    dates.push(
      `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")}`
    );
  }
  return dates;
}

/**
 * Returns the 5 weekday dates (Mon–Fri, YYYY-MM-DD) of the calendar week
 * that contains the given ISO date string. Used for team-student daily plans
 * where we want the real Mon–Fri of the week the plan was submitted.
 */
export function getCalendarWeekWorkdays(isoDate: string): string[] {
  const d = new Date(isoDate);
  const dayMs = 24 * 60 * 60 * 1000;
  // Get UTC day-of-week (0=Sun … 6=Sat); shift so Mon=0
  const dow = (d.getUTCDay() + 6) % 7; // Mon=0, Tue=1, … Sun=6
  const monday = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()) - dow * dayMs;
  const dates: string[] = [];
  for (let i = 0; i < 5; i++) {
    const t = monday + i * dayMs;
    const day = new Date(t);
    dates.push(
      `${day.getUTCFullYear()}-${String(day.getUTCMonth() + 1).padStart(2, "0")}-${String(day.getUTCDate()).padStart(2, "0")}`
    );
  }
  return dates;
}
