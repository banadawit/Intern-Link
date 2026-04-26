import { Request, Response, NextFunction } from 'express';
import { sendError } from '../utils/responseHelper';

export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
    console.error(`[Error Handler]: ${err.message}`);
    console.error(err.stack);

    const statusCode = err.statusCode || 500;
    const message = err.message || 'Something went wrong on the server.';

    return sendError(res, message, statusCode, err);
};
