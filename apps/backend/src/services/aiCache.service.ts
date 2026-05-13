import prisma from '../config/db';
import type { FeedbackInput, FeedbackResult, WeeklyPlanInput, WeeklyPlanResult } from './ai.service';
import * as ai from './ai.service';

function parseWeeklyPlanJson(content: string): WeeklyPlanResult | null {
    try {
        const o = JSON.parse(content) as Record<string, unknown>;
        if (typeof o.tasks !== 'string' || typeof o.goals !== 'string' || typeof o.deliverables !== 'string') return null;
        return { tasks: o.tasks, goals: o.goals, deliverables: o.deliverables };
    } catch {
        return null;
    }
}

function parseFeedbackJson(content: string): FeedbackResult | null {
    try {
        const o = JSON.parse(content) as Record<string, unknown>;
        if (typeof o.strengths !== 'string' || typeof o.weaknesses !== 'string' || typeof o.suggestions !== 'string') {
            return null;
        }
        return { strengths: o.strengths, weaknesses: o.weaknesses, suggestions: o.suggestions };
    } catch {
        return null;
    }
}

export async function getStudentPlan(
    studentId: string,
    data: WeeklyPlanInput
): Promise<{ result: WeeklyPlanResult; cached: boolean }> {
    const row = await prisma.studentPlan.findUnique({ where: { studentId } });
    if (row) {
        const parsed = parseWeeklyPlanJson(row.content);
        if (parsed) return { result: parsed, cached: true };
    }
    const result = await ai.generateWeeklyPlan(data);
    const content = JSON.stringify(result);
    await prisma.studentPlan.upsert({
        where: { studentId },
        create: { studentId, content },
        update: { content },
    });
    return { result, cached: false };
}

export async function regenerateStudentPlan(
    studentId: string,
    data: WeeklyPlanInput
): Promise<{ result: WeeklyPlanResult; cached: boolean }> {
    const result = await ai.generateWeeklyPlan(data);
    const content = JSON.stringify(result);
    await prisma.studentPlan.upsert({
        where: { studentId },
        create: { studentId, content },
        update: { content },
    });
    return { result, cached: false };
}

export async function getSupervisorFeedback(
    studentId: string,
    week: number,
    input: FeedbackInput
): Promise<{ result: FeedbackResult; cached: boolean }> {
    const row = await prisma.supervisorFeedback.findUnique({
        where: { studentId_week: { studentId, week } },
    });
    if (row) {
        const parsed = parseFeedbackJson(row.content);
        if (parsed) return { result: parsed, cached: true };
    }
    const result = await ai.generateFeedback(input);
    const content = JSON.stringify(result);
    await prisma.supervisorFeedback.upsert({
        where: { studentId_week: { studentId, week } },
        create: { studentId, week, content },
        update: { content },
    });
    return { result, cached: false };
}

export async function regenerateSupervisorFeedback(
    studentId: string,
    week: number,
    input: FeedbackInput
): Promise<{ result: FeedbackResult; cached: boolean }> {
    const result = await ai.generateFeedback(input);
    const content = JSON.stringify(result);
    await prisma.supervisorFeedback.upsert({
        where: { studentId_week: { studentId, week } },
        create: { studentId, week, content },
        update: { content },
    });
    return { result, cached: false };
}

export async function getHodSuggestion(studentId: string, contextText: string): Promise<{ text: string; cached: boolean }> {
    const row = await prisma.hodSuggestion.findUnique({ where: { studentId } });
    if (row?.content?.trim()) {
        return { text: row.content, cached: true };
    }
    const text = await ai.generateHodSuggestion({ contextText });
    await prisma.hodSuggestion.upsert({
        where: { studentId },
        create: { studentId, content: text },
        update: { content: text },
    });
    return { text, cached: false };
}

export async function regenerateHodSuggestion(studentId: string, contextText: string): Promise<{ text: string; cached: boolean }> {
    const text = await ai.generateHodSuggestion({ contextText });
    await prisma.hodSuggestion.upsert({
        where: { studentId },
        create: { studentId, content: text },
        update: { content: text },
    });
    return { text, cached: false };
}

export async function getCoordinatorReport(
    coordinatorUserId: number,
    contextText: string
): Promise<{ text: string; cached: boolean }> {
    const row = await prisma.coordinatorReport.findUnique({ where: { coordinatorUserId } });
    if (row?.content?.trim()) {
        return { text: row.content, cached: true };
    }
    const text = await ai.generateCoordinatorReport({ contextText });
    await prisma.coordinatorReport.upsert({
        where: { coordinatorUserId },
        create: { coordinatorUserId, content: text },
        update: { content: text },
    });
    return { text, cached: false };
}

export async function regenerateCoordinatorReport(
    coordinatorUserId: number,
    contextText: string
): Promise<{ text: string; cached: boolean }> {
    const text = await ai.generateCoordinatorReport({ contextText });
    await prisma.coordinatorReport.upsert({
        where: { coordinatorUserId },
        create: { coordinatorUserId, content: text },
        update: { content: text },
    });
    return { text, cached: false };
}
