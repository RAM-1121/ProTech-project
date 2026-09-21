import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { PlansService } from './plans.service';

@Controller('plans')
export class PlansController {
  constructor(private readonly plansService: PlansService) {}

  // --- Plans ---
  @Get()
  findAllPlans() {
    return this.plansService.findAllPlans();
  }

  @Post()
  createPlan(@Body() data: any) {
    return this.plansService.createPlan(data);
  }

  @Patch(':id')
  updatePlan(@Param('id') id: string, @Body() data: any) {
    return this.plansService.updatePlan(id, data);
  }

  @Delete(':id')
  removePlan(@Param('id') id: string) {
    return this.plansService.removePlan(id);
  }

  // --- Coupons ---
  @Get('coupons')
  findAllCoupons() {
    return this.plansService.findAllCoupons();
  }

  @Post('coupons')
  createCoupon(@Body() data: any) {
    return this.plansService.createCoupon(data);
  }

  @Patch('coupons/:id')
  updateCoupon(@Param('id') id: string, @Body() data: any) {
    return this.plansService.updateCoupon(id, data);
  }

  @Delete('coupons/:id')
  removeCoupon(@Param('id') id: string) {
    return this.plansService.removeCoupon(id);
  }
}
