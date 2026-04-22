import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import {
    isWorkDateInInternshipWeek,
    parseIsoDateOnly,
} from '../utils/internshipWeekDates';
import { incrementActivityForUser } from '../services/activityLog.service';
import { sendSuccess, sendError } from '../utils/responseHelper';

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
        return sendSuccess(res, 'Weekly plans fetched', plans);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/** Student updates own plan while still PENDING (description only; new file via new submission if needed) */
export const updateMyWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const planId = parseInt(Array.isArray(id) ? id[0] : id, 10);
        const { plan_description } = req.body;
        const userId = req.user?.userId;

        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        const existing = await prisma.weeklyPlan.findFirst({
            where: { id: planId, studentId: student.id },
        });
        if (!existing) return sendError(res, 'Plan not found.', 404);
        if (existing.status !== 'PENDING') {
            return sendError(res, 'Only pending plans can be edited.', 400);
        }

        const updated = await prisma.weeklyPlan.update({
            where: { id: planId },
            data: {
                plan_description: typeof plan_description === 'string' ? plan_description : existing.plan_description,
            },
            include: { presentation: true },
        });
        return sendSuccess(res, 'Plan updated.', { plan: updated });
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// 1. STUDENT: Submit Weekly Plan & Presentation (FR-5.3 & FR-5.5)
export const submitWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const { week_number, plan_description } = req.body;
        const userId = req.user?.userId;

        // 1. Verify Student is PLACED
        const student = await prisma.student.findUnique({
            where: { userId },
            include: { assignments: { where: { status: 'ACTIVE' } } }
        });

        if (!student || student.internship_status !== 'PLACED') {
            return sendError(res, "You must be placed in a company to submit plans.", 403);
        }

        // 2. Create the Weekly Plan and Link Presentation File if uploaded
        const plan = await prisma.weeklyPlan.create({
            data: {
                studentId: student.id,
                week_number: parseInt(week_number),
                plan_description,
                status: 'PENDING',
                presentation: req.file ? {
                    create: {
                        file_url: req.file.path
                    }
                } : undefined
            },
            include: { presentation: true }
        });

        if (userId) {
            void incrementActivityForUser(userId);
        }

        return sendSuccess(res, "Weekly plan submitted successfully.", { plan }, 201);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// 2. SUPERVISOR: Review and Approve/Reject Plan (FR-6.3 & BR-004)
export const reviewWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params; // Plan ID
        const { status, remarks, attendance } = req.body; // status: 'APPROVED' or 'REJECTED'

        const planId = Array.isArray(id) ? id[0] : id;
        const parsedId = parseInt(String(planId), 10);
        if (Number.isNaN(parsedId)) {
            return sendError(res, 'Invalid plan id.', 400);
        }

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user?.userId },
        });

        if (!supervisor) return sendError(res, 'Only supervisors can review plans.', 403);

        if (status !== 'APPROVED' && status !== 'REJECTED') {
            return sendError(res, "status must be 'APPROVED' or 'REJECTED'.", 400);
        }

        const existing = await prisma.weeklyPlan.findUnique({
            where: { id: parsedId },
            include: {
                student: {
                    include: {
                        assignments: {
                            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
                        },
                    },
                },
            },
        });

        if (!existing) {
            return sendError(res, 'Plan not found.', 404);
        }
        if (existing.student.assignments.length === 0) {
            return sendError(res, 'This weekly plan is not for a student currently assigned to your company.', 403);
        }

        const now = new Date();
        const updatedPlan = await prisma.weeklyPlan.update({
            where: { id: parsedId },
            data: {
                status,
                feedback: typeof req.body?.remarks === 'string' ? req.body.remarks : null,
                reviewed_at: now,
            },
        });

        // If approved, also log the Weekly Report/Attendance (FR-6.5)
        if (status === 'APPROVED') {
            const present = attendance === 'true' || attendance === true;
            await prisma.weeklyReport.create({
                data: {
                    studentId: updatedPlan.studentId,
                    supervisorId: supervisor.id,
                    weeklyPlanId: updatedPlan.id,
                    attendanceStatus: present ? 'PRESENT' : 'ABSENT',
                    remarks: typeof remarks === 'string' ? remarks : 'Plan approved.',
                },
            });
        }

        return sendSuccess(res, `Plan ${status}`, { updatedPlan });
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

/** Student: list daily check-ins for a plan (same data as embedded in my-plans). */
export const getPlanDaySubmissions = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.id), 10);
        if (Number.isNaN(planId)) {
            return sendError(res, 'Invalid plan id.', 400);
        }
        const userId = req.user?.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        const plan = await prisma.weeklyPlan.findFirst({
            where: { id: planId, studentId: student.id },
            include: { daySubmissions: { orderBy: { workDate: 'asc' } } },
        });
        if (!plan) return sendError(res, 'Plan not found.', 404);
        return sendSuccess(res, 'Day submissions fetched', plan.daySubmissions);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

/** Student: log a daily check-in for an approved plan (date must fall in that internship week). */
export const submitPlanDay = async (req: AuthRequest, res: Response) => {
    try {
        const planId = parseInt(String(req.params.id), 10);
        if (Number.isNaN(planId)) {
            return sendError(res, 'Invalid plan id.', 400);
        }
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
        if (!assignment) {
            return sendError(res, 'You need an active placement to log daily tasks.', 403);
        }

        const plan = await prisma.weeklyPlan.findFirst({
            where: { id: planId, studentId: student.id },
        });
        if (!plan) return sendError(res, 'Plan not found.', 404);
        if (plan.status !== 'APPROVED') {
            return sendError(res, 'Daily check-ins are only available after your weekly plan is approved.', 400);
        }
        if (!isWorkDateInInternshipWeek(assignment.start_date, plan.week_number, workDateRaw)) {
            return sendError(res, 'That date is outside the internship week for this plan.', 400);
        }

        const created = await prisma.weeklyPlanDaySubmission.upsert({
            where: {
                weeklyPlanId_workDate: {
                    weeklyPlanId: planId,
                    workDate: new Date(`${workDateRaw}T12:00:00.000Z`),
                },
            },
            create: {
                weeklyPlanId: planId,
                workDate: new Date(`${workDateRaw}T12:00:00.000Z`),
            },
            update: {},
        });

        if (userId) {
            void incrementActivityForUser(userId);
        }

        return sendSuccess(res, 'Daily check-in submitted.', created, 201);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

/** Student: remove a daily check-in */
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

        const plan = await prisma.weeklyPlan.findFirst({
            where: { id: planId, studentId: student.id },
        });
        if (!plan) return sendError(res, 'Plan not found.', 404);

        await prisma.weeklyPlanDaySubmission.deleteMany({
            where: {
                weeklyPlanId: planId,
                workDate: new Date(`${workDateParam}T12:00:00.000Z`),
            },
        });

        return sendSuccess(res, 'Removed.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};