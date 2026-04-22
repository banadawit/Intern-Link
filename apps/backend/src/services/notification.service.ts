import prisma from '../config/db';

export enum NotificationType {
    PLAN_APPROVED = 'PLAN_APPROVED',
    PLAN_REJECTED = 'PLAN_REJECTED',
    NEW_PROPOSAL = 'NEW_PROPOSAL',
    PROPOSAL_RESPONDED = 'PROPOSAL_RESPONDED',
    GENERAL = 'GENERAL'
}

export const createNotification = async (recipientId: number, message: string) => {
    try {
        const notification = await prisma.notification.create({
            data: {
                recipientId,
                message,
                is_read: false,
            }
        });
        
        // In a real app, you would trigger a push notification here (FCM/Socket.io)
        console.log(`[Notification] To User ${recipientId}: ${message}`);
        
        return notification;
    } catch (error) {
        console.error('Failed to create notification:', error);
    }
};

export const notifyStudentPlanReview = async (studentUserId: number, weekNumber: number, status: string) => {
    const message = status === 'APPROVED' 
        ? `Your weekly plan for Week ${weekNumber} has been approved!` 
        : `Your weekly plan for Week ${weekNumber} was rejected. Please check feedback and resubmit.`;
    
    return createNotification(studentUserId, message);
};
