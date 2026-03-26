import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';

// 1. STUDENT: Submit Weekly Plan & Presentation (FR-5.3 & FR-5.5)
export const submitWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const { week_number, plan_description } = req.body;
        const userId = req.user?.userId;

        // 1. Verify Student is PLACED
        const student = await prisma.student.findUnique({
            where: { userId },
            include: { assignments: { where: { status: 'ACTIVE' } } }
        });

        if (!student || student.internship_status !== 'PLACED') {
            return res.status(403).json({ message: "You must be placed in a company to submit plans." });
        }

        // 2. Create the Weekly Plan and Link Presentation File if uploaded
        const plan = await prisma.weeklyPlan.create({
            data: {
                studentId: student.id,
                week_number: parseInt(week_number),
                plan_description,
                status: 'PENDING',
                presentation: req.file ? {
                    create: {
                        file_url: req.file.path
                    }
                } : undefined
            },
            include: { presentation: true }
        });

        res.status(201).json({ message: "Weekly plan submitted successfully.", plan });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 2. SUPERVISOR: Review and Approve/Reject Plan (FR-6.3 & BR-004)
export const reviewWeeklyPlan = async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params; // Plan ID
        const { status, remarks, attendance } = req.body; // status: 'APPROVED' or 'REJECTED'

        // Ensure id is a string
        const planId = Array.isArray(id) ? id[0] : id;

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user?.userId }
        });

        if (!supervisor) return res.status(403).json({ message: "Only supervisors can review plans." });

        // Update the plan status
        const updatedPlan = await prisma.weeklyPlan.update({
            where: { id: parseInt(planId) },
            data: { status }
        });

        // If approved, also log the Weekly Report/Attendance (FR-6.5)
        if (status === 'APPROVED') {
            await prisma.weeklyReport.create({
                data: {
                    studentId: updatedPlan.studentId,
                    supervisorId: supervisor.id,
                    attendance: attendance === 'true' || attendance === true,
                    remarks: remarks || "Plan approved."
                }
            });
        }

        res.json({ message: `Plan ${status}`, updatedPlan });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};