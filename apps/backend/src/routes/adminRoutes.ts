import { Router } from 'express';
import * as adminCtrl from '../controllers/adminController';
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

// Common Page Feed
router.post('/announcements', adminCtrl.postAnnouncement);

export default router;