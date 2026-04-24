import { Response } from 'express';
import prisma from '../config/db';
import { AuthRequest } from '../middlewares/authMiddleware';
import { ApprovalStatus } from '@prisma/client';
import { departmentsMatch } from '../utils/hodScope';
import { sendCompanyInviteEmail, sendStudentHodDecisionEmail } from '../services/email.service';
import { sendNotification } from '../utils/notificationHelper';
import { sendSuccess, sendError } from '../utils/responseHelper';

async function getHodOr403(userId: number) {
    const hod = await prisma.hodProfile.findUnique({
        where: { userId },
        include: { university: true },
    });
    return hod;
}

export const verifyStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const { studentId, status, reason } = req.body as {
            studentId?: number;
            status?: string;
            reason?: string;
        };

        if (!studentId || !status || !['APPROVED', 'REJECTED'].includes(status)) {
            return sendError(res, 'studentId and status (APPROVED | REJECTED) are required.', 400);
        }

        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });
        
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return sendError(res, 'Student not in your department.', 404);
        }

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: status as ApprovalStatus },
        });

        if (status === 'APPROVED') {
            await prisma.user.update({
                where: { id: student.userId },
                data: { verification_status: 'APPROVED' },
            });
        }

        const msg = status === 'APPROVED'
            ? `Your registration has been approved by your Head of Department.`
            : `Your registration was not approved. Reason: ${reason?.trim() || 'No reason provided.'}`;
        
        await sendNotification(student.userId, msg);

        await sendStudentHodDecisionEmail({
            to: student.user.email,
            studentName: student.user.full_name,
            universityName: hod.university.name,
            department: hod.department,
            decision: status === 'APPROVED' ? 'approved' : 'rejected',
            reason: reason?.trim(),
        });

        return sendSuccess(res, { studentId, status }, `Student ${status.toLowerCase()}.`);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getDashboardStats = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const baseStudentWhere = {
            universityId: hod.universityId,
            department: { not: null },
        };

        const students = await prisma.student.findMany({
            where: baseStudentWhere,
            select: { id: true, department: true, hod_approval_status: true, internship_status: true },
        });
        const inDept = students.filter((s) => departmentsMatch(s.department, hod.department));

        const deptStudentIds = inDept.map((s) => s.id);
        const reportCount = deptStudentIds.length === 0 ? 0 : await prisma.report.count({
            where: { studentId: { in: deptStudentIds } },
        });

        return sendSuccess(res, {
            totalStudents: inDept.length,
            pendingApprovals: inDept.filter((s) => s.hod_approval_status === 'PENDING').length,
            placedStudents: inDept.filter((s) => s.internship_status === 'PLACED').length,
            reports: reportCount,
            university: { name: hod.university.name },
        });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getStudents = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const status = (req.query.status as string) || 'all';
        const hodApprovalFilter: ApprovalStatus | 'all' =
            status === 'pending' ? 'PENDING' : status === 'approved' ? 'APPROVED' : status === 'rejected' ? 'REJECTED' : 'all';

        const rows = await prisma.student.findMany({
            where: {
                universityId: hod.universityId,
                department: { not: null },
                ...(hodApprovalFilter !== 'all' ? { hod_approval_status: hodApprovalFilter } : {}),
            },
            include: {
                user: { select: { id: true, email: true, full_name: true, verification_status: true } },
            },
            orderBy: { id: 'desc' },
        });

        const filtered = rows.filter((s) => departmentsMatch(s.department, hod.department));
        return sendSuccess(res, filtered);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const approveStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentId = parseInt(String(req.params.studentId), 10);
        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });
        
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return sendError(res, 'Student not found in your department.', 404);
        }

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: 'APPROVED' },
        });

        await prisma.user.update({
            where: { id: student.userId },
            data: { verification_status: 'APPROVED' },
        });

        // Notify the student that they've been approved
        await sendNotification(
            student.userId,
            `✅ Your registration has been approved by your Head of Department. You can now log in to access the system.`
        );

        // Send approval email (fire-and-forget)
        sendStudentHodDecisionEmail({
            to: student.user.email,
            studentName: student.user.full_name,
            universityName: hod.university.name,
            department: hod.department,
            decision: 'approved',
        }).catch((e: any) => console.error('Approval email error:', e?.message));

        return sendSuccess(res, { studentId }, 'Student approved.');
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const rejectStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentId = parseInt(String(req.params.studentId), 10);
        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });

        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return sendError(res, 'Student not found in your department.', 404);
        }

        const reason = typeof req.body?.reason === 'string' ? req.body.reason.trim() : '';

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: 'REJECTED' },
        });

        await sendNotification(student.userId, `Your registration was not approved.${reason ? ` Reason: ${reason}` : ''}`);

        await sendStudentHodDecisionEmail({
            to: student.user.email,
            studentName: student.user.full_name,
            universityName: hod.university.name,
            department: hod.department,
            decision: 'rejected',
            reason,
        });

        return sendSuccess(res, { studentId }, 'Student rejected.');
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getCompanies = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
        const verifiedOnly = req.query.verifiedOnly !== 'false';

        const companies = await prisma.company.findMany({
            where: {
                ...(verifiedOnly ? { approval_status: 'APPROVED' } : {}),
                ...(q ? { name: { contains: q, mode: 'insensitive' } } : {}),
            },
            orderBy: { name: 'asc' },
            take: 200,
        });
        return sendSuccess(res, companies);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const sendProposal = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const { studentId, companyId, proposal_type, expected_duration_weeks, expected_outcomes } = req.body;
        const sid = parseInt(String(studentId), 10);
        const cid = parseInt(String(companyId), 10);

        const student = await prisma.student.findUnique({ where: { id: sid } });
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return sendError(res, 'Student not found in your department.', 400);
        }
        
        if (student.hod_approval_status !== 'APPROVED') {
            return sendError(res, 'Student must be approved by HOD before placement.', 400);
        }

        if (student.internship_status === 'PLACED') {
            return sendError(res, 'This student already has an active internship placement.', 400);
        }

        const company = await prisma.company.findUnique({ where: { id: cid } });
        if (!company || company.approval_status !== 'APPROVED') {
            return sendError(res, 'Company must be verified (approved).', 400);
        }

        const pendingDup = await prisma.internshipProposal.findFirst({
            where: { studentId: sid, companyId: cid, status: 'PENDING' },
        });
        if (pendingDup) {
            return sendError(res, 'A pending proposal already exists.', 400);
        }

        const proposal = await prisma.internshipProposal.create({
            data: {
                studentId: sid,
                companyId: cid,
                universityId: hod.universityId,
                proposal_type: proposal_type || 'HoD_Initiated',
                status: 'PENDING',
                expected_duration_weeks: expected_duration_weeks != null ? parseInt(String(expected_duration_weeks), 10) : null,
                expected_outcomes: typeof expected_outcomes === 'string' ? expected_outcomes : null,
            },
        });

        return sendSuccess(res, proposal, 'Proposal sent.', 201);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getProposals = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const students = await prisma.student.findMany({
            where: { universityId: hod.universityId, department: { not: null } },
            select: { id: true, department: true },
        });
        const studentIds = students.filter((s) => departmentsMatch(s.department, hod.department)).map((s) => s.id);

        const proposals = await prisma.internshipProposal.findMany({
            where: { studentId: { in: studentIds } },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: { select: { id: true, name: true, official_email: true, approval_status: true } },
            },
            orderBy: { submitted_at: 'desc' },
        });
        return sendSuccess(res, proposals);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const inviteCompany = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const { email, company_name } = req.body;
        if (!email || !company_name) return sendError(res, 'email and company_name are required', 400);

        const existing = await prisma.company.findFirst({ where: { official_email: email } });
        if (existing) return sendError(res, 'A company with this email already exists.', 400);

        const company = await prisma.company.create({
            data: { name: company_name, official_email: email, approval_status: 'PENDING' },
        });

        const hodUser = await prisma.user.findUnique({ where: { id: uid } });
        await sendCompanyInviteEmail({
            to: email,
            companyName: company_name,
            universityName: hod.university.name,
            hodName: hodUser?.full_name ?? 'Head of Department',
        });

        return sendSuccess(res, { companyId: company.id }, 'Invitation sent.', 201);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getOpenLetterProposals = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const students = await prisma.student.findMany({
            where: { universityId: hod.universityId, department: { not: null } },
            select: { id: true, department: true },
        });
        const studentIds = students.filter((s) => departmentsMatch(s.department, hod.department)).map((s) => s.id);

        const proposals = await prisma.internshipProposal.findMany({
            where: { studentId: { in: studentIds }, proposal_type: 'Open_Letter' },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: true,
            },
            orderBy: { submitted_at: 'desc' },
        });
        return sendSuccess(res, proposals);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const updateOpenLetterProposal = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const id = parseInt(String(req.params.id), 10);
        const { status } = req.body as { status?: ApprovalStatus };
        
        if (Number.isNaN(id) || !status || !['APPROVED', 'REJECTED'].includes(status)) {
            return sendError(res, 'Valid status (APPROVED|REJECTED) required', 400);
        }

        const proposal = await prisma.internshipProposal.findUnique({ where: { id } });
        if (!proposal || proposal.proposal_type !== 'Open_Letter') {
            return sendError(res, 'Open letter proposal not found.', 404);
        }

        const student = await prisma.student.findUnique({ where: { id: proposal.studentId } });
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return sendError(res, 'Unauthorized.', 403);
        }

        const updated = await prisma.internshipProposal.update({
            where: { id },
            data: { status, responded_at: new Date() },
        });
        return sendSuccess(res, updated);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getReports = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentsInDept = await prisma.student.findMany({
            where: { universityId: hod.universityId, department: { not: null } },
            select: { id: true, department: true },
        });
        const deptIds = studentsInDept.filter((s) => departmentsMatch(s.department, hod.department)).map((s) => s.id);
        
        const reports = deptIds.length === 0 ? [] : await prisma.report.findMany({
            where: { studentId: { in: deptIds } },
            include: { student: { include: { user: { select: { full_name: true, email: true } } } } },
            orderBy: { generated_at: 'desc' },
        });
        return sendSuccess(res, reports);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getReportDownload = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const id = parseInt(String(req.params.id), 10);
        const report = await prisma.report.findUnique({
            where: { id },
            include: { student: true },
        });
        
        if (!report) return sendError(res, 'Report not found', 404);
        if (report.student.universityId !== hod.universityId || !departmentsMatch(report.student.department, hod.department)) {
            return sendError(res, 'Unauthorized', 403);
        }

        return sendSuccess(res, { pdf_url: report.pdf_url, stamped: report.stamped, generated_at: report.generated_at });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};
