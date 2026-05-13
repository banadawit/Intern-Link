import { Router } from 'express';
import * as studentCtrl from '../controllers/studentController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { uploadDocument } from '../config/multer.config';
import multer from 'multer';

const router = Router();
router.use(authenticate);

// Only Coordinators can register students
router.post('/register', authorize([Role.COORDINATOR]), studentCtrl.registerStudent);

// Only Students can view their own profile
router.get('/me', authorize([Role.STUDENT]), studentCtrl.getMyStudentProfile);

// Student: submit open letter request to HoD (multipart: stamp + verification_doc)
const openLetterUpload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (_req, file, cb) => {
        const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
        cb(null, allowed.includes(file.mimetype));
    },
}).fields([
    { name: 'stamp', maxCount: 1 },
    { name: 'verification_doc', maxCount: 1 },
]);
router.post('/open-letter', authorize([Role.STUDENT]), openLetterUpload, studentCtrl.submitOpenLetter);

// Weekly presentation upload
router.post('/upload-presentation', authorize([Role.STUDENT]), uploadDocument.single('file'), studentCtrl.uploadWeeklyPresentation);

// Student: view their team
router.get('/my-team', authorize([Role.STUDENT]), studentCtrl.getMyTeam);

export default router;
