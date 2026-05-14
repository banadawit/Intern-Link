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

        const membersData = team.members
            .filter((m) => m.studentId !== team.managerId)
            .map((m) => ({
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
                tl_status: p.tl_status,
                tl_comment: p.tl_comment,
                dailySubmissions: p.daySubmissions.map((d) => ({
                    id: d.id,
                    workDate: d.workDate instanceof Date ? d.workDate.toISOString().slice(0, 10) : String(d.workDate).slice(0, 10),
                    notes: d.notes,
                    status: d.status,
                    tl_status: d.tl_status,
                    tl_comment: d.tl_comment,
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
                // Exclude TL_PENDING — those are still being reviewed by the Team Leader
                status: { not: 'TL_PENDING' },
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
            // Record attendance for ALL team members:
            // - Submitted their individual weekly plan → PRESENT (WeeklyReport + activity + day check-in)
            // - Did NOT submit → ABSENT (WeeklyReport with ABSENT, no activity, no heatmap entry)
            const activityDate = new Date(plan.submitted_at);
            const ymd = activityDate.toISOString().slice(0, 10);

            for (const m of plan.team.members) {
                const s = m.student;
                const individualPlan = await prisma.weeklyPlan.findFirst({
                    where: { studentId: s.id, week_number: plan.week_number },
                });

                if (individualPlan) {
                    // ── PRESENT: student submitted ──────────────────────────────
                    // Create/update WeeklyReport as PRESENT
                    await prisma.weeklyReport.upsert({
                        where: { weeklyPlanId: individualPlan.id },
                        update: {
                            attendanceStatus: 'PRESENT',
                            remarks: `Team plan approved (Week ${plan.week_number}).`,
                        },
                        create: {
                            studentId: s.id,
                            supervisorId: sup.id,
                            weeklyPlanId: individualPlan.id,
                            attendanceStatus: 'PRESENT',
                            remarks: `Team plan approved (Week ${plan.week_number}).`,
                        },
                    });
                    // Mark a day check-in on the plan submission date — status APPROVED so it shows in heatmap
                    await prisma.weeklyPlanDaySubmission.upsert({
                        where: { weeklyPlanId_workDate: { weeklyPlanId: individualPlan.id, workDate: new Date(`${ymd}T12:00:00.000Z`) } },
                        create: {
                            weeklyPlanId: individualPlan.id,
                            workDate: new Date(`${ymd}T12:00:00.000Z`),
                            notes: `Auto-recorded: team plan approved (Week ${plan.week_number})`,
                            status: 'APPROVED',
                            tl_status: 'APPROVED',
                        },
                        update: { status: 'APPROVED', tl_status: 'APPROVED' },
                    });
                    void incrementActivityForUser(s.user.id);
                } else {
                    // ── ABSENT: student did not submit ──────────────────────────
                    // We can't link to a weeklyPlanId (none exists), so create a WeeklyReport
                    // without a plan link — just mark ABSENT for this week.
                    // Check if a report already exists for this student+week via a plan
                    // (no plan means no weeklyPlanId, so we skip WeeklyReport here —
                    //  the absence is implicit: no heatmap entry, no activity increment)
                }

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

            // Record attendance for ALL team members:
            // - Submitted a daily plan for this date → mark their WeeklyPlanDaySubmission APPROVED + activity
            // - Did NOT submit → no entry, no activity (absent in heatmap)
            for (const m of daily.teamWeeklyPlan.team.members) {
                const s = m.student;
                const individualPlan = await prisma.weeklyPlan.findFirst({
                    where: { studentId: s.id, week_number: daily.teamWeeklyPlan.week_number },
                });
                if (individualPlan) {
                    const memberDailySubmission = await prisma.weeklyPlanDaySubmission.findUnique({
                        where: { weeklyPlanId_workDate: { weeklyPlanId: individualPlan.id, workDate: new Date(`${workDateStr}T12:00:00.000Z`) } },
                    });
                    if (memberDailySubmission) {
                        // Member submitted → mark APPROVED + record activity (present in heatmap)
                        await prisma.weeklyPlanDaySubmission.update({
                            where: { id: memberDailySubmission.id },
                            data: { status: 'APPROVED' },
                        });
                        void incrementActivityForUser(s.user.id);
                    }
                    // No daily submission → absent → no heatmap entry, no activity
                }
                void sendNotification(s.user.id, `✅ Your team's daily plan for ${workDateStr} was approved.`);
            }
        }

        return sendSuccess(res, updated, `Team daily plan ${status.toLowerCase()}.`);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Team Leader: review a member's weekly plan ────────────────────────────────
export const tlReviewWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const planId = parseInt(String(req.params.planId), 10);
        const { status, comment } = req.body as { status?: string; comment?: string };

        if (status !== 'APPROVED' && status !== 'REVISION_REQUESTED') {
            return sendError(res, "status must be 'APPROVED' or 'REVISION_REQUESTED'.", 400);
        }

        // Verify student is TL of the plan owner's team
        const plan = await prisma.weeklyPlan.findUnique({
            where: { id: planId },
            include: { student: { include: { user: { select: { id: true, full_name: true } } } } },
        });
        if (!plan) return sendError(res, 'Plan not found.', 404);

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
        if (!team.members.some((m) => m.studentId === plan.studentId)) {
            return sendError(res, 'This plan is not from a member of your team.', 403);
        }

        const updated = await prisma.weeklyPlan.update({
            where: { id: planId },
            data: {
                tl_status: status,
                tl_comment: typeof comment === 'string' ? comment.trim() || null : null,
                tl_reviewed_at: new Date(),
            },
        });

        // Notify the member
        const msg = status === 'APPROVED'
            ? `✅ Your Week ${plan.week_number} plan was approved by the Team Leader.`
            : `🔄 Your Week ${plan.week_number} plan needs revision. ${comment ? `Comment: ${comment}` : ''} Please resubmit.`;
        void sendNotification(plan.student.user.id, msg);

        // If approved — check if ALL team members' plans for this week are TL-approved
        // If yes, auto-compile and submit the team plan to the supervisor
        if (status === 'APPROVED') {
            const weekNum = plan.week_number;
            const peerMemberIds = team.members
                .map((m) => m.studentId)
                .filter((sid) => sid !== team.managerId);

            if (peerMemberIds.length > 0) {
            const memberPlans = await prisma.weeklyPlan.findMany({
                where: { studentId: { in: peerMemberIds }, week_number: weekNum },
                include: { student: { include: { user: { select: { full_name: true } } } } },
            });

            const allApproved = peerMemberIds.every((sid) => {
                const mp = memberPlans.find((p) => p.studentId === sid);
                return mp && (mp.tl_status === 'APPROVED' || mp.id === planId);
            });

            if (allApproved && memberPlans.length === peerMemberIds.length) {
                // Compile all plans into team plan description
                const compiledText = memberPlans
                    .map((p) => `**${p.student.user.full_name}:**\n${p.plan_description}`)
                    .join('\n\n');

                // Upsert team plan — set status to TL_PENDING so TL reviews before supervisor sees it
                const existingTeamPlan = await prisma.teamWeeklyPlan.findUnique({
                    where: { teamId_week_number: { teamId: team.id, week_number: weekNum } },
                });

                if (existingTeamPlan) {
                    await prisma.teamWeeklyPlan.update({
                        where: { id: existingTeamPlan.id },
                        data: {
                            plan_description: compiledText,
                            status: 'TL_PENDING',
                            tl_status: 'PENDING',
                            tl_comment: null,
                            tl_reviewed_at: null,
                            feedback: null,
                            reviewed_at: null,
                            version: existingTeamPlan.version + 1,
                            submitted_at: new Date(),
                        },
                    });
                } else {
                    await prisma.teamWeeklyPlan.create({
                        data: {
                            teamId: team.id,
                            projectId: team.projectId ?? undefined,
                            submittedById: student.id,
                            week_number: weekNum,
                            plan_description: compiledText,
                            status: 'TL_PENDING',
                            tl_status: 'PENDING',
                        },
                    });
                }

                void incrementActivityForUser(req.user!.userId);

                // Notify TL that the compiled plan is ready for their final review
                void sendNotification(req.user!.userId,
                    `📋 All Week ${weekNum} member plans approved! Review the compiled team plan in your Team Plans tab before forwarding to the supervisor.`
                );
            }
            }
        }

        return sendSuccess(res, updated, `Weekly plan ${status === 'APPROVED' ? 'approved' : 'revision requested'}.`);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Team Leader: review a member's daily plan ─────────────────────────────────
export const tlReviewDailyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const submissionId = parseInt(String(req.params.submissionId), 10);
        const { status, comment } = req.body as { status?: string; comment?: string };

        if (status !== 'APPROVED' && status !== 'REVISION_REQUESTED') {
            return sendError(res, "status must be 'APPROVED' or 'REVISION_REQUESTED'.", 400);
        }

        const submission = await prisma.weeklyPlanDaySubmission.findUnique({
            where: { id: submissionId },
            include: {
                weeklyPlan: {
                    include: { student: { include: { user: { select: { id: true } } } } },
                },
            },
        });
        if (!submission) return sendError(res, 'Daily submission not found.', 404);

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
        if (!team.members.some((m) => m.studentId === submission.weeklyPlan.studentId)) {
            return sendError(res, 'This submission is not from a member of your team.', 403);
        }

        const updated = await prisma.weeklyPlanDaySubmission.update({
            where: { id: submissionId },
            data: {
                tl_status: status,
                tl_comment: typeof comment === 'string' ? comment.trim() || null : null,
                tl_reviewed_at: new Date(),
            },
        });

        const dateStr = submission.workDate instanceof Date
            ? submission.workDate.toISOString().slice(0, 10)
            : String(submission.workDate).slice(0, 10);
        const msg = status === 'APPROVED'
            ? `✅ Your daily plan for ${dateStr} was approved by the Team Leader.`
            : `🔄 Your daily plan for ${dateStr} needs revision. ${comment ? `Comment: ${comment}` : ''} Please resubmit.`;
        void sendNotification(submission.weeklyPlan.student.user.id, msg);

        // If approved — check if ALL teammates' daily submissions for this date are TL-approved
        if (status === 'APPROVED') {
            const peerMemberIds = team.members
                .map((m) => m.studentId)
                .filter((sid) => sid !== team.managerId);
            const weekNum = submission.weeklyPlan.week_number;

            // Find the team weekly plan for this week
            const teamWeeklyPlan = await prisma.teamWeeklyPlan.findUnique({
                where: { teamId_week_number: { teamId: team.id, week_number: weekNum } },
            });

            if (teamWeeklyPlan && peerMemberIds.length > 0) {
                // Get all teammates' daily submissions for this date
                const memberDailyPlans = await prisma.weeklyPlanDaySubmission.findMany({
                    where: {
                        workDate: submission.workDate,
                        weeklyPlan: { studentId: { in: peerMemberIds }, week_number: weekNum },
                    },
                    include: { weeklyPlan: { select: { studentId: true } } },
                });

                const allDailyApproved = peerMemberIds.every((sid) => {
                    const dp = memberDailyPlans.find((d) => d.weeklyPlan.studentId === sid);
                    return dp && (dp.tl_status === 'APPROVED' || dp.id === submissionId);
                });

                if (allDailyApproved && memberDailyPlans.length === peerMemberIds.length) {
                    // Compile notes
                    const compiledNotes = memberDailyPlans
                        .map((d) => d.notes?.trim())
                        .filter(Boolean)
                        .join('\n');

                    // Upsert team daily plan
                    const existingTeamDaily = await prisma.teamDailyPlan.findUnique({
                        where: { teamWeeklyPlanId_workDate: { teamWeeklyPlanId: teamWeeklyPlan.id, workDate: submission.workDate } },
                    });

                    if (existingTeamDaily) {
                        await prisma.teamDailyPlan.update({
                            where: { id: existingTeamDaily.id },
                            data: { notes: compiledNotes || null, status: 'PENDING', supervisorNote: null, reviewedAt: null },
                        });
                    } else {
                        await prisma.teamDailyPlan.create({
                            data: {
                                teamWeeklyPlanId: teamWeeklyPlan.id,
                                submittedById: student.id,
                                workDate: submission.workDate,
                                notes: compiledNotes || null,
                                status: 'PENDING',
                            },
                        });
                    }

                    // Notify team
                    for (const m of team.members) {
                        void sendNotification(m.student.user.id,
                            `📤 All daily plans for ${dateStr} approved! Auto-submitted to supervisor.`
                        );
                    }
                }
            }
        }

        return sendSuccess(res, updated, `Daily plan ${status === 'APPROVED' ? 'approved' : 'revision requested'}.`);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Team Leader: forward compiled plan to supervisor ──────────────────────────
// Compiles all TL-approved member plans for a given week into a team plan draft
export const forwardToSupervisor = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const { week_number, plan_description, title } = req.body as { week_number?: number; plan_description?: string; title?: string };

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

        // Check if team plan already exists for this week
        const existing = await prisma.teamWeeklyPlan.findUnique({
            where: { teamId_week_number: { teamId: team.id, week_number } },
        });
        if (existing) {
            // Update existing plan — forward directly to supervisor
            const updated = await prisma.teamWeeklyPlan.update({
                where: { id: existing.id },
                data: {
                    title: typeof title === 'string' ? title.trim() || null : existing.title,
                    plan_description: plan_description.trim(),
                    status: 'PENDING',
                    tl_status: 'APPROVED',
                    tl_comment: null,
                    tl_reviewed_at: new Date(),
                    feedback: null,
                    reviewed_at: null,
                    version: existing.version + 1,
                    submitted_at: new Date(),
                },
            });
            void incrementActivityForUser(req.user!.userId);
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
                tl_status: 'APPROVED',
                tl_reviewed_at: new Date(),
            },
        });

        void incrementActivityForUser(req.user!.userId);

        // Notify all team members
        for (const m of team.members) {
            if (m.student.user.id !== req.user!.userId) {
                void sendNotification(m.student.user.id, `📤 Your Team Leader has forwarded the Week ${week_number} team plan to the supervisor.`);
            }
        }

        return sendSuccess(res, plan, 'Team plan forwarded to supervisor.', 201);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Team Leader: approve or request resubmission of the compiled team plan ────
export const tlReviewTeamPlan = async (req: AuthRequest, res: Response) => {
    try {
        const student = await getStudentOrFail(req.user!.userId);
        const planId = parseInt(String(req.params.planId), 10);
        const { status, comment } = req.body as { status?: string; comment?: string };

        if (status !== 'APPROVED' && status !== 'REVISION_REQUESTED') {
            return sendError(res, "status must be 'APPROVED' or 'REVISION_REQUESTED'.", 400);
        }

        // Verify TL owns this team plan
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
            // TL approves → forward to supervisor (status becomes PENDING)
            await prisma.teamWeeklyPlan.update({
                where: { id: planId },
                data: {
                    tl_status: 'APPROVED',
                    tl_comment: trimmedComment,
                    tl_reviewed_at: new Date(),
                    status: 'PENDING',
                },
            });

            // Notify all team members
            for (const m of teamPlan.team.members) {
                void sendNotification(m.student.user.id,
                    `📤 Team Leader approved the Week ${teamPlan.week_number} team plan. It has been forwarded to the supervisor.`
                );
            }

            return sendSuccess(res, null, `Week ${teamPlan.week_number} team plan forwarded to supervisor.`);
        } else {
            // TL requests resubmission → reset to TL_PENDING, notify members to revise
            await prisma.teamWeeklyPlan.update({
                where: { id: planId },
                data: {
                    tl_status: 'REVISION_REQUESTED',
                    tl_comment: trimmedComment,
                    tl_reviewed_at: new Date(),
                    status: 'TL_PENDING',
                },
            });

            // Reset all member plans' tl_status so they resubmit
            const memberIds = teamPlan.team.members.map((m) => m.studentId);
            await prisma.weeklyPlan.updateMany({
                where: { studentId: { in: memberIds }, week_number: teamPlan.week_number },
                data: { tl_status: 'REVISION_REQUESTED', tl_comment: trimmedComment },
            });

            // Notify all members
            for (const m of teamPlan.team.members) {
                void sendNotification(m.student.user.id,
                    `🔄 Team Leader requested revision for the Week ${teamPlan.week_number} team plan. ${trimmedComment ? `Comment: ${trimmedComment}` : ''} Please revise and resubmit.`
                );
            }

            return sendSuccess(res, null, 'Revision requested. Members have been notified.');
        }
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Team Leader: get all team members' daily submissions (for Collect Daily Plans) ──
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
                                    include: {
                                        daySubmissions: { orderBy: { workDate: 'asc' } },
                                    },
                                },
                            },
                        },
                    },
                },
                weeklyPlans: {
                    where: { status: 'APPROVED' },
                    orderBy: { week_number: 'asc' },
                    include: {
                        dailyPlans: {
                            select: {
                                workDate: true,
                                status: true,
                            },
                        },
                    },
                },
            },
        });

        if (!team) return sendError(res, 'You are not a Team Leader of any team.', 403);

        const peerMembers = team.members.filter((m) => m.studentId !== team.managerId);

        // Group daily submissions by week number
        const weekNumbers = [...new Set(
            peerMembers.flatMap((m) => m.student.weeklyPlans.map((p) => p.week_number))
        )].sort((a, b) => a - b);

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
                        workDate: d.workDate instanceof Date ? d.workDate.toISOString().slice(0, 10) : String(d.workDate).slice(0, 10),
                        notes: d.notes,
                        tl_status: d.tl_status,
                        tl_comment: d.tl_comment,
                    })),
                };
            });

            // Build a map of date → supervisor status for forwarded team daily plans
            const forwardedDailyDates: Record<string, string> = {};
            if (approvedTeamPlan) {
                for (const dp of (approvedTeamPlan as any).dailyPlans ?? []) {
                    const ymd = dp.workDate instanceof Date
                        ? dp.workDate.toISOString().slice(0, 10)
                        : String(dp.workDate).slice(0, 10);
                    forwardedDailyDates[ymd] = dp.status; // PENDING | APPROVED | REJECTED
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

        return sendSuccess(res, {
            teamId: team.id,
            teamName: team.name,
            weeks: weeklyData,
        });
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Team Leader: forward compiled daily plans to supervisor ───────────────────
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

        // Collect only the members who actually submitted AND were TL-approved for this date.
        // Members who didn't submit are simply absent — no gate, TL can always forward.
        const memberDailyPlans = await prisma.weeklyPlanDaySubmission.findMany({
            where: {
                workDate: new Date(`${work_date}T12:00:00.000Z`),
                weeklyPlan: { studentId: { in: peerMemberIds }, week_number },
                tl_status: 'APPROVED',
            },
            include: { weeklyPlan: { select: { studentId: true } } },
        });

        // Compile notes only from members who submitted
        const compiledNotes = notes?.trim() || memberDailyPlans
            .map((d) => d.notes?.trim())
            .filter(Boolean)
            .join('\n') || null;

        const workDateObj = new Date(`${work_date}T12:00:00.000Z`);

        // Upsert team daily plan
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

        void incrementActivityForUser(req.user!.userId);

        // Notify all team members
        for (const m of team.members) {
            if (m.student.user.id !== req.user!.userId) {
                void sendNotification(m.student.user.id,
                    `📤 Team Leader forwarded the daily plan for ${work_date} (Week ${week_number}) to the supervisor.`
                );
            }
        }

        return sendSuccess(res, daily, `Daily plan for ${work_date} forwarded to supervisor.`, 201);
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};

// ── Team Leader: get compiled draft from approved member plans ────────────────
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

        // Compile approved plans into a draft (teammates only — TL uses Weekly Plans separately)
        const approvedPlans = peerMembers
            .filter((m) => m.student.weeklyPlans.length > 0)
            .map((m) => ({
                memberName: m.student.user.full_name,
                plan: m.student.weeklyPlans[0].plan_description,
                approvedDailyDates: m.student.weeklyPlans[0].daySubmissions.map((d) =>
                    d.workDate instanceof Date ? d.workDate.toISOString().slice(0, 10) : String(d.workDate).slice(0, 10)
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
    } catch (e: any) {
        return sendError(res, e.message, e.status ?? 500);
    }
};
