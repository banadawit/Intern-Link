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
export const sendVerificationEmail = async (email: string, token: string): Promise<void> => {
  try {
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
    const verificationUrl = `${frontendUrl}/verify-email?token=${token}`;
    
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