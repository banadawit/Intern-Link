import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { getPendingHods, getApprovedHods, getRejectedHods, verifyHod } from '../controllers/coordinatorController';

const router = Router();

router.use(authenticate);
router.use(authorize([Role.COORDINATOR]));

// HoD approval workflow
router.get('/pending-hods', getPendingHods);
router.get('/approved-hods', getApprovedHods);
router.get('/rejected-hods', getRejectedHods);
router.patch('/verify-hod', verifyHod);

export default router;
