import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

export const getSupervisorMe = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
            include: {
                user: { select: { full_name: true, email: true } },
                company: true,
            },
        });
        if (!supervisor) {
            return res.status(404).json({ message: 'Supervisor profile not found.' });
        }

        const companyId = supervisor.companyId;

        const [pendingProposalsCount, pendingWeeklyPlansCount, placedStudentsCount] = await Promise.all([
            prisma.internshipProposal.count({ where: { companyId, status: 'PENDING' } }),
            prisma.weeklyPlan.count({
                where: {
                    status: 'PENDING',
                    student: {
                        assignments: { some: { companyId, status: 'ACTIVE' } },
                    },
                },
            }),
            prisma.internshipAssignment.count({ where: { companyId, status: 'ACTIVE' } }),
        ]);

        res.json({
            supervisor,
            stats: {
                pendingProposalsCount,
                pendingWeeklyPlansCount,
                placedStudentsCount,
            },
        });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const getCompanyStudents = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return res.status(403).json({ message: 'Supervisor profile not found.' });
        }

        const assignments = await prisma.internshipAssignment.findMany({
            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
            include: {
                student: {
                    include: {
                        user: { select: { id: true, full_name: true, email: true } },
                        university: { select: { id: true, name: true } },
                        finalReport: {
                            select: { locked: true, sent_at: true, pdf_url: true, generated_at: true },
                        },
                    },
                },
            },
            orderBy: { start_date: 'desc' },
        });

        const payload = assignments.map((a) => ({
            student: {
                id: a.student.id,
                internship_status: a.student.internship_status,
                department: a.student.department,
                user: a.student.user,
                university: a.student.university,
                finalReport: a.student.finalReport,
            },
            assignment: {
                id: a.id,
                start_date: a.start_date,
                end_date: a.end_date,
                status: a.status,
                project_name: a.project_name,
            },
        }));

        res.json(payload);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const getCompanyWeeklyPlans = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return res.status(403).json({ message: 'Supervisor profile not found.' });
        }

        const active = await prisma.internshipAssignment.findMany({
            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
            select: { studentId: true },
        });
        const studentIds = [...new Set(active.map((a) => a.studentId))];
        if (studentIds.length === 0) {
            return res.json([]);
        }

        const statusParam = typeof req.query.status === 'string' ? req.query.status.toUpperCase() : undefined;
        const where: {
            studentId: { in: number[] };
            status?: 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED';
        } = { studentId: { in: studentIds } };
        if (statusParam === 'PENDING' || statusParam === 'APPROVED' || statusParam === 'REJECTED') {
            where.status = statusParam;
        }

        const plans = await prisma.weeklyPlan.findMany({
            where,
            include: {
                student: {
                    include: {
                        user: { select: { full_name: true, email: true } },
                        university: { select: { id: true, name: true } },
                    },
                },
                presentation: true,
            },
            orderBy: [{ submitted_at: 'desc' }],
        });

        res.json(plans);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

/** FR-6.5: Weekly attendance & execution records for company-placed students */
export const listWeeklyAttendanceReports = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return res.status(403).json({ message: 'Supervisor profile not found.' });
        }

        const reports = await prisma.weeklyReport.findMany({
            where: {
                student: {
                    assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } },
                },
            },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                weeklyPlan: { select: { id: true, week_number: true, status: true } },
            },
            orderBy: { submitted_at: 'desc' },
        });

        res.json(reports);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const patchWeeklyAttendanceReport = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        if (Number.isNaN(id)) {
            return res.status(400).json({ message: 'Invalid id.' });
        }

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return res.status(403).json({ message: 'Supervisor profile not found.' });
        }

        const report = await prisma.weeklyReport.findUnique({
            where: { id },
            include: {
                student: {
                    include: {
                        assignments: {
                            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
                        },
                    },
                },
            },
        });

        if (!report || report.student.assignments.length === 0) {
            return res.status(403).json({ message: 'Report not found or not in scope for your company.' });
        }

        const { attendanceStatus, execution_status, remarks } = req.body as {
            attendanceStatus?: string;
            execution_status?: string;
            remarks?: string;
        };

        const allowed = ['PRESENT', 'ABSENT', 'LATE'];
        const data: {
            attendanceStatus?: 'PRESENT' | 'ABSENT' | 'LATE';
            execution_status?: string | null;
            remarks?: string | null;
        } = {};

        if (attendanceStatus && allowed.includes(attendanceStatus)) {
            data.attendanceStatus = attendanceStatus as 'PRESENT' | 'ABSENT' | 'LATE';
        }
        if (typeof execution_status === 'string') {
            data.execution_status = execution_status;
        }
        if (typeof remarks === 'string') {
            data.remarks = remarks;
        }

        const updated = await prisma.weeklyReport.update({
            where: { id },
            data,
        });

        res.json(updated);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};
