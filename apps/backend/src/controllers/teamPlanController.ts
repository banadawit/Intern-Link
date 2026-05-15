import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import { sendSuccess, sendError } from '../utils/responseHelper';
import prisma from '../config/db';

// ── Assign team manager ───────────────────────────────────────────────────────

export const assignTeamManager = async (req: AuthRequest, res: Response) => {
    try {
        const teamId = parseInt(String(req.params.teamId), 10);
        const { studentId } = req.body as { studentId?: number };
        if (isNaN(teamId) || !studentId) return res.status(400).json({ success: false, message: 'teamId and studentId are required.' });

        const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
        if (!supervisor) return res.status(403).json({ success: false, message: 'Supervisor not found.' });

        const team = await prisma.team.findFirst({ where: { id: teamId, companyId: supervisor.companyId, deleted_at: null } });
        if (!team) return res.status(404).json({ success: false, message: 'Team not found.' });

        const membership = await prisma.studentTeam.findFirst({ where: { teamId, studentId } });
        if (!membership) return res.status(400).json({ success: false, message: 'Student is not a member of this team.' });

        const updated = await prisma.team.update({ where: { id: teamId }, data: { managerId: studentId } });
        return res.json({ success: true, message: 'Team leader assigned.', data: updated });
    } catch (error: any) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ── Student: get own team info + plans ────────────────────────────────────────

export const getMyTeamPlans = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student not found.', 404);

        const membership = await prisma.studentTeam.findFirst({
            where: { studentId: student.id, team: { deleted_at: null } },
            include: {
                team: {
                    include: {
                        members: { include: { student: { include: { user: { select: { full_name: true, email: true } } } } } },
                        project: { select: { id: true, name: true, description: true } },
                    },
                },
            },
        });

        if (!membership) return sendSuccess(res, null, 'Not in a team.');

        const team = membership.team;
        const isManager = team.managerId === student.id;

        const plans = await prisma.weeklyPlan.findMany({
            where: { studentId: student.id },
            orderBy: { week_number: 'asc' },
            include: { daySubmissions: { orderBy: { workDate: 'asc' } } },
        });

        return sendSuccess(res, {
            team: { id: team.id, name: team.name, managerId: team.managerId },
            isManager,
            plans: plans.map((p) => ({
                id: p.id,
                week_number: p.week_number,
                plan_description: p.plan_description,
                status: p.status,
                feedback: p.feedback,
                submitted_at: p.submitted_at,
                tl_status: (p as any).tl_status ?? 'PENDING',
                tl_comment: (p as any).tl_comment ?? null,
                title: null,
                submittedBy: { user: { full_name: 'You' } },
                dailyPlans: [],
            })),
        });
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ── TL: see all team members' plans ──────────────────────────────────────────

export const getTeamMembersPlans = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student not found.', 404);

        const membership = await prisma.studentTeam.findFirst({
            where: { studentId: student.id, team: { deleted_at: null, managerId: student.id } },
            include: {
                team: {
                    include: {
                        members: {
                            include: {
                                student: {
                                    include: {
                                        user: { select: { full_name: true, email: true } },
                                        weeklyPlans: {
                                            orderBy: { week_number: 'asc' },
                                            include: { daySubmissions: { orderBy: { workDate: 'asc' } } },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        });

        if (!membership) return sendError(res, 'You are not a team leader of any team.', 403);

        const team = membership.team;
        const members = team.members
            .filter((m) => m.studentId !== student.id)
            .map((m) => ({
                studentId: m.student.id,
                fullName: m.student.user.full_name,
                email: m.student.user.email,
                isMe: false,
                weeklyPlans: m.student.weeklyPlans.map((p) => ({
                    id: p.id,
                    weekNumber: p.week_number,
                    description: p.plan_description,
                    status: p.status,
                    feedback: p.feedback,
                    submittedAt: p.submitted_at,
                    tl_status: (p as any).tl_status ?? 'PENDING',
                    tl_comment: (p as any).tl_comment ?? null,
                    dailySubmissions: p.daySubmissions.map((d) => ({
                        id: d.id,
                        workDate: d.workDate,
                        notes: d.notes,
                        status: 'APPROVED',
                        tl_status: (d as any).tl_status ?? 'PENDING',
                        tl_comment: (d as any).tl_comment ?? null,
                    })),
                })),
            }));

        return sendSuccess(res, { teamId: team.id, teamName: team.name, members });
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ── TL: get compiled draft from member plans ──────────────────────────────────

export const getCompiledDraft = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const weekNum = parseInt(String(req.query.week ?? '1'), 10);
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student not found.', 404);

        const membership = await prisma.studentTeam.findFirst({
            where: { studentId: student.id, team: { deleted_at: null, managerId: student.id } },
            include: {
                team: {
                    include: {
                        members: {
                            include: {
                                student: {
                                    include: {
                                        user: { select: { full_name: true } },
                                        weeklyPlans: { where: { week_number: weekNum } },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        });

        if (!membership) return sendError(res, 'Not a team leader.', 403);

        const peers = membership.team.members.filter((m) => m.studentId !== student.id);
        const approvedPlans = peers
            .map((m) => ({ memberName: m.student.user.full_name, plan: m.student.weeklyPlans[0]?.plan_description }))
            .filter((p) => p.plan);

        const compiledDraft = approvedPlans.length > 0
            ? approvedPlans.map((p) => `**${p.memberName}:**\n${p.plan}`).join('\n\n')
            : 'No member plans submitted yet for this week.';

        return sendSuccess(res, {
            compiledDraft,
            approvedMembersCount: approvedPlans.length,
            totalMembers: peers.length,
        });
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ── TL: forward compiled plan to supervisor ───────────────────────────────────

export const forwardToSupervisor = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const { week_number, plan_description, compiled_description } = req.body as {
            week_number?: number;
            plan_description?: string;
            compiled_description?: string;
        };
        if (!week_number || !plan_description?.trim()) return sendError(res, 'week_number and plan_description are required.', 400);

        const student = await prisma.student.findUnique({
            where: { userId },
            include: { assignments: { where: { status: 'ACTIVE' } } },
        });
        if (!student) return sendError(res, 'Student not found.', 404);
        if (student.internship_status !== 'PLACED') return sendError(res, 'You must be placed to submit plans.', 403);

        const existing = await prisma.weeklyPlan.findFirst({ where: { studentId: student.id, week_number } });
        if (existing) return sendError(res, `A plan for Week ${week_number} already exists.`, 400);

        // Store TL's own plan description. Append compiled team description as context if provided.
        const fullDescription = compiled_description?.trim()
            ? `${plan_description.trim()}\n\n---\n**Team Compiled Plans:**\n${compiled_description.trim()}`
            : plan_description.trim();

        const plan = await prisma.weeklyPlan.create({
            data: { studentId: student.id, week_number, plan_description: fullDescription, status: 'PENDING' },
        });

        // Auto-record TL's own attendance for this week (WeeklyReport)
        try {
            const assignment = student.assignments[0];
            if (assignment) {
                const supervisor = await prisma.supervisor.findFirst({
                    where: { companyId: assignment.companyId },
                });
                if (supervisor) {
                    await prisma.weeklyReport.upsert({
                        where: { weeklyPlanId: plan.id },
                        update: { attendanceStatus: 'PRESENT' },
                        create: {
                            studentId: student.id,
                            supervisorId: supervisor.id,
                            weeklyPlanId: plan.id,
                            attendanceStatus: 'PRESENT',
                            remarks: 'Team Leader weekly plan submitted.',
                        },
                    });
                }
            }
        } catch {
            // Non-fatal
        }

        return sendSuccess(res, plan, 'Team plan forwarded to supervisor.', 201);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ── TL review — simplified (no tl_status in schema) ──────────────────────────

export const tlReviewWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.planId), 10);
        const { status, comment } = req.body as { status?: string; comment?: string };
        if (!status || !['APPROVED', 'REVISION_REQUESTED'].includes(status)) {
            return sendError(res, "status must be 'APPROVED' or 'REVISION_REQUESTED'.", 400);
        }

        const userId = req.user!.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student not found.', 404);

        // Verify TL is the manager of the team the plan's student belongs to
        const plan = await prisma.weeklyPlan.findUnique({
            where: { id: planId },
            include: { student: { include: { studentTeams: { include: { team: true } } } } },
        });
        if (!plan) return sendError(res, 'Plan not found.', 404);

        const isTlOfTeam = plan.student.studentTeams.some((st) => st.team.managerId === student.id);
        if (!isTlOfTeam) return sendError(res, 'You are not the team leader for this student.', 403);

        const updated = await prisma.weeklyPlan.update({
            where: { id: planId },
            data: {
                tl_status: status,
                tl_comment: comment?.trim() || null,
                tl_reviewed_at: new Date(),
            },
        });

        return sendSuccess(res, updated, `Plan ${status === 'APPROVED' ? 'approved' : 'revision requested'} by Team Leader.`);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

export const tlReviewDailyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const submissionId = parseInt(String(req.params.submissionId), 10);
        const { status, comment } = req.body as { status?: string; comment?: string };
        if (!status || !['APPROVED', 'REVISION_REQUESTED'].includes(status)) {
            return sendError(res, "status must be 'APPROVED' or 'REVISION_REQUESTED'.", 400);
        }

        const userId = req.user!.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student not found.', 404);

        const submission = await prisma.weeklyPlanDaySubmission.findUnique({
            where: { id: submissionId },
            include: {
                weeklyPlan: {
                    include: { student: { include: { studentTeams: { include: { team: true } } } } },
                },
            },
        });
        if (!submission) return sendError(res, 'Submission not found.', 404);

        const isTlOfTeam = submission.weeklyPlan.student.studentTeams.some(
            (st) => st.team.managerId === student.id
        );
        if (!isTlOfTeam) return sendError(res, 'You are not the team leader for this student.', 403);

        const updated = await prisma.weeklyPlanDaySubmission.update({
            where: { id: submissionId },
            data: {
                tl_status: status,
                tl_comment: comment?.trim() || null,
                tl_reviewed_at: new Date(),
            },
        });

        return sendSuccess(res, updated, `Daily plan ${status === 'APPROVED' ? 'approved' : 'revision requested'} by Team Leader.`);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

export const tlReviewTeamPlan = async (_req: AuthRequest, res: Response) =>
    sendSuccess(res, {}, 'Review noted.');

// ── Remaining stubs ───────────────────────────────────────────────────────────

const notImplemented = (_req: AuthRequest, res: Response) =>
    res.status(501).json({ success: false, message: 'Not yet available.' });

export const getTeamWeeklyPlans = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
        if (!supervisor) return sendError(res, 'Supervisor not found.', 403);

        // Get all active students at this company
        const active = await prisma.internshipAssignment.findMany({
            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
            select: { studentId: true },
        });
        const studentIds = [...new Set(active.map((a) => a.studentId))];
        if (studentIds.length === 0) return sendSuccess(res, []);

        // Find which of those students are team managers
        const managedTeams = await prisma.team.findMany({
            where: { managerId: { in: studentIds }, deleted_at: null },
            include: { members: { select: { studentId: true } } },
        });

        const managerIds = managedTeams.map((t) => t.managerId).filter(Boolean) as number[];
        if (managerIds.length === 0) return sendSuccess(res, []);

        // Get weekly plans submitted by team managers (these are the forwarded team plans)
        const plans = await prisma.weeklyPlan.findMany({
            where: { studentId: { in: managerIds }, status: { in: ['PENDING', 'APPROVED', 'REJECTED', 'RESUBMITTED'] } },
            include: {
                student: {
                    include: {
                        user: { select: { full_name: true, email: true } },
                        studentTeams: {
                            where: { team: { managerId: { in: managerIds }, deleted_at: null } },
                            include: { team: { select: { id: true, name: true, project: { select: { id: true, name: true } } } } },
                            take: 1,
                        },
                    },
                },
                daySubmissions: { orderBy: { workDate: 'asc' } },
            },
            orderBy: { submitted_at: 'desc' },
        });

        const result = plans.map((p) => {
            const team = p.student.studentTeams[0]?.team ?? null;
            return {
                id: p.id,
                week_number: p.week_number,
                title: null,
                plan_description: p.plan_description,
                status: p.status,
                feedback: p.feedback,
                submitted_at: p.submitted_at,
                tl_status: 'APPROVED',
                tl_comment: null,
                team: team ? { id: team.id, name: team.name } : null,
                project: team?.project ?? null,
                submittedBy: { user: { full_name: p.student.user.full_name, email: p.student.user.email } },
                dailyPlans: p.daySubmissions.map((d) => ({
                    id: d.id,
                    workDate: d.workDate,
                    notes: d.notes,
                    status: d.status ?? 'PENDING',
                    supervisorNote: d.supervisor_note ?? null,
                    reviewedAt: d.reviewed_at ?? null,
                })),
            };
        });

        return sendSuccess(res, result);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};
export const reviewTeamWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.planId), 10);
        const { status, feedback } = req.body as { status?: string; feedback?: string };
        if (!status || !['APPROVED', 'REJECTED'].includes(status)) {
            return sendError(res, "status must be 'APPROVED' or 'REJECTED'.", 400);
        }

        const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
        if (!supervisor) return sendError(res, 'Supervisor not found.', 403);

        const plan = await prisma.weeklyPlan.findUnique({
            where: { id: planId },
            include: { student: { include: { assignments: { where: { companyId: supervisor.companyId, status: 'ACTIVE' } } } } },
        });
        if (!plan) return sendError(res, 'Plan not found.', 404);
        if (plan.student.assignments.length === 0) return sendError(res, 'Not authorized to review this plan.', 403);

        const updated = await prisma.weeklyPlan.update({
            where: { id: planId },
            data: { status: status as 'APPROVED' | 'REJECTED', feedback: feedback?.trim() || null, reviewed_at: new Date() },
        });

        return sendSuccess(res, updated, `Team plan ${status.toLowerCase()}.`);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};
export const reviewTeamDailyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const dailyId = parseInt(String(req.params.dailyId), 10);
        const { status, supervisorNote } = req.body as { status?: string; supervisorNote?: string };
        if (!status || !['APPROVED', 'REJECTED'].includes(status)) {
            return sendError(res, "status must be 'APPROVED' or 'REJECTED'.", 400);
        }

        const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
        if (!supervisor) return sendError(res, 'Supervisor not found.', 403);

        const submission = await prisma.weeklyPlanDaySubmission.findUnique({
            where: { id: dailyId },
            include: {
                weeklyPlan: {
                    include: {
                        student: {
                            include: { assignments: { where: { companyId: supervisor.companyId, status: 'ACTIVE' } } },
                        },
                    },
                },
            },
        });
        if (!submission) return sendError(res, 'Daily submission not found.', 404);
        if (submission.weeklyPlan.student.assignments.length === 0) {
            return sendError(res, 'This submission is not for a student at your company.', 403);
        }

        // Store supervisor note and update status
        const updated = await prisma.weeklyPlanDaySubmission.update({
            where: { id: dailyId },
            data: {
                status,
                supervisor_note: supervisorNote?.trim() || null,
                reviewed_at: new Date(),
            },
        });

        return sendSuccess(res, updated, `Daily plan ${status.toLowerCase()}.`);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};
export const getTeamMembersDailyPlans = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student not found.', 404);

        const membership = await prisma.studentTeam.findFirst({
            where: { studentId: student.id, team: { deleted_at: null, managerId: student.id } },
            include: {
                team: {
                    include: {
                        members: {
                            include: {
                                student: {
                                    include: {
                                        user: { select: { full_name: true, email: true } },
                                        weeklyPlans: {
                                            orderBy: { week_number: 'asc' },
                                            include: { daySubmissions: { orderBy: { workDate: 'asc' } } },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        });

        if (!membership) return sendError(res, 'You are not a team leader of any team.', 403);

        const team = membership.team;
        const peers = team.members.filter((m) => m.studentId !== student.id);

        // Collect all week numbers across all members
        const allWeekNums = new Set<number>();
        for (const m of peers) {
            for (const p of m.student.weeklyPlans) allWeekNums.add(p.week_number);
        }

        // Check which weeks the TL has already forwarded (their own WeeklyPlan for that week)
        const tlPlans = await prisma.weeklyPlan.findMany({
            where: { studentId: student.id },
            select: { week_number: true, status: true },
        });
        const tlPlanMap = new Map(tlPlans.map((p) => [p.week_number, p.status]));

        const weeks = [...allWeekNums].sort((a, b) => a - b).map((weekNum) => {
            const tlStatus = tlPlanMap.get(weekNum);
            const teamWeeklyPlanApproved = tlStatus === 'APPROVED';

            const members = peers.map((m) => {
                const plan = m.student.weeklyPlans.find((p) => p.week_number === weekNum);
                return {
                    studentId: m.student.id,
                    fullName: m.student.user.full_name,
                    email: m.student.user.email,
                    weeklyPlanId: plan?.id ?? null,
                    weeklyPlanApproved: plan?.status === 'APPROVED' || (plan as any)?.tl_status === 'APPROVED',
                    dailySubmissions: (plan?.daySubmissions ?? []).map((d) => ({
                        id: d.id,
                        workDate: new Date(d.workDate as unknown as string).toISOString().slice(0, 10),
                        notes: d.notes,
                        tl_status: (d as any).tl_status ?? 'PENDING',
                        tl_comment: (d as any).tl_comment ?? null,
                    })),
                };
            });

            return {
                weekNumber: weekNum,
                teamWeeklyPlanApproved,
                teamWeeklyPlanStatus: tlStatus ?? null,
                teamWeeklyPlanDescription: null,
                forwardedDailyDates: {},
                members,
            };
        });

        return sendSuccess(res, { teamId: team.id, teamName: team.name, weeks });
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};
export const forwardDailyToSupervisor = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user!.userId;
        const { week_number, work_date, notes } = req.body as { week_number?: number; work_date?: string; notes?: string };
        if (!week_number || !work_date) return sendError(res, 'week_number and work_date are required.', 400);

        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student not found.', 404);

        // Find the TL's weekly plan for this week (must exist — forwarded via forwardToSupervisor)
        const weeklyPlan = await prisma.weeklyPlan.findFirst({
            where: { studentId: student.id, week_number },
        });
        if (!weeklyPlan) return sendError(res, `No weekly plan found for Week ${week_number}. Forward the weekly plan first.`, 400);

        // Check if already submitted for this date
        const workDate = new Date(`${work_date}T12:00:00.000Z`);
        const existing = await prisma.weeklyPlanDaySubmission.findUnique({
            where: { weeklyPlanId_workDate: { weeklyPlanId: weeklyPlan.id, workDate } },
        });
        if (existing) {
            // Update notes if already exists
            const updated = await prisma.weeklyPlanDaySubmission.update({
                where: { id: existing.id },
                data: { notes: notes?.trim() || null },
            });
            return sendSuccess(res, updated, 'Daily plan updated.');
        }

        const created = await prisma.weeklyPlanDaySubmission.create({
            data: { weeklyPlanId: weeklyPlan.id, workDate, notes: notes?.trim() || null },
        });

        // Increment activity log for TL's attendance
        const { incrementActivityForUser } = await import('../services/activityLog.service');
        void incrementActivityForUser(userId);

        return sendSuccess(res, created, 'Daily plan forwarded to supervisor.', 201);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};
export const submitTeamWeeklyPlan     = notImplemented;
export const submitTeamDailyPlan      = notImplemented;
