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

/**
 * Upload signed final report (PDF)
 * Used when student/supervisor uploads a manually signed report
 */
export const uploadSignedReport = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId } = req.body;
        const file = req.file;

        if (!file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        if (!studentId) {
            return res.status(400).json({ error: 'studentId is required' });
        }

        const sid = parseInt(studentId);

        // Verify access
        const student = await prisma.student.findUnique({
            where: { id: sid },
            include: { assignments: true },
        });

        if (!student) {
            return res.status(404).json({ error: 'Student not found' });
        }

        // Check if user has permission
        if (req.user?.role === 'STUDENT' && student.userId !== req.user.userId) {
            return res.status(403).json({ error: 'Access denied' });
        }

        if (req.user?.role === 'SUPERVISOR') {
            const supervisor = await prisma.supervisor.findUnique({
                where: { userId: req.user.userId },
            });
            const placedHere = student.assignments.some(
                (a) => a.companyId === supervisor?.companyId && a.status === 'ACTIVE'
            );
            if (!supervisor || !placedHere) {
                return res.status(403).json({ error: 'Access denied' });
            }
        }

        // Check if report is locked
        const existingReport = await prisma.report.findUnique({
            where: { studentId: sid },
        });

        if (existingReport?.locked) {
            return res.status(400).json({
                error: 'This report has been sent to the university and is locked.',
            });
        }

        const { CloudinaryService } = await import('../services/cloudinary.service');

        const folder = `internlink/${student.universityId}/${student.userId}/final-reports`;

        // Replace existing report if any
        let uploadResult;

        if (existingReport) {
            const existingFile = await prisma.file.findFirst({
                where: { url: existingReport.pdf_url },
            });

            if (existingFile) {
                uploadResult = await CloudinaryService.replaceFile(
                    existingFile.publicId,
                    file,
                    {
                        userId: student.userId,
                        organizationId: student.universityId,
                        fileType: 'FINAL_REPORT',
                        folder,
                        resourceType: 'raw',
                    }
                );
            } else {
                uploadResult = await CloudinaryService.uploadDocument(file, {
                    userId: student.userId,
                    organizationId: student.universityId,
                    fileType: 'FINAL_REPORT',
                    folder,
                    resourceType: 'raw',
                });
            }

            await prisma.report.update({
                where: { studentId: sid },
                data: { 
                    pdf_url: uploadResult.url!,
                    stamped: true, // Assume manually uploaded reports are signed
                    generated_at: new Date(),
                },
            });
        } else {
            uploadResult = await CloudinaryService.uploadDocument(file, {
                userId: student.userId,
                organizationId: student.universityId,
                fileType: 'FINAL_REPORT',
                folder,
                resourceType: 'raw',
            });

            await prisma.report.create({
                data: {
                    studentId: sid,
                    pdf_url: uploadResult.url!,
                    stamped: true,
                },
            });
        }

        if (!uploadResult.success) {
            return res.status(400).json({ error: uploadResult.error });
        }

        res.json({
            message: existingReport
                ? 'Final report replaced successfully'
                : 'Final report uploaded successfully',
            url: uploadResult.url,
            fileId: uploadResult.fileId,
        });
    } catch (error: any) {
        console.error('Upload signed report error:', error);
        res.status(500).json({ error: error.message });
    }
};
