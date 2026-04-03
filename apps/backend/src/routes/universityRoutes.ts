import { Router } from 'express';
import { setupUniversity, getPendingUniversities, updateUniversityStatus } from '../controllers/universityController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import prisma from '../config/db';

const router = Router();

// Public: list approved universities (used by HoD registration dropdown)
router.get('/approved', async (_req, res) => {
    try {
        const universities = await prisma.university.findMany({
            where: { approval_status: 'APPROVED' },
            select: { id: true, name: true },
            orderBy: { name: 'asc' },
        });
        res.json(universities);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

// Public: list departments with an approved HoD for a given university
router.get('/:universityId/departments', async (req, res) => {
    try {
        const universityId = parseInt(req.params.universityId, 10);
        if (isNaN(universityId)) return res.status(400).json({ error: 'Invalid university id' });

        const hods = await prisma.hodProfile.findMany({
            where: {
                universityId,
                user: { institution_access_approval: 'APPROVED', verification_status: 'APPROVED' },
            },
            select: { id: true, department: true },
            orderBy: { department: 'asc' },
        });
        res.json(hods); // [{ id, department }]
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint for Coordinators to setup their University
router.post('/setup', authenticate, authorize([Role.COORDINATOR]), setupUniversity);

// Endpoints for Admins to manage the pending list
router.get('/pending', authenticate, authorize([Role.ADMIN]), getPendingUniversities);
router.patch('/status/:id', authenticate, authorize([Role.ADMIN]), updateUniversityStatus);

export default router;