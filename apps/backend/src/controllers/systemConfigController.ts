import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { Prisma } from '@prisma/client';
import { testEmailConfig } from '../services/email.service';
import { notifyAllAdmins, NotificationType } from '../services/notification.service';

// Default config values
const DEFAULTS: Record<string, string> = {
  // Registration toggles
  registration_student_open: 'true',
  registration_coordinator_open: 'true',
  registration_supervisor_open: 'true',
  registration_hod_open: 'true',
  registration_university_open: 'true',
  registration_company_open: 'true',
  // Internship rules
  internship_min_weeks: '4',
  internship_max_weeks: '24',
  weekly_plan_deadline_day: 'Sunday',
  max_weekly_plans: '24',
  // Platform
  platform_name: 'InternLink',
  support_email: 'support@internlink.com',
  maintenance_mode: 'false',
  maintenance_message: 'The platform is currently under maintenance. Please check back soon.',
};

function isMissingSystemConfigTableError(error: unknown): boolean {
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2021') {
    return true;
  }
  const msg = error instanceof Error ? error.message : String(error ?? '');
  return msg.includes('SystemConfig') && msg.includes('does not exist');
}

/** Merge DB rows with defaults so all keys are always present */
async function getFullConfig(): Promise<Record<string, string>> {
  let rows: Array<{ key: string; value: string }> = [];
  try {
    rows = await prisma.systemConfig.findMany();
  } catch (error) {
    if (!isMissingSystemConfigTableError(error)) {
      throw error;
    }
    // Older databases may not yet have SystemConfig; safely fall back to defaults.
    return { ...DEFAULTS };
  }
  const map: Record<string, string> = { ...DEFAULTS };
  for (const row of rows) {
    map[row.key] = row.value;
  }
  return map;
}

export const getConfig = async (req: AuthRequest, res: Response) => {
  try {
    const config = await getFullConfig();
    res.json({ success: true, data: config });
  } catch (e: any) {
    res.status(500).json({ success: false, error: e.message });
  }
};

export const updateConfig = async (req: AuthRequest, res: Response) => {
  try {
    const updates = req.body as Record<string, string>;
    if (!updates || typeof updates !== 'object') {
      return res.status(400).json({ success: false, error: 'Body must be a key-value object.' });
    }

    await Promise.all(
      Object.entries(updates).map(([key, value]) =>
        prisma.systemConfig.upsert({
          where: { key },
          update: { value: String(value) },
          create: { key, value: String(value) },
        })
      )
    );

    const config = await getFullConfig();
    res.json({ success: true, data: config, message: 'Configuration updated.' });
  } catch (e: any) {
    res.status(500).json({ success: false, error: e.message });
  }
};

export const testSmtp = async (req: AuthRequest, res: Response) => {
  try {
    const ok = await testEmailConfig();
    res.json({ success: ok, message: ok ? 'SMTP connection verified.' : 'SMTP connection failed.' });
  } catch (e: any) {
    res.status(500).json({ success: false, message: e.message });
  }
};

export const exportAuditLogCsv = async (req: AuthRequest, res: Response) => {
  try {
    const logs = await prisma.auditLog.findMany({
      orderBy: { timestamp: 'desc' },
      take: 5000,
    });

    const adminIds = [...new Set(logs.map((l) => l.adminId))];
    const admins = await prisma.user.findMany({
      where: { id: { in: adminIds } },
      select: { id: true, full_name: true, email: true },
    });
    const adminMap = new Map(admins.map((a) => [a.id, a]));

    const header = 'ID,Action,Target ID,Details,Admin Name,Admin Email,Timestamp\n';
    const rows = logs.map((l) => {
      const admin = adminMap.get(l.adminId);
      const details = (l.details ?? '').replace(/"/g, '""');
      return `${l.id},"${l.action}",${l.targetId},"${details}","${admin?.full_name ?? ''}","${admin?.email ?? ''}","${l.timestamp.toISOString()}"`;
    });

    const csv = header + rows.join('\n');
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="audit-log-${Date.now()}.csv"`);
    res.send(csv);
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
};

/** Broadcast announcement to all users */
export const broadcastAnnouncement = async (req: AuthRequest, res: Response) => {
  try {
    const { title, content } = req.body as { title?: string; content?: string };
    if (!title?.trim() || !content?.trim()) {
      return res.status(400).json({ error: 'Title and content are required.' });
    }

    // Create as a CommonPost (visible in common feed)
    const post = await prisma.commonPost.create({
      data: {
        authorId: req.user!.userId,
        postType: 'ANNOUNCEMENT',
        visibility: 'PUBLIC',
        title: title.trim(),
        content: content.trim(),
        isPinned: true, // Pin broadcast announcements
      },
    });

    // Send in-app notification to all users with link to common feed
    const users = await prisma.user.findMany({ select: { id: true } });
    await prisma.notification.createMany({
      data: users.map((u) => ({
        recipientId: u.id,
        message: `📢 ${title.trim()}: ${content.trim().slice(0, 100)}${content.trim().length > 100 ? '…' : ''}`,
        is_read: false,
      })),
    });

    await notifyAllAdmins(
        `System-wide broadcast sent successfully: "${title.trim()}"`,
        NotificationType.SYSTEM_ALERT
    );

    res.status(201).json({ success: true, data: post });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
};

/**
 * Middleware-style helper: check if registration is open for a given role.
 * For STUDENT role, also checks per-university override if universityId is provided.
 * Used in authController to gate registrations.
 */
export async function isRegistrationOpen(role: string, universityId?: number): Promise<{ allowed: boolean; reason?: string }> {
  const key = `registration_${role.toLowerCase()}_open`;
  let row: { value: string } | null = null;
  try {
    row = await prisma.systemConfig.findUnique({ where: { key } });
  } catch (error) {
    if (!isMissingSystemConfigTableError(error)) throw error;
  }
  const globalValue = row?.value ?? DEFAULTS[key] ?? 'true';
  const globalAllowed = globalValue === 'true';

  // For students, check per-university override
  if (role.toUpperCase() === 'STUDENT' && universityId) {
    try {
      const uniConfig = await prisma.universityConfig.findUnique({ where: { universityId } });
      if (uniConfig && uniConfig.studentRegistrationEnabled !== null) {
        // University has an explicit override
        if (!uniConfig.studentRegistrationEnabled) {
          return { allowed: false, reason: 'Student registration is currently disabled for your university.' };
        }
        return { allowed: true };
      }
    } catch (_) {
      // UniversityConfig table may not exist yet — fall through to global
    }
  }

  if (!globalAllowed) {
    return { allowed: false, reason: `Registration for ${role} accounts is currently closed.` };
  }
  return { allowed: true };
}

export async function isMaintenanceMode(): Promise<{ active: boolean; message: string }> {
  let rows: Array<{ key: string; value: string }> = [];
  try {
    rows = await prisma.systemConfig.findMany({
      where: { key: { in: ['maintenance_mode', 'maintenance_message'] } },
    });
  } catch (error) {
    if (!isMissingSystemConfigTableError(error)) {
      throw error;
    }
    return {
      active: false,
      message: DEFAULTS['maintenance_message'],
    };
  }
  const map = Object.fromEntries(rows.map((r) => [r.key, r.value]));
  return {
    active: (map['maintenance_mode'] ?? 'false') === 'true',
    message: map['maintenance_message'] ?? DEFAULTS['maintenance_message'],
  };
}
