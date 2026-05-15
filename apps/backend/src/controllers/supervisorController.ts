import { Response } from 'express';
import type { Prisma } from '@prisma/client';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { ymdFromUtcMs } from '../utils/internshipWeekDates';
import { sendSuccess, sendError } from '../utils/responseHelper';
import {
    getPeerStudentIdsWithTeamLeaderForCompany,
    weeklyPlanWhereVisibleToSupervisor,
} from '../utils/supervisorWeeklyPlanFilter';

export const getSupervisorMe = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
            include: {
                user: { select: { full_name: true, email: true } },
                company: true,
            },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 404);
        }

        const companyId = supervisor.companyId;
        const peerWithTlIds = await getPeerStudentIdsWithTeamLeaderForCompany(companyId);
        const supervisorWeeklyVisibility = weeklyPlanWhereVisibleToSupervisor(peerWithTlIds);

        // ── Core counts ───────────────────────────────────────────────────────
        const [
            pendingProposalsCount,
            pendingWeeklyPlansCount,
            placedStudentsCount,
            approvedProposalsCount,
            reportsSubmittedCount,
            recentPendingProposals,
            recentPendingPlans,
        ] = await Promise.all([
            prisma.internshipProposal.count({ where: { companyId, status: 'PENDING' } }),
            prisma.weeklyPlan.count({
                where: {
                    status: 'PENDING',
                    student: { assignments: { some: { companyId, status: 'ACTIVE' } } },
                    ...supervisorWeeklyVisibility,
                },
            }),
            prisma.internshipAssignment.count({ where: { companyId, status: 'ACTIVE' } }),
            prisma.internshipProposal.count({ where: { companyId, status: 'APPROVED' } }),
            prisma.report.count({ where: { student: { assignments: { some: { companyId } } } } }),
            prisma.internshipProposal.findMany({
                where: { companyId, status: 'PENDING' },
                orderBy: { submitted_at: 'desc' },
                take: 3,
                include: {
                    student: { include: { user: { select: { full_name: true, email: true } } } },
                    university: { select: { name: true } },
                },
            }),
            prisma.weeklyPlan.findMany({
                where: {
                    status: 'PENDING',
                    student: { assignments: { some: { companyId, status: 'ACTIVE' } } },
                    ...supervisorWeeklyVisibility,
                },
                orderBy: { submitted_at: 'desc' },
                take: 3,
                include: {
                    student: { include: { user: { select: { full_name: true } } } },
                },
            }),
        ]);

        // ── Students summary (for snapshot section) ───────────────────────────
        const activeAssignments = await prisma.internshipAssignment.findMany({
            where: { companyId, status: 'ACTIVE' },
            include: {
                student: {
                    include: {
                        user: { select: { id: true, full_name: true, email: true } },
                        weeklyPlans: {
                            orderBy: { submitted_at: 'desc' },
                            take: 1,
                            select: { status: true, submitted_at: true, week_number: true },
                        },
                    },
                },
            },
        });

        // ── Missed check-ins: students with APPROVED plan but no check-in today ─
        const today = new Date();
        const todayStart = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()));
        const todayEnd = new Date(todayStart.getTime() + 86400000);

        const approvedPlanStudentIds = await prisma.weeklyPlan.findMany({
            where: {
                status: 'APPROVED',
                student: { assignments: { some: { companyId, status: 'ACTIVE' } } },
            },
            select: { studentId: true, id: true },
        });

        const checkedInToday = await prisma.weeklyPlanDaySubmission.findMany({
            where: {
                workDate: { gte: todayStart, lt: todayEnd },
                weeklyPlanId: { in: approvedPlanStudentIds.map((p) => p.id) },
            },
            select: { weeklyPlanId: true },
        });

        const checkedInPlanIds = new Set(checkedInToday.map((c) => c.weeklyPlanId));
        const missedCheckinsCount = approvedPlanStudentIds.filter((p) => !checkedInPlanIds.has(p.id)).length;

        // ── Students snapshot ─────────────────────────────────────────────────
        const studentsSummary = activeAssignments.map((a) => {
            const latestPlan = a.student.weeklyPlans[0];
            const daysSinceLastPlan = latestPlan
                ? Math.floor((Date.now() - new Date(latestPlan.submitted_at).getTime()) / 86400000)
                : null;

            // Status logic: at-risk if no plan in 7+ days or rejected plan
            let status: 'ACTIVE' | 'AT_RISK' | 'INACTIVE' = 'ACTIVE';
            if (!latestPlan || daysSinceLastPlan === null || daysSinceLastPlan > 14) {
                status = 'INACTIVE';
            } else if (latestPlan.status === 'REJECTED' || daysSinceLastPlan > 7) {
                status = 'AT_RISK';
            }

            return {
                studentId: a.student.id,
                studentName: a.student.user.full_name,
                studentEmail: a.student.user.email,
                status,
                lastPlanStatus: latestPlan?.status ?? null,
                lastPlanWeek: latestPlan?.week_number ?? null,
                daysSinceLastPlan,
                startDate: a.start_date,
            };
        });

        // ── Recent activity feed ──────────────────────────────────────────────
        const [recentPlans, recentProposals] = await Promise.all([
            prisma.weeklyPlan.findMany({
                where: {
                    student: { assignments: { some: { companyId, status: 'ACTIVE' } } },
                    ...supervisorWeeklyVisibility,
                },
                orderBy: { submitted_at: 'desc' },
                take: 5,
                select: {
                    id: true, week_number: true, status: true, submitted_at: true,
                    student: { include: { user: { select: { full_name: true } } } },
                },
            }),
            prisma.internshipProposal.findMany({
                where: { companyId },
                orderBy: { submitted_at: 'desc' },
                take: 5,
                select: {
                    id: true, status: true, submitted_at: true,
                    student: { include: { user: { select: { full_name: true } } } },
                },
            }),
        ]);

        const recentActivity = [
            ...recentPlans.map((p) => ({
                type: 'PLAN',
                id: p.id,
                title: `${p.student.user.full_name} submitted Week ${p.week_number} plan`,
                status: p.status,
                timestamp: p.submitted_at,
            })),
            ...recentProposals.map((p) => ({
                type: 'PROPOSAL',
                id: p.id,
                title: `Proposal from ${p.student.user.full_name}`,
                status: p.status,
                timestamp: p.submitted_at,
            })),
        ].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()).slice(0, 8);

        // ── Deadlines (students without evaluation, approaching end date) ─────
        const approachingEnd = await prisma.internshipAssignment.findMany({
            where: {
                companyId,
                status: 'ACTIVE',
                end_date: {
                    not: null,
                    lte: new Date(Date.now() + 14 * 86400000), // within 14 days
                    gte: new Date(),
                },
            },
            include: {
                student: {
                    include: {
                        user: { select: { full_name: true } },
                        finalEvaluation: { select: { id: true } },
                    },
                },
            },
        });

        const deadlines = approachingEnd.map((a) => ({
            type: a.student.finalEvaluation ? 'REPORT_DUE' : 'EVALUATION_DUE',
            studentName: a.student.user.full_name,
            dueDate: a.end_date,
            daysLeft: a.end_date
                ? Math.ceil((new Date(a.end_date).getTime() - Date.now()) / 86400000)
                : null,
        }));

        return sendSuccess(res, {
            supervisor,
            stats: {
                pendingProposalsCount,
                pendingWeeklyPlansCount,
                placedStudentsCount,
                approvedProposalsCount,
                reportsSubmittedCount,
                missedCheckinsCount,
            },
            recentPendingProposals: recentPendingProposals.map((p) => ({
                id: p.id,
                studentName: p.student.user.full_name,
                studentEmail: p.student.user.email,
                universityName: p.university.name,
                submitted_at: p.submitted_at,
            })),
            recentPendingPlans: recentPendingPlans.map((p) => ({
                id: p.id,
                studentName: p.student.user.full_name,
                weekNumber: p.week_number,
                submitted_at: p.submitted_at,
            })),
            studentsSummary,
            recentActivity,
            deadlines,
        }, 'Supervisor profile fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const getCompanyStudents = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
        }

        const assignments = await prisma.internshipAssignment.findMany({
            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
            include: {
                student: {
                    include: {
                        user: { select: { id: true, full_name: true, email: true } },
                        university: { select: { id: true, name: true } },
                        finalReport: {
                            select: { locked: true, sent_at: true, pdf_url: true, generated_at: true },
                        },
                        finalEvaluation: {
                            select: { technical_skills: true, problem_solving: true, communication: true, team_collaboration: true, time_management: true, adaptability: true, professionalism: true, initiative_creativity: true, attendance_punctuality: true, task_completion_quality: true, comments: true },
                        },
                    },
                },
            },
            orderBy: { start_date: 'desc' },
        });

        const payload = assignments.map((a) => ({
            student: {
                id: a.student.id,
                internship_status: a.student.internship_status,
                department: a.student.department,
                user: a.student.user,
                university: a.student.university,
                finalReport: a.student.finalReport,
                finalEvaluation: a.student.finalEvaluation ?? null,
            },
            assignment: {
                id: a.id,
                start_date: a.start_date,
                end_date: a.end_date,
                status: a.status,
                project_name: a.project_name,
            },
        }));

        // Enrich with computed attendance stats for each student
        const enriched = await Promise.all(payload.map(async (row) => {
            try {
                const [weeklyReports, daySubmissions] = await Promise.all([
                    prisma.weeklyReport.findMany({
                        where: { studentId: row.student.id },
                        select: { attendanceStatus: true },
                    }),
                    prisma.weeklyPlanDaySubmission.findMany({
                        where: { weeklyPlan: { studentId: row.student.id } },
                        select: { status: true, tl_status: true },
                    }),
                ]);

                const totalWeeks = weeklyReports.length;
                const presentWeeks = weeklyReports.filter((r) => r.attendanceStatus === 'PRESENT').length;
                const totalDays = daySubmissions.length;
                const approvedDays = daySubmissions.filter((d) => d.status === 'APPROVED' || d.tl_status === 'APPROVED').length;

                // Compute attendance score (0-10): weighted average of weekly + daily attendance
                let attendanceScore: number | null = null;
                if (totalWeeks > 0 || totalDays > 0) {
                    const weeklyPct = totalWeeks > 0 ? presentWeeks / totalWeeks : 0;
                    const dailyPct = totalDays > 0 ? approvedDays / totalDays : weeklyPct;
                    const combined = totalDays > 0 ? (weeklyPct * 0.4 + dailyPct * 0.6) : weeklyPct;
                    attendanceScore = Math.round(combined * 100) / 10; // 0-10 scale
                }

                return {
                    ...row,
                    attendanceStats: {
                        totalWeeks,
                        presentWeeks,
                        totalDays,
                        approvedDays,
                        attendanceScore,
                        attendancePct: totalWeeks > 0 ? Math.round((presentWeeks / totalWeeks) * 100) : null,
                    },
                };
            } catch {
                return { ...row, attendanceStats: null };
            }
        }));

        return sendSuccess(res, enriched, 'Students fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const getCompanyWeeklyPlans = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
        }

        const active = await prisma.internshipAssignment.findMany({
            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
            select: { studentId: true },
        });
        const studentIds = [...new Set(active.map((a) => a.studentId))];
        if (studentIds.length === 0) {
            return sendSuccess(res, [], 'No students found');
        }

        const statusParam = typeof req.query.status === 'string' ? req.query.status.toUpperCase() : undefined;
        const peerWithTlIds = await getPeerStudentIdsWithTeamLeaderForCompany(supervisor.companyId);
        const supervisorWeeklyVisibility = weeklyPlanWhereVisibleToSupervisor(peerWithTlIds);

        const where: Prisma.WeeklyPlanWhereInput = {
            studentId: { in: studentIds },
            ...(statusParam === 'PENDING' || statusParam === 'APPROVED' || statusParam === 'REJECTED'
                ? { status: statusParam }
                : {}),
            ...supervisorWeeklyVisibility,
        };

        const plans = await prisma.weeklyPlan.findMany({
            where,
            include: {
                student: {
                    include: {
                        user: { select: { full_name: true, email: true } },
                        university: { select: { id: true, name: true } },
                    },
                },
                presentation: true,
            },
            orderBy: [{ submitted_at: 'desc' }],
        });

        return sendSuccess(res, plans, 'Weekly plans fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

/** FR-6.5: Weekly attendance & execution records for company-placed students */
export const listWeeklyAttendanceReports = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
        }

        const reports = await prisma.weeklyReport.findMany({
            where: {
                student: {
                    assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } },
                },
            },
            include: {
                student: {
                    include: {
                        user: { select: { full_name: true, email: true } },
                        assignments: {
                            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
                            take: 1,
                            select: { start_date: true },
                        },
                    },
                },
                weeklyPlan: {
                    select: {
                        id: true,
                        week_number: true,
                        status: true,
                        daySubmissions: { select: { workDate: true } },
                    },
                },
            },
            orderBy: { submitted_at: 'desc' },
        });

        return sendSuccess(res, reports, 'Attendance reports fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const patchWeeklyAttendanceReport = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        if (Number.isNaN(id)) {
            return sendError(res, 'Invalid id.', 400);
        }

        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
        }

        const report = await prisma.weeklyReport.findUnique({
            where: { id },
            include: {
                student: {
                    include: {
                        assignments: {
                            where: { companyId: supervisor.companyId, status: 'ACTIVE' },
                        },
                    },
                },
            },
        });

        if (!report || report.student.assignments.length === 0) {
            return sendError(res, 'Report not found or not in scope for your company.', 403);
        }

        const { attendanceStatus, execution_status, remarks } = req.body as {
            attendanceStatus?: string;
            execution_status?: string;
            remarks?: string;
        };

        const allowed = ['PRESENT', 'ABSENT', 'LATE'];
        const data: {
            attendanceStatus?: 'PRESENT' | 'ABSENT' | 'LATE';
            execution_status?: string | null;
            remarks?: string | null;
        } = {};

        if (attendanceStatus && allowed.includes(attendanceStatus)) {
            data.attendanceStatus = attendanceStatus as 'PRESENT' | 'ABSENT' | 'LATE';
        }
        if (typeof execution_status === 'string') {
            data.execution_status = execution_status;
        }
        if (typeof remarks === 'string') {
            data.remarks = remarks;
        }

        const updated = await prisma.weeklyReport.update({
            where: { id },
            data,
        });

        return sendSuccess(res, updated, 'Attendance report updated');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

/** GitHub-style contribution data: daily check-ins per student (approved plans only). */
export const getAttendanceHeatmap = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) {
            return sendError(res, 'Supervisor profile not found.', 403);
        }

        const today = new Date();
        const endUtc = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate());
        const startUtc = endUtc - 371 * 86400000;

        const placedStudents = await prisma.student.findMany({
            where: {
                assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } },
            },
            select: {
                id: true,
                user: { select: { full_name: true, email: true } },
            },
        });

        const peerWithTlIds = await getPeerStudentIdsWithTeamLeaderForCompany(supervisor.companyId);
        const supervisorWeeklyVisibility = weeklyPlanWhereVisibleToSupervisor(peerWithTlIds);

        // For solo students: show all daily submissions (any status)
        // For team students: only show submissions with status='APPROVED' (set when supervisor approves team daily plan)
        // This ensures absent team members don't appear in the heatmap
        const rows = await prisma.weeklyPlanDaySubmission.findMany({
            where: {
                weeklyPlan: {
                    student: {
                        assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } },
                    },
                },
                workDate: { gte: new Date(startUtc), lte: new Date(endUtc) },
                // Team students: only count APPROVED daily submissions (supervisor-approved team daily plan)
                // Solo students: count all submissions (status defaults to PENDING until reviewed)
                OR: [
                    // Solo student submissions — show all
                    {
                        weeklyPlan: {
                            studentId: peerWithTlIds.length > 0 ? { notIn: peerWithTlIds } : undefined,
                        },
                    },
                    // Team student submissions — show all (tl_status not in schema)
                    ...(peerWithTlIds.length > 0 ? [{
                        weeklyPlan: { studentId: { in: peerWithTlIds } },
                    }] : []),
                ],
            },
            select: {
                workDate: true,
                weeklyPlan: {
                    select: {
                        studentId: true,
                        student: { select: { user: { select: { full_name: true, email: true } } } },
                    },
                },
            },
        });

        // Approved weekly plan dates (dark green — supervisor approved)
        const approvedPlans = await prisma.weeklyPlan.findMany({
            where: {
                status: 'APPROVED',
                student: { assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } } },
                reviewed_at: { gte: new Date(startUtc), lte: new Date(endUtc) },
            },
            select: { studentId: true, reviewed_at: true, submitted_at: true },
        });

        // Plan submission dates (medium green — visible to supervisor: TL-approved for teammates)
        const planSubmissions = await prisma.weeklyPlan.findMany({
            where: {
                student: { assignments: { some: { companyId: supervisor.companyId, status: 'ACTIVE' } } },
                submitted_at: { gte: new Date(startUtc), lte: new Date(endUtc) },
                ...supervisorWeeklyVisibility,
            },
            select: { studentId: true, submitted_at: true },
        });

        const byStudent = new Map<
            number,
            { fullName: string; email: string; dailyDates: Set<string>; approvedDates: Set<string>; submittedDates: Set<string> }
        >();

        const ensureEntry = (sid: number, fullName: string, email: string) => {
            if (!byStudent.has(sid)) {
                byStudent.set(sid, { fullName, email, dailyDates: new Set(), approvedDates: new Set(), submittedDates: new Set() });
            }
            return byStudent.get(sid)!;
        };

        for (const r of rows) {
            const sid = r.weeklyPlan.studentId;
            const u = r.weeklyPlan.student.user;
            const entry = ensureEntry(sid, u.full_name, u.email);
            entry.dailyDates.add(ymdFromUtcMs(new Date(r.workDate).getTime()));
        }

        for (const p of approvedPlans) {
            const student = placedStudents.find((s) => s.id === p.studentId);
            if (student) {
                const dateMs = p.reviewed_at ? new Date(p.reviewed_at).getTime() : new Date(p.submitted_at).getTime();
                ensureEntry(p.studentId, student.user.full_name, student.user.email).approvedDates.add(ymdFromUtcMs(dateMs));
            }
        }

        for (const p of planSubmissions) {
            const student = placedStudents.find((s) => s.id === p.studentId);
            if (student) {
                ensureEntry(p.studentId, student.user.full_name, student.user.email).submittedDates.add(ymdFromUtcMs(new Date(p.submitted_at).getTime()));
            }
        }

        const rangeEnd = ymdFromUtcMs(endUtc);
        const rangeStart = ymdFromUtcMs(startUtc);

        const merged = placedStudents.map((s) => {
            const sub = byStudent.get(s.id);
            return {
                studentId: s.id,
                fullName: s.user.full_name,
                email: s.user.email,
                submittedDates: sub ? [...new Set([...sub.dailyDates, ...sub.approvedDates, ...sub.submittedDates])].sort() : [],
                dailyCheckInDates: sub ? [...sub.dailyDates].sort() : [],
                approvedPlanDates: sub ? [...sub.approvedDates].sort() : [],
                planSubmissionDates: sub ? [...sub.submittedDates].sort() : [],
            };
        });

        return sendSuccess(res, {
            rangeStart,
            rangeEnd,
            students: merged,
        }, 'Attendance heatmap fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

export const submitEvaluation = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId: req.user!.userId },
        });
        if (!supervisor) return sendError(res, 'Supervisor profile not found.', 403);

        const { studentId, technical_skills, problem_solving, communication, team_collaboration, time_management, adaptability, professionalism, initiative_creativity, attendance_punctuality, task_completion_quality, comments } = req.body;
        const sid = parseInt(String(studentId), 10);

        // Verify student belongs to this company
        const assignment = await prisma.internshipAssignment.findFirst({
            where: { studentId: sid, companyId: supervisor.companyId, status: 'ACTIVE' },
        });
        if (!assignment) {
            return sendError(res, 'Student not assigned to your company.', 403);
        }

        const evaluation = await prisma.finalEvaluation.upsert({
            where: { studentId: sid },
            update: {
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
                evaluated_at: new Date(),
            },
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
        });

        return sendSuccess(res, evaluation, 'Evaluation submitted successfully.');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

// --- PERFORMANCE SUMMARY ---

export const getSupervisorPerformance = async (req: AuthRequest, res: Response) => {
    try {
        const supervisor = await prisma.supervisor.findUnique({ where: { userId: req.user!.userId } });
        if (!supervisor) return sendError(res, 'Supervisor profile not found.', 403);

        const companyId = supervisor.companyId;

        const [
            totalStudentsEver,
            completedInternships,
            evaluations,
            approvedProposals,
            totalProposals,
            approvedPlans,
            totalPlans,
        ] = await Promise.all([
            // All students ever assigned (active + completed + terminated)
            prisma.internshipAssignment.count({ where: { companyId } }),
            prisma.internshipAssignment.count({ where: { companyId, status: 'COMPLETED' } }),
            prisma.finalEvaluation.findMany({
                where: { supervisor: { companyId } },
                select: { technical_skills: true, problem_solving: true, communication: true, team_collaboration: true, time_management: true, adaptability: true, professionalism: true, initiative_creativity: true, attendance_punctuality: true, task_completion_quality: true },
            }),
            prisma.internshipProposal.count({ where: { companyId, status: 'APPROVED' } }),
            prisma.internshipProposal.count({ where: { companyId } }),
            prisma.weeklyPlan.count({
                where: {
                    status: 'APPROVED',
                    student: { assignments: { some: { companyId } } },
                },
            }),
            prisma.weeklyPlan.count({
                where: { student: { assignments: { some: { companyId } } } },
            }),
        ]);

        const avg10 = (e: any) => [e.technical_skills, e.problem_solving, e.communication, e.team_collaboration, e.time_management, e.adaptability, e.professionalism, e.initiative_creativity, e.attendance_punctuality, e.task_completion_quality].reduce((s: number, v: any) => s + Number(v), 0) / 10;
        const avgScore = evaluations.length > 0
            ? evaluations.reduce((sum, e) => sum + avg10(e), 0) / evaluations.length
            : null;

        const proposalApprovalRate = totalProposals > 0
            ? Math.round((approvedProposals / totalProposals) * 100)
            : null;

        const planApprovalRate = totalPlans > 0
            ? Math.round((approvedPlans / totalPlans) * 100)
            : null;

        return sendSuccess(res, {
            totalStudentsSupervised: totalStudentsEver,
            completedInternships,
            averageStudentScore: avgScore !== null ? Math.round(avgScore * 10) / 10 : null,
            evaluationsSubmitted: evaluations.length,
            proposalApprovalRate,
            planApprovalRate,
        }, 'Performance summary fetched');
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Server error';
        return sendError(res, message, 500);
    }
};

// --- COMPANY STAMP UPLOAD ---

/**
 * Upload or replace company stamp image
 * Used for stamping final reports
 */
export const uploadCompanyStamp = async (req: AuthRequest, res: Response) => {
    try {
        const file = req.file;
        const userId = req.user?.userId;

        if (!file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }

        // Get supervisor's company
        const supervisor = await prisma.supervisor.findUnique({
            where: { userId },
            include: { company: true },
        });

        if (!supervisor) {
            return res.status(403).json({ error: 'Supervisor profile not found' });
        }

        const { CloudinaryService } = await import('../services/cloudinary.service');

        const folder = `internlink/${supervisor.companyId}/${userId}/stamps`;

        // Check if stamp already exists
        const existingStamp = supervisor.company.stamp_image_url;

        let uploadResult;

        if (existingStamp) {
            // Upload new stamp directly (no file record lookup needed)
            uploadResult = await CloudinaryService.uploadImage(file, {
                userId,
                organizationId: supervisor.companyId,
                fileType: 'COMPANY_STAMP',
                folder,
                resourceType: 'image',
            });
        } else {
            // Upload new stamp
            uploadResult = await CloudinaryService.uploadImage(file, {
                userId,
                organizationId: supervisor.companyId,
                fileType: 'COMPANY_STAMP',
                folder,
                resourceType: 'image',
            });
        }

        if (!uploadResult.success) {
            return res.status(400).json({ error: uploadResult.error });
        }

        // Update company record
        await prisma.company.update({
            where: { id: supervisor.companyId },
            data: { stamp_image_url: uploadResult.url },
        });

        res.json({
            message: existingStamp
                ? 'Company stamp replaced successfully'
                : 'Company stamp uploaded successfully',
            url: uploadResult.url,
            fileId: uploadResult.fileId,
        });
    } catch (error: any) {
        console.error('Upload company stamp error:', error);
        res.status(500).json({ error: error.message });
    }
};
