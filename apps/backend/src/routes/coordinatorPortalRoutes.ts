import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import * as ctrl from '../controllers/coordinatorPortalController';

const router = Router();
router.use(authenticate);
router.use(authorize([Role.COORDINATOR]));

router.get('/dashboard-stats', ctrl.getDashboardStats);
router.patch('/notifications/:id/read', ctrl.markNotificationRead);
router.get('/companies', ctrl.getCompanies);
router.get('/proposals/overview', ctrl.getProposalsOverview);
router.get('/assignments/overview', ctrl.getAssignmentsOverview);
router.get('/reports/overview', ctrl.getReportsOverview);

export default router;
