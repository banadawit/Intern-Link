import { Response } from 'express';
import { Role } from '@prisma/client';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import * as ai from '../services/ai.service';
import * as aiHistory from '../services/aiChatHistory.service';

const MAX_PLAN_CHARS = 16000;

const ROLE_BODY_MAP: Record<string, Role> = {
    student: Role.STUDENT,
    supervisor: Role.SUPERVISOR,
    coordinator: Role.COORDINATOR,
    hod: Role.HOD,
    admin: Role.ADMIN,
    STUDENT: Role.STUDENT,
    SUPERVISOR: Role.SUPERVISOR,
    COORDINATOR: Role.COORDINATOR,
    HOD: Role.HOD,
    ADMIN: Role.ADMIN,
};

function parseHistoryPayload(raw: unknown): { role: 'user' | 'assistant'; content: string }[] | undefined {
    if (!Array.isArray(raw)) return undefined;
    return raw
        .filter(
            (h: unknown) =>
                h &&
                typeof h === 'object' &&
                ('role' in h ? (h as { role: string }).role : '') &&
                'content' in h
        )
        .map((h: unknown) => {
            const o = h as { role: string; content: string };
            const role: 'assistant' | 'user' = o.role === 'assistant' ? 'assistant' : 'user';
            return { role, content: String(o.content ?? '').slice(0, MAX_PLAN_CHARS) };
        })
        .slice(-20);
}

function aiErrorStatus(err: unknown): number {
    const msg = err instanceof Error ? err.message : String(err ?? '');
    if (
        /(^|\s)429(\s|$)/.test(msg) ||
        /too many requests/i.test(msg) ||
        /quota exceeded/i.test(msg) ||
        /rate[-\s]?limit/i.test(msg)
    ) {
        return 429;
    }
    if (
        (err && typeof err === 'object' && 'code' in err && (err as { code?: string }).code === 'AI_UNAVAILABLE') ||
        (err instanceof Error && err.message === 'AI_UNAVAILABLE')
    ) {
        return 503;
    }
    return 502;
}

function safeMessage(err: unknown): string {
    const msg = err instanceof Error ? err.message : String(err ?? '');
    if (
        /(^|\s)429(\s|$)/.test(msg) ||
        /too many requests/i.test(msg) ||
        /quota exceeded/i.test(msg) ||
        /rate[-\s]?limit/i.test(msg)
    ) {
        const retry = msg.match(/retry in\s+([\d.]+)\s*s/i)?.[1];
        if (retry) {
            return `AI request limit reached for now. Please try again in about ${Math.ceil(Number(retry))} seconds, or check API quota/billing.`;
        }
        return 'AI request limit reached for now. Please try again shortly, or check API quota/billing.';
    }
    if (err instanceof Error) {
        if (err.message === 'AI_UNAVAILABLE') {
            return 'AI is not configured. Set GROQ_API_KEY on the server.';
        }
        return err.message;
    }
    return 'AI request failed.';
}

export const postGeneratePlan = async (req: AuthRequest, res: Response) => {
    try {
        if (!ai.isAiConfigured()) {
            return res.status(503).json({ success: false, message: 'AI is not configured. Set GROQ_API_KEY on the server.' });
        }
        const { field, week, skills, internshipType } = req.body ?? {};
        if (typeof field !== 'string' || !field.trim()) {
            return res.status(400).json({ success: false, message: 'field is required' });
        }
        if (typeof skills !== 'string' || !skills.trim()) {
            return res.status(400).json({ success: false, message: 'skills is required' });
        }
        if (typeof internshipType !== 'string' || !internshipType.trim()) {
            return res.status(400).json({ success: false, message: 'internshipType is required' });
        }
        const w = parseInt(String(week), 10);
        if (Number.isNaN(w) || w < 1 || w > 104) {
            return res.status(400).json({ success: false, message: 'week must be a number between 1 and 104' });
        }

        const result = await ai.generateWeeklyPlan({
            field: field.trim().slice(0, 500),
            week: w,
            skills: skills.trim().slice(0, 2000),
            internshipType: internshipType.trim().slice(0, 500),
        });
        res.json({ success: true, data: result });
    } catch (err: unknown) {
        res.status(aiErrorStatus(err)).json({ success: false, message: safeMessage(err) });
    }
};

export const postGenerateFeedback = async (req: AuthRequest, res: Response) => {
    try {
        if (!ai.isAiConfigured()) {
            return res.status(503).json({ success: false, message: 'AI is not configured. Set GROQ_API_KEY on the server.' });
        }
        const { plan, studentName, week } = req.body ?? {};
        if (typeof plan !== 'string' || !plan.trim()) {
            return res.status(400).json({ success: false, message: 'plan is required' });
        }
        if (plan.length > MAX_PLAN_CHARS) {
            return res.status(400).json({ success: false, message: `plan must be at most ${MAX_PLAN_CHARS} characters` });
        }
        let weekNum: number | undefined;
        if (week !== undefined && week !== null) {
            weekNum = parseInt(String(week), 10);
            if (Number.isNaN(weekNum)) {
                return res.status(400).json({ success: false, message: 'week must be a number' });
            }
        }

        const result = await ai.generateFeedback({
            plan: plan.trim(),
            studentName: typeof studentName === 'string' ? studentName.trim().slice(0, 200) : undefined,
            week: weekNum,
        });
        res.json({ success: true, data: result });
    } catch (err: unknown) {
        res.status(aiErrorStatus(err)).json({ success: false, message: safeMessage(err) });
    }
};

export const postChat = async (req: AuthRequest, res: Response) => {
    try {
        if (!ai.isChatAiConfigured()) {
            return res.status(503).json({ success: false, message: 'AI is not configured. Set GROQ_API_KEY on the server.' });
        }
        const uid = req.user?.userId;
        const appRole = req.user?.role;

        const body = req.body ?? {};
        const { message, history, conversationHistory, role: bodyRole } = body as {
            message?: unknown;
            history?: unknown;
            conversationHistory?: unknown;
            role?: unknown;
        };

        if (typeof message !== 'string' || !message.trim()) {
            return res.status(400).json({ success: false, message: 'message is required' });
        }

        let effectiveAppRole: Role | 'VISITOR' = appRole ?? 'VISITOR';
        let skipHistory = false;

        if (bodyRole !== undefined && bodyRole !== null && typeof bodyRole === 'string') {
            const trimmed = bodyRole.trim().toLowerCase();
            if (trimmed === 'visitor') {
                effectiveAppRole = 'VISITOR';
                skipHistory = true;
            } else if (appRole) {
                const mapped = ROLE_BODY_MAP[trimmed];
                if (!mapped || mapped !== appRole) {
                    return res.status(403).json({ success: false, message: 'role in body must match your account role' });
                }
            }
        }

        const histFromHistory = parseHistoryPayload(history);
        const histFromConv = parseHistoryPayload(conversationHistory);
        const hist =
            histFromConv && histFromConv.length > 0 ? histFromConv : histFromHistory;

        let userDisplayName = 'Visitor';
        let studentContext: import('../services/ai.service').StudentContext | undefined;
        let supervisorContext: import('../services/ai.service').SupervisorContext | undefined;
        let hodContext: import('../services/ai.service').HodContext | undefined;

        if (uid && !skipHistory) {
            const userRow = await prisma.user.findUnique({
                where: { id: uid },
                select: { full_name: true, role: true },
            });
            userDisplayName = (userRow?.full_name ?? '').trim() || 'there';

            // ── STUDENT context ───────────────────────────────────────────────
            if (effectiveAppRole === Role.STUDENT) {
                const student = await prisma.student.findUnique({
                    where: { userId: uid },
                    include: {
                        assignments: {
                            where: { status: 'ACTIVE' },
                            take: 1,
                            include: { company: { select: { name: true } } },
                        },
                        studentProjects: {
                            include: { project: { select: { id: true, name: true, description: true } } },
                            take: 1,
                        },
                        weeklyPlans: {
                            orderBy: { week_number: 'desc' },
                            take: 5,
                            include: {
                                daySubmissions: { orderBy: { workDate: 'desc' }, take: 7 },
                            },
                        },
                    },
                });

                if (student) {
                    const assignment = student.assignments[0];
                    const project = student.studentProjects[0]?.project ?? null;
                    let supervisorName: string | undefined;
                    if (assignment?.companyId) {
                        const sup = await prisma.supervisor.findFirst({
                            where: { companyId: assignment.companyId },
                            include: { user: { select: { full_name: true } } },
                        });
                        supervisorName = sup?.user.full_name;
                    }
                    studentContext = {
                        companyName: assignment?.company?.name,
                        supervisorName,
                        projectName: project?.name,
                        projectDescription: project?.description ?? undefined,
                        weeklyPlans: student.weeklyPlans.map((p) => ({
                            weekNumber: p.week_number,
                            description: p.plan_description,
                            status: p.status,
                            feedback: p.feedback ?? undefined,
                            dailySubmissions: p.daySubmissions.map((d) => ({
                                date: d.workDate instanceof Date
                                    ? d.workDate.toISOString().slice(0, 10)
                                    : String(d.workDate).slice(0, 10),
                                notes: d.notes ?? undefined,
                            })),
                        })),
                    };
                }
            }

            // ── SUPERVISOR context ────────────────────────────────────────────
            if (effectiveAppRole === Role.SUPERVISOR) {
                const sup = await prisma.supervisor.findUnique({
                    where: { userId: uid },
                    include: { company: { select: { name: true } } },
                });
                if (sup) {
                    // Get placed students with their plans
                    const assignments = await prisma.internshipAssignment.findMany({
                        where: { companyId: sup.companyId, status: 'ACTIVE' },
                        include: {
                            student: {
                                include: {
                                    user: { select: { full_name: true, email: true } },
                                    studentProjects: {
                                        include: { project: { select: { name: true } } },
                                        take: 1,
                                    },
                                    weeklyPlans: {
                                        orderBy: { week_number: 'desc' },
                                        take: 1,
                                    },
                                },
                            },
                        },
                        take: 10,
                    });

                    const pendingProposals = await prisma.internshipProposal.count({
                        where: { companyId: sup.companyId, status: 'PENDING' },
                    });

                    const pendingPlans = await prisma.weeklyPlan.count({
                        where: {
                            status: { in: ['PENDING', 'RESUBMITTED'] },
                            student: { assignments: { some: { companyId: sup.companyId, status: 'ACTIVE' } } },
                        },
                    });

                    supervisorContext = {
                        companyName: sup.company.name,
                        pendingProposalsCount: pendingProposals,
                        pendingPlansCount: pendingPlans,
                        placedStudents: assignments.map((a) => {
                            const plans = a.student.weeklyPlans;
                            const lastPlan = plans[0];
                            return {
                                name: a.student.user.full_name,
                                email: a.student.user.email,
                                projectName: a.student.studentProjects[0]?.project?.name,
                                pendingPlans: plans.filter((p) => p.status === 'PENDING' || p.status === 'RESUBMITTED').length,
                                approvedPlans: plans.filter((p) => p.status === 'APPROVED').length,
                                rejectedPlans: plans.filter((p) => p.status === 'REJECTED').length,
                                lastPlanDescription: lastPlan?.plan_description,
                            };
                        }),
                    };
                }
            }

            // ── HOD context ───────────────────────────────────────────────────
            if (effectiveAppRole === Role.HOD) {
                const hod = await prisma.hodProfile.findUnique({
                    where: { userId: uid },
                    include: { university: { select: { name: true } } },
                });
                if (hod) {
                    const students = await prisma.student.findMany({
                        where: { universityId: hod.universityId },
                        select: {
                            id: true,
                            department: true,
                            hodId: true,
                            hod_approval_status: true,
                            internship_status: true,
                            user: { select: { full_name: true, email: true } },
                        },
                    });
                    const inDept = students.filter((s) =>
                        s.hodId === hod.id ||
                        (s.department ?? '').trim().toLowerCase() === hod.department.trim().toLowerCase()
                    );
                    const pending = inDept.filter((s) => s.hod_approval_status === 'PENDING');

                    hodContext = {
                        universityName: hod.university.name,
                        department: hod.department,
                        totalStudents: inDept.length,
                        pendingApprovals: pending.length,
                        approvedStudents: inDept.filter((s) => s.hod_approval_status === 'APPROVED').length,
                        placedStudents: inDept.filter((s) => s.internship_status === 'PLACED').length,
                        recentPendingStudents: pending.slice(0, 5).map((s) => ({
                            name: s.user.full_name,
                            email: s.user.email,
                        })),
                    };
                }
            }
        }

        const result = await ai.chatAssistant({
            message,
            history: hist,
            appRole: effectiveAppRole,
            userId: uid ?? 0,
            userDisplayName,
            studentContext,
            supervisorContext,
            hodContext,
        });

        if (uid && !skipHistory) {
            try {
                await aiHistory.appendChatTurn(uid, message.trim(), result.reply);
            } catch (persistErr) {
                console.error('ai chat persist:', persistErr);
            }
        }

        res.json({
            success: true,
            data: result,
            reply: result.reply,
        });
    } catch (err: unknown) {
        res.status(aiErrorStatus(err)).json({ success: false, message: safeMessage(err) });
    }
};

export const getChatHistory = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (uid == null) {
            return res.json({ success: true, data: { messages: [] } });
        }
        const raw = req.query.limit;
        let limit = 100;
        if (raw !== undefined && raw !== null) {
            const n = parseInt(String(raw), 10);
            if (!Number.isNaN(n) && n > 0) limit = Math.min(n, 200);
        }
        const messages = await aiHistory.listChatHistory(uid, limit);
        res.json({ success: true, data: { messages } });
    } catch (err: unknown) {
        console.error('getChatHistory:', err);
        res.status(500).json({ success: false, message: 'Failed to load chat history' });
    }
};

export const deleteChatHistory = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (uid == null) {
            return res.json({ success: true, message: 'Chat history cleared' });
        }
        await aiHistory.clearChatHistory(uid);
        res.json({ success: true, message: 'Chat history cleared' });
    } catch (err: unknown) {
        console.error('deleteChatHistory:', err);
        res.status(500).json({ success: false, message: 'Failed to clear chat history' });
    }
};
