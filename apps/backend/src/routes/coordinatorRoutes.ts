import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import * as coordinatorCtrl from '../controllers/coordinatorController';

const router = Router();
router.use(authenticate, authorize([Role.COORDINATOR]));

router.get('/pending-hods', coordinatorCtrl.getPendingHods);
router.post('/hods/:userId/approve', coordinatorCtrl.approveHod);
router.post('/hods/:userId/reject', coordinatorCtrl.rejectHod);

export default router;
