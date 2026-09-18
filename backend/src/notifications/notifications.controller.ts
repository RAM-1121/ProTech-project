import { Controller, Post, Body } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post('send')
  sendPush(@Body() dto: { userId: string, title: string, body: string }) {
    return this.notificationsService.sendPushNotification(dto.userId, dto.title, dto.body);
  }
}
