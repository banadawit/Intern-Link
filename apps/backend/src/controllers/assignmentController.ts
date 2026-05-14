import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendSuccess, sendError } from '../utils/responseHelper';
import {
  assignStudentsToTeamAndProject,
  reassignStudentToTeam,
  reassignTeamToProject,
} from '../services/assignmentService';
import { sendNotification } from '../utils/notificationHelper';
import { sendProjectAssignmentEmail } from '../services/email.service';

async function getSupervisor(req: AuthRequest) {
  return prisma.supervisor.findUnique({
    where: { userId: req.user!.userId },
    include: { user: { select: { full_name: true } } },
  });
}

// ── POST /supervisor/assignments ──────────────────────────────────────────────
/**
 * Bulk assign students to a team (new or existing) and optionally link to a project.
 *
 * Body:
 *   studentIds: number[]          — required, min 1
 *   teamId?: number               — use existing team
 *   teamName?: string             — create new team (required if no teamId)
 *   projectId?: number            — link team to this project
 */
export const createAssignment = async (req: AuthRequest, res: Response) => {
  try {
    const sup = await getSupervisor(req);
    if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

    const { studentIds, teamId, teamName, projectId } = req.body as {
      studentIds?: unknown;
      teamId?: unknown;
      teamName?: unknown;
      projectId?: unknown;
    };

    if (!Array.isArray(studentIds) || studentIds.length === 0) {
      return sendError(res, 'studentIds must be a non-empty array.', 400);
    }

    const parsedStudentIds = studentIds.map((id) => parseInt(String(id), 10)).filter((n) => !Number.isNaN(n));
    if (parsedStudentIds.length === 0) {
      return sendError(res, 'No valid studentIds provided.', 400);
    }

    const parsedTeamId = teamId != null ? parseInt(String(teamId), 10) : undefined;
    const parsedProjectId = projectId != null ? parseInt(String(projectId), 10) : undefined;
    const parsedTeamName = typeof teamName === 'string' ? teamName.trim() : undefined;

    if (parsedTeamId == null && !parsedTeamName) {
      return sendError(res, 'Either teamId (existing) or teamName (new) is required.', 400);
    }

    const result = await assignStudentsToTeamAndProject({
      supervisorId: sup.id,
      companyId: sup.companyId,
      supervisorName: sup.user.full_name,
      studentIds: parsedStudentIds,
      teamId: parsedTeamId,
      teamName: parsedTeamName,
      projectId: parsedProjectId,
    });

    return sendSuccess(
      res,
      result,
      `${result.assignedStudents.length} student(s) assigned to team "${result.team.name}"${result.project ? ` on project "${result.project.name}"` : ''}.`,
      201,
    );
  } catch (error: unknown) {
    const e = error as Error & { status?: number };
    return sendError(res, e.message, e.status ?? 500);
  }
};

// ── GET /supervisor/assignments ───────────────────────────────────────────────
/**
 * List all active assignments for the supervisor's company.
 * Returns students with their team and project info.
 */
export const listAssignments = async (req: AuthRequest, res: Response) => {
  try {
    const sup = await getSupervisor(req);
    if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

    const assignments = await prisma.internshipAssignment.findMany({
      where: { companyId: sup.companyId, status: 'ACTIVE' },
      include: {
        student: {
          include: {
            user: { select: { id: true, full_name: true, email: true } },
            studentTeams: {
              include: {
                team: {
                  select: {
                    id: true,
                    name: true,
                    projectId: true,
                    project: { select: { id: true, name: true } },
                  },
                },
              },
              where: { team: { companyId: sup.companyId, deleted_at: null } },
            },
            studentProjects: {
              include: {
                project: { select: { id: true, name: true } },
              },
              where: { project: { companyId: sup.companyId, deleted_at: null } },
            },
          },
        },
      },
      orderBy: { start_date: 'desc' },
    });

    const payload = assignments.map((a) => ({
      assignmentId: a.id,
      studentId: a.student.id,
      studentName: a.student.user.full_name,
      studentEmail: a.student.user.email,
      startDate: a.start_date,
      endDate: a.end_date,
      projectName: a.project_name,
      teams: a.student.studentTeams.map((st) => ({
        id: st.team.id,
        name: st.team.name,
        linkedProject: st.team.project ?? null,
      })),
      projects: a.student.studentProjects.map((sp) => sp.project),
    }));

    return sendSuccess(res, payload, 'Assignments fetched.');
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Server error';
    return sendError(res, message, 500);
  }
};

// ── PATCH /supervisor/assignments/students/:studentId/team ────────────────────
/**
 * Move a student to a different team.
 * Body: { teamId: number }
 */
export const moveStudentToTeam = async (req: AuthRequest, res: Response) => {
  try {
    const sup = await getSupervisor(req);
    if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

    const studentId = parseInt(String(req.params.studentId), 10);
    const newTeamId = parseInt(String(req.body?.teamId), 10);

    if (Number.isNaN(studentId) || Number.isNaN(newTeamId)) {
      return sendError(res, 'studentId and teamId are required.', 400);
    }

    await reassignStudentToTeam(sup.companyId, studentId, newTeamId);
    return sendSuccess(res, { studentId, newTeamId }, 'Student moved to new team.');
  } catch (error: unknown) {
    const e = error as Error & { status?: number };
    return sendError(res, e.message, e.status ?? 500);
  }
};

// ── PATCH /supervisor/assignments/teams/:teamId/project ───────────────────────
/**
 * Move a team to a different project.
 * Body: { projectId: number }
 */
export const moveTeamToProject = async (req: AuthRequest, res: Response) => {
  try {
    const sup = await getSupervisor(req);
    if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

    const teamId = parseInt(String(req.params.teamId), 10);
    const newProjectId = parseInt(String(req.body?.projectId), 10);

    if (Number.isNaN(teamId) || Number.isNaN(newProjectId)) {
      return sendError(res, 'teamId and projectId are required.', 400);
    }

    const result = await reassignTeamToProject(sup.companyId, teamId, newProjectId);

    // Notify all team members by email + in-app notification (fire-and-forget)
    void (async () => {
      try {
        const [team, supervisorProfile] = await Promise.all([
          prisma.team.findUnique({
            where: { id: teamId },
            include: {
              members: {
                include: {
                  student: { include: { user: { select: { id: true, email: true, full_name: true } } } },
                },
              },
            },
          }),
          prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
            include: { user: { select: { full_name: true } }, company: { select: { name: true } } },
          }),
        ]);
        const project = await prisma.project.findUnique({
          where: { id: newProjectId },
          select: { name: true },
        });
        if (team && supervisorProfile && project) {
          for (const m of team.members) {
            const s = m.student;
            const msg = `Your team "${team.name}" has been assigned to project "${project.name}" at ${supervisorProfile.company.name} by ${supervisorProfile.user.full_name}.`;
            sendNotification(s.user.id, msg).catch(() => {});
            sendProjectAssignmentEmail({
              to: s.user.email,
              studentName: s.user.full_name,
              projectName: project.name,
              companyName: supervisorProfile.company.name,
              supervisorName: supervisorProfile.user.full_name,
            }).catch(() => {});
          }
        }
      } catch {
        // Non-fatal — don't fail the response
      }
    })();

    return sendSuccess(
      res,
      { teamId, newProjectId, ...result },
      result.warned ? result.warningMessage! : 'Team moved to new project.',
    );
  } catch (error: unknown) {
    const e = error as Error & { status?: number };
    return sendError(res, e.message, e.status ?? 500);
  }
};
