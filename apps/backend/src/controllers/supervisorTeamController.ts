import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

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
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });

        const [active, deleted] = await Promise.all([
            prisma.team.findMany({
                where: { companyId: sup.companyId, deleted_at: null },
                include: {
                    members: {
                        include: {
                            student: { include: { user: { select: { full_name: true, email: true } } } },
                        },
                    },
                },
                orderBy: { name: 'asc' },
            }),
            prisma.team.findMany({
                where: { companyId: sup.companyId, deleted_at: { not: null } },
                select: { id: true, name: true, deleted_at: true },
                orderBy: { deleted_at: 'desc' },
            }),
        ]);
        res.json({ active, deleted });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const createTeam = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const name = typeof req.body?.name === 'string' ? req.body.name.trim() : '';
        if (!name) return res.status(400).json({ message: 'Team name is required.' });

        const team = await prisma.team.create({
            data: { name, companyId: sup.companyId },
        });
        res.status(201).json(team);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const deleteTeam = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const id = parseInt(String(req.params.id), 10);
        const team = await prisma.team.findFirst({ where: { id, companyId: sup.companyId, deleted_at: null } });
        if (!team) return res.status(404).json({ message: 'Team not found.' });
        await prisma.team.update({ where: { id }, data: { deleted_at: new Date() } });
        res.json({ message: 'Team moved to trash. You have 24 hours to restore it.' });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const restoreTeam = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const id = parseInt(String(req.params.id), 10);
        const team = await prisma.team.findFirst({ where: { id, companyId: sup.companyId, deleted_at: { not: null } } });
        if (!team) return res.status(404).json({ message: 'Team not found in trash.' });
        await prisma.team.update({ where: { id }, data: { deleted_at: null } });
        res.json({ message: 'Team restored.' });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const addTeamMember = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const teamId = parseInt(String(req.params.id), 10);
        const studentId = parseInt(String(req.body?.studentId), 10);
        if (Number.isNaN(studentId)) return res.status(400).json({ message: 'studentId required.' });

        const team = await prisma.team.findFirst({
            where: { id: teamId, companyId: sup.companyId },
        });
        if (!team) return res.status(404).json({ message: 'Team not found.' });

        await assertActiveStudentAtCompany(sup.companyId, studentId);

        await prisma.studentTeam.create({
            data: { teamId, studentId },
        });
        res.status(201).json({ message: 'Member added.' });
    } catch (error: unknown) {
        const e = error as Error & { status?: number };
        if (e.status === 403) return res.status(403).json({ message: e.message });
        const message = error instanceof Error ? error.message : 'Server error';
        if (message.includes('Unique constraint')) {
            return res.status(400).json({ message: 'Student already in team.' });
        }
        res.status(500).json({ error: message });
    }
};

export const removeTeamMember = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const teamId = parseInt(String(req.params.teamId), 10);
        const studentId = parseInt(String(req.params.studentId), 10);

        const team = await prisma.team.findFirst({
            where: { id: teamId, companyId: sup.companyId },
        });
        if (!team) return res.status(404).json({ message: 'Team not found.' });

        await prisma.studentTeam.delete({
            where: { studentId_teamId: { studentId, teamId } },
        });
        res.json({ message: 'Member removed.' });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const listProjects = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });

        const [active, deleted] = await Promise.all([
            prisma.project.findMany({
                where: { companyId: sup.companyId, deleted_at: null },
                include: {
                    students: {
                        include: {
                            student: { include: { user: { select: { full_name: true, email: true } } } },
                        },
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
        res.json({ active, deleted });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const createProject = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const name = typeof req.body?.name === 'string' ? req.body.name.trim() : '';
        if (!name) return res.status(400).json({ message: 'Project name is required.' });

        const project = await prisma.project.create({
            data: { name, companyId: sup.companyId },
        });
        res.status(201).json(project);
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const deleteProject = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const id = parseInt(String(req.params.id), 10);
        const project = await prisma.project.findFirst({
            where: { id, companyId: sup.companyId, deleted_at: null },
        });
        if (!project) return res.status(404).json({ message: 'Project not found.' });
        // Soft delete — hard delete happens after 24h via cron
        await prisma.project.update({ where: { id }, data: { deleted_at: new Date() } });
        res.json({ message: 'Project moved to trash. You have 24 hours to restore it.' });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const restoreProject = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const id = parseInt(String(req.params.id), 10);
        const project = await prisma.project.findFirst({
            where: { id, companyId: sup.companyId, deleted_at: { not: null } },
        });
        if (!project) return res.status(404).json({ message: 'Project not found in trash.' });
        await prisma.project.update({ where: { id }, data: { deleted_at: null } });
        res.json({ message: 'Project restored.' });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};

export const addProjectMember = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const projectId = parseInt(String(req.params.id), 10);
        const studentId = parseInt(String(req.body?.studentId), 10);
        if (Number.isNaN(studentId)) return res.status(400).json({ message: 'studentId required.' });

        const project = await prisma.project.findFirst({
            where: { id: projectId, companyId: sup.companyId },
        });
        if (!project) return res.status(404).json({ message: 'Project not found.' });

        await assertActiveStudentAtCompany(sup.companyId, studentId);

        // Block if student is already assigned to any other active project at this company
        const alreadyInProject = await prisma.studentProject.findFirst({
            where: {
                studentId,
                project: { companyId: sup.companyId, deleted_at: null },
            },
        });
        if (alreadyInProject) {
            return res.status(400).json({ message: 'This student is already assigned to another project. Remove them first.' });
        }

        await prisma.studentProject.create({
            data: { projectId, studentId },
        });
        res.status(201).json({ message: 'Student linked to project.' });
    } catch (error: unknown) {
        const e = error as Error & { status?: number };
        if (e.status === 403) return res.status(403).json({ message: e.message });
        const message = error instanceof Error ? error.message : 'Server error';
        if (message.includes('Unique constraint')) {
            return res.status(400).json({ message: 'Student already on project.' });
        }
        res.status(500).json({ error: message });
    }
};

export const removeProjectMember = async (req: AuthRequest, res: Response) => {
    try {
        const sup = await getSupervisor(req);
        if (!sup) return res.status(403).json({ message: 'Supervisor profile not found.' });
        const projectId = parseInt(String(req.params.projectId), 10);
        const studentId = parseInt(String(req.params.studentId), 10);

        const project = await prisma.project.findFirst({
            where: { id: projectId, companyId: sup.companyId },
        });
        if (!project) return res.status(404).json({ message: 'Project not found.' });

        await prisma.studentProject.delete({
            where: { studentId_projectId: { studentId, projectId } },
        });
        res.json({ message: 'Student removed from project.' });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        res.status(500).json({ error: message });
    }
};
