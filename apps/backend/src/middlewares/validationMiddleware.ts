import { Request, Response, NextFunction } from 'express';
import { AnyZodObject, ZodError } from 'zod';
import { sendError } from '../utils/responseHelper';

export const validate = (schema: AnyZodObject) => {
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
                const message = error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join(', ');
                return sendError(res, `Validation Error: ${message}`, 400);
            }
            return sendError(res, 'Internal Validation Error', 500);
        }
    };
};
