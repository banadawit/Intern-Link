/**
 * Admin Onboarding Controller
 *
 * Handles:
 * 1. Manual creation of Universities (with optional Coordinator contact user)
 * 2. Manual creation of Companies (with optional Supervisor contact user)
 * 3. Per-university student registration toggle
 * 4. Secure password setup link (replaces default passwords)
 */

import { Response } from 'express';
import { AuthRequest } from '../middlewares/authMiddleware';
import prisma from '../config/db';
import crypto from 'crypto';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { getTransporter } from '../services/email.service';

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Generate a secure random setup token (hex, 48 chars) */
function generateSetupToken(): string {
    return crypto.randomBytes(24).toString('hex');
}

/** Send a password setup email to a newly created user */
async function sendPasswordSetupEmail(params: {
    to: string;
    name: string;
    role: string;
    orgName: string;
    setupToken: string;
}): Promise<void> {
    const frontendUrl = (process.env.FRONTEND_URL || 'http://localhost:3000').replace(/\/$/, '');
    const setupUrl = `${frontendUrl}/reset-password?token=${params.setupToken}`;
    const transporter = await getTransporter();
    const from = process.env.SMTP_USER || 'noreply@internlink.com';

    const html = `
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f8fafc; margin: 0; padding: 0; }
      .container { max-width: 560px; margin: 40px auto; background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
      .header { background: linear-gradient(135deg, #0C8B83, #4A00E0); padding: 36px 32px; text-align: center; }
      .header h1 { color: #fff; margin: 0; font-size: 24px; font-weight: 900; }
      .header p { color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 14px; }
      .body { padding: 32px; }
      .body p { color: #475569; line-height: 1.6; font-size: 15px; }
      .btn { display: inline-block; background: linear-gradient(135deg, #0C8B83, #4A00E0); color: #fff !important; text-decoration: none; padding: 14px 32px; border-radius: 10px; font-weight: 700; font-size: 15px; margin: 20px 0; }
      .info-box { background: #f1f5f9; border-radius: 10px; padding: 16px 20px; margin: 20px 0; }
      .info-box p { margin: 4px 0; font-size: 13px; color: #64748b; }
      .info-box strong { color: #1e293b; }
      .footer { background: #f8fafc; padding: 20px 32px; text-align: center; font-size: 12px; color: #94a3b8; }
      .expire { color: #f59e0b; font-size: 13px; font-weight: 600; }
    </style></head><body>
    <div class="container">
      <div class="header">
        <h1>Welcome to InternLink</h1>
        <p>You have been added to the platform</p>
      </div>
      <div class="body">
        <p>Hi <strong>${params.name}</strong>,</p>
        <p>An administrator has created an account for you on <strong>InternLink</strong> as a <strong>${params.role}</strong> for <strong>${params.orgName}</strong>.</p>
        <p>To get started, please set your password by clicking the button below:</p>
        <div style="text-align:center">
          <a href="${setupUrl}" class="btn">Set My Password →</a>
        </div>
        <div class="info-box">
          <p><strong>Your account details:</strong></p>
          <p>Role: <strong>${params.role}</strong></p>
          <p>Organization: <strong>${params.orgName}</strong></p>
        </div>
        <p class="expire">⏰ This link expires in 48 hours. If you did not expect this email, please ignore it.</p>
      </div>
      <div class="footer">
        <p>&copy; ${new Date().getFullYear()} InternLink — Connecting Ethiopian Universities with Industry Leaders</p>
      </div>
    </div>
    </body></html>`;

    const info = await transporter.sendMail({
        from: `"InternLink" <${from}>`,
        to: params.to,
        subject: `Welcome to InternLink — Set your password`,
        html,
    });

    const preview = require('nodemailer').getTestMessageUrl(info);
    if (preview) console.info(`ℹ️  Setup email preview: ${preview}`);
    console.log(`✅ Password setup email sent to ${params.to}`);
}

// ── 1. Create University ──────────────────────────────────────────────────────

/**
 * POST /admin/universities
 * Admin manually creates a university (auto-approved) and optionally
 * creates a coordinator contact user who receives a password setup link.
 *
 * Body: {
 *   name: string
 *   official_email: string
 *   address?: string
 *   contactUser?: { name: string; email: string }
 * }
 */
export const adminCreateUniversity = async (req: AuthRequest, res: Response) => {
    try {
        const { name, official_email, address, contactUser } = req.body as {
            name?: string;
            official_email?: string;
            address?: string;
            contactUser?: { name?: string; email?: string };
        };

        if (!name?.trim() || !official_email?.trim()) {
            return sendError(res, 'name and official_email are required.', 400);
        }

        // Check for duplicate
        const existing = await prisma.university.findUnique({ where: { official_email: official_email.trim() } });
        if (existing) return sendError(res, 'A university with this email already exists.', 400);

        // Create university (auto-approved since admin is creating it)
        const university = await prisma.university.create({
            data: {
                name: name.trim(),
                official_email: official_email.trim(),
                address: address?.trim() ?? null,
                approval_status: 'APPROVED',
            },
        });

        let createdUser: { id: number; email: string; full_name: string } | null = null;
        let setupToken: string | null = null;

        // Optionally create coordinator contact user
        if (contactUser?.name?.trim() && contactUser?.email?.trim()) {
            const emailLower = contactUser.email.trim().toLowerCase();
            const emailExists = await prisma.user.findUnique({ where: { email: emailLower } });
            if (emailExists) {
                return sendError(res, `User with email ${emailLower} already exists.`, 400);
            }

            // Generate setup token (stored as reset_password_token, expires in 48h)
            setupToken = generateSetupToken();
            const tokenExpiry = new Date(Date.now() + 48 * 60 * 60 * 1000);

            // Create user with a random unusable password (they must use setup link)
            const unusableHash = await require('bcryptjs').hash(crypto.randomBytes(32).toString('hex'), 10);

            const user = await prisma.user.create({
                data: {
                    full_name: contactUser.name.trim(),
                    email: emailLower,
                    password_hash: unusableHash,
                    role: 'COORDINATOR',
                    verification_status: 'APPROVED',
                    institution_access_approval: 'APPROVED',
                    must_change_password: true,
                    reset_password_token: setupToken,
                    reset_password_expires: tokenExpiry,
                    coordinatorProfile: {
                        create: {
                            universityId: university.id,
                            phone_number: null,
                        },
                    },
                },
                select: { id: true, email: true, full_name: true },
            });

            createdUser = user;

            // Send setup email (fire-and-forget)
            sendPasswordSetupEmail({
                to: emailLower,
                name: contactUser.name.trim(),
                role: 'Coordinator',
                orgName: university.name,
                setupToken,
            }).catch((e) => console.error('Setup email error:', e?.message));
        }

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'ADMIN_CREATE_UNIVERSITY',
                targetId: university.id,
                details: `Created university "${university.name}"${createdUser ? ` with coordinator ${createdUser.email}` : ''}`,
            },
        });

        return sendSuccess(res, {
            university,
            coordinator: createdUser,
            setupLinkSent: !!createdUser,
        }, `University "${university.name}" created successfully.${createdUser ? ' Setup email sent to coordinator.' : ''}`, 201);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 2. Create Company ─────────────────────────────────────────────────────────

/**
 * POST /admin/companies
 * Admin manually creates a company (auto-approved) and optionally
 * creates a supervisor contact user who receives a password setup link.
 *
 * Body: {
 *   name: string
 *   official_email: string
 *   address?: string
 *   contactUser?: { name: string; email: string }
 * }
 */
export const adminCreateCompany = async (req: AuthRequest, res: Response) => {
    try {
        const { name, official_email, address, contactUser } = req.body as {
            name?: string;
            official_email?: string;
            address?: string;
            contactUser?: { name?: string; email?: string };
        };

        if (!name?.trim() || !official_email?.trim()) {
            return sendError(res, 'name and official_email are required.', 400);
        }

        const existing = await prisma.company.findUnique({ where: { official_email: official_email.trim() } });
        if (existing) return sendError(res, 'A company with this email already exists.', 400);

        const company = await prisma.company.create({
            data: {
                name: name.trim(),
                official_email: official_email.trim(),
                address: address?.trim() ?? null,
                approval_status: 'APPROVED',
            },
        });

        let createdUser: { id: number; email: string; full_name: string } | null = null;

        if (contactUser?.name?.trim() && contactUser?.email?.trim()) {
            const emailLower = contactUser.email.trim().toLowerCase();
            const emailExists = await prisma.user.findUnique({ where: { email: emailLower } });
            if (emailExists) return sendError(res, `User with email ${emailLower} already exists.`, 400);

            const setupToken = generateSetupToken();
            const tokenExpiry = new Date(Date.now() + 48 * 60 * 60 * 1000);
            const unusableHash = await require('bcryptjs').hash(crypto.randomBytes(32).toString('hex'), 10);

            const user = await prisma.user.create({
                data: {
                    full_name: contactUser.name.trim(),
                    email: emailLower,
                    password_hash: unusableHash,
                    role: 'SUPERVISOR',
                    verification_status: 'APPROVED',
                    institution_access_approval: 'APPROVED',
                    must_change_password: true,
                    reset_password_token: setupToken,
                    reset_password_expires: tokenExpiry,
                    supervisorProfile: {
                        create: { companyId: company.id },
                    },
                },
                select: { id: true, email: true, full_name: true },
            });

            createdUser = user;

            sendPasswordSetupEmail({
                to: emailLower,
                name: contactUser.name.trim(),
                role: 'Supervisor',
                orgName: company.name,
                setupToken,
            }).catch((e) => console.error('Setup email error:', e?.message));
        }

        await prisma.auditLog.create({
            data: {
                adminId: req.user!.userId,
                action: 'ADMIN_CREATE_COMPANY',
                targetId: company.id,
                details: `Created company "${company.name}"${createdUser ? ` with supervisor ${createdUser.email}` : ''}`,
            },
        });

        return sendSuccess(res, {
            company,
            supervisor: createdUser,
            setupLinkSent: !!createdUser,
        }, `Company "${company.name}" created successfully.${createdUser ? ' Setup email sent to supervisor.' : ''}`, 201);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 3. Per-university registration toggle ─────────────────────────────────────

/**
 * PATCH /admin/universities/:id/config
 * Set per-university student registration override.
 * Body: { studentRegistrationEnabled: true | false | null }
 * null = inherit global setting
 */
export const updateUniversityConfig = async (req: AuthRequest, res: Response) => {
    try {
        const id = parseInt(String(req.params.id), 10);
        if (Number.isNaN(id)) return sendError(res, 'Invalid university id.', 400);

        const { studentRegistrationEnabled } = req.body as { studentRegistrationEnabled?: boolean | null };
        if (studentRegistrationEnabled !== undefined && studentRegistrationEnabled !== null && typeof studentRegistrationEnabled !== 'boolean') {
            return sendError(res, 'studentRegistrationEnabled must be true, false, or null.', 400);
        }

        const university = await prisma.university.findUnique({ where: { id } });
        if (!university) return sendError(res, 'University not found.', 404);

        const config = await prisma.universityConfig.upsert({
            where: { universityId: id },
            update: { studentRegistrationEnabled: studentRegistrationEnabled ?? null },
            create: { universityId: id, studentRegistrationEnabled: studentRegistrationEnabled ?? null },
        });

        const statusLabel = studentRegistrationEnabled === null
            ? 'inheriting global setting'
            : studentRegistrationEnabled
                ? 'enabled'
                : 'disabled';

        return sendSuccess(res, config, `Student registration for "${university.name}" is now ${statusLabel}.`);
    } catch (e: any) {
        return sendError(res, e.message);
    }
};

// ── 4. Send setup link to existing user ──────────────────────────────────────

/**
 * POST /auth/send-setup-link
 * Admin sends (or resends) a password setup link to a user.
 * Body: { email: string }
 */
export const sendSetupLink = async (req: AuthRequest, res: Response) => {
    try {
        const { email } = req.body as { email?: string };
        if (!email?.trim()) return sendError(res, 'email is required.', 400);

        const user = await prisma.user.findUnique({ where: { email: email.trim().toLowerCase() } });
        if (!user) return sendError(res, 'User not found.', 404);

        const setupToken = generateSetupToken();
        const tokenExpiry = new Date(Date.now() + 48 * 60 * 60 * 1000);

        await prisma.user.update({
            where: { id: user.id },
            data: {
                reset_password_token: setupToken,
                reset_password_expires: tokenExpiry,
                must_change_password: true,
            },
        });

        // Determine org name for email
        let orgName = 'InternLink';
        if (user.role === 'COORDINATOR') {
            const coord = await prisma.coordinator.findUnique({ where: { userId: user.id }, include: { university: { select: { name: true } } } });
            orgName = coord?.university?.name ?? orgName;
        } else if (user.role === 'SUPERVISOR') {
            const sup = await prisma.supervisor.findUnique({ where: { userId: user.id }, include: { company: { select: { name: true } } } });
            orgName = sup?.company?.name ?? orgName;
        }

        await sendPasswordSetupEmail({
            to: user.email,
            name: user.full_name,
            role: user.role,
            orgName,
            setupToken,
        });

        return sendSuccess(res, { email: user.email }, 'Password setup link sent successfully.');
    } catch (e: any) {
        return sendError(res, e.message);
    }
};
