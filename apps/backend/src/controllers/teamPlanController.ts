/**
 * teamPlanController — STUBBED
 *
 * This controller depends on schema fields (managerId, tl_status, teamWeeklyPlan,
 * teamDailyPlan) that are not yet present in the current Prisma schema/migrations.
 * All endpoints return 501 until the required migrations are applied and the
 * Prisma client is regenerated.
 */
import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';

const notImplemented = (_req: AuthRequest, res: Response) =>
    res.status(501).json({ success: false, message: 'Team plan features are not yet available.' });

export const assignTeamManager      = notImplemented;
export const getTeamWeeklyPlans     = notImplemented;
export const reviewTeamWeeklyPlan   = notImplemented;
export const reviewTeamDailyPlan    = notImplemented;
export const getMyTeamPlans         = notImplemented;
export const getTeamMembersPlans    = notImplemented;
export const getCompiledDraft       = notImplemented;
export const submitTeamWeeklyPlan   = notImplemented;
export const forwardToSupervisor    = notImplemented;
export const submitTeamDailyPlan    = notImplemented;
export const tlReviewWeeklyPlan     = notImplemented;
export const tlReviewDailyPlan      = notImplemented;
export const tlReviewTeamPlan       = notImplemented;
