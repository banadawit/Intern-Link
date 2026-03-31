import { Router } from 'express';
import * as placementCtrl from '../controllers/placementController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();
router.use(authenticate);

// Coordinators initiate
router.post('/proposals', authorize([Role.COORDINATOR]), placementCtrl.sendPlacementProposal);

// Student: own proposals
router.get('/my-proposals', authorize([Role.STUDENT]), placementCtrl.getMyProposals);

// Supervisors respond
router.get('/incoming', authorize([Role.SUPERVISOR]), placementCtrl.getIncomingProposals);
router.patch('/respond/:id', authorize([Role.SUPERVISOR]), placementCtrl.respondToProposal);

export default router;
