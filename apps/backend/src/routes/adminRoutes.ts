import { Router } from 'express';
import * as adminCtrl from '../controllers/adminController';
import * as configCtrl from '../controllers/systemConfigController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

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

router.get('/pending-companies', adminCtrl.getPendingCompanies);
router.patch('/company-status/:id', adminCtrl.updateCompanyStatus);

// User Management
router.get('/users', adminCtrl.getAllUsers);
router.patch('/users/:id/institution-access', adminCtrl.updateUserInstitutionAccess);

// Coordinator Approval Workflow
router.get('/pending-coordinators', adminCtrl.getPendingCoordinators);
router.get('/approved-coordinators', adminCtrl.getApprovedCoordinators);
router.get('/rejected-coordinators', adminCtrl.getRejectedCoordinators);
router.get('/suspended-coordinators', adminCtrl.getSuspendedCoordinators);
router.post('/coordinators/:userId/approve', adminCtrl.approveCoordinator);
router.post('/coordinators/:userId/reject', adminCtrl.rejectCoordinator);

// Supervisor Approval Workflow
router.get('/pending-supervisors', adminCtrl.getPendingSupervisors);
router.get('/approved-supervisors', adminCtrl.getApprovedSupervisors);
router.get('/rejected-supervisors', adminCtrl.getRejectedSupervisors);
router.get('/suspended-supervisors', adminCtrl.getSuspendedSupervisors);
router.post('/supervisors/:userId/approve', adminCtrl.approveSupervisor);
router.post('/supervisors/:userId/reject', adminCtrl.rejectSupervisor);

// Common Page Feed
router.post('/announcements', adminCtrl.postAnnouncement);

// System Configuration
router.get('/config', configCtrl.getConfig);
router.patch('/config', configCtrl.updateConfig);
router.post('/config/test-smtp', configCtrl.testSmtp);
router.get('/config/export-audit-csv', configCtrl.exportAuditLogCsv);
router.post('/config/broadcast', configCtrl.broadcastAnnouncement);

export default router;