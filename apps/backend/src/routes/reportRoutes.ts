import { Router } from 'express';
import * as reportCtrl from '../controllers/reportController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();
router.use(authenticate);

router.get('/my-evaluation', authorize([Role.STUDENT]), reportCtrl.getMyEvaluation);

// Supervisor submits grades
router.post('/evaluate', authorize([Role.SUPERVISOR]), reportCtrl.submitEvaluation);

// Coordinator or Admin generates the final document
router.get(
    '/generate/:studentId',
    authorize([Role.ADMIN, Role.COORDINATOR, Role.SUPERVISOR]),
    reportCtrl.generateStudentReport
);

router.post(
    '/send-to-university',
    authorize([Role.ADMIN, Role.SUPERVISOR]),
    reportCtrl.sendReportToUniversity
);

export default router;
