export declare class NotificationsService {
    sendPushNotification(userId: string, title: string, body: string): Promise<{
        success: boolean;
        message: string;
    }>;
}
