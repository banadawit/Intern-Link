// src/routes/authRoutes.ts
import { Router } from 'express';
import { 
    register, 
    login, 
    forgotPassword, 
    resetPassword,
    verifyEmail,
    resendVerification,
    getCurrentUser
} from '../controllers/authController';
import { authenticate } from '../middlewares/authMiddleware';
import { uploadVerificationDocument } from '../config/multer.config';

const router = Router();

// ============================================
// PUBLIC ROUTES (No authentication required)
// ============================================

// Registration with file upload
router.post('/register', uploadVerificationDocument, register);

// Login
router.post('/login', login);

// Email Verification
router.post('/verify-email', verifyEmail);
router.post('/resend-verification', resendVerification);

// Password Reset
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// ============================================
// PROTECTED ROUTES (Authentication required)
// ============================================

// Get current user info
router.get('/me', authenticate, getCurrentUser);

// Logout (client-side token removal, but can add blacklist if needed)
router.post('/logout', authenticate, (req, res) => {
    res.json({ success: true, message: 'Logged out successfully' });
});

export default router;