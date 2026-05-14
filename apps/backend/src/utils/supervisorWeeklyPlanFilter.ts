import type { Prisma } from '@prisma/client';
import prisma from '../config/db';

/**
 * Active company students who are teammates (not the Team Leader) on a team that has a TL assigned.
 * Their individual weekly plans stay off the supervisor queue until `tl_status === APPROVED'`.
 */
export async function getPeerStudentIdsWithTeamLeaderForCompany(companyId: number): Promise<number[]> {
    const active = await prisma.internshipAssignment.findMany({
        where: { companyId, status: 'ACTIVE' },
        select: { studentId: true },
    });
    const ids = [...new Set(active.map((a) => a.studentId))];
    if (ids.length === 0) return [];

    const memberships = await prisma.studentTeam.findMany({
        where: {
            studentId: { in: ids },
            team: { deleted_at: null, managerId: { not: null } },
        },
        select: { studentId: true, team: { select: { managerId: true } } },
    });

    const peerIds = new Set<number>();
    for (const m of memberships) {
        const mgr = m.team.managerId;
        if (mgr != null && mgr !== m.studentId) peerIds.add(m.studentId);
    }
    return [...peerIds];
}

/** AND-clause: fully hide individual plans for team-member students from supervisor lists.
 *  Supervisor only reviews the compiled TeamWeeklyPlan, not individual member plans.
 */
export function weeklyPlanWhereVisibleToSupervisor(
    peerWithTlStudentIds: number[],
): Prisma.WeeklyPlanWhereInput {
    if (peerWithTlStudentIds.length === 0) return {};
    // Exclude ALL individual plans from students who are on a team with a TL
    return {
        studentId: { notIn: peerWithTlStudentIds },
    };
}
