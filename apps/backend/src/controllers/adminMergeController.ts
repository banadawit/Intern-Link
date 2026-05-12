/**
 * Admin Merge Controller
 *
 * Allows admin to merge duplicate universities or companies.
 * All references (coordinators, students, supervisors, proposals, etc.)
 * are re-pointed to the target (canonical) record before the source is deleted.
 *
 * POST /admin/merge/universities  { sourceId, targetId }
 * POST /admin/merge/companies     { sourceId, targetId }
 */

import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendSuccess, sendError } from '../utils/responseHelper';

export const mergeUniversities = async (req: AuthRequest, res: Response) => {
  try {
    const { sourceId, targetId } = req.body as { sourceId?: number; targetId?: number };
    if (!sourceId || !targetId) return sendError(res, 'sourceId and targetId are required.', 400);
    if (sourceId === targetId) return sendError(res, 'sourceId and targetId must be different.', 400);

    const [source, target] = await Promise.all([
      prisma.university.findUnique({ where: { id: sourceId } }),
      prisma.university.findUnique({ where: { id: targetId } }),
    ]);
    if (!source) return sendError(res, `Source university ${sourceId} not found.`, 404);
    if (!target) return sendError(res, `Target university ${targetId} not found.`, 404);

    // Re-point all references from source → target in a transaction
    await prisma.$transaction([
      // Coordinators
      prisma.coordinator.updateMany({ where: { universityId: sourceId }, data: { universityId: targetId } }),
      // HOD profiles
      prisma.hodProfile.updateMany({ where: { universityId: sourceId }, data: { universityId: targetId } }),
      // Students
      prisma.student.updateMany({ where: { universityId: sourceId }, data: { universityId: targetId } }),
      // Proposals
      prisma.internshipProposal.updateMany({ where: { universityId: sourceId }, data: { universityId: targetId } }),
      // Reports
      prisma.report.updateMany({ where: { sentToUniversityId: sourceId }, data: { sentToUniversityId: targetId } }),
    ]);

    // Handle UniversityConfig — keep target's, delete source's if exists
    await prisma.universityConfig.deleteMany({ where: { universityId: sourceId } });

    // Delete source university
    await prisma.university.delete({ where: { id: sourceId } });

    await prisma.auditLog.create({
      data: {
        adminId: req.user!.userId,
        action: 'MERGE_UNIVERSITIES',
        targetId: targetId,
        details: `Merged university "${source.name}" (id:${sourceId}) into "${target.name}" (id:${targetId})`,
      },
    });

    return sendSuccess(res, { merged: source.name, into: target.name },
      `"${source.name}" merged into "${target.name}" successfully.`);
  } catch (e: any) {
    return sendError(res, e.message);
  }
};

export const mergeCompanies = async (req: AuthRequest, res: Response) => {
  try {
    const { sourceId, targetId } = req.body as { sourceId?: number; targetId?: number };
    if (!sourceId || !targetId) return sendError(res, 'sourceId and targetId are required.', 400);
    if (sourceId === targetId) return sendError(res, 'sourceId and targetId must be different.', 400);

    const [source, target] = await Promise.all([
      prisma.company.findUnique({ where: { id: sourceId } }),
      prisma.company.findUnique({ where: { id: targetId } }),
    ]);
    if (!source) return sendError(res, `Source company ${sourceId} not found.`, 404);
    if (!target) return sendError(res, `Target company ${targetId} not found.`, 404);

    await prisma.$transaction([
      // Supervisors
      prisma.supervisor.updateMany({ where: { companyId: sourceId }, data: { companyId: targetId } }),
      // Assignments
      prisma.internshipAssignment.updateMany({ where: { companyId: sourceId }, data: { companyId: targetId } }),
      // Proposals
      prisma.internshipProposal.updateMany({ where: { companyId: sourceId }, data: { companyId: targetId } }),
      // Projects
      prisma.project.updateMany({ where: { companyId: sourceId }, data: { companyId: targetId } }),
      // Teams
      prisma.team.updateMany({ where: { companyId: sourceId }, data: { companyId: targetId } }),
    ]);

    await prisma.company.delete({ where: { id: sourceId } });

    await prisma.auditLog.create({
      data: {
        adminId: req.user!.userId,
        action: 'MERGE_COMPANIES',
        targetId: targetId,
        details: `Merged company "${source.name}" (id:${sourceId}) into "${target.name}" (id:${targetId})`,
      },
    });

    return sendSuccess(res, { merged: source.name, into: target.name },
      `"${source.name}" merged into "${target.name}" successfully.`);
  } catch (e: any) {
    return sendError(res, e.message);
  }
};

/**
 * GET /admin/merge/duplicates/universities
 * Returns groups of universities with similar names (potential duplicates).
 */
export const findDuplicateUniversities = async (req: AuthRequest, res: Response) => {
  try {
    const all = await prisma.university.findMany({
      select: { id: true, name: true, address: true, approval_status: true, created_at: true },
      orderBy: { name: 'asc' },
    });

    // Simple grouping: normalize names and find near-matches
    const normalize = (s: string) => s.toLowerCase().trim().replace(/\s+/g, ' ');
    const groups: Array<{ names: string[]; records: typeof all }> = [];
    const used = new Set<number>();

    for (let i = 0; i < all.length; i++) {
      if (used.has(all[i].id)) continue;
      const group = [all[i]];
      const na = normalize(all[i].name);
      for (let j = i + 1; j < all.length; j++) {
        if (used.has(all[j].id)) continue;
        const nb = normalize(all[j].name);
        // Check if one contains the other or they share 80%+ chars
        if (na.includes(nb) || nb.includes(na) || _similarity(na, nb) >= 0.80) {
          group.push(all[j]);
          used.add(all[j].id);
        }
      }
      if (group.length > 1) {
        used.add(all[i].id);
        groups.push({ names: group.map((g) => g.name), records: group });
      }
    }

    return sendSuccess(res, groups, `Found ${groups.length} potential duplicate group(s).`);
  } catch (e: any) {
    return sendError(res, e.message);
  }
};

export const findDuplicateCompanies = async (req: AuthRequest, res: Response) => {
  try {
    const all = await prisma.company.findMany({
      select: { id: true, name: true, address: true, approval_status: true, created_at: true },
      orderBy: { name: 'asc' },
    });

    const normalize = (s: string) => s.toLowerCase().trim().replace(/\s+/g, ' ');
    const groups: Array<{ names: string[]; records: typeof all }> = [];
    const used = new Set<number>();

    for (let i = 0; i < all.length; i++) {
      if (used.has(all[i].id)) continue;
      const group = [all[i]];
      const na = normalize(all[i].name);
      for (let j = i + 1; j < all.length; j++) {
        if (used.has(all[j].id)) continue;
        const nb = normalize(all[j].name);
        if (na.includes(nb) || nb.includes(na) || _similarity(na, nb) >= 0.80) {
          group.push(all[j]);
          used.add(all[j].id);
        }
      }
      if (group.length > 1) {
        used.add(all[i].id);
        groups.push({ names: group.map((g) => g.name), records: group });
      }
    }

    return sendSuccess(res, groups, `Found ${groups.length} potential duplicate group(s).`);
  } catch (e: any) {
    return sendError(res, e.message);
  }
};

function _similarity(a: string, b: string): number {
  const m = a.length, n = b.length;
  if (m === 0 || n === 0) return 0;
  const dp: number[][] = Array.from({ length: m + 1 }, (_, i) =>
    Array.from({ length: n + 1 }, (_, j) => (i === 0 ? j : j === 0 ? i : 0))
  );
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = a[i - 1] === b[j - 1] ? dp[i - 1][j - 1] : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
  return 1 - dp[m][n] / Math.max(m, n);
}
