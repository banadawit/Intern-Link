import cron from 'node-cron';
import prisma from '../config/db';
import { getTransporter } from './email.service';
import nodemailer from 'nodemailer';

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Returns tomorrow's date at midnight UTC (date-only, no time component). */
function getTomorrowDate(): Date {
    const d = new Date();
    d.setUTCDate(d.getUTCDate() + 1);
    d.setUTCHours(0, 0, 0, 0);
    return d;
}

/** Create an in-app notification for a user. */
async function createNotification(recipientId: number, message: string): Promise<void> {
    await prisma.notification.create({
        data: { recipientId, message },
    });
}

/** Send a plain email reminder. */
async function sendEmail(to: string, subject: string, message: string): Promise<void> {
    try {
        const transporter = await getTransporter();
        const from = process.env.SMTP_USER || 'noreply@internlink.com';
        const info = await transporter.sendMail({
            from: `"InternLink" <${from}>`,
            to,
            subject,
            html: `
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"><style>
              body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;background:#f8fafc;margin:0;padding:0;}
              .container{max-width:560px;margin:40px auto;padding:0 20px;}
              .card{background:#fff;border-radius:16px;box-shadow:0 4px 6px -1px rgba(0,0,0,.1);overflow:hidden;}
              .header{background:linear-gradient(135deg,#0d9488,#115e59);padding:28px 24px;text-align:center;}
              .logo{font-size:24px;font-weight:700;color:#fff;margin:0;}
              .content{padding:28px 24px;}
              .btn{display:inline-block;background:#0d9488;color:#fff!important;text-decoration:none;padding:11px 28px;border-radius:8px;font-weight:600;margin:20px 0;}
              .footer{background:#f1f5f9;padding:20px 24px;text-align:center;font-size:12px;color:#64748b;}
            </style></head>
            <body>
              <div class="container"><div class="card">
                <div class="header"><h1 class="logo">InternLink</h1></div>
                <div class="content">
                  <p style="color:#1e293b;font-size:15px;line-height:1.6;">${message.replace(/\n/g, '<br/>')}</p>
                  <div style="text-align:center;">
                    <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/student/plans" class="btn">Go to My Plans</a>
                  </div>
                </div>
                <div class="footer">&copy; ${new Date().getFullYear()} InternLink &mdash; Connecting Ethiopian Universities with Industry</div>
              </div></div>
            </body></html>`,
        });
        const preview = nodemailer.getTestMessageUrl(info);
        if (preview) console.info(`ℹ️  Email preview: ${preview}`);
    } catch (err: any) {
        console.error('❌ Reminder email failed:', err?.message);
    }
}

// ─── Active students helper ──────────────────────────────────────────────────

/** Returns all PLACED students with their user email. */
async function getActiveStudents() {
    return prisma.student.findMany({
        where: {
            internship_status: 'PLACED',
            hod_approval_status: 'APPROVED',
        },
        include: {
            user: { select: { id: true, email: true, full_name: true } },
        },
    });
}

// ─── Daily Reminder — weekdays at 16:00 ─────────────────────────────────────
// Checks if the student has submitted a daily check-in for TOMORROW.
// If not → remind them to prepare.

export function scheduleDailyReminder(): void {
    cron.schedule('0 16 * * 1-5', async () => {
        console.log('⏰ [Daily Reminder] Running at 4 PM weekday check…');
        const tomorrow = getTomorrowDate();

        const students = await getActiveStudents();

        for (const student of students) {
            // Check if a day submission exists for tomorrow under any of their plans
            const existing = await prisma.weeklyPlanDaySubmission.findFirst({
                where: {
                    weeklyPlan: { studentId: student.id },
                    workDate: tomorrow,
                },
            });

            if (existing) continue; // Already submitted — no spam

            const dayName = tomorrow.toLocaleDateString('en-US', { weekday: 'long' });
            const dateStr = tomorrow.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

            const message =
                `Hi ${student.user.full_name},\n\n` +
                `Don't forget to prepare your daily plan for tomorrow (${dayName}, ${dateStr}).\n\n` +
                `Staying consistent with your daily submissions helps your supervisor track your progress.`;

            await Promise.all([
                createNotification(student.user.id, `📋 Reminder: Submit your plan for tomorrow (${dayName}, ${dateStr}).`),
                sendEmail(student.user.email, `[InternLink] Prepare your plan for tomorrow — ${dateStr}`, message),
            ]);

            console.log(`  ✅ Reminded student ${student.user.email} for ${dateStr}`);
        }

        console.log(`⏰ [Daily Reminder] Done. Checked ${students.length} students.`);
    }, { timezone: 'Africa/Addis_Ababa' });

    console.log('✅ Daily reminder cron scheduled (Mon–Fri 4:00 PM EAT)');
}

// ─── Weekly Reminder — every Sunday at 18:00 ────────────────────────────────
// Sends a planning reminder to ALL active students.

export function scheduleWeeklyReminder(): void {
    cron.schedule('0 18 * * 0', async () => {
        console.log('⏰ [Weekly Reminder] Running Sunday 6 PM check…');

        const students = await getActiveStudents();

        for (const student of students) {
            const message =
                `Hi ${student.user.full_name},\n\n` +
                `A new week is starting soon! Take a few minutes to plan your week ahead and stay consistent with your internship progress.\n\n` +
                `Submit your weekly plan on InternLink so your supervisor can review and guide you.`;

            await Promise.all([
                createNotification(student.user.id, '📅 Weekly reminder: Plan your week ahead and stay consistent!'),
                sendEmail(student.user.email, '[InternLink] Plan your week ahead — weekly reminder', message),
            ]);
        }

        console.log(`⏰ [Weekly Reminder] Done. Notified ${students.length} students.`);
    }, { timezone: 'Africa/Addis_Ababa' });

    console.log('✅ Weekly reminder cron scheduled (Sunday 6:00 PM EAT)');
}

// ─── Bootstrap ───────────────────────────────────────────────────────────────

export function startReminderScheduler(): void {
    scheduleDailyReminder();
    scheduleWeeklyReminder();
    scheduleProjectCleanup();
}

// ─── Hard-delete projects after 24h in trash ────────────────────────────────
export function scheduleProjectCleanup(): void {
    // Run every hour
    cron.schedule('0 * * * *', async () => {
        const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
        try {
            // Use $executeRaw to avoid stale Prisma client type issues
            await prisma.$executeRaw`DELETE FROM "Project" WHERE "deleted_at" IS NOT NULL AND "deleted_at" <= ${cutoff}`;
            console.log('🗑️  Project cleanup ran.');
        } catch (e: any) {
            console.error('Project cleanup error:', e?.message);
        }
    });
    console.log('✅ Project cleanup cron scheduled (every hour)');
}
