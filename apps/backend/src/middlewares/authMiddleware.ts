import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { Role } from '@prisma/client';

// Custom interface to extend Express Request
export interface AuthRequest extends Request {

    user?: {
        userId: number;
        role: Role;
    };
}

export const authorize = (allowedRoles: Role[]) => {
    return (req: AuthRequest, res: Response, next: NextFunction) => {
        const token = req.headers.authorization?.split(" ")[1];
        if (!token) return res.status(401).json({ message: "Access Denied" });

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as any;
            req.user = decoded;

            if (allowedRoles.length > 0 && !allowedRoles.includes(req.user?.role as Role)) {
                return res.status(403).json({ message: "Forbidden: Access Denied" });
            }

            next();
        } catch (err) {
            res.status(401).json({ message: "Invalid Token" });
        }
    };
};