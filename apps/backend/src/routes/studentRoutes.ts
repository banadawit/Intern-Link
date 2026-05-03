import { Router } from 'express';
import * as studentCtrl from '../controllers/studentController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { uploadDocument } from '../config/multer.config';

const router = Router();
router.use(authenticate);

// Only Coordinators can register students
router.post('/register', authorize([Role.COORDINATOR]), studentCtrl.registerStudent);

// Only Students can view their own profile
router.get('/me', authorize([Role.STUDENT]), studentCtrl.getMyStudentProfile);

// Student: submit open letter request to HoD
router.post('/open-letter', authorize([Role.STUDENT]), studentCtrl.submitOpenLetter);

// Weekly presentation upload
router.post('/upload-presentation', authorize([Role.STUDENT]), uploadDocument.single('file'), studentCtrl.uploadWeeklyPresentation);

export default router;
