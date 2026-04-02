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
