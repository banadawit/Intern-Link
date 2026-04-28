import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Role } from '@prisma/client';

const getJwtSecret = (): string => {
    const secret = (process.env.JWT_SECRET || '').trim();
    if (secret) return secret;
    if (process.env.NODE_ENV !== 'production') {
        return 'dev_jwt_secret_change_me';
    }
    throw new Error('JWT_SECRET is not configured');
};

// Custom interface to extend Express Request
export interface AuthRequest extends Request {
    user?: {
        userId: number;
        role: Role;
        email?: string;
    };
}

/**
 * Authenticate middleware - Verifies JWT token and attaches user to request
 * Use for any route that requires authentication
 */
export const authenticate = (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ 
                success: false,
                message: 'Access denied. No token provided.' 
            });
        }

        const token = authHeader.split(' ')[1];
        
        const decoded = jwt.verify(token, getJwtSecret()) as {
            userId: number;
            role: Role;
            email: string;
        };
        
        req.user = decoded;
        next();
        
    } catch (error) {
        if (error instanceof jwt.TokenExpiredError) {
            return res.status(401).json({ 
                success: false,
                message: 'Token expired. Please login again.' 
            });
        }
        
        return res.status(401).json({ 
            success: false,
            message: 'Invalid token.' 
        });
    }
};

/**
 * Authorize middleware - Checks if user has required roles
 * Use after authenticate middleware
 */
export const authorize = (allowedRoles: Role[]) => {
    return (req: AuthRequest, res: Response, next: NextFunction) => {
        if (!req.user) {
            return res.status(401).json({ 
                success: false,
                message: 'Unauthorized. Please login first.' 
            });
        }

        if (allowedRoles.length > 0 && !allowedRoles.includes(req.user.role)) {
            return res.status(403).json({ 
                success: false,
                message: 'Forbidden. You do not have permission to access this resource.' 
            });
        }

        next();
    };
};

/**
 * Optional: Check if user is authenticated (for routes that allow both)
 */
export const optionalAuth = (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
        const authHeader = req.headers.authorization;
        
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            const decoded = jwt.verify(token, getJwtSecret()) as {
                userId: number;
                role: Role;
                email: string;
            };
            req.user = decoded;
        }
        next();
    } catch {
        next(); // Continue without user
    }
};