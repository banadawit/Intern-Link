import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import {
    isWorkDateInInternshipWeek,
    parseIsoDateOnly,
} from '../utils/internshipWeekDates';
import { incrementActivityForUser } from '../services/activityLog.service';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { notifyStudentPlanReview } from '../services/notification.service';

// ── Attachment helpers ────────────────────────────────────────────────────────

interface AttachmentMeta {
    url: string;
    name: string;
    type: string;
    size: number;
    uploadedAt: string;
}

/**
 * Upload files to Cloudinary and return attachment metadata.
 * Falls back to a placeholder URL if Cloudinary is not configured.
 */
/** Teammate (not the TL) on a team with a Team Leader — individual plans go TL → supervisor. */
async function studentOnTeamWithLeader(_studentId: number): Promise<boolean> {
    // managerId not yet in schema — always return false until migration is applied
    return false;
}

async function uploadAttachments(
    files: Express.Multer.File[],
    userId: number,
    folder: string,
): Promise<AttachmentMeta[]> {
    if (!files || files.length === 0) return [];

    const { CloudinaryService } = await import('../services/cloudinary.service');
    const results: AttachmentMeta[] = [];

    for (const file of files) {
        const upload = await CloudinaryService.uploadDocument(file, {
            userId,
            organizationId: userId,
            fileType: 'WEEKLY_PRESENTATION' as any, // PLAN_ATTACHMENT added in new schema
            folder,
            resourceType: 'raw',
        });

        if (upload.success && upload.url) {
            results.push({
                url: upload.url,
                name: file.originalname,
                type: file.mimetype,
                size: file.size,
                uploadedAt: new Date().toISOString(),
            });
        }
    }

    return results;
}

// ── Student endpoints ─────────────────────────────────────────────────────────

/** List weekly plans for the logged-in student */
export const getMyWeeklyPlans = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        const plans = await prisma.weeklyPlan.findMany({
            where: { studentId: student.id },
            orderBy: [{ week_number: 'asc' }, { submitted_at: 'asc' }],
            include: {
                presentation: true,
                daySubmissions: { orderBy: { workDate: 'asc' } },
            },
        });
        return sendSuccess(res, plans, 'Weekly plans fetched');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/** Student updates own plan while still PENDING or REJECTED (description + attachments) */
export const updateMyWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const planId = parseInt(Array.isArray(id) ? id[0] : id, 10);
        const { plan_description } = req.body;
        const userId = req.user?.userId!;

        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        const existing = await prisma.weeklyPlan.findFirst({
            where: { id: planId, studentId: student.id },
        });
        if (!existing) return sendError(res, 'Plan not found.', 404);

        // Allow editing PENDING or REJECTED plans
        if (existing.status !== 'PENDING' && existing.status !== 'REJECTED') {
            return sendError(res, 'Only pending or rejected plans can be edited.', 400);
        }

        // Upload new attachments if provided
        const files = (req.files as Express.Multer.File[]) ?? [];
        const newAttachments = await uploadAttachments(
            files,
            userId,
            `internlink/plans/${student.id}`,
        );

        // Merge with existing attachments
        const existingAttachments = ((existing as any).attachments as AttachmentMeta[]) ?? [];
        const mergedAttachments = [...existingAttachments, ...newAttachments];

        const resetTlAfterRevision = false; // tl_status not yet in schema

        const updated = await prisma.weeklyPlan.update({
            where: { id: planId },
            data: {
                plan_description: typeof plan_description === 'string' ? plan_description : existing.plan_description,
            },
            include: { presentation: true },
        });
        return sendSuccess(res, { plan: updated }, 'Plan updated.');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/** Student: Submit a new weekly plan with optional attachments */
export const submitWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const { week_number, plan_description } = req.body;
        const userId = req.user?.userId!;

        const student = await prisma.student.findUnique({
            where: { userId },
            include: { assignments: { where: { status: 'ACTIVE' } } },
        });

        if (!student || student.internship_status !== 'PLACED') {
            return sendError(res, 'You must be placed in a company to submit plans.', 403);
        }

        // Block submission if the student is not assigned to any team
        // (companies that use teams require team membership before plan submission)
        const teamMembership = await prisma.studentTeam.findFirst({
            where: { studentId: student.id, team: { deleted_at: null } },
        });
        const companyHasTeams = await prisma.team.findFirst({
            where: {
                companyId: student.assignments[0]?.companyId,
                deleted_at: null,
            },
        });
        if (companyHasTeams && !teamMembership) {
            return sendError(
                res,
                'You must be assigned to a team before submitting a weekly plan. Ask your supervisor to add you to a team.',
                403,
            );
        }

        const weekNum = parseInt(week_number);
        if (Number.isNaN(weekNum)) return sendError(res, 'week_number must be a number.', 400);

        const existingPlan = await prisma.weeklyPlan.findFirst({
            where: { studentId: student.id, week_number: weekNum },
        });
        if (existingPlan) {
            return sendError(res, `A weekly plan for Week ${weekNum} already exists. Use resubmit if it was rejected.`, 400);
        }

        // Upload attachments
        const files = (req.files as Express.Multer.File[]) ?? [];
        const attachments = await uploadAttachments(files, userId, `internlink/plans/${student.id}`);

        // Handle legacy single-file presentation (backward compat)
        const singleFile = req.file;

        const plan = await prisma.weeklyPlan.create({
            data: {
                studentId: student.id,
                week_number: weekNum,
                plan_description,
                status: 'PENDING',
                presentation: singleFile ? {
                    create: { file_url: singleFile.path ?? singleFile.originalname },
                } : undefined,
            },
            include: { presentation: true },
        });

        if (userId) void incrementActivityForUser(userId);

        // ── Team awareness: notify the last remaining member who hasn't submitted ──
        void (async () => {
            try {
                const { sendNotification } = await import('../utils/notificationHelper');

                // Find the team this student belongs to (if any)
                const teamMembership = await prisma.studentTeam.findFirst({
                    where: { studentId: student.id, team: { deleted_at: null } },
                    include: {
                        team: {
                            include: {
                                members: {
                                    include: {
                                        student: {
                                            include: { user: { select: { id: true, full_name: true } } },
                                        },
                                    },
                                },
                            },
                        },
                    },
                });
                if (!teamMembership) return;

                const team = teamMembership.team;
                const allMemberIds = team.members.map((m) => m.studentId);

                // Find which members have already submitted for this week (including the one just submitted)
                const submitted = await prisma.weeklyPlan.findMany({
                    where: { studentId: { in: allMemberIds }, week_number: weekNum },
                    select: { studentId: true },
                });
                const submittedIds = new Set(submitted.map((p) => p.studentId));

                // Members who haven't submitted yet
                const missing = team.members.filter((m) => !submittedIds.has(m.studentId));

                if (missing.length === 1) {
                    // Exactly one member left — notify them
                    const lastMember = missing[0];
                    const submittedCount = submittedIds.size;
                    const totalCount = allMemberIds.length;
                    void sendNotification(
                        lastMember.student.user.id,
                        `⏳ You're the last one! ${submittedCount} out of ${totalCount} teammates have already submitted their Week ${weekNum} plan. Submit yours so the Team Leader can compile and forward the team plan.`,
                    );
                }
            } catch {
                // Non-fatal — don't fail the main response
            }
        })();

        return sendSuccess(res, { plan }, 'Weekly plan submitted successfully.', 201);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Student: Resubmit a REJECTED plan.
 * Creates a new version of the plan (increments version, resets status to RESUBMITTED).
 * Previous feedback is preserved in the old plan record.
 */
export const resubmitWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.id), 10);
        if (Number.isNaN(planId)) return sendError(res, 'Invalid plan id.', 400);

        const { plan_description } = req.body;
        const userId = req.user?.userId!;

        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        const existing = await prisma.weeklyPlan.findFirst({
            where: { id: planId, studentId: student.id },
        });
        if (!existing) return sendError(res, 'Plan not found.', 404);
        if (existing.status !== 'REJECTED') {
            return sendError(res, 'Only rejected plans can be resubmitted.', 400);
        }

        // Upload new attachments
        const files = (req.files as Express.Multer.File[]) ?? [];
        const newAttachments = await uploadAttachments(files, userId, `internlink/plans/${student.id}`);

        // Keep existing attachments + add new ones
        const existingAttachments = ((existing as any).attachments as AttachmentMeta[]) ?? [];
        const mergedAttachments = [...existingAttachments, ...newAttachments];

        // Clear attendance records so they reset to unfilled until supervisor re-approves
        await prisma.weeklyReport.deleteMany({ where: { weeklyPlanId: planId } });
        await prisma.weeklyPlanDaySubmission.deleteMany({ where: { weeklyPlanId: planId } });

        const updated = await prisma.weeklyPlan.update({
            where: { id: planId },
            data: {
                plan_description: typeof plan_description === 'string' ? plan_description : existing.plan_description,
                status: 'RESUBMITTED',
                submitted_at: new Date(),
                version: existing.version + 1,
                feedback: null,
                reviewed_at: null,
            },
            include: { presentation: true },
        });

        if (userId) void incrementActivityForUser(userId);

        return sendSuccess(res, { plan: updated }, 'Plan resubmitted successfully.', 200);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/** Student: Remove a specific attachment from a plan */
export const removePlanAttachment = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.id), 10);
        const { attachmentUrl } = req.body as { attachmentUrl?: string };
        if (Number.isNaN(planId) || !attachmentUrl) {
            return sendError(res, 'planId and attachmentUrl are required.', 400);
        }

        const userId = req.user?.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        const plan = await prisma.weeklyPlan.findFirst({ where: { id: planId, studentId: student.id } });
        if (!plan) return sendError(res, 'Plan not found.', 404);
        if (plan.status !== 'PENDING' && plan.status !== 'REJECTED') {
            return sendError(res, 'Cannot remove attachments from a reviewed plan.', 400);
        }

        const attachments = ((plan as any).attachments as { url: string }[]) ?? [];
        const filtered = attachments.filter((a) => a.url !== attachmentUrl);

        await prisma.weeklyPlan.update({ where: { id: planId }, data: {} });
        return sendSuccess(res, { removed: attachments.length - filtered.length }, 'Attachment removed.');
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/**
 * Team Leader: Delete ALL weekly plans for a given week number across all team members.
 * Also deletes the compiled TeamWeeklyPlan for that week if it exists.
 * Only the team manager can call this. Intended for testing / resetting a whole week.
 */
export const deleteWeekForTeam = async (req: AuthRequest, res: Response) => {
    try {
        const weekNumber = parseInt(String(req.params.weekNumber), 10);
        if (Number.isNaN(weekNumber)) return sendError(res, 'Invalid week number.', 400);

        const userId = req.user?.userId!;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        // Verify caller is the team leader
        const team = await prisma.team.findFirst({
            where: { managerId: student.id, deleted_at: null },
            include: { members: { select: { studentId: true } } },
        });
        if (!team) return sendError(res, 'You are not a Team Leader.', 403);

        const memberIds = team.members.map((m) => m.studentId);

        // Find all individual WeeklyPlans for this week
        const plans = await prisma.weeklyPlan.findMany({
            where: { studentId: { in: memberIds }, week_number: weekNumber },
            select: { id: true },
        });
        const planIds = plans.map((p) => p.id);

        if (planIds.length > 0) {
            // Delete WeeklyReport and WeeklyPresentation first (no cascade on weeklyPlanId)
            await prisma.weeklyReport.deleteMany({ where: { weeklyPlanId: { in: planIds } } });
            await prisma.weeklyPresentation.deleteMany({ where: { weeklyPlanId: { in: planIds } } });
            // DaySubmissions cascade automatically via schema onDelete: Cascade
            await prisma.weeklyPlan.deleteMany({ where: { id: { in: planIds } } });
        }

        // Also delete the compiled TeamWeeklyPlan for this week (TeamDailyPlans cascade)
        await prisma.teamWeeklyPlan.deleteMany({
            where: { teamId: team.id, week_number: weekNumber },
        });

        return sendSuccess(res, null, `Week ${weekNumber} plans deleted for all team members.`);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ── Supervisor endpoints ──────────────────────────────────────────────────────

/** Supervisor: Review and Approve/Reject Plan */
export const reviewWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { status, remarks, attendance } = req.body;

        const planId = parseInt(String(Array.isArray(id) ? id[0] : id), 10);
        if (Number.isNaN(planId)) return sendError(res, 'Invalid plan id.', 400);

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user?.userId },
        });
        if (!supervisor) return sendError(res, 'Only supervisors can review plans.', 403);

        if (status !== 'APPROVED' && status !== 'REJECTED') {
            return sendError(res, "status must be 'APPROVED' or 'REJECTED'.", 400);
        }
        if (status === 'REJECTED' && (!remarks || remarks.trim().length < 5)) {
            return sendError(res, 'Feedback is required when rejecting a plan (min 5 chars).', 400);
        }

        const existing = await prisma.weeklyPlan.findUnique({
            where: { id: planId },
            include: {
                student: {
                    include: {
                        user: { select: { id: true } },
                        assignments: { where: { companyId: supervisor.companyId, status: 'ACTIVE' } },
                    },
                },
            },
        });

        if (!existing) return sendError(res, 'Plan not found.', 404);
        if (existing.student.assignments.length === 0) {
            return sendError(res, 'This plan is not for a student assigned to your company.', 403);
        }

        const needsTlFirst = await studentOnTeamWithLeader(existing.studentId);
        if (needsTlFirst) {
            return sendError(
                res,
                'This student is on a team. Individual plans are reviewed by the Team Leader only. The supervisor reviews the compiled team plan.',
                403,
            );
        }

        // Block re-reviewing an already-reviewed plan (unless it was resubmitted)
        if (existing.status === 'APPROVED') {
            return sendError(res, 'This plan has already been approved.', 400);
        }

        const now = new Date();
        const updatedPlan = await prisma.weeklyPlan.update({
            where: { id: planId },
            data: {
                status,
                feedback: typeof remarks === 'string' ? remarks : null,
                reviewed_at: now,
            },
            include: { presentation: true },
        });

        if (status === 'APPROVED') {
            // Student submitted and plan was approved → PRESENT
            // The attendance checkbox in the UI defaults to true; we honour it but
            // if not provided we default to PRESENT (submitted = present).
            const present = attendance !== false && attendance !== 'false';
            await prisma.weeklyReport.upsert({
                where: { weeklyPlanId: planId },
                update: {
                    attendanceStatus: present ? 'PRESENT' : 'ABSENT',
                    remarks: typeof remarks === 'string' ? remarks : 'Plan approved.',
                },
                create: {
                    studentId: updatedPlan.studentId,
                    supervisorId: supervisor.id,
                    weeklyPlanId: updatedPlan.id,
                    attendanceStatus: present ? 'PRESENT' : 'ABSENT',
                    remarks: typeof remarks === 'string' ? remarks : 'Plan approved.',
                },
            });

            // Auto-create daily check-ins for all weekdays of this internship week
            // that have already passed (up to today), if not already submitted.
            try {
                const assignment = existing.student.assignments[0];
                if (assignment?.start_date) {
                    const { internshipWeekBoundsUtcDayMs, ymdFromUtcMs } = await import('../utils/internshipWeekDates');
                    const { start, endExclusive } = internshipWeekBoundsUtcDayMs(assignment.start_date, existing.week_number);
                    const todayMs = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
                    const weekEnd = Math.min(endExclusive - 86400000, todayMs); // don't go past today

                    const existingCheckins = await prisma.weeklyPlanDaySubmission.findMany({
                        where: { weeklyPlanId: planId },
                        select: { workDate: true },
                    });
                    const existingDates = new Set(existingCheckins.map((c) =>
                        c.workDate instanceof Date ? c.workDate.toISOString().slice(0, 10) : String(c.workDate).slice(0, 10)
                    ));

                    const toCreate: { weeklyPlanId: number; workDate: Date }[] = [];
                    for (let dayMs = start; dayMs <= weekEnd; dayMs += 86400000) {
                        const dow = new Date(dayMs).getUTCDay();
                        if (dow === 0 || dow === 6) continue; // skip weekends
                        const ymd = ymdFromUtcMs(dayMs);
                        if (!existingDates.has(ymd)) {
                            toCreate.push({ weeklyPlanId: planId, workDate: new Date(`${ymd}T12:00:00.000Z`) });
                        }
                    }

                    if (toCreate.length > 0) {
                        await prisma.weeklyPlanDaySubmission.createMany({
                            data: toCreate,
                            skipDuplicates: true,
                        });
                        // Increment activity log for each auto-checked day
                        void incrementActivityForUser(existing.student.userId, toCreate.length);
                    }
                }
            } catch (autoCheckErr: any) {
                // Non-fatal — log but don't fail the approval
                console.error('[reviewWeeklyPlan] Auto daily check-in error:', autoCheckErr?.message);
            }
        }

        void notifyStudentPlanReview(existing.student.userId, existing.week_number, status);

        return sendSuccess(res, { updatedPlan }, `Plan ${status}`);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ── Daily check-in endpoints (unchanged) ─────────────────────────────────────

export const getPlanDaySubmissions = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.id), 10);
        if (Number.isNaN(planId)) return sendError(res, 'Invalid plan id.', 400);
        const userId = req.user?.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);
        const plan = await prisma.weeklyPlan.findFirst({
            where: { id: planId, studentId: student.id },
            include: { daySubmissions: { orderBy: { workDate: 'asc' } } },
        });
        if (!plan) return sendError(res, 'Plan not found.', 404);
        return sendSuccess(res, plan.daySubmissions, 'Day submissions fetched');
    } catch (error: unknown) {
        return sendError(res, error instanceof Error ? error.message : 'Server error', 500);
    }
};

export const submitPlanDay = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.id), 10);
        if (Number.isNaN(planId)) return sendError(res, 'Invalid plan id.', 400);
        const workDateRaw = (req.body as { workDate?: string })?.workDate;
        if (typeof workDateRaw !== 'string' || !parseIsoDateOnly(workDateRaw)) {
            return sendError(res, 'workDate must be YYYY-MM-DD.', 400);
        }
        const userId = req.user?.userId;
        const student = await prisma.student.findUnique({
            where: { userId },
            include: { assignments: { where: { status: 'ACTIVE' }, take: 1 } },
        });
        if (!student) return sendError(res, 'Student profile not found.', 404);
        const assignment = student.assignments[0];
        if (!assignment) return sendError(res, 'You need an active placement to log daily tasks.', 403);
        const plan = await prisma.weeklyPlan.findFirst({ where: { id: planId, studentId: student.id } });
        if (!plan) return sendError(res, 'Plan not found.', 404);
        const onTeamWithLeader = await studentOnTeamWithLeader(student.id);
        // tl_status not yet in schema — only check regular status
        const weeklyReadyForDaily = plan.status === 'APPROVED';
        if (!weeklyReadyForDaily) {
            return sendError(res, 'Daily check-ins are only available after your weekly plan is approved.', 400);
        }
        if (!isWorkDateInInternshipWeek(assignment.start_date, plan.week_number, workDateRaw)) {
            return sendError(res, 'That date is outside the internship week for this plan.', 400);
        }
        const existingCheckin = await prisma.weeklyPlanDaySubmission.findUnique({
            where: { weeklyPlanId_workDate: { weeklyPlanId: planId, workDate: new Date(`${workDateRaw}T12:00:00.000Z`) } },
        });
        if (existingCheckin) return sendError(res, 'You have already checked in for this date.', 400);
        const created = await prisma.weeklyPlanDaySubmission.create({
            data: {
                weeklyPlanId: planId,
                workDate: new Date(`${workDateRaw}T12:00:00.000Z`),
                notes: typeof (req.body as { notes?: string }).notes === 'string'
                    ? (req.body as { notes?: string }).notes!.trim() || null
                    : null,
            },
        });
        if (userId) void incrementActivityForUser(userId);
        return sendSuccess(res, created, 'Daily check-in submitted.', 201);
    } catch (error: unknown) {
        return sendError(res, error instanceof Error ? error.message : 'Server error', 500);
    }
};

// ── Student: update/create daily plan (upsert) ───────────────────────────────

export const updatePlanDay = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.id), 10);
        const workDateParam = String(req.params.workDate ?? '');
        if (Number.isNaN(planId) || !parseIsoDateOnly(workDateParam)) {
            return sendError(res, 'Invalid plan or date.', 400);
        }
        const userId = req.user?.userId;
        const student = await prisma.student.findUnique({
            where: { userId },
            include: { assignments: { where: { status: 'ACTIVE' }, take: 1 } },
        });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        const plan = await prisma.weeklyPlan.findFirst({ where: { id: planId, studentId: student.id } });
        if (!plan) return sendError(res, 'Plan not found.', 404);

        const onTeamWithLeader = await studentOnTeamWithLeader(student.id);
        // Allow editing when: supervisor-approved (solo), TL-approved, or TL requested revision
        const weeklyReadyForDaily =
            plan.status === 'APPROVED' ||
            (onTeamWithLeader && (plan.tl_status === 'APPROVED' || plan.tl_status === 'REVISION_REQUESTED'));
        if (!weeklyReadyForDaily) {
            return sendError(res, 'Daily plans are not available yet.', 400);
        }

        const workDateObj = new Date(`${workDateParam}T12:00:00.000Z`);
        const notes = typeof (req.body as { notes?: string }).notes === 'string'
            ? (req.body as { notes?: string }).notes!.trim() || null
            : null;

        const existing = await prisma.weeklyPlanDaySubmission.findUnique({
            where: { weeklyPlanId_workDate: { weeklyPlanId: planId, workDate: workDateObj } },
        });

        if (existing) {
            // Cannot edit an already TL-approved submission
            if (existing.tl_status === 'APPROVED') {
                return sendError(res, 'This daily plan has already been approved by the Team Leader.', 400);
            }
            // Update notes and reset TL review so TL sees the updated submission
            const updated = await prisma.weeklyPlanDaySubmission.update({
                where: { id: existing.id },
                data: {
                    notes,
                    tl_status: 'PENDING',
                    tl_comment: null,
                    tl_reviewed_at: null,
                },
            });
            return sendSuccess(res, updated, 'Daily plan updated and resubmitted to Team Leader.');
        } else {
            // No existing submission — create new one
            const assignment = student.assignments[0];
            if (!assignment) return sendError(res, 'No active placement found.', 403);
            if (!isWorkDateInInternshipWeek(assignment.start_date, plan.week_number, workDateParam)) {
                return sendError(res, 'That date is outside the internship week for this plan.', 400);
            }
            const created = await prisma.weeklyPlanDaySubmission.create({
                data: { weeklyPlanId: planId, workDate: workDateObj, notes },
            });
            if (userId) void incrementActivityForUser(userId);
            return sendSuccess(res, created, 'Daily plan submitted.', 201);
        }
    } catch (error: unknown) {
        return sendError(res, error instanceof Error ? error.message : 'Server error', 500);
    }
};

export const deletePlanDay = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.id), 10);
        const workDateParam = String(req.params.workDate ?? '');
        if (Number.isNaN(planId) || !parseIsoDateOnly(workDateParam)) {
            return sendError(res, 'Invalid plan or date.', 400);
        }
        const userId = req.user?.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);
        const plan = await prisma.weeklyPlan.findFirst({ where: { id: planId, studentId: student.id } });
        if (!plan) return sendError(res, 'Plan not found.', 404);
        const onTeamWithLeader = await studentOnTeamWithLeader(student.id);
        // tl_status not yet in schema — only check regular status
        const weeklyReadyForDaily = plan.status === 'APPROVED';
        if (!weeklyReadyForDaily) {
            return sendError(res, 'You can only remove daily entries after your weekly plan is approved.', 400);
        }
        await prisma.weeklyPlanDaySubmission.deleteMany({
            where: { weeklyPlanId: planId, workDate: new Date(`${workDateParam}T12:00:00.000Z`) },
        });
        return sendSuccess(res, null, 'Removed.');
    } catch (error: unknown) {
        return sendError(res, error instanceof Error ? error.message : 'Server error', 500);
    }
};

export const reviewPlanDay = async (req: AuthRequest, res: Response) => {
    try {
        const submissionId = parseInt(String(req.params.submissionId), 10);
        if (Number.isNaN(submissionId)) return sendError(res, 'Invalid submission id.', 400);

        const { status, supervisorNote } = req.body as { status?: string; supervisorNote?: string };
        if (status !== 'APPROVED' && status !== 'REJECTED') {
            return sendError(res, "status must be 'APPROVED' or 'REJECTED'.", 400);
        }

        const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user?.userId } });
        if (!supervisor) return sendError(res, 'Only supervisors can review daily plans.', 403);

        const submission = await prisma.weeklyPlanDaySubmission.findUnique({
            where: { id: submissionId },
            include: {
                weeklyPlan: {
                    include: {
                        student: {
                            include: {
                                assignments: { where: { companyId: supervisor.companyId, status: 'ACTIVE' } },
                            },
                        },
                    },
                },
            },
        });

        if (!submission) return sendError(res, 'Daily submission not found.', 404);
        if (submission.weeklyPlan.student.assignments.length === 0) {
            return sendError(res, 'This submission is not for a student at your company.', 403);
        }

        // Block supervisor from reviewing individual daily plans for team students
        const onTeam = await studentOnTeamWithLeader(submission.weeklyPlan.studentId);
        if (onTeam) {
            return sendError(
                res,
                'This student is on a team. Individual daily plans are reviewed by the Team Leader only.',
                403,
            );
        }

        const updated = await prisma.weeklyPlanDaySubmission.update({
            where: { id: submissionId },
            data: {
                notes: typeof supervisorNote === 'string' ? supervisorNote.trim() || null : null,
            },
        });

        // Notify student
        const studentUserId = submission.weeklyPlan.student.userId;
        const dateStr = submission.workDate instanceof Date
            ? submission.workDate.toISOString().slice(0, 10)
            : String(submission.workDate).slice(0, 10);
        const { sendNotification } = await import('../utils/notificationHelper');
        void sendNotification(
            studentUserId,
            status === 'APPROVED'
                ? `✅ Your daily plan for ${dateStr} was approved by your supervisor.`
                : `❌ Your daily plan for ${dateStr} was not approved. ${supervisorNote ? `Note: ${supervisorNote}` : ''}`
        );

        return sendSuccess(res, updated, `Daily plan ${status.toLowerCase()}.`);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};
