import { Router } from 'express';
import * as adminCtrl from '../controllers/adminController';
import * as configCtrl from '../controllers/systemConfigController';
import * as onboardCtrl from '../controllers/adminOnboardingController';
import * as mergeCtrl from '../controllers/adminMergeController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { uploadVerification } from '../config/multer.config';

const router = Router();

router.use(authenticate);
router.use(authorize([Role.ADMIN]));

// Dashboard & Stats
router.get('/stats', adminCtrl.getDashboardStats);

router.get('/universities', adminCtrl.listUniversities);
router.get('/companies', adminCtrl.listCompanies);
router.get('/audit-logs', adminCtrl.getAuditLogs);

// Institution Approvals
router.get('/pending-universities', adminCtrl.getPendingUniversities);
router.patch('/university-status/:id', adminCtrl.updateUniversityStatus);
router.delete('/universities/:id', adminCtrl.deleteUniversity);

router.get('/pending-companies', adminCtrl.getPendingCompanies);
router.patch('/company-status/:id', adminCtrl.updateCompanyStatus);
router.delete('/companies/:id', adminCtrl.deleteCompany);

// ── Admin Manual Creation (Universities & Companies) ──────────────────────────
// POST /admin/universities — create university + optional coordinator (sends setup link)
// POST /admin/companies   — create company + optional supervisor (sends setup link)
// PATCH /admin/universities/:id/config — per-university student registration toggle
router.post('/universities', onboardCtrl.adminCreateUniversity);
router.post('/companies', onboardCtrl.adminCreateCompany);
router.patch('/universities/:id/config', onboardCtrl.updateUniversityConfig);

// File Upload
router.post('/upload-verification', uploadVerification.single('file'), adminCtrl.uploadVerificationDocument);

// User Management
router.get('/users', adminCtrl.getAllUsers);
router.patch('/users/:id/institution-access', adminCtrl.updateUserInstitutionAccess);
router.patch('/users/:id/mark-viewed', adminCtrl.markUserDocumentViewed);

// Coordinator Approval Workflow
router.get('/pending-coordinators', adminCtrl.getPendingCoordinators);
router.get('/approved-coordinators', adminCtrl.getApprovedCoordinators);
router.get('/rejected-coordinators', adminCtrl.getRejectedCoordinators);
router.get('/suspended-coordinators', adminCtrl.getSuspendedCoordinators);
router.post('/coordinators/:userId/approve', adminCtrl.approveCoordinator);
router.post('/coordinators/:userId/reject', adminCtrl.rejectCoordinator);
router.post('/coordinators/:userId/suspend', adminCtrl.suspendCoordinator);
router.post('/coordinators/:userId/reactivate', adminCtrl.reactivateCoordinator);
router.delete('/coordinators/:userId', adminCtrl.deleteCoordinator);

// Supervisor Approval Workflow
router.get('/pending-supervisors', adminCtrl.getPendingSupervisors);
router.get('/approved-supervisors', adminCtrl.getApprovedSupervisors);
router.get('/rejected-supervisors', adminCtrl.getRejectedSupervisors);
router.get('/suspended-supervisors', adminCtrl.getSuspendedSupervisors);
router.post('/supervisors/:userId/approve', adminCtrl.approveSupervisor);
router.post('/supervisors/:userId/reject', adminCtrl.rejectSupervisor);
router.post('/supervisors/:userId/suspend', adminCtrl.suspendSupervisor);
router.post('/supervisors/:userId/reactivate', adminCtrl.reactivateSupervisor);
router.delete('/supervisors/:userId', adminCtrl.deleteSupervisor);

// HOD Approval Workflow - MOVED TO COORDINATOR
router.get('/pending-hods', adminCtrl.getPendingHods);
// router.post('/hods/:userId/approve', adminCtrl.approveHod);
// router.post('/hods/:userId/reject', adminCtrl.rejectHod);

// Common Page Feed
router.post('/announcements', adminCtrl.postAnnouncement);

// System Configuration
router.get('/config', configCtrl.getConfig);
router.patch('/config', configCtrl.updateConfig);
router.post('/config/test-smtp', configCtrl.testSmtp);
router.get('/config/export-audit-csv', configCtrl.exportAuditLogCsv);
router.post('/config/broadcast', configCtrl.broadcastAnnouncement);

// Analytics
router.get('/analytics', adminCtrl.getAnalytics);

// ── Merge Tools (duplicate organization management) ───────────────────────────
router.get('/merge/duplicates/universities', mergeCtrl.findDuplicateUniversities);
router.get('/merge/duplicates/companies', mergeCtrl.findDuplicateCompanies);
router.post('/merge/universities', mergeCtrl.mergeUniversities);
router.post('/merge/companies', mergeCtrl.mergeCompanies);

export default router;