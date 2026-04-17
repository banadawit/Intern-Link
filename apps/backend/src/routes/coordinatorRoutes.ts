import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { getPendingHods, verifyHod } from '../controllers/coordinatorController';

const router = Router();

router.use(authenticate);
router.use(authorize([Role.COORDINATOR]));

// HoD approval workflow
router.get('/pending-hods', getPendingHods);
router.patch('/verify-hod', verifyHod);

export default router;
