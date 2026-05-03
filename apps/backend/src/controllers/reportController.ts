import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import PDFDocument from 'pdfkit';
import fs from 'fs';
import { sendNotification } from '../utils/notificationHelper';
import { sendSuccess, sendError } from '../utils/responseHelper';

// 1. SUPERVISOR: Submit Final Evaluation (FR-16)
export const submitEvaluation = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId, technical_score, soft_skill_score, comments } = req.body;

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) return sendError(res, 'Only supervisors can submit evaluations.', 403);

        const sid = parseInt(String(studentId), 10);
        const assignment = await prisma.internshipAssignment.findFirst({
            where: { studentId: sid, companyId: supervisor.companyId, status: 'ACTIVE' },
        });
        if (!assignment) return sendError(res, 'This student is not actively placed at your company.', 403);

        const pendingPlans = await prisma.weeklyPlan.count({
            where: { studentId: sid, status: 'PENDING' },
        });
        if (pendingPlans > 0) {
            return sendError(res, 'Cannot submit final evaluation. There are still pending weekly plans that need approval.', 400);
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

        return sendSuccess(res, evaluation, 'Evaluation submitted.', 201);
    } catch (error: any) {
        return sendError(res, error.message);
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
        if (!student) return sendError(res, 'Student not found.', 404);
        if (!student.finalEvaluation) {
            return sendSuccess(res, { evaluation: null }, 'No evaluation yet.');
        }
        const ev = student.finalEvaluation;
        return sendSuccess(res, {
            evaluation: {
                technicalScore: Number(ev.technical_score),
                softSkillScore: Number(ev.soft_skill_score),
                comments: ev.comments ?? '',
                evaluatedAt: ev.evaluated_at,
                supervisorName: ev.supervisor.user.full_name,
                companyName: ev.supervisor.company.name,
            },
        }, 'Evaluation fetched.');
    } catch (error: any) {
        return sendError(res, error.message);
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

        // Create PDF using PDFKit
        const doc = new PDFDocument();
        const chunks: Buffer[] = [];

        doc.on('data', (chunk) => chunks.push(chunk));
        doc.on('end', async () => {
            try {
                const pdfBuffer = Buffer.concat(chunks);

                // Import services
                const { CloudinaryService } = await import('../services/cloudinary.service');
                const { PDFStampingService } = await import('../services/pdfStamping.service');

                // Upload unstamped PDF first
                const unstampedFile = {
                    buffer: pdfBuffer,
                    originalname: `report-${studentId}-unstamped.pdf`,
                    mimetype: 'application/pdf',
                    size: pdfBuffer.length,
                } as Express.Multer.File;

                const folder = `internlink/${data.universityId}/${data.userId}/final-reports`;

                const uploadResult = await CloudinaryService.uploadDocument(unstampedFile, {
                    userId: data.userId,
                    organizationId: data.universityId,
                    fileType: 'FINAL_REPORT',
                    folder,
                    resourceType: 'raw',
                });

                if (!uploadResult.success) {
                    return res.status(500).json({ error: 'Failed to upload PDF' });
                }

                let finalPdfUrl = uploadResult.url!;

                // Apply stamp if company has one
                if (company?.stamp_image_url) {
                    const stampResult = await PDFStampingService.stampAndUploadPDF(
                        uploadResult.url!,
                        company.stamp_image_url,
                        {
                            userId: data.userId,
                            organizationId: data.universityId,
                            folder,
                        }
                    );

                    if (stampResult.success) {
                        finalPdfUrl = stampResult.url!;
                        // Delete unstamped version
                        await CloudinaryService.deleteFile(uploadResult.publicId!);
                    }
                }

                // Save report record in DB
                await prisma.report.upsert({
                    where: { studentId: parseInt(studentId) },
                    update: { 
                        pdf_url: finalPdfUrl,
                        stamped: !!company?.stamp_image_url,
                    },
                    create: { 
                        studentId: parseInt(studentId), 
                        pdf_url: finalPdfUrl,
                        stamped: !!company?.stamp_image_url,
                    }
                });

                res.json({ 
                    message: "PDF Generated Successfully", 
                    reportUrl: finalPdfUrl,
                    stamped: !!company?.stamp_image_url,
                });
            } catch (error: any) {
                console.error('PDF processing error:', error);
                res.status(500).json({ error: error.message });
            }
        });

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

        doc.moveDown(2);
        doc.text('Company Authorization:', { underline: true });
        doc.text('This report has been verified and approved by the company.');

        doc.end();
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

/** UC10–UC11: Lock report and notify coordinators after company sends to university */
export const sendReportToUniversity = async (req: AuthRequest, res: Response) => {
    try {
        const studentId = parseInt(String(req.body?.studentId), 10);
        if (Number.isNaN(studentId)) return sendError(res, 'studentId is required.', 400);

        if (req.user?.role === 'SUPERVISOR') {
            const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
            if (!supervisor) return sendError(res, 'Supervisor profile not found.', 403);
            const assignment = await prisma.internshipAssignment.findFirst({
                where: { studentId, companyId: supervisor.companyId, status: 'ACTIVE' },
            });
            if (!assignment) return sendError(res, 'Student is not placed at your company.', 403);
        } else if (req.user?.role !== 'ADMIN') {
            return sendError(res, 'Forbidden.', 403);
        }

        const report = await prisma.report.findUnique({ where: { studentId } });
        if (!report) return sendError(res, 'Generate the PDF before sending to the university.', 400);
        if (report.locked) return sendError(res, 'Report has already been sent to the university.', 400);

        const student = await prisma.student.findUnique({ where: { id: studentId }, include: { user: true } });
        if (!student) return sendError(res, 'Student not found.', 404);

        await prisma.report.update({
            where: { studentId },
            data: { locked: true, sent_at: new Date(), sentToUniversityId: student.universityId },
        });

        const coordinators = await prisma.coordinator.findMany({
            where: { universityId: student.universityId },
            select: { userId: true },
        });
        const msg = `Final internship report for ${student.user.full_name} has been submitted by the company and is available.`;
        for (const c of coordinators) await sendNotification(c.userId, msg);

        return sendSuccess(res, { studentId, locked: true }, 'Report sent to the university. Coordinators have been notified.');
    } catch (error: any) {
        return sendError(res, error.message);
    }
};

/**
 * Upload signed final report (PDF)
 */
export const uploadSignedReport = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId } = req.body;
        const file = req.file;

        if (!file) return sendError(res, 'No file uploaded', 400);
        if (!studentId) return sendError(res, 'studentId is required', 400);

        const sid = parseInt(studentId);
        const student = await prisma.student.findUnique({ where: { id: sid }, include: { assignments: true } });
        if (!student) return sendError(res, 'Student not found', 404);

        if (req.user?.role === 'STUDENT' && student.userId !== req.user.userId) {
            return sendError(res, 'Access denied', 403);
        }
        if (req.user?.role === 'SUPERVISOR') {
            const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user.userId } });
            const placedHere = student.assignments.some((a) => a.companyId === supervisor?.companyId && a.status === 'ACTIVE');
            if (!supervisor || !placedHere) return sendError(res, 'Access denied', 403);
        }

        const existingReport = await prisma.report.findUnique({ where: { studentId: sid } });
        if (existingReport?.locked) return sendError(res, 'This report has been sent to the university and is locked.', 400);

        const { CloudinaryService } = await import('../services/cloudinary.service');
        const folder = `internlink/${student.universityId}/${student.userId}/final-reports`;

        const uploadResult = await CloudinaryService.uploadDocument(file, {
            userId: student.userId,
            organizationId: student.universityId,
            fileType: 'FINAL_REPORT',
            folder,
            resourceType: 'raw',
        });

        if (!uploadResult.success) return sendError(res, uploadResult.error ?? 'Upload failed', 400);

        if (existingReport) {
            await prisma.report.update({ where: { studentId: sid }, data: { pdf_url: uploadResult.url!, stamped: true, generated_at: new Date() } });
        } else {
            await prisma.report.create({ data: { studentId: sid, pdf_url: uploadResult.url!, stamped: true } });
        }

        return sendSuccess(res, { url: uploadResult.url }, existingReport ? 'Final report replaced successfully' : 'Final report uploaded successfully');
    } catch (error: any) {
        console.error('Upload signed report error:', error);
        return sendError(res, error.message);
    }
};
