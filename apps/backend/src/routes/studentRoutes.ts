import { Router } from 'express';
import * as studentCtrl from '../controllers/studentController';
import { authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

// Only Coordinators can register students
router.post('/register', authorize([Role.COORDINATOR]), studentCtrl.registerStudent);

// Only Students can view their own profile
router.get('/me', authorize([Role.STUDENT]), studentCtrl.getMyStudentProfile);

export default router;