import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendOrganizationApprovalEmail, sendOrganizationRejectionEmail } from '../services/email.service';
import { assertUniversityVerificationProposalExists } from '../utils/institutionVerification';
import { attachVerificationSla } from '../utils/verificationSla';
import { notifyAdminsNewVerificationProposal } from '../utils/notifyAdminNewProposal';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { notifyAllAdmins, NotificationType } from '../services/notification.service';

// 1. Coordinator: Setup University Profile
export const setupUniversity = async (req: AuthRequest, res: Response) => {
    try {
        const { name, official_email, address } = req.body;
        const userId = req.user?.userId;

        // Check if this user is already a coordinator
        const existingCoordinator = await prisma.coordinator.findUnique({
            where: { userId }
        });

        if (existingCoordinator) {
            return sendError(res, "You have already set up a university profile.", 400);
        }

        // Create University and link Coordinator in one transaction
        const university = await prisma.university.create({
            data: {
                name,
                official_email,
                address,
                approval_status: 'PENDING',
                coordinators: {
                    create: {
                        userId: userId!
                    }
                }
            }
        });

        const coordinatorUser = await prisma.user.findUnique({
            where: { id: userId! },
            select: { email: true },
        });
        await notifyAdminsNewVerificationProposal({
            organizationName: university.name,
            institutionType: 'University',
            organizationId: university.id,
            submitterEmail: coordinatorUser?.email,
        });

        await notifyAllAdmins(
            `New university registration pending approval: ${university.name}`,
            NotificationType.ADMIN_ALERT
        );

        return sendSuccess(res, { university }, "University profile submitted for approval.", 201);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// 2. Admin: Get all pending universities
export const getPendingUniversities = async (req: AuthRequest, res: Response) => {
    try {
        const pending = await prisma.university.findMany({
            where: { approval_status: 'PENDING' }
        });
        return sendSuccess(res, pending.map((u) => attachVerificationSla(u)), "Pending universities fetched");
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// 3. Admin: Approve, Reject, Suspend, or reactivate a university
export const updateUniversityStatus = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { status, reason } = req.body;

        const universityId = Array.isArray(id) ? id[0] : id;
        const uid = parseInt(universityId);
        const rejectionReason = typeof reason === 'string' ? reason : '';

        const existing = await prisma.university.findUnique({ where: { id: uid } });
        if (!existing) {
            return sendError(res, 'University not found', 404);
        }

        if (status === 'SUSPENDED' && existing.approval_status !== 'APPROVED') {
            return sendError(res, 'Only approved organizations can be suspended.', 400);
        }

        if (status === 'APPROVED') {
            if (existing.approval_status !== 'SUSPENDED') {
                try {
                    await assertUniversityVerificationProposalExists(uid);
                } catch (e: any) {
                    return sendError(res, e.message || 'Approval validation failed', 400);
                }
            }
        }

        const updated = await prisma.university.update({
            where: { id: uid },
            data: {
                approval_status: status,
                ...(status === 'REJECTED'
                    ? { rejection_reason: rejectionReason, verification_doc: null }
                    : status === 'SUSPENDED'
                      ? {}
                      : { rejection_reason: null }),
            }
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

        return sendSuccess(res, { updated }, `University is now ${status}`);
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};