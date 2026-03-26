import prisma from '../config/db';

export const sendNotification = async (userId: number, message: string) => {
    return await prisma.notification.create({
        data: {
            recipientId: userId,
            message,
            is_read: false
        }
    });
};