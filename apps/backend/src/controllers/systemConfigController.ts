import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import { testEmailConfig } from '../services/email.service';

// Default config values
const DEFAULTS: Record<string, string> = {
  // Registration toggles
  registration_student_open: 'true',
  registration_coordinator_open: 'true',
  registration_supervisor_open: 'true',
  registration_hod_open: 'true',
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

/** Merge DB rows with defaults so all keys are always present */
async function getFullConfig(): Promise<Record<string, string>> {
  const rows = await prisma.systemConfig.findMany();
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
    res.status(500).json({ error: e.message });
  }
};

export const updateConfig = async (req: AuthRequest, res: Response) => {
  try {
    const updates = req.body as Record<string, string>;
    if (!updates || typeof updates !== 'object') {
      return res.status(400).json({ error: 'Body must be a key-value object.' });
    }

    // Upsert each key
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
    res.json({ success: true, data: config });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
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

    res.status(201).json({ success: true, data: post });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
};

/**
 * Middleware-style helper: check if registration is open for a given role.
 * Used in authController to gate registrations.
 */
export async function isRegistrationOpen(role: string): Promise<boolean> {
  const key = `registration_${role.toLowerCase()}_open`;
  const row = await prisma.systemConfig.findUnique({ where: { key } });
  const value = row?.value ?? DEFAULTS[key] ?? 'true';
  return value === 'true';
}

export async function isMaintenanceMode(): Promise<{ active: boolean; message: string }> {
  const rows = await prisma.systemConfig.findMany({
    where: { key: { in: ['maintenance_mode', 'maintenance_message'] } },
  });
  const map = Object.fromEntries(rows.map((r) => [r.key, r.value]));
  return {
    active: (map['maintenance_mode'] ?? 'false') === 'true',
    message: map['maintenance_message'] ?? DEFAULTS['maintenance_message'],
  };
}
