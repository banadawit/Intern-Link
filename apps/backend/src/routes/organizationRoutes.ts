import { Router } from 'express';
import { 
    searchOrganizations, 
    requestNewOrganization, 
    adminGetRequests, 
    adminApproveRequest, 
    adminRejectRequest,
    adminMarkDocumentViewed,
    adminMergeOrganizations
} from '../controllers/organizationController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { uploadVerification } from '../config/multer.config';

const router = Router();

/**
 * Public organization search & request routes
 * Used during registration for autocomplete and new institution requests.
 */
router.get('/search', searchOrganizations);
router.post('/request', uploadVerification.single('verification_doc'), requestNewOrganization);

// Backward compatibility (optional, but good to have)
router.get('/universities/search', (req, res) => { req.query.type = 'UNIVERSITY'; searchOrganizations(req, res); });
router.get('/companies/search', (req, res) => { req.query.type = 'COMPANY'; searchOrganizations(req, res); });

/**
 * Admin only management routes
 */
router.get('/admin/requests', authenticate, authorize([Role.ADMIN]), adminGetRequests);
router.patch('/admin/requests/:id/view', authenticate, authorize([Role.ADMIN]), adminMarkDocumentViewed);
router.post('/admin/requests/:id/approve', authenticate, authorize([Role.ADMIN]), adminApproveRequest);
router.post('/admin/requests/:id/reject', authenticate, authorize([Role.ADMIN]), adminRejectRequest);
router.post('/admin/merge', authenticate, authorize([Role.ADMIN]), adminMergeOrganizations);

export default router;
