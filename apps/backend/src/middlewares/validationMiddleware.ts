import { Request, Response, NextFunction } from 'express';
import { ZodTypeAny, ZodError } from 'zod';
import { sendError } from '../utils/responseHelper';

export const validate = (schema: ZodTypeAny) => {
    return async (req: Request, res: Response, next: NextFunction) => {
        try {
            await schema.parseAsync({
                body: req.body,
                query: req.query,
                params: req.params,
            });
            return next();
        } catch (error) {
            if (error instanceof ZodError) {
                const message = error.issues.map((issue) => `${issue.path.join('.')}: ${issue.message}`).join(', ');
                return sendError(res, `Validation Error: ${message}`, 400);
            }
            return sendError(res, 'Internal Validation Error', 500);
        }
    };
};
