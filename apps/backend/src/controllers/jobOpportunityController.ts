/**
 * jobOpportunityController
 *
 * Handles the full job-opportunity lifecycle:
 *   - Supervisor creates an OPPORTUNITY post + metadata + questions
 *   - Students browse open opportunities and apply with Q&A answers
 *   - Supervisor receives a notification, reviews applicants, accepts/rejects
 *   - Supervisor announces the winner(s) as a new ANNOUNCEMENT post
 */
import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { sendNotification } from '../utils/notificationHelper';
import { PostType, PostVisibility, Role } from '@prisma/client';

// ─── helpers ──────────────────────────────────────────────────────────────────

async function getSupervisor(req: AuthRequest) {
    return prisma.supervisor.findUnique({
        where: { userId: req.user!.userId },
        include: { user: { select: { full_name: true } }, company: { select: { name: true } } },
    });
}

async function getStudent(req: AuthRequest) {
    return prisma.student.findUnique({
        where: { userId: req.user!.userId },
        include: { user: { select: { full_name: true, email: true } } },
    });
}

// ─── Supervisor: create opportunity ──────────────────────────────────────────

/**
 * POST /api/job-opportunities
 * Body: { title, content, deadline?, slots?, imageUrls?, questions: [{ question, required, order }] }
 */
export const createOpportunity = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) { sendError(res, 'Supervisor profile not found.', 403); return; }

        const { title, content, deadline, slots, imageUrls, questions } = req.body;
        if (!title?.trim() || !content?.trim()) {
            sendError(res, 'Title and content are required.', 400); return;
        }

        // Create CommonPost first, then JobOpportunity (cascade delete handles cleanup if second fails)
        const post = await prisma.commonPost.create({
            data: {
                authorId: req.user!.userId,
                postType: PostType.OPPORTUNITY,
                visibility: PostVisibility.PUBLIC,
                title: title.trim(),
                content: content.trim(),
                imageUrls: imageUrls ?? [],
                documentUrls: [],
            },
        });

        const opportunity = await prisma.jobOpportunity.create({
            data: {
                postId: post.id,
                deadline: deadline ? new Date(deadline) : null,
                slots: slots ? parseInt(String(slots), 10) : 1,
                status: 'OPEN',
                questions: {
                    create: Array.isArray(questions)
                        ? questions.map((q: { question: string; required?: boolean; order?: number }, i: number) => ({
                            question: String(q.question).trim(),
                            required: q.required !== false,
                            order: q.order ?? i,
                        }))
                        : [],
                },
            },
            include: { questions: { orderBy: { order: 'asc' } } },
        });

        const result = { post, opportunity };

        sendSuccess(res, result, 'Job opportunity created.', 201);
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── List open opportunities (all roles) ─────────────────────────────────────

/**
 * GET /api/job-opportunities
 * Query: page?, limit?, status? (default OPEN)
 */
export const listOpportunities = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const page  = Math.max(1, parseInt(String(req.query.page  ?? 1), 10));
        const limit = Math.min(50, parseInt(String(req.query.limit ?? 20), 10));
        const status = typeof req.query.status === 'string' ? req.query.status : 'OPEN';
        const skip = (page - 1) * limit;

        const where = status === 'ALL' ? {} : { status };

        const [items, total] = await Promise.all([
            prisma.jobOpportunity.findMany({
                where,
                skip,
                take: limit,
                orderBy: { id: 'desc' },
                include: {
                    post: {
                        include: {
                            author: { select: { id: true, full_name: true, role: true } },
                        },
                    },
                    questions: { orderBy: { order: 'asc' } },
                    _count: { select: { applications: true } },
                },
            }),
            prisma.jobOpportunity.count({ where }),
        ]);

        // For students: attach whether they already applied
        let appliedIds = new Set<number>();
        if (req.user!.role === Role.STUDENT) {
            const student = await getStudent(req);
            if (student) {
                const apps = await prisma.jobApplication.findMany({
                    where: { studentId: student.id, opportunityId: { in: items.map((o) => o.id) } },
                    select: { opportunityId: true },
                });
                appliedIds = new Set(apps.map((a) => a.opportunityId));
            }
        }

        const data = items.map((o) => ({
            ...o,
            applicationCount: o._count.applications,
            hasApplied: appliedIds.has(o.id),
        }));

        sendSuccess(res, {
            opportunities: data,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
        });
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── Get single opportunity ───────────────────────────────────────────────────

/**
 * GET /api/job-opportunities/:id
 */
export const getOpportunity = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(String(req.params.id), 10);
        const opp = await prisma.jobOpportunity.findUnique({
            where: { id },
            include: {
                post: {
                    include: { author: { select: { id: true, full_name: true, role: true } } },
                },
                questions: { orderBy: { order: 'asc' } },
                _count: { select: { applications: true } },
            },
        });
        if (!opp) { sendError(res, 'Opportunity not found.', 404); return; }

        let hasApplied = false;
        let myApplication = null;
        if (req.user!.role === Role.STUDENT) {
            const student = await getStudent(req);
            if (student) {
                myApplication = await prisma.jobApplication.findUnique({
                    where: { opportunityId_studentId: { opportunityId: id, studentId: student.id } },
                    include: { answers: true },
                });
                hasApplied = !!myApplication;
            }
        }

        sendSuccess(res, {
            ...opp,
            applicationCount: opp._count.applications,
            hasApplied,
            myApplication,
        });
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── Student: apply ───────────────────────────────────────────────────────────

/**
 * POST /api/job-opportunities/:id/apply
 * Body: { answers: [{ questionId, answer }] }
 */
export const applyToOpportunity = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (req.user!.role !== Role.STUDENT) {
            sendError(res, 'Only students can apply.', 403); return;
        }

        const student = await getStudent(req);
        if (!student) { sendError(res, 'Student profile not found.', 403); return; }

        const oppId = parseInt(String(req.params.id), 10);
        const opp = await prisma.jobOpportunity.findUnique({
            where: { id: oppId },
            include: {
                questions: true,
                post: {
                    include: { author: { select: { id: true, full_name: true } } },
                },
            },
        });
        if (!opp) { sendError(res, 'Opportunity not found.', 404); return; }
        if (opp.status !== 'OPEN') { sendError(res, 'This opportunity is no longer accepting applications.', 400); return; }
        if (opp.deadline && new Date() > opp.deadline) {
            sendError(res, 'The application deadline has passed.', 400); return;
        }

        // Check duplicate
        const existing = await prisma.jobApplication.findUnique({
            where: { opportunityId_studentId: { opportunityId: oppId, studentId: student.id } },
        });
        if (existing) { sendError(res, 'You have already applied to this opportunity.', 400); return; }

        // Validate required questions
        const answers: { questionId: number; answer: string }[] = Array.isArray(req.body.answers) ? req.body.answers : [];
        const answeredIds = new Set(answers.map((a) => Number(a.questionId)));
        const missingRequired = opp.questions.filter((q) => q.required && !answeredIds.has(q.id));
        if (missingRequired.length > 0) {
            sendError(res, `Please answer all required questions: ${missingRequired.map((q) => q.question).join(', ')}`, 400);
            return;
        }

        // Create application + answers
        const application = await prisma.jobApplication.create({
            data: {
                opportunityId: oppId,
                studentId: student.id,
                answers: {
                    create: answers
                        .filter((a) => String(a.answer).trim())
                        .map((a) => ({
                            questionId: Number(a.questionId),
                            answer: String(a.answer).trim(),
                        })),
                },
            },
            include: { answers: true },
        });

        // Notify the supervisor who posted the opportunity
        sendNotification(
            opp.post.author.id,
            `New application from ${student.user.full_name} for your opportunity "${opp.post.title}".`,
        ).catch(() => {});

        sendSuccess(res, application, 'Application submitted successfully.', 201);
    } catch (e: unknown) {
        const err = e as Error;
        if (err.message?.includes('Unique constraint')) {
            sendError(res, 'You have already applied to this opportunity.', 400); return;
        }
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── Supervisor: list applicants ──────────────────────────────────────────────

/**
 * GET /api/job-opportunities/:id/applications
 */
export const listApplications = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) { sendError(res, 'Supervisor profile not found.', 403); return; }

        const oppId = parseInt(String(req.params.id), 10);

        // Verify this opportunity belongs to this supervisor
        const opp = await prisma.jobOpportunity.findUnique({
            where: { id: oppId },
            include: { post: { select: { authorId: true, title: true } } },
        });
        if (!opp) { sendError(res, 'Opportunity not found.', 404); return; }
        if (opp.post.authorId !== req.user!.userId) {
            sendError(res, 'You can only view applications for your own opportunities.', 403); return;
        }

        const applications = await prisma.jobApplication.findMany({
            where: { opportunityId: oppId },
            orderBy: { appliedAt: 'desc' },
            include: {
                student: {
                    include: {
                        user: { select: { id: true, full_name: true, email: true } },
                        university: { select: { name: true } },
                        assignments: {
                            where: { status: 'ACTIVE' },
                            select: { project_name: true, start_date: true },
                            take: 1,
                        },
                    },
                },
                answers: {
                    include: { question: { select: { question: true, order: true } } },
                    orderBy: { question: { order: 'asc' } },
                },
            },
        });

        sendSuccess(res, { opportunity: opp, applications });
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── Supervisor: review single application ────────────────────────────────────

/**
 * GET /api/job-opportunities/:id/applications/:appId
 */
export const getApplication = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) { sendError(res, 'Supervisor profile not found.', 403); return; }

        const appId = parseInt(String(req.params.appId), 10);
        const application = await prisma.jobApplication.findUnique({
            where: { id: appId },
            include: {
                opportunity: {
                    include: { post: { select: { authorId: true, title: true } } },
                },
                student: {
                    include: {
                        user: { select: { id: true, full_name: true, email: true } },
                        university: { select: { name: true } },
                        weeklyPlans: {
                            orderBy: { week_number: 'desc' },
                            take: 5,
                            select: { week_number: true, status: true, plan_description: true, submitted_at: true },
                        },
                        assignments: {
                            select: { project_name: true, start_date: true, end_date: true, status: true },
                        },
                        finalEvaluation: {
                            select: {
                                technical_skills: true, communication: true, team_collaboration: true,
                                time_management: true, professionalism: true, comments: true,
                            },
                        },
                    },
                },
                answers: {
                    include: { question: { select: { question: true, order: true } } },
                    orderBy: { question: { order: 'asc' } },
                },
            },
        });

        if (!application) { sendError(res, 'Application not found.', 404); return; }
        if (application.opportunity.post.authorId !== req.user!.userId) {
            sendError(res, 'Access denied.', 403); return;
        }

        sendSuccess(res, application);
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── Supervisor: accept / reject ──────────────────────────────────────────────

/**
 * PATCH /api/job-opportunities/:id/applications/:appId
 * Body: { status: 'ACCEPTED' | 'REJECTED' }
 */
export const reviewApplication = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) { sendError(res, 'Supervisor profile not found.', 403); return; }

        const appId = parseInt(String(req.params.appId), 10);
        const { status } = req.body;
        if (!['ACCEPTED', 'REJECTED'].includes(status)) {
            sendError(res, 'Status must be ACCEPTED or REJECTED.', 400); return;
        }

        const application = await prisma.jobApplication.findUnique({
            where: { id: appId },
            include: {
                opportunity: { include: { post: { select: { authorId: true, title: true } } } },
                student: { include: { user: { select: { id: true, full_name: true } } } },
            },
        });
        if (!application) { sendError(res, 'Application not found.', 404); return; }
        if (application.opportunity.post.authorId !== req.user!.userId) {
            sendError(res, 'Access denied.', 403); return;
        }

        const updated = await prisma.jobApplication.update({
            where: { id: appId },
            data: { status, reviewedAt: new Date() },
        });

        // Notify the student
        const msg = status === 'ACCEPTED'
            ? `Congratulations! Your application for "${application.opportunity.post.title}" has been accepted.`
            : `Your application for "${application.opportunity.post.title}" was not selected this time.`;
        sendNotification(application.student.user.id, msg).catch(() => {});

        // If accepted: post a public congratulation + check if slots are filled
        if (status === 'ACCEPTED') {
            // Public congratulation post visible to everyone on the platform
            const congratsContent = `<p>🎉 We are thrilled to congratulate <strong>${application.student.user.full_name}</strong> on being selected for the position of <strong>${application.opportunity.post.title}</strong> at <strong>${sup.company.name}</strong>!</p><p>This is a well-deserved achievement. We wish ${application.student.user.full_name} great success in this new role. 🚀</p>`;
            prisma.commonPost.create({
                data: {
                    authorId: req.user!.userId,
                    postType: PostType.ANNOUNCEMENT,
                    visibility: PostVisibility.PUBLIC,
                    title: `🎉 Congratulations, ${application.student.user.full_name}!`,
                    content: congratsContent,
                    imageUrls: [],
                    documentUrls: [],
                },
            }).catch(() => {});

            const acceptedCount = await prisma.jobApplication.count({
                where: { opportunityId: application.opportunityId, status: 'ACCEPTED' },
            });
            if (acceptedCount >= application.opportunity.slots) {
                await prisma.jobOpportunity.update({
                    where: { id: application.opportunityId },
                    data: { status: 'FILLED' },
                });
            }
        }

        sendSuccess(res, updated, `Application ${status.toLowerCase()}.`);
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── Supervisor: announce winner(s) ──────────────────────────────────────────

/**
 * POST /api/job-opportunities/:id/announce
 * Body: { message? } — optional custom message
 * Creates a public ANNOUNCEMENT post tagging the accepted students.
 */
export const announceWinners = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) { sendError(res, 'Supervisor profile not found.', 403); return; }

        const oppId = parseInt(String(req.params.id), 10);
        const opp = await prisma.jobOpportunity.findUnique({
            where: { id: oppId },
            include: {
                post: { select: { authorId: true, title: true } },
                applications: {
                    where: { status: 'ACCEPTED' },
                    include: {
                        student: { include: { user: { select: { id: true, full_name: true } } } },
                    },
                },
            },
        });
        if (!opp) { sendError(res, 'Opportunity not found.', 404); return; }
        if (opp.post.authorId !== req.user!.userId) {
            sendError(res, 'Access denied.', 403); return;
        }
        if (opp.applications.length === 0) {
            sendError(res, 'No accepted applications to announce.', 400); return;
        }

        const names = opp.applications.map((a) => a.student.user.full_name).join(', ');
        const customMsg = typeof req.body.message === 'string' ? req.body.message.trim() : '';

        const announcementContent = customMsg
            ? `<p>${customMsg}</p><p><strong>Selected candidate(s):</strong> ${names}</p>`
            : `<p>We are pleased to announce the selected candidate(s) for <strong>${opp.post.title}</strong>:</p><p><strong>${names}</strong></p><p>Congratulations to all selected candidates!</p>`;

        const announcement = await prisma.commonPost.create({
            data: {
                authorId: req.user!.userId,
                postType: PostType.ANNOUNCEMENT,
                visibility: PostVisibility.PUBLIC,
                title: `🎉 Results: ${opp.post.title}`,
                content: announcementContent,
                imageUrls: [],
                documentUrls: [],
            },
        });

        // Close the opportunity
        await prisma.jobOpportunity.update({
            where: { id: oppId },
            data: { status: 'FILLED' },
        });

        // Notify all accepted students
        for (const app of opp.applications) {
            sendNotification(
                app.student.user.id,
                `The results for "${opp.post.title}" have been announced. Check the common feed!`,
            ).catch(() => {});
        }

        sendSuccess(res, announcement, 'Winner announcement posted.', 201);
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── Supervisor: close / reopen opportunity ───────────────────────────────────

/**
 * PATCH /api/job-opportunities/:id/status
 * Body: { status: 'OPEN' | 'CLOSED' }
 */
export const updateOpportunityStatus = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) { sendError(res, 'Supervisor profile not found.', 403); return; }

        const oppId = parseInt(String(req.params.id), 10);
        const { status } = req.body;
        if (!['OPEN', 'CLOSED'].includes(status)) {
            sendError(res, 'Status must be OPEN or CLOSED.', 400); return;
        }

        const opp = await prisma.jobOpportunity.findUnique({
            where: { id: oppId },
            include: { post: { select: { authorId: true } } },
        });
        if (!opp) { sendError(res, 'Opportunity not found.', 404); return; }
        if (opp.post.authorId !== req.user!.userId) {
            sendError(res, 'Access denied.', 403); return;
        }

        const updated = await prisma.jobOpportunity.update({
            where: { id: oppId },
            data: { status },
        });
        sendSuccess(res, updated, `Opportunity ${status.toLowerCase()}.`);
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};

// ─── Supervisor: list own opportunities ──────────────────────────────────────

/**
 * GET /api/job-opportunities/mine
 */
export const myOpportunities = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) { sendError(res, 'Supervisor profile not found.', 403); return; }

        const opps = await prisma.jobOpportunity.findMany({
            where: { post: { authorId: req.user!.userId } },
            orderBy: { id: 'desc' },
            include: {
                post: { select: { id: true, title: true, content: true, createdAt: true } },
                questions: { orderBy: { order: 'asc' } },
                _count: { select: { applications: true } },
            },
        });

        const data = opps.map((o) => ({
            ...o,
            applicationCount: o._count.applications,
        }));

        sendSuccess(res, data);
    } catch (e: unknown) {
        const err = e as Error;
        sendError(res, err.message ?? 'Server error', 500);
    }
};
