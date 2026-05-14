/**
 * jobOpportunityController — STUBBED
 *
 * Depends on Prisma models (jobOpportunity, jobApplication) that are not
 * yet in the current schema/migrations. All endpoints return 501 until
 * the required migrations are applied.
 */
import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';

const notImplemented = (_req: AuthRequest, res: Response) =>
    res.status(501).json({ success: false, message: 'Job opportunity features are not yet available.' });

export const myOpportunities        = notImplemented;
export const listOpportunities      = notImplemented;
export const getOpportunity         = notImplemented;
export const createOpportunity      = notImplemented;
export const updateOpportunityStatus = notImplemented;
export const announceWinners        = notImplemented;
export const listApplications       = notImplemented;
export const getApplication         = notImplemented;
export const reviewApplication      = notImplemented;
export const applyToOpportunity     = notImplemented;
