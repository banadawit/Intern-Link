/**
 * aiCache.service — STUBBED
 *
 * Depends on Prisma models (studentPlan, supervisorFeedback, hodSuggestion,
 * coordinatorReport) that are not yet in the current schema/migrations.
 * All functions fall through directly to the AI service without caching
 * until the required migrations are applied.
 */
import type { FeedbackInput, FeedbackResult, WeeklyPlanInput, WeeklyPlanResult } from './ai.service';
import * as ai from './ai.service';

export async function getStudentPlan(
    _studentId: string,
    data: WeeklyPlanInput,
): Promise<{ result: WeeklyPlanResult; cached: boolean }> {
    return { result: await ai.generateWeeklyPlan(data), cached: false };
}

export async function regenerateStudentPlan(
    _studentId: string,
    data: WeeklyPlanInput,
): Promise<{ result: WeeklyPlanResult; cached: boolean }> {
    return { result: await ai.generateWeeklyPlan(data), cached: false };
}

export async function getSupervisorFeedback(
    _studentId: string,
    _week: number,
    input: FeedbackInput,
): Promise<{ result: FeedbackResult; cached: boolean }> {
    return { result: await ai.generateFeedback(input), cached: false };
}

export async function regenerateSupervisorFeedback(
    _studentId: string,
    _week: number,
    input: FeedbackInput,
): Promise<{ result: FeedbackResult; cached: boolean }> {
    return { result: await ai.generateFeedback(input), cached: false };
}

export async function getHodSuggestion(
    _studentId: string,
    contextText: string,
): Promise<{ text: string; cached: boolean }> {
    return { text: await ai.generateHodSuggestion({ contextText }), cached: false };
}

export async function regenerateHodSuggestion(
    _studentId: string,
    contextText: string,
): Promise<{ text: string; cached: boolean }> {
    return { text: await ai.generateHodSuggestion({ contextText }), cached: false };
}

export async function getCoordinatorReport(
    _coordinatorUserId: number,
    contextText: string,
): Promise<{ text: string; cached: boolean }> {
    return { text: await ai.generateCoordinatorReport({ contextText }), cached: false };
}

export async function regenerateCoordinatorReport(
    _coordinatorUserId: number,
    contextText: string,
): Promise<{ text: string; cached: boolean }> {
    return { text: await ai.generateCoordinatorReport({ contextText }), cached: false };
}
