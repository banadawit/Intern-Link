import { Router } from 'express';
import * as supervisorCtrl from '../controllers/supervisorController';
import * as supervisorTeamCtrl from '../controllers/supervisorTeamController';
import * as assignmentCtrl from '../controllers/assignmentController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { uploadImage } from '../config/multer.config';

import { validate } from '../middlewares/validationMiddleware';
import { evaluationSchema, teamSchema } from '../validations/supervisorValidation';

const router = Router();
router.use(authenticate);
router.use(authorize([Role.SUPERVISOR]));

router.get('/me', supervisorCtrl.getSupervisorMe);
router.get('/performance', supervisorCtrl.getSupervisorPerformance);
router.get('/students', supervisorCtrl.getCompanyStudents);
router.get('/weekly-plans', supervisorCtrl.getCompanyWeeklyPlans);

router.get('/weekly-reports', supervisorCtrl.listWeeklyAttendanceReports);
router.patch('/weekly-reports/:id', supervisorCtrl.patchWeeklyAttendanceReport);
router.get('/attendance-heatmap', supervisorCtrl.getAttendanceHeatmap);

// Company stamp upload
router.post('/upload-stamp', uploadImage.single('file'), supervisorCtrl.uploadCompanyStamp);

// ── Teams ─────────────────────────────────────────────────────────────────────
router.get('/teams', supervisorTeamCtrl.listTeams);
router.post('/teams', validate(teamSchema), supervisorTeamCtrl.createTeam);
router.delete('/teams/:id', supervisorTeamCtrl.deleteTeam);
router.patch('/teams/:id/restore', supervisorTeamCtrl.restoreTeam);
router.post('/teams/:id/members', supervisorTeamCtrl.addTeamMember);
router.delete('/teams/:teamId/members/:studentId', supervisorTeamCtrl.removeTeamMember);

// ── Projects ──────────────────────────────────────────────────────────────────
router.get('/projects', supervisorTeamCtrl.listProjects);
router.post('/projects', supervisorTeamCtrl.createProject);
router.delete('/projects/:id', supervisorTeamCtrl.deleteProject);
router.patch('/projects/:id/restore', supervisorTeamCtrl.restoreProject);
router.post('/projects/:id/members', supervisorTeamCtrl.addProjectMember);
router.delete('/projects/:projectId/members/:studentId', supervisorTeamCtrl.removeProjectMember);

// ── Assignments (bulk + reassignment) ────────────────────────────────────────
// POST   /supervisor/assignments          — bulk assign students to team+project
// GET    /supervisor/assignments          — list all active assignments with team/project info
// PATCH  /supervisor/assignments/students/:studentId/team   — move student to different team
// PATCH  /supervisor/assignments/teams/:teamId/project      — move team to different project
router.post('/assignments', assignmentCtrl.createAssignment);
router.get('/assignments', assignmentCtrl.listAssignments);
router.patch('/assignments/students/:studentId/team', assignmentCtrl.moveStudentToTeam);
router.patch('/assignments/teams/:teamId/project', assignmentCtrl.moveTeamToProject);

router.post('/evaluation', validate(evaluationSchema), supervisorCtrl.submitEvaluation);

export default router;
