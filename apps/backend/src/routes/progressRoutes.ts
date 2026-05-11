import { Router } from 'express';
import * as progressCtrl from '../controllers/progressController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { uploadPresentation } from '../middlewares/uploadMiddleware';
import { uploadPlanAttachments } from '../config/multer.config';
import { Role } from '@prisma/client';

const router = Router();
router.use(authenticate);

// ── Student: read ─────────────────────────────────────────────────────────────
router.get('/my-plans', authorize([Role.STUDENT]), progressCtrl.getMyWeeklyPlans);

// ── Student: submit new plan (multipart: attachments[] + optional presentation) ─
router.post(
    '/submit',
    authorize([Role.STUDENT]),
    uploadPlanAttachments,          // accepts up to 5 files in field "attachments"
    progressCtrl.submitWeeklyPlan,
);

// ── Student: update PENDING/REJECTED plan ─────────────────────────────────────
router.patch(
    '/plan/:id',
    authorize([Role.STUDENT]),
    uploadPlanAttachments,
    progressCtrl.updateMyWeeklyPlan,
);

// ── Student: resubmit a REJECTED plan ────────────────────────────────────────
router.post(
    '/plan/:id/resubmit',
    authorize([Role.STUDENT]),
    uploadPlanAttachments,
    progressCtrl.resubmitWeeklyPlan,
);

// ── Student: remove a single attachment from a plan ───────────────────────────
router.delete('/plan/:id/attachment', authorize([Role.STUDENT]), progressCtrl.removePlanAttachment);

// ── Student: daily check-ins ──────────────────────────────────────────────────
router.get('/plan/:id/days', authorize([Role.STUDENT]), progressCtrl.getPlanDaySubmissions);
router.post('/plan/:id/days', authorize([Role.STUDENT]), progressCtrl.submitPlanDay);
router.delete('/plan/:id/days/:workDate', authorize([Role.STUDENT]), progressCtrl.deletePlanDay);

// ── Supervisor: review (approve / reject with feedback) ───────────────────────
router.patch('/review/:id', authorize([Role.SUPERVISOR]), progressCtrl.reviewWeeklyPlan);

export default router;
