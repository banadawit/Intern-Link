import { Router } from 'express';
import * as progressCtrl from '../controllers/progressController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { uploadPresentation } from '../middlewares/uploadMiddleware';
import { Role } from '@prisma/client';

const router = Router();
router.use(authenticate);

router.get('/my-plans', authorize([Role.STUDENT]), progressCtrl.getMyWeeklyPlans);

router.patch('/plan/:id', authorize([Role.STUDENT]), progressCtrl.updateMyWeeklyPlan);

// Student submits (Handles File + Form Data)
router.post(
    '/submit',
    authorize([Role.STUDENT]),
    uploadPresentation.single('presentation'),
    progressCtrl.submitWeeklyPlan
);

// Supervisor approves/rejects
router.patch('/review/:id', authorize([Role.SUPERVISOR]), progressCtrl.reviewWeeklyPlan);

export default router;
