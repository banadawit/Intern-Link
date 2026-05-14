/**
 * supervisorWeeklyPlanFilter — STUBBED
 *
 * Depends on managerId (Team) and tl_status (WeeklyPlan) which are not yet
 * in the current schema. Returns safe no-op values until migrations are applied.
 */
import type { Prisma } from '@prisma/client';

export async function getPeerStudentIdsWithTeamLeaderForCompany(
    _companyId: number,
): Promise<number[]> {
    return [];
}

export function weeklyPlanWhereVisibleToSupervisor(
    _peerWithTlStudentIds: number[],
): Prisma.WeeklyPlanWhereInput {
    return {};
}
