import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

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
            return res.status(400).json({ message: "You have already set up a university profile." });
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

        res.status(201).json({ message: "University profile submitted for approval.", university });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 2. Admin: Get all pending universities
export const getPendingUniversities = async (req: AuthRequest, res: Response) => {
    try {
        const pending = await prisma.university.findMany({
            where: { approval_status: 'PENDING' }
        });
        res.json(pending);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 3. Admin: Approve or Reject a university
export const updateUniversityStatus = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { status } = req.body; // 'APPROVED' or 'REJECTED'

        // Ensure id is a string (not string[])
        const universityId = Array.isArray(id) ? id[0] : id;

        const updated = await prisma.university.update({
            where: { id: parseInt(universityId) },
            data: { approval_status: status }
        });

        res.json({ message: `University is now ${status}`, updated });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};