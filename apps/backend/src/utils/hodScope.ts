/** Normalize department for comparison (case-insensitive, trimmed). */
export function normalizeDepartment(d: string | null | undefined): string {
    return (d ?? '').trim().toLowerCase();
}

export function departmentsMatch(a: string | null | undefined, b: string | null | undefined): boolean {
    return normalizeDepartment(a) === normalizeDepartment(b);
}
