import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendOrganizationApprovalEmail, sendOrganizationRejectionEmail } from '../services/email.service';
import {
    assertCompanyVerificationProposalExists,
    assertUniversityVerificationProposalExists,
} from '../utils/institutionVerification';
import { attachVerificationSla } from '../utils/verificationSla';

// --- INSTITUTION MANAGEMENT ---

// Get all pending Universities and Companies
export const getDashboardStats = async (req: AuthRequest, res: Response) => {
    try {
        const [
            pendingUniversities,
            pendingCompanies,
            totalUsers,
            approvedUniversities,
            approvedCompanies,
            totalStudents,
            activeInternships,
        ] = await Promise.all([
            prisma.university.count({ where: { approval_status: 'PENDING' } }),
            prisma.company.count({ where: { approval_status: 'PENDING' } }),
            prisma.user.count(),
            prisma.university.count({ where: { approval_status: 'APPROVED' } }),
            prisma.company.count({ where: { approval_status: 'APPROVED' } }),
            prisma.student.count(),
            prisma.internshipAssignment.count({ where: { status: 'ACTIVE' } }),
        ]);

        res.json({
            pendingUniversities,
            pendingCompanies,
            totalUsers,
            approvedUniversities,
            approvedCompanies,
            totalStudents,
            activeInternships,
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** List universities (optional ?status=PENDING|APPROVED|REJECTED|SUSPENDED) */
export const listUniversities = async (req: AuthRequest, res: Response) => {
    try {
        const raw = req.query.status as string | undefined;
        const allowed = ['PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED'] as const;
        const status = raw && allowed.includes(raw as (typeof allowed)[number]) ? raw : undefined;
        const universities = await prisma.university.findMany({
            where: status ? { approval_status: status as 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED' } : {},
            orderBy: { created_at: 'desc' },
        });
        res.json(universities.map((u) => attachVerificationSla(u)));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** List companies (optional ?status=) */
export const listCompanies = async (req: AuthRequest, res: Response) => {
    try {
        const raw = req.query.status as string | undefined;
        const allowed = ['PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED'] as const;
        const status = raw && allowed.includes(raw as (typeof allowed)[number]) ? raw : undefined;
        const companies = await prisma.company.findMany({
            where: status ? { approval_status: status as 'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED' } : {},
            orderBy: { created_at: 'desc' },
        });
        res.json(companies.map((c) => attachVerificationSla(c)));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const getAuditLogs = async (req: AuthRequest, res: Response) => {
    try {
        const take = Math.min(500, Math.max(1, parseInt(String(req.query.take || '100'), 10) || 100));
        const logs = await prisma.auditLog.findMany({
            orderBy: { timestamp: 'desc' },
            take,
        });
        const adminIds = [...new Set(logs.map((l) => l.adminId))];
        const admins = await prisma.user.findMany({
            where: { id: { in: adminIds } },
            select: { id: true, full_name: true, email: true },
        });
        const adminMap = new Map(admins.map((a) => [a.id, a]));
        res.json(
            logs.map((l) => ({
                ...l,
                admin: adminMap.get(l.adminId) ?? null,
            }))
        );
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// List all pending universities (includes 24h SLA response window metadata)
export const getPendingUniversities = async (req: AuthRequest, res: Response) => {
    const universities = await prisma.university.findMany({
        where: { approval_status: 'PENDING' }
    });
    res.json(universities.map((u) => attachVerificationSla(u)));
};

// List all pending companies (includes 24h SLA response window metadata)
export const getPendingCompanies = async (req: AuthRequest, res: Response) => {
    const companies = await prisma.company.findMany({
        where: { approval_status: 'PENDING' }
    });
    res.json(companies.map((c) => attachVerificationSla(c)));
};

// Approve, Reject, Suspend, or reactivate (APPROVED from SUSPENDED) a university
export const updateUniversityStatus = async (req: AuthRequest, res: Response) => {
    const { id } = req.params;
    const { status, reason } = req.body; // 'APPROVED' | 'REJECTED' | 'SUSPENDED'
    try {
        const universityId = Array.isArray(id) ? id[0] : id;
        const uid = parseInt(universityId);
        const rejectionReason = typeof reason === 'string' ? reason : '';

        const existing = await prisma.university.findUnique({ where: { id: uid } });
        if (!existing) {
            return res.status(404).json({ error: 'University not found' });
        }

        if (status === 'SUSPENDED' && existing.approval_status !== 'APPROVED') {
            return res.status(400).json({ error: 'Only approved organizations can be suspended.' });
        }

        if (status === 'APPROVED') {
            if (existing.approval_status !== 'SUSPENDED') {
                try {
                    await assertUniversityVerificationProposalExists(uid);
                } catch (e: any) {
                    return res.status(400).json({ error: e.message || 'Approval validation failed' });
                }
            }
        }

        const updated = await prisma.university.update({
            where: { id: uid },
            data: {
                approval_status: status,
                ...(status === 'REJECTED'
                    ? {
                          rejection_reason: rejectionReason,
                          verification_doc: null,
                      }
                    : status === 'SUSPENDED'
                      ? {}
                      : {
                            rejection_reason: null,
                        }),
            },
        });
        if (status === 'APPROVED' && existing.approval_status === 'PENDING') {
            await sendOrganizationApprovalEmail(updated.official_email, updated.name, 'University');
        }
        if (status === 'REJECTED') {
            await sendOrganizationRejectionEmail(
                updated.official_email,
                updated.name,
                'University',
                updated.rejection_reason ?? rejectionReason
            );
        }
        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: `${status}_UNIVERSITY`,
                targetId: uid,
                details: `${updated.name}: ${status}${status === 'REJECTED' && rejectionReason ? ` — ${rejectionReason}` : ''}`,
            },
        });
        res.json({ message: `University ${status}`, updated });
    } catch (error: any) {
        res.status(400).json({ error: "Update failed" });
    }
};

// Approve, Reject, Suspend, or reactivate a company
export const updateCompanyStatus = async (req: AuthRequest, res: Response) => {
    const { id } = req.params;
    const { status, reason } = req.body;
    try {
        const companyId = Array.isArray(id) ? id[0] : id;
        const cid = parseInt(companyId);
        const rejectionReason = typeof reason === 'string' ? reason : '';

        const existing = await prisma.company.findUnique({ where: { id: cid } });
        if (!existing) {
            return res.status(404).json({ error: 'Company not found' });
        }

        if (status === 'SUSPENDED' && existing.approval_status !== 'APPROVED') {
            return res.status(400).json({ error: 'Only approved organizations can be suspended.' });
        }

        if (status === 'APPROVED') {
            if (existing.approval_status !== 'SUSPENDED') {
                try {
                    await assertCompanyVerificationProposalExists(cid);
                } catch (e: any) {
                    return res.status(400).json({ error: e.message || 'Approval validation failed' });
                }
            }
        }

        const updated = await prisma.company.update({
            where: { id: cid },
            data: {
                approval_status: status,
                ...(status === 'REJECTED'
                    ? {
                          rejection_reason: rejectionReason,
                          verification_doc: null,
                      }
                    : status === 'SUSPENDED'
                      ? {}
                      : {
                            rejection_reason: null,
                        }),
            }
        });
        if (status === 'APPROVED' && existing.approval_status === 'PENDING') {
            await sendOrganizationApprovalEmail(updated.official_email, updated.name, 'Company');
        }
        if (status === 'REJECTED') {
            await sendOrganizationRejectionEmail(
                updated.official_email,
                updated.name,
                'Company',
                updated.rejection_reason ?? rejectionReason
            );
        }
        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: `${status}_COMPANY`,
                targetId: cid,
                details: `${updated.name}: ${status}${status === 'REJECTED' && rejectionReason ? ` — ${rejectionReason}` : ''}`,
            },
        });
        res.json({ message: `Company ${status}`, updated });
    } catch (error: any) {
        res.status(400).json({ error: "Update failed" });
    }
};

// --- USER MANAGEMENT ---

// View all users in the system
export const getAllUsers = async (req: AuthRequest, res: Response) => {
    const users = await prisma.user.findMany({
        select: {
            id: true,
            full_name: true,
            email: true,
            role: true,
            verification_status: true,
            institution_access_approval: true,
            created_at: true,
        },
    });
    res.json(users);
};

/** Approve or reject individual coordinator/supervisor access (after org verification). */
export const updateUserInstitutionAccess = async (req: AuthRequest, res: Response) => {
    try {
        const rawId = req.params.id;
        const userId = parseInt(Array.isArray(rawId) ? rawId[0] : rawId, 10);
        const { status } = req.body as { status?: string };
        if (!status || !['APPROVED', 'REJECTED'].includes(status)) {
            return res.status(400).json({ error: 'Body must include status: APPROVED or REJECTED' });
        }
        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user || (user.role !== 'COORDINATOR' && user.role !== 'SUPERVISOR')) {
            return res.status(400).json({ error: 'User must be a coordinator or supervisor' });
        }
        const updated = await prisma.user.update({
            where: { id: userId },
            data: { institution_access_approval: status as 'APPROVED' | 'REJECTED' },
        });
        res.json({ message: `Institution access ${status}`, user: updated });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// --- SYSTEM ANNOUNCEMENTS (SRS FR-7.2) ---
export const postAnnouncement = async (req: AuthRequest, res: Response) => {
    const { title, content } = req.body;
    try {
        const announcement = await prisma.announcement.create({
            data: {
                title,
                content,
                authorId: req.user!.userId
            }
        });
        res.status(201).json(announcement);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};


export const verifyInstitution = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { type, status, reason } = req.body; // type: 'UNIVERSITY' | 'COMPANY', status includes SUSPENDED
        const adminId = req.user!.userId;

        let updatedRecord;

        const institutionId = Array.isArray(id) ? id[0] : id;
        const reasonStr = typeof reason === 'string' ? reason : '';
        const iid = parseInt(institutionId);

        const existing =
            type === 'UNIVERSITY'
                ? await prisma.university.findUnique({ where: { id: iid } })
                : await prisma.company.findUnique({ where: { id: iid } });
        if (!existing) {
            return res.status(404).json({ error: 'Institution not found' });
        }

        if (status === 'SUSPENDED' && existing.approval_status !== 'APPROVED') {
            return res.status(400).json({ error: 'Only approved organizations can be suspended.' });
        }

        if (status === 'APPROVED' && existing.approval_status !== 'SUSPENDED') {
            try {
                if (type === 'UNIVERSITY') {
                    await assertUniversityVerificationProposalExists(iid);
                } else {
                    await assertCompanyVerificationProposalExists(iid);
                }
            } catch (e: any) {
                return res.status(400).json({ error: e.message || 'Approval validation failed' });
            }
        }

        const statusData =
            status === 'REJECTED'
                ? { rejection_reason: reasonStr, verification_doc: null }
                : status === 'SUSPENDED'
                  ? {}
                  : { rejection_reason: null };

        if (type === 'UNIVERSITY') {
            updatedRecord = await prisma.university.update({
                where: { id: iid },
                data: {
                    approval_status: status,
                    ...statusData,
                },
            });
        } else {
            updatedRecord = await prisma.company.update({
                where: { id: iid },
                data: {
                    approval_status: status,
                    ...statusData,
                },
            });
        }

        await prisma.auditLog.create({
            data: {
                adminId,
                action: `${status}_${type}`,
                targetId: iid,
                details:
                    status === 'REJECTED'
                        ? `Reason: ${reason}`
                        : status === 'SUSPENDED'
                          ? 'Organization suspended by admin'
                          : `Processed ${type} as ${status}`,
            },
        });

        if (status === 'APPROVED' && existing.approval_status === 'PENDING') {
            const kind = type === 'UNIVERSITY' ? 'University' : 'Company';
            await sendOrganizationApprovalEmail(updatedRecord.official_email, updatedRecord.name, kind);
        }
        if (status === 'REJECTED') {
            const kind = type === 'UNIVERSITY' ? 'University' : 'Company';
            await sendOrganizationRejectionEmail(
                updatedRecord.official_email,
                updatedRecord.name,
                kind,
                updatedRecord.rejection_reason ?? reasonStr
            );
        }

        res.json({ message: `Verification processed as ${status}`, updatedRecord });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};