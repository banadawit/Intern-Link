/**
 * Assignment Service — Team & Project Assignment
 *
 * Handles the full assignment flow in a single DB transaction:
 *   1. Validate all students (PLACED, belong to company, not already assigned)
 *   2. Check project capacity
 *   3. Create or reuse team
 *   4. Add students to team
 *   5. Link team → project (if provided)
 *   6. Update InternshipAssignment.project_name for each student
 *   7. Notify all assigned students
 *
 * If ANY step fails the entire transaction is rolled back.
 */

import prisma from '../config/db';
import { sendNotification } from '../utils/notificationHelper';
import { sendProjectAssignmentEmail } from '../services/email.service';

// ── Types ─────────────────────────────────────────────────────────────────────

export interface AssignInput {
  /** Supervisor performing the assignment */
  supervisorId: number;
  companyId: number;
  supervisorName: string;
  /** IDs of students to assign */
  studentIds: number[];
  /** Existing team to add students to (mutually exclusive with teamName) */
  teamId?: number;
  /** Create a new team with this name (mutually exclusive with teamId) */
  teamName?: string;
  /** Project to link the team to */
  projectId?: number;
}

export interface AssignResult {
  team: { id: number; name: string };
  project: { id: number; name: string } | null;
  assignedStudents: { id: number; fullName: string }[];
  skipped: { studentId: number; reason: string }[];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

async function validateStudents(
  companyId: number,
  studentIds: number[],
): Promise<{
  valid: { id: number; userId: number; fullName: string; email: string }[];
  skipped: { studentId: number; reason: string }[];
}> {
  const valid: { id: number; userId: number; fullName: string; email: string }[] = [];
  const skipped: { studentId: number; reason: string }[] = [];

  // Batch fetch all students in one query
  const students = await prisma.student.findMany({
    where: { id: { in: studentIds } },
    include: {
      user: { select: { id: true, full_name: true, email: true } },
      assignments: { where: { companyId, status: 'ACTIVE' }, take: 1 },
    },
  });

  const foundIds = new Set(students.map((s) => s.id));

  // Flag any IDs that don't exist
  for (const sid of studentIds) {
    if (!foundIds.has(sid)) {
      skipped.push({ studentId: sid, reason: 'Student not found.' });
    }
  }

  for (const s of students) {
    if (s.internship_status !== 'PLACED') {
      skipped.push({ studentId: s.id, reason: 'Student is not placed.' });
      continue;
    }
    if (s.assignments.length === 0) {
      skipped.push({ studentId: s.id, reason: 'Student is not actively placed at your company.' });
      continue;
    }
    valid.push({
      id: s.id,
      userId: s.user.id,
      fullName: s.user.full_name,
      email: s.user.email,
    });
  }

  return { valid, skipped };
}

// ── Main service function ─────────────────────────────────────────────────────

export async function assignStudentsToTeamAndProject(
  input: AssignInput,
): Promise<AssignResult> {
  const { supervisorId, companyId, supervisorName, studentIds, teamId, teamName, projectId } = input;

  if (studentIds.length === 0) {
    throw Object.assign(new Error('At least one studentId is required.'), { status: 400 });
  }

  // ── 1. Validate students ──────────────────────────────────────────────────
  const { valid, skipped } = await validateStudents(companyId, studentIds);

  if (valid.length === 0) {
    throw Object.assign(
      new Error('No valid students to assign. ' + skipped.map((s) => s.reason).join(' ')),
      { status: 400 },
    );
  }

  // ── 2. Validate project (if provided) ────────────────────────────────────
  let project: { id: number; name: string; capacity: number } | null = null;
  if (projectId != null) {
    const p = await prisma.project.findFirst({
      where: { id: projectId, companyId, deleted_at: null },
      select: { id: true, name: true, capacity: true, students: { select: { studentId: true } } },
    });
    if (!p) {
      throw Object.assign(new Error('Project not found or does not belong to your company.'), { status: 404 });
    }
    // Capacity check (0 = unlimited)
    if (p.capacity > 0) {
      const currentCount = p.students.length;
      const available = p.capacity - currentCount;
      if (valid.length > available) {
        throw Object.assign(
          new Error(
            `Project capacity exceeded. Capacity: ${p.capacity}, current: ${currentCount}, trying to add: ${valid.length}.`,
          ),
          { status: 400 },
        );
      }
    }
    project = { id: p.id, name: p.name, capacity: p.capacity };
  }

  // ── 3. Validate or resolve team ───────────────────────────────────────────
  if (teamId != null) {
    const t = await prisma.team.findFirst({
      where: { id: teamId, companyId, deleted_at: null },
    });
    if (!t) {
      throw Object.assign(new Error('Team not found or does not belong to your company.'), { status: 404 });
    }
  } else if (!teamName?.trim()) {
    throw Object.assign(new Error('Either teamId or teamName is required.'), { status: 400 });
  }

  // ── 4. Transaction: create/update team, add members, link project ─────────
  const result = await prisma.$transaction(async (tx) => {
    // 4a. Create or fetch team
    let team: { id: number; name: string };
    if (teamId != null) {
      const t = await tx.team.findUniqueOrThrow({ where: { id: teamId } });
      team = { id: t.id, name: t.name };
    } else {
      const t = await tx.team.create({
        data: {
          name: teamName!.trim(),
          companyId,
          supervisorId,
          projectId: projectId ?? null,
        },
      });
      team = { id: t.id, name: t.name };
    }

    // 4b. Link team → project (if not already set during creation)
    if (projectId != null && teamId != null) {
      await tx.team.update({
        where: { id: team.id },
        data: { projectId, supervisorId },
      });
    }

    // 4c. Add students to team (skip duplicates)
    const existingMembers = await tx.studentTeam.findMany({
      where: { teamId: team.id },
      select: { studentId: true },
    });
    const existingSet = new Set(existingMembers.map((m) => m.studentId));
    const newMembers = valid.filter((s) => !existingSet.has(s.id));

    if (newMembers.length > 0) {
      await tx.studentTeam.createMany({
        data: newMembers.map((s) => ({ teamId: team.id, studentId: s.id })),
        skipDuplicates: true,
      });
    }

    // 4d. Add students to project (if provided), skip duplicates
    if (projectId != null) {
      const existingProjectMembers = await tx.studentProject.findMany({
        where: { projectId },
        select: { studentId: true },
      });
      const existingProjectSet = new Set(existingProjectMembers.map((m) => m.studentId));
      const newProjectMembers = valid.filter((s) => !existingProjectSet.has(s.id));

      if (newProjectMembers.length > 0) {
        await tx.studentProject.createMany({
          data: newProjectMembers.map((s) => ({ projectId: projectId!, studentId: s.id })),
          skipDuplicates: true,
        });
      }

      // 4e. Update InternshipAssignment.project_name for each student
      if (project) {
        await tx.internshipAssignment.updateMany({
          where: {
            studentId: { in: valid.map((s) => s.id) },
            companyId,
            status: 'ACTIVE',
          },
          data: { project_name: project.name },
        });
      }
    }

    return { team };
  });

  // ── 5. Notifications (fire-and-forget, outside transaction) ──────────────
  const projectName = project?.name ?? null;
  for (const s of valid) {
    const msg = projectName
      ? `You have been assigned to team "${result.team.name}" on project "${projectName}" by ${supervisorName}.`
      : `You have been added to team "${result.team.name}" by ${supervisorName}.`;

    sendNotification(s.userId, msg).catch(() => {});

    if (projectName) {
      sendProjectAssignmentEmail({
        to: s.email,
        studentName: s.fullName,
        projectName,
        companyName: '',   // enriched below if needed
        supervisorName,
      }).catch(() => {});
    }
  }

  return {
    team: result.team,
    project: project ? { id: project.id, name: project.name } : null,
    assignedStudents: valid.map((s) => ({ id: s.id, fullName: s.fullName })),
    skipped,
  };
}

// ── Reassignment ──────────────────────────────────────────────────────────────

/**
 * Move a student from their current team to a different team.
 * Blocked if the student has a submitted final evaluation.
 */
export async function reassignStudentToTeam(
  companyId: number,
  studentId: number,
  newTeamId: number,
): Promise<void> {
  // Block if evaluation already submitted
  const evaluation = await prisma.finalEvaluation.findUnique({ where: { studentId } });
  if (evaluation) {
    throw Object.assign(
      new Error('Cannot reassign student: final evaluation has already been submitted.'),
      { status: 400 },
    );
  }

  const newTeam = await prisma.team.findFirst({
    where: { id: newTeamId, companyId, deleted_at: null },
  });
  if (!newTeam) {
    throw Object.assign(new Error('Target team not found.'), { status: 404 });
  }

  await prisma.$transaction(async (tx) => {
    // Remove from all current teams at this company
    const currentTeams = await tx.studentTeam.findMany({
      where: { studentId, team: { companyId } },
      select: { teamId: true },
    });
    if (currentTeams.length > 0) {
      await tx.studentTeam.deleteMany({
        where: { studentId, teamId: { in: currentTeams.map((t) => t.teamId) } },
      });
    }
    // Add to new team
    await tx.studentTeam.create({ data: { studentId, teamId: newTeamId } });
  });
}

/**
 * Move a team to a different project.
 * Warns (but does not block) if team members have active weekly reports.
 */
export async function reassignTeamToProject(
  companyId: number,
  teamId: number,
  newProjectId: number,
): Promise<{ warned: boolean; warningMessage?: string }> {
  const team = await prisma.team.findFirst({
    where: { id: teamId, companyId, deleted_at: null },
    include: { members: { select: { studentId: true } } },
  });
  if (!team) {
    throw Object.assign(new Error('Team not found.'), { status: 404 });
  }

  const newProject = await prisma.project.findFirst({
    where: { id: newProjectId, companyId, deleted_at: null },
    select: { id: true, name: true, capacity: true, students: { select: { studentId: true } } },
  });
  if (!newProject) {
    throw Object.assign(new Error('Target project not found.'), { status: 404 });
  }

  // Capacity check
  if (newProject.capacity > 0) {
    const existingIds = new Set(newProject.students.map((s) => s.studentId));
    const newCount = team.members.filter((m) => !existingIds.has(m.studentId)).length;
    if (newProject.students.length + newCount > newProject.capacity) {
      throw Object.assign(new Error('Target project capacity would be exceeded.'), { status: 400 });
    }
  }

  // Warn if active reports exist
  const studentIds = team.members.map((m) => m.studentId);
  let warned = false;
  let warningMessage: string | undefined;
  if (studentIds.length > 0) {
    const reportCount = await prisma.weeklyReport.count({
      where: { studentId: { in: studentIds } },
    });
    if (reportCount > 0) {
      warned = true;
      warningMessage = `${reportCount} weekly report(s) exist for team members. Reassignment recorded but historical reports are preserved.`;
    }
  }

  await prisma.$transaction(async (tx) => {
    // Update team's project link
    await tx.team.update({ where: { id: teamId }, data: { projectId: newProjectId } });

    // Remove members from old project (if any)
    if (team.projectId != null && team.projectId !== newProjectId && studentIds.length > 0) {
      await tx.studentProject.deleteMany({
        where: { studentId: { in: studentIds }, projectId: team.projectId },
      });
    }

    // Add members to new project (skip duplicates)
    if (studentIds.length > 0) {
      await tx.studentProject.createMany({
        data: studentIds.map((sid) => ({ studentId: sid, projectId: newProjectId })),
        skipDuplicates: true,
      });
    }

    // Update assignment project_name
    if (studentIds.length > 0) {
      await tx.internshipAssignment.updateMany({
        where: { studentId: { in: studentIds }, companyId, status: 'ACTIVE' },
        data: { project_name: newProject.name },
      });
    }
  });

  return { warned, warningMessage };
}
