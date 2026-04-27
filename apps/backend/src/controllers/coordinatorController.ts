import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import bcrypt from 'bcryptjs';
import { sendOrganizationApprovalEmail, sendOrganizationRejectionEmail } from '../services/email.service';

const hodInclude = {
    user: {
        select: {
            id: true,
            full_name: true,
            email: true,
            verification_document: true,
            institution_access_approval: true,
            verification_status: true,
            created_at: true,
        },
    },
    university: { select: { name: true } },
};

async function getCoordinatorUniversityId(userId: number) {
    const profile = await prisma.coordinator.findUnique({ where: { userId } });
    return profile?.universityId ?? null;
}

/**
 * GET /coordinator/pending-hods
 */
export const getPendingHods = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await getCoordinatorUniversityId(req.user!.userId);
        if (!universityId) return res.status(403).json({ error: 'Your coordinator account is not linked to a university.' });

        const hods = await prisma.hodProfile.findMany({
            where: { universityId, user: { institution_access_approval: 'PENDING', role: 'HOD' } },
            include: hodInclude,
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(hods);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/**
 * GET /coordinator/approved-hods
 */
export const getApprovedHods = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await getCoordinatorUniversityId(req.user!.userId);
        if (!universityId) return res.status(403).json({ error: 'Your coordinator account is not linked to a university.' });

        const hods = await prisma.hodProfile.findMany({
            where: { universityId, user: { institution_access_approval: 'APPROVED', role: 'HOD' } },
            include: hodInclude,
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(hods);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/**
 * GET /coordinator/rejected-hods
 */
export const getRejectedHods = async (req: AuthRequest, res: Response) => {
    try {
        const universityId = await getCoordinatorUniversityId(req.user!.userId);
        if (!universityId) return res.status(403).json({ error: 'Your coordinator account is not linked to a university.' });

        const hods = await prisma.hodProfile.findMany({
            where: { universityId, user: { institution_access_approval: 'REJECTED', role: 'HOD' } },
            include: hodInclude,
            orderBy: { user: { created_at: 'desc' } },
        });
        res.json(hods);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/**
 * PATCH /coordinator/verify-hod
 * Approve or reject an HoD from the coordinator's own university.
 * Body: { userId: number, status: 'APPROVED' | 'REJECTED', reason?: string }
 */
export const verifyHod = async (req: AuthRequest, res: Response) => {
    try {
        const { userId, status, reason } = req.body as {
            userId?: number;
            status?: string;
            reason?: string;
        };

        if (!userId || !status || !['APPROVED', 'REJECTED'].includes(status)) {
            return res.status(400).json({ error: 'userId and status (APPROVED | REJECTED) are required.' });
        }

        // Ensure the coordinator is linked to a university
        const coordinatorProfile = await prisma.coordinator.findUnique({
            where: { userId: req.user!.userId },
        });

        if (!coordinatorProfile?.universityId) {
            return res.status(403).json({ error: 'Your coordinator account is not linked to a university.' });
        }

        // Fetch the HoD profile and verify it belongs to the same university
        const hodProfile = await prisma.hodProfile.findUnique({
            where: { userId },
            include: { user: true, university: true },
        });

        if (!hodProfile) {
            return res.status(404).json({ error: 'HoD profile not found.' });
        }

        if (hodProfile.universityId !== coordinatorProfile.universityId) {
            return res.status(403).json({ error: 'You can only manage HoDs from your own university.' });
        }

        const rejectionReason = reason?.trim() || 'Your credentials could not be verified.';

        // Update user approval status
        await prisma.user.update({
            where: { id: userId },
            data: {
                institution_access_approval: status as 'APPROVED' | 'REJECTED',
                ...(status === 'APPROVED'
                    ? { verification_status: 'APPROVED' }
                    : { verification_status: 'REJECTED' }),
            },
        });

        // Send email notification to the HoD
        if (status === 'APPROVED') {
            await sendOrganizationApprovalEmail(
                hodProfile.user.email,
                hodProfile.university.name,
                'University'
            );
        } else {
            await sendOrganizationRejectionEmail(
                hodProfile.user.email,
                hodProfile.university.name,
                'University',
                rejectionReason
            );
        }

        res.json({
            message: `HoD ${status.toLowerCase()}`,
            userId,
            status,
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/**
 * POST /coordinator/hods
 * Coordinator manually creates an HoD account for their university.
 * The account is auto-approved because the coordinator is vouching for them.
 * Body: { fullName, email, department, password?, employeeId? }
 */
export const createHod = async (req: AuthRequest, res: Response) => {
    try {
        const coordinatorProfile = await prisma.coordinator.findUnique({
            where: { userId: req.user!.userId },
            include: { university: true },
        });

        if (!coordinatorProfile?.universityId) {
            return res.status(403).json({ error: 'Your coordinator account is not linked to a university.' });
        }

        const { fullName, email, department, password, employeeId } = req.body as {
            fullName?: string;
            email?: string;
            department?: string;
            password?: string;
            employeeId?: string;
        };

        if (!fullName?.trim() || !email?.trim() || !department?.trim()) {
            return res.status(400).json({ error: 'fullName, email, and department are required.' });
        }

        const emailLower = email.trim().toLowerCase();

        // Check email not already taken
        const existing = await prisma.user.findUnique({ where: { email: emailLower } });
        if (existing) {
            return res.status(409).json({ error: 'An account with this email already exists.' });
        }

        // Use provided password or generate a temporary one
        const rawPassword = password?.trim() || `HoD@${Math.random().toString(36).slice(2, 10)}`;
        const passwordHash = await bcrypt.hash(rawPassword, 10);

        // Create user + HOD profile in a transaction — auto-approved
        const newUser = await prisma.user.create({
            data: {
                full_name: fullName.trim(),
                email: emailLower,
                password_hash: passwordHash,
                role: 'HOD',
                verification_status: 'APPROVED',
                institution_access_approval: 'APPROVED', // auto-approved by coordinator
                hodProfile: {
                    create: {
                        universityId: coordinatorProfile.universityId,
                        department: department.trim(),
                        phone_number: employeeId?.trim() || null,
                    },
                },
            },
            select: {
                id: true,
                full_name: true,
                email: true,
                role: true,
                institution_access_approval: true,
                hodProfile: { select: { id: true, department: true } },
            },
        });

        // Notify the new HOD by email
        try {
            await sendOrganizationApprovalEmail(
                emailLower,
                coordinatorProfile.university!.name,
                'University'
            );
        } catch (_) {
            // Non-fatal — account is created regardless
        }

        return res.status(201).json({
            message: 'HoD account created and approved successfully.',
            user: newUser,
            temporaryPassword: password?.trim() ? undefined : rawPassword,
        });
    } catch (error: any) {
        return res.status(500).json({ error: error.message });
    }
};
