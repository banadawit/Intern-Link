import { Response } from 'express';
import prisma from '../config/db';
import { safeFindFirstProposal } from '../utils/querySanitizer';
import { AuthRequest } from '../middlewares/authMiddleware';
import { ApprovalStatus } from '@prisma/client';
import { departmentsMatch } from '../utils/hodScope';
import { sendCompanyInviteEmail, sendStudentHodDecisionEmail } from '../services/email.service';
import { sendNotification } from '../utils/notificationHelper';
import { sendSuccess, sendError } from '../utils/responseHelper';

async function getHodOr403(userId: number) {
    const hod = await prisma.hodProfile.findUnique({
        where: { userId },
        include: { university: true },
    });
    return hod;
}

export const verifyStudent = async (req: AuthRequest, res: Response) => {
    // ⚠️ DEPRECATED: Use PATCH /hod/students/:id/approve or /reject instead.
    // This endpoint is kept for backward compatibility only.
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const { studentId, status, reason } = req.body as {
            studentId?: number;
            status?: string;
            reason?: string;
        };

        if (!studentId || !status || !['APPROVED', 'REJECTED'].includes(status)) {
            return sendError(res, 'studentId and status (APPROVED | REJECTED) are required.', 400);
        }

        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });
        
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return sendError(res, 'Student not in your department.', 404);
        }

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: status as ApprovalStatus },
        });

        if (status === 'APPROVED') {
            await prisma.user.update({
                where: { id: student.userId },
                data: { verification_status: 'APPROVED' },
            });
        }

        const msg = status === 'APPROVED'
            ? `Your registration has been approved by your Head of Department.`
            : `Your registration was not approved. Reason: ${reason?.trim() || 'No reason provided.'}`;
        
        await sendNotification(student.userId, msg);

        await sendStudentHodDecisionEmail({
            to: student.user.email,
            studentName: student.user.full_name,
            universityName: hod.university.name,
            department: hod.department,
            decision: status === 'APPROVED' ? 'approved' : 'rejected',
            reason: reason?.trim(),
        });

        return sendSuccess(res, { studentId, status }, `Student ${status.toLowerCase()}.`);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getDashboardStats = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const students = await prisma.student.findMany({
            where: { universityId: hod.universityId },
            select: { id: true, department: true, hodId: true, hod_approval_status: true, internship_status: true },
        });
        const inDept = students.filter((s) => s.hodId === hod.id || departmentsMatch(s.department, hod.department));
        const deptStudentIds = inDept.map((s) => s.id);

        const [reportCount, proposalStats, recentStudents] = await Promise.all([
            deptStudentIds.length === 0 ? Promise.resolve(0) : prisma.report.count({
                where: { studentId: { in: deptStudentIds } },
            }),
            deptStudentIds.length === 0 ? Promise.resolve({ pending: 0, approved: 0, rejected: 0 }) :
                prisma.internshipProposal.groupBy({
                    by: ['status'],
                    where: { studentId: { in: deptStudentIds } },
                    _count: { status: true },
                }).then((rows) => {
                    const map: Record<string, number> = {};
                    rows.forEach((r) => { map[r.status] = r._count.status; });
                    return { pending: map['PENDING'] ?? 0, approved: map['APPROVED'] ?? 0, rejected: map['REJECTED'] ?? 0 };
                }),
            deptStudentIds.length === 0 ? Promise.resolve([]) :
                prisma.student.findMany({
                    where: { id: { in: deptStudentIds }, hod_approval_status: 'PENDING' },
                    include: { user: { select: { full_name: true, email: true } } },
                    orderBy: { id: 'desc' },
                    take: 5,
                }),
        ]);

        const approvedCount = inDept.filter((s) => s.hod_approval_status === 'APPROVED').length;
        const rejectedCount = inDept.filter((s) => s.hod_approval_status === 'REJECTED').length;
        const pendingCount = inDept.filter((s) => s.hod_approval_status === 'PENDING').length;
        const placedCount = inDept.filter((s) => s.internship_status === 'PLACED').length;
        const notPlacedApproved = inDept.filter((s) => s.hod_approval_status === 'APPROVED' && s.internship_status !== 'PLACED').length;

        return sendSuccess(res, {
            totalStudents: inDept.length,
            pendingApprovals: pendingCount,
            approvedStudents: approvedCount,
            rejectedStudents: rejectedCount,
            placedStudents: placedCount,
            approvedNotPlaced: notPlacedApproved,
            reports: reportCount,
            proposals: proposalStats,
            recentPendingStudents: recentStudents.map((s) => ({
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

export const getStudents = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        if (!uid) return sendError(res, 'Unauthorized', 401);
        const hod = await getHodOr403(uid);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const status = (req.query.status as string) || 'all';
        const hodApprovalFilter: ApprovalStatus | 'all' =
            status === 'pending' ? 'PENDING' : status === 'approved' ? 'APPROVED' : status === 'rejected' ? 'REJECTED' : 'all';

        const rows = await prisma.student.findMany({
            where: {
                universityId: hod.universityId,
                ...(hodApprovalFilter !== 'all' ? { hod_approval_status: hodApprovalFilter } : {}),
                ...(status === 'placed' ? { internship_status: 'PLACED' } : {}),
            },
            include: {
                user: { select: { id: true, email: true, full_name: true, verification_status: true, verification_document: true } },
            },
            orderBy: { id: 'desc' },
        });

        // Match by hodId (direct link) OR by department name
        const filtered = rows.filter((s) => s.hodId === hod.id || departmentsMatch(s.department, hod.department));

        // Enrich each student with their latest proposal info so the UI can
        // show smart status badges without extra round-trips.
        const studentIds = filtered.map((s) => s.id);
        const proposals = studentIds.length === 0 ? [] : await prisma.internshipProposal.findMany({
            where: { studentId: { in: studentIds } },
            include: { company: { select: { id: true, name: true } } },
            orderBy: { submitted_at: 'desc' },
        });

        // Build a map: studentId → latest proposal
        const proposalMap = new Map<number, typeof proposals[0]>();
        for (const p of proposals) {
            if (!proposalMap.has(p.studentId)) proposalMap.set(p.studentId, p);
        }

        const enriched = filtered.map((s) => {
            const latestProposal = proposalMap.get(s.id);
            return {
                ...s,
                latestProposal: latestProposal
                    ? {
                          id: latestProposal.id,
                          status: latestProposal.status,
                          companyId: latestProposal.companyId,
                          companyName: latestProposal.company.name,
                          submittedAt: latestProposal.submitted_at,
                          proposalType: latestProposal.proposal_type,
                      }
                    : null,
            };
        });

        return sendSuccess(res, enriched);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const approveStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentId = parseInt(String(req.params.studentId), 10);
        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });
        
        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return sendError(res, 'Student not found in your department.', 404);
        }

        if (student.hod_approval_status === 'APPROVED') {
            return sendError(res, 'Student is already approved.', 409);
        }

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: 'APPROVED' },
        });

        await prisma.user.update({
            where: { id: student.userId },
            data: { verification_status: 'APPROVED' },
        });

        // Notify the student that they've been approved
        await sendNotification(
            student.userId,
            `✅ Your registration has been approved by your Head of Department. You can now log in to access the system.`
        );

        // Send approval email (fire-and-forget)
        sendStudentHodDecisionEmail({
            to: student.user.email,
            studentName: student.user.full_name,
            universityName: hod.university.name,
            department: hod.department,
            decision: 'approved',
        }).catch((e: any) => console.error('Approval email error:', e?.message));

        return sendSuccess(res, { studentId }, 'Student approved.');
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const rejectStudent = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentId = parseInt(String(req.params.studentId), 10);
        const student = await prisma.student.findUnique({
            where: { id: studentId },
            include: { user: true },
        });

        if (!student || student.universityId !== hod.universityId || !departmentsMatch(student.department, hod.department)) {
            return sendError(res, 'Student not found in your department.', 404);
        }

        if (student.hod_approval_status === 'REJECTED') {
            return sendError(res, 'Student is already rejected.', 409);
        }

        const reason = typeof req.body?.reason === 'string' ? req.body.reason.trim() : '';

        await prisma.student.update({
            where: { id: studentId },
            data: { hod_approval_status: 'REJECTED' },
        });

        await sendNotification(student.userId, `Your registration was not approved.${reason ? ` Reason: ${reason}` : ''}`);

        await sendStudentHodDecisionEmail({
            to: student.user.email,
            studentName: student.user.full_name,
            universityName: hod.university.name,
            department: hod.department,
            decision: 'rejected',
            reason,
        });

        return sendSuccess(res, { studentId }, 'Student rejected.');
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getCompanies = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
        const verifiedOnly = req.query.verifiedOnly !== 'false';

        const companies = await prisma.company.findMany({
            where: {
                ...(verifiedOnly ? { approval_status: 'APPROVED' } : {}),
                ...(q ? { name: { contains: q, mode: 'insensitive' } } : {}),
            },
            orderBy: { name: 'asc' },
            take: 200,
            include: {
                _count: {
                    select: {
                        supervisors: true,
                        assignments: { where: { status: 'ACTIVE' } },
                    },
                },
            },
        });

        const payload = companies.map((c) => ({
            id: c.id,
            name: c.name,
            official_email: c.official_email,
            address: c.address,
            approval_status: c.approval_status,
            created_at: c.created_at,
            supervisorCount: c._count.supervisors,
            activePlacementsCount: c._count.assignments,
        }));

        return sendSuccess(res, payload);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const sendProposal = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const {
            studentId,
            studentIds,
            companyId,
            proposal_type,
            proposal_kind,
            team_name,
            expected_duration_weeks,
            expected_outcomes,
        } = req.body;

        const cid = parseInt(String(companyId), 10);
        const kind: 'INDIVIDUAL' | 'TEAM' = proposal_kind === 'TEAM' ? 'TEAM' : 'INDIVIDUAL';

        // ── Resolve student list ──────────────────────────────────────────────
        let allStudentIds: number[];
        if (kind === 'TEAM') {
            if (!Array.isArray(studentIds) || studentIds.length < 2) {
                return sendError(res, 'TEAM proposals require at least 2 studentIds.', 400);
            }
            allStudentIds = studentIds.map((id: any) => parseInt(String(id), 10));
        } else {
            const sid = parseInt(String(studentId), 10);
            if (isNaN(sid)) return sendError(res, 'studentId is required for INDIVIDUAL proposals.', 400);
            allStudentIds = [sid];
        }

        // ── Validate company ──────────────────────────────────────────────────
        const company = await prisma.company.findUnique({ where: { id: cid } });
        if (!company || company.approval_status !== 'APPROVED') {
            return sendError(res, 'Company must be verified (approved).', 400);
        }

        // ── Validate all students ─────────────────────────────────────────────
        const students = await prisma.student.findMany({
            where: { id: { in: allStudentIds } },
        });

        if (students.length !== allStudentIds.length) {
            return sendError(res, 'One or more students not found.', 400);
        }

        const errors: string[] = [];
        for (const s of students) {
            if (s.universityId !== hod.universityId || !departmentsMatch(s.department, hod.department)) {
                errors.push(`Student ${s.id} is not in your department.`);
            } else if (s.hod_approval_status !== 'APPROVED') {
                errors.push(`Student ${s.id} must be approved by HOD before placement.`);
            } else if (s.internship_status === 'PLACED') {
                errors.push(`Student ${s.id} already has an active internship placement.`);
            }
        }
        if (errors.length > 0) return sendError(res, errors.join(' '), 400);

        // ── Duplicate check for each student ──────────────────────────────────
        for (const sid of allStudentIds) {
            // Only check PENDING status — SENT/DRAFT don't exist in ApprovalStatus enum
            const dup = await safeFindFirstProposal({
                where: { studentId: sid, companyId: cid, status: 'PENDING' },
            });
            if (dup) {
                return res.status(400).json({
                    success: false,
                    message: `Student already has a pending proposal for this company.`,
                    data: {
                        studentId: sid,
                        proposalStatus: 'PENDING',
                        proposalId: dup.id,
                        companyId: cid,
                        companyName: company.name,
                        submittedAt: dup.submitted_at,
                    },
                });
            }

            // Check ProposalTeamMember only if table exists (requires regenerated Prisma client)
            try {
                const teamDup = await (prisma as any).proposalTeamMember.findFirst({
                    where: {
                        studentId: sid,
                        proposal: { companyId: cid, status: 'PENDING' },
                    },
                    include: { proposal: { include: { company: { select: { name: true } } } } },
                });
                if (teamDup) {
                    return res.status(400).json({
                        success: false,
                        message: `Student is already in an active team proposal for this company.`,
                        data: {
                            studentId: sid,
                            proposalStatus: 'PENDING',
                            proposalId: teamDup.proposalId,
                            companyId: cid,
                            companyName: teamDup.proposal?.company?.name ?? company.name,
                            teamName: (teamDup.proposal as any)?.team_name ?? null,
                            submittedAt: (teamDup.proposal as any)?.submitted_at ?? null,
                        },
                    });
                }
            } catch (_) {
                // ProposalTeamMember table not available yet — skip this check
            }
        }

        // ── Create proposal ───────────────────────────────────────────────────
        const leadStudentId = allStudentIds[0];
        const additionalStudentIds = allStudentIds.slice(1);

        // Parse attachments from request body (JSON string array or already parsed)
        let proposalAttachments: object[] = [];
        if (req.body.attachments) {
            try {
                proposalAttachments = typeof req.body.attachments === 'string'
                    ? JSON.parse(req.body.attachments)
                    : req.body.attachments;
            } catch { proposalAttachments = []; }
        }

        // Use only the core fields that definitely exist in the current Prisma client
        const coreProposalData = {
            studentId: leadStudentId,
            companyId: cid,
            universityId: hod.universityId,
            proposal_type: kind === 'TEAM'
                ? `HoD_Team:${(team_name || 'Team').trim()}:${allStudentIds.join(',')}`
                : (proposal_type || 'HoD_Initiated'),
            status: 'PENDING' as const,
            ...(expected_duration_weeks != null ? { expected_duration_weeks: parseInt(String(expected_duration_weeks), 10) } : {}),
            ...(typeof expected_outcomes === 'string' && expected_outcomes.trim() ? { expected_outcomes: expected_outcomes.trim() } : {}),
        };

        // Create with core fields only — guaranteed to work regardless of Prisma client version
        const proposal = await prisma.internshipProposal.create({ data: coreProposalData });

        // Try to update with new fields (proposal_kind, team_name) if Prisma client supports them
        try {
            await (prisma.internshipProposal as any).update({
                where: { id: proposal.id },
                data: {
                    proposal_kind: kind,
                    ...(kind === 'TEAM' ? { team_name: (team_name || 'Team').trim() } : {}),
                },
            });
        } catch (_) {
            // New fields not available in current Prisma client — skip silently
        }

        // Try to add team members if table exists
        if (kind === 'TEAM' && additionalStudentIds.length > 0) {
            try {
                await (prisma as any).proposalTeamMember.createMany({
                    data: additionalStudentIds.map((sid: number) => ({
                        proposalId: proposal.id,
                        studentId: sid,
                    })),
                    skipDuplicates: true,
                });
            } catch (teamErr: any) {
                console.warn('ProposalTeamMember insert skipped:', teamErr.message);
            }
        }

        return sendSuccess(res, { ...proposal, proposal_kind: kind, teamMembers: [] }, 'Proposal sent.', 201);
    } catch (e: any) {
        console.error('sendProposal error:', e.message);
        return sendError(res, e.message);
    }
};

export const getProposals = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const students = await prisma.student.findMany({
            where: { universityId: hod.universityId, department: { not: null } },
            select: { id: true, department: true },
        });
        const studentIds = students.filter((s) => departmentsMatch(s.department, hod.department)).map((s) => s.id);

        // Parse optional status filter — only accept valid ApprovalStatus values
        const validStatuses = ['PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED', 'CANCELLED'];
        const rawStatus = typeof req.query.status === 'string' ? req.query.status.toUpperCase().trim() : null;
        const statusFilter = rawStatus && validStatuses.includes(rawStatus) ? rawStatus as ApprovalStatus : null;

        const proposals = await prisma.internshipProposal.findMany({
            where: {
                studentId: { in: studentIds },
                ...(statusFilter ? { status: statusFilter } : {}),
            },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: { select: { id: true, name: true, official_email: true, approval_status: true } },
            },
            orderBy: { submitted_at: 'desc' },
        });

        // Enrich with team members if available (requires regenerated Prisma client)
        const enriched = await Promise.all(proposals.map(async (p) => {
            try {
                const members = await (prisma as any).proposalTeamMember.findMany({
                    where: { proposalId: p.id },
                    include: { student: { include: { user: { select: { full_name: true, email: true } } } } },
                });
                return { ...p, teamMembers: members, proposal_kind: (p as any).proposal_kind ?? 'INDIVIDUAL', team_name: (p as any).team_name ?? null };
            } catch {
                return { ...p, teamMembers: [], proposal_kind: 'INDIVIDUAL', team_name: null };
            }
        }));
        return sendSuccess(res, enriched);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const inviteCompany = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const { email, company_name } = req.body;
        if (!email || !company_name) return sendError(res, 'email and company_name are required', 400);

        const existing = await prisma.company.findFirst({ where: { official_email: email } });
        if (existing) return sendError(res, 'A company with this email already exists.', 400);

        const company = await prisma.company.create({
            data: { name: company_name, official_email: email, approval_status: 'PENDING' },
        });

        const hodUser = await prisma.user.findUnique({ where: { id: uid } });
        await sendCompanyInviteEmail({
            to: email,
            companyName: company_name,
            universityName: hod.university.name,
            hodName: hodUser?.full_name ?? 'Head of Department',
        });

        return sendSuccess(res, { companyId: company.id }, 'Invitation sent.', 201);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getOpenLetterProposals = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const students = await prisma.student.findMany({
            where: { universityId: hod.universityId, department: { not: null } },
            select: { id: true, department: true },
        });
        const studentIds = students.filter((s) => departmentsMatch(s.department, hod.department)).map((s) => s.id);

        const proposals = await prisma.internshipProposal.findMany({
            where: { studentId: { in: studentIds }, proposal_type: 'Open_Letter' },
            include: {
                student: { include: { user: { select: { full_name: true, email: true } } } },
                company: true,
            },
            orderBy: { submitted_at: 'desc' },
        });
        return sendSuccess(res, proposals);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const updateOpenLetterProposal = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const id = parseInt(String(req.params.id), 10);
        const { status, reason } = req.body as { status?: string; reason?: string };

        if (Number.isNaN(id) || !status || !['APPROVED', 'REJECTED'].includes(status)) {
            return sendError(res, 'Valid status (APPROVED|REJECTED) required', 400);
        }

        // Load the proposal with student + company
        const proposal = await prisma.internshipProposal.findUnique({
            where: { id },
            include: {
                student: { include: { user: { select: { id: true, full_name: true, email: true } } } },
                company: { select: { id: true, name: true, official_email: true } },
            },
        });

        if (!proposal || !proposal.proposal_type.startsWith('Open_Letter')) {
            return sendError(res, 'Open letter proposal not found.', 404);
        }

        if (proposal.status !== 'PENDING') {
            return sendError(res, `This open letter has already been ${proposal.status.toLowerCase()}.`, 400);
        }

        const student = proposal.student;
        if (
            student.universityId !== hod.universityId ||
            !departmentsMatch(student.department, hod.department)
        ) {
            return sendError(res, 'Unauthorized.', 403);
        }

        const rejectionReason = typeof reason === 'string' && reason.trim()
            ? reason.trim()
            : 'Your open letter request was reviewed and could not be approved at this time.';

        // ── Update proposal status ────────────────────────────────────────────
        const updated = await prisma.internshipProposal.update({
            where: { id },
            data: { status: status as ApprovalStatus, responded_at: new Date() },
        });

        if (status === 'APPROVED') {
            // ── In-app notification to student ────────────────────────────────
            await sendNotification(
                student.user.id,
                `✅ Your open letter request for ${proposal.company.name} was approved by your HoD. The proposal has been forwarded to the company.`
            );

            // ── Email to student ──────────────────────────────────────────────
            const hodUser = await prisma.user.findUnique({ where: { id: uid! }, select: { full_name: true } });
            sendStudentHodDecisionEmail({
                to: student.user.email,
                studentName: student.user.full_name,
                universityName: hod.university.name,
                department: hod.department,
                decision: 'approved',
            }).catch((e: any) => console.error('Open letter approval email error:', e?.message));

            // ── Notify all supervisors at the target company ──────────────────
            const supervisors = await prisma.supervisor.findMany({
                where: { companyId: proposal.companyId },
                select: { userId: true },
            });
            for (const sup of supervisors) {
                await sendNotification(
                    sup.userId,
                    `📋 New internship proposal: ${student.user.full_name} from ${hod.university.name} is applying for an internship at your company. Please review and respond.`
                );
            }

        } else {
            // ── REJECTED: notify student with reason ──────────────────────────
            await sendNotification(
                student.user.id,
                `❌ Your open letter request for ${proposal.company.name} was not approved by your HoD.${rejectionReason ? ` Reason: ${rejectionReason}` : ''}`
            );

            // ── Email to student with rejection reason ────────────────────────
            sendStudentHodDecisionEmail({
                to: student.user.email,
                studentName: student.user.full_name,
                universityName: hod.university.name,
                department: hod.department,
                decision: 'rejected',
                reason: rejectionReason,
            }).catch((e: any) => console.error('Open letter rejection email error:', e?.message));
        }

        return sendSuccess(res, updated, `Open letter ${status.toLowerCase()}.`);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getReports = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const studentsInDept = await prisma.student.findMany({
            where: { universityId: hod.universityId, department: { not: null } },
            select: { id: true, department: true },
        });
        const deptIds = studentsInDept.filter((s) => departmentsMatch(s.department, hod.department)).map((s) => s.id);
        
        const reports = deptIds.length === 0 ? [] : await prisma.report.findMany({
            where: { studentId: { in: deptIds } },
            include: { student: { include: { user: { select: { full_name: true, email: true } } } } },
            orderBy: { generated_at: 'desc' },
        });
        return sendSuccess(res, reports);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

export const getReportDownload = async (req: AuthRequest, res: Response) => {
    try {
        const uid = req.user?.userId;
        const hod = await getHodOr403(uid!);
        if (!hod) return sendError(res, 'HOD profile not found.', 403);

        const id = parseInt(String(req.params.id), 10);
        const report = await prisma.report.findUnique({
            where: { id },
            include: { student: true },
        });
        
        if (!report) return sendError(res, 'Report not found', 404);
        if (report.student.universityId !== hod.universityId || !departmentsMatch(report.student.department, hod.department)) {
            return sendError(res, 'Unauthorized', 403);
        }

        return sendSuccess(res, { pdf_url: report.pdf_url, stamped: report.stamped, generated_at: report.generated_at });
    } catch (e: any) {
        return sendError(res, e.message);
    }
};
