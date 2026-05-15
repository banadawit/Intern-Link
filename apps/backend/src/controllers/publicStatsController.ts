import { Request, Response } from 'express';
import prisma from '../config/db';

/**
 * GET /api/public/stats
 * Returns real platform statistics for the landing page.
 * No authentication required.
 */
export const getPublicStats = async (_req: Request, res: Response) => {
    try {
        const [
            totalStudents,
            placedStudents,
            completedStudents,
            partnerCompanies,
            partnerUniversities,
            totalReports,
            totalWeeklyPlans,
        ] = await Promise.all([
            prisma.student.count(),
            prisma.student.count({ where: { internship_status: 'PLACED' } }),
            prisma.student.count({ where: { internship_status: 'COMPLETED' } }),
            prisma.company.count({ where: { approval_status: 'APPROVED' } }),
            prisma.university.count({ where: { approval_status: 'APPROVED' } }),
            prisma.report.count(),
            prisma.weeklyPlan.count(),
        ]);

        const activeStudents = placedStudents + completedStudents;
        const placementRate = totalStudents > 0
            ? Math.round(((placedStudents + completedStudents) / totalStudents) * 100)
            : 0;

        res.json({
            success: true,
            data: {
                totalStudents,
                activeStudents,
                placedStudents,
                completedStudents,
                placementRate,
                partnerCompanies,
                partnerUniversities,
                totalReports,
                totalWeeklyPlans,
                reportsGenerated: totalReports + totalWeeklyPlans,
            },
        });
    } catch (error: any) {
        res.status(500).json({ success: false, error: error.message });
    }
};
