import { Router } from 'express';
import { authenticate } from '../middlewares/authMiddleware';
import * as activityCtrl from '../controllers/activityController';

const router = Router();
router.use(authenticate);
router.get('/', activityCtrl.getActivity);

export default router;
