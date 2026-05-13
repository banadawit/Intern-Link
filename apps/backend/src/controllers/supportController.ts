import { Request, Response } from 'express';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { getTransporter } from '../services/email.service';
import prisma from '../config/db';

export const submitSupportRequest = async (req: Request, res: Response) => {
    try {
        const { name, email, subject, message } = req.body;

        if (!name?.trim() || !email?.trim() || !subject?.trim() || !message?.trim()) {
            return sendError(res, 'All fields are required.', 400);
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email.trim())) {
            return sendError(res, 'Please provide a valid email address.', 400);
        }

        const safeName = name.trim().slice(0, 100);
        const safeEmail = email.trim().slice(0, 200);
        const safeSubject = subject.trim().slice(0, 200);
        const safeMessage = message.trim().slice(0, 2000);

        // Get all admin emails
        const admins = await prisma.user.findMany({
            where: { role: 'ADMIN' },
            select: { id: true, email: true },
        });

        if (admins.length === 0) {
            return sendError(res, 'Support is currently unavailable. Please try again later.', 503);
        }

        const transporter = await getTransporter();
        const fromAddr = process.env.SMTP_USER || 'noreply@internlink.com';
        const submittedAt = new Date().toLocaleString('en-US', { dateStyle: 'medium', timeStyle: 'short' });

        const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #1e293b; background: #f8fafc; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .card { background: #fff; border-radius: 16px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; }
    .header { background: linear-gradient(135deg, #0d9488 0%, #115e59 100%); padding: 28px 24px; text-align: center; }
    .logo { font-size: 24px; font-weight: bold; color: white; margin: 0; }
    .badge { display: inline-block; background: rgba(255,255,255,0.2); color: white; font-size: 12px; font-weight: 600; padding: 4px 12px; border-radius: 20px; margin-top: 8px; }
    .content { padding: 28px 24px; }
    .field { margin-bottom: 16px; }
    .label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; color: #64748b; margin-bottom: 4px; }
    .value { font-size: 14px; color: #1e293b; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 14px; }
    .message-box { font-size: 14px; color: #1e293b; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; white-space: pre-wrap; line-height: 1.7; }
    .reply-note { background: #eff6ff; border-left: 4px solid #3b82f6; padding: 12px 16px; border-radius: 8px; font-size: 13px; color: #1e40af; margin-top: 20px; }
    .footer { background: #f1f5f9; padding: 20px 24px; text-align: center; font-size: 12px; color: #64748b; }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="header">
        <h1 class="logo">InternLink</h1>
        <div class="badge">Support Request</div>
      </div>
      <div class="content">
        <h2 style="margin-top:0;font-size:18px;">New support request received</h2>
        <div class="field">
          <div class="label">From</div>
          <div class="value">${safeName} &lt;${safeEmail}&gt;</div>
        </div>
        <div class="field">
          <div class="label">Subject</div>
          <div class="value">${safeSubject}</div>
        </div>
        <div class="field">
          <div class="label">Submitted</div>
          <div class="value">${submittedAt}</div>
        </div>
        <div class="field">
          <div class="label">Message</div>
          <div class="message-box">${safeMessage}</div>
        </div>
        <div class="reply-note">
          💡 Reply directly to this email to respond to <strong>${safeName}</strong> at <strong>${safeEmail}</strong>.
        </div>
      </div>
      <div class="footer">
        <p>&copy; ${new Date().getFullYear()} InternLink — Admin Support Inbox</p>
      </div>
    </div>
  </div>
</body>
</html>`;

        // Send to all admins
        for (const admin of admins) {
            await transporter.sendMail({
                from: `"InternLink Support" <${fromAddr}>`,
                to: admin.email,
                replyTo: safeEmail,
                subject: `[Support] ${safeSubject}`,
                html,
            });

            // In-app notification
            await prisma.notification.create({
                data: {
                    recipientId: admin.id,
                    message: `📩 Support request from ${safeName} (${safeEmail}): "${safeSubject}"`,
                    is_read: false,
                },
            });
        }

        return sendSuccess(res, null, 'Your message has been sent. We will get back to you shortly.');
    } catch (error: any) {
        console.error('[Support] Error:', error.message);
        return sendError(res, 'Failed to send your message. Please try again.', 500);
    }
};
