// src/routes/authRoutes.ts
import { Router } from 'express';
import { register, login, forgotPassword, resetPassword } from '../controllers/authController';

const router = Router();

// Endpoint: POST /api/auth/register
router.post('/register', register);

// Endpoint: POST /api/auth/login
router.post('/login', login);

router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
export default router;