import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { incrementActivityForUser } from '../services/activityLog.service';
import { sendNotification } from '../utils/notificationHelper';

async function getSupervisor(req: AuthRequest) {
    return prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
}

async function getStudentOrFail(userId: number) {
    const s = await prisma.student.findUnique({ where: { userId } });
    if (!s) throw Object.assign(new Error('Student profile not found.'), { status: 404 });
    return s;
}

// ── Supervisor: assign project manager to a team ──────────────────────────────
export const assignTeamManager = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

        const teamId = parseInt(String(req.params.teamId), 10);
        const studentId = parseInt(String(req.body?.studentId), 10);
        if (Number.isNaN(teamId) || Number.isNaN(studentId)) {
            return sendError(res, 'teamId and studentId are required.', 400);
        }

        const team = await prisma.team.findFirst({
            where: { id: teamId, companyId: sup.companyId, deleted_at: null },
            include: { members: { select: { studentId: true } } },
        });
        if (!team) return sendError(res, 'Team not found.', 404);

        // Manager must be a team member
        const isMember = team.members.some((m) => m.studentId === studentId);
        if (!isMember) return sendError(res, 'Student must be a team member to be assigned as manager.', 400);

        const updated = await prisma.team.update({
            where: { id: teamId },
            data: { managerId: studentId },
        });

        // Notify the new PM
        const student = await prisma.student.findUnique({ where: { id: studentId }, include: { user: { select: { id: true, full_name: true } } } });
        if (student) {
            void sendNotification(student.user.id, `🎯 You have been assigned as Project Manager for team "${team.name}". You can now submit weekly and daily plans on behalf of your team.`);
        }

        return sendSuccess(res, updated, 'Project manager assigned.');
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Project Manager: submit team weekly plan ──────────────────────────────────
export const submitTeamWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const { teamId, week_number, plan_description } = req.body as {
            teamId?: number; week_number?: number; plan_description?: string;
        };

        if (!teamId || !week_number || !plan_description?.trim()) {
            return sendError(res, 'teamId, week_number, and plan_description are required.', 400);
        }

        // Verify student is the PM of this team
        const team = await prisma.team.findFirst({
            where: { id: teamId, managerId: student.id, deleted_at: null },
            include: { members: { include: { student: { include: { user: { select: { id: true } } } } } } },
        });
        if (!team) return sendError(res, 'You are not the project manager of this team.', 403);

        const existing = await prisma.teamWeeklyPlan.findUnique({
            where: { teamId_week_number: { teamId, week_number } },
        });
        if (existing) return sendError(res, `A team plan for Week ${week_number} already exists.`, 400);

        const plan = await prisma.teamWeeklyPlan.create({
            data: {
                teamId,
                projectId: team.projectId ?? undefined,
                submittedById: student.id,
                week_number,
                plan_description: plan_description.trim(),
                status: 'PENDING',
            },
        });

        // Increment activity for PM
        void incrementActivityForUser(req.user!.userId);

        // Notify all team members
        for (const m of team.members) {
            if (m.student.user.id !== req.user!.userId) {
                void sendNotification(m.student.user.id, `📋 Your team's Week ${week_number} plan has been submitted by the project manager.`);
            }
        }

        return sendSuccess(res, plan, 'Team weekly plan submitted.', 201);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Project Manager: submit team daily plan ───────────────────────────────────
export const submitTeamDailyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const teamWeeklyPlanId = parseInt(String(req.params.planId), 10);
        const { workDate, notes } = req.body as { workDate?: string; notes?: string };

        if (Number.isNaN(teamWeeklyPlanId) || !workDate) {
            return sendError(res, 'planId and workDate are required.', 400);
        }

        const weeklyPlan = await prisma.teamWeeklyPlan.findUnique({
            where: { id: teamWeeklyPlanId },
            include: { team: { include: { members: { include: { student: { include: { user: { select: { id: true } } } } } } } } },
        });
        if (!weeklyPlan) return sendError(res, 'Team weekly plan not found.', 404);
        if (weeklyPlan.team.managerId !== student.id) return sendError(res, 'Only the project manager can submit daily plans.', 403);
        if (weeklyPlan.status !== 'APPROVED') return sendError(res, 'Daily plans can only be submitted after the weekly plan is approved.', 400);

        const existing = await prisma.teamDailyPlan.findUnique({
            where: { teamWeeklyPlanId_workDate: { teamWeeklyPlanId, workDate: new Date(`${workDate}T12:00:00.000Z`) } },
        });
        if (existing) return sendError(res, 'A daily plan for this date already exists.', 400);

        const daily = await prisma.teamDailyPlan.create({
            data: {
                teamWeeklyPlanId,
                submittedById: student.id,
                workDate: new Date(`${workDate}T12:00:00.000Z`),
                notes: notes?.trim() || null,
                status: 'PENDING',
            },
        });

        void incrementActivityForUser(req.user!.userId);

        return sendSuccess(res, daily, 'Team daily plan submitted.', 201);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Team Leader: get all team members' individual weekly + daily plans ────────
export const getTeamMembersPlans = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);

        // Verify student is TL of their team
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
                                    include: {
                                        daySubmissions: { orderBy: { workDate: 'asc' } },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        });

        if (!team) return sendError(res, 'You are not a Team Leader of any team.', 403);

        const membersData = team.members.map((m) => ({
            studentId: m.studentId,
            fullName: m.student.user.full_name,
            email: m.student.user.email,
            isMe: m.studentId === student.id,
            weeklyPlans: m.student.weeklyPlans.map((p) => ({
                id: p.id,
                weekNumber: p.week_number,
                description: p.plan_description,
                status: p.status,
                feedback: p.feedback,
                submittedAt: p.submitted_at,
                dailySubmissions: p.daySubmissions.map((d) => ({
                    id: d.id,
                    workDate: d.workDate instanceof Date ? d.workDate.toISOString().slice(0, 10) : String(d.workDate).slice(0, 10),
                    notes: d.notes,
                    status: d.status,
                })),
            })),
        }));

        return sendSuccess(res, {
            teamId: team.id,
            teamName: team.name,
            members: membersData,
        });
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Student: get team plans for their team ────────────────────────────────────
export const getMyTeamPlans = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);

        const teamMembership = await prisma.studentTeam.findFirst({
            where: { studentId: student.id, team: { deleted_at: null } },
            include: { team: { select: { id: true, name: true, managerId: true } } },
        });
        if (!teamMembership) return sendSuccess(res, [], 'No team found.');

        const plans = await prisma.teamWeeklyPlan.findMany({
            where: { teamId: teamMembership.teamId },
            include: {
                submittedBy: { include: { user: { select: { full_name: true } } } },
                dailyPlans: { orderBy: { workDate: 'asc' } },
            },
            orderBy: { week_number: 'asc' },
        });

        return sendSuccess(res, {
            team: teamMembership.team,
            isManager: teamMembership.team.managerId === student.id,
            plans,
        });
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Supervisor: list all team weekly plans ────────────────────────────────────
export const getTeamWeeklyPlans = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

        const statusFilter = req.query.status as string | undefined;

        const teams = await prisma.team.findMany({
            where: { companyId: sup.companyId, deleted_at: null },
            select: { id: true },
        });
        const teamIds = teams.map((t) => t.id);

        const plans = await prisma.teamWeeklyPlan.findMany({
            where: {
                teamId: { in: teamIds },
                ...(statusFilter === 'PENDING' ? { status: { in: ['PENDING', 'RESUBMITTED'] } } : {}),
            },
            include: {
                team: { select: { id: true, name: true } },
                project: { select: { id: true, name: true } },
                submittedBy: { include: { user: { select: { full_name: true, email: true } } } },
                dailyPlans: { orderBy: { workDate: 'asc' } },
            },
            orderBy: { submitted_at: 'desc' },
        });

        return sendSuccess(res, plans);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Supervisor: review team weekly plan ───────────────────────────────────────
export const reviewTeamWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

        const planId = parseInt(String(req.params.planId), 10);
        const { status, feedback } = req.body as { status?: string; feedback?: string };

        if (status !== 'APPROVED' && status !== 'REJECTED') {
            return sendError(res, "status must be 'APPROVED' or 'REJECTED'.", 400);
        }

        const plan = await prisma.teamWeeklyPlan.findUnique({
            where: { id: planId },
            include: {
                team: {
                    include: {
                        members: {
                            include: { student: { include: { user: { select: { id: true } }, assignments: { where: { status: 'ACTIVE' }, take: 1 } } } },
                        },
                    },
                },
            },
        });
        if (!plan) return sendError(res, 'Team plan not found.', 404);
        if (plan.team.companyId !== sup.companyId) return sendError(res, 'Unauthorized.', 403);

        const updated = await prisma.teamWeeklyPlan.update({
            where: { id: planId },
            data: {
                status,
                feedback: typeof feedback === 'string' ? feedback.trim() || null : null,
                reviewed_at: new Date(),
            },
        });

        if (status === 'APPROVED') {
            // Auto-create attendance (WeeklyPlanDaySubmission) for all team members
            // using the plan submission date as the activity date
            const activityDate = new Date(plan.submitted_at);
            const ymd = activityDate.toISOString().slice(0, 10);

            for (const m of plan.team.members) {
                const s = m.student;
                // Find the student's individual weekly plan for this week (if any) to link attendance
                const individualPlan = await prisma.weeklyPlan.findFirst({
                    where: { studentId: s.id, week_number: plan.week_number },
                });

                if (individualPlan) {
                    // Mark attendance on the plan submission date
                    await prisma.weeklyPlanDaySubmission.upsert({
                        where: { weeklyPlanId_workDate: { weeklyPlanId: individualPlan.id, workDate: new Date(`${ymd}T12:00:00.000Z`) } },
                        create: { weeklyPlanId: individualPlan.id, workDate: new Date(`${ymd}T12:00:00.000Z`), notes: `Auto-recorded: team plan approved (Week ${plan.week_number})` },
                        update: {},
                    });
                }

                // Increment activity log
                void incrementActivityForUser(s.user.id);

                // Notify each member
                void sendNotification(s.user.id, `✅ Your team's Week ${plan.week_number} plan was approved by the supervisor.`);
            }
        } else {
            // Notify PM of rejection
            const pm = plan.team.members.find((m) => m.studentId === plan.team.managerId);
            if (pm) {
                void sendNotification(pm.student.user.id, `❌ Your team's Week ${plan.week_number} plan was rejected. ${feedback ? `Feedback: ${feedback}` : ''}`);
            }
        }

        return sendSuccess(res, updated, `Team plan ${status.toLowerCase()}.`);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Supervisor: review team daily plan ───────────────────────────────────────
export const reviewTeamDailyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

        const dailyId = parseInt(String(req.params.dailyId), 10);
        const { status, supervisorNote } = req.body as { status?: string; supervisorNote?: string };

        if (status !== 'APPROVED' && status !== 'REJECTED') {
            return sendError(res, "status must be 'APPROVED' or 'REJECTED'.", 400);
        }

        const daily = await prisma.teamDailyPlan.findUnique({
            where: { id: dailyId },
            include: {
                teamWeeklyPlan: {
                    include: {
                        team: {
                            include: {
                                members: { include: { student: { include: { user: { select: { id: true } } } } } },
                            },
                        },
                    },
                },
            },
        });
        if (!daily) return sendError(res, 'Team daily plan not found.', 404);
        if (daily.teamWeeklyPlan.team.companyId !== sup.companyId) return sendError(res, 'Unauthorized.', 403);

        const updated = await prisma.teamDailyPlan.update({
            where: { id: dailyId },
            data: {
                status,
                supervisorNote: typeof supervisorNote === 'string' ? supervisorNote.trim() || null : null,
                reviewedAt: new Date(),
            },
        });

        if (status === 'APPROVED') {
            const workDateStr = daily.workDate instanceof Date
                ? daily.workDate.toISOString().slice(0, 10)
                : String(daily.workDate).slice(0, 10);

            // Auto-record attendance for all team members on this date
            for (const m of daily.teamWeeklyPlan.team.members) {
                const s = m.student;
                const individualPlan = await prisma.weeklyPlan.findFirst({
                    where: { studentId: s.id, week_number: daily.teamWeeklyPlan.week_number },
                });
                if (individualPlan) {
                    await prisma.weeklyPlanDaySubmission.upsert({
                        where: { weeklyPlanId_workDate: { weeklyPlanId: individualPlan.id, workDate: new Date(`${workDateStr}T12:00:00.000Z`) } },
                        create: { weeklyPlanId: individualPlan.id, workDate: new Date(`${workDateStr}T12:00:00.000Z`), notes: 'Auto-recorded: team daily plan approved' },
                        update: {},
                    });
                }
                void incrementActivityForUser(s.user.id);
                void sendNotification(s.user.id, `✅ Your team's daily plan for ${workDateStr} was approved.`);
            }
        }

        return sendSuccess(res, updated, `Team daily plan ${status.toLowerCase()}.`);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};
