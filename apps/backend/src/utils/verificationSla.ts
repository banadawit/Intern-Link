/** Response Time Policy: Approve/Reject within this many hours of submission (submission time = record created_at). */
export const VERIFICATION_RESPONSE_HOURS = 24;

export type WithVerificationSla<T> = T & {
    responseDueAt: string;
    slaOverdue: boolean;
    slaRemainingMs: number;
};

export function attachVerificationSla<T extends { created_at: Date }>(row: T, now: Date = new Date()): WithVerificationSla<T> {
    const deadline = new Date(row.created_at.getTime() + VERIFICATION_RESPONSE_HOURS * 60 * 60 * 1000);
    const remainingMs = deadline.getTime() - now.getTime();
    return {
        ...row,
        responseDueAt: deadline.toISOString(),
        slaOverdue: remainingMs < 0,
        slaRemainingMs: remainingMs,
    };
}

/** BR-002: Company response SLA for internship proposals (clock starts at submitted_at). */
export function attachProposalSla<T extends { submitted_at: Date }>(row: T, now: Date = new Date()): WithVerificationSla<T> {
    const deadline = new Date(row.submitted_at.getTime() + VERIFICATION_RESPONSE_HOURS * 60 * 60 * 1000);
    const remainingMs = deadline.getTime() - now.getTime();
    return {
        ...row,
        responseDueAt: deadline.toISOString(),
        slaOverdue: remainingMs < 0,
        slaRemainingMs: remainingMs,
    };
}
