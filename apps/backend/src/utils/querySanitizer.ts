import { ApprovalStatus } from '@prisma/client';
import prisma from '../config/db';

export function sanitizeApprovalStatuses(input: unknown): ApprovalStatus[] {
    if (input == null) return [];
    const valid = new Set<string>(Object.values(ApprovalStatus) as string[]);
    const arr = Array.isArray(input) ? input : [input];
    return arr
        .map((v) => (typeof v === 'string' ? v.toUpperCase() : String(v).toUpperCase()))
        .filter((s) => valid.has(s)) as ApprovalStatus[];
}

export async function safeFindFirstProposal(params: {
    where: any;
    select?: any;
    include?: any;
}) {
    const where = { ...(params.where ?? {}) };
    // Normalize if caller passed status as array or object with in: []
    if (where.status != null) {
        const filtered = sanitizeApprovalStatuses(where.status);
        if (filtered.length === 0) {
            // remove status filter to avoid invalid enum errors
            delete where.status;
        } else if (filtered.length === 1) {
            where.status = filtered[0];
        } else {
            where.status = { in: filtered };
        }
    }
    const args: any = { where };
    if (params.select) args.select = params.select;
    else if (params.include) args.include = params.include;
    return prisma.internshipProposal.findFirst(args);
}

export default {};
