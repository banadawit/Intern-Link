import { Router } from 'express';
import * as supervisorCtrl from '../controllers/supervisorController';
import * as supervisorTeamCtrl from '../controllers/supervisorTeamController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';

const router = Router();
router.use(authenticate);
router.use(authorize([Role.SUPERVISOR]));

router.get('/me', supervisorCtrl.getSupervisorMe);
router.get('/students', supervisorCtrl.getCompanyStudents);
router.get('/weekly-plans', supervisorCtrl.getCompanyWeeklyPlans);

router.get('/weekly-reports', supervisorCtrl.listWeeklyAttendanceReports);
router.patch('/weekly-reports/:id', supervisorCtrl.patchWeeklyAttendanceReport);
router.get('/attendance-heatmap', supervisorCtrl.getAttendanceHeatmap);

router.get('/teams', supervisorTeamCtrl.listTeams);
router.post('/teams', supervisorTeamCtrl.createTeam);
router.delete('/teams/:id', supervisorTeamCtrl.deleteTeam);
router.post('/teams/:id/members', supervisorTeamCtrl.addTeamMember);
router.delete('/teams/:teamId/members/:studentId', supervisorTeamCtrl.removeTeamMember);

router.get('/projects', supervisorTeamCtrl.listProjects);
router.post('/projects', supervisorTeamCtrl.createProject);
router.delete('/projects/:id', supervisorTeamCtrl.deleteProject);
router.patch('/projects/:id/restore', supervisorTeamCtrl.restoreProject);
router.post('/projects/:id/members', supervisorTeamCtrl.addProjectMember);
router.delete('/projects/:projectId/members/:studentId', supervisorTeamCtrl.removeProjectMember);

export default router;
