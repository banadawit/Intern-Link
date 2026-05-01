import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { sendNotification } from '../utils/notificationHelper';
import { sendProjectAssignmentEmail } from '../services/email.service';
import { sendSuccess, sendError } from '../utils/responseHelper';

async function getSupervisor(req: AuthRequest) {
    return prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
}

async function assertActiveStudentAtCompany(companyId: number, studentId: number) {
    const a = await prisma.internshipAssignment.findFirst({
        where: { companyId, studentId, status: 'ACTIVE' },
    });
    if (!a) {
        const err = new Error('Student is not actively placed at your company.');
        (err as Error & { status: number }).status = 403;
        throw err;
    }
}

export const listTeams = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

        const [active, deleted] = await Promise.all([
            prisma.team.findMany({
                where: { companyId: sup.companyId, deleted_at: null },
                include: {
                    members: {
                        include: {
                            student: { include: { user: { select: { full_name: true, email: true } } } },
                        },
                    },
                    project: { select: { id: true, name: true } },
                },
                orderBy: { name: 'asc' },
            }),
            prisma.team.findMany({
                where: { companyId: sup.companyId, deleted_at: { not: null } },
                select: { id: true, name: true, deleted_at: true },
                orderBy: { deleted_at: 'desc' },
            }),
        ]);
        return sendSuccess(res, { active, deleted });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const createTeam = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const name = typeof req.body?.name === 'string' ? req.body.name.trim() : '';
        if (!name) return sendError(res, 'Team name is required.', 400);
        const projectId = req.body?.projectId != null ? parseInt(String(req.body.projectId), 10) : undefined;

        const team = await prisma.team.create({
            data: {
                name,
                companyId: sup.companyId,
                supervisorId: sup.id,
                projectId: projectId && !Number.isNaN(projectId) ? projectId : null,
            },
        });
        return sendSuccess(res, team, 'Team created.', 201);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const deleteTeam = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const id = parseInt(String(req.params.id), 10);
        const team = await prisma.team.findFirst({ where: { id, companyId: sup.companyId, deleted_at: null } });
        if (!team) return sendError(res, 'Team not found.', 404);
        await prisma.team.update({ where: { id }, data: { deleted_at: new Date() } });
        return sendSuccess(res, { id }, 'Team moved to trash. You have 24 hours to restore it.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const restoreTeam = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const id = parseInt(String(req.params.id), 10);
        const team = await prisma.team.findFirst({ where: { id, companyId: sup.companyId, deleted_at: { not: null } } });
        if (!team) return sendError(res, 'Team not found in trash.', 404);
        await prisma.team.update({ where: { id }, data: { deleted_at: null } });
        return sendSuccess(res, { id }, 'Team restored.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const addTeamMember = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const teamId = parseInt(String(req.params.id), 10);
        const studentId = parseInt(String(req.body?.studentId), 10);
        if (Number.isNaN(studentId)) return sendError(res, 'studentId required.', 400);

        const team = await prisma.team.findFirst({
            where: { id: teamId, companyId: sup.companyId, deleted_at: null },
        });
        if (!team) return sendError(res, 'Team not found.', 404);

        await assertActiveStudentAtCompany(sup.companyId, studentId);

        await prisma.studentTeam.create({ data: { teamId, studentId } });
        return sendSuccess(res, { teamId, studentId }, 'Member added.', 201);
    } catch (error: unknown) {
        const e = error as Error & { status?: number };
        if (e.status === 403) return sendError(res, e.message, 403);
        const message = error instanceof Error ? error.message : 'Server error';
        if (message.includes('Unique constraint')) return sendError(res, 'Student already in team.', 400);
        return sendError(res, message, 500);
    }
};

export const removeTeamMember = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const teamId = parseInt(String(req.params.teamId), 10);
        const studentId = parseInt(String(req.params.studentId), 10);

        const team = await prisma.team.findFirst({ where: { id: teamId, companyId: sup.companyId } });
        if (!team) return sendError(res, 'Team not found.', 404);

        await prisma.studentTeam.delete({
            where: { studentId_teamId: { studentId, teamId } },
        });
        return sendSuccess(res, { teamId, studentId }, 'Member removed.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const listProjects = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

        const [active, deleted] = await Promise.all([
            prisma.project.findMany({
                where: { companyId: sup.companyId, deleted_at: null },
                include: {
                    students: {
                        include: {
                            student: { include: { user: { select: { full_name: true, email: true } } } },
                        },
                    },
                    teams: {
                        where: { deleted_at: null },
                        select: { id: true, name: true },
                    },
                },
                orderBy: { name: 'asc' },
            }),
            prisma.project.findMany({
                where: { companyId: sup.companyId, deleted_at: { not: null } },
                select: { id: true, name: true, deleted_at: true },
                orderBy: { deleted_at: 'desc' },
            }),
        ]);
        return sendSuccess(res, { active, deleted });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const createProject = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);

        const name = typeof req.body?.name === 'string' ? req.body.name.trim() : '';
        if (!name) return sendError(res, 'Project name is required.', 400);

        const description = typeof req.body?.description === 'string' ? req.body.description.trim() : null;
        const capacity = req.body?.capacity != null ? parseInt(String(req.body.capacity), 10) : 0;
        const requiredSkills: string[] = Array.isArray(req.body?.requiredSkills)
            ? req.body.requiredSkills.map(String).filter(Boolean)
            : [];

        const project = await prisma.project.create({
            data: {
                name,
                description,
                capacity: Number.isNaN(capacity) ? 0 : capacity,
                requiredSkills,
                companyId: sup.companyId,
                supervisorId: sup.id,
            },
        });
        return sendSuccess(res, project, 'Project created.', 201);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const deleteProject = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const id = parseInt(String(req.params.id), 10);
        const project = await prisma.project.findFirst({
            where: { id, companyId: sup.companyId, deleted_at: null },
        });
        if (!project) return sendError(res, 'Project not found.', 404);
        await prisma.project.update({ where: { id }, data: { deleted_at: new Date() } });
        return sendSuccess(res, { id }, 'Project moved to trash. You have 24 hours to restore it.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const restoreProject = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const id = parseInt(String(req.params.id), 10);
        const project = await prisma.project.findFirst({
            where: { id, companyId: sup.companyId, deleted_at: { not: null } },
        });
        if (!project) return sendError(res, 'Project not found in trash.', 404);
        await prisma.project.update({ where: { id }, data: { deleted_at: null } });
        return sendSuccess(res, { id }, 'Project restored.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const addProjectMember = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const projectId = parseInt(String(req.params.id), 10);
        const studentId = parseInt(String(req.body?.studentId), 10);
        if (Number.isNaN(studentId)) return sendError(res, 'studentId required.', 400);

        const project = await prisma.project.findFirst({
            where: { id: projectId, companyId: sup.companyId, deleted_at: null },
            include: { students: { select: { studentId: true } } },
        });
        if (!project) return sendError(res, 'Project not found.', 404);

        // Capacity check
        if (project.capacity > 0 && project.students.length >= project.capacity) {
            return sendError(res, `Project is at full capacity (${project.capacity} students).`, 400);
        }

        await assertActiveStudentAtCompany(sup.companyId, studentId);

        // Block if student is already assigned to any other active project at this company
        const alreadyInProject = await prisma.studentProject.findFirst({
            where: { studentId, project: { companyId: sup.companyId, deleted_at: null } },
        });
        if (alreadyInProject) {
            return sendError(res, 'This student is already assigned to another project. Remove them first.', 400);
        }

        await prisma.studentProject.create({ data: { projectId, studentId } });

        // Update assignment project_name
        await prisma.internshipAssignment.updateMany({
            where: { studentId, companyId: sup.companyId, status: 'ACTIVE' },
            data: { project_name: project.name },
        });

        // Notify student (fire-and-forget)
        const [assignedStudent, supervisorProfile] = await Promise.all([
            prisma.student.findUnique({ where: { id: studentId }, include: { user: { select: { id: true, email: true, full_name: true } } } }),
            prisma.supervisor.findUnique({ where: { userId: req.user!.userId }, include: { user: { select: { full_name: true } }, company: { select: { name: true } } } }),
        ]);

        if (assignedStudent && supervisorProfile) {
            const msg = `You have been assigned to project "${project.name}" at ${supervisorProfile.company.name} by ${supervisorProfile.user.full_name}.`;
            sendNotification(assignedStudent.user.id, msg).catch(() => {});
            sendProjectAssignmentEmail({
                to: assignedStudent.user.email,
                studentName: assignedStudent.user.full_name,
                projectName: project.name,
                companyName: supervisorProfile.company.name,
                supervisorName: supervisorProfile.user.full_name,
            }).catch(() => {});
        }

        return sendSuccess(res, { projectId, studentId }, 'Student linked to project.', 201);
    } catch (error: unknown) {
        const e = error as Error & { status?: number };
        if (e.status === 403) return sendError(res, e.message, 403);
        const message = error instanceof Error ? error.message : 'Server error';
        if (message.includes('Unique constraint')) return sendError(res, 'Student already on project.', 400);
        return sendError(res, message, 500);
    }
};

export const removeProjectMember = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return sendError(res, 'Supervisor profile not found.', 403);
        const projectId = parseInt(String(req.params.projectId), 10);
        const studentId = parseInt(String(req.params.studentId), 10);

        const project = await prisma.project.findFirst({ where: { id: projectId, companyId: sup.companyId } });
        if (!project) return sendError(res, 'Project not found.', 404);

        await prisma.studentProject.delete({
            where: { studentId_projectId: { studentId, projectId } },
        });
        return sendSuccess(res, { projectId, studentId }, 'Student removed from project.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

