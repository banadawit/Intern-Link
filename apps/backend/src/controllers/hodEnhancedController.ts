import { Response } from 'express';
import prisma from '../config/db';
import { ApprovalStatus } from '@prisma/client';
import { AuthRequest } from '../middlewares/authMiddleware';
import { departmentsMatch } from '../utils/hodScope';
import { sendNotification } from '../utils/notificationHelper';
import { sendSuccess, sendError } from '../utils/responseHelper';

// ── Shared helpers ────────────────────────────────────────────────────────────

async function getHodOr403(userId: number) {
    return prisma.hodProfile.findUnique({
        where: { userId },
        include: { university: true },
    });
}

async function getDeptStudentIds(hod: { universityId: number; department: string }): Promise<number[]> {
    const students = await prisma.student.findMany({
        where: { universityId: hod.universityId, department: { not: null } },
        select: { id: true, department: true },
    });
    return students
        .filter((s) => departmentsMatch(s.department, hod.department))
        .map((s) => s.id);
}

function weeksAgo(n: number): Date {
    const d = new Date();
    d.setDate(d.getDate() - n * 7);
    return d;
}

function daysAgo(n: number): Date {
    const d = new Date();
    d.setDate(d.getDate() - n);
    return d;
}

// ── 1. Enhanced Dashboard Stats ───────────────────────────────────────────────

export const getEnhancedStats = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const deptStudentIds = await getDeptStudentIds(hod);

        if (deptStudentIds.length === 0) {
            return sendSuccess(res, {
                totalStudents: 0, pendingApprovals: 0, approvedStudents: 0,
                rejectedStudents: 0, placedStudents: 0, approvedNotPlaced: 0,
                reports: 0, proposals: { pending: 0, approved: 0, rejected: 0 },
                placementRate: 0, reportsCompletionRate: 0, approvalSuccessRate: 0,
                alerts: [], weeklyPlacementTrend: [],
                recentPendingStudents: [],
                university: { name: hod.university.name },
                department: hod.department,
            });
        }

        const thirtyDaysAgo = daysAgo(30);
        const fourteenDaysAgo = daysAgo(14);
        const eightWeeksAgo = weeksAgo(8);

        const [students, assignments, proposals30d, weeklyAssignments, reports, evaluations, recentPending] =
            await Promise.all([
                prisma.student.findMany({
                    where: { id: { in: deptStudentIds } },
                    include: { user: { select: { full_name: true, email: true } } },
                }),
                prisma.internshipAssignment.findMany({
                    where: { studentId: { in: deptStudentIds } },
                    include: { company: { select: { name: true } }, student: { include: { user: { select: { full_name: true } } } } },
                }),
                prisma.internshipProposal.findMany({
                    where: { studentId: { in: deptStudentIds }, submitted_at: { gte: thirtyDaysAgo } },
                }),
                prisma.internshipAssignment.findMany({
                    where: { studentId: { in: deptStudentIds }, start_date: { gte: eightWeeksAgo } },
                    select: { start_date: true },
                }),
                prisma.report.findMany({ where: { studentId: { in: deptStudentIds } } }),
                prisma.finalEvaluation.findMany({ where: { studentId: { in: deptStudentIds } } }),
                prisma.student.findMany({
                    where: { id: { in: deptStudentIds }, hod_approval_status: 'PENDING' },
                    include: { user: { select: { full_name: true, email: true } } },
                    orderBy: { id: 'desc' },
                    take: 5,
                }),
            ]);

        // Basic counts
        const pendingCount = students.filter((s) => s.hod_approval_status === 'PENDING').length;
        const approvedCount = students.filter((s) => s.hod_approval_status === 'APPROVED').length;
        const rejectedCount = students.filter((s) => s.hod_approval_status === 'REJECTED').length;
        const placedCount = students.filter((s) => s.internship_status === 'PLACED').length;
        const approvedNotPlaced = students.filter(
            (s) => s.hod_approval_status === 'APPROVED' && s.internship_status !== 'PLACED',
        ).length;

        // Proposal stats (all time)
        const allProposals = await prisma.internshipProposal.findMany({
            where: { studentId: { in: deptStudentIds } },
            select: { status: true, studentId: true, companyId: true },
        });
        const proposalStats = {
            pending: allProposals.filter((p) => p.status === 'PENDING').length,
            approved: allProposals.filter((p) => p.status === 'APPROVED').length,
            rejected: allProposals.filter((p) => p.status === 'REJECTED').length,
        };

        // Rates
        const placementRate = approvedCount > 0 ? Math.round((placedCount / approvedCount) * 10000) / 100 : 0;
        const reportsCompletionRate = placedCount > 0 ? Math.round((reports.length / placedCount) * 10000) / 100 : 0;
        const approved30d = proposals30d.filter((p) => p.status === 'APPROVED').length;
        const approvalSuccessRate = proposals30d.length > 0
            ? Math.round((approved30d / proposals30d.length) * 10000) / 100
            : 0;

        // Alerts
        const alerts: any[] = [];
        const now = new Date();

        // UNPLACED: approved > 30 days, not placed
        for (const s of students) {
            if (s.hod_approval_status === 'APPROVED' && s.internship_status !== 'PLACED') {
                const daysSince = Math.floor((now.getTime() - s.created_at.getTime()) / 86400000);
                if (daysSince > 30) {
                    alerts.push({
                        type: 'UNPLACED',
                        message: `${s.user.full_name} has been approved for ${daysSince} days without a placement`,
                        studentId: s.id,
                        studentName: s.user.full_name,
                        daysElapsed: daysSince,
                    });
                }
            }
        }

        // NEEDS_REASSIGNMENT: all proposals rejected/cancelled
        const studentProposalMap = new Map<number, string[]>();
        for (const p of allProposals) {
            const arr = studentProposalMap.get(p.studentId) ?? [];
            arr.push(p.status);
            studentProposalMap.set(p.studentId, arr);
        }
        for (const s of students) {
            if (s.hod_approval_status === 'APPROVED' && s.internship_status !== 'PLACED') {
                const statuses = studentProposalMap.get(s.id) ?? [];
                if (statuses.length > 0 && statuses.every((st) => st === 'REJECTED' || st === 'CANCELLED')) {
                    alerts.push({
                        type: 'NEEDS_REASSIGNMENT',
                        message: `${s.user.full_name}'s proposals were all rejected — needs reassignment`,
                        studentId: s.id,
                        studentName: s.user.full_name,
                    });
                }
            }
        }

        // INACTIVE: placed student, no WeeklyReport in 14 days
        const placedStudentIds = students.filter((s) => s.internship_status === 'PLACED').map((s) => s.id);
        if (placedStudentIds.length > 0) {
            const recentReports = await prisma.weeklyReport.findMany({
                where: { studentId: { in: placedStudentIds }, submitted_at: { gte: fourteenDaysAgo } },
                select: { studentId: true },
            });
            const activeReporters = new Set(recentReports.map((r) => r.studentId));
            for (const s of students) {
                if (s.internship_status === 'PLACED' && !activeReporters.has(s.id)) {
                    alerts.push({
                        type: 'INACTIVE',
                        message: `${s.user.full_name} has not submitted a weekly report in 14 days`,
                        studentId: s.id,
                        studentName: s.user.full_name,
                    });
                }
            }
        }

        // Weekly placement trend (8 weeks)
        const weeklyPlacementTrend: { weekLabel: string; weekStart: string; count: number }[] = [];
        for (let i = 7; i >= 0; i--) {
            const weekStart = weeksAgo(i + 1);
            const weekEnd = weeksAgo(i);
            const count = weeklyAssignments.filter(
                (a) => a.start_date >= weekStart && a.start_date < weekEnd,
            ).length;
            weeklyPlacementTrend.push({
                weekLabel: `W${8 - i}`,
                weekStart: weekStart.toISOString().split('T')[0],
                count,
            });
        }

        return sendSuccess(res, {
            totalStudents: students.length,
            pendingApprovals: pendingCount,
            approvedStudents: approvedCount,
            rejectedStudents: rejectedCount,
            placedStudents: placedCount,
            approvedNotPlaced,
            reports: reports.length,
            proposals: proposalStats,
            placementRate,
            reportsCompletionRate,
            approvalSuccessRate,
            alerts,
            weeklyPlacementTrend,
            recentPendingStudents: recentPending.map((s) => ({
                id: s.id,
                full_name: s.user.full_name,
                email: s.user.email,
            })),
            university: { name: hod.university.name },
            department: hod.department,
        });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 2. Bulk Approve Students ──────────────────────────────────────────────────

export const bulkApproveStudents = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const { studentIds } = req.body as { studentIds?: number[] };
        if (!Array.isArray(studentIds) || studentIds.length === 0) {
            return sendError(res, 'studentIds array is required.', 400);
        }
        if (studentIds.length > 100) {
            return sendError(res, 'Cannot bulk approve more than 100 students at once.', 400);
        }

        const deptStudentIds = new Set(await getDeptStudentIds(hod));
        const approved: number[] = [];
        const skipped: { studentId: number; reason: string }[] = [];
        const outOfScope: number[] = [];

        for (const sid of studentIds) {
            if (!deptStudentIds.has(sid)) {
                outOfScope.push(sid);
                continue;
            }
            const student = await prisma.student.findUnique({
                where: { id: sid },
                include: { user: true },
            });
            if (!student) { outOfScope.push(sid); continue; }
            if (student.hod_approval_status !== 'PENDING') {
                skipped.push({ studentId: sid, reason: `Already ${student.hod_approval_status}` });
                continue;
            }
            await prisma.student.update({ where: { id: sid }, data: { hod_approval_status: 'APPROVED' } });
            await prisma.user.update({ where: { id: student.userId }, data: { verification_status: 'APPROVED' } });
            await sendNotification(student.userId, '✅ Your registration has been approved by your Head of Department.');
            approved.push(sid);
        }

        return sendSuccess(res, { approved, skipped, outOfScope });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 3. Flag Student ───────────────────────────────────────────────────────────

export const flagStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentId = parseInt(String(req.params.id), 10);
        const { flagType, note } = req.body as { flagType?: string; note?: string };

        if (!flagType || !['LOW_PERFORMANCE', 'INACTIVE'].includes(flagType)) {
            return sendError(res, 'flagType must be LOW_PERFORMANCE or INACTIVE.', 400);
        }

        const deptIds = await getDeptStudentIds(hod);
        if (!deptIds.includes(studentId)) return sendError(res, 'Student not in your department.', 403);

        await prisma.student.update({
            where: { id: studentId },
            data: { flag_type: flagType, flag_note: note?.trim() ?? null },
        });

        // Notify the student
        const student = await prisma.student.findUnique({ where: { id: studentId }, select: { userId: true } });
        if (student) {
            const label = flagType === 'LOW_PERFORMANCE' ? 'Low Performance' : 'Inactive';
            const noteText = note?.trim() ? ` Note from your HOD: "${note.trim()}"` : '';
            await sendNotification(
                student.userId,
                `⚠️ Your profile has been flagged as ${label} by your Head of Department.${noteText} Please contact them for more information.`
            );
        }

        return sendSuccess(res, { studentId, flagType, note: note?.trim() ?? null });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 4. Unflag Student ─────────────────────────────────────────────────────────

export const unflagStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentId = parseInt(String(req.params.id), 10);
        const deptIds = await getDeptStudentIds(hod);
        if (!deptIds.includes(studentId)) return sendError(res, 'Student not in your department.', 403);

        await prisma.student.update({
            where: { id: studentId },
            data: { flag_type: null, flag_note: null },
        });

        return sendSuccess(res, { studentId, flagType: null });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 5. Student Timeline ───────────────────────────────────────────────────────

export const getStudentTimeline = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentId = parseInt(String(req.params.id), 10);
        const deptIds = await getDeptStudentIds(hod);
        if (!deptIds.includes(studentId)) return sendError(res, 'Student not in your department.', 403);

        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: {
                proposals: { orderBy: { submitted_at: 'asc' }, take: 1 },
                assignments: { orderBy: { start_date: 'asc' }, take: 1 },
            },
        });
        if (!student) return sendError(res, 'Student not found.', 404);

        const timeline: { state: string; timestamp: string; actor: string }[] = [];

        // REGISTERED
        timeline.push({ state: 'REGISTERED', timestamp: student.created_at.toISOString(), actor: 'student' });

        // APPROVED or REJECTED
        if (student.hod_approval_status === 'APPROVED' || student.hod_approval_status === 'REJECTED') {
            timeline.push({
                state: student.hod_approval_status,
                timestamp: student.created_at.toISOString(), // best proxy
                actor: 'hod',
            });
        }

        // PROPOSED
        if (student.proposals.length > 0) {
            timeline.push({
                state: 'PROPOSED',
                timestamp: student.proposals[0].submitted_at.toISOString(),
                actor: 'hod',
            });
        }

        // PLACED / ACTIVE
        if (student.assignments.length > 0) {
            const a = student.assignments[0];
            timeline.push({ state: 'PLACED', timestamp: a.start_date.toISOString(), actor: 'system' });
            if (a.status === 'ACTIVE') {
                timeline.push({ state: 'ACTIVE', timestamp: a.start_date.toISOString(), actor: 'system' });
            }
            if (a.status === 'COMPLETED' && a.end_date) {
                timeline.push({ state: 'COMPLETED', timestamp: a.end_date.toISOString(), actor: 'system' });
            }
            if (a.status === 'TERMINATED' && a.end_date) {
                timeline.push({ state: 'TERMINATED', timestamp: a.end_date.toISOString(), actor: 'system' });
            }
        }

        return sendSuccess(res, timeline);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 6. Reprocess Rejected Student ────────────────────────────────────────────

export const reprocessStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentId = parseInt(String(req.params.id), 10);
        const deptIds = await getDeptStudentIds(hod);
        if (!deptIds.includes(studentId)) return sendError(res, 'Student not in your department.', 403);

        const student = await prisma.student.findUnique({ where: { id: studentId } });
        if (!student) return sendError(res, 'Student not found.', 404);
        if (student.hod_approval_status !== 'REJECTED') {
            return sendError(res, 'Student is not in REJECTED status.', 400);
        }

        await prisma.student.update({ where: { id: studentId }, data: { hod_approval_status: 'PENDING' } });
        return sendSuccess(res, { studentId, hod_approval_status: 'PENDING' });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 7. Proposal State Machine ─────────────────────────────────────────────────

const VALID_TRANSITIONS: Record<string, string[]> = {
    DRAFT: ['SENT', 'CANCELLED'],
    SENT: ['PENDING', 'CANCELLED'],
    PENDING: ['APPROVED', 'REJECTED'],
    APPROVED: [],
    REJECTED: [],
    CANCELLED: [],
    SUSPENDED: [],
};

export const transitionProposalState = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const proposalId = parseInt(String(req.params.id), 10);
        const { targetState } = req.body as { targetState?: string };
        if (!targetState) return sendError(res, 'targetState is required.', 400);

        const proposal = await prisma.internshipProposal.findUnique({
            where: { id: proposalId },
            include: {
                student: { include: { user: true } },
            },
        });
        if (!proposal) return sendError(res, 'Proposal not found.', 404);

        const deptIds = await getDeptStudentIds(hod);
        if (!deptIds.includes(proposal.studentId)) return sendError(res, 'Proposal not in your department.', 403);

        const currentStatus = proposal.status as string;
        const allowed = VALID_TRANSITIONS[currentStatus] ?? [];
        if (!allowed.includes(targetState)) {
            return sendError(res, `Invalid transition: ${currentStatus} → ${targetState}`, 400);
        }

        // Ensure the target state is a valid Prisma ApprovalStatus before updating the DB
        const validApprovalStatuses = new Set<string>(Object.values(ApprovalStatus) as string[]);
        if (!validApprovalStatuses.has(targetState)) {
            return sendError(res, `targetState must be one of: ${[...validApprovalStatuses].join(', ')}`, 400);
        }

        const isTerminal = ['APPROVED', 'REJECTED', 'CANCELLED'].includes(targetState);
        const updated = await prisma.internshipProposal.update({
            where: { id: proposalId },
            data: {
                status: targetState as ApprovalStatus,
                ...(isTerminal ? { responded_at: new Date() } : {}),
            },
        });

        // Collect all student userIds (lead + team members if available)
        const allUserIds: number[] = [proposal.student.userId];
        try {
            const teamMembers = await (prisma as any).proposalTeamMember.findMany({
                where: { proposalId },
                include: { student: { include: { user: { select: { userId: true } } } } },
            });
            for (const m of teamMembers ?? []) {
                if (m.student?.user?.id) allUserIds.push(m.student.user.id);
            }
        } catch (_) { /* ProposalTeamMember not available yet */ }

        // Notifications to all students
        if (targetState === 'APPROVED') {
            for (const userId of allUserIds) {
                await sendNotification(userId, `✅ Your internship proposal has been approved!`);
            }
        } else if (targetState === 'REJECTED') {
            for (const userId of allUserIds) {
                await sendNotification(userId, `Your internship proposal was not approved.`);
            }
        }

        return sendSuccess(res, updated);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 8. Get Placements ─────────────────────────────────────────────────────────

export const getPlacements = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const deptIds = await getDeptStudentIds(hod);
        const statusFilter = req.query.status as string | undefined;

        const assignments = await prisma.internshipAssignment.findMany({
            where: {
                studentId: { in: deptIds },
                ...(statusFilter ? { status: statusFilter as any } : {}),
            },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: { select: { id: true, name: true } },
            },
            orderBy: { start_date: 'desc' },
        });

        const payload = assignments.map((a) => ({
            id: a.id,
            studentId: a.studentId,
            studentName: a.student.user.full_name,
            studentEmail: a.student.user.email,
            companyId: a.companyId,
            companyName: a.company.name,
            startDate: a.start_date,
            endDate: a.end_date,
            status: a.status,
            projectName: a.project_name,
        }));

        return sendSuccess(res, payload);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 9. Force End Placement ────────────────────────────────────────────────────

export const forceEndPlacement = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const placementId = parseInt(String(req.params.id), 10);
        const { reason } = req.body as { reason?: string };

        const assignment = await prisma.internshipAssignment.findUnique({
            where: { id: placementId },
            include: { student: true },
        });
        if (!assignment) return sendError(res, 'Placement not found.', 404);

        const deptIds = await getDeptStudentIds(hod);
        if (!deptIds.includes(assignment.studentId)) return sendError(res, 'Placement not in your department.', 403);

        if (assignment.status === 'COMPLETED' || assignment.status === 'TERMINATED') {
            return sendError(res, `Placement is already ${assignment.status}.`, 400);
        }

        await prisma.internshipAssignment.update({
            where: { id: placementId },
            data: { status: 'TERMINATED', end_date: new Date() },
        });

        // Reset student internship status so they can be reassigned
        await prisma.student.update({
            where: { id: assignment.studentId },
            data: { internship_status: 'PENDING' },
        });

        return sendSuccess(res, { placementId, status: 'TERMINATED', reason: reason ?? '' });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 10. Get Weekly Reports ────────────────────────────────────────────────────

export const getWeeklyReports = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const deptIds = await getDeptStudentIds(hod);
        const weekNumber = req.query.weekNumber ? parseInt(String(req.query.weekNumber), 10) : undefined;
        const attendanceStatus = req.query.attendanceStatus as string | undefined;
        const studentName = req.query.studentName as string | undefined;

        const reports = await prisma.weeklyReport.findMany({
            where: {
                studentId: { in: deptIds },
                ...(attendanceStatus ? { attendanceStatus: attendanceStatus as any } : {}),
                ...(weekNumber ? { weeklyPlan: { week_number: weekNumber } } : {}),
            },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                weeklyPlan: { select: { week_number: true } },
            },
            orderBy: { submitted_at: 'desc' },
        });

        let filtered = reports;
        if (studentName) {
            const lower = studentName.toLowerCase();
            filtered = reports.filter((r) =>
                r.student.user.full_name.toLowerCase().includes(lower),
            );
        }

        const payload = filtered.map((r) => ({
            id: r.id,
            studentId: r.studentId,
            studentName: r.student.user.full_name,
            weekNumber: r.weeklyPlan?.week_number ?? null,
            attendanceStatus: r.attendanceStatus,
            executionStatus: r.execution_status,
            remarks: r.remarks,
            submittedAt: r.submitted_at,
        }));

        return sendSuccess(res, payload);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 11. Get Reports Summary ───────────────────────────────────────────────────

export const getReportsSummary = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const deptIds = await getDeptStudentIds(hod);

        const [weeklyReports, evaluations, students, finalReports] = await Promise.all([
            prisma.weeklyReport.findMany({
                where: { studentId: { in: deptIds } },
                select: { attendanceStatus: true },
            }),
            prisma.finalEvaluation.findMany({
                where: { studentId: { in: deptIds } },
                select: { technical_skills: true, problem_solving: true, communication: true, team_collaboration: true, time_management: true, adaptability: true, professionalism: true, initiative_creativity: true, attendance_punctuality: true, task_completion_quality: true },
            }),
            prisma.student.findMany({
                where: { id: { in: deptIds } },
                select: { internship_status: true },
            }),
            prisma.report.findMany({ where: { studentId: { in: deptIds } }, select: { id: true } }),
        ]);

        const attendance = { PRESENT: 0, ABSENT: 0, LATE: 0 };
        for (const r of weeklyReports) {
            if (r.attendanceStatus in attendance) {
                (attendance as any)[r.attendanceStatus]++;
            }
        }

        const avg10 = (e: any) => [e.technical_skills, e.problem_solving, e.communication, e.team_collaboration, e.time_management, e.adaptability, e.professionalism, e.initiative_creativity, e.attendance_punctuality, e.task_completion_quality].reduce((s: number, v: any) => s + Number(v), 0) / 10;
        const avgTech = evaluations.length > 0
            ? evaluations.reduce((sum, e) => sum + avg10(e), 0) / evaluations.length
            : null;
        const avgSoft = avgTech; // same overall average

        const studentsPlaced = students.filter((s) => s.internship_status === 'PLACED').length;

        return sendSuccess(res, {
            totalWeeklyReports: weeklyReports.length,
            attendance,
            averageScore: avgTech !== null ? Math.round(avgTech * 100) / 100 : null,
            studentsWithFinalReport: finalReports.length,
            studentsPlaced,
        });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};
