/**
 * University Search Controller
 *
 * Provides:
 * - Searchable/autocomplete endpoint for coordinator registration
 * - Fuzzy duplicate detection
 * - Organization type support
 */

import { Request, Response } from 'express';
import prisma from '../config/db';
import { sendSuccess, sendError } from '../utils/responseHelper';

/** Normalize a name for comparison */
function normalize(name: string): string {
  return name.toLowerCase().trim().replace(/\s+/g, ' ');
}

/**
 * Simple Levenshtein distance for fuzzy matching.
 * Returns 0 for identical strings, higher for more different.
 */
function levenshtein(a: string, b: string): number {
  const m = a.length, n = b.length;
  const dp: number[][] = Array.from({ length: m + 1 }, (_, i) =>
    Array.from({ length: n + 1 }, (_, j) => (i === 0 ? j : j === 0 ? i : 0))
  );
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] === b[j - 1]
        ? dp[i - 1][j - 1]
        : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    }
  }
  return dp[m][n];
}

/** Similarity score 0–1 (1 = identical) */
function similarity(a: string, b: string): number {
  const na = normalize(a), nb = normalize(b);
  const maxLen = Math.max(na.length, nb.length);
  if (maxLen === 0) return 1;
  return 1 - levenshtein(na, nb) / maxLen;
}

/**
 * GET /universities/search?q=haramaya&limit=10
 * Returns universities matching the query with partial/fuzzy matching.
 * Used in coordinator registration autocomplete.
 */
export const searchUniversities = async (req: Request, res: Response) => {
  try {
    const q = (req.query.q as string ?? '').trim();
    const limit = Math.min(20, parseInt(String(req.query.limit ?? '10'), 10) || 10);

    if (q.length < 1) {
      // Return top approved universities when no query
      const top = await prisma.university.findMany({
        where: { approval_status: 'APPROVED' },
        orderBy: { name: 'asc' },
        take: limit,
        select: { id: true, name: true, address: true, approval_status: true },
      });
      return sendSuccess(res, top);
    }

    // Prisma full-text search (case-insensitive contains)
    const results = await prisma.university.findMany({
      where: {
        approval_status: 'APPROVED',
        name: { contains: q, mode: 'insensitive' },
      },
      orderBy: { name: 'asc' },
      take: limit * 2, // fetch more for re-ranking
      select: { id: true, name: true, address: true, approval_status: true },
    });

    // Re-rank by similarity score
    const ranked = results
      .map((u) => ({ ...u, score: similarity(q, u.name) }))
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);

    return sendSuccess(res, ranked);
  } catch (e: any) {
    return sendError(res, e.message);
  }
};

/**
 * GET /universities/approved
 * Returns all approved universities (for HOD/Student registration dropdowns).
 */
export const getApprovedUniversities = async (req: Request, res: Response) => {
  try {
    const universities = await prisma.university.findMany({
      where: { approval_status: 'APPROVED' },
      orderBy: { name: 'asc' },
      select: {
        id: true,
        name: true,
        address: true,
        approval_status: true,
        coordinators: {
          select: { id: true },
          take: 1,
        },
      },
    });

    const result = universities.map((u) => ({
      id: u.id,
      name: u.name,
      address: u.address,
      approval_status: u.approval_status,
      hasCoordinator: u.coordinators.length > 0,
    }));

    return sendSuccess(res, result);
  } catch (e: any) {
    return sendError(res, e.message);
  }
};

/**
 * POST /universities/check-duplicate
 * Body: { name: string }
 * Returns: { isDuplicate: boolean, suggestions: University[] }
 * Used before submitting a new institution request.
 */
export const checkUniversityDuplicate = async (req: Request, res: Response) => {
  try {
    const { name } = req.body as { name?: string };
    if (!name?.trim()) {
      return sendError(res, 'name is required.', 400);
    }

    const normalized = normalize(name);

    // Exact match check
    const exact = await prisma.university.findFirst({
      where: { name: { equals: name.trim(), mode: 'insensitive' } },
      select: { id: true, name: true, address: true, approval_status: true },
    });

    if (exact) {
      return sendSuccess(res, {
        isDuplicate: true,
        exactMatch: exact,
        suggestions: [],
        message: `"${exact.name}" already exists in the system.`,
      });
    }

    // Fuzzy match — get all universities and score them
    const all = await prisma.university.findMany({
      where: { approval_status: { in: ['APPROVED', 'PENDING'] } },
      select: { id: true, name: true, address: true, approval_status: true },
    });

    const SIMILARITY_THRESHOLD = 0.75;
    const suggestions = all
      .map((u) => ({ ...u, score: similarity(name, u.name) }))
      .filter((u) => u.score >= SIMILARITY_THRESHOLD)
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);

    if (suggestions.length > 0) {
      return sendSuccess(res, {
        isDuplicate: false,
        exactMatch: null,
        suggestions,
        message: `Similar institutions found. Did you mean one of these?`,
      });
    }

    return sendSuccess(res, {
      isDuplicate: false,
      exactMatch: null,
      suggestions: [],
      message: 'No similar institutions found. You can proceed with your request.',
    });
  } catch (e: any) {
    return sendError(res, e.message);
  }
};

/**
 * GET /companies/search?q=demo&limit=10
 * Returns companies matching the query.
 * Used in supervisor registration autocomplete.
 */
export const searchCompanies = async (req: Request, res: Response) => {
  try {
    const q = (req.query.q as string ?? '').trim();
    const limit = Math.min(20, parseInt(String(req.query.limit ?? '10'), 10) || 10);

    if (q.length < 1) {
      const top = await prisma.company.findMany({
        where: { approval_status: 'APPROVED' },
        orderBy: { name: 'asc' },
        take: limit,
        select: { id: true, name: true, address: true, approval_status: true },
      });
      return sendSuccess(res, top);
    }

    const results = await prisma.company.findMany({
      where: {
        approval_status: 'APPROVED',
        name: { contains: q, mode: 'insensitive' },
      },
      orderBy: { name: 'asc' },
      take: limit * 2,
      select: { id: true, name: true, address: true, approval_status: true },
    });

    const ranked = results
      .map((c) => ({ ...c, score: similarity(q, c.name) }))
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);

    return sendSuccess(res, ranked);
  } catch (e: any) {
    return sendError(res, e.message);
  }
};

/**
 * POST /companies/check-duplicate
 * Body: { name: string }
 */
export const checkCompanyDuplicate = async (req: Request, res: Response) => {
  try {
    const { name } = req.body as { name?: string };
    if (!name?.trim()) return sendError(res, 'name is required.', 400);

    const exact = await prisma.company.findFirst({
      where: { name: { equals: name.trim(), mode: 'insensitive' } },
      select: { id: true, name: true, address: true, approval_status: true },
    });

    if (exact) {
      return sendSuccess(res, {
        isDuplicate: true,
        exactMatch: exact,
        suggestions: [],
        message: `"${exact.name}" already exists in the system.`,
      });
    }

    const all = await prisma.company.findMany({
      where: { approval_status: { in: ['APPROVED', 'PENDING'] } },
      select: { id: true, name: true, address: true, approval_status: true },
    });

    const SIMILARITY_THRESHOLD = 0.75;
    const suggestions = all
      .map((c) => ({ ...c, score: similarity(name, c.name) }))
      .filter((c) => c.score >= SIMILARITY_THRESHOLD)
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);

    return sendSuccess(res, {
      isDuplicate: false,
      exactMatch: null,
      suggestions,
      message: suggestions.length > 0
        ? 'Similar organizations found. Did you mean one of these?'
        : 'No similar organizations found. You can proceed with your request.',
    });
  } catch (e: any) {
    return sendError(res, e.message);
  }
};
