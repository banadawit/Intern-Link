import { Router } from 'express';
import * as progressCtrl from '../controllers/progressController';
import * as teamPlanCtrl from '../controllers/teamPlanController';
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

// ── Student: daily check-ins ──────────────────────────────────────────────────
router.get('/plan/:id/days', authorize([Role.STUDENT]), progressCtrl.getPlanDaySubmissions);
router.post('/plan/:id/days', authorize([Role.STUDENT]), progressCtrl.submitPlanDay);
router.patch('/plan/:id/days/:workDate', authorize([Role.STUDENT]), progressCtrl.updatePlanDay);
router.delete('/plan/:id/days/:workDate', authorize([Role.STUDENT]), progressCtrl.deletePlanDay);

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

// ── Team Leader: delete all plans for a week across all team members ──────────
router.delete('/team-week/:weekNumber', authorize([Role.STUDENT]), progressCtrl.deleteWeekForTeam);

// ── Supervisor: review (approve / reject with feedback) ───────────────────────
router.patch('/review/:id', authorize([Role.SUPERVISOR]), progressCtrl.reviewWeeklyPlan);
// ── Supervisor: review daily plan submission ──────────────────────────────────
router.patch('/day-submission/:submissionId/review', authorize([Role.SUPERVISOR]), progressCtrl.reviewPlanDay);

// ── Team plans (team leader submits on behalf of team) ────────────────────────
router.get('/team-plans/my', authorize([Role.STUDENT]), teamPlanCtrl.getMyTeamPlans);
router.get('/team-plans/members', authorize([Role.STUDENT]), teamPlanCtrl.getTeamMembersPlans);
router.get('/team-plans/members/daily', authorize([Role.STUDENT]), teamPlanCtrl.getTeamMembersDailyPlans);
router.get('/team-plans/compiled-draft', authorize([Role.STUDENT]), teamPlanCtrl.getCompiledDraft);
router.post('/team-plans', authorize([Role.STUDENT]), teamPlanCtrl.submitTeamWeeklyPlan);
router.post('/team-plans/forward', authorize([Role.STUDENT]), teamPlanCtrl.forwardToSupervisor);
router.post('/team-plans/forward-daily', authorize([Role.STUDENT]), teamPlanCtrl.forwardDailyToSupervisor);
router.post('/team-plans/:planId/daily', authorize([Role.STUDENT]), teamPlanCtrl.submitTeamDailyPlan);
// TL review of member plans
router.patch('/team-plans/tl-review/weekly/:planId', authorize([Role.STUDENT]), teamPlanCtrl.tlReviewWeeklyPlan);
router.patch('/team-plans/tl-review/daily/:submissionId', authorize([Role.STUDENT]), teamPlanCtrl.tlReviewDailyPlan);
// TL final review of the compiled team plan (approve → forward to supervisor, or request resubmission)
router.patch('/team-plans/:planId/tl-review', authorize([Role.STUDENT]), teamPlanCtrl.tlReviewTeamPlan);

export default router;
