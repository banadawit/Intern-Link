/**
 * teamPlanController
 *
 * Handles team leader (project manager) assignment and team plan workflows.
 */
import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { sendNotification } from '../utils/notificationHelper';

// ─── Helpers ──────────────────────────────────────────────────────────────────

async function getSupervisor(req: AuthRequest) {
    return prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
}

/** Get student profile or throw a 403 error */
async function getStudentOrFail(userId: number) {
    const student = await prisma.student.findUnique({ where: { userId } });
    if (!student) {
        const err = new Error('Student profile not found.') as Error & { status: number };
        err.status = 403;
        throw err;
    }
    return student;
}

// ─── Supervisor: assign / unassign team leader ────────────────────────────────

/**
 * PATCH /supervisor/teams/:teamId/manager
 * Body: { studentId: number } — pass null/0 to unassign
 */
export const assignTeamManager = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) { sendError(res, 'Supervisor profile not found.', 403); return; }

        const teamId    = parseInt(String(req.params.teamId), 10);
        const studentId = req.body?.studentId != null && req.body.studentId !== ''
            ? parseInt(String(req.body.studentId), 10)
            : null;

        const team = await prisma.team.findFirst({
            where: { id: teamId, companyId: sup.companyId, deleted_at: null },
            include: { members: { select: { studentId: true } } },
        });
        if (!team) { sendError(res, 'Team not found.', 404); return; }

        if (studentId !== null) {
            const isMember = team.members.some((m: { studentId: number }) => m.studentId === studentId);
            if (!isMember) { sendError(res, 'Student is not a member of this team.', 400); return; }
        }

        const updated = await prisma.team.update({
            where: { id: teamId },
            data: { managerId: studentId },
            include: {
                manager: { include: { user: { select: { full_name: true, email: true } } } },
            },
        });

        if (studentId !== null) {
            const leader = await prisma.student.findUnique({
                where: { id: studentId },
                include: { user: { select: { id: true } } },
            });
            if (leader) {
                sendNotification(
                    leader.user.id,
                    `You have been assigned as Team Leader for team "${team.name}".`,
                ).catch(() => {});
            }
        }

        sendSuccess(res, updated, studentId !== null ? 'Team leader assigned.' : 'Team leader removed.');
    } catch (e: unknown) {
        const err = e as Error & { status?: number };
        sendError(res, err.message ?? 'Server error', err.status ?? 500);
    }
};

// ─── Team Leader: forward compiled plan to supervisor ─────────────────────────

export const forwardToSupervisor = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const { week_number, plan_description, title } = req.body as {
            week_number?: number; plan_description?: string; title?: string;
        };

        if (!week_number || !plan_description?.trim()) {
            return sendError(res, 'week_number and plan_description are required.', 400);
        }

        const team = await prisma.team.findFirst({
            where: { managerId: student.id, deleted_at: null },
            include: {
                members: {
                    include: {
                        student: { include: { user: { select: { id: true } } } },
                    },
                },
            },
        });
        if (!team) return sendError(res, 'You are not a Team Leader.', 403);

        const existing = await prisma.teamWeeklyPlan.findUnique({
            where: { teamId_week_number: { teamId: team.id, week_number } },
        });

        if (existing) {
            const updated = await prisma.teamWeeklyPlan.update({
                where: { id: existing.id },
                data: {
                    title: typeof title === 'string' ? title.trim() || null : existing.title,
                    plan_description: plan_description.trim(),
                    status: 'PENDING',
                    feedback: null,
                    reviewed_at: null,
                    version: existing.version + 1,
                    submitted_at: new Date(),
                },
            });
            return sendSuccess(res, updated, 'Team plan forwarded to supervisor.', 200);
        }

        const plan = await prisma.teamWeeklyPlan.create({
            data: {
                teamId: team.id,
                projectId: team.projectId ?? undefined,
                submittedById: student.id,
                week_number,
                title: typeof title === 'string' ? title.trim() || null : null,
                plan_description: plan_description.trim(),
                status: 'PENDING',
            },
        });

        for (const m of team.members) {
            if (m.student.user.id !== req.user!.userId) {
                void sendNotification(m.student.user.id,
                    `📤 Your Team Leader has forwarded the Week ${week_number} team plan to the supervisor.`
                );
            }
        }

        return sendSuccess(res, plan, 'Team plan forwarded to supervisor.', 201);
    } catch (e: unknown) {
        const err = e as Error & { status?: number };
        return sendError(res, err.message ?? 'Server error', err.status ?? 500);
    }
};

// ─── Team Leader: review the compiled team plan ───────────────────────────────

export const tlReviewTeamPlan = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const planId = parseInt(String(req.params.planId), 10);
        const { status, comment } = req.body as { status?: string; comment?: string };

        if (status !== 'APPROVED' && status !== 'REVISION_REQUESTED') {
            return sendError(res, "status must be 'APPROVED' or 'REVISION_REQUESTED'.", 400);
        }

        const teamPlan = await prisma.teamWeeklyPlan.findUnique({
            where: { id: planId },
            include: {
                team: {
                    include: {
                        members: {
                            include: { student: { include: { user: { select: { id: true } } } } },
                        },
                    },
                },
            },
        });
        if (!teamPlan) return sendError(res, 'Team plan not found.', 404);
        if (teamPlan.team.managerId !== student.id) {
            return sendError(res, 'Only the Team Leader can review this plan.', 403);
        }

        const trimmedComment = typeof comment === 'string' ? comment.trim() || null : null;

        if (status === 'APPROVED') {
            await prisma.teamWeeklyPlan.update({
                where: { id: planId },
                data: { status: 'PENDING', feedback: trimmedComment, reviewed_at: new Date() },
            });

            for (const m of teamPlan.team.members) {
                void sendNotification(m.student.user.id,
                    `📤 Team Leader approved the Week ${teamPlan.week_number} team plan. It has been forwarded to the supervisor.`
                );
            }

            return sendSuccess(res, null, `Week ${teamPlan.week_number} team plan forwarded to supervisor.`);
        } else {
            await prisma.teamWeeklyPlan.update({
                where: { id: planId },
                data: { status: 'REVISION_REQUESTED', feedback: trimmedComment, reviewed_at: new Date() },
            });

            const memberIds = teamPlan.team.members.map((m) => m.studentId);
            await prisma.weeklyPlan.updateMany({
                where: { studentId: { in: memberIds }, week_number: teamPlan.week_number },
                data: { tl_status: 'REVISION_REQUESTED', tl_comment: trimmedComment },
            });

            for (const m of teamPlan.team.members) {
                void sendNotification(m.student.user.id,
                    `🔄 Team Leader requested revision for the Week ${teamPlan.week_number} team plan.${trimmedComment ? ` Comment: ${trimmedComment}` : ''} Please revise and resubmit.`
                );
            }

            return sendSuccess(res, null, 'Revision requested. Members have been notified.');
        }
    } catch (e: unknown) {
        const err = e as Error & { status?: number };
        return sendError(res, err.message ?? 'Server error', err.status ?? 500);
    }
};

// ─── Team Leader: get all team members' daily submissions ─────────────────────

export const getTeamMembersDailyPlans = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);

        const team = await prisma.team.findFirst({
            where: { managerId: student.id, deleted_at: null },
            include: {
                members: {
                    include: {
                        student: {
                            include: {
                                user: { select: { id: true, full_name: true, email: true } },
                                weeklyPlans: {
                                    orderBy: { week_number: 'asc' },
                                    include: { daySubmissions: { orderBy: { workDate: 'asc' } } },
                                },
                            },
                        },
                    },
                },
                weeklyPlans: {
                    where: { status: 'APPROVED' },
                    orderBy: { week_number: 'asc' },
                    include: { dailyPlans: { select: { workDate: true, status: true } } },
                },
            },
        });

        if (!team) return sendError(res, 'You are not a Team Leader of any team.', 403);

        const peerMembers = team.members.filter((m) => m.studentId !== team.managerId);

        const weekNumbers = [...new Set(
            peerMembers.flatMap((m) => m.student.weeklyPlans.map((p) => p.week_number))
        )].sort((a: number, b: number) => a - b);

        const weeklyData = weekNumbers.map((weekNum) => {
            const approvedTeamPlan = team.weeklyPlans.find((p) => p.week_number === weekNum);
            const members = peerMembers.map((m) => {
                const weeklyPlan = m.student.weeklyPlans.find((p) => p.week_number === weekNum);
                return {
                    studentId: m.studentId,
                    fullName: m.student.user.full_name,
                    email: m.student.user.email,
                    weeklyPlanId: weeklyPlan?.id ?? null,
                    weeklyPlanApproved: weeklyPlan?.tl_status === 'APPROVED',
                    dailySubmissions: (weeklyPlan?.daySubmissions ?? []).map((d) => ({
                        id: d.id,
                        workDate: d.workDate instanceof Date
                            ? d.workDate.toISOString().slice(0, 10)
                            : String(d.workDate).slice(0, 10),
                        notes: d.notes,
                        tl_status: d.tl_status,
                        tl_comment: d.tl_comment,
                    })),
                };
            });

            const forwardedDailyDates: Record<string, string> = {};
            if (approvedTeamPlan) {
                for (const dp of (approvedTeamPlan as typeof approvedTeamPlan & { dailyPlans: { workDate: Date | string; status: string }[] }).dailyPlans ?? []) {
                    const ymd = dp.workDate instanceof Date
                        ? dp.workDate.toISOString().slice(0, 10)
                        : String(dp.workDate).slice(0, 10);
                    forwardedDailyDates[ymd] = dp.status;
                }
            }

            return {
                weekNumber: weekNum,
                teamWeeklyPlanApproved: !!approvedTeamPlan,
                teamWeeklyPlanId: approvedTeamPlan?.id ?? null,
                teamWeeklyPlanDescription: approvedTeamPlan?.plan_description ?? null,
                forwardedDailyDates,
                members,
            };
        });

        return sendSuccess(res, { teamId: team.id, teamName: team.name, weeks: weeklyData });
    } catch (e: unknown) {
        const err = e as Error & { status?: number };
        return sendError(res, err.message ?? 'Server error', err.status ?? 500);
    }
};

// ─── Team Leader: forward compiled daily plans to supervisor ──────────────────

export const forwardDailyToSupervisor = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const { week_number, work_date, notes } = req.body as {
            week_number?: number; work_date?: string; notes?: string;
        };

        if (!week_number || !work_date) {
            return sendError(res, 'week_number and work_date are required.', 400);
        }

        const team = await prisma.team.findFirst({
            where: { managerId: student.id, deleted_at: null },
            include: {
                members: {
                    include: { student: { include: { user: { select: { id: true } } } } },
                },
                weeklyPlans: {
                    where: { week_number, status: 'APPROVED' },
                    take: 1,
                },
            },
        });
        if (!team) return sendError(res, 'You are not a Team Leader.', 403);

        const teamWeeklyPlan = team.weeklyPlans[0];
        if (!teamWeeklyPlan) {
            return sendError(res, `The team weekly plan for Week ${week_number} must be approved by the supervisor before submitting daily plans.`, 400);
        }

        const peerMemberIds = team.members
            .map((m) => m.studentId)
            .filter((sid) => sid !== team.managerId);

        const memberDailyPlans = await prisma.weeklyPlanDaySubmission.findMany({
            where: {
                workDate: new Date(`${work_date}T12:00:00.000Z`),
                weeklyPlan: { studentId: { in: peerMemberIds }, week_number },
                tl_status: 'APPROVED',
            },
            include: { weeklyPlan: { select: { studentId: true } } },
        });

        const compiledNotes = notes?.trim() || memberDailyPlans
            .map((d) => d.notes?.trim())
            .filter(Boolean)
            .join('\n') || null;

        const workDateObj = new Date(`${work_date}T12:00:00.000Z`);

        const existing = await prisma.teamDailyPlan.findUnique({
            where: { teamWeeklyPlanId_workDate: { teamWeeklyPlanId: teamWeeklyPlan.id, workDate: workDateObj } },
        });

        let daily;
        if (existing) {
            daily = await prisma.teamDailyPlan.update({
                where: { id: existing.id },
                data: { notes: compiledNotes, status: 'PENDING', supervisorNote: null, reviewedAt: null },
            });
        } else {
            daily = await prisma.teamDailyPlan.create({
                data: {
                    teamWeeklyPlanId: teamWeeklyPlan.id,
                    submittedById: student.id,
                    workDate: workDateObj,
                    notes: compiledNotes,
                    status: 'PENDING',
                },
            });
        }

        for (const m of team.members) {
            if (m.student.user.id !== req.user!.userId) {
                void sendNotification(m.student.user.id,
                    `📤 Team Leader forwarded the daily plan for ${work_date} (Week ${week_number}) to the supervisor.`
                );
            }
        }

        return sendSuccess(res, daily, `Daily plan for ${work_date} forwarded to supervisor.`, 201);
    } catch (e: unknown) {
        const err = e as Error & { status?: number };
        return sendError(res, err.message ?? 'Server error', err.status ?? 500);
    }
};

// ─── Team Leader: get compiled draft from approved member plans ───────────────

export const getCompiledDraft = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const weekNum = parseInt(String(req.query.week), 10);
        if (Number.isNaN(weekNum)) return sendError(res, 'week query param required.', 400);

        const team = await prisma.team.findFirst({
            where: { managerId: student.id, deleted_at: null },
            include: {
                members: {
                    include: {
                        student: {
                            include: {
                                user: { select: { full_name: true } },
                                weeklyPlans: {
                                    where: { week_number: weekNum, tl_status: 'APPROVED' },
                                    include: { daySubmissions: { where: { tl_status: 'APPROVED' } } },
                                },
                            },
                        },
                    },
                },
            },
        });
        if (!team) return sendError(res, 'You are not a Team Leader.', 403);

        const peerMembers = team.members.filter((m) => m.studentId !== team.managerId);

        const approvedPlans = peerMembers
            .filter((m) => m.student.weeklyPlans.length > 0)
            .map((m) => ({
                memberName: m.student.user.full_name,
                plan: m.student.weeklyPlans[0].plan_description,
                approvedDailyDates: m.student.weeklyPlans[0].daySubmissions.map((d) =>
                    d.workDate instanceof Date
                        ? d.workDate.toISOString().slice(0, 10)
                        : String(d.workDate).slice(0, 10)
                ),
            }));

        const compiledText = approvedPlans.length > 0
            ? approvedPlans.map((p) => `**${p.memberName}:**\n${p.plan}`).join('\n\n')
            : '';

        return sendSuccess(res, {
            weekNumber: weekNum,
            compiledDraft: compiledText,
            approvedMembersCount: approvedPlans.length,
            totalMembers: peerMembers.length,
            members: approvedPlans,
        });
    } catch (e: unknown) {
        const err = e as Error & { status?: number };
        return sendError(res, err.message ?? 'Server error', err.status ?? 500);
    }
};

// ─── Remaining stubs ──────────────────────────────────────────────────────────

const notImplemented = (_req: AuthRequest, res: Response): void => {
    res.status(501).json({ success: false, message: 'This team plan feature is not yet fully implemented.' });
};

export const submitTeamWeeklyPlan   = notImplemented;
export const submitTeamDailyPlan    = notImplemented;
export const getTeamMembersPlans    = notImplemented;
export const getMyTeamPlans         = notImplemented;
export const getTeamWeeklyPlans     = notImplemented;
export const reviewTeamWeeklyPlan   = notImplemented;
export const reviewTeamDailyPlan    = notImplemented;
export const tlReviewWeeklyPlan     = notImplemented;
export const tlReviewDailyPlan      = notImplemented;
