/** Current internship week (1-based) from assignment start, or 1 if unplaced / invalid. */
export function getCurrentInternshipWeekFromStart(startDate: Date | null | undefined): number {
    if (!startDate) return 1;
    const start = new Date(startDate).getTime();
    const now = Date.now();
    const diffMs = Math.max(0, now - start);
    const weekMs = 7 * 24 * 60 * 60 * 1000;
    return Math.max(1, Math.floor(diffMs / weekMs) + 1);
}
