import { Router } from 'express';
import * as reportCtrl from '../controllers/reportController';
import { authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

// Supervisor submits grades
router.post('/evaluate', authorize([Role.SUPERVISOR]), reportCtrl.submitEvaluation);

// Coordinator or Admin generates the final document
router.get('/generate/:studentId', authorize([Role.ADMIN, Role.COORDINATOR, Role.SUPERVISOR]), reportCtrl.generateStudentReport);

export default router;