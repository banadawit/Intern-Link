// src/routes/authRoutes.ts
import { Router } from 'express';
import { 
    register, 
    login, 
    forgotPassword, 
    resetPassword,
    verifyEmail,
    resendVerification,
    getCurrentUser,
    updateCurrentUser,
    changePassword
} from '../controllers/authController';
import { sendSetupLink } from '../controllers/adminOnboardingController';
import { authenticate, authorize } from '../middlewares/authMiddleware';
import { Role } from '@prisma/client';
import { uploadVerificationDocument } from '../config/multer.config';

import { validate } from '../middlewares/validationMiddleware';
import { registerSchema, loginSchema } from '../validations/authValidation';

const router = Router();

// ============================================
// PUBLIC ROUTES (No authentication required)
// ============================================

// Registration (no multer needed now as frontend uploads directly to Cloudinary)
router.post('/register', register);

// Login
router.post('/login', validate(loginSchema), login);

// Email Verification
router.post('/verify-email', verifyEmail);
router.post('/resend-verification', resendVerification);

// Password Reset / Setup
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// ============================================
// PROTECTED ROUTES (Authentication required)
// ============================================

// Get current user info
router.get('/me', authenticate, getCurrentUser);
router.patch('/me', authenticate, updateCurrentUser);
router.post('/change-password', authenticate, changePassword);

// Admin: send password setup link to a user
router.post('/send-setup-link', authenticate, authorize([Role.ADMIN]), sendSetupLink);

// Logout (client-side token removal, but can add blacklist if needed)
router.post('/logout', authenticate, (req, res) => {
    res.json({ success: true, message: 'Logged out successfully' });
});

export default router;