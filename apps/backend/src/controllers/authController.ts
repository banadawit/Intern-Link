import { Request, Response } from 'express';
import prisma from '../config/db';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
export const register = async (req: Request, res: Response) => {
    try {
        const { full_name, email, password, role } = req.body;

        const userExists = await prisma.user.findUnique({ where: { email } });
        if (userExists) return res.status(400).json({ message: "Email already exists" });

        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = await prisma.user.create({
            data: {
                full_name,
                email,
                password_hash: hashedPassword,
                role, // Prisma checks if this is a valid Role enum
                verification_status: 'PENDING'
            }
        });

        res.status(201).json({ message: "Registration successful. Pending admin approval." });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const login = async (req: Request, res: Response) => {
    try {
        const { email, password } = req.body;

        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) return res.status(404).json({ message: "User not found" });

        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

        // Generate JWT with User ID and Role
        const token = jwt.sign(
            { userId: user.id, role: user.role },
            process.env.JWT_SECRET as string,
            { expiresIn: '1h' }
        );

        res.json({ token, role: user.role });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};


// 1. Forgot Password - Generates Token
export const forgotPassword = async (req: Request, res: Response) => {
    try {
        const { email } = req.body;
        const user = await prisma.user.findUnique({ where: { email } });

        if (!user) return res.status(404).json({ message: "User not found" });

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

        // IN REALITY: Send an email here. 
        // FOR TESTING: We return the token in the response so you can test it.
        res.json({ message: "Password reset token generated", token: resetToken });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

// 2. Reset Password - Verifies Token & Updates Password
export const resetPassword = async (req: Request, res: Response) => {
    try {
        const { token, newPassword } = req.body;

        // Find user with this token and check if token is still valid (not expired)
        const user = await prisma.user.findFirst({
            where: {
                reset_password_token: token,
                reset_password_expires: { gt: new Date() } // "gt" means greater than now
            }
        });

        if (!user) return res.status(400).json({ message: "Invalid or expired token" });

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

        res.json({ message: "Password has been reset successfully" });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};