// src/routes/feedRoutes.ts
import { Router } from 'express';
import * as feedCtrl from '../controllers/feedController';
import { authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

// 1. Get the chronological feed (Visible to ALL authenticated roles)
router.get('/',
    authorize([Role.ADMIN, Role.COORDINATOR, Role.SUPERVISOR, Role.STUDENT]),
    feedCtrl.getFeed
);

// 2. Create a new post/announcement
router.post('/',
    authorize([Role.ADMIN, Role.COORDINATOR, Role.SUPERVISOR, Role.STUDENT]),
    feedCtrl.createPost
);

export default router;