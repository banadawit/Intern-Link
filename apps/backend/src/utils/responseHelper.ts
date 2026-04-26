import { Response } from 'express';

export const sendSuccess = (res: Response, data: any, message: string = 'Success', statusCode: number = 200) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data
    });
};

export const sendError = (res: Response, message: string = 'Internal Server Error', statusCode: number = 500, code?: string, details?: any) => {
    return res.status(statusCode).json({
        success: false,
        message,
        code,
        details,
        // For legacy compatibility if any code uses .error
        error: process.env.NODE_ENV === 'development' ? (details || code) : undefined
    });
};
