import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendOrganizationApprovalEmail, sendOrganizationRejectionEmail } from '../services/email.service';
import {
    checkCompanyVerification,
    checkUniversityVerification,
} from '../utils/institutionVerification';
import { attachVerificationSla } from '../utils/verificationSla';
import { UploadResult } from '../services/cloudinary.service';
import { sendNotification } from '../utils/notificationHelper';

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
            pendingCoordinators,
            pendingSupervisors,
            totalEvaluations,
            totalReports,
            pendingOrganizationRequests,
        ] = await Promise.all([
            prisma.university.count({ where: { approval_status: 'PENDING' } }),
            prisma.company.count({ where: { approval_status: 'PENDING' } }),
            prisma.user.count(),
            prisma.university.count({ where: { approval_status: 'APPROVED' } }),
            prisma.company.count({ where: { approval_status: 'APPROVED' } }),
            prisma.student.count(),
            prisma.internshipAssignment.count({ where: { status: 'ACTIVE' } }),
            prisma.coordinator.count({
                where: {
                    user: { institution_access_approval: 'PENDING', role: 'COORDINATOR' },
                },
            }),
            prisma.supervisor.count({
                where: { user: { institution_access_approval: 'PENDING' } },
            }),
            prisma.finalEvaluation.count(),
            prisma.report.count(),
            prisma.organizationRequest.count({ where: { status: 'PENDING' } }),
        ]);

        res.json({
            pendingUniversities,
            pendingCompanies,
            totalUsers,
            approvedUniversities,
            approvedCompanies,
            totalStudents,
            activeInternships,
            pendingCoordinators,
            pendingSupervisors,
            pendingHods: await prisma.hodProfile.count({ where: { user: { institution_access_approval: 'PENDING' } } }),
            totalEvaluations,
            totalReports,
            pendingOrganizationRequests,
            rejectedCoordinators: await prisma.user.count({ where: { role: 'COORDINATOR', institution_access_approval: 'REJECTED' } }),
            rejectedSupervisors: await prisma.user.count({ where: { role: 'SUPERVISOR', institution_access_approval: 'REJECTED' } }),
            rejectedHods: await prisma.user.count({ where: { role: 'HOD', institution_access_approval: 'REJECTED' } }),
            suspendedCoordinators: await prisma.user.count({ where: { role: 'COORDINATOR', institution_access_approval: 'SUSPENDED' } }),
            suspendedSupervisors: await prisma.user.count({ where: { role: 'SUPERVISOR', institution_access_approval: 'SUSPENDED' } }),
            suspendedHods: await prisma.user.count({ where: { role: 'HOD', institution_access_approval: 'SUSPENDED' } }),
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
            include: {
                coordinators: {
                    take: 1,
                    include: { user: { select: { verification_document: true } } },
                },
            },
        });
        const rows = universities.map((u) => {
            // Fall back to coordinator's verification_document if university has none
            const fallbackDoc = u.coordinators[0]?.user?.verification_document ?? null;
            const { coordinators, ...rest } = u;
            return attachVerificationSla({ ...rest, verification_doc: rest.verification_doc ?? fallbackDoc });
        });
        res.json({ success: true, data: rows });
    } catch (error: any) {
        res.status(500).json({ success: false, error: error.message });
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
            include: {
                supervisors: {
                    take: 1,
                    include: { user: { select: { verification_document: true } } },
                },
            },
        });
        const rows = companies.map((c) => {
            // Fall back to supervisor's verification_document if company has none
            const fallbackDoc = c.supervisors[0]?.user?.verification_document ?? null;
            const { supervisors, ...rest } = c;
            return attachVerificationSla({ ...rest, verification_doc: rest.verification_doc ?? fallbackDoc });
        });
        res.json({ success: true, data: rows });
    } catch (error: any) {
        res.status(500).json({ success: false, error: error.message });
    }
};

export const getAuditLogs = async (req: AuthRequest, res: Response) => {
    try {
        const take = Math.min(1000, Math.max(1, parseInt(String(req.query.take || '500'), 10) || 500));
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
    try {
        const universities = await prisma.university.findMany({
            where: { approval_status: 'PENDING' }
        });
        res.json({ success: true, data: universities.map((u) => attachVerificationSla(u)) });
    } catch (error: any) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// List all pending companies (includes 24h SLA response window metadata)
export const getPendingCompanies = async (req: AuthRequest, res: Response) => {
    try {
        const companies = await prisma.company.findMany({
            where: { approval_status: 'PENDING' }
        });
        res.json({ success: true, data: companies.map((c) => attachVerificationSla(c)) });
    } catch (error: any) {
        res.status(500).json({ success: false, error: error.message });
    }
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
            // Already suspended — treat as no-op instead of erroring
            if (existing.approval_status === 'SUSPENDED') {
                return res.json({ success: true, message: 'University is already suspended', data: existing });
            }
            return res.status(400).json({ error: 'Only approved organizations can be suspended.' });
        }

        if (status === 'APPROVED') {
            if (existing.approval_status !== 'SUSPENDED') {
                const check = await checkUniversityVerification(uid);
                if (!check.verified && check.warning) {
                    console.warn(`[Admin Approval] University ${uid}: ${check.warning}`);
                }
            }
        }

        // When approving, pull verification_doc from the linked coordinator if not already set
        let coordVerificationDoc: string | null = null;
        if (status === 'APPROVED' && existing.verification_doc == null) {
            const coordinator = await prisma.coordinator.findFirst({
                where: { universityId: uid },
                include: { user: { select: { verification_document: true } } },
            });
            coordVerificationDoc = coordinator?.user?.verification_document ?? null;
        }

        const updated = await prisma.university.update({
            where: { id: uid },
            data: {
                approval_status: status,
                ...(status === 'REJECTED'
                    ? { rejection_reason: rejectionReason, verification_doc: null }
                    : status === 'SUSPENDED'
                      ? {}
                      : {
                            rejection_reason: null,
                            ...(coordVerificationDoc ? { verification_doc: coordVerificationDoc } : {}),
                        }),
            },
        });
        if (status === 'APPROVED' && existing.approval_status === 'PENDING') {
            await sendOrganizationApprovalEmail(updated.official_email, updated.name, 'University');
            // Notify the coordinator linked to this university
            const coordinator = await prisma.coordinator.findFirst({
                where: { universityId: uid },
                select: { userId: true },
            });
            if (coordinator) {
                await sendNotification(coordinator.userId, `✅ Your university "${updated.name}" has been approved. You can now access the platform.`);
            }
        }
        if (status === 'REJECTED') {
            await sendOrganizationRejectionEmail(
                updated.official_email,
                updated.name,
                'University',
                updated.rejection_reason ?? rejectionReason
            );
            const coordinator = await prisma.coordinator.findFirst({
                where: { universityId: uid },
                select: { userId: true },
            });
            if (coordinator) {
                await sendNotification(coordinator.userId, `❌ Your university "${updated.name}" registration was not approved.${rejectionReason ? ` Reason: ${rejectionReason}` : ''}`);
            }
        }
        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: `${status}_UNIVERSITY`,
                targetId: uid,
                details: `${updated.name}: ${status}${status === 'REJECTED' && rejectionReason ? ` — ${rejectionReason}` : ''}`,
            },
        });
        res.json({ success: true, message: `University ${status}`, data: updated });
    } catch (error: any) {
        console.error('[updateUniversityStatus] Error:', error?.message || error);
        res.status(500).json({ success: false, error: error?.message || 'Update failed' });
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
            if (existing.approval_status === 'SUSPENDED') {
                return res.json({ success: true, message: 'Company is already suspended', data: existing });
            }
            return res.status(400).json({ error: 'Only approved organizations can be suspended.' });
        }

        if (status === 'APPROVED') {
            if (existing.approval_status !== 'SUSPENDED') {
                const check = await checkCompanyVerification(cid);
                if (!check.verified && check.warning) {
                    console.warn(`[Admin Approval] Company ${cid}: ${check.warning}`);
                }
            }
        }

        // When approving, pull verification_doc from the linked supervisor if not already set
        let supVerificationDoc: string | null = null;
        if (status === 'APPROVED' && existing.verification_doc == null) {
            const supervisor = await prisma.supervisor.findFirst({
                where: { companyId: cid },
                include: { user: { select: { verification_document: true } } },
            });
            supVerificationDoc = supervisor?.user?.verification_document ?? null;
        }

        const updated = await prisma.company.update({
            where: { id: cid },
            data: {
                approval_status: status,
                ...(status === 'REJECTED'
                    ? { rejection_reason: rejectionReason, verification_doc: null }
                    : status === 'SUSPENDED'
                      ? {}
                      : {
                            rejection_reason: null,
                            ...(supVerificationDoc ? { verification_doc: supVerificationDoc } : {}),
                        }),
            }
        });
        if (status === 'APPROVED' && existing.approval_status === 'PENDING') {
            await sendOrganizationApprovalEmail(updated.official_email, updated.name, 'Company');
            // Notify supervisors linked to this company
            const supervisors = await prisma.supervisor.findMany({
                where: { companyId: cid },
                select: { userId: true },
            });
            for (const sup of supervisors) {
                await sendNotification(sup.userId, `✅ Your company "${updated.name}" has been approved. You can now access the platform.`);
            }
        }
        if (status === 'REJECTED') {
            await sendOrganizationRejectionEmail(
                updated.official_email,
                updated.name,
                'Company',
                updated.rejection_reason ?? rejectionReason
            );
            const supervisors = await prisma.supervisor.findMany({
                where: { companyId: cid },
                select: { userId: true },
            });
            for (const sup of supervisors) {
                await sendNotification(sup.userId, `❌ Your company "${updated.name}" registration was not approved.${rejectionReason ? ` Reason: ${rejectionReason}` : ''}`);
            }
        }
        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: `${status}_COMPANY`,
                targetId: cid,
                details: `${updated.name}: ${status}${status === 'REJECTED' && rejectionReason ? ` — ${rejectionReason}` : ''}`,
            },
        });
        res.json({ success: true, message: `Company ${status}`, data: updated });
    } catch (error: any) {
        console.error('[updateCompanyStatus] Error:', error?.message || error);
        res.status(500).json({ success: false, error: error?.message || 'Update failed' });
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
            verification_document: true,
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

        const roleLabel = user.role.charAt(0) + user.role.slice(1).toLowerCase();
        if (status === 'APPROVED') {
            await sendNotification(userId, `✅ Your ${roleLabel} account has been approved by the admin. You can now log in and access the platform.`);
        } else {
            await sendNotification(userId, `❌ Your ${roleLabel} account access was not approved by the admin. Please contact support for more information.`);
        }

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
            // Non-blocking: warn but allow admin to approve regardless
            if (type === 'UNIVERSITY') {
                const check = await checkUniversityVerification(iid);
                if (!check.verified && check.warning) {
                    console.warn(`[Admin Approval] University ${iid}: ${check.warning}`);
                }
            } else {
                const check = await checkCompanyVerification(iid);
                if (!check.verified && check.warning) {
                    console.warn(`[Admin Approval] Company ${iid}: ${check.warning}`);
                }
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

// --- SUPERVISOR APPROVAL WORKFLOW ---

/** List all approved supervisors */
export const getApprovedSupervisors = async (req: AuthRequest, res: Response) => {
    try {
        const supervisors = await prisma.supervisor.findMany({
            where: { user: { institution_access_approval: 'APPROVED' } },
            include: {
                user: {
                    select: {
                        id: true,
                        full_name: true,
                        email: true,
                        verification_document: true,
                        institution_access_approval: true,
                        created_at: true,
                    },
                },
                company: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(supervisors);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** List all rejected supervisors */
export const getRejectedSupervisors = async (req: AuthRequest, res: Response) => {
    try {
        const supervisors = await prisma.supervisor.findMany({
            where: { user: { institution_access_approval: 'REJECTED' } },
            include: {
                user: { select: { id: true, full_name: true, email: true, institution_access_approval: true, created_at: true } },
                company: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(supervisors);
    } catch (error: any) { res.status(500).json({ error: error.message }); }
};

/** List all suspended supervisors */
export const getSuspendedSupervisors = async (req: AuthRequest, res: Response) => {
    try {
        const supervisors = await prisma.supervisor.findMany({
            where: { user: { institution_access_approval: 'SUSPENDED' } },
            include: {
                user: { select: { id: true, full_name: true, email: true, institution_access_approval: true, created_at: true } },
                company: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(supervisors);
    } catch (error: any) { res.status(500).json({ error: error.message }); }
};

/** List all approved supervisors */
export const getPendingSupervisors = async (req: AuthRequest, res: Response) => {
    try {
        const supervisors = await prisma.supervisor.findMany({
            where: { user: { institution_access_approval: 'PENDING' } },
            include: {
                user: {
                    select: {
                        id: true,
                        full_name: true,
                        email: true,
                        verification_document: true,
                        institution_access_approval: true,
                        created_at: true,
                    },
                },
                company: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(supervisors);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** Approve a pending supervisor */
export const approveSupervisor = async (req: AuthRequest, res: Response) => {
    try {
        const rawId = req.params.userId;
        const userId = parseInt(Array.isArray(rawId) ? rawId[0] : rawId, 10);

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId },
            include: { user: true, company: true },
        });
        if (!supervisor) return res.status(404).json({ error: 'Supervisor not found' });

        // Approve the user and the company
        await prisma.user.update({
            where: { id: userId },
            data: { institution_access_approval: 'APPROVED', verification_status: 'APPROVED' },
        });

        await prisma.company.update({
            where: { id: supervisor.companyId },
            data: {
                approval_status: 'APPROVED',
                // Copy supervisor's verification doc to company if not already set
                ...(supervisor.company.verification_doc == null && supervisor.user.verification_document
                    ? { verification_doc: supervisor.user.verification_document }
                    : {}),
            },
        });

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'APPROVED_SUPERVISOR',
                targetId: userId,
                details: `Approved supervisor ${supervisor.user.full_name} — company "${supervisor.company.name}"`,
            },
        });

        await sendOrganizationApprovalEmail(supervisor.user.email, supervisor.company.name, 'Company');
        res.json({ message: 'Supervisor approved', userId });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** Reject a pending supervisor */
export const rejectSupervisor = async (req: AuthRequest, res: Response) => {
    try {
        const rawId = req.params.userId;
        const userId = parseInt(Array.isArray(rawId) ? rawId[0] : rawId, 10);
        const { reason } = req.body as { reason?: string };
        const rejectionReason = reason?.trim() || 'Your credentials could not be verified.';

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId },
            include: { user: true, company: true },
        });
        if (!supervisor) return res.status(404).json({ error: 'Supervisor not found' });

        await prisma.user.update({
            where: { id: userId },
            data: { institution_access_approval: 'REJECTED', verification_status: 'REJECTED' },
        });

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'REJECTED_SUPERVISOR',
                targetId: userId,
                details: `Rejected supervisor ${supervisor.user.full_name} — reason: ${rejectionReason}`,
            },
        });

        await sendOrganizationRejectionEmail(supervisor.user.email, supervisor.company.name, 'Company', rejectionReason);
        res.json({ message: 'Supervisor rejected', userId });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// --- COORDINATOR APPROVAL WORKFLOW ---

/** List all approved coordinators */
export const getApprovedCoordinators = async (req: AuthRequest, res: Response) => {
    try {
        const coordinators = await prisma.coordinator.findMany({
            where: { universityId: { not: null } },
            include: {
                user: {
                    select: {
                        id: true,
                        full_name: true,
                        email: true,
                        verification_status: true,
                        institution_access_approval: true,
                        verification_document: true,
                        created_at: true,
                    },
                },
                university: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(coordinators);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** List all rejected coordinators */
export const getRejectedCoordinators = async (req: AuthRequest, res: Response) => {
    try {
        const coordinators = await prisma.coordinator.findMany({
            where: { user: { institution_access_approval: 'REJECTED' } },
            include: {
                user: { select: { id: true, full_name: true, email: true, institution_access_approval: true, created_at: true } },
                university: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(coordinators);
    } catch (error: any) { res.status(500).json({ error: error.message }); }
};

/** List all suspended coordinators */
export const getSuspendedCoordinators = async (req: AuthRequest, res: Response) => {
    try {
        const coordinators = await prisma.coordinator.findMany({
            where: { user: { institution_access_approval: 'SUSPENDED' } },
            include: {
                user: { select: { id: true, full_name: true, email: true, institution_access_approval: true, created_at: true } },
                university: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(coordinators);
    } catch (error: any) { res.status(500).json({ error: error.message }); }
};

/** List all coordinators pending admin approval */
/** List all pending HODs */
export const getPendingHods = async (req: AuthRequest, res: Response) => {
    try {
        const hods = await prisma.hodProfile.findMany({
            where: { user: { institution_access_approval: 'PENDING' } },
            include: {
                user: {
                    select: {
                        id: true,
                        full_name: true,
                        email: true,
                        verification_status: true,
                        institution_access_approval: true,
                        verification_document: true,
                        created_at: true,
                    },
                },
                university: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(hods);
    } catch (error: any) { res.status(500).json({ error: error.message }); }
};

/** Approve a pending HOD */
export const approveHod = async (req: AuthRequest, res: Response) => {
    try {
        const rawId = req.params.userId;
        const userId = parseInt(Array.isArray(rawId) ? rawId[0] : rawId, 10);

        const hod = await prisma.hodProfile.findUnique({
            where: { userId },
            include: { user: true, university: true },
        });
        if (!hod) return res.status(404).json({ error: 'HOD not found' });

        await prisma.user.update({
            where: { id: userId },
            data: { institution_access_approval: 'APPROVED', verification_status: 'APPROVED' },
        });

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'APPROVED_HOD',
                targetId: userId,
                details: `Approved HOD ${hod.user.full_name} for university "${hod.university.name}" - department "${hod.department}"`,
            },
        });

        await sendNotification(userId, `✅ Your Head of Department account has been approved. You can now access the coordinator portal.`);
        res.json({ message: 'HOD approved', userId });
    } catch (error: any) { res.status(500).json({ error: error.message }); }
};

/** Reject a pending HOD */
export const rejectHod = async (req: AuthRequest, res: Response) => {
    try {
        const rawId = req.params.userId;
        const userId = parseInt(Array.isArray(rawId) ? rawId[0] : rawId, 10);
        const { reason } = req.body as { reason?: string };
        const rejectionReason = reason?.trim() || 'Your credentials could not be verified.';

        const hod = await prisma.hodProfile.findUnique({
            where: { userId },
            include: { user: true, university: true },
        });
        if (!hod) return res.status(404).json({ error: 'HOD not found' });

        await prisma.user.update({
            where: { id: userId },
            data: { institution_access_approval: 'REJECTED', verification_status: 'REJECTED' },
        });

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'REJECTED_HOD',
                targetId: userId,
                details: `Rejected HOD ${hod.user.full_name} for university "${hod.university.name}". Reason: ${rejectionReason}`,
            },
        });

        await sendNotification(userId, `❌ Your HOD registration was rejected. Reason: ${rejectionReason}`);
        res.json({ message: 'HOD rejected', userId });
    } catch (error: any) { res.status(500).json({ error: error.message }); }
};

export const getPendingCoordinators = async (req: AuthRequest, res: Response) => {
    try {
        const coordinators = await prisma.coordinator.findMany({
            where: {
                user: { institution_access_approval: 'PENDING', role: 'COORDINATOR' },
            },
            include: {
                user: {
                    select: {
                        id: true,
                        full_name: true,
                        email: true,
                        verification_status: true,
                        institution_access_approval: true,
                        verification_document: true,
                        created_at: true,
                    },
                },
                university: { select: { id: true, name: true } },
            },
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(coordinators);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/**
 * Approve a pending coordinator:
 * 1. If pending_university_name starts with __EXISTING__:id: → link to that university
 * 2. Otherwise create (or reuse) the University record from pending_university_name
 * 3. Link the CoordinatorProfile to the University
 * 4. Set user.institution_access_approval = APPROVED
 * 5. Send approval email
 */
export const approveCoordinator = async (req: AuthRequest, res: Response) => {
    try {
        const rawId = req.params.userId;
        const userId = parseInt(Array.isArray(rawId) ? rawId[0] : rawId, 10);
        // Admin can override the university name when approving a new-university request
        const { universityNameOverride } = req.body as { universityNameOverride?: string };

        const coordinator = await prisma.coordinator.findUnique({
            where: { userId },
            include: { user: true },
        });

        if (!coordinator) {
            return res.status(404).json({ error: 'Coordinator not found' });
        }
        if (coordinator.universityId && coordinator.user.institution_access_approval === 'APPROVED') {
            return res.status(400).json({ error: 'Coordinator is already approved and linked to a university' });
        }

        // Case 1: Coordinator already linked to an existing university (selected during registration)
        if (coordinator.universityId) {
            // Just approve the user — university already exists and is approved
            await prisma.user.update({
                where: { id: userId },
                data: {
                    institution_access_approval: 'APPROVED',
                    verification_status: 'APPROVED',
                },
            });

            const university = await prisma.university.findUnique({ where: { id: coordinator.universityId } });

            await prisma.auditLog.create({
                data: {
                    adminId: req.user!.userId,
                    action: 'APPROVED_COORDINATOR',
                    targetId: userId,
                    details: `Approved coordinator ${coordinator.user.full_name} — linked to existing university "${university?.name ?? coordinator.universityId}"`,
                },
            });

            await sendOrganizationApprovalEmail(coordinator.user.email, university?.name ?? 'your university', 'University');
            await sendNotification(userId, `✅ Your coordinator account has been approved. You can now access the platform.`);

            return res.json({ message: 'Coordinator approved', universityId: coordinator.universityId });
        }

        // Case 2: New university request — pending_university_name must exist
        const pendingName = coordinator.pending_university_name;
        if (!pendingName) {
            return res.status(400).json({ error: 'No pending university name on this coordinator profile' });
        }

        // Resolve the university to link to
        type UniversityRecord = { id: number; name: string; official_email: string; approval_status: string; verification_doc: string | null };
        let resolvedUniversity: UniversityRecord | null = null;

        // Check if coordinator selected an existing university (__EXISTING__:id:name)
        if (pendingName.startsWith('__EXISTING__:')) {
            const parts = pendingName.split(':');
            const existingId = parseInt(parts[1], 10);
            if (!isNaN(existingId)) {
                resolvedUniversity = await prisma.university.findUnique({ where: { id: existingId } });
            }
            if (!resolvedUniversity && parts.length > 2) {
                const fallbackName = parts.slice(2).join(':');
                resolvedUniversity = await prisma.university.findFirst({ where: { name: fallbackName } });
            }
        }

        // New university request — find or create
        if (!resolvedUniversity) {
            // Admin can override the name (e.g. fix "harama" → "Haramaya University")
            const universityName = universityNameOverride?.trim() ||
                (pendingName.startsWith('__EXISTING__:')
                    ? pendingName.split(':').slice(2).join(':')
                    : pendingName);

            resolvedUniversity = await prisma.university.findFirst({ where: { name: universityName } });
            if (!resolvedUniversity) {
                const emailTaken = await prisma.university.findUnique({
                    where: { official_email: coordinator.user.email }
                });
                resolvedUniversity = await prisma.university.create({
                    data: {
                        name: universityName,
                        official_email: emailTaken
                            ? `coord-${coordinator.user.id}@${coordinator.user.email.split('@')[1]}`
                            : coordinator.user.email,
                        approval_status: 'APPROVED',
                        verification_doc: coordinator.user.verification_document ?? null,
                    },
                });
            } else if (resolvedUniversity.approval_status !== 'APPROVED') {
                await prisma.university.update({
                    where: { id: resolvedUniversity.id },
                    data: {
                        approval_status: 'APPROVED',
                        ...(resolvedUniversity.verification_doc == null && coordinator.user.verification_document
                            ? { verification_doc: coordinator.user.verification_document }
                            : {}),
                    },
                });
            }
        }

        if (!resolvedUniversity) {
            return res.status(500).json({ error: 'Could not resolve university for this coordinator.' });
        }

        const university = resolvedUniversity;

        // Enforce one coordinator per university
        const existingCoordinator = await prisma.coordinator.findFirst({
            where: {
                universityId: university.id,
                user: {
                    institution_access_approval: 'APPROVED',
                },
            },
            include: {
                user: {
                    select: {
                        id: true,
                        full_name: true,
                        email: true,
                    },
                },
            },
        });
        if (existingCoordinator && existingCoordinator.userId !== userId) {
            return res.status(409).json({
                error: `University "${university.name}" already has an approved coordinator: ${existingCoordinator.user.full_name} (${existingCoordinator.user.email}). Suspend or reject the current coordinator before approving another one.`,
                code: 'UNIVERSITY_COORDINATOR_ALREADY_ASSIGNED',
                existingCoordinator: {
                    userId: existingCoordinator.user.id,
                    fullName: existingCoordinator.user.full_name,
                    email: existingCoordinator.user.email,
                },
            });
        }

        // Link coordinator to university and clear pending name
        await prisma.coordinator.update({
            where: { userId },
            data: {
                universityId: university.id,
                pending_university_name: null,
            },
        });

        // Approve the user — both institution access and email verification status
        await prisma.user.update({
            where: { id: userId },
            data: {
                institution_access_approval: 'APPROVED',
                verification_status: 'APPROVED',
            },
        });

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'APPROVED_COORDINATOR',
                targetId: userId,
                details: `Approved coordinator ${coordinator.user.full_name} — linked to university "${university.name}"`,
            },
        });

        // Notify coordinator by email
        await sendOrganizationApprovalEmail(coordinator.user.email, university.name, 'University');

        res.json({ message: 'Coordinator approved', universityId: university.id });
    } catch (error: any) {
        console.error('approveCoordinator error:', error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Reject a pending coordinator:
 * Sets institution_access_approval = REJECTED and sends rejection email.
 */
export const rejectCoordinator = async (req: AuthRequest, res: Response) => {
    try {
        const rawId = req.params.userId;
        const userId = parseInt(Array.isArray(rawId) ? rawId[0] : rawId, 10);
        const { reason } = req.body as { reason?: string };
        const rejectionReason = reason?.trim() || 'Your credentials could not be verified.';

        const coordinator = await prisma.coordinator.findUnique({
            where: { userId },
            include: { user: true },
        });

        if (!coordinator) {
            return res.status(404).json({ error: 'Coordinator not found' });
        }

        await prisma.user.update({
            where: { id: userId },
            data: { institution_access_approval: 'REJECTED', verification_status: 'REJECTED' },
        });

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'REJECTED_COORDINATOR',
                targetId: userId,
                details: `Rejected coordinator ${coordinator.user.full_name} — reason: ${rejectionReason}`,
            },
        });

        await sendOrganizationRejectionEmail(
            coordinator.user.email,
            coordinator.pending_university_name || 'University',
            'University',
            rejectionReason
        );

        res.json({ message: 'Coordinator rejected' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// --- FILE UPLOAD ENDPOINTS ---

/**
 * Upload verification document for university/company
 * Used during manual verification process
 */
export const uploadVerificationDocument = async (req: AuthRequest, res: Response) => {
    try {
        const { organizationType, organizationId } = req.body;
        const file = req.file;

        if (!file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        if (!organizationType || !organizationId) {
            return res.status(400).json({ error: 'organizationType and organizationId are required' });
        }

        const { CloudinaryService } = await import('../services/cloudinary.service');

        const orgId = parseInt(organizationId);
        const folder = `internlink/${orgId}/verification-docs`;

        const uploadResult: UploadResult = await CloudinaryService.uploadDocument(file, {
            organizationId: orgId,
            fileType: 'VERIFICATION_DOC',
            folder,
            resourceType: 'raw',
        });

        if (!uploadResult.success) {
            return res.status(400).json({ error: uploadResult.error });
        }

        // Update organization record
        if (organizationType === 'UNIVERSITY') {
            await prisma.university.update({
                where: { id: orgId },
                data: { verification_doc: uploadResult.url },
            });
        } else if (organizationType === 'COMPANY') {
            await prisma.company.update({
                where: { id: orgId },
                data: { verification_doc: uploadResult.url },
            });
        }

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'UPLOADED_VERIFICATION_DOC',
                targetId: orgId,
                details: `Uploaded verification document for ${organizationType}`,
            },
        });

        res.json({
            message: 'Verification document uploaded successfully',
            url: uploadResult.url,
            fileId: uploadResult.fileId,
        });
    } catch (error: any) {
        console.error('Upload verification document error:', error);
        res.status(500).json({ error: error.message });
    }
};

// ─── Analytics ────────────────────────────────────────────────────────────────

export const getAnalytics = async (req: AuthRequest, res: Response) => {
    try {
        // ── User growth: last 6 months, grouped by month ──────────────────────
        const now = new Date();
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
        sixMonthsAgo.setDate(1);
        sixMonthsAgo.setHours(0, 0, 0, 0);

        const oneMonthAgo = new Date();
        oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

        const users = await prisma.user.findMany({
            where: { created_at: { gte: sixMonthsAgo } },
            select: { role: true, created_at: true },
        });

        // Build month buckets
        const monthMap: Record<string, { label: string; students: number; coordinators: number; supervisors: number; hods: number; total: number }> = {};
        for (let i = 5; i >= 0; i--) {
            const d = new Date();
            d.setMonth(d.getMonth() - i);
            const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            const label = d.toLocaleString('default', { month: 'short' });
            monthMap[key] = { label, students: 0, coordinators: 0, supervisors: 0, hods: 0, total: 0 };
        }
        for (const u of users) {
            const d = new Date(u.created_at);
            const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            if (!monthMap[key]) continue;
            monthMap[key].total++;
            if (u.role === 'STUDENT') monthMap[key].students++;
            else if (u.role === 'COORDINATOR') monthMap[key].coordinators++;
            else if (u.role === 'SUPERVISOR') monthMap[key].supervisors++;
            else if (u.role === 'HOD') monthMap[key].hods++;
        }
        const userGrowth = Object.values(monthMap);

        // ── Placement stats ───────────────────────────────────────────────────
        const [totalStudents, placedStudents, completedStudents] = await Promise.all([
            prisma.student.count(),
            prisma.student.count({ where: { internship_status: 'PLACED' } }),
            prisma.student.count({ where: { internship_status: 'COMPLETED' } }),
        ]);
        const placementStats = {
            total: totalStudents,
            placed: placedStudents,
            completed: completedStudents,
            pending: totalStudents - placedStudents - completedStudents,
        };

        // ── Placement trend: assignments created per month (last 6 months) ────
        const assignments = await prisma.internshipAssignment.findMany({
            where: { start_date: { gte: sixMonthsAgo } },
            select: { start_date: true },
        });
        const trendMap: Record<string, { label: string; count: number }> = {};
        for (const key of Object.keys(monthMap)) {
            trendMap[key] = { label: monthMap[key].label, count: 0 };
        }
        for (const a of assignments) {
            const d = new Date(a.start_date);
            const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            if (trendMap[key]) trendMap[key].count++;
        }
        const placementTrend = Object.values(trendMap);

        // ── Proposal stats ────────────────────────────────────────────────────
        const proposalGroups = await prisma.internshipProposal.groupBy({
            by: ['status'],
            _count: { status: true },
        });
        const pMap: Record<string, number> = {};
        for (const g of proposalGroups) pMap[g.status] = g._count.status;
        const proposalStats = {
            total: Object.values(pMap).reduce((a, b) => a + b, 0),
            approved: pMap['APPROVED'] ?? 0,
            rejected: pMap['REJECTED'] ?? 0,
            pending: pMap['PENDING'] ?? 0,
        };

        // ── Org stats ─────────────────────────────────────────────────────────
        const [totalUnis, approvedUnis, totalComps, approvedComps] = await Promise.all([
            prisma.university.count(),
            prisma.university.count({ where: { approval_status: 'APPROVED' } }),
            prisma.company.count(),
            prisma.company.count({ where: { approval_status: 'APPROVED' } }),
        ]);
        const orgStats = {
            universities: { total: totalUnis, approved: approvedUnis },
            companies: { total: totalComps, approved: approvedComps },
        };

        // ── Weekly plan trend: last 6 months ──────────────────────────────────
        const plans = await prisma.weeklyPlan.findMany({
            where: { submitted_at: { gte: sixMonthsAgo } },
            select: { status: true, submitted_at: true },
        });
        const wpMap: Record<string, { label: string; submitted: number; approved: number }> = {};
        for (const key of Object.keys(monthMap)) {
            wpMap[key] = { label: monthMap[key].label, submitted: 0, approved: 0 };
        }
        for (const p of plans) {
            const d = new Date(p.submitted_at);
            const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            if (!wpMap[key]) continue;
            wpMap[key].submitted++;
            if (p.status === 'APPROVED') wpMap[key].approved++;
        }
        const weeklyPlanTrend = Object.values(wpMap);

        // ── Platform totals ───────────────────────────────────────────────────
        const [totalUsers, totalEvaluations, totalReports, newUsersThisMonth] = await Promise.all([
            prisma.user.count(),
            prisma.finalEvaluation.count(),
            prisma.report.count(),
            prisma.user.count({ where: { created_at: { gte: oneMonthAgo } } }),
        ]);

        // ── Pending approvals summary ─────────────────────────────────────────
        const [pendingUnis, pendingComps, pendingCoords, pendingSupervs] = await Promise.all([
            prisma.university.count({ where: { approval_status: 'PENDING' } }),
            prisma.company.count({ where: { approval_status: 'PENDING' } }),
            prisma.coordinator.count({
                where: {
                    universityId: null,
                    user: { institution_access_approval: 'PENDING' },
                },
            }),
            prisma.supervisor.count({
                where: { user: { institution_access_approval: 'PENDING' } },
            }),
        ]);
        const pendingApprovals = {
            universities: pendingUnis,
            companies: pendingComps,
            coordinators: pendingCoords,
            supervisors: pendingSupervs,
            total: pendingUnis + pendingComps + pendingCoords + pendingSupervs,
        };

        // ── Evaluation stats ──────────────────────────────────────────────────
        const avg10 = (e: any) => Math.round(([
            e.technical_skills, e.problem_solving, e.communication, e.team_collaboration,
            e.time_management, e.adaptability, e.professionalism, e.initiative_creativity,
            e.attendance_punctuality, e.task_completion_quality
        ].reduce((s: number, v: any) => s + Number(v), 0) / 10) * 10) / 10;

        const evalData = await prisma.finalEvaluation.findMany({
            select: { technical_skills: true, problem_solving: true, communication: true, team_collaboration: true, time_management: true, adaptability: true, professionalism: true, initiative_creativity: true, attendance_punctuality: true, task_completion_quality: true },
        });
        const evalStats = evalData.length > 0
            ? {
                count: evalData.length,
                avgOverall: Math.round(evalData.reduce((s, e) => s + avg10(e), 0) / evalData.length * 10) / 10,
            }
            : { count: 0, avgOverall: 0 };

        // ── Recent activity (paginated) ───────────────────────────────────────
        const activityPage = Math.max(1, parseInt(String(req.query.activityPage ?? '1'), 10) || 1);
        const activityLimit = Math.min(50, Math.max(1, parseInt(String(req.query.activityLimit ?? '4'), 10) || 4));
        const activitySkip = (activityPage - 1) * activityLimit;

        const [recentLogs, totalActivity] = await Promise.all([
            prisma.auditLog.findMany({
                orderBy: { timestamp: 'desc' },
                skip: activitySkip,
                take: activityLimit,
            }),
            prisma.auditLog.count(),
        ]);
        const recentAdminIds = [...new Set(recentLogs.map((l) => l.adminId))];
        const recentAdmins = await prisma.user.findMany({
            where: { id: { in: recentAdminIds } },
            select: { id: true, full_name: true },
        });
        const recentAdminMap = new Map(recentAdmins.map((a) => [a.id, a.full_name]));
        const recentActivity = recentLogs.map((l) => ({
            id: l.id,
            action: l.action,
            details: l.details,
            adminName: recentAdminMap.get(l.adminId) ?? 'Admin',
            timestamp: l.timestamp,
        }));

        return res.json({
            userGrowth,
            placementStats,
            placementTrend,
            proposalStats,
            orgStats,
            weeklyPlanTrend,
            totalUsers,
            totalEvaluations,
            totalReports,
            newUsersThisMonth,
            pendingApprovals,
            evalStats,
            recentActivity,
            totalActivity,
            activityPage,
            activityLimit,
            generatedAt: now.toISOString(),
        });
    } catch (error: any) {
        return res.status(500).json({ error: error.message });
    }
};

/** DELETE /admin/universities/:id — permanently remove a university and all linked data */
export const deleteUniversity = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        if (isNaN(id)) return res.status(400).json({ success: false, error: 'Invalid university ID.' });

        const university = await prisma.university.findUnique({ where: { id } });
        if (!university) return res.status(404).json({ success: false, error: 'University not found.' });

        // Cascade: delete all students, coordinators, hods, proposals, reports linked to this university
        // Prisma onDelete: Cascade handles most relations; we just delete the root record.
        await prisma.university.delete({ where: { id } });

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'DELETE_UNIVERSITY',
                targetId: id,
                details: `Permanently deleted university: ${university.name}`,
            },
        });

        return res.json({ success: true, message: `University "${university.name}" deleted.` });
    } catch (error: any) {
        return res.status(500).json({ success: false, error: error.message });
    }
};

/** DELETE /admin/companies/:id — permanently remove a company and all linked data */
export const deleteCompany = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        if (isNaN(id)) return res.status(400).json({ success: false, error: 'Invalid company ID.' });

        const company = await prisma.company.findUnique({ where: { id } });
        if (!company) return res.status(404).json({ success: false, error: 'Company not found.' });

        await prisma.company.delete({ where: { id } });

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'DELETE_COMPANY',
                targetId: id,
                details: `Permanently deleted company: ${company.name}`,
            },
        });

        return res.json({ success: true, message: `Company "${company.name}" deleted.` });
    } catch (error: any) {
        return res.status(500).json({ success: false, error: error.message });
    }
};
