import { z } from 'zod';

export const evaluationSchema = z.object({
    body: z.object({
        studentId: z.number(),
        technical_score: z.number().min(0).max(100),
        soft_skill_score: z.number().min(0).max(100),
        comments: z.string().min(5, "Comments must be at least 5 characters"),
    })
});

export const teamSchema = z.object({
    body: z.object({
        name: z.string().min(3, "Team name must be at least 3 characters"),
    })
});
