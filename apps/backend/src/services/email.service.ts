import nodemailer from 'nodemailer';
import { Transporter } from 'nodemailer';

// Email configuration interface
interface EmailConfig {
  host: string;
  port: number;
  secure: boolean;
  auth: {
    user: string;
    pass: string;
  };
}

// Email templates
interface VerificationEmailParams {
  email: string;
  token: string;
  frontendUrl: string;
}

interface PasswordResetEmailParams {
  email: string;
  token: string;
  frontendUrl: string;
}

// Email transporter instance (lazy singleton)
let transporter: Transporter | null = null;

/**
 * Initialize email transporter
 */
const initTransporter = async (): Promise<Transporter> => {
  const smtpHost = process.env.SMTP_HOST || 'smtp.gmail.com';
  const smtpPort = parseInt(process.env.SMTP_PORT || '587');
  const smtpSecure = process.env.SMTP_SECURE === 'true';
  const smtpUser = (process.env.SMTP_USER || '').trim();
  const smtpPass = (process.env.SMTP_PASS || '').trim();

  if (!smtpUser || !smtpPass) {
    console.warn('⚠️ SMTP credentials not configured. Falling back to Ethereal test account for development.');

    const testAccount = await nodemailer.createTestAccount();
    console.info(`ℹ️ Ethereal test account created: ${testAccount.user}`);

    return nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: {
        user: testAccount.user,
        pass: testAccount.pass,
      },
    });
  }

  return nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpSecure,
    auth: {
      user: smtpUser,
      pass: smtpPass,
    },
  });
};

/**
 * Get transporter instance
 */
const getTransporter = async (): Promise<Transporter> => {
  if (!transporter) {
    transporter = await initTransporter();
  }
  return transporter;
};

/**
 * Send verification email
 */
export const sendVerificationEmail = async (email: string, token: string, role?: string): Promise<void> => {
  try {
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const roleParam = role ? `&role=${role.toLowerCase()}` : '';
    const verificationUrl = `${frontendUrl}/verify-email?token=${token}${roleParam}`;
    
    const transporter = await getTransporter();
    
    const mailOptions = {
      from: `"InternLink" <${process.env.SMTP_USER || 'noreply@internlink.com'}>`,
      to: email,
      subject: 'Verify Your Email - InternLink',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Verify Your Email</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              line-height: 1.6;
              color: #1e293b;
              background-color: #f8fafc;
              margin: 0;
              padding: 0;
            }
            .container {
              max-width: 600px;
              margin: 0 auto;
              padding: 40px 20px;
            }
            .card {
              background-color: #ffffff;
              border-radius: 16px;
              box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
              overflow: hidden;
            }
            .header {
              background: linear-gradient(135deg, #0d9488 0%, #115e59 100%);
              padding: 32px 24px;
              text-align: center;
            }
            .logo {
              font-size: 28px;
              font-weight: bold;
              color: white;
              margin: 0;
            }
            .content {
              padding: 32px 24px;
            }
            .button {
              display: inline-block;
              background-color: #0d9488;
              color: white;
              text-decoration: none;
              padding: 12px 32px;
              border-radius: 8px;
              font-weight: 600;
              margin: 24px 0;
              transition: background-color 0.3s;
            }
            .button:hover {
              background-color: #0f766e;
            }
            .footer {
              background-color: #f1f5f9;
              padding: 24px;
              text-align: center;
              font-size: 12px;
              color: #64748b;
            }
            .text-muted {
              color: #64748b;
              font-size: 14px;
            }
            hr {
              border: none;
              border-top: 1px solid #e2e8f0;
              margin: 24px 0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="card">
              <div class="header">
                <h1 class="logo">InternLink</h1>
                <p style="color: rgba(255,255,255,0.9); margin-top: 8px;">Smart Internship Management System</p>
              </div>
              <div class="content">
                <h2 style="margin-top: 0;">Verify Your Email Address</h2>
                <p>Thank you for registering with InternLink! Please verify your email address to complete your registration and start using the platform.</p>
                
                <div style="text-align: center;">
                  <a href="${verificationUrl}" class="button">Verify Email Address</a>
                </div>
                
                <p class="text-muted">Or copy and paste this link into your browser:</p>
                <p style="background-color: #f1f5f9; padding: 12px; border-radius: 8px; word-break: break-all; font-size: 12px;">
                  ${verificationUrl}
                </p>
                
                <hr />
                
                <p class="text-muted" style="font-size: 12px;">
                  This verification link will expire in <strong>24 hours</strong>.<br>
                  If you did not create an account with InternLink, you can safely ignore this email.
                </p>
              </div>
              <div class="footer">
                <p>&copy; ${new Date().getFullYear()} InternLink. All rights reserved.</p>
                <p>Connecting Ethiopian Universities with Industry Leaders</p>
              </div>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    // Send email
    const info = await transporter.sendMail(mailOptions);

    const testUrl = nodemailer.getTestMessageUrl(info);
    if (testUrl) {
      console.info(`ℹ️ Preview verification email at: ${testUrl}`);
    }

    console.log(`✅ Verification email sent to ${email}: ${info.messageId}`);
    return;
  } catch (error: any) {
    console.error('❌ Failed to send verification email:', error);
    throw new Error(`Failed to send verification email: ${error?.message || 'unknown error'}`);
  }
};

/**
 * Send password reset email
 */
export const sendPasswordResetEmail = async (email: string, token: string): Promise<void> => {
  try {
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const resetUrl = `${frontendUrl}/reset-password/${token}`;
    
    const transporter = await getTransporter();
    
    const mailOptions = {
      from: `"InternLink" <${process.env.SMTP_USER || 'noreply@internlink.com'}>`,
      to: email,
      subject: 'Reset Your Password - InternLink',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Reset Your Password</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              line-height: 1.6;
              color: #1e293b;
              background-color: #f8fafc;
              margin: 0;
              padding: 0;
            }
            .container {
              max-width: 600px;
              margin: 0 auto;
              padding: 40px 20px;
            }
            .card {
              background-color: #ffffff;
              border-radius: 16px;
              box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
              overflow: hidden;
            }
            .header {
              background: linear-gradient(135deg, #0d9488 0%, #115e59 100%);
              padding: 32px 24px;
              text-align: center;
            }
            .logo {
              font-size: 28px;
              font-weight: bold;
              color: white;
              margin: 0;
            }
            .content {
              padding: 32px 24px;
            }
            .button {
              display: inline-block;
              background-color: #0d9488;
              color: white;
              text-decoration: none;
              padding: 12px 32px;
              border-radius: 8px;
              font-weight: 600;
              margin: 24px 0;
              transition: background-color 0.3s;
            }
            .button:hover {
              background-color: #0f766e;
            }
            .footer {
              background-color: #f1f5f9;
              padding: 24px;
              text-align: center;
              font-size: 12px;
              color: #64748b;
            }
            .warning {
              background-color: #fef3c7;
              border-left: 4px solid #f59e0b;
              padding: 12px 16px;
              margin: 20px 0;
              border-radius: 8px;
              font-size: 14px;
            }
            .text-muted {
              color: #64748b;
              font-size: 14px;
            }
            hr {
              border: none;
              border-top: 1px solid #e2e8f0;
              margin: 24px 0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="card">
              <div class="header">
                <h1 class="logo">InternLink</h1>
                <p style="color: rgba(255,255,255,0.9); margin-top: 8px;">Smart Internship Management System</p>
              </div>
              <div class="content">
                <h2 style="margin-top: 0;">Reset Your Password</h2>
                <p>We received a request to reset the password for your InternLink account. Click the button below to create a new password:</p>
                
                <div style="text-align: center;">
                  <a href="${resetUrl}" class="button">Reset Password</a>
                </div>
                
                <div class="warning">
                  <strong>⚠️ Security Notice</strong><br>
                  This password reset link will expire in <strong>1 hour</strong>. If you didn't request this, please ignore this email and your password will remain unchanged.
                </div>
                
                <p class="text-muted">Or copy and paste this link into your browser:</p>
                <p style="background-color: #f1f5f9; padding: 12px; border-radius: 8px; word-break: break-all; font-size: 12px;">
                  ${resetUrl}
                </p>
                
                <hr />
                
                <p class="text-muted" style="font-size: 12px;">
                  For security reasons, this link can only be used once.<br>
                  If you need further assistance, please contact our support team.
                </p>
              </div>
              <div class="footer">
                <p>&copy; ${new Date().getFullYear()} InternLink. All rights reserved.</p>
                <p>Connecting Ethiopian Universities with Industry Leaders</p>
              </div>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`✅ Password reset email sent to ${email}: ${info.messageId}`);
    
  } catch (error) {
    console.error('❌ Failed to send password reset email:', error);
    // Don't throw error - password reset should still succeed
  }
};

const escapeHtml = (s: string): string =>
  s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

/**
 * Notify organization contact when admin approves university or company verification.
 * Logs errors only — does not throw (approval is already saved).
 */
export const sendOrganizationApprovalEmail = async (
  to: string,
  organizationName: string,
  institutionType: 'University' | 'Company'
): Promise<void> => {
  try {
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const loginUrl = `${frontendUrl}/login`;
    const safeName = escapeHtml(organizationName);
    const transporter = await getTransporter();

    const mailOptions = {
      from: `"InternLink" <${process.env.SMTP_USER || 'noreply@internlink.com'}>`,
      to,
      subject: `Your ${institutionType} account has been approved — InternLink`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Account approved</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #1e293b; background: #f8fafc; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
            .card { background: #fff; border-radius: 16px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; }
            .header { background: linear-gradient(135deg, #0d9488 0%, #115e59 100%); padding: 32px 24px; text-align: center; }
            .logo { font-size: 28px; font-weight: bold; color: white; margin: 0; }
            .content { padding: 32px 24px; }
            .button { display: inline-block; background: #0d9488; color: white !important; text-decoration: none; padding: 12px 32px; border-radius: 8px; font-weight: 600; margin: 16px 0; }
            .footer { background: #f1f5f9; padding: 24px; text-align: center; font-size: 12px; color: #64748b; }
            .text-muted { color: #64748b; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="card">
              <div class="header">
                <h1 class="logo">InternLink</h1>
                <p style="color: rgba(255,255,255,0.95); margin-top: 8px;">Verification approved</p>
              </div>
              <div class="content">
                <h2 style="margin-top: 0;">Your organization is approved</h2>
                <p>Good news — <strong>${safeName}</strong> has been <strong>approved</strong> as a registered <strong>${institutionType}</strong> on InternLink.</p>
                <p>Your organization account is now active. Coordinators and supervisors associated with your institution can sign in and use the platform according to their roles.</p>
                <div style="text-align: center;">
                  <a href="${loginUrl}" class="button">Sign in to InternLink</a>
                </div>
                <p class="text-muted">If the button does not work, open: <a href="${loginUrl}">${loginUrl}</a></p>
              </div>
              <div class="footer">
                <p>&copy; ${new Date().getFullYear()} InternLink. All rights reserved.</p>
              </div>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    const preview = nodemailer.getTestMessageUrl(info);
    if (preview) console.info(`ℹ️ Preview approval email at: ${preview}`);
    console.log(`✅ Organization approval email sent to ${to}: ${info.messageId}`);
  } catch (error: any) {
    console.error('❌ Failed to send organization approval email:', error?.message || error);
  }
};

/**
 * Notify organization contact when admin rejects verification; includes reason.
 * Logs errors only — does not throw (rejection is already saved).
 */
export const sendOrganizationRejectionEmail = async (
  to: string,
  organizationName: string,
  institutionType: 'University' | 'Company',
  rejectionReason: string
): Promise<void> => {
  try {
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const loginUrl = `${frontendUrl}/login`;
    const safeName = escapeHtml(organizationName);
    const safeReason = escapeHtml(rejectionReason.trim() || 'No additional details were provided.');
    const transporter = await getTransporter();

    const mailOptions = {
      from: `"InternLink" <${process.env.SMTP_USER || 'noreply@internlink.com'}>`,
      to,
      subject: `Verification update for ${organizationName} — InternLink`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Verification not approved</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #1e293b; background: #f8fafc; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
            .card { background: #fff; border-radius: 16px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; }
            .header { background: linear-gradient(135deg, #b91c1c 0%, #7f1d1d 100%); padding: 32px 24px; text-align: center; }
            .logo { font-size: 28px; font-weight: bold; color: white; margin: 0; }
            .content { padding: 32px 24px; }
            .reason { background: #fef2f2; border-left: 4px solid #dc2626; padding: 16px; border-radius: 8px; margin: 16px 0; font-size: 14px; color: #450a0a; white-space: pre-wrap; }
            .footer { background: #f1f5f9; padding: 24px; text-align: center; font-size: 12px; color: #64748b; }
            .text-muted { color: #64748b; font-size: 14px; }
            a.link { color: #0d9488; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="card">
              <div class="header">
                <h1 class="logo">InternLink</h1>
                <p style="color: rgba(255,255,255,0.95); margin-top: 8px;">Verification request closed</p>
              </div>
              <div class="content">
                <h2 style="margin-top: 0;">Your verification request was not approved</h2>
                <p>The verification request for <strong>${safeName}</strong> (${institutionType}) has been <strong>removed from the pending queue</strong>. Uploaded verification materials are no longer retained for this submission.</p>
                <p class="text-muted" style="margin-bottom: 8px;">Reason provided by the reviewer:</p>
                <div class="reason">${safeReason}</div>
                <p>You may register again with corrected information if your organization is eligible. If you have questions, contact platform support.</p>
                <p class="text-muted"><a class="link" href="${loginUrl}">Open InternLink</a></p>
              </div>
              <div class="footer">
                <p>&copy; ${new Date().getFullYear()} InternLink. All rights reserved.</p>
              </div>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    const preview = nodemailer.getTestMessageUrl(info);
    if (preview) console.info(`ℹ️ Preview rejection email at: ${preview}`);
    console.log(`✅ Organization rejection email sent to ${to}: ${info.messageId}`);
  } catch (error: any) {
    console.error('❌ Failed to send organization rejection email:', error?.message || error);
  }
};

/**
 * Notify platform admins when a new verification proposal is submitted (pending org).
 * Logs errors only — does not throw.
 */
export const sendAdminNewVerificationProposalEmail = async (
    toEmails: string[],
    params: {
        organizationName: string;
        institutionType: 'University' | 'Company';
        organizationId: number;
        submitterEmail?: string;
    }
): Promise<void> => {
    if (!toEmails.length) return;
    try {
        const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
        const queueUrl = `${frontendUrl}/admin?view=pending`;
        const safeName = escapeHtml(params.organizationName);
        const transporter = await getTransporter();
        const fromAddr = process.env.SMTP_USER || 'noreply@internlink.com';
        const submitterLine = params.submitterEmail
            ? `<p class="text-muted">Submitter contact: <strong>${escapeHtml(params.submitterEmail)}</strong></p>`
            : '';

        const html = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>New verification proposal</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #1e293b; background: #f8fafc; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
            .card { background: #fff; border-radius: 16px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; }
            .header { background: linear-gradient(135deg, #0d9488 0%, #115e59 100%); padding: 32px 24px; text-align: center; }
            .logo { font-size: 28px; font-weight: bold; color: white; margin: 0; }
            .content { padding: 32px 24px; }
            .button { display: inline-block; background: #0d9488; color: white !important; text-decoration: none; padding: 12px 28px; border-radius: 8px; font-weight: 600; margin: 16px 0; }
            .footer { background: #f1f5f9; padding: 24px; text-align: center; font-size: 12px; color: #64748b; }
            .text-muted { color: #64748b; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="card">
              <div class="header">
                <h1 class="logo">InternLink</h1>
                <p style="color: rgba(255,255,255,0.95); margin-top: 8px;">New verification proposal</p>
              </div>
              <div class="content">
                <h2 style="margin-top: 0;">Action required</h2>
                <p>A new <strong>${params.institutionType}</strong> verification proposal has been submitted and is <strong>pending review</strong>.</p>
                <p><strong>Organization:</strong> ${safeName}</p>
                <p class="text-muted"><strong>Reference ID:</strong> ${params.organizationId}</p>
                ${submitterLine}
                <div style="text-align: center;">
                  <a href="${queueUrl}" class="button">Open pending queue</a>
                </div>
                <p class="text-muted">Review and approve or reject within your platform response-time policy.</p>
              </div>
              <div class="footer">
                <p>&copy; ${new Date().getFullYear()} InternLink — Admin notification</p>
              </div>
            </div>
          </div>
        </body>
        </html>
        `;

        for (const to of toEmails) {
            const mailOptions = {
                from: `"InternLink" <${fromAddr}>`,
                to,
                subject: `[InternLink] New ${params.institutionType} proposal: ${params.organizationName}`,
                html,
            };
            const info = await transporter.sendMail(mailOptions);
            const preview = nodemailer.getTestMessageUrl(info);
            if (preview) console.info(`ℹ️ Preview admin new-proposal email at: ${preview}`);
            console.log(`✅ Admin new-proposal email sent to ${to}: ${info.messageId}`);
        }
    } catch (error: any) {
        console.error('❌ Failed to send admin new-proposal email:', error?.message || error);
    }
};

/**
 * Notify coordinator(s) when a new HoD registers and needs approval.
 * Logs errors only — does not throw.
 */
export const sendCoordinatorHodReviewEmail = async (
    toEmails: string[],
    params: {
        hodName: string;
        hodEmail: string;
        department: string;
        universityName: string;
    }
): Promise<void> => {
    if (!toEmails.length) return;
    try {
        const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
        const reviewUrl = `${frontendUrl}/coordinator/hod-approvals`;
        const transporter = await getTransporter();
        const fromAddr = process.env.SMTP_USER || 'noreply@internlink.com';

        const html = `
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #1e293b; background: #f8fafc; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
          .card { background: #fff; border-radius: 16px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; }
          .header { background: linear-gradient(135deg, #0d9488 0%, #115e59 100%); padding: 32px 24px; text-align: center; }
          .logo { font-size: 28px; font-weight: bold; color: white; margin: 0; }
          .content { padding: 32px 24px; }
          .button { display: inline-block; background: #0d9488; color: white !important; text-decoration: none; padding: 12px 28px; border-radius: 8px; font-weight: 600; margin: 16px 0; }
          .footer { background: #f1f5f9; padding: 24px; text-align: center; font-size: 12px; color: #64748b; }
          .text-muted { color: #64748b; font-size: 14px; }
          .info-row { padding: 6px 0; border-bottom: 1px solid #f1f5f9; font-size: 14px; }
        </style></head>
        <body>
          <div class="container"><div class="card">
            <div class="header">
              <h1 class="logo">InternLink</h1>
              <p style="color:rgba(255,255,255,0.9);margin-top:8px;">New HoD Verification Request</p>
            </div>
            <div class="content">
              <h2 style="margin-top:0;">Action Required: HoD Approval</h2>
              <p>A new Head of Department has registered and is awaiting your approval for <strong>${escapeHtml(params.universityName)}</strong>.</p>
              <div class="info-row"><strong>Name:</strong> ${escapeHtml(params.hodName)}</div>
              <div class="info-row"><strong>Email:</strong> ${escapeHtml(params.hodEmail)}</div>
              <div class="info-row" style="border:none"><strong>Department:</strong> ${escapeHtml(params.department)}</div>
              <div style="text-align:center;margin-top:24px;">
                <a href="${reviewUrl}" class="button">Review HoD Applications</a>
              </div>
              <p class="text-muted">Please review their credentials and approve or reject their access.</p>
            </div>
            <div class="footer"><p>&copy; ${new Date().getFullYear()} InternLink. All rights reserved.</p></div>
          </div></div>
        </body></html>`;

        for (const to of toEmails) {
            const info = await transporter.sendMail({
                from: `"InternLink" <${fromAddr}>`,
                to,
                subject: `[InternLink] New HoD registration pending review — ${params.universityName}`,
                html,
            });
            const preview = nodemailer.getTestMessageUrl(info);
            if (preview) console.info(`ℹ️ Preview HoD notification email at: ${preview}`);
            console.log(`✅ HoD coordinator notification sent to ${to}: ${info.messageId}`);
        }
    } catch (error: any) {
        console.error('❌ Failed to send HoD coordinator notification:', error?.message || error);
    }
};

/**
 * Invite a company to register on InternLink (sent by HoD).
 * Logs errors only — does not throw.
 */
export const sendCompanyInviteEmail = async (params: {
    to: string;
    companyName: string;
    universityName: string;
    hodName: string;
}): Promise<void> => {
    try {
        const frontendUrl = (process.env.FRONTEND_URL || 'http://localhost:3000').replace(/\/$/, '');
        const transporter = await getTransporter();
        const fromAddr = process.env.SMTP_USER || 'noreply@internlink.com';
        const html = `
        <!DOCTYPE html><html><head><meta charset="utf-8"/></head>
        <body style="font-family:sans-serif;line-height:1.5;color:#334155;">
          <p>Hello,</p>
          <p><strong>${escapeHtml(params.hodName)}</strong> from <strong>${escapeHtml(params.universityName)}</strong>
          has invited <strong>${escapeHtml(params.companyName)}</strong> to join InternLink for internship collaboration.</p>
          <p>Please register your company supervisor account at:<br/>
          <a href="${frontendUrl}/register">${frontendUrl}/register</a></p>
          <p>— InternLink</p>
        </body></html>`;
        const info = await transporter.sendMail({
            from: `"InternLink" <${fromAddr}>`,
            to: params.to,
            subject: `[InternLink] Invitation to register — ${params.companyName}`,
            html,
        });
        const preview = nodemailer.getTestMessageUrl(info);
        if (preview) console.info(`ℹ️ Preview company invite email at: ${preview}`);
        console.log(`✅ Company invite email sent to ${params.to}: ${info.messageId}`);
    } catch (error: any) {
        console.error('❌ Failed to send company invite email:', error?.message || error);
    }
};

/**
 * Test email configuration
 */
export const testEmailConfig = async (): Promise<boolean> => {
  try {
    const transporter = await getTransporter();
    await transporter.verify();
    console.log('✅ Email configuration is valid');
    return true;
  } catch (error) {
    console.error('❌ Email configuration is invalid:', error);
    return false;
  }
};