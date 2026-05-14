import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { getPendingHods, getApprovedHods, getRejectedHods, getSuspendedHods, getAllHods, verifyHod, createHod, getHodDetail, suspendHod, activateHod, markHodViewed } from '../controllers/coordinatorController';

const router = Router();

router.use(authenticate);
router.use(authorize([Role.COORDINATOR]));

// HoD approval workflow
router.get('/pending-hods', getPendingHods);
router.get('/approved-hods', getApprovedHods);
router.get('/rejected-hods', getRejectedHods);
router.get('/suspended-hods', getSuspendedHods);
router.get('/all-hods', getAllHods);
router.patch('/verify-hod', verifyHod);
router.patch('/hods/:userId/mark-viewed', markHodViewed);

// Coordinator manually creates an HoD (auto-approved)
router.post('/hods', createHod);

// HoD detail and status management
router.get('/hods/:userId', getHodDetail);
router.patch('/hods/:userId/suspend', suspendHod);
router.patch('/hods/:userId/activate', activateHod);

export default router;
