import { Injectable } from '@nestjs/common';

@Injectable()
export class NotificationsService {
  async sendPushNotification(userId: string, title: string, body: string) {
    // Mocked implementation for FCM/APNs
    console.log(`[MOCK PUSH] To: ${userId} | Title: ${title} | Body: ${body}`);
    return { success: true, message: 'Push notification queued (mocked)' };
  }
}
