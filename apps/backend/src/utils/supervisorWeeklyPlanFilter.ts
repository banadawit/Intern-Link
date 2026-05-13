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

/** AND-clause: hide peer TL-queue plans from supervisor lists and counts. */
export function weeklyPlanWhereVisibleToSupervisor(
    peerWithTlStudentIds: number[],
): Prisma.WeeklyPlanWhereInput {
    if (peerWithTlStudentIds.length === 0) return {};
    return {
        OR: [
            { studentId: { notIn: peerWithTlStudentIds } },
            { status: { notIn: ['PENDING', 'RESUBMITTED'] } },
            { tl_status: 'APPROVED' },
        ],
    };
}
