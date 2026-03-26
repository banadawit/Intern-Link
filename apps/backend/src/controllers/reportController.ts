import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import PDFDocument from 'pdfkit';
import fs from 'fs';
import path from 'path';

// 1. SUPERVISOR: Submit Final Evaluation (FR-16)
// src/controllers/reportController.ts -> update the submitEvaluation function

export const submitEvaluation = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId, technical_score, soft_skill_score, comments } = req.body;

        // 1. CHECK REQUIREMENT BR-007: Are there any pending weekly plans?
        const pendingPlans = await prisma.weeklyPlan.count({
            where: {
                studentId: parseInt(studentId),
                status: 'PENDING'
            }
        });

        if (pendingPlans > 0) {
            return res.status(400).json({
                message: "Cannot submit final evaluation. There are still pending weekly plans that need approval."
            });
        }

        // 2. Proceed with saving evaluation...
        const evaluation = await prisma.finalEvaluation.create({
            data: {
                studentId: parseInt(studentId),
                supervisorId: (await prisma.supervisor.findUnique({ where: { userId: req.user!.userId } }))!.id,
                technical_score: parseFloat(technical_score),
                soft_skill_score: parseFloat(soft_skill_score),
                comments
            }
        });

        res.status(201).json(evaluation);
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

        const company = data.assignments[0]?.company;
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