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

        const evaluation = await prisma.finalEvaluation.upsert({
            where: { studentId: sid },
            create: {
                studentId: sid,
                supervisorId: supervisor.id,
                technical_score: parseFloat(technical_score),
                soft_skill_score: parseFloat(soft_skill_score),
                comments,
            },
            update: {
                supervisorId: supervisor.id,
                technical_score: parseFloat(technical_score),
                soft_skill_score: parseFloat(soft_skill_score),
                comments,
            },
        });

        // Notify the student
        const student = await prisma.student.findUnique({
            where: { id: sid },
            include: { user: true, hod: { include: { user: true } } },
        });
        if (student) {
            await sendNotification(
                student.userId,
                `📊 Your final evaluation has been submitted — Technical: ${parseFloat(technical_score)}/100, Soft Skills: ${parseFloat(soft_skill_score)}/100.`
            );
            // Notify HOD if linked
            if (student.hod) {
                await sendNotification(
                    student.hod.userId,
                    `📊 Final evaluation submitted for ${student.user.full_name} — Technical: ${parseFloat(technical_score)}/100, Soft Skills: ${parseFloat(soft_skill_score)}/100.`
                );
            }
        }

        return sendSuccess(res, evaluation, 'Evaluation submitted.');
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
        if (Array.isArray(studentId)) studentId = studentId[0];

        const data = await prisma.student.findUnique({
            where: { id: parseInt(studentId) },
            include: {
                user: true,
                university: true,
                finalEvaluation: { include: { supervisor: { include: { user: true } } } },
                weeklyPlans: { where: { status: 'APPROVED' }, orderBy: { week_number: 'asc' } },
                assignments: { include: { company: true } },
            },
        });

        if (!data || !data.finalEvaluation) {
            return res.status(400).json({ message: 'Final evaluation not found. Submit scores first.' });
        }

        const existingReport = await prisma.report.findUnique({ where: { studentId: parseInt(studentId, 10) } });
        if (existingReport?.locked) {
            return res.status(400).json({ message: 'This report has been sent to the university and is locked.' });
        }

        const company = data.assignments.find((a) => a.status === 'ACTIVE')?.company ?? data.assignments[0]?.company;
        const stampUrl = company?.stamp_image_url ?? null;

        if (req.user?.role === 'SUPERVISOR') {
            const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user.userId } });
            const placedHere = data.assignments.some((a) => a.companyId === supervisor?.companyId && a.status === 'ACTIVE');
            if (!supervisor || !placedHere) {
                return res.status(403).json({ message: 'You can only generate reports for students placed at your company.' });
            }
        }

        // ── Build professional PDF with PDFKit ────────────────────────────────
        const doc = new PDFDocument({ margin: 50, size: 'A4' });
        const chunks: Buffer[] = [];
        doc.on('data', (chunk) => chunks.push(chunk));

        doc.on('end', async () => {
            try {
                let pdfBuffer = Buffer.concat(chunks);

                // ── Apply stamp with pdf-lib if available ─────────────────────
                let stamped = false;
                if (stampUrl) {
                    try {
                        const { PDFDocument, degrees } = await import('pdf-lib');

                        // Download stamp image
                        const stampRes = await fetch(stampUrl);
                        if (stampRes.ok) {
                            const stampBytes = Buffer.from(await stampRes.arrayBuffer());
                            const pdfDoc = await PDFDocument.load(pdfBuffer);
                            const pages = pdfDoc.getPages();
                            const lastPage = pages[pages.length - 1];
                            const { width, height } = lastPage.getSize();

                            // Embed image (support PNG and JPG)
                            const isJpg = stampUrl.toLowerCase().includes('.jpg') || stampUrl.toLowerCase().includes('.jpeg');
                            const stampImage = isJpg
                                ? await pdfDoc.embedJpg(stampBytes)
                                : await pdfDoc.embedPng(stampBytes);

                            // Draw stamp: 110×110 pt, bottom-right with margin, slight transparency
                            const stampSize = 110;
                            const margin = 45;
                            lastPage.drawImage(stampImage, {
                                x: width - stampSize - margin,
                                y: margin,
                                width: stampSize,
                                height: stampSize,
                                opacity: 0.88,
                            });

                            // Add "Authorized" label below stamp
                            lastPage.drawText('Authorized', {
                                x: width - stampSize - margin + 22,
                                y: margin - 14,
                                size: 8,
                                opacity: 0.6,
                            });

                            pdfBuffer = Buffer.from(await pdfDoc.save());
                            stamped = true;
                        }
                    } catch (stampErr: any) {
                        console.warn('Stamp apply failed, continuing without stamp:', stampErr.message);
                    }
                }

                // ── Save locally ──────────────────────────────────────────────
                const uploadsDir = `${process.cwd()}/uploads/reports`;
                if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

                const filename = `report-${studentId}-${Date.now()}.pdf`;
                const filePath = `${uploadsDir}/${filename}`;
                fs.writeFileSync(filePath, pdfBuffer);

                const baseUrl = process.env.BACKEND_URL || `http://localhost:${process.env.PORT || 5000}`;
                const finalPdfUrl = `${baseUrl}/uploads/reports/${filename}`;

                // Delete old local file
                const existing = await prisma.report.findUnique({ where: { studentId: parseInt(studentId) } });
                if (existing?.pdf_url?.includes('/uploads/reports/')) {
                    const oldFile = `${process.cwd()}/uploads/reports/${existing.pdf_url.split('/uploads/reports/')[1]}`;
                    if (fs.existsSync(oldFile)) fs.unlinkSync(oldFile);
                }

                await prisma.report.upsert({
                    where: { studentId: parseInt(studentId) },
                    update: { pdf_url: finalPdfUrl, stamped },
                    create: { studentId: parseInt(studentId), pdf_url: finalPdfUrl, stamped },
                });

                if (data.userId) {
                    await sendNotification(data.userId, `📄 Your final internship report has been generated and is ready to view.`);
                }

                res.json({ message: 'PDF Generated Successfully', reportUrl: finalPdfUrl, stamped });
            } catch (error: any) {
                console.error('PDF processing error:', error);
                res.status(500).json({ error: error.message });
            }
        });

        // ── Professional PDF layout ───────────────────────────────────────────
        const ev = data.finalEvaluation;
        const supervisorName = ev.supervisor?.user?.full_name ?? 'Supervisor';
        const generatedDate = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

        // Header bar
        doc.rect(0, 0, doc.page.width, 80).fill('#1e3a5f');
        doc.fillColor('#ffffff').fontSize(20).font('Helvetica-Bold')
            .text('INTERNSHIP PERFORMANCE REPORT', 50, 25, { align: 'center' });
        doc.fontSize(9).font('Helvetica').fillColor('#a8c4e0')
            .text('InternLink — Official Internship Management System', 50, 52, { align: 'center' });

        // Reset color
        doc.fillColor('#1a1a2e');

        // Student info section
        doc.moveDown(3);
        const infoY = 110;
        doc.roundedRect(50, infoY, doc.page.width - 100, 110, 8).fillAndStroke('#f0f4f8', '#d0dce8');

        doc.fontSize(11).font('Helvetica-Bold').fillColor('#1e3a5f')
            .text('STUDENT INFORMATION', 70, infoY + 14);
        doc.moveTo(70, infoY + 30).lineTo(doc.page.width - 70, infoY + 30).strokeColor('#d0dce8').stroke();

        doc.fontSize(10).font('Helvetica').fillColor('#333');
        const col1x = 70, col2x = 320;
        doc.font('Helvetica-Bold').text('Full Name:', col1x, infoY + 40).font('Helvetica').text(data.user.full_name, col1x + 75, infoY + 40);
        doc.font('Helvetica-Bold').text('University:', col1x, infoY + 58).font('Helvetica').text(data.university.name, col1x + 75, infoY + 58);
        doc.font('Helvetica-Bold').text('Company:', col2x, infoY + 40).font('Helvetica').text(company?.name ?? '—', col2x + 70, infoY + 40);
        doc.font('Helvetica-Bold').text('Report Date:', col2x, infoY + 58).font('Helvetica').text(generatedDate, col2x + 80, infoY + 58);
        doc.font('Helvetica-Bold').text('Supervisor:', col1x, infoY + 76).font('Helvetica').text(supervisorName, col1x + 75, infoY + 76);

        // Final Evaluation section
        const evalY = infoY + 135;
        doc.fontSize(13).font('Helvetica-Bold').fillColor('#1e3a5f').text('FINAL EVALUATION', 50, evalY);
        doc.moveTo(50, evalY + 18).lineTo(doc.page.width - 50, evalY + 18).strokeColor('#1e3a5f').lineWidth(1.5).stroke();
        doc.lineWidth(1);

        // Score boxes
        const boxY = evalY + 28;
        const boxW = (doc.page.width - 120) / 2;

        // Technical score box
        doc.roundedRect(50, boxY, boxW, 70, 6).fillAndStroke('#e8f4fd', '#b3d4f0');
        doc.fontSize(10).font('Helvetica-Bold').fillColor('#1e3a5f').text('Technical Skills', 60, boxY + 10);
        doc.fontSize(28).font('Helvetica-Bold').fillColor('#1e3a5f')
            .text(`${Number(ev.technical_score)}`, 60, boxY + 26);
        doc.fontSize(10).font('Helvetica').fillColor('#666').text('out of 100', 60, boxY + 54);

        // Soft skills score box
        const box2x = 50 + boxW + 20;
        doc.roundedRect(box2x, boxY, boxW, 70, 6).fillAndStroke('#edf7ee', '#b3ddb5');
        doc.fontSize(10).font('Helvetica-Bold').fillColor('#2d6a2d').text('Soft Skills', box2x + 10, boxY + 10);
        doc.fontSize(28).font('Helvetica-Bold').fillColor('#2d6a2d')
            .text(`${Number(ev.soft_skill_score)}`, box2x + 10, boxY + 26);
        doc.fontSize(10).font('Helvetica').fillColor('#666').text('out of 100', box2x + 10, boxY + 54);

        // Comments
        if (ev.comments) {
            const commY = boxY + 85;
            doc.fontSize(10).font('Helvetica-Bold').fillColor('#1e3a5f').text('Supervisor Comments:', 50, commY);
            doc.roundedRect(50, commY + 16, doc.page.width - 100, 50, 5).fillAndStroke('#fafafa', '#e0e0e0');
            doc.fontSize(10).font('Helvetica-Oblique').fillColor('#444')
                .text(`"${ev.comments}"`, 60, commY + 24, { width: doc.page.width - 120 });
        }

        // Weekly progress section
        const weekY = boxY + 160;
        doc.fontSize(13).font('Helvetica-Bold').fillColor('#1e3a5f').text('WEEKLY PROGRESS SUMMARY', 50, weekY);
        doc.moveTo(50, weekY + 18).lineTo(doc.page.width - 50, weekY + 18).strokeColor('#1e3a5f').lineWidth(1.5).stroke();
        doc.lineWidth(1);

        let rowY = weekY + 28;
        if (data.weeklyPlans.length === 0) {
            doc.fontSize(10).font('Helvetica-Oblique').fillColor('#888').text('No approved weekly plans on record.', 60, rowY);
        } else {
            data.weeklyPlans.forEach((plan, i) => {
                const bg = i % 2 === 0 ? '#f7f9fc' : '#ffffff';
                doc.rect(50, rowY, doc.page.width - 100, 22).fill(bg);
                doc.fontSize(9).font('Helvetica-Bold').fillColor('#1e3a5f')
                    .text(`Week ${plan.week_number}`, 60, rowY + 6);
                doc.font('Helvetica').fillColor('#333')
                    .text(plan.plan_description.slice(0, 90) + (plan.plan_description.length > 90 ? '…' : ''), 120, rowY + 6, { width: doc.page.width - 180 });
                rowY += 22;
            });
        }

        // Authorization section at bottom
        const authY = rowY + 30;
        doc.roundedRect(50, authY, doc.page.width - 100, 65, 6).fillAndStroke('#f9f9f9', '#d0d0d0');
        doc.fontSize(10).font('Helvetica-Bold').fillColor('#1e3a5f').text('COMPANY AUTHORIZATION', 70, authY + 12);
        doc.fontSize(9).font('Helvetica').fillColor('#555')
            .text('This report has been reviewed and authorized by the supervising company.', 70, authY + 28);
        doc.text(`Authorized by: ${supervisorName}  |  ${company?.name ?? ''}  |  Date: ${generatedDate}`, 70, authY + 44);

        // Footer
        const footerY = doc.page.height - 40;
        doc.rect(0, footerY - 5, doc.page.width, 45).fill('#1e3a5f');
        doc.fontSize(8).font('Helvetica').fillColor('#a8c4e0')
            .text('Generated by InternLink — Confidential Internship Document', 50, footerY + 5, { align: 'center' });

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

        // Notify the student
        await sendNotification(
            student.userId,
            `✅ Your final internship report has been sent to your university.`
        );

        // Notify the student's HOD if linked
        const studentWithHod = await prisma.student.findUnique({
            where: { id: studentId },
            include: { hod: { include: { user: true } } },
        });
        if (studentWithHod?.hod) {
            await sendNotification(
                studentWithHod.hod.userId,
                `📬 Final report for ${student.user.full_name} has been sent to the university by the company.`
            );
        }

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
