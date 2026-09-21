import { Controller, Get, Patch, Body, Param, Headers, UnauthorizedException, Logger } from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { UsersService } from '../users/users.service';
import { PlansService } from '../plans/plans.service';

@Controller('executive/tasks')
export class ExecutiveTasksController {
  private readonly logger = new Logger(ExecutiveTasksController.name);

  constructor(
    private readonly bookingsService: BookingsService,
    private readonly usersService: UsersService,
    private readonly plansService: PlansService,
  ) {}

  private extractEmployeeId(authHeader: string): string {
    if (!authHeader || !authHeader.startsWith('Bearer mock-jwt-token-executive-')) {
      throw new UnauthorizedException('Invalid executive token');
    }
    return authHeader.replace('Bearer mock-jwt-token-executive-', '');
  }

  @Get()
  getExecutiveTasks(@Headers('authorization') auth: string) {
    const employeeId = this.extractEmployeeId(auth);
    // Return all active and historical tasks assigned to this employee
    return this.bookingsService.findAll().filter(b => 
      b.assignedEmployee && b.assignedEmployee.id === employeeId
    );
  }

  @Patch(':id/status')
  async updateTaskStatus(
    @Param('id') id: string,
    @Body('status') status: string,
    @Body('finalBill') finalBill: string,
    @Body('pendingReason') pendingReason: string,
    @Body('planId') planId: string,
    @Body('couponId') couponId: string,
    @Headers('authorization') auth: string
  ) {
    const employeeId = this.extractEmployeeId(auth);
    const booking = this.bookingsService.findOne(id);
    if (!booking) {
      throw new Error('Booking not found');
    }
    if (!booking.assignedEmployee || booking.assignedEmployee.id !== employeeId) {
      throw new UnauthorizedException('Task is not assigned to you');
    }
    
    if (finalBill !== undefined && finalBill !== '') {
      booking.finalBill = finalBill;
    }
    
    let pointsToAward = 50; // Fallback default
    if (planId) {
      try {
        const plan = await this.plansService.findPlanById(planId);
        if (plan) {
          booking.planId = plan.id;
          booking.planName = plan.name;
          if (plan.rewardPoints) {
            const points = parseInt(plan.rewardPoints.toString(), 10);
            if (!isNaN(points)) {
              pointsToAward = points;
              booking.rewardPoints = pointsToAward;
            }
          }
        }
      } catch (e) {
        this.logger.error(`Could not fetch plan ${planId} for reward points`, e);
      }
    } else if (booking.rewardPoints) {
      pointsToAward = booking.rewardPoints;
    }

    if (couponId) {
      try {
        const coupon = await this.plansService.findCouponById(couponId);
        if (coupon) {
          booking.couponId = coupon.id;
          booking.couponCode = coupon.code;
        }
      } catch (e) {
        this.logger.error(`Could not fetch coupon ${couponId}`, e);
      }
    }

    if (status === 'Completed' || status === 'completed' || status === 'Complaint Closed Thank You For choosing Protech Cooling Solutions') {
      this.usersService.awardPoints(employeeId, pointsToAward, 'Task Completed - #' + id.substring(0, 8)).catch(e => console.error('Error awarding points:', e));
    }
    
    return this.bookingsService.updateStatus(id, status, undefined, pendingReason);
  }
}
