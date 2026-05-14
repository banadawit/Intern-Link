import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import * as ctrl from '../controllers/jobOpportunityController';

const router = Router();
router.use(authenticate);

const ALL = [Role.ADMIN, Role.COORDINATOR, Role.HOD, Role.SUPERVISOR, Role.STUDENT];
const SUP = [Role.SUPERVISOR];
const STU = [Role.STUDENT];

// Supervisor: own opportunities (must be before /:id)
router.get('/mine', authorize(SUP), ctrl.myOpportunities);

// All roles: browse open opportunities
router.get('/', authorize(ALL), ctrl.listOpportunities);

// All roles: get single opportunity details
router.get('/:id', authorize(ALL), ctrl.getOpportunity);

// Supervisor: create opportunity
router.post('/', authorize(SUP), ctrl.createOpportunity);

// Supervisor: update status (open/close)
router.patch('/:id/status', authorize(SUP), ctrl.updateOpportunityStatus);

// Supervisor: announce winners
router.post('/:id/announce', authorize(SUP), ctrl.announceWinners);

// Supervisor: list all applicants
router.get('/:id/applications', authorize(SUP), ctrl.listApplications);

// Supervisor: view single application + student profile
router.get('/:id/applications/:appId', authorize(SUP), ctrl.getApplication);

// Supervisor: accept / reject application
router.patch('/:id/applications/:appId', authorize(SUP), ctrl.reviewApplication);

// Student: apply
router.post('/:id/apply', authorize(STU), ctrl.applyToOpportunity);

export default router;
