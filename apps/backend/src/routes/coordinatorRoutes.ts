import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import * as coordinatorCtrl from '../controllers/coordinatorController';

const router = Router();
router.use(authenticate, authorize([Role.COORDINATOR]));

router.get('/dashboard-stats', coordinatorCtrl.getDashboardStats);
router.get('/pending-hods', coordinatorCtrl.getPendingHods);
router.get('/hods', coordinatorCtrl.getHods);
router.post('/hods/:userId/approve', coordinatorCtrl.approveHod);
router.post('/hods/:userId/reject', coordinatorCtrl.rejectHod);
router.get('/students/overview', coordinatorCtrl.getStudentsOverview);
router.get('/proposals/overview', coordinatorCtrl.getProposalsOverview);
router.get('/assignments/overview', coordinatorCtrl.getAssignmentsOverview);
router.get('/reports/overview', coordinatorCtrl.getReportsOverview);
router.get('/companies', coordinatorCtrl.getCompanies);
router.get('/notifications', coordinatorCtrl.getNotifications);
router.patch('/notifications/:id/read', coordinatorCtrl.markNotificationRead);

export default router;
