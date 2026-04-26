import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { ymdFromUtcMs } from '../utils/internshipWeekDates';
import { sendSuccess, sendError } from '../utils/responseHelper';

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
            return sendError(res, 'Supervisor profile not found.', 404);
        }

        const companyId = supervisor.companyId;

        const [
            pendingProposalsCount,
            pendingWeeklyPlansCount,
            placedStudentsCount,
            approvedProposalsCount,
            reportsSubmittedCount,
            recentPendingProposals,
            recentPendingPlans,
        ] = await Promise.all([
            prisma.internshipProposal.count({ where: { companyId, status: 'PENDING' } }),
            prisma.weeklyPlan.count({
                where: {
                    status: 'PENDING',
                    student: { assignments: { some: { companyId, status: 'ACTIVE' } } },
                },
            }),
            prisma.internshipAssignment.count({ where: { companyId, status: 'ACTIVE' } }),
            prisma.internshipProposal.count({ where: { companyId, status: 'APPROVED' } }),
            prisma.report.count({ where: { student: { assignments: { some: { companyId } } } } }),
            prisma.internshipProposal.findMany({
                where: { companyId, status: 'PENDING' },
                orderBy: { submitted_at: 'desc' },
                take: 3,
                include: {
                    student: { include: { user: { select: { full_name: true, email: true } } } },
                    university: { select: { name: true } },
                },
            }),
            prisma.weeklyPlan.findMany({
                where: {
                    status: 'PENDING',
                    student: { assignments: { some: { companyId, status: 'ACTIVE' } } },
                },
                orderBy: { submitted_at: 'desc' },
                take: 3,
                include: {
                    student: { include: { user: { select: { full_name: true } } } },
                },
            }),
        ]);

        return sendSuccess(res, {
            supervisor,
            stats: {
                pendingProposalsCount,
                pendingWeeklyPlansCount,
                placedStudentsCount,
                approvedProposalsCount,
                reportsSubmittedCount,
            },
            recentPendingProposals: recentPendingProposals.map((p) => ({
                id: p.id,
                studentName: p.student.user.full_name,
                studentEmail: p.student.user.email,
                universityName: p.university.name,
                submitted_at: p.submitted_at,
            })),
            recentPendingPlans: recentPendingPlans.map((p) => ({
                id: p.id,
                studentName: p.student.user.full_name,
                weekNumber: p.week_number,
                submitted_at: p.submitted_at,
            })),
        }, 'Supervisor profile fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const getCompanyStudents = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
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

        return sendSuccess(res, payload, 'Students fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const getCompanyWeeklyPlans = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
        }

        const active = await prisma.internshipAssignment.findMany({
            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
            select: { studentId: true },
        });
        const studentIds = [...new Set(active.map((a) => a.studentId))];
        if (studentIds.length === 0) {
            return sendSuccess(res, [], 'No students found');
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

        return sendSuccess(res, plans, 'Weekly plans fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

/** FR-6.5: Weekly attendance & execution records for company-placed students */
export const listWeeklyAttendanceReports = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
        }

        const reports = await prisma.weeklyReport.findMany({
            where: {
                student: {
                    assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } },
                },
            },
            include: {
                student: {
                    include: {
                        user: { select: { full_name: true, email: true } },
                        assignments: {
                            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
                            take: 1,
                            select: { start_date: true },
                        },
                    },
                },
                weeklyPlan: {
                    select: {
                        id: true,
                        week_number: true,
                        status: true,
                        daySubmissions: { select: { workDate: true } },
                    },
                },
            },
            orderBy: { submitted_at: 'desc' },
        });

        return sendSuccess(res, reports, 'Attendance reports fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const patchWeeklyAttendanceReport = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        if (Number.isNaN(id)) {
            return sendError(res, 'Invalid id.', 400);
        }

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
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
            return sendError(res, 'Report not found or not in scope for your company.', 403);
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

        return sendSuccess(res, updated, 'Attendance report updated');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

/** GitHub-style contribution data: daily check-ins per student (approved plans only). */
export const getAttendanceHeatmap = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
        }

        const today = new Date();
        const endUtc = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());
        const startUtc = endUtc - 371 * 86400000;

        const placedStudents = await prisma.student.findMany({
            where: {
                assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } },
            },
            select: {
                id: true,
                user: { select: { full_name: true, email: true } },
            },
        });

        const rows = await prisma.weeklyPlanDaySubmission.findMany({
            where: {
                weeklyPlan: {
                    status: 'APPROVED',
                    student: {
                        assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } },
                    },
                },
                workDate: { gte: new Date(startUtc), lte: new Date(endUtc) },
            },
            select: {
                workDate: true,
                weeklyPlan: {
                    select: {
                        studentId: true,
                        student: {
                            select: {
                                user: { select: { full_name: true, email: true } },
                            },
                        },
                    },
                },
            },
        });

        const byStudent = new Map<
            number,
            { fullName: string; email: string; dates: Set<string> }
        >();

        for (const r of rows) {
            const sid = r.weeklyPlan.studentId;
            const u = r.weeklyPlan.student.user;
            let entry = byStudent.get(sid);
            if (!entry) {
                entry = { fullName: u.full_name, email: u.email, dates: new Set<string>() };
                byStudent.set(sid, entry);
            }
            const wd = r.workDate;
            const ms = new Date(wd).getTime();
            entry.dates.add(ymdFromUtcMs(ms));
        }

        const rangeEnd = ymdFromUtcMs(endUtc);
        const rangeStart = ymdFromUtcMs(startUtc);

        const merged = placedStudents.map((s) => {
            const sub = byStudent.get(s.id);
            return {
                studentId: s.id,
                fullName: s.user.full_name,
                email: s.user.email,
                submittedDates: sub ? [...sub.dates].sort() : [],
            };
        });

        return sendSuccess(res, {
            rangeStart,
            rangeEnd,
            students: merged,
        }, 'Attendance heatmap fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const submitEvaluation = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) return sendError(res, 'Supervisor profile not found.', 403);

        const { studentId, technical_score, soft_skill_score, comments } = req.body;
        const sid = parseInt(String(studentId), 10);

        // Verify student belongs to this company
        const assignment = await prisma.internshipAssignment.findFirst({
            where: { studentId: sid, companyId: supervisor.companyId, status: 'ACTIVE' },
        });
        if (!assignment) {
            return sendError(res, 'Student not assigned to your company.', 403);
        }

        const evaluation = await prisma.finalEvaluation.upsert({
            where: { studentId: sid },
            update: {
                technical_score,
                soft_skill_score,
                comments,
                evaluated_at: new Date(),
            },
            create: {
                studentId: sid,
                supervisorId: supervisor.id,
                technical_score,
                soft_skill_score,
                comments,
            },
        });

        return sendSuccess(res, evaluation, 'Evaluation submitted successfully.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

// --- COMPANY STAMP UPLOAD ---

/**
 * Upload or replace company stamp image
 * Used for stamping final reports
 */
export const uploadCompanyStamp = async (req: AuthRequest, res: Response) => {
    try {
        const file = req.file;
        const userId = req.user?.userId;

        if (!file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        // Get supervisor's company
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId },
            include: { company: true },
        });

        if (!supervisor) {
            return res.status(403).json({ error: 'Supervisor profile not found' });
        }

        const { CloudinaryService } = await import('../services/cloudinary.service');

        const folder = `internlink/${supervisor.companyId}/${userId}/stamps`;

        // Check if stamp already exists
        const existingStamp = supervisor.company.stamp_image_url;

        let uploadResult;

        if (existingStamp) {
            // Find existing file record
            const existingFile = await prisma.file.findFirst({
                where: { url: existingStamp },
            });

            if (existingFile) {
                // Replace existing stamp
                uploadResult = await CloudinaryService.replaceFile(
                    existingFile.publicId,
                    file,
                    {
                        userId,
                        organizationId: supervisor.companyId,
                        fileType: 'COMPANY_STAMP',
                        folder,
                        resourceType: 'image',
                    }
                );
            } else {
                // Old stamp not in new system, just upload new one
                uploadResult = await CloudinaryService.uploadImage(file, {
                    userId,
                    organizationId: supervisor.companyId,
                    fileType: 'COMPANY_STAMP',
                    folder,
                    resourceType: 'image',
                });
            }
        } else {
            // Upload new stamp
            uploadResult = await CloudinaryService.uploadImage(file, {
                userId,
                organizationId: supervisor.companyId,
                fileType: 'COMPANY_STAMP',
                folder,
                resourceType: 'image',
            });
        }

        if (!uploadResult.success) {
            return res.status(400).json({ error: uploadResult.error });
        }

        // Update company record
        await prisma.company.update({
            where: { id: supervisor.companyId },
            data: { stamp_image_url: uploadResult.url },
        });

        res.json({
            message: existingStamp
                ? 'Company stamp replaced successfully'
                : 'Company stamp uploaded successfully',
            url: uploadResult.url,
            fileId: uploadResult.fileId,
        });
    } catch (error: any) {
        console.error('Upload company stamp error:', error);
        res.status(500).json({ error: error.message });
    }
};
