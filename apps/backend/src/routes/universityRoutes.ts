import { Router } from 'express';
import { setupUniversity, getPendingUniversities, updateUniversityStatus } from '../controllers/universityController';
import { authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

// Endpoint for Coordinators to setup their University
router.post('/setup', authorize([Role.COORDINATOR]), setupUniversity);

// Endpoints for Admins to manage the pending list
router.get('/pending', authorize([Role.ADMIN]), getPendingUniversities);
router.patch('/status/:id', authorize([Role.ADMIN]), updateUniversityStatus);

export default router;