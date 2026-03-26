import { Router } from 'express';
import * as placementCtrl from '../controllers/placementController';
import { authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();

// Coordinators initiate
router.post('/proposals', authorize([Role.COORDINATOR]), placementCtrl.sendPlacementProposal);

// Supervisors respond
router.get('/incoming', authorize([Role.SUPERVISOR]), placementCtrl.getIncomingProposals);
router.patch('/respond/:id', authorize([Role.SUPERVISOR]), placementCtrl.respondToProposal);

export default router;