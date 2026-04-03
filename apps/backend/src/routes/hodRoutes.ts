import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import * as hodCtrl from '../controllers/hodController';

const router = Router();
router.use(authenticate, authorize([Role.HOD]));

router.get('/dashboard-stats', hodCtrl.getDashboardStats);
router.get('/students', hodCtrl.getStudents);
router.patch('/students/:studentId/approve', hodCtrl.approveStudent);
router.patch('/students/:studentId/reject', hodCtrl.rejectStudent);
router.patch('/verify-student', hodCtrl.verifyStudent);
router.get('/companies', hodCtrl.getCompanies);
router.get('/proposals/open-letters', hodCtrl.getOpenLetterProposals);
router.patch('/proposals/open-letters/:id', hodCtrl.updateOpenLetterProposal);
router.post('/proposals', hodCtrl.sendProposal);
router.get('/proposals', hodCtrl.getProposals);
router.post('/invite-company', hodCtrl.inviteCompany);
router.get('/reports', hodCtrl.getReports);
router.get('/reports/:id/download', hodCtrl.getReportDownload);

export default router;
