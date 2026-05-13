import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import PDFDocument from 'pdfkit';
import fs from 'fs';
import { sendNotification } from '../utils/notificationHelper';
import { sendSuccess, sendError } from '../utils/responseHelper';
import {
    getPeerStudentIdsWithTeamLeaderForCompany,
    weeklyPlanWhereVisibleToSupervisor,
} from '../utils/supervisorWeeklyPlanFilter';

// 1. SUPERVISOR: Submit Final Evaluation (FR-16)
export const submitEvaluation = async (req: AuthRequest, res: Response) => {
    try {
        const { studentId, technical_skills, problem_solving, communication, team_collaboration, time_management, adaptability, professionalism, initiative_creativity, attendance_punctuality, task_completion_quality, comments } = req.body;

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) return sendError(res, 'Only supervisors can submit evaluations.', 403);

        const sid = parseInt(String(studentId), 10);
        const assignment = await prisma.internshipAssignment.findFirst({
            where: { studentId: sid, companyId: supervisor.companyId, status: 'ACTIVE' },
        });
        if (!assignment) return sendError(res, 'This student is not actively placed at your company.', 403);

        const peerWithTlIds = await getPeerStudentIdsWithTeamLeaderForCompany(supervisor.companyId);
        const supervisorWeeklyVisibility = weeklyPlanWhereVisibleToSupervisor(peerWithTlIds);

        const pendingPlans = await prisma.weeklyPlan.count({
            where: {
                studentId: sid,
                status: 'PENDING',
                ...supervisorWeeklyVisibility,
            },
        });
        if (pendingPlans > 0) {
            return sendError(res, 'Cannot submit final evaluation. There are still pending weekly plans that need approval.', 400);
        }

        const evaluation = await prisma.finalEvaluation.upsert({
            where: { studentId: sid },
            create: {
                studentId: sid,
                supervisorId: supervisor.id,
                technical_skills: parseFloat(technical_skills),
                problem_solving: parseFloat(problem_solving),
                communication: parseFloat(communication),
                team_collaboration: parseFloat(team_collaboration),
                time_management: parseFloat(time_management),
                adaptability: parseFloat(adaptability),
                professionalism: parseFloat(professionalism),
                initiative_creativity: parseFloat(initiative_creativity),
                attendance_punctuality: parseFloat(attendance_punctuality),
                task_completion_quality: parseFloat(task_completion_quality),
                comments,
            },
            update: {
                supervisorId: supervisor.id,
                technical_skills: parseFloat(technical_skills),
                problem_solving: parseFloat(problem_solving),
                communication: parseFloat(communication),
                team_collaboration: parseFloat(team_collaboration),
                time_management: parseFloat(time_management),
                adaptability: parseFloat(adaptability),
                professionalism: parseFloat(professionalism),
                initiative_creativity: parseFloat(initiative_creativity),
                attendance_punctuality: parseFloat(attendance_punctuality),
                task_completion_quality: parseFloat(task_completion_quality),
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
                `📊 Your final evaluation has been submitted with 10 criteria scores.`
            );
            // Notify HOD if linked
            if (student.hod) {
                await sendNotification(
                    student.hod.userId,
                    `📊 Final evaluation submitted for ${student.user.full_name} with 10 criteria scores.`
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
                technical_skills: Number(ev.technical_skills),
                problem_solving: Number(ev.problem_solving),
                communication: Number(ev.communication),
                team_collaboration: Number(ev.team_collaboration),
                time_management: Number(ev.time_management),
                adaptability: Number(ev.adaptability),
                professionalism: Number(ev.professionalism),
                initiative_creativity: Number(ev.initiative_creativity),
                attendance_punctuality: Number(ev.attendance_punctuality),
                task_completion_quality: Number(ev.task_completion_quality),
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
                weeklyReports: {
                    orderBy: { submitted_at: 'asc' },
                    include: {
                        weeklyPlan: { select: { week_number: true, daySubmissions: { select: { workDate: true } } } },
                    },
                },
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

        // 10-criteria score grid (2 columns)
        const criteria: Array<{ label: string; key: keyof typeof ev }> = [
            { label: 'Technical Skills', key: 'technical_skills' },
            { label: 'Problem Solving', key: 'problem_solving' },
            { label: 'Communication', key: 'communication' },
            { label: 'Team Collaboration', key: 'team_collaboration' },
            { label: 'Time Management', key: 'time_management' },
            { label: 'Adaptability', key: 'adaptability' },
            { label: 'Professionalism', key: 'professionalism' },
            { label: 'Initiative & Creativity', key: 'initiative_creativity' },
            { label: 'Attendance & Punctuality', key: 'attendance_punctuality' },
            { label: 'Task Completion Quality', key: 'task_completion_quality' },
        ];

        const gridStartY = evalY + 28;
        const colW = (doc.page.width - 120) / 2;
        const rowH = 28;

        criteria.forEach((c, i) => {
            const col = i % 2;
            const row = Math.floor(i / 2);
            const cx = 50 + col * (colW + 20);
            const cy = gridStartY + row * rowH;
            const bg = col === 0 ? '#e8f4fd' : '#edf7ee';
            const border = col === 0 ? '#b3d4f0' : '#b3ddb5';
            const textColor = col === 0 ? '#1e3a5f' : '#2d6a2d';
            doc.roundedRect(cx, cy, colW, rowH - 2, 4).fillAndStroke(bg, border);
            doc.fontSize(9).font('Helvetica-Bold').fillColor(textColor).text(c.label, cx + 8, cy + 5);
            doc.fontSize(11).font('Helvetica-Bold').fillColor(textColor)
                .text(`${Number(ev[c.key])}/100`, cx + colW - 60, cy + 5, { width: 55, align: 'right' });
        });

        // Overall average
        const overallAvg = Math.round(([
            ev.technical_skills, ev.problem_solving, ev.communication, ev.team_collaboration,
            ev.time_management, ev.adaptability, ev.professionalism, ev.initiative_creativity,
            ev.attendance_punctuality, ev.task_completion_quality,
        ].reduce((s, v) => s + Number(v), 0) / 10) * 10) / 10;

        const avgBoxY = gridStartY + Math.ceil(criteria.length / 2) * rowH + 6;
        doc.roundedRect(50, avgBoxY, doc.page.width - 100, 32, 5).fillAndStroke('#1e3a5f', '#1e3a5f');
        doc.fontSize(11).font('Helvetica-Bold').fillColor('#ffffff')
            .text(`Overall Average Score: ${overallAvg} / 100`, 60, avgBoxY + 9, { width: doc.page.width - 120, align: 'center' });

        // Comments
        if (ev.comments) {
            const commY = avgBoxY + 42;
            doc.fontSize(10).font('Helvetica-Bold').fillColor('#1e3a5f').text('Supervisor Comments:', 50, commY);
            doc.roundedRect(50, commY + 16, doc.page.width - 100, 50, 5).fillAndStroke('#fafafa', '#e0e0e0');
            doc.fontSize(10).font('Helvetica-Oblique').fillColor('#444')
                .text(`"${ev.comments}"`, 60, commY + 24, { width: doc.page.width - 120 });
        }

        // ── WEEKLY ATTENDANCE RECORD ──────────────────────────────────────────
        const attStartY = avgBoxY + (ev.comments ? 115 : 50);

        // Build attendance map: weekNumber → { mon, tue, wed, thu, fri }
        type DayStatus = 'PRESENT' | 'ABSENT' | 'LATE' | 'NONE';
        type WeekAttendance = { mon: DayStatus; tue: DayStatus; wed: DayStatus; thu: DayStatus; fri: DayStatus };

        const weekMap = new Map<number, WeekAttendance>();
        const emptyWeek = (): WeekAttendance => ({ mon: 'NONE', tue: 'NONE', wed: 'NONE', thu: 'NONE', fri: 'NONE' });
        const dayKeys: Array<keyof WeekAttendance> = ['mon', 'tue', 'wed', 'thu', 'fri'];

        // Populate from weeklyReports (one report per week)
        for (const wr of data.weeklyReports) {
            const wn = wr.weeklyPlan?.week_number;
            if (!wn) continue;
            if (!weekMap.has(wn)) weekMap.set(wn, emptyWeek());
            const entry = weekMap.get(wn)!;

            // Use day submissions to determine per-day status
            const submittedDays = new Set(
                (wr.weeklyPlan?.daySubmissions ?? []).map((d) => new Date(d.workDate).getDay()) // 1=Mon..5=Fri
            );

            // Map attendance status to each weekday
            const status = wr.attendanceStatus as DayStatus;
            for (let d = 1; d <= 5; d++) {
                const key = dayKeys[d - 1];
                if (submittedDays.has(d)) {
                    entry[key] = status;
                } else if (status === 'ABSENT') {
                    entry[key] = 'ABSENT';
                }
            }
        }

        // Determine total weeks from assignment duration or max week number
        const assignment = data.assignments.find((a) => a.status === 'ACTIVE') ?? data.assignments[0];
        let totalWeeks = weekMap.size > 0 ? Math.max(...weekMap.keys()) : 0;
        if (assignment?.start_date && assignment?.end_date) {
            const diffMs = new Date(assignment.end_date).getTime() - new Date(assignment.start_date).getTime();
            totalWeeks = Math.max(totalWeeks, Math.ceil(diffMs / (7 * 86400000)));
        }
        if (totalWeeks === 0) totalWeeks = data.weeklyPlans.length || 1;

        // Ensure all weeks exist in map
        for (let w = 1; w <= totalWeeks; w++) {
            if (!weekMap.has(w)) weekMap.set(w, emptyWeek());
        }

        // Count totals
        let totalPresent = 0, totalAbsent = 0, totalLate = 0, totalRecorded = 0;
        for (const [, week] of weekMap) {
            for (const key of dayKeys) {
                const s = week[key];
                if (s === 'PRESENT') { totalPresent++; totalRecorded++; }
                else if (s === 'ABSENT') { totalAbsent++; totalRecorded++; }
                else if (s === 'LATE') { totalLate++; totalRecorded++; }
            }
        }
        const attendancePct = totalRecorded > 0
            ? Math.round(((totalPresent + totalLate) / totalRecorded) * 100)
            : 0;

        // Section header
        doc.addPage();
        doc.rect(0, 0, doc.page.width, 80).fill('#1e3a5f');
        doc.fillColor('#ffffff').fontSize(20).font('Helvetica-Bold')
            .text('INTERNSHIP PERFORMANCE REPORT', 50, 25, { align: 'center' });
        doc.fontSize(9).font('Helvetica').fillColor('#a8c4e0')
            .text('InternLink — Official Internship Management System', 50, 52, { align: 'center' });

        const attY = 100;
        doc.fontSize(13).font('Helvetica-Bold').fillColor('#1e3a5f').text('WEEKLY ATTENDANCE RECORD', 50, attY);
        doc.moveTo(50, attY + 18).lineTo(doc.page.width - 50, attY + 18).strokeColor('#1e3a5f').lineWidth(1.5).stroke();
        doc.lineWidth(1);

        // Legend
        const legY = attY + 26;
        const legendItems = [
            { symbol: '\u2713', label: 'Present', color: '#16a34a' },
            { symbol: '\u2717', label: 'Absent', color: '#dc2626' },
            { symbol: 'L', label: 'Late', color: '#d97706' },
            { symbol: '\u2014', label: 'Not recorded', color: '#9ca3af' },
        ];
        let legX = 50;
        for (const item of legendItems) {
            doc.roundedRect(legX, legY, 14, 14, 2).fillAndStroke('#f8fafc', '#e2e8f0');
            doc.fontSize(8).font('Helvetica-Bold').fillColor(item.color).text(item.symbol, legX + 3, legY + 3);
            doc.fontSize(8).font('Helvetica').fillColor('#555').text(item.label, legX + 18, legY + 3);
            legX += 80;
        }

        // Table header
        const tblY = legY + 24;
        const colWidths = { week: 65, day: (doc.page.width - 165) / 5 };
        const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
        const tblRight = 50 + 65 + colWidths.day * 5;

        // Header row
        doc.rect(50, tblY, tblRight - 50, 20).fill('#1e3a5f');
        doc.fontSize(8).font('Helvetica-Bold').fillColor('#ffffff').text('WEEK', 55, tblY + 6);
        days.forEach((d, i) => {
            doc.text(d.toUpperCase(), 50 + 65 + i * colWidths.day + 4, tblY + 6, { width: colWidths.day - 4, align: 'center' });
        });

        // Week rows
        let tblRowY = tblY + 20;
        const sortedWeeks = Array.from(weekMap.entries()).sort(([a], [b]) => a - b);

        const statusSymbol = (s: DayStatus): string => {
            if (s === 'PRESENT') return '\u2713';  // ✓ check mark
            if (s === 'ABSENT') return '\u2717';   // ✗ ballot X
            if (s === 'LATE') return 'L';
            return '\u2014';                        // — em dash
        };
        const statusColor = (s: DayStatus): string => {
            if (s === 'PRESENT') return '#16a34a';
            if (s === 'ABSENT') return '#dc2626';
            if (s === 'LATE') return '#d97706';
            return '#9ca3af';
        };
        const statusBg = (s: DayStatus): string => {
            if (s === 'PRESENT') return '#f0fdf4';
            if (s === 'ABSENT') return '#fef2f2';
            if (s === 'LATE') return '#fffbeb';
            return '#f9fafb';
        };

        for (const [weekNum, week] of sortedWeeks) {
            const rowBg = weekNum % 2 === 0 ? '#f8fafc' : '#ffffff';
            doc.rect(50, tblRowY, tblRight - 50, 22).fill(rowBg).stroke();

            // Week label
            doc.rect(50, tblRowY, 65, 22).fill('#f0f4f8').stroke();
            doc.fontSize(9).font('Helvetica-Bold').fillColor('#1e3a5f')
                .text(`Week ${weekNum}`, 55, tblRowY + 7);

            // Day cells
            dayKeys.forEach((key, i) => {
                const s = week[key];
                const cellX = 50 + 65 + i * colWidths.day;
                doc.rect(cellX, tblRowY, colWidths.day, 22).fill(statusBg(s)).stroke();
                doc.fontSize(10).font('Helvetica-Bold').fillColor(statusColor(s))
                    .text(statusSymbol(s), cellX, tblRowY + 6, { width: colWidths.day, align: 'center' });
            });

            tblRowY += 22;

            // Add new page if running out of space
            if (tblRowY > doc.page.height - 160) {
                doc.addPage();
                tblRowY = 50;
            }
        }

        // Attendance Summary box
        const sumY = tblRowY + 16;
        doc.roundedRect(50, sumY, doc.page.width - 100, 80, 6).fillAndStroke('#f0f4f8', '#d0dce8');
        doc.fontSize(11).font('Helvetica-Bold').fillColor('#1e3a5f').text('ATTENDANCE SUMMARY', 70, sumY + 12);
        doc.moveTo(70, sumY + 28).lineTo(doc.page.width - 70, sumY + 28).strokeColor('#d0dce8').stroke();

        const sumCol1 = 70, sumCol2 = 230, sumCol3 = 380;
        doc.fontSize(9).font('Helvetica-Bold').fillColor('#16a34a').text(`\u2713 Present: ${totalPresent} days`, sumCol1, sumY + 36);
        doc.font('Helvetica-Bold').fillColor('#dc2626').text(`\u2717 Absent: ${totalAbsent} days`, sumCol2, sumY + 36);
        doc.font('Helvetica-Bold').fillColor('#d97706').text(`L Late: ${totalLate} days`, sumCol3, sumY + 36);
        doc.fontSize(10).font('Helvetica-Bold').fillColor('#1e3a5f')
            .text(`Attendance Rate: ${attendancePct}%`, sumCol1, sumY + 54);
        const rateBarW = doc.page.width - 260;
        doc.roundedRect(sumCol1 + 120, sumY + 56, rateBarW, 10, 3).fill('#e2e8f0');
        doc.roundedRect(sumCol1 + 120, sumY + 56, Math.round(rateBarW * attendancePct / 100), 10, 3)
            .fill(attendancePct >= 80 ? '#16a34a' : attendancePct >= 60 ? '#d97706' : '#dc2626');

        // ── WEEKLY PROGRESS SUMMARY ───────────────────────────────────────────
        const weekY = sumY + 110;
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
