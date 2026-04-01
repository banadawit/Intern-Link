import { Router } from 'express';
import { setupUniversity, getPendingUniversities, updateUniversityStatus } from '../controllers/universityController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

// Endpoint for Coordinators to setup their University
router.post('/setup', authenticate, authorize([Role.COORDINATOR]), setupUniversity);

// Endpoints for Admins to manage the pending list
router.get('/pending', authenticate, authorize([Role.ADMIN]), getPendingUniversities);
router.patch('/status/:id', authenticate, authorize([Role.ADMIN]), updateUniversityStatus);

export default router;