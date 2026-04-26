import { z } from 'zod';

export const registerSchema = z.object({
    body: z.object({
        full_name: z.string().min(3, "Full name must be at least 3 characters"),
        email: z.string().email("Invalid email address"),
        password: z.string().min(8, "Password must be at least 8 characters"),
        role: z.enum(['STUDENT', 'SUPERVISOR', 'HOD', 'COORDINATOR']),
        universityId: z.number().optional(),
        department: z.string().optional(),
        companyId: z.number().optional(),
        location: z.string().optional(),
    })
});

export const loginSchema = z.object({
    body: z.object({
        email: z.string().email("Invalid email address"),
        password: z.string().min(1, "Password is required"),
    })
});
