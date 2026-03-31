import { Router } from 'express';
import { setupCompany, getMyCompanyProfile } from '../controllers/companyController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { uploadStamp } from '../middlewares/uploadMiddleware';
import { Role } from '@prisma/client';

const router = Router();
router.use(authenticate);

// Route: POST /api/companies/setup
// Uses 'uploadStamp.single' to handle the "stamp" field in the form-data
router.post('/setup', authorize([Role.SUPERVISOR]), uploadStamp.single('stamp'), setupCompany);

router.get('/profile', authorize([Role.SUPERVISOR]), getMyCompanyProfile);

export default router;