import { z } from 'zod';

export const evaluationSchema = z.object({
    body: z.object({
        studentId: z.number(),
        technical_skills: z.number().min(0).max(100),
        problem_solving: z.number().min(0).max(100),
        communication: z.number().min(0).max(100),
        team_collaboration: z.number().min(0).max(100),
        time_management: z.number().min(0).max(100),
        adaptability: z.number().min(0).max(100),
        professionalism: z.number().min(0).max(100),
        initiative_creativity: z.number().min(0).max(100),
        attendance_punctuality: z.number().min(0).max(100),
        task_completion_quality: z.number().min(0).max(100),
        comments: z.string().optional(),
    })
});

export const teamSchema = z.object({
    body: z.object({
        name: z.string().min(3, "Team name must be at least 3 characters"),
    })
});
