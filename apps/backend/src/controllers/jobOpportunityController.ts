import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { Role } from '@prisma/client';

// ─── helpers ────────────────────────────────────────────────────────────────

const oppInclude = (studentId?: number) => ({
    post: {
        select: {
            id: true, title: true, content: true, createdAt: true,
            author: { select: { id: true, full_name: true, role: true } },
        },
    },
    questions: { select: { id: true, question: true, required: true, order: true } },
    applications: { select: { id: true, studentId: true, status: true, appliedAt: true } },
});

function formatOpp(opp: any, studentId?: number) {
    const { applications, ...rest } = opp;
    const myApp = studentId
        ? applications.find((a: any) => a.studentId === studentId) ?? null
        : null;
    return {
        ...rest,
        applicationCount: applications.length,
        hasApplied: !!myApp,
        myApplication: myApp ? { id: myApp.id, status: myApp.status, appliedAt: myApp.appliedAt } : null,
    };
}

// ─── SUPERVISOR: list own opportunities ─────────────────────────────────────

export const myOpportunities = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
        if (!supervisor) return sendError(res, 'Supervisor profile not found.', 403);

        const opps = await prisma.jobOpportunity.findMany({
            where: { post: { authorId: req.user!.userId } },
            include: oppInclude(),
            orderBy: { post: { createdAt: 'desc' } },
        });

        return sendSuccess(res, opps.map((o) => formatOpp(o)));
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── ALL: browse opportunities ───────────────────────────────────────────────

export const listOpportunities = async (req: AuthRequest, res: Response) => {
    try {
        const { status, limit = '50', offset = '0' } = req.query as Record<string, string>;

        const where: any = {};
        if (status && status !== 'ALL') where.status = status;

        const [opps, total] = await Promise.all([
            prisma.jobOpportunity.findMany({
                where,
                include: oppInclude(),
                orderBy: { post: { createdAt: 'desc' } },
                take: Math.min(parseInt(limit, 10), 100),
                skip: parseInt(offset, 10),
            }),
            prisma.jobOpportunity.count({ where }),
        ]);

        let studentId: number | undefined;
        if (req.user!.role === Role.STUDENT) {
            const student = await prisma.student.findUnique({ where: { userId: req.user!.userId } });
            studentId = student?.id;
        }

        return sendSuccess(res, { opportunities: opps.map((o) => formatOpp(o, studentId)), total });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── ALL: get single opportunity ─────────────────────────────────────────────

export const getOpportunity = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(req.params.id as string, 10);
        const opp = await prisma.jobOpportunity.findUnique({ where: { id }, include: oppInclude() });
        if (!opp) return sendError(res, 'Opportunity not found.', 404);

        let studentId: number | undefined;
        if (req.user!.role === Role.STUDENT) {
            const student = await prisma.student.findUnique({ where: { userId: req.user!.userId } });
            studentId = student?.id;
        }

        return sendSuccess(res, formatOpp(opp, studentId));
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── SUPERVISOR: create opportunity ──────────────────────────────────────────

export const createOpportunity = async (req: AuthRequest, res: Response) => {
    try {
        const { title, content, deadline, slots, questions = [] } = req.body as {
            title: string; content: string; deadline?: string;
            slots?: number; questions?: { question: string; required?: boolean; order?: number }[];
        };

        if (!title?.trim() || !content?.trim()) {
            return sendError(res, 'Title and content are required.', 400);
        }

        const opp = await prisma.jobOpportunity.create({
            data: {
                deadline: deadline ? new Date(deadline) : null,
                slots: slots ?? 1,
                status: 'OPEN',
                post: {
                    create: {
                        authorId: req.user!.userId,
                        postType: 'OPPORTUNITY',
                        title: title.trim(),
                        content: content.trim(),
                    },
                },
                questions: {
                    create: questions.map((q, i) => ({
                        question: q.question,
                        required: q.required ?? true,
                        order: q.order ?? i,
                    })),
                },
            },
            include: oppInclude(),
        });

        return sendSuccess(res, formatOpp(opp), 'Opportunity created.', 201);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── SUPERVISOR: update status ────────────────────────────────────────────────

export const updateOpportunityStatus = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(req.params.id as string, 10);
        const { status } = req.body as { status: 'OPEN' | 'CLOSED' | 'FILLED' };

        if (!['OPEN', 'CLOSED', 'FILLED'].includes(status)) {
            return sendError(res, 'Invalid status. Must be OPEN, CLOSED, or FILLED.', 400);
        }

        const opp = await prisma.jobOpportunity.findUnique({
            where: { id }, include: { post: { select: { authorId: true } } },
        });
        if (!opp) return sendError(res, 'Opportunity not found.', 404);
        if (opp.post.authorId !== req.user!.userId) return sendError(res, 'Not your opportunity.', 403);

        const updated = await prisma.jobOpportunity.update({
            where: { id }, data: { status }, include: oppInclude(),
        });

        return sendSuccess(res, formatOpp(updated), 'Status updated.');
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── SUPERVISOR: announce winners ────────────────────────────────────────────

export const announceWinners = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(req.params.id as string, 10);
        const { acceptedIds } = req.body as { acceptedIds: number[] };

        const opp = await prisma.jobOpportunity.findUnique({
            where: { id }, include: { post: { select: { authorId: true } } },
        });
        if (!opp) return sendError(res, 'Opportunity not found.', 404);
        if (opp.post.authorId !== req.user!.userId) return sendError(res, 'Not your opportunity.', 403);

        if (!Array.isArray(acceptedIds) || acceptedIds.length === 0) {
            return sendError(res, 'acceptedIds must be a non-empty array.', 400);
        }

        // Accept listed, reject the rest
        await prisma.$transaction([
            prisma.jobApplication.updateMany({
                where: { opportunityId: id, id: { in: acceptedIds } },
                data: { status: 'ACCEPTED', reviewedAt: new Date() },
            }),
            prisma.jobApplication.updateMany({
                where: { opportunityId: id, id: { notIn: acceptedIds }, status: 'PENDING' },
                data: { status: 'REJECTED', reviewedAt: new Date() },
            }),
            prisma.jobOpportunity.update({ where: { id }, data: { status: 'FILLED' } }),
        ]);

        const { sendNotification } = await import('../utils/notificationHelper');
        const accepted = await prisma.jobApplication.findMany({
            where: { opportunityId: id, id: { in: acceptedIds } },
            include: { student: { include: { user: { select: { id: true } } } } },
        });
        for (const app of accepted) {
            await sendNotification(app.student.user.id, '🎉 Congratulations! Your application has been accepted.');
        }

        return sendSuccess(res, null, 'Winners announced.');
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── SUPERVISOR: list applications ───────────────────────────────────────────

export const listApplications = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(req.params.id as string, 10);

        const opp = await prisma.jobOpportunity.findUnique({
            where: { id },
            include: {
                post: { select: { authorId: true, title: true, content: true } },
                questions: { select: { id: true, question: true, required: true } },
            },
        });
        if (!opp) return sendError(res, 'Opportunity not found.', 404);
        if (opp.post.authorId !== req.user!.userId) return sendError(res, 'Not your opportunity.', 403);

        const apps = await prisma.jobApplication.findMany({
            where: { opportunityId: id },
            include: {
                student: {
                    include: {
                        user: { select: { id: true, full_name: true, email: true } },
                        university: { select: { name: true } },
                    },
                },
                answers: { include: { question: { select: { question: true, order: true } } } },
            },
            orderBy: { appliedAt: 'asc' },
        });

        return sendSuccess(res, { opportunity: opp, applications: apps });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── SUPERVISOR: get single application ──────────────────────────────────────

export const getApplication = async (req: AuthRequest, res: Response) => {
    try {
        const oppId = parseInt(req.params.id as string, 10);
        const appId = parseInt(req.params.appId as string, 10);

        const opp = await prisma.jobOpportunity.findUnique({
            where: { id: oppId }, include: { post: { select: { authorId: true } } },
        });
        if (!opp) return sendError(res, 'Opportunity not found.', 404);
        if (opp.post.authorId !== req.user!.userId) return sendError(res, 'Not your opportunity.', 403);

        const app = await prisma.jobApplication.findUnique({
            where: { id: appId },
            include: {
                opportunity: { include: { post: { select: { title: true } } } },
                student: {
                    include: {
                        user: { select: { id: true, full_name: true, email: true } },
                        university: { select: { name: true } },
                        weeklyPlans: {
                            select: { week_number: true, status: true, submitted_at: true },
                            orderBy: { week_number: 'asc' },
                        },
                        assignments: {
                            select: { project_name: true, start_date: true, end_date: true, status: true },
                        },
                        finalEvaluation: {
                            select: {
                                technical_skills: true, communication: true,
                                team_collaboration: true, time_management: true,
                                professionalism: true, comments: true,
                            },
                        },
                    },
                },
                answers: { include: { question: { select: { question: true, order: true } } } },
            },
        });
        if (!app || app.opportunityId !== oppId) return sendError(res, 'Application not found.', 404);

        return sendSuccess(res, app);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── SUPERVISOR: review (accept/reject) application ──────────────────────────

export const reviewApplication = async (req: AuthRequest, res: Response) => {
    try {
        const oppId = parseInt(req.params.id as string, 10);
        const appId = parseInt(req.params.appId as string, 10);
        const { status } = req.body as { status: 'ACCEPTED' | 'REJECTED' };

        if (!['ACCEPTED', 'REJECTED'].includes(status)) {
            return sendError(res, 'Status must be ACCEPTED or REJECTED.', 400);
        }

        const opp = await prisma.jobOpportunity.findUnique({
            where: { id: oppId }, include: { post: { select: { authorId: true } } },
        });
        if (!opp) return sendError(res, 'Opportunity not found.', 404);
        if (opp.post.authorId !== req.user!.userId) return sendError(res, 'Not your opportunity.', 403);

        const app = await prisma.jobApplication.findUnique({ where: { id: appId } });
        if (!app || app.opportunityId !== oppId) return sendError(res, 'Application not found.', 404);

        const updated = await prisma.jobApplication.update({
            where: { id: appId },
            data: { status, reviewedAt: new Date() },
        });

        const { sendNotification } = await import('../utils/notificationHelper');
        const student = await prisma.student.findUnique({
            where: { id: app.studentId },
            include: { user: { select: { id: true, full_name: true } } },
        });

        if (student) {
            const msg = status === 'ACCEPTED'
                ? '🎉 Your application has been accepted!'
                : 'Your application was not selected this time.';
            await sendNotification(student.user.id, msg);

            // Auto-post congratulation to common feed on acceptance
            if (status === 'ACCEPTED') {
                const postTitle = await prisma.commonPost.findUnique({
                    where: { id: opp.postId },
                    select: { title: true },
                });
                const jobTitle = postTitle?.title ?? 'a job opportunity';
                await prisma.commonPost.create({
                    data: {
                        authorId: req.user!.userId,
                        postType: 'ANNOUNCEMENT',
                        visibility: 'PUBLIC',
                        title: `🎉 Congratulations to ${student.user.full_name}!`,
                        content: `<p>We are thrilled to announce that <strong>${student.user.full_name}</strong> has been selected for <strong>${jobTitle}</strong>. Congratulations on this well-deserved achievement! 🎊</p>`,
                    },
                });
            }
        }

        return sendSuccess(res, updated, `Application ${status.toLowerCase()}.`);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ─── STUDENT: apply ───────────────────────────────────────────────────────────

export const applyToOpportunity = async (req: AuthRequest, res: Response) => {
    try {
        const oppId = parseInt(req.params.id as string, 10);
        const { answers = [] } = req.body as {
            answers: { questionId: number; answer: string }[];
        };

        const student = await prisma.student.findUnique({ where: { userId: req.user!.userId } });
        if (!student) return sendError(res, 'Student profile not found.', 403);

        const opp = await prisma.jobOpportunity.findUnique({
            where: { id: oppId },
            include: { questions: true },
        });
        if (!opp) return sendError(res, 'Opportunity not found.', 404);
        if (opp.status !== 'OPEN') return sendError(res, 'This opportunity is no longer accepting applications.', 400);
        if (opp.deadline && new Date() > opp.deadline) {
            return sendError(res, 'The application deadline has passed.', 400);
        }

        // Check duplicate
        const existing = await prisma.jobApplication.findUnique({
            where: { opportunityId_studentId: { opportunityId: oppId, studentId: student.id } },
        });
        if (existing) return sendError(res, 'You have already applied to this opportunity.', 400);

        // Validate required questions
        const required = opp.questions.filter((q) => q.required);
        const answeredIds = new Set(answers.map((a) => a.questionId));
        const missing = required.filter((q) => !answeredIds.has(q.id));
        if (missing.length > 0) {
            return sendError(res, `Missing required answers for: ${missing.map((q) => q.question).join(', ')}`, 400);
        }

        const application = await prisma.jobApplication.create({
            data: {
                opportunityId: oppId,
                studentId: student.id,
                answers: {
                    create: answers.map((a) => ({
                        questionId: a.questionId,
                        answer: a.answer,
                    })),
                },
            },
            include: { answers: true },
        });

        // Notify the supervisor
        const { sendNotification } = await import('../utils/notificationHelper');
        const post = await prisma.commonPost.findUnique({
            where: { id: opp.postId },
            select: { authorId: true, title: true },
        });
        if (post) {
            await sendNotification(
                post.authorId,
                `📩 New application for "${post.title}" from ${student.userId}.`,
            );
        }

        return sendSuccess(res, application, 'Application submitted.', 201);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};
