import { Router } from 'express';
import * as aiCtrl from '../controllers/aiController';
import { authenticate, authorize, optionalAuth } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

router.post('/generate-plan', authenticate, authorize([Role.STUDENT]), aiCtrl.postGeneratePlan);
router.post('/generate-feedback', authenticate, authorize([Role.SUPERVISOR]), aiCtrl.postGenerateFeedback);

router.post('/student-plan', authenticate, authorize([Role.STUDENT]), aiCtrl.postCachedStudentPlan);
router.post('/student-plan/regenerate', authenticate, authorize([Role.STUDENT]), aiCtrl.postRegenerateStudentPlan);
router.post('/supervisor-feedback', authenticate, authorize([Role.SUPERVISOR]), aiCtrl.postCachedSupervisorFeedback);
router.post('/supervisor-feedback/regenerate', authenticate, authorize([Role.SUPERVISOR]), aiCtrl.postRegenerateSupervisorFeedback);
router.post('/hod-suggestion', authenticate, authorize([Role.HOD]), aiCtrl.postCachedHodSuggestion);
router.post('/hod-suggestion/regenerate', authenticate, authorize([Role.HOD]), aiCtrl.postRegenerateHodSuggestion);
router.post('/coordinator-report', authenticate, authorize([Role.COORDINATOR]), aiCtrl.postCachedCoordinatorReport);
router.post('/coordinator-report/regenerate', authenticate, authorize([Role.COORDINATOR]), aiCtrl.postRegenerateCoordinatorReport);
router.get(
    '/chat/history',
    optionalAuth,
    aiCtrl.getChatHistory
);
router.delete(
    '/chat/history',
    optionalAuth,
    aiCtrl.deleteChatHistory
);
router.post(
    '/chat',
    optionalAuth,
    aiCtrl.postChat
);

export default router;
