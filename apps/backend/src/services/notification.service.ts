import prisma from '../config/db';

export enum NotificationType {
    PLAN_APPROVED = 'PLAN_APPROVED',
    PLAN_REJECTED = 'PLAN_REJECTED',
    NEW_PROPOSAL = 'NEW_PROPOSAL',
    PROPOSAL_RESPONDED = 'PROPOSAL_RESPONDED',
    ADMIN_ALERT = 'ADMIN_ALERT',
    SECURITY_ALERT = 'SECURITY_ALERT',
    SYSTEM_ALERT = 'SYSTEM_ALERT',
    GENERAL = 'GENERAL'
}

export const createNotification = async (recipientId: number, message: string, type: NotificationType = NotificationType.GENERAL) => {
    try {
        const notification = await prisma.notification.create({
            data: {
                recipientId,
                message,
                is_read: false,
                // If we added a 'type' column to the schema, we'd use it here. 
                // For now, we'll prefix the message if it's an alert.
            }
        });
        
        console.log(`[Notification] To User ${recipientId} (${type}): ${message}`);
        return notification;
    } catch (error) {
        console.error('Failed to create notification:', error);
    }
};

export const notifyAllAdmins = async (message: string, type: NotificationType = NotificationType.ADMIN_ALERT) => {
    try {
        const admins = await prisma.user.findMany({
            where: { role: 'ADMIN' },
            select: { id: true }
        });

        const notifications = await Promise.all(admins.map(admin => 
            createNotification(admin.id, `[${type}] ${message}`, type)
        ));

        return notifications;
    } catch (error) {
        console.error('Failed to notify admins:', error);
    }
};

export const notifyStudentPlanReview = async (studentUserId: number, weekNumber: number, status: string) => {
    const message = status === 'APPROVED' 
        ? `Your weekly plan for Week ${weekNumber} has been approved!` 
        : `Your weekly plan for Week ${weekNumber} was rejected. Please check feedback and resubmit.`;
    
    return createNotification(studentUserId, message);
};
