import { Router } from 'express';
import * as aiCtrl from '../controllers/aiController';
import { authenticate, authorize, optionalAuth } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

router.post('/generate-plan', authenticate, authorize([Role.STUDENT]), aiCtrl.postGeneratePlan);
router.post('/generate-feedback', authenticate, authorize([Role.SUPERVISOR]), aiCtrl.postGenerateFeedback);
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
