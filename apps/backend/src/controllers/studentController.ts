import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import bcrypt from 'bcryptjs';
import { getCurrentInternshipWeekFromStart } from '../utils/internshipWeek';
import { sendSuccess, sendError } from '../utils/responseHelper';

// 1. COORDINATOR Task: Register a Student (SRS FR-4.2)
export const registerStudent = async (req: AuthRequest, res: Response) => {
    try {
        const { full_name, email, registration_type } = req.body;
        const coordinatorUserId = req.user?.userId;

        // Find the Coordinator's University ID
        const coordinator = await prisma.coordinator.findUnique({
            where: { userId: coordinatorUserId }
        });

        if (!coordinator) {
            return sendError(res, "Coordinator profile not found.", 403);
        }

        if (!coordinator.universityId) {
            return sendError(res, "Your coordinator account has not been approved yet. You cannot register students until an administrator approves your university credentials.", 403);
        }

        // Generate a temporary password (Requirement BR-006)
        const tempPassword = "Internlink123!";
        const hashedTempPassword = await bcrypt.hash(tempPassword, 10);

        // Create the Student User and Profile in a Transaction
        const student = await prisma.user.create({
            data: {
                full_name,
                email,
                password_hash: hashedTempPassword,
                role: 'STUDENT',
                verification_status: 'APPROVED', // Students are auto-approved by Coordinator
                institution_access_approval: 'APPROVED',
                studentProfile: {
                    create: {
                        universityId: coordinator.universityId as number,
                        registration_type: registration_type || "Official",
                        hod_approval_status: 'APPROVED',
                    }
                }
            },
            include: { studentProfile: true }
        });

        return sendSuccess(res, {
            tempPassword, // In production, send this via email
            student
        }, "Student registered successfully.", 201);
    } catch (error: any) {
        if (error.code === 'P2002') return sendError(res, "Email already exists", 400);
        return sendError(res, error.message, 500);
    }
};

// 2. STUDENT: enriched profile for dashboard / settings
export const getMyStudentProfile = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const profile = await prisma.student.findUnique({
            where: { userId },
            include: {
                user: { select: { full_name: true, email: true } },
                university: true,
                assignments: {
                    where: { status: 'ACTIVE' },
                    take: 1,
                    include: {
                        company: {
                            include: {
                                supervisors: {
                                    take: 1,
                                    include: { user: { select: { full_name: true, email: true } } },
                                },
                            },
                        },
                    },
                },
            },
        });
        if (!profile) {
            return sendError(res, 'Student profile not found.', 404);
        }

        const assignment = profile.assignments[0];
        const supervisor = assignment?.company?.supervisors?.[0];

        const currentInternshipWeek = assignment?.start_date
            ? getCurrentInternshipWeekFromStart(assignment.start_date)
            : 1;

        return sendSuccess(res, {
            ...profile,
            activeAssignment: assignment ?? null,
            supervisor: supervisor
                ? {
                      full_name: supervisor.user.full_name,
                      email: supervisor.user.email,
                  }
                : null,
            currentInternshipWeek,
        }, "Student profile fetched");
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// 3. STUDENT: Get their team info
export const getMyTeam = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const student = await prisma.student.findUnique({ where: { userId } });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        const membership = await prisma.studentTeam.findFirst({
            where: { studentId: student.id, team: { deleted_at: null } },
            include: {
                team: {
                    include: {
                        members: {
                            include: {
                                student: {
                                    include: {
                                        user: { select: { full_name: true, email: true } },
                                    },
                                },
                            },
                        },
                        project: { select: { id: true, name: true, description: true } },
                    },
                },
            },
        });

        if (!membership) return sendSuccess(res, null, 'Not in a team.');

        const team = membership.team;
        const manager = team.members.find((m) => m.studentId === team.managerId);

        return sendSuccess(res, {
            id: team.id,
            name: team.name,
            managerId: team.managerId,
            managerName: manager?.student.user.full_name ?? null,
            project: team.project ?? null,
            isManager: team.managerId === student.id,
            members: team.members.map((m) => ({
                studentId: m.studentId,
                fullName: m.student.user.full_name,
                email: m.student.user.email,
                isManager: m.studentId === team.managerId,
                isMe: m.studentId === student.id,
            })),
        });
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// 4. STUDENT: Submit an Open Letter request to their HoD
export const submitOpenLetter = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        if (!userId) return sendError(res, 'Unauthorized', 401);

        const student = await prisma.student.findUnique({
            where: { userId },
            include: { university: true },
        });
        if (!student) return sendError(res, 'Student profile not found.', 404);

        if (student.hod_approval_status !== 'APPROVED') {
            return sendError(res, 'Your account must be approved by your HoD before submitting an open letter.', 403);
        }

        if (student.internship_status === 'PLACED') {
            return sendError(res, 'You already have an active internship placement.', 400);
        }

        const { company_name, cover_letter } = req.body as { company_name?: string; cover_letter?: string };
        if (!company_name?.trim()) return sendError(res, 'company_name is required.', 400);

        // Find or create the company by name (open letters may target companies not yet in the system)
        let company = await prisma.company.findFirst({
            where: { name: { equals: company_name.trim(), mode: 'insensitive' } },
        });

        if (!company) {
            company = await prisma.company.create({
                data: {
                    name: company_name.trim(),
                    official_email: `pending@${company_name.trim().toLowerCase().replace(/\s+/g, '')}.com`,
                    approval_status: 'PENDING',
                },
            });
        }

        // Check for duplicate pending open letter for same company
        const existing = await prisma.internshipProposal.findFirst({
            where: {
                studentId: student.id,
                companyId: company.id,
                proposal_type: 'Open_Letter',
                status: 'PENDING',
            },
        });
        if (existing) {
            return sendError(res, 'You already have a pending open letter for this company.', 400);
        }

        const proposal = await prisma.internshipProposal.create({
            data: {
                studentId: student.id,
                companyId: company.id,
                universityId: student.universityId,
                proposal_type: 'Open_Letter',
                status: 'PENDING',
                expected_outcomes: cover_letter?.trim() ?? null,
            },
            include: {
                company: { select: { id: true, name: true } },
            },
        });

        // Notify the student's HoD
        const hod = await prisma.hodProfile.findFirst({
            where: {
                universityId: student.universityId,
                department: student.department ?? undefined,
            },
        });
        if (hod) {
            const { sendNotification } = await import('../utils/notificationHelper');
            await sendNotification(
                hod.userId,
                `📩 Open letter request from a student for ${company.name}. Please review in your Proposals tab.`
            );
        }

        return sendSuccess(res, proposal, 'Open letter submitted successfully.', 201);
    } catch (error: any) {
        return sendError(res, error.message);
    }
};

// --- WEEKLY PRESENTATION UPLOAD ---

/**
 * Upload or replace weekly presentation (PDF/PPT)
 * Allows re-submission by replacing old file
 */
export const uploadWeeklyPresentation = async (req: AuthRequest, res: Response) => {
    try {
        const { weeklyPlanId } = req.body;
        const file = req.file;
        const userId = req.user?.userId;

        if (!file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        if (!weeklyPlanId) {
            return res.status(400).json({ error: 'weeklyPlanId is required' });
        }

        // Verify student owns this weekly plan
        const student = await prisma.student.findUnique({
            where: { userId },
            include: {
                weeklyPlans: {
                    where: { id: parseInt(weeklyPlanId) },
                },
            },
        });

        if (!student || student.weeklyPlans.length === 0) {
            return res.status(403).json({ error: 'Weekly plan not found or access denied' });
        }

        const { CloudinaryService } = await import('../services/cloudinary.service');

        const folder = `internlink/${student.universityId}/${userId}/weekly-presentations`;

        // Check if presentation already exists
        const existingPresentation = await prisma.weeklyPresentation.findUnique({
            where: { weeklyPlanId: parseInt(weeklyPlanId) },
        });

        let uploadResult;

        if (existingPresentation) {
            // Replace existing — upload new file directly (no file record lookup needed)
            uploadResult = await CloudinaryService.uploadDocument(file, {
                userId,
                organizationId: student.universityId,
                fileType: 'WEEKLY_PRESENTATION',
                folder,
                resourceType: 'raw',
            });

            // Update presentation record
            await prisma.weeklyPresentation.update({
                where: { weeklyPlanId: parseInt(weeklyPlanId) },
                data: { file_url: uploadResult.url!, uploaded_at: new Date() },
            });
        } else {
            // Create new presentation
            uploadResult = await CloudinaryService.uploadDocument(file, {
                userId,
                organizationId: student.universityId,
                fileType: 'WEEKLY_PRESENTATION',
                folder,
                resourceType: 'raw',
            });

            await prisma.weeklyPresentation.create({
                data: {
                    weeklyPlanId: parseInt(weeklyPlanId),
                    file_url: uploadResult.url!,
                },
            });
        }

        if (!uploadResult.success) {
            return res.status(400).json({ error: uploadResult.error });
        }

        res.json({
            message: existingPresentation
                ? 'Weekly presentation replaced successfully'
                : 'Weekly presentation uploaded successfully',
            url: uploadResult.url,
            fileId: uploadResult.fileId,
        });
    } catch (error: any) {
        console.error('Upload weekly presentation error:', error);
        res.status(500).json({ error: error.message });
    }
};
