import { Module } from '@nestjs/common';
import { BookingsController } from './bookings.controller';
import { ExecutiveTasksController } from './executive-tasks.controller';
import { BookingsService } from './bookings.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { UsersModule } from '../users/users.module';
import { PlansModule } from '../plans/plans.module';

@Module({
  imports: [NotificationsModule, UsersModule, PlansModule],
  controllers: [BookingsController, ExecutiveTasksController],
  providers: [BookingsService]
})
export class BookingsModule {}
