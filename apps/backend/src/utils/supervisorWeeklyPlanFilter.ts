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
    peerWithTlStudentIds: number[],
): Prisma.WeeklyPlanWhereInput {
    if (peerWithTlStudentIds.length === 0) return {};
    return {
        studentId: { notIn: peerWithTlStudentIds },
    };
}
