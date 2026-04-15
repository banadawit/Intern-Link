import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

async function getCoordinator(userId: number) {
    return prisma.coordinator.findUnique({
        where: { userId },
        include: { university: true },
    });
}

// GET /coordinator-portal/dashboard-stats
export const getDashboardStats = async (req: AuthRequest, res: Response) => {
    try {
        const coord = await getCoordinator(req.user!.userId);
        if (!coord?.universityId) return res.status(403).json({ error: 'Not linked to a university.' });

        const uniId = coord.universityId;

        const [
            hodsAll,
            studentsAll,
            proposalsPending,
            activeAssignments,
            reportsCount,
            recentNotifications,
        ] = await Promise.all([
            prisma.hodProfile.findMany({
                where: { universityId: uniId },
                select: { user: { select: { institution_access_approval: true } } },
            }),
            prisma.student.findMany({
                where: { universityId: uniId },
                select: { hod_approval_status: true, internship_status: true },
            }),
            prisma.internshipProposal.count({
                where: { universityId: uniId, status: 'PENDING' },
            }),
            prisma.internshipAssignment.count({
                where: { student: { universityId: uniId }, status: 'ACTIVE' },
            }),
            prisma.report.count({
                where: { student: { universityId: uniId } },
            }),
            prisma.notification.findMany({
                where: { recipientId: req.user!.userId },
                orderBy: { created_at: 'desc' },
                take: 10,
                select: { id: true, message: true, is_read: true, created_at: true },
            }),
        ]);

        const hodsByStatus = hodsAll.reduce(
            (acc, h) => {
                const s = h.user.institution_access_approval;
                if (s === 'PENDING') acc.pending++;
                else if (s === 'APPROVED') acc.approved++;
                else if (s === 'REJECTED') acc.rejected++;
                return acc;
            },
            { pending: 0, approved: 0, rejected: 0 }
        );

        const byInternshipStatus = studentsAll.reduce<Record<string, number>>((acc, s) => {
            acc[s.internship_status] = (acc[s.internship_status] ?? 0) + 1;
            return acc;
        }, {});

        res.json({
            universityId: uniId,
            hods: { total: hodsAll.length, ...hodsByStatus },
            students: {
                total: studentsAll.length,
                byInternshipStatus,
                hodApprovalPending: studentsAll.filter((s) => s.hod_approval_status === 'PENDING').length,
            },
            proposalsPending,
            activeAssignments,
            reportsCount,
            recentNotifications,
        });
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// PATCH /coordinator-portal/notifications/:id/read
export const markNotificationRead = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        await prisma.notification.updateMany({
            where: { id, recipientId: req.user!.userId },
            data: { is_read: true },
        });
        res.json({ ok: true });
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// GET /coordinator-portal/companies
export const getCompanies = async (req: AuthRequest, res: Response) => {
    try {
        const companies = await prisma.company.findMany({
            orderBy: { created_at: 'desc' },
            select: {
                id: true,
                name: true,
                official_email: true,
                approval_status: true,
                address: true,
                created_at: true,
            },
        });
        res.json(companies);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// GET /coordinator-portal/proposals/overview
export const getProposalsOverview = async (req: AuthRequest, res: Response) => {
    try {
        const coord = await getCoordinator(req.user!.userId);
        if (!coord?.universityId) return res.status(403).json({ error: 'Not linked to a university.' });

        const proposals = await prisma.internshipProposal.findMany({
            where: { universityId: coord.universityId },
            orderBy: { submitted_at: 'desc' },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: { select: { id: true, name: true, official_email: true, approval_status: true } },
            },
        });
        res.json(proposals);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// GET /coordinator-portal/assignments/overview
export const getAssignmentsOverview = async (req: AuthRequest, res: Response) => {
    try {
        const coord = await getCoordinator(req.user!.userId);
        if (!coord?.universityId) return res.status(403).json({ error: 'Not linked to a university.' });

        const assignments = await prisma.internshipAssignment.findMany({
            where: { student: { universityId: coord.universityId } },
            orderBy: { start_date: 'desc' },
            include: {
                student: {
                    select: {
                        department: true,
                        user: { select: { full_name: true, email: true } },
                    },
                },
                company: { select: { id: true, name: true, official_email: true } },
            },
        });
        res.json(assignments);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};

// GET /coordinator-portal/reports/overview
export const getReportsOverview = async (req: AuthRequest, res: Response) => {
    try {
        const coord = await getCoordinator(req.user!.userId);
        if (!coord?.universityId) return res.status(403).json({ error: 'Not linked to a university.' });

        const reports = await prisma.report.findMany({
            where: { student: { universityId: coord.universityId } },
            orderBy: { generated_at: 'desc' },
            include: {
                student: {
                    select: {
                        department: true,
                        user: { select: { full_name: true, email: true } },
                    },
                },
            },
        });
        res.json(reports);
    } catch (e: any) {
        res.status(500).json({ error: e.message });
    }
};
