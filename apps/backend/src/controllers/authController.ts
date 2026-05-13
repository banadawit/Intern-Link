import { Request, Response } from 'express';
import prisma from '../config/db';
import { Role } from '@prisma/client';
import { incrementActivityForUser } from '../services/activityLog.service';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { generateVerificationToken, getVerificationTokenExpiry } from '../utils/token.utils';
import { sendVerificationEmail, sendPasswordResetEmail, sendCoordinatorHodReviewEmail } from '../services/email.service';
import { notifyAdminsNewVerificationProposal } from '../utils/notifyAdminNewProposal';
import { sendNotification } from '../utils/notificationHelper';
import { isRegistrationOpen, isMaintenanceMode } from './systemConfigController';
import { sendSuccess, sendError } from '../utils/responseHelper';
import { notifyAllAdmins, NotificationType } from '../services/notification.service';
import { CloudinaryService } from '../services/cloudinary.service';

const getJwtSecret = (): string => {
    const secret = (process.env.JWT_SECRET || '').trim();
    if (secret) return secret;
    if (process.env.NODE_ENV !== 'production') {
        return 'dev_jwt_secret_change_me';
    }
    throw new Error('JWT_SECRET is not configured');
};

// ============================================
// REGISTER - with email verification
// ============================================
export const register = async (req: Request, res: Response) => {
    try {
        const { 
            full_name, 
            email, 
            password, 
            role, 
            university_name, 
            company_name, 
            department, 
            student_id, 
            position,
            verification_document // This is now a URL string from frontend
        } = req.body;
        
        // Get uploaded file if exists
        const file = (req as any).file;
        let verificationDocUrl = (verification_document && String(verification_document).startsWith('http')) ? verification_document : null;

        const roleUpper = (role ?? '').toUpperCase();
        
        if (file) {
            const upload = await CloudinaryService.uploadVerificationDoc(file, {
                fileType: 'VERIFICATION_DOC',
                folder: `internlink/users/verification/${roleUpper.toLowerCase()}`,
            });
            if (upload.success && upload.url) {
                verificationDocUrl = upload.url;
            } else {
                return sendError(res, upload.error || 'Failed to upload verification document', 500);
            }
        }

        // Maintenance mode check
        const maintenance = await isMaintenanceMode();
        if (maintenance.active) {
            return sendError(res, maintenance.message, 503, 'MAINTENANCE_MODE');
        }

        // For students, pass universityId so per-university override is checked
        const universityIdForCheck = roleUpper === 'STUDENT'
            ? parseInt(String(req.body.university_id ?? '0'), 10) || undefined
            : undefined;
        const regCheck = await isRegistrationOpen(roleUpper, universityIdForCheck);
        if (!regCheck.allowed) {
            return sendError(res, regCheck.reason ?? `Registration for ${roleUpper} accounts is currently closed.`, 403, 'REGISTRATION_CLOSED');
        }

        const supervisorCompanyName =
            roleUpper === 'SUPERVISOR' && typeof company_name === 'string' ? company_name.trim() : '';

        if (roleUpper === 'SUPERVISOR' && !supervisorCompanyName) {
            return sendError(res, 'Company name is required for supervisor registration.', 400);
        }

        const { university_id: bodyUniversityId, hod_id: bodyHodId, employee_id } = req.body as {
            university_id?: unknown;
            hod_id?: unknown;
            employee_id?: unknown;
        };

        // ────────────────────────────────────────────────────────────────────
        // COORDINATOR Registration: Must select existing APPROVED university OR have a pending request
        // ────────────────────────────────────────────────────────────────────
        let coordinatorEnrollment: { universityId?: number; requestId?: number; universityName: string } | undefined;

        if (roleUpper === 'COORDINATOR') {
            const universityId = parseInt(String(bodyUniversityId ?? ''), 10);
            const requestId = parseInt(String(req.body.organization_request_id ?? ''), 10);

            if (universityId && !isNaN(universityId)) {
                const university = await prisma.university.findUnique({ where: { id: universityId } });
                if (!university || university.approval_status !== 'APPROVED') {
                    return sendError(res, 'Selected university is not approved or does not exist.', 400);
                }
                const existingCoordinator = await prisma.coordinator.findFirst({
                    where: { universityId }
                });
                if (existingCoordinator) {
                    return sendError(res, `A coordinator is already registered for "${university.name}". Each university can only have one primary coordinator.`, 400);
                }
                coordinatorEnrollment = { universityId, universityName: university.name };
            } else if (requestId && !isNaN(requestId)) {
                const request = await prisma.organizationRequest.findUnique({ where: { id: requestId } });
                if (!request || request.type !== 'UNIVERSITY') {
                    return sendError(res, 'Organization request not found or invalid type.', 400);
                }
                coordinatorEnrollment = { requestId, universityName: request.name };
                // Fallback: If no document was uploaded during registration, use the one from the request
                if (!verificationDocUrl && request.verification_doc) {
                    verificationDocUrl = request.verification_doc;
                }
            } else {
                return sendError(res, 'Please select a university or submit a new institution request.', 400);
            }
        }

        let hodEnrollment:
            | {
                  universityId: number;
                  department: string;
                  employeePhone: string | null;
                  coordinatorEmails: string[];
                  universityName: string;
              }
            | undefined;

        if (roleUpper === 'HOD') {
            const universityId = parseInt(String(bodyUniversityId ?? ''), 10);
            if (!universityId || !department) {
                return sendError(res, 'University and department are required for HoD registration.', 400);
            }
            const university = await prisma.university.findUnique({ where: { id: universityId } });
            if (!university || university.approval_status !== 'APPROVED') {
                return sendError(res, 'Selected university is not approved or does not exist.', 400);
            }
            const universityCoordinator = await prisma.coordinator.findFirst({
                where: { universityId },
            });
            if (!universityCoordinator) {
                return sendError(
                    res,
                    `Your university "${university.name}" does not have a coordinator yet. Please make sure your coordinator registers and gets approved first before you register as Head of Department.`,
                    400
                );
            }
            const coordinators = await prisma.coordinator.findMany({
                where: { universityId },
                include: { user: { select: { email: true } } },
            });
            hodEnrollment = {
                universityId,
                department,
                employeePhone:
                    typeof employee_id === 'string' && employee_id.trim() ? employee_id.trim() : null,
                coordinatorEmails: coordinators.map((c) => c.user.email),
                universityName: university.name,
            };
        }

        let studentEnrollment:
            | {
                  universityId: number;
                  hodId: number | null;
                  hodDepartment: string | null;
                  hodUserId: number | null;
              }
            | undefined;

        if (roleUpper === 'STUDENT') {
            const universityId = parseInt(String(bodyUniversityId ?? ''), 10);
            const hodId = bodyHodId ? parseInt(String(bodyHodId), 10) : null;

            if (!universityId) {
                return sendError(res, 'University is required for student registration.', 400);
            }

            const university = await prisma.university.findUnique({ where: { id: universityId } });
            if (!university || university.approval_status !== 'APPROVED') {
                return sendError(res, 'Selected university is not approved.', 400);
            }

            let hodProfile: { department: string; userId: number } | null = null;
            if (hodId) {
                const hp = await prisma.hodProfile.findUnique({ where: { id: hodId } });
                if (!hp || hp.universityId !== universityId) {
                    return sendError(res, 'Selected department is not valid for this university.', 400);
                }
                hodProfile = { department: hp.department, userId: hp.userId };
            }

            studentEnrollment = {
                universityId,
                hodId,
                hodDepartment: hodProfile?.department ?? (department || null),
                hodUserId: hodProfile?.userId ?? null,
            };
        }

        // Check if user exists
        const userExists = await prisma.user.findUnique({ where: { email } });
        if (userExists) {
            return sendError(res, "Email already exists", 400);
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // ✅ Generate email verification token
        const verificationToken = generateVerificationToken();
        const verificationTokenExpiry = getVerificationTokenExpiry();

        // The URL is already provided by the frontend after Cloudinary upload
        // OR we just uploaded it above if it was a direct file upload
        // const verificationDocUrl = verification_document || null; // Handled above now

        const needsIndividualAdminApproval =
            roleUpper === 'COORDINATOR' || roleUpper === 'SUPERVISOR' || roleUpper === 'HOD';

        const registrationResult = await prisma.$transaction(async (tx) => {
            let supervisorNewCompanyMeta: { companyId: number; companyName: string } | null = null;

            const user = await tx.user.create({
                data: {
                    full_name,
                    email,
                    password_hash: hashedPassword,
                    role: roleUpper as Role,
                    verification_status: 'PENDING',
                    verification_token: verificationToken,
                    verification_token_expiry: verificationTokenExpiry,
                    verification_document: verificationDocUrl,
                    institution_access_approval: needsIndividualAdminApproval ? 'PENDING' : 'APPROVED',
                },
            });

            if (roleUpper === 'COORDINATOR') {
                await tx.coordinator.create({
                    data: {
                        userId: user.id,
                        universityId: coordinatorEnrollment?.universityId ?? null,
                        pending_university_name: coordinatorEnrollment?.universityId ? null : coordinatorEnrollment?.universityName,
                        phone_number: null,
                    },
                });
            } else if (roleUpper === 'SUPERVISOR') {
                const companyId = parseInt(String(req.body.company_id ?? ''), 10);
                const requestId = parseInt(String(req.body.organization_request_id ?? ''), 10);
                let linkedCompanyId: number;

                if (companyId && !isNaN(companyId)) {
                    const company = await tx.company.findUnique({ where: { id: companyId } });
                    if (!company || company.approval_status !== 'APPROVED') {
                        throw new Error('Selected company is not approved or does not exist.');
                    }
                    linkedCompanyId = company.id;
                } else if (requestId && !isNaN(requestId)) {
                    const request = await tx.organizationRequest.findUnique({ where: { id: requestId } });
                    if (!request || request.type !== 'COMPANY') {
                        throw new Error('Organization request not found or invalid type.');
                    }
                    // Fallback: If no document was uploaded during registration, use the one from the request
                    if (!verificationDocUrl && request.verification_doc) {
                        verificationDocUrl = request.verification_doc;
                    }

                    const existingCompany = await tx.company.findFirst({ where: { name: request.name } });
                    if (existingCompany) {
                        linkedCompanyId = existingCompany.id;
                    } else {
                        const newCompany = await tx.company.create({
                            data: {
                                name: request.name,
                                official_email: request.requester_email,
                                approval_status: 'PENDING',
                                verification_doc: request.verification_doc,
                            },
                        });
                        linkedCompanyId = newCompany.id;
                        supervisorNewCompanyMeta = { companyId: newCompany.id, companyName: newCompany.name };
                    }
                } else {
                    throw new Error('Please select a company or submit a new organization request.');
                }

                await tx.supervisor.create({
                    data: {
                        userId: user.id,
                        companyId: linkedCompanyId,
                        phone_number: position || null,
                    },
                });
            } else if (roleUpper === 'HOD' && hodEnrollment) {
                await tx.hodProfile.create({
                    data: {
                        userId: user.id,
                        universityId: hodEnrollment.universityId,
                        department: hodEnrollment.department,
                        phone_number: hodEnrollment.employeePhone,
                    },
                });
            } else if (roleUpper === 'STUDENT' && studentEnrollment) {
                await tx.student.create({
                    data: {
                        userId: user.id,
                        universityId: studentEnrollment.universityId,
                        hodId: studentEnrollment.hodId,
                        registration_type: email.includes('.edu.et') ? 'Official' : 'Personal',
                        studentId: student_id || null,
                        department: studentEnrollment.hodDepartment,
                        hod_approval_status: 'PENDING',
                    },
                });
            }

            return { user, supervisorNewCompanyMeta };
        });

        const newUser = registrationResult.user;

        if (roleUpper === 'COORDINATOR') {
            if (coordinatorEnrollment) {
                await notifyAllAdmins(
                    `New Coordinator registration pending: ${full_name} (${email}) for ${coordinatorEnrollment.universityName}`,
                    NotificationType.ADMIN_ALERT
                );
            }

            await sendNotification(
                newUser.id,
                'Your coordinator registration was received and is pending review by an administrator.'
            );
        } else if (roleUpper === 'SUPERVISOR') {
            const supervisorNewCompanyMeta = registrationResult.supervisorNewCompanyMeta;
            if (supervisorNewCompanyMeta) {
                await notifyAdminsNewVerificationProposal({
                    organizationName: supervisorNewCompanyMeta.companyName,
                    institutionType: 'Company',
                    organizationId: supervisorNewCompanyMeta.companyId,
                    submitterEmail: email,
                });

                await notifyAllAdmins(
                    `New Company registration pending: ${supervisorCompanyName} (Submitted by ${full_name})`,
                    NotificationType.ADMIN_ALERT
                );
            }

            await notifyAllAdmins(
                `New Supervisor registration pending: ${full_name} (${email}) for ${supervisorCompanyName}`,
                NotificationType.ADMIN_ALERT
            );

            await sendNotification(
                newUser.id,
                'Your supervisor registration was received and is pending review by an administrator.'
            );
        } else if (roleUpper === 'HOD' && hodEnrollment) {
            if (hodEnrollment.coordinatorEmails.length > 0) {
                await sendCoordinatorHodReviewEmail(hodEnrollment.coordinatorEmails, {
                    hodName: full_name,
                    hodEmail: email,
                    department: hodEnrollment.department,
                    universityName: hodEnrollment.universityName,
                });
            } else {
                console.log(`ℹ️ No coordinators found for university ${hodEnrollment.universityId} to notify about new HoD.`);
            }
        } else if (roleUpper === 'STUDENT' && studentEnrollment && studentEnrollment.hodUserId) {
            const dept =
                (await prisma.hodProfile.findUnique({
                    where: { userId: studentEnrollment.hodUserId },
                    select: { department: true },
                }))?.department ?? 'your department';
            await sendNotification(
                studentEnrollment.hodUserId,
                `New student ${full_name} (${email}) has registered for your department "${dept}" and is awaiting your approval.`
            );
        }
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
            verificationToken:
                process.env.NODE_ENV !== 'production' ? verificationToken : undefined,
        };

        if (emailSendError) {
            return sendSuccess(res, {
                ...baseResponse,
                emailSent: false,
                emailError: emailSendError
            }, "Registration successful, but verification email could not be sent. Please request a new verification link or contact support.", 201);
        }

        const successMessage =
            roleUpper === 'COORDINATOR'
                ? "Registration submitted. An administrator will review your university credentials. You will receive an email once approved."
                : roleUpper === 'SUPERVISOR'
                  ? "Registration submitted. An administrator will review your company credentials. You will receive an email once approved."
                  : roleUpper === 'HOD'
                    ? "Registration submitted. Your University Coordinator will review your department credentials. You will be notified via email upon approval."
                    : roleUpper === 'STUDENT'
                      ? "Registration submitted. Your Head of Department will review your academic status. You will be notified via email once approved."
                      : "Registration successful. Please check your email to verify your account.";

        return sendSuccess(res, {
            ...baseResponse,
            emailSent: true,
            pendingAdminReview: roleUpper === 'COORDINATOR' || roleUpper === 'SUPERVISOR',
            pendingCoordinatorReview: roleUpper === 'HOD',
        }, successMessage, 201);
        
    } catch (error: any) {
        console.error('Registration error:', error);
        if (error.code === 'P2002' && error.meta?.target?.includes('universityId')) {
            return sendError(res, 'A coordinator is already registered for this university. Each university can only have one primary coordinator.', 400);
        }
        return sendError(res, error.message || 'An unexpected error occurred during registration', 500);
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
            return sendError(res, 'Email and password are required', 400);
        }

        let user;
        try {
            user = await prisma.user.findFirst({
                where: {
                    email: { equals: email, mode: 'insensitive' },
                },
                include: {
                    coordinatorProfile: { include: { university: true } },
                    hodProfile: { include: { university: true } },
                    supervisorProfile: { include: { company: true } },
                    studentProfile: { include: { university: true } },
                },
            });
        } catch (dbError: any) {
            console.error('[Database Error] Login query failed:', dbError.message);
            return sendError(res, 'Unable to connect to the database. Please try again later or contact support.', 503, 'DATABASE_CONNECTION_ERROR');
        }

        if (!user) {
            // Log security alert for unknown user login attempt
            console.warn(`[Security] Login attempt for non-existent email: ${email}`);
            // notifyAllAdmins(`Suspicious activity: Login attempt for non-existent user ${email}`, NotificationType.SECURITY_ALERT);
            return sendError(res, 'Invalid email or password. Please try again.', 401);
        }

        // ✅ Check if email is verified
        if (user.verification_status !== 'APPROVED') {
            if (user.role === 'COORDINATOR') {
                return sendError(res, "Your registration is pending administrator approval. You will receive an email once your university credentials are reviewed.", 401, 'PENDING_ADMIN_REVIEW', { email: user.email });
            }
            if (user.role === 'HOD') {
                return sendError(res, "Your registration is pending coordinator approval. You will receive an email once your department credentials are reviewed.", 401, 'PENDING_COORDINATOR_REVIEW', { email: user.email });
            }
            if (user.role === 'STUDENT') {
                // For students, check if HOD has already approved them (email verification is the blocker)
                const sp = user.studentProfile;
                if (sp && sp.hod_approval_status === 'APPROVED') {
                    return sendError(res, "Please verify your email before logging in. Check your inbox for the verification link.", 401, 'EMAIL_NOT_VERIFIED', { requiresVerification: true, email: user.email });
                }
                return sendError(res, "Please verify your email before logging in. After verification, your registration will be reviewed by your Head of Department.", 401, 'EMAIL_NOT_VERIFIED', { requiresVerification: true, email: user.email });
            }
            if (user.role === 'SUPERVISOR') {
                return sendError(res, "Your registration is pending administrator approval. You will receive an email once your company credentials are reviewed.", 401, 'PENDING_ADMIN_REVIEW', { email: user.email });
            }
            return sendError(res, "Please verify your email before logging in", 401, 'EMAIL_NOT_VERIFIED', { requiresVerification: true, email: user.email });
        }

        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            console.warn(`[Security] Failed login attempt for user: ${email}`);
            // If we wanted to track multiple failures, we'd do it here.
            return sendError(res, 'Invalid email or password. Please try again.', 401);
        }

        // Institution verification (SRS): org must be admin-approved; coordinators/supervisors also need individual admin approval
        if (user.role === 'COORDINATOR') {
            const profile = user.coordinatorProfile;
            // Coordinator hasn't been approved yet (no university linked)
            if (!profile?.universityId) {
                return sendError(res, 'Your coordinator account is pending administrator approval. You will receive an email once approved.', 403, 'PENDING_ADMIN_REVIEW');
            }
            const uni = profile?.university;
            if (!uni) {
                return sendError(res, 'No university profile is linked to this account. Contact support.', 403, 'NO_INSTITUTION_PROFILE');
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
                return sendError(res, 'Your university’s verification proposal must be submitted and approved by an administrator before you can access the system.', 403, 'INSTITUTION_NOT_APPROVED');
            }
            if (user.institution_access_approval !== 'APPROVED') {
                return sendError(res, 'Your coordinator account must be individually approved by an administrator after your organization is verified.', 403, 'INSTITUTION_MEMBER_NOT_APPROVED');
            }
        }

        if (user.role === 'SUPERVISOR') {
            const company = user.supervisorProfile?.company;
            if (!company) {
                return sendError(res, 'No company profile is linked to this account. Contact support.', 403, 'NO_INSTITUTION_PROFILE');
            }
            if (company.approval_status === 'SUSPENDED') {
                return sendError(res, 'This company organization has been suspended by an administrator. Contact support for assistance.', 403, 'INSTITUTION_SUSPENDED');
            }
            if (company.approval_status !== 'APPROVED') {
                return sendError(res, 'Your company’s verification proposal must be submitted and approved by an administrator before you can access the system.', 403, 'INSTITUTION_NOT_APPROVED');
            }
            if (user.institution_access_approval !== 'APPROVED') {
                return sendError(res, 'Your supervisor account must be individually approved by an administrator after your organization is verified.', 403, 'INSTITUTION_MEMBER_NOT_APPROVED');
            }
        }

        if (user.role === 'HOD') {
            const profile = user.hodProfile;
            const uni = profile?.university;
            if (!profile) {
                return sendError(res, 'Your HoD profile is incomplete. Please re-register or contact support.', 403, 'NO_INSTITUTION_PROFILE');
            }
            if (!uni) {
                return sendError(res, 'No university is linked to your HoD account. Contact support.', 403, 'NO_INSTITUTION_PROFILE');
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
                return sendError(res, 'Your university must be verified by an administrator before you can access the system.', 403, 'INSTITUTION_NOT_APPROVED');
            }
            if (user.institution_access_approval !== 'APPROVED') {
                return sendError(res, 'Your HOD account is pending approval from your university coordinator.', 403, 'INSTITUTION_MEMBER_NOT_APPROVED');
            }
        }

        if (user.role === 'STUDENT') {
            const uni = user.studentProfile?.university;
            if (uni && uni.approval_status === 'SUSPENDED') {
                return sendError(res, 'Your university organization has been suspended by an administrator. Contact support for assistance.', 403, 'INSTITUTION_SUSPENDED');
            }
            if (uni && uni.approval_status !== 'APPROVED') {
                return sendError(res, 'Your university account is not active yet. Verification must be submitted and approved by an administrator before you can sign in.', 403, 'INSTITUTION_NOT_APPROVED');
            }
            const sp = user.studentProfile;
            if (sp && sp.hod_approval_status !== 'APPROVED') {
                return sendError(res, sp.hod_approval_status === 'REJECTED'
                    ? 'Your registration was not approved by your Head of Department. Contact your department for assistance.'
                    : 'Your registration is pending approval from your Head of Department.', 403, 'HOD_APPROVAL_PENDING');
            }
        }

        // Generate JWT
        const token = jwt.sign(
            { userId: user.id, role: user.role, email: user.email },
            getJwtSecret(),
            // { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
            { expiresIn: '7d' } as jwt.SignOptions
        );

        if (user.role === Role.STUDENT) {
            // Activity is tracked on meaningful actions (plan submissions, check-ins) — not on login
        }

        return sendSuccess(res, {
            token,
            user: {
                id: user.id,
                email: user.email,
                fullName: user.full_name,
                role: user.role,
                isVerified: user.verification_status === 'APPROVED',
                institutionAccessApproval: user.institution_access_approval,
                hodApprovalStatus: user.role === 'STUDENT' ? user.studentProfile?.hod_approval_status : undefined,
            }
        }, "Login successful");
        
    } catch (error: any) {
        console.error('[Login Error]', error.message);
        return sendError(res, 'Something went wrong. Please try again later.', 500);
    }
};

// ============================================
// VERIFY EMAIL - New Endpoint
// ============================================
export const verifyEmail = async (req: Request, res: Response) => {
    try {
        const { token } = req.body;

        if (!token) {
            return sendError(res, "Verification token is required", 400);
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
            return sendError(res, "Invalid or expired verification token. Please request a new one.", 400);
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

        return sendSuccess(res, null, "Email verified successfully. You can now login.");

    } catch (error: any) {
        console.error('Verification error:', error);
        return sendError(res, error.message, 500);
    }
};

// ============================================
// RESEND VERIFICATION EMAIL - New Endpoint
// ============================================
export const resendVerification = async (req: Request, res: Response) => {
    try {
        const { email } = req.body;

        if (!email) {
            return sendError(res, "Email is required", 400);
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
            return sendError(res, "Email is already verified", 400);
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
            await sendVerificationEmail(email, verificationToken, user.role);
        } catch (err: any) {
            console.error('Email resend error:', err);
            return sendError(res, "Failed to resend verification email. Please check your email settings or contact support.", 500);
        }

        return sendSuccess(res, null, "Verification email resent successfully");

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
            return sendError(res, "User not found", 404);
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

        return sendSuccess(res, {
            token: process.env.NODE_ENV === 'development' ? resetToken : undefined
        }, "Password reset email sent");
        
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ============================================
// RESET PASSWORD - Verifies Token & Updates Password
// ============================================
export const resetPassword = async (req: Request, res: Response) => {
    try {
        const { token, newPassword } = req.body;

        if (!token || !newPassword) {
            return sendError(res, "Token and new password are required", 400);
        }

        // Find user with this token and check if token is still valid
        const user = await prisma.user.findFirst({
            where: {
                reset_password_token: token,
                reset_password_expires: { gt: new Date() }
            }
        });

        if (!user) {
            return sendError(res, "Invalid or expired token", 400);
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

        return sendSuccess(res, null, "Password has been reset successfully");
        
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ============================================
// GET CURRENT USER - Protected Route
// ============================================
export const getCurrentUser = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.userId;
        
        if (!userId) {
            return sendError(res, "Unauthorized", 401);
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
                hodProfile: {
                    include: { university: true }
                },
                supervisorProfile: {
                    include: { company: true }
                }
            }
        });

        if (!user) {
            return sendError(res, "User not found", 404);
        }

        // Build role-specific profile fields
        let roleProfile: Record<string, any> = {};
        if (user.role === 'STUDENT' && user.studentProfile) {
            roleProfile = {
                studentId: user.studentProfile.studentId,
                department: user.studentProfile.department,
                universityName: user.studentProfile.university?.name,
            };
        } else if (user.role === 'SUPERVISOR' && user.supervisorProfile) {
            roleProfile = {
                phoneNumber: user.supervisorProfile.phone_number,
                companyName: user.supervisorProfile.company?.name,
            };
        } else if (user.role === 'COORDINATOR' && user.coordinatorProfile) {
            roleProfile = {
                phoneNumber: user.coordinatorProfile.phone_number,
                universityName: user.coordinatorProfile.university?.name,
            };
        } else if (user.role === 'HOD' && user.hodProfile) {
            roleProfile = {
                phoneNumber: user.hodProfile.phone_number,
                department: user.hodProfile.department,
                universityName: user.hodProfile.university?.name,
            };
        }

        return sendSuccess(res, {
            id: user.id,
            email: user.email,
            fullName: user.full_name,
            role: user.role,
            isVerified: user.verification_status === 'APPROVED',
            institutionAccessApproval: user.institution_access_approval,
            profile: roleProfile,
        }, "User profile fetched");

    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ============================================
// UPDATE CURRENT USER PROFILE - Protected Route
// ============================================
export const updateCurrentUser = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.userId;
        if (!userId) {
            return sendError(res, "Unauthorized", 401);
        }

        const body = (req.body ?? {}) as Record<string, unknown>;
        const rawFullName = (body['fullName'] ?? body['full_name'] ?? '').toString().trim();
        const rawEmail = (body['email'] ?? '').toString().trim().toLowerCase();

        // Role-specific fields
        const rawPhoneNumber = (body['phoneNumber'] ?? body['phone_number'] ?? '').toString().trim();
        const rawDepartment = (body['department'] ?? '').toString().trim();
        const rawStudentId = (body['studentId'] ?? body['student_id'] ?? '').toString().trim();

        const existing = await prisma.user.findUnique({ where: { id: userId } });
        if (!existing) {
            return sendError(res, "User not found", 404);
        }

        if (!rawFullName && !rawEmail && !rawPhoneNumber && !rawDepartment && !rawStudentId) {
            return sendError(res, "Please provide at least one field to update.", 400);
        }

        if (rawEmail && rawEmail !== existing.email) {
            const emailTaken = await prisma.user.findUnique({ where: { email: rawEmail } });
            if (emailTaken && emailTaken.id !== userId) {
                return sendError(res, "Email is already in use.", 400);
            }
        }

        // Update shared User fields
        const updated = await prisma.user.update({
            where: { id: userId },
            data: {
                ...(rawFullName ? { full_name: rawFullName } : {}),
                ...(rawEmail ? { email: rawEmail } : {}),
            },
        });

        // Update role-specific profile fields
        if (existing.role === 'STUDENT') {
            await prisma.student.updateMany({
                where: { userId },
                data: {
                    ...(rawDepartment ? { department: rawDepartment } : {}),
                    ...(rawStudentId ? { studentId: rawStudentId } : {}),
                },
            });
        } else if (existing.role === 'SUPERVISOR') {
            await prisma.supervisor.updateMany({
                where: { userId },
                data: {
                    ...(rawPhoneNumber ? { phone_number: rawPhoneNumber } : {}),
                },
            });
        } else if (existing.role === 'COORDINATOR') {
            await prisma.coordinator.updateMany({
                where: { userId },
                data: {
                    ...(rawPhoneNumber ? { phone_number: rawPhoneNumber } : {}),
                },
            });
        } else if (existing.role === 'HOD') {
            await prisma.hodProfile.updateMany({
                where: { userId },
                data: {
                    ...(rawPhoneNumber ? { phone_number: rawPhoneNumber } : {}),
                    ...(rawDepartment ? { department: rawDepartment } : {}),
                },
            });
        }

        // Re-fetch role-specific profile to return updated data
        let roleProfile: Record<string, any> = {};
        if (existing.role === 'STUDENT') {
            const sp = await prisma.student.findUnique({ where: { userId }, include: { university: true } });
            if (sp) roleProfile = { studentId: sp.studentId, department: sp.department, universityName: sp.university?.name };
        } else if (existing.role === 'SUPERVISOR') {
            const sv = await prisma.supervisor.findUnique({ where: { userId }, include: { company: true } });
            if (sv) roleProfile = { phoneNumber: sv.phone_number, companyName: sv.company?.name };
        } else if (existing.role === 'COORDINATOR') {
            const co = await prisma.coordinator.findUnique({ where: { userId }, include: { university: true } });
            if (co) roleProfile = { phoneNumber: co.phone_number, universityName: co.university?.name };
        } else if (existing.role === 'HOD') {
            const hod = await prisma.hodProfile.findUnique({ where: { userId }, include: { university: true } });
            if (hod) roleProfile = { phoneNumber: hod.phone_number, department: hod.department, universityName: hod.university?.name };
        }

        return sendSuccess(res, {
            id: updated.id,
            email: updated.email,
            fullName: updated.full_name,
            role: updated.role,
            profile: roleProfile,
        }, "Profile updated successfully.");
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};

// ============================================
// CHANGE PASSWORD - Protected Route
// ============================================
export const changePassword = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.userId;
        if (!userId) {
            return sendError(res, "Unauthorized", 401);
        }

        const { currentPassword, newPassword } = req.body as {
            currentPassword?: string;
            newPassword?: string;
        };

        if (!currentPassword || !newPassword) {
            return sendError(res, "Current password and new password are required.", 400);
        }

        if (newPassword.length < 8) {
            return sendError(res, "New password must be at least 8 characters long.", 400);
        }

        const user = await prisma.user.findUnique({ where: { id: userId } });
        if (!user) {
            return sendError(res, "User not found", 404);
        }

        const matches = await bcrypt.compare(currentPassword, user.password_hash);
        if (!matches) {
            return sendError(res, "Current password is incorrect.", 400);
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await prisma.user.update({
            where: { id: userId },
            data: {
                password_hash: hashedPassword,
            },
        });

        return sendSuccess(res, null, "Password changed successfully.");
    } catch (error: any) {
        return sendError(res, error.message, 500);
    }
};
