import { Response } from 'express';
import prisma from '../config/db';
import { AuthRequest } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

async function getCoordinatorUniversityId(userId: number): Promise<number | null> {
    const c = await prisma.coordinator.findUnique({ where: { userId } });
    return c?.universityId ?? null;
}

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

        res.json({ message: 'HOD access rejected.', userId: targetUserId });
    } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : 'Server error';
        res.status(500).json({ error: msg });
    }
};
