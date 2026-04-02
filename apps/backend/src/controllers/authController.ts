import { Request, Response } from 'express';
import prisma from '../config/db';
import { Role } from '@prisma/client';
import { incrementActivityForUser } from '../services/activityLog.service';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { generateVerificationToken, getVerificationTokenExpiry } from '../utils/token.utils';
import { sendVerificationEmail, sendPasswordResetEmail } from '../services/email.service';
import { notifyAdminsNewVerificationProposal } from '../utils/notifyAdminNewProposal';

// ============================================
// REGISTER - with email verification
// ============================================
export const register = async (req: Request, res: Response) => {
    try {
        const { full_name, email, password, role, university_name, company_name, department, student_id, position } = req.body;
        
        // Get uploaded file if exists
        const file = (req as any).file;

        // Check if user exists
        const userExists = await prisma.user.findUnique({ where: { email } });
        if (userExists) {
            return res.status(400).json({ 
                success: false,
                message: "Email already exists" 
            });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // ✅ Generate email verification token
        const verificationToken = generateVerificationToken();
        const verificationTokenExpiry = getVerificationTokenExpiry();

        // Create user with verification token
        const roleUpper = role.toUpperCase();
        const needsIndividualAdminApproval =
            roleUpper === 'COORDINATOR' || roleUpper === 'SUPERVISOR';

        const newUser = await prisma.user.create({
            data: {
                full_name,
                email,
                password_hash: hashedPassword,
                role: roleUpper, // Ensure uppercase for enum
                verification_status: 'PENDING',
                verification_token: verificationToken,
                verification_token_expiry: verificationTokenExpiry,
                verification_document: file ? file.path : null, // Store file path if uploaded
                institution_access_approval: needsIndividualAdminApproval ? 'PENDING' : 'APPROVED',
            }
        });

        // ✅ Create role-specific profile
        if (roleUpper === 'COORDINATOR') {
            // Late-creation workflow: do NOT create University yet.
            // Store the university name in the profile; admin will create it upon approval.
            await prisma.coordinator.create({
                data: {
                    userId: newUser.id,
                    pending_university_name: university_name || null,
                }
            });

            // Notify admins to review this coordinator's credentials
            await notifyAdminsNewVerificationProposal({
                organizationName: university_name || 'Unknown University',
                institutionType: 'University',
                organizationId: newUser.id,
                submitterEmail: email,
            });
        } 
        else if (roleUpper === 'SUPERVISOR') {
            // First, find or create company
            let company = await prisma.company.findFirst({
                where: { name: company_name }
            });
            let createdNewCompany = false;

            if (!company && company_name) {
                company = await prisma.company.create({
                    data: {
                        name: company_name,
                        official_email: email,
                        approval_status: 'PENDING'
                    }
                });
                createdNewCompany = true;
            }

            if (company && createdNewCompany) {
                await notifyAdminsNewVerificationProposal({
                    organizationName: company.name,
                    institutionType: 'Company',
                    organizationId: company.id,
                    submitterEmail: email,
                });
            }
            
            if (company) {
                await prisma.supervisor.create({
                    data: {
                        userId: newUser.id,
                        companyId: company.id,
                        phone_number: position || null,
                    }
                });
            }
        } 
        else if (roleUpper === 'STUDENT') {
            // Find university
            let university = await prisma.university.findFirst({
                where: { name: university_name }
            });
            let createdNewUniversityForStudent = false;

            if (!university && university_name) {
                university = await prisma.university.create({
                    data: {
                        name: university_name,
                        official_email: email,
                        approval_status: 'PENDING'
                    }
                });
                createdNewUniversityForStudent = true;
            }

            if (university && createdNewUniversityForStudent) {
                await notifyAdminsNewVerificationProposal({
                    organizationName: university.name,
                    institutionType: 'University',
                    organizationId: university.id,
                    submitterEmail: email,
                });
            }
            
            if (university) {
                await prisma.student.create({
                    data: {
                        userId: newUser.id,
                        universityId: university.id,
                        registration_type: email.includes('.edu.et') ? 'Official' : 'Personal',
                        studentId: student_id || null,
                        department: department || null,
                    }
                });
            }
        }

        // ✅ Send verification email
        let emailSendError = null;
        try {
            await sendVerificationEmail(email, verificationToken, roleUpper);
        } catch (err: any) {
            console.error('Email send error after registration:', err);
            emailSendError = err?.message || 'Unable to send verification email.';
        }

        // In development, log the token so you can verify manually
        if (process.env.NODE_ENV === 'development') {
            console.log(`\n🔑 VERIFY EMAIL TOKEN for ${email}:`);
            console.log(`   http://localhost:3000/verify-email?token=${verificationToken}${roleUpper === 'COORDINATOR' ? '&role=coordinator' : ''}\n`);
        }

        const baseResponse = {
            userId: newUser.id,
            email: newUser.email,
            requiresVerification: true,
        };

        if (emailSendError) {
            return res.status(201).json({ 
                success: true,
                message: "Registration successful, but verification email could not be sent. Please request a new verification link or contact support.",
                error: emailSendError,
                data: {
                    ...baseResponse,
                    emailSent: false
                }
            });
        }

        res.status(201).json({ 
            success: true,
            message: roleUpper === 'COORDINATOR'
                ? "Registration submitted. An administrator will review your university credentials. You will receive an email once approved."
                : "Registration successful. Please check your email to verify your account.",
            data: {
                ...baseResponse,
                emailSent: true,
                pendingAdminReview: roleUpper === 'COORDINATOR',
            }
        });
        
    } catch (error: any) {
        console.error('Registration error:', error);
        res.status(500).json({ 
            success: false,
            error: error.message 
        });
    }
};

// ============================================
// LOGIN - with verification check
// ============================================
export const login = async (req: Request, res: Response) => {
    try {
        const { email: rawEmail, password } = req.body;
        const email =
            typeof rawEmail === 'string' ? rawEmail.trim() : '';

        if (!email || typeof password !== 'string') {
            return res.status(400).json({
                success: false,
                message: 'Email and password are required',
            });
        }

        const user = await prisma.user.findFirst({
            where: {
                email: { equals: email, mode: 'insensitive' },
            },
            include: {
                coordinatorProfile: { include: { university: true } },
                supervisorProfile: { include: { company: true } },
                studentProfile: { include: { university: true } },
            },
        });
        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password. Please try again.',
            });
        }

        // ✅ Check if email is verified
        if (user.verification_status !== 'APPROVED') {
            return res.status(401).json({ 
                success: false,
                message: "Please verify your email before logging in",
                requiresVerification: true,
                email: user.email
            });
        }

        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password. Please try again.',
            });
        }

        // Institution verification (SRS): org must be admin-approved; coordinators/supervisors also need individual admin approval
        if (user.role === 'COORDINATOR') {
            const profile = user.coordinatorProfile;
            // Coordinator hasn't been approved yet (no university linked)
            if (!profile?.universityId) {
                return res.status(403).json({
                    success: false,
                    message: 'Your coordinator account is pending administrator approval. You will receive an email once approved.',
                    code: 'PENDING_ADMIN_REVIEW',
                });
            }
            const uni = profile?.university;
            if (!uni) {
                return res.status(403).json({
                    success: false,
                    message: 'No university profile is linked to this account. Contact support.',
                    code: 'NO_INSTITUTION_PROFILE',
                });
            }
            if (uni.approval_status === 'SUSPENDED') {
                return res.status(403).json({
                    success: false,
                    message:
                        'This university organization has been suspended by an administrator. Contact support for assistance.',
                    code: 'INSTITUTION_SUSPENDED',
                });
            }
            if (uni.approval_status !== 'APPROVED') {
                return res.status(403).json({
                    success: false,
                    message:
                        'Your university’s verification proposal must be submitted and approved by an administrator before you can access the system.',
                    code: 'INSTITUTION_NOT_APPROVED',
                });
            }
            if (user.institution_access_approval !== 'APPROVED') {
                return res.status(403).json({
                    success: false,
                    message:
                        'Your coordinator account must be individually approved by an administrator after your organization is verified.',
                    code: 'INSTITUTION_MEMBER_NOT_APPROVED',
                });
            }
        }

        if (user.role === 'SUPERVISOR') {
            const company = user.supervisorProfile?.company;
            if (!company) {
                return res.status(403).json({
                    success: false,
                    message: 'No company profile is linked to this account. Contact support.',
                    code: 'NO_INSTITUTION_PROFILE',
                });
            }
            if (company.approval_status === 'SUSPENDED') {
                return res.status(403).json({
                    success: false,
                    message:
                        'This company organization has been suspended by an administrator. Contact support for assistance.',
                    code: 'INSTITUTION_SUSPENDED',
                });
            }
            if (company.approval_status !== 'APPROVED') {
                return res.status(403).json({
                    success: false,
                    message:
                        'Your company’s verification proposal must be submitted and approved by an administrator before you can access the system.',
                    code: 'INSTITUTION_NOT_APPROVED',
                });
            }
            if (user.institution_access_approval !== 'APPROVED') {
                return res.status(403).json({
                    success: false,
                    message:
                        'Your supervisor account must be individually approved by an administrator after your organization is verified.',
                    code: 'INSTITUTION_MEMBER_NOT_APPROVED',
                });
            }
        }

        if (user.role === 'STUDENT') {
            const uni = user.studentProfile?.university;
            if (uni && uni.approval_status === 'SUSPENDED') {
                return res.status(403).json({
                    success: false,
                    message:
                        'Your university organization has been suspended by an administrator. Contact support for assistance.',
                    code: 'INSTITUTION_SUSPENDED',
                });
            }
            if (uni && uni.approval_status !== 'APPROVED') {
                return res.status(403).json({
                    success: false,
                    message:
                        'Your university account is not active yet. Verification must be submitted and approved by an administrator before you can sign in.',
                    code: 'INSTITUTION_NOT_APPROVED',
                });
            }
        }

        // Generate JWT
        const token = jwt.sign(
            { userId: user.id, role: user.role, email: user.email },
            process.env.JWT_SECRET as string,
            // { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
            { expiresIn: '7d' } as jwt.SignOptions
        );

        if (user.role === Role.STUDENT) {
            void incrementActivityForUser(user.id);
        }

        res.json({ 
            success: true,
            data: {
                token,
                user: {
                    id: user.id,
                    email: user.email,
                    fullName: user.full_name,
                    role: user.role,
                    isVerified: user.verification_status === 'APPROVED',
                    institutionAccessApproval: user.institution_access_approval,
                }
            }
        });
        
    } catch (error: any) {
        res.status(500).json({ 
            success: false,
            error: error.message 
        });
    }
};

// ============================================
// VERIFY EMAIL - New Endpoint
// ============================================
export const verifyEmail = async (req: Request, res: Response) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                message: "Verification token is required"
            });
        }

        // Find user with valid token
        const user = await prisma.user.findFirst({
            where: {
                verification_token: token,
                verification_token_expiry: {
                    gt: new Date() // Token not expired
                }
            }
        });

        if (!user) {
            return res.status(400).json({
                success: false,
                message: "Invalid or expired verification token. Please request a new one."
            });
        }

        // Update user as verified
        await prisma.user.update({
            where: { id: user.id },
            data: {
                verification_status: 'APPROVED',
                verification_token: null,
                verification_token_expiry: null
            }
        });

        res.status(200).json({
            success: true,
            message: "Email verified successfully. You can now login."
        });

    } catch (error: any) {
        console.error('Verification error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

// ============================================
// RESEND VERIFICATION EMAIL - New Endpoint
// ============================================
export const resendVerification = async (req: Request, res: Response) => {
    try {
        const { email } = req.body;

        if (!email) {
            return res.status(400).json({
                success: false,
                message: "Email is required"
            });
        }

        const user = await prisma.user.findUnique({
            where: { email }
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        if (user.verification_status === 'APPROVED') {
            return res.status(400).json({
                success: false,
                message: "Email is already verified"
            });
        }

        // Generate new token
        const verificationToken = generateVerificationToken();
        const verificationTokenExpiry = getVerificationTokenExpiry();

        await prisma.user.update({
            where: { id: user.id },
            data: {
                verification_token: verificationToken,
                verification_token_expiry: verificationTokenExpiry
            }
        });

        // Send new verification email
        try {
            await sendVerificationEmail(email, verificationToken);
        } catch (err: any) {
            console.error('Email resend error:', err);
            return res.status(500).json({
                success: false,
                message: "Failed to resend verification email. Please check your email settings or contact support.",
                error: err?.message || 'Unable to send verification email.'
            });
        }

        res.status(200).json({
            success: true,
            message: "Verification email resent successfully"
        });

    } catch (error: any) {
        console.error('Resend error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

// ============================================
// FORGOT PASSWORD - Generates Token
// ============================================
export const forgotPassword = async (req: Request, res: Response) => {
    try {
        const { email } = req.body;
        const user = await prisma.user.findUnique({ where: { email } });

        if (!user) {
            return res.status(404).json({ 
                success: false,
                message: "User not found" 
            });
        }

        // Generate a random token
        const resetToken = crypto.randomBytes(32).toString('hex');
        const expiry = new Date(Date.now() + 3600000); // Expires in 1 hour

        // Save to DB
        await prisma.user.update({
            where: { email },
            data: {
                reset_password_token: resetToken,
                reset_password_expires: expiry
            }
        });

        // TODO: Send email with reset link
        let emailError = null;
        try {
            await sendPasswordResetEmail(email, resetToken);
        } catch (err: any) {
            emailError = err?.message;
        }

        if (process.env.NODE_ENV === 'development') {
            console.log(`\n🔑 RESET PASSWORD TOKEN for ${email}:`);
            console.log(`   http://localhost:3000/reset-password/${resetToken}\n`);
        }

        res.json({ 
            success: true,
            message: "Password reset email sent",
            token: process.env.NODE_ENV === 'development' ? resetToken : undefined
        });
        
    } catch (error: any) {
        res.status(500).json({ 
            success: false,
            error: error.message 
        });
    }
};

// ============================================
// RESET PASSWORD - Verifies Token & Updates Password
// ============================================
export const resetPassword = async (req: Request, res: Response) => {
    try {
        const { token, newPassword } = req.body;

        if (!token || !newPassword) {
            return res.status(400).json({
                success: false,
                message: "Token and new password are required"
            });
        }

        // Find user with this token and check if token is still valid
        const user = await prisma.user.findFirst({
            where: {
                reset_password_token: token,
                reset_password_expires: { gt: new Date() }
            }
        });

        if (!user) {
            return res.status(400).json({ 
                success: false,
                message: "Invalid or expired token" 
            });
        }

        // Hash new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        // Update user and clear reset fields
        await prisma.user.update({
            where: { id: user.id },
            data: {
                password_hash: hashedPassword,
                reset_password_token: null,
                reset_password_expires: null
            }
        });

        res.json({ 
            success: true,
            message: "Password has been reset successfully" 
        });
        
    } catch (error: any) {
        res.status(500).json({ 
            success: false,
            error: error.message 
        });
    }
};

// ============================================
// GET CURRENT USER - Protected Route
// ============================================
export const getCurrentUser = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.userId;
        
        if (!userId) {
            return res.status(401).json({
                success: false,
                message: "Unauthorized"
            });
        }

        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                studentProfile: {
                    include: { university: true }
                },
                coordinatorProfile: {
                    include: { university: true }
                },
                supervisorProfile: {
                    include: { company: true }
                }
            }
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found"
            });
        }

        res.json({
            success: true,
            data: {
                id: user.id,
                email: user.email,
                fullName: user.full_name,
                role: user.role,
                isVerified: user.verification_status === 'APPROVED',
                institutionAccessApproval: user.institution_access_approval,
                profile: user.studentProfile || user.coordinatorProfile || user.supervisorProfile
            }
        });

    } catch (error: any) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
};