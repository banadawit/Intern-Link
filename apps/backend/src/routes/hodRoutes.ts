import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import * as hodCtrl from '../controllers/hodController';
import * as hodEnhanced from '../controllers/hodEnhancedController';

const router = Router();
router.use(authenticate, authorize([Role.HOD]));

// ── Enhanced stats (before /dashboard-stats to avoid shadowing) ───────────────
router.get('/dashboard-stats/enhanced', hodEnhanced.getEnhancedStats);
router.get('/dashboard-stats', hodCtrl.getDashboardStats);

// ── Student management ────────────────────────────────────────────────────────
// bulk-approve MUST come before /:studentId/approve to avoid Express matching 'bulk-approve' as an id
router.post('/students/bulk-approve', hodEnhanced.bulkApproveStudents);
router.get('/students', hodCtrl.getStudents);
router.patch('/students/:studentId/approve', hodCtrl.approveStudent);
router.patch('/students/:studentId/reject', hodCtrl.rejectStudent);
router.patch('/verify-student', hodCtrl.verifyStudent);
router.patch('/students/:id/flag', hodEnhanced.flagStudent);
router.delete('/students/:id/flag', hodEnhanced.unflagStudent);
router.get('/students/:id/timeline', hodEnhanced.getStudentTimeline);
router.patch('/students/:id/reprocess', hodEnhanced.reprocessStudent);

// ── Companies ─────────────────────────────────────────────────────────────────
router.get('/companies', hodCtrl.getCompanies);
router.post('/invite-company', hodCtrl.inviteCompany);

// ── Proposals ─────────────────────────────────────────────────────────────────
router.get('/proposals/open-letters', hodCtrl.getOpenLetterProposals);
router.patch('/proposals/open-letters/:id', hodCtrl.updateOpenLetterProposal);
router.post('/proposals', hodCtrl.sendProposal);
router.get('/proposals', hodCtrl.getProposals);
router.patch('/proposals/:id/state', hodEnhanced.transitionProposalState);

// ── Placements ────────────────────────────────────────────────────────────────
router.get('/placements', hodEnhanced.getPlacements);
router.patch('/placements/:id/force-end', hodEnhanced.forceEndPlacement);

// ── Reports (weekly/summary MUST come before /:id/download) ──────────────────
router.get('/reports/weekly', hodEnhanced.getWeeklyReports);
router.get('/reports/summary', hodEnhanced.getReportsSummary);
router.get('/reports', hodCtrl.getReports);
router.get('/reports/:id/download', hodCtrl.getReportDownload);

export default router;
