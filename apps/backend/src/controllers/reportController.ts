import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import PDFDocument from 'pdfkit';
import fs from 'fs';
import { sendNotification } from '../utils/notificationHelper';

// 1. SUPERVISOR: Submit Final Evaluation (FR-16)
// src/controllers/reportController.ts -> update the submitEvaluation function

export const submitEvaluation = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId, technical_score, soft_skill_score, comments } = req.body;

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return res.status(403).json({ message: 'Only supervisors can submit evaluations.' });
        }

        const sid = parseInt(String(studentId), 10);
        const assignment = await prisma.internshipAssignment.findFirst({
            where: { studentId: sid, companyId: supervisor.companyId, status: 'ACTIVE' },
        });
        if (!assignment) {
            return res.status(403).json({
                message: 'This student is not actively placed at your company.',
            });
        }

        // 1. CHECK REQUIREMENT BR-007: Are there any pending weekly plans?
        const pendingPlans = await prisma.weeklyPlan.count({
            where: {
                studentId: sid,
                status: 'PENDING',
            },
        });

        if (pendingPlans > 0) {
            return res.status(400).json({
                message:
                    'Cannot submit final evaluation. There are still pending weekly plans that need approval.',
            });
        }

        const evaluation = await prisma.finalEvaluation.create({
            data: {
                studentId: sid,
                supervisorId: supervisor.id,
                technical_score: parseFloat(technical_score),
                soft_skill_score: parseFloat(soft_skill_score),
                comments,
            },
        });

        res.status(201).json(evaluation);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** STUDENT: read own final evaluation if any */
export const getMyEvaluation = async (req: AuthRequest, res: Response) => {
    try {
        const student = await prisma.student.findUnique({
            where: { userId: req.user!.userId },
            include: {
                finalEvaluation: {
                    include: {
                        supervisor: { include: { user: true, company: true } },
                    },
                },
            },
        });
        if (!student) return res.status(404).json({ message: 'Student not found.' });
        if (!student.finalEvaluation) {
            return res.json({ evaluation: null });
        }
        const ev = student.finalEvaluation;
        res.json({
            evaluation: {
                technicalScore: Number(ev.technical_score),
                softSkillScore: Number(ev.soft_skill_score),
                comments: ev.comments ?? '',
                evaluatedAt: ev.evaluated_at,
                supervisorName: ev.supervisor.user.full_name,
                companyName: ev.supervisor.company.name,
            },
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 2. SYSTEM: Generate Stamped PDF (FR-18 & FR-19)
export const generateStudentReport = async (req: AuthRequest, res: Response) => {
    try {
        let { studentId } = req.params;
        if (Array.isArray(studentId)) {
            studentId = studentId[0];
        }

        // Fetch all data for the report
        const data = await prisma.student.findUnique({
            where: { id: parseInt(studentId) },
            include: {
                user: true,
                university: true,
                finalEvaluation: true,
                weeklyPlans: { where: { status: 'APPROVED' } },
                assignments: { include: { company: true } }
            }
        });

        if (!data || !data.finalEvaluation) {
            return res.status(400).json({ message: "Final evaluation not found. Submit scores first." });
        }

        const existingReport = await prisma.report.findUnique({
            where: { studentId: parseInt(String(studentId), 10) },
        });
        if (existingReport?.locked) {
            return res.status(400).json({
                message: 'This report has been sent to the university and is locked.',
            });
        }

        if (req.user?.role === 'SUPERVISOR') {
            const supervisor = await prisma.supervisor.findUnique({
                where: { userId: req.user.userId },
            });
            const placedHere = data.assignments.some(
                (a) => a.companyId === supervisor?.companyId && a.status === 'ACTIVE',
            );
            if (!supervisor || !placedHere) {
                return res.status(403).json({
                    message: 'You can only generate reports for students placed at your company.',
                });
            }
        }

        const company = data.assignments.find((a) => a.status === 'ACTIVE')?.company ?? data.assignments[0]?.company;
        const reportPath = `uploads/reports/report-${studentId}.pdf`;

        // Ensure directory exists
        if (!fs.existsSync('uploads/reports')) fs.mkdirSync('uploads/reports', { recursive: true });

        // Create PDF
        const doc = new PDFDocument();
        const stream = fs.createWriteStream(reportPath);
        doc.pipe(stream);

        // --- PDF CONTENT ---
        doc.fontSize(20).text('InternLink: Internship Performance Report', { align: 'center' });
        doc.moveDown();
        doc.fontSize(12).text(`Student Name: ${data.user.full_name}`);
        doc.text(`University: ${data.university.name}`);
        doc.text(`Company: ${company?.name}`);
        doc.moveDown();

        doc.text('--- FINAL EVALUATION ---', { underline: true });
        doc.text(`Technical Score: ${data.finalEvaluation.technical_score}/100`);
        doc.text(`Soft Skill Score: ${data.finalEvaluation.soft_skill_score}/100`);
        doc.text(`Supervisor Comments: ${data.finalEvaluation.comments}`);
        doc.moveDown();

        doc.text('--- WEEKLY PROGRESS SUMMARY ---', { underline: true });
        data.weeklyPlans.forEach(plan => {
            doc.text(`Week ${plan.week_number}: ${plan.plan_description}`);
        });

        // --- THE STAMP (Requirement FR-19) ---
        if (company?.stamp_image_url) {
            doc.moveDown();
            doc.text('Company Authorization:');
            // Assuming image path is valid
            doc.image(company.stamp_image_url, { width: 100 });
        }

        doc.end();

        // Save report record in DB
        const report = await prisma.report.upsert({
            where: { studentId: parseInt(studentId) },
            update: { pdf_url: reportPath },
            create: { studentId: parseInt(studentId), pdf_url: reportPath }
        });

        res.json({ message: "PDF Generated Successfully", reportUrl: reportPath });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** UC10–UC11: Lock report and notify coordinators after company sends to university */
export const sendReportToUniversity = async (req: AuthRequest, res: Response) => {
    try {
        const studentId = parseInt(String(req.body?.studentId), 10);
        if (Number.isNaN(studentId)) {
            return res.status(400).json({ message: 'studentId is required.' });
        }

        if (req.user?.role === 'SUPERVISOR') {
            const supervisor = await prisma.supervisor.findUnique({
                where: { userId: req.user!.userId },
            });
            if (!supervisor) {
                return res.status(403).json({ message: 'Supervisor profile not found.' });
            }

            const assignment = await prisma.internshipAssignment.findFirst({
                where: { studentId, companyId: supervisor.companyId, status: 'ACTIVE' },
            });
            if (!assignment) {
                return res.status(403).json({ message: 'Student is not placed at your company.' });
            }
        } else if (req.user?.role !== 'ADMIN') {
            return res.status(403).json({ message: 'Forbidden.' });
        }

        const report = await prisma.report.findUnique({ where: { studentId } });
        if (!report) {
            return res.status(400).json({ message: 'Generate the PDF before sending to the university.' });
        }
        if (report.locked) {
            return res.status(400).json({ message: 'Report has already been sent to the university.' });
        }

        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });
        if (!student) {
            return res.status(404).json({ message: 'Student not found.' });
        }

        await prisma.report.update({
            where: { studentId },
            data: {
                locked: true,
                sent_at: new Date(),
                sentToUniversityId: student.universityId,
            },
        });

        const coordinators = await prisma.coordinator.findMany({
            where: { universityId: student.universityId },
            select: { userId: true },
        });

        const msg = `Final internship report for ${student.user.full_name} has been submitted by the company and is available.`;
        for (const c of coordinators) {
            await sendNotification(c.userId, msg);
        }

        res.json({ message: 'Report sent to the university. Coordinators have been notified.' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};