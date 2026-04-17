import { Response } from 'express';
import prisma from '../config/db';
import { AuthRequest } from '../middlewares/authMiddleware';
import type { ApprovalStatus } from '@prisma/client';
import { departmentsMatch } from '../utils/hodScope';
import { sendCompanyInviteEmail } from '../services/email.service';
import { sendNotification } from '../utils/notificationHelper';
import { sendStudentHodDecisionEmail } from '../services/email.service';

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
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const { studentId, status, reason } = req.body as {
            studentId?: number;
            status?: string;
            reason?: string;
        };

        if (!studentId || !status || !['APPROVED', 'REJECTED'].includes(status)) {
            return res.status(400).json({ error: 'studentId and status (APPROVED | REJECTED) are required.' });
        }

        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return res.status(404).json({ error: 'Student not in your department.' });
        }

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: status as ApprovalStatus },
        });

        // Notify the student via in-app + email
        const msg = status === 'APPROVED'
            ? `Your registration has been approved by your Head of Department. You can now access InternLink features.`
            : `Your registration was not approved by your Head of Department. Reason: ${reason?.trim() || 'No reason provided.'}`;
        await sendNotification(student.userId, msg);

        await sendStudentHodDecisionEmail({
            to: student.user.email,
            studentName: student.user.full_name,
            universityName: hod.university.name,
            department: hod.department,
            decision: status === 'APPROVED' ? 'approved' : 'rejected',
            reason: reason?.trim(),
        });

        res.json({ message: `Student ${status.toLowerCase()}.`, studentId, status });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getDashboardStats = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const baseStudentWhere = {
            universityId: hod.universityId,
            department: { not: null },
        };

        const students = await prisma.student.findMany({
            where: baseStudentWhere,
            select: { id: true, department: true, hod_approval_status: true, internship_status: true },
        });
        const inDept = students.filter((s) => departmentsMatch(s.department, hod.department));

        const totalStudents = inDept.length;
        const pendingApprovals = inDept.filter((s) => s.hod_approval_status === 'PENDING').length;
        const placedStudents = inDept.filter((s) => s.internship_status === 'PLACED').length;

        const deptStudentIds = inDept.map((s) => s.id);
        const reportCount =
            deptStudentIds.length === 0
                ? 0
                : await prisma.report.count({
                      where: { studentId: { in: deptStudentIds } },
                  });

        res.json({
            totalStudents,
            pendingApprovals,
            placedStudents,
            reports: reportCount,
        });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getStudents = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const status = (req.query.status as string) || 'all';
        const hodApprovalFilter: ApprovalStatus | 'all' | undefined =
            status === 'pending'
                ? 'PENDING'
                : status === 'approved'
                  ? 'APPROVED'
                  : status === 'rejected'
                    ? 'REJECTED'
                    : 'all';

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
        res.json(filtered);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const approveStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const studentId = parseInt(String(req.params.studentId), 10);
        if (Number.isNaN(studentId)) return res.status(400).json({ error: 'Invalid student id' });

        const student = await prisma.student.findUnique({ where: { id: studentId } });
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return res.status(404).json({ error: 'Student not in your department.' });
        }

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: 'APPROVED' },
        });
        res.json({ message: 'Student approved.', studentId });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const rejectStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const studentId = parseInt(String(req.params.studentId), 10);
        if (Number.isNaN(studentId)) return res.status(400).json({ error: 'Invalid student id' });

        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return res.status(404).json({ error: 'Student not in your department.' });
        }

        const reason = typeof req.body?.reason === 'string' ? req.body.reason.trim() : '';

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: 'REJECTED' },
        });

        await sendNotification(student.userId,
            `Your registration was not approved by your Head of Department.${reason ? ` Reason: ${reason}` : ''}`
        );

        await sendStudentHodDecisionEmail({
            to: student.user.email,
            studentName: student.user.full_name,
            universityName: hod.university.name,
            department: hod.department,
            decision: 'rejected',
            reason,
        });

        res.json({ message: 'Student rejected.', studentId });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getCompanies = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
        const verifiedOnly = req.query.verifiedOnly !== 'false';

        const companies = await prisma.company.findMany({
            where: {
                ...(verifiedOnly ? { approval_status: 'APPROVED' } : {}),
                ...(q
                    ? {
                          name: { contains: q, mode: 'insensitive' },
                      }
                    : {}),
            },
            orderBy: { name: 'asc' },
            take: 200,
        });
        res.json(companies);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const sendProposal = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const { studentId, companyId, proposal_type, expected_duration_weeks, expected_outcomes } = req.body;
        const sid = parseInt(String(studentId), 10);
        const cid = parseInt(String(companyId), 10);
        if (Number.isNaN(sid) || Number.isNaN(cid)) {
            return res.status(400).json({ error: 'studentId and companyId are required' });
        }

        const student = await prisma.student.findUnique({ where: { id: sid } });
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return res.status(400).json({ error: 'Student not in your department or not found.' });
        }
        if (student.hod_approval_status !== 'APPROVED') {
            return res.status(400).json({ error: 'Student must be approved by HOD before placement.' });
        }

        const company = await prisma.company.findUnique({ where: { id: cid } });
        if (!company || company.approval_status !== 'APPROVED') {
            return res.status(400).json({ error: 'Company must be verified (approved).' });
        }

        const pendingDup = await prisma.internshipProposal.findFirst({
            where: { studentId: sid, companyId: cid, status: 'PENDING' },
        });
        if (pendingDup) {
            return res.status(400).json({ error: 'A pending proposal already exists for this student and company.' });
        }

        const proposal = await prisma.internshipProposal.create({
            data: {
                studentId: sid,
                companyId: cid,
                universityId: hod.universityId,
                proposal_type: proposal_type || 'University_Initiated',
                status: 'PENDING',
                expected_duration_weeks:
                    expected_duration_weeks != null ? parseInt(String(expected_duration_weeks), 10) : null,
                expected_outcomes: typeof expected_outcomes === 'string' ? expected_outcomes : null,
            },
        });

        res.status(201).json({ message: 'Proposal sent.', proposal });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getProposals = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

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
        res.json(proposals);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const inviteCompany = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const { email, company_name } = req.body;
        if (!email || !company_name) {
            return res.status(400).json({ error: 'email and company_name are required' });
        }

        const existing = await prisma.company.findFirst({
            where: { official_email: email },
        });
        if (existing) {
            return res.status(400).json({ error: 'A company with this email already exists.' });
        }

        const company = await prisma.company.create({
            data: {
                name: company_name,
                official_email: email,
                approval_status: 'PENDING',
            },
        });

        const hodUser = await prisma.user.findUnique({ where: { id: uid } });
        await sendCompanyInviteEmail({
            to: email,
            companyName: company_name,
            universityName: hod.university.name,
            hodName: hodUser?.full_name ?? 'Head of Department',
        });

        res.status(201).json({ message: 'Invitation sent.', companyId: company.id });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getOpenLetterProposals = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const students = await prisma.student.findMany({
            where: { universityId: hod.universityId, department: { not: null } },
            select: { id: true, department: true },
        });
        const studentIds = students.filter((s) => departmentsMatch(s.department, hod.department)).map((s) => s.id);

        const proposals = await prisma.internshipProposal.findMany({
            where: {
                studentId: { in: studentIds },
                proposal_type: 'Open_Letter',
            },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: true,
            },
            orderBy: { submitted_at: 'desc' },
        });
        res.json(proposals);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const updateOpenLetterProposal = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const id = parseInt(String(req.params.id), 10);
        const { status } = req.body as { status?: ApprovalStatus };
        if (Number.isNaN(id) || !status || !['APPROVED', 'REJECTED'].includes(status)) {
            return res.status(400).json({ error: 'Valid status (APPROVED|REJECTED) required' });
        }

        const proposal = await prisma.internshipProposal.findUnique({ where: { id } });
        if (!proposal || proposal.proposal_type !== 'Open_Letter') {
            return res.status(404).json({ error: 'Open letter proposal not found.' });
        }

        const student = await prisma.student.findUnique({ where: { id: proposal.studentId } });
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return res.status(403).json({ error: 'Not allowed.' });
        }

        const updated = await prisma.internshipProposal.update({
            where: { id },
            data: {
                status,
                responded_at: new Date(),
            },
        });
        res.json(updated);
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};

export const getReports = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const studentsInDept = await prisma.student.findMany({
            where: {
                universityId: hod.universityId,
                department: { not: null },
            },
            select: { id: true, department: true },
        });
        const deptIds = studentsInDept
            .filter((s) => departmentsMatch(s.department, hod.department))
            .map((s) => s.id);
        const reports =
            deptIds.length === 0
                ? []
                : await prisma.report.findMany({
                      where: { studentId: { in: deptIds } },
                      include: {
                          student: {
                              include: { user: { select: { full_name: true, email: true } } },
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

export const getReportDownload = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return res.status(401).json({ error: 'Unauthorized' });
        const hod = await getHodOr403(uid);
        if (!hod) return res.status(403).json({ error: 'HOD profile not found.' });

        const id = parseInt(String(req.params.id), 10);
        if (Number.isNaN(id)) return res.status(400).json({ error: 'Invalid id' });

        const report = await prisma.report.findUnique({
            where: { id },
            include: { student: true },
        });
        if (!report) return res.status(404).json({ error: 'Report not found' });
        if (
            report.student.universityId !== hod.universityId ||
            !departmentsMatch(report.student.department, hod.department)
        ) {
            return res.status(403).json({ error: 'Not allowed' });
        }

        res.json({ pdf_url: report.pdf_url, stamped: report.stamped, generated_at: report.generated_at });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};
