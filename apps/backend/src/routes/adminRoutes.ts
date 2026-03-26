import { Router } from 'express';
import * as adminCtrl from '../controllers/adminController';
import { authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

// Apply Admin protection to ALL routes in this file
router.use(authorize([Role.ADMIN]));

// Dashboard & Stats
router.get('/stats', adminCtrl.getDashboardStats);

// Institution Approvals
router.get('/pending-universities', adminCtrl.getPendingUniversities);
router.patch('/university-status/:id', adminCtrl.updateUniversityStatus);

router.get('/pending-companies', adminCtrl.getPendingCompanies);
router.patch('/company-status/:id', adminCtrl.updateCompanyStatus);

// User Management
router.get('/users', adminCtrl.getAllUsers);

// Common Page Feed
router.post('/announcements', adminCtrl.postAnnouncement);

export default router;