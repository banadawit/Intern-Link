import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import bcrypt from 'bcryptjs';
import { getCurrentInternshipWeekFromStart } from '../utils/internshipWeek';

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
            return res.status(403).json({ message: "Coordinator profile not found." });
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
                        universityId: coordinator.universityId,
                        registration_type: registration_type || "Official"
                    }
                }
            },
            include: { studentProfile: true }
        });

        res.status(201).json({
            message: "Student registered successfully.",
            tempPassword, // In production, send this via email
            student
        });
    } catch (error: any) {
        if (error.code === 'P2002') return res.status(400).json({ message: "Email already exists" });
        res.status(500).json({ error: error.message });
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
            return res.status(404).json({ message: 'Student profile not found.' });
        }

        const assignment = profile.assignments[0];
        const supervisor = assignment?.company?.supervisors?.[0];

        const currentInternshipWeek = assignment?.start_date
            ? getCurrentInternshipWeekFromStart(assignment.start_date)
            : 1;

        res.json({
            ...profile,
            activeAssignment: assignment ?? null,
            supervisor: supervisor
                ? {
                      full_name: supervisor.user.full_name,
                      email: supervisor.user.email,
                  }
                : null,
            currentInternshipWeek,
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
