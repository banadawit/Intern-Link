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

/** AND-clause: fully hide individual plans for team-member students from supervisor lists.
 *  Supervisor only reviews the compiled TeamWeeklyPlan, not individual member plans.
 */

export function weeklyPlanWhereVisibleToSupervisor(
    _peerWithTlStudentIds: number[],
): Prisma.WeeklyPlanWhereInput {

    if (peerWithTlStudentIds.length === 0) return {};
    // Exclude ALL individual plans from students who are on a team with a TL
    return {
        studentId: { notIn: peerWithTlStudentIds },
    };

    return {};
 main
}
