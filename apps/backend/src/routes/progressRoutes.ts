import { Router } from 'express';
import * as progressCtrl from '../controllers/progressController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { uploadPresentation } from '../middlewares/uploadMiddleware';
import { Role } from '@prisma/client';

const router = Router();
router.use(authenticate);

router.get('/my-plans', authorize([Role.STUDENT]), progressCtrl.getMyWeeklyPlans);

router.patch('/plan/:id', authorize([Role.STUDENT]), progressCtrl.updateMyWeeklyPlan);

router.get('/plan/:id/days', authorize([Role.STUDENT]), progressCtrl.getPlanDaySubmissions);
router.post('/plan/:id/days', authorize([Role.STUDENT]), progressCtrl.submitPlanDay);
router.delete('/plan/:id/days/:workDate', authorize([Role.STUDENT]), progressCtrl.deletePlanDay);

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
