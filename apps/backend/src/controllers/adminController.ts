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
            pendingCoordinators,
            pendingSupervisors,
        ] = await Promise.all([
            prisma.university.count({ where: { approval_status: 'PENDING' } }),
            prisma.company.count({ where: { approval_status: 'PENDING' } }),
            prisma.user.count(),
            prisma.university.count({ where: { approval_status: 'APPROVED' } }),
            prisma.company.count({ where: { approval_status: 'APPROVED' } }),
            prisma.student.count(),
            prisma.internshipAssignment.count({ where: { status: 'ACTIVE' } }),
            prisma.coordinator.count({ where: { universityId: { equals: null } } }),
            prisma.user.count({ where: { role: 'SUPERVISOR', institution_access_approval: 'PENDING' } }),
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
            rejectedCoordinators: await prisma.user.count({ where: { role: 'COORDINATOR', institution_access_approval: 'REJECTED' } }),
            rejectedSupervisors: await prisma.user.count({ where: { role: 'SUPERVISOR', institution_access_approval: 'REJECTED' } }),
            suspendedCoordinators: await prisma.user.count({ where: { role: 'COORDINATOR', institution_access_approval: 'SUSPENDED' } }),
            suspendedSupervisors: await prisma.user.count({ where: { role: 'SUPERVISOR', institution_access_approval: 'SUSPENDED' } }),
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
            data: { approval_status: 'APPROVED' },
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

/** List all coordinators pending admin approval (no university linked yet) */
export const getPendingCoordinators = async (req: AuthRequest, res: Response) => {
    try {
        const coordinators = await prisma.coordinator.findMany({
            where: { universityId: { equals: null } },
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
 * 1. Create (or reuse) the University record from pending_university_name
 * 2. Link the CoordinatorProfile to the new University
 * 3. Set user.institution_access_approval = APPROVED
 * 4. Send approval email
 */
export const approveCoordinator = async (req: AuthRequest, res: Response) => {
    try {
        const rawId = req.params.userId;
        const userId = parseInt(Array.isArray(rawId) ? rawId[0] : rawId, 10);

        const coordinator = await prisma.coordinator.findUnique({
            where: { userId },
            include: { user: true },
        });

        if (!coordinator) {
            return res.status(404).json({ error: 'Coordinator not found' });
        }
        if (coordinator.universityId) {
            return res.status(400).json({ error: 'Coordinator is already linked to a university' });
        }

        const universityName = coordinator.pending_university_name;
        if (!universityName) {
            return res.status(400).json({ error: 'No pending university name on this coordinator profile' });
        }

        // Find or create the University — use upsert to handle unique email conflicts
        let university = await prisma.university.findFirst({ where: { name: universityName } });
        if (!university) {
            // Check if email is already taken by another university
            const emailTaken = await prisma.university.findUnique({
                where: { official_email: coordinator.user.email }
            });
            university = await prisma.university.create({
                data: {
                    name: universityName,
                    official_email: emailTaken
                        ? `coord-${coordinator.user.id}@${coordinator.user.email.split('@')[1]}`
                        : coordinator.user.email,
                    approval_status: 'APPROVED',
                },
            });
        } else if (university.approval_status !== 'APPROVED') {
            await prisma.university.update({
                where: { id: university.id },
                data: { approval_status: 'APPROVED' },
            });
        }

        // Enforce one coordinator per university
        const existingCoordinator = await prisma.coordinator.findFirst({
            where: { universityId: university.id },
        });
        if (existingCoordinator && existingCoordinator.userId !== userId) {
            return res.status(409).json({
                error: `University "${university.name}" already has an approved coordinator. Each university can only have one coordinator.`,
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
