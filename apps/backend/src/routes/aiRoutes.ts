import { Router } from 'express';
import * as aiCtrl from '../controllers/aiController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();
router.use(authenticate);

router.post('/generate-plan', authorize([Role.STUDENT]), aiCtrl.postGeneratePlan);
router.post('/generate-feedback', authorize([Role.SUPERVISOR]), aiCtrl.postGenerateFeedback);
router.get(
    '/chat/history',
    authorize([Role.STUDENT, Role.SUPERVISOR, Role.COORDINATOR, Role.ADMIN]),
    aiCtrl.getChatHistory
);
router.delete(
    '/chat/history',
    authorize([Role.STUDENT, Role.SUPERVISOR, Role.COORDINATOR, Role.ADMIN]),
    aiCtrl.deleteChatHistory
);
router.post(
    '/chat',
    authorize([Role.STUDENT, Role.SUPERVISOR, Role.COORDINATOR, Role.ADMIN]),
    aiCtrl.postChat
);

export default router;
