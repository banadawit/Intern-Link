import { Request, Response } from 'express';
import prisma from '../config/db';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { generateVerificationToken, getVerificationTokenExpiry } from '../utils/token.utils';
import { sendVerificationEmail } from '../services/email.service';

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
        const newUser = await prisma.user.create({
            data: {
                full_name,
                email,
                password_hash: hashedPassword,
                role: role.toUpperCase(), // Ensure uppercase for enum
                verification_status: 'PENDING',
                verification_token: verificationToken,
                verification_token_expiry: verificationTokenExpiry,
                verification_document: file ? file.path : null, // Store file path if uploaded
            }
        });

        // ✅ Create role-specific profile
        if (role.toUpperCase() === 'COORDINATOR') {
            // First, find or create university
            let university = await prisma.university.findFirst({
                where: { name: university_name }
            });
            
            if (!university && university_name) {
                university = await prisma.university.create({
                    data: {
                        name: university_name,
                        official_email: email,
                        approval_status: 'PENDING'
                    }
                });
            }
            
            if (university) {
                await prisma.coordinator.create({
                    data: {
                        userId: newUser.id,
                        universityId: university.id,
                        phone_number: position || null,
                    }
                });
            }
        } 
        else if (role.toUpperCase() === 'SUPERVISOR') {
            // First, find or create company
            let company = await prisma.company.findFirst({
                where: { name: company_name }
            });
            
            if (!company && company_name) {
                company = await prisma.company.create({
                    data: {
                        name: company_name,
                        official_email: email,
                        approval_status: 'PENDING'
                    }
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
        else if (role.toUpperCase() === 'STUDENT') {
            // Find university
            let university = await prisma.university.findFirst({
                where: { name: university_name }
            });
            
            if (!university && university_name) {
                university = await prisma.university.create({
                    data: {
                        name: university_name,
                        official_email: email,
                        approval_status: 'PENDING'
                    }
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
            await sendVerificationEmail(email, verificationToken);
        } catch (err: any) {
            console.error('Email send error after registration:', err);
            emailSendError = err?.message || 'Unable to send verification email.';
        }

        // In development, log the token so you can verify manually
        if (process.env.NODE_ENV === 'development') {
            console.log(`\n🔑 VERIFY EMAIL TOKEN for ${email}:`);
            console.log(`   http://localhost:3000/verify-email?token=${verificationToken}\n`);
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
            message: "Registration successful. Please check your email to verify your account.",
            data: {
                ...baseResponse,
                emailSent: true
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
        const { email, password } = req.body;

        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) {
            return res.status(401).json({ 
                success: false,
                message: "Invalid credentials" 
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
                message: "Invalid credentials" 
            });
        }

        // Generate JWT
        const token = jwt.sign(
            { userId: user.id, role: user.role, email: user.email },
            process.env.JWT_SECRET as string,
            // { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
            { expiresIn: '7d' } as jwt.SignOptions
        );

        res.json({ 
            success: true,
            data: {
                token,
                user: {
                    id: user.id,
                    email: user.email,
                    fullName: user.full_name,
                    role: user.role,
                    isVerified: user.verification_status === 'APPROVED'
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
        // await sendPasswordResetEmail(email, resetToken);

        res.json({ 
            success: true,
            message: "Password reset email sent",
            // Remove token in production, keep for testing
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