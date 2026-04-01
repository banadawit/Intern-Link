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
    admin: Role.ADMIN,
    STUDENT: Role.STUDENT,
    SUPERVISOR: Role.SUPERVISOR,
    COORDINATOR: Role.COORDINATOR,
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
    if (
        (err && typeof err === 'object' && 'code' in err && (err as { code?: string }).code === 'AI_UNAVAILABLE') ||
        (err instanceof Error && err.message === 'AI_UNAVAILABLE')
    ) {
        return 503;
    }
    return 502;
}

function safeMessage(err: unknown): string {
    if (err instanceof Error) {
        if (err.message === 'AI_UNAVAILABLE') {
            return 'AI is not configured. Set OPENAI_API_KEY on the server.';
        }
        return err.message;
    }
    return 'AI request failed.';
}

export const postGeneratePlan = async (req: AuthRequest, res: Response) => {
    try {
        if (!ai.isAiConfigured()) {
            return res.status(503).json({ success: false, message: 'AI is not configured. Set OPENAI_API_KEY on the server.' });
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
            return res.status(503).json({ success: false, message: 'AI is not configured. Set OPENAI_API_KEY on the server.' });
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
            return res.status(503).json({ success: false, message: 'AI is not configured. Set OPENAI_API_KEY on the server.' });
        }
        const uid = req.user?.userId;
        const appRole = req.user?.role;
        if (uid == null || !appRole) {
            return res.status(401).json({ success: false, message: 'Unauthorized' });
        }

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

        if (bodyRole !== undefined && bodyRole !== null && typeof bodyRole === 'string') {
            const mapped = ROLE_BODY_MAP[bodyRole.trim()];
            if (!mapped || mapped !== appRole) {
                return res.status(403).json({ success: false, message: 'role in body must match your account role' });
            }
        }

        const histFromHistory = parseHistoryPayload(history);
        const histFromConv = parseHistoryPayload(conversationHistory);
        const hist =
            histFromConv && histFromConv.length > 0 ? histFromConv : histFromHistory;

        const userRow = await prisma.user.findUnique({
            where: { id: uid },
            select: { full_name: true },
        });
        const userDisplayName = (userRow?.full_name ?? '').trim() || 'there';

        const result = await ai.chatAssistant({
            message,
            history: hist,
            appRole,
            userId: uid,
            userDisplayName,
        });

        try {
            await aiHistory.appendChatTurn(uid, message.trim(), result.reply);
        } catch (persistErr) {
            console.error('ai chat persist:', persistErr);
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
            return res.status(401).json({ success: false, message: 'Unauthorized' });
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
            return res.status(401).json({ success: false, message: 'Unauthorized' });
        }
        await aiHistory.clearChatHistory(uid);
        res.json({ success: true, message: 'Chat history cleared' });
    } catch (err: unknown) {
        console.error('deleteChatHistory:', err);
        res.status(500).json({ success: false, message: 'Failed to clear chat history' });
    }
};
