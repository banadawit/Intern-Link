import prisma from '../config/db';
import { sendAdminNewVerificationProposalEmail } from '../services/email.service';

/**
 * Resolves who receives “new verification proposal” alerts.
 * Order: ADMIN_NOTIFICATION_EMAILS (comma/semicolon), ADMIN_NOTIFICATION_EMAIL, all ADMIN users in DB, then SMTP_USER.
 */
export async function getAdminNotificationEmails(): Promise<string[]> {
    const raw = process.env.ADMIN_NOTIFICATION_EMAILS;
    if (raw) {
        const list = raw
            .split(/[,;]/)
            .map((e) => e.trim())
            .filter(Boolean);
        if (list.length) return list;
    }
    const single = process.env.ADMIN_NOTIFICATION_EMAIL?.trim();
    if (single) return [single];

    const admins = await prisma.user.findMany({
        where: { role: 'ADMIN' },
        select: { email: true },
    });
    if (admins.length) return admins.map((a) => a.email);

    const fallback = process.env.SMTP_USER?.trim();
    return fallback ? [fallback] : [];
}

export async function notifyAdminsNewVerificationProposal(params: {
    organizationName: string;
    institutionType: 'University' | 'Company';
    organizationId: number;
    submitterEmail?: string;
}): Promise<void> {
    const emails = await getAdminNotificationEmails();
    if (!emails.length) {
        console.warn('⚠️ No admin notification email configured — skipping new proposal email.');
        return;
    }
    await sendAdminNewVerificationProposalEmail(emails, params);
}
