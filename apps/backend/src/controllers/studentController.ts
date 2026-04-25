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
