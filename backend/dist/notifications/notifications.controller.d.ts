import { NotificationsService } from './notifications.service';
export declare class NotificationsController {
    private readonly notificationsService;
    constructor(notificationsService: NotificationsService);
    sendPush(dto: {
        userId: string;
        title: string;
        body: string;
    }): Promise<{
        success: boolean;
        message: string;
    }>;
}
