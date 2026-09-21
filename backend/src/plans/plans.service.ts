import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Plan } from './entities/plan.entity';
import { Coupon } from './entities/coupon.entity';

@Injectable()
export class PlansService {
  constructor(
    @InjectRepository(Plan)
    private readonly plansRepository: Repository<Plan>,
    @InjectRepository(Coupon)
    private readonly couponsRepository: Repository<Coupon>,
  ) {}

  // --- Plans ---
  async findAllPlans(): Promise<Plan[]> {
    return this.plansRepository.find();
  }

  async findPlanById(id: string): Promise<Plan> {
    const plan = await this.plansRepository.findOne({ where: { id } });
    if (!plan) throw new NotFoundException('Plan not found');
    return plan;
  }

  async createPlan(data: Partial<Plan>): Promise<Plan> {
    const plan = this.plansRepository.create(data);
    return this.plansRepository.save(plan);
  }

  async updatePlan(id: string, data: Partial<Plan>): Promise<Plan> {
    const plan = await this.findPlanById(id);
    Object.assign(plan, data);
    return this.plansRepository.save(plan);
  }

  async removePlan(id: string): Promise<void> {
    const plan = await this.findPlanById(id);
    await this.plansRepository.remove(plan);
  }

  // --- Coupons ---
  async findAllCoupons(): Promise<Coupon[]> {
    return this.couponsRepository.find();
  }

  async findCouponById(id: string): Promise<Coupon> {
    const coupon = await this.couponsRepository.findOne({ where: { id } });
    if (!coupon) throw new NotFoundException('Coupon not found');
    return coupon;
  }

  async createCoupon(data: Partial<Coupon>): Promise<Coupon> {
    const coupon = this.couponsRepository.create(data);
    return this.couponsRepository.save(coupon);
  }

  async updateCoupon(id: string, data: Partial<Coupon>): Promise<Coupon> {
    const coupon = await this.findCouponById(id);
    Object.assign(coupon, data);
    return this.couponsRepository.save(coupon);
  }

  async removeCoupon(id: string): Promise<void> {
    const coupon = await this.findCouponById(id);
    await this.couponsRepository.remove(coupon);
  }
}
