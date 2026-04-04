import { Response } from 'express';
import prisma from '../config/db';
import { AuthRequest } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { sendHodAccessDecisionEmail } from '../services/email.service';
import { sendNotification } from '../utils/notificationHelper';

async function getCoordinatorUniversityId(userId: number): Promise<number | null> {
    const c = await prisma.coordinator.findUnique({ where: { userId } });
    return c?.universityId ?? null;
}

async function requireUniversityId(req: AuthRequest, res: Response): Promise<number | null> {
    const uid = req.user?.userId;
    if (!uid) {
        res.status(401).json({ error: 'Unauthorized' });
        return null;
    }
    const universityId = await getCoordinatorUniversityId(uid);
    if (!universityId) {
        res.status(403).json({ error: 'Coordinator profile or university not linked.' });
        return null;
    }
    return universityId;
}

/** Aggregated KPIs for the coordinator home dashboard. */
export const getDashboardStats = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await requireUniversityId(req, res);
        if (universityId === null) return;

        const hods = await prisma.hod.findMany({
            where: { universityId },
            include: { user: { select: { institution_access_approval: true } } },
        });

        let hodPending = 0;
        let hodApproved = 0;
        let hodRejected = 0;
        for (const h of hods) {
            const a = h.user.institution_access_approval;
            if (a === 'PENDING') hodPending++;
            else if (a === 'APPROVED') hodApproved++;
            else if (a === 'REJECTED') hodRejected++;
        }

        const students = await prisma.student.findMany({
            where: { universityId },
            select: { internship_status: true, hod_approval_status: true },
        });

        const byInternship: Record<string, number> = { PENDING: 0, PLACED: 0, COMPLETED: 0 };
        let hodApprovalPendingStudents = 0;
        for (const s of students) {
            byInternship[s.internship_status] = (byInternship[s.internship_status] ?? 0) + 1;
            if (s.hod_approval_status === 'PENDING') hodApprovalPendingStudents++;
        }

        const [proposalsPending, activeAssignments, reportsCount] = await Promise.all([
            prisma.internshipProposal.count({
                where: { universityId, status: 'PENDING' },
            }),
            prisma.internshipAssignment.count({
                where: { student: { universityId }, status: 'ACTIVE' },
            }),
            prisma.report.count({
                where: { student: { universityId } },
            }),
        ]);

        const recentNotifications = await prisma.notification.findMany({
            where: { recipientId: req.user!.userId },
            orderBy: { created_at: 'desc' },
            take: 8,
            select: { id: true, message: true, is_read: true, created_at: true },
        });

        res.json({
            universityId,
            hods: {
                total: hods.length,
                pending: hodPending,
                approved: hodApproved,
                rejected: hodRejected,
            },
            students: {
                total: students.length,
                byInternshipStatus: byInternship,
                hodApprovalPending: hodApprovalPendingStudents,
            },
            proposalsPending,
            activeAssignments,
            reportsCount,
            recentNotifications,
        });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

/** All HOD accounts linked to the coordinator's university. */
export const getHods = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await requireUniversityId(req, res);
        if (universityId === null) return;

        const rows = await prisma.hod.findMany({
            where: { universityId },
            include: {
                user: {
                    select: {
                        id: true,
                        email: true,
                        full_name: true,
                        created_at: true,
                        institution_access_approval: true,
                        verification_status: true,
                    },
                },
                university: { select: { id: true, name: true } },
            },
            orderBy: { id: 'desc' },
        });

        res.json(rows);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

/** Placement monitoring: student counts and optional department breakdown. */
export const getStudentsOverview = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await requireUniversityId(req, res);
        if (universityId === null) return;

        const students = await prisma.student.findMany({
            where: { universityId },
            select: {
                id: true,
                department: true,
                internship_status: true,
                hod_approval_status: true,
                user: { select: { full_name: true, email: true } },
            },
            orderBy: { id: 'desc' },
            take: 200,
        });

        const byDept = new Map<string, number>();
        for (const s of students) {
            const d = s.department?.trim() || '—';
            byDept.set(d, (byDept.get(d) ?? 0) + 1);
        }

        res.json({
            students,
            byDepartment: Array.from(byDept.entries()).map(([department, count]) => ({ department, count })),
        });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getProposalsOverview = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await requireUniversityId(req, res);
        if (universityId === null) return;

        const proposals = await prisma.internshipProposal.findMany({
            where: { universityId },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: { select: { id: true, name: true, official_email: true, approval_status: true } },
            },
            orderBy: { submitted_at: 'desc' },
            take: 500,
        });
        res.json(proposals);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getAssignmentsOverview = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await requireUniversityId(req, res);
        if (universityId === null) return;

        const assignments = await prisma.internshipAssignment.findMany({
            where: { student: { universityId } },
            include: {
                student: {
                    select: {
                        department: true,
                        user: { select: { full_name: true, email: true } },
                    },
                },
                company: { select: { id: true, name: true, official_email: true } },
            },
            orderBy: { start_date: 'desc' },
            take: 500,
        });
        res.json(assignments);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getReportsOverview = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await requireUniversityId(req, res);
        if (universityId === null) return;

        const studentIds = (
            await prisma.student.findMany({
                where: { universityId },
                select: { id: true },
            })
        ).map((s) => s.id);

        const reports =
            studentIds.length === 0
                ? []
                : await prisma.report.findMany({
                      where: { studentId: { in: studentIds } },
                      include: {
                          student: {
                              select: {
                                  department: true,
                                  user: { select: { full_name: true, email: true } },
                              },
                          },
                      },
                      orderBy: { generated_at: 'desc' },
                  });
        res.json(reports);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

/** Read-only: all companies (platform directory) for monitoring. */
export const getCompanies = async (req: AuthRequest, res: Response) => {
    try {
        const ok = await requireUniversityId(req, res);
        if (ok === null) return;

        const companies = await prisma.company.findMany({
            select: {
                id: true,
                name: true,
                official_email: true,
                approval_status: true,
                created_at: true,
                address: true,
            },
            orderBy: { name: 'asc' },
        });
        res.json(companies);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getNotifications = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });

        const rows = await prisma.notification.findMany({
            where: { recipientId: uid },
            orderBy: { created_at: 'desc' },
            take: 100,
        });
        res.json(rows);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const markNotificationRead = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });

        const id = parseInt(String(req.params.id), 10);
        if (Number.isNaN(id)) return res.status(400).json({ error: 'Invalid id' });

        const n = await prisma.notification.findFirst({
            where: { id, recipientId: uid },
        });
        if (!n) return res.status(404).json({ error: 'Notification not found' });

        await prisma.notification.update({
            where: { id },
            data: { is_read: true },
        });
        res.json({ ok: true });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

/** Pending HOD accounts at this coordinator's university (awaiting coordinator approval). */
export const getPendingHods = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });

        const universityId = await getCoordinatorUniversityId(uid);
        if (!universityId) {
            return res.status(403).json({ error: 'Coordinator profile or university not linked.' });
        }

        const rows = await prisma.hod.findMany({
            where: {
                universityId,
                user: {
                    institution_access_approval: 'PENDING',
                    role: Role.HOD,
                },
            },
            include: {
                user: { select: { id: true, email: true, full_name: true, created_at: true } },
                university: { select: { id: true, name: true } },
            },
            orderBy: { id: 'desc' },
        });

        res.json(rows);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const approveHod = async (req: AuthRequest, res: Response) => {
    try {
        const coordinatorUserId = req.user?.userId;
        const targetUserId = parseInt(String(req.params.userId), 10);
        if (!coordinatorUserId || Number.isNaN(targetUserId)) {
            return res.status(400).json({ error: 'Invalid request' });
        }

        const universityId = await getCoordinatorUniversityId(coordinatorUserId);
        if (!universityId) {
            return res.status(403).json({ error: 'Coordinator profile or university not linked.' });
        }

        const hod = await prisma.hod.findUnique({
            where: { userId: targetUserId },
            include: { user: true },
        });
        if (!hod || hod.universityId !== universityId) {
            return res.status(404).json({ error: 'HOD not found at your university.' });
        }
        if (hod.user.role !== Role.HOD) {
            return res.status(400).json({ error: 'User is not an HOD.' });
        }

        await prisma.user.update({
            where: { id: targetUserId },
            data: { institution_access_approval: 'APPROVED' },
        });

        const uni = await prisma.university.findUnique({
            where: { id: universityId },
            select: { name: true },
        });

        await sendHodAccessDecisionEmail({
            to: hod.user.email,
            hodName: hod.user.full_name,
            universityName: uni?.name ?? 'Your university',
            decision: 'approved',
            department: hod.department,
        });

        await sendNotification(
            targetUserId,
            `Your Head of Department access for ${uni?.name ?? 'your university'} (${hod.department}) has been approved. You can sign in to InternLink.`
        );

        res.json({ message: 'HOD approved.', userId: targetUserId });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const rejectHod = async (req: AuthRequest, res: Response) => {
    try {
        const coordinatorUserId = req.user?.userId;
        const targetUserId = parseInt(String(req.params.userId), 10);
        if (!coordinatorUserId || Number.isNaN(targetUserId)) {
            return res.status(400).json({ error: 'Invalid request' });
        }

        const universityId = await getCoordinatorUniversityId(coordinatorUserId);
        if (!universityId) {
            return res.status(403).json({ error: 'Coordinator profile or university not linked.' });
        }

        const hod = await prisma.hod.findUnique({
            where: { userId: targetUserId },
            include: { user: true },
        });
        if (!hod || hod.universityId !== universityId) {
            return res.status(404).json({ error: 'HOD not found at your university.' });
        }
        if (hod.user.role !== Role.HOD) {
            return res.status(400).json({ error: 'User is not an HOD.' });
        }

        await prisma.user.update({
            where: { id: targetUserId },
            data: { institution_access_approval: 'REJECTED' },
        });

        const uni = await prisma.university.findUnique({
            where: { id: universityId },
            select: { name: true },
        });

        await sendHodAccessDecisionEmail({
            to: hod.user.email,
            hodName: hod.user.full_name,
            universityName: uni?.name ?? 'Your university',
            decision: 'rejected',
            department: hod.department,
        });

        await sendNotification(
            targetUserId,
            `Your Head of Department access request for ${uni?.name ?? 'your university'} (${hod.department}) was not approved. Contact your coordinator if you believe this is an error.`
        );

        res.json({ message: 'HOD access rejected.', userId: targetUserId });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};
