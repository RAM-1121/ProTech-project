import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
import { NotificationsGateway } from '../notifications/notifications.gateway';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private readonly notificationsGateway: NotificationsGateway,
  ) {}

  async updateLocation(userId: string, lat: number, lng: number): Promise<void> {
    await this.usersRepository.update(userId, {
      currentLocation: {
        type: 'Point',
        coordinates: [lng, lat], // GeoJSON is [longitude, latitude]
      },
    });
  }

  async findNearestExecutives(lat: number, lng: number, radiusMeters: number): Promise<User[]> {
    // For local SQLite testing, just return all executives since ST_DWithin is PostGIS specific
    return this.usersRepository.find({
      where: { role: UserRole.EXECUTIVE }
    });
  }


  
  async getWalletDetails(employeeId: string) {
    const user = await this.usersRepository.findOne({ where: { employeeId } });
    if (!user) {
      throw new Error('User not found');
    }
    return {
      rewardPoints: user.rewardPoints || 0,
      rewardTransactions: user.rewardTransactions || [],
    };
  }

  async awardPoints(employeeId: string, amount: number, title: string) {
    const user = await this.usersRepository.findOne({ where: { employeeId } });
    if (!user) return;
    
    const currentPoints = user.rewardPoints || 0;
    const transactions = user.rewardTransactions || [];
    
    transactions.unshift({
      title,
      date: new Date().toISOString(),
      amount,
      type: 'earn'
    });
    
    await this.usersRepository.update(user.id, {
      rewardPoints: currentPoints + amount,
      rewardTransactions: transactions
    });
  }

  async redeemPoints(employeeId: string, amount: number) {
    const user = await this.usersRepository.findOne({ where: { employeeId } });
    if (!user) {
      throw new Error('User not found');
    }
    
    const currentPoints = user.rewardPoints || 0;
    if (amount > currentPoints || amount <= 0) {
      throw new Error('Invalid redemption amount');
    }
    
    const transactions = user.rewardTransactions || [];
    transactions.unshift({
      title: 'Redeemed Points',
      date: new Date().toISOString(),
      amount,
      type: 'redeem'
    });
    
    await this.usersRepository.update(user.id, {
      rewardPoints: currentPoints - amount,
      rewardTransactions: transactions
    });
    
    return { success: true, remaining: currentPoints - amount };
  }

  async rejectRedemption(employeeId: string, amount: number) {
    const user = await this.usersRepository.findOne({ where: { employeeId } });
    if (!user) {
      throw new Error('User not found');
    }
    
    const transactions = user.rewardTransactions || [];
    transactions.unshift({
      title: 'Redemption Rejected',
      date: new Date().toISOString(),
      amount,
      type: 'rejected'
    });
    
    await this.usersRepository.update(user.id, {
      rewardTransactions: transactions
    });
    
    return { success: true };
  }


  private async checkAndExpireLeave(user: User): Promise<User> {
    if (user.status === 'On Leave' && user.leaveEndDate) {
      const now = new Date();
      now.setHours(0, 0, 0, 0); // Consider end of day or just current time
      const endDate = new Date(user.leaveEndDate);
      // if today is strictly greater than endDate (i.e. endDate has passed)
      if (now.getTime() > endDate.getTime()) {
        user.status = 'Offline';
        user.leaveStartDate = null as any;
        user.leaveEndDate = null as any;
        await this.usersRepository.save(user);
        this.notificationsGateway.broadcast('update_received', { type: 'EXECUTIVE_UPDATE', data: user });
      }
    }
    return user;
  }

  async findAllExecutives(): Promise<User[]> {
    const users = await this.usersRepository.find({
      where: { role: UserRole.EXECUTIVE }
    });
    return Promise.all(users.map(u => this.checkAndExpireLeave(u)));
  }

  async findByEmployeeId(employeeId: string): Promise<User | null> {
    const user = await this.usersRepository.findOne({
      where: { employeeId, role: UserRole.EXECUTIVE }
    });
    if (!user) return null;
    return this.checkAndExpireLeave(user);
  }


  async createExecutive(createExecutiveDto: any): Promise<User> {
    const executive = new User();
    Object.assign(executive, createExecutiveDto);
    executive.role = UserRole.EXECUTIVE;
    return this.usersRepository.save(executive);
  }

  async updateExecutive(employeeId: string, updateExecutiveDto: any): Promise<User | null> {
    const user = await this.findByEmployeeId(employeeId);
    if (!user) return null;
    await this.usersRepository.update(user.id, updateExecutiveDto);
    const updatedUser = await this.usersRepository.findOneBy({ id: user.id });
    this.notificationsGateway.broadcast('update_received', { type: 'EXECUTIVE_UPDATE', data: updatedUser });
    return updatedUser;
  }

  async removeExecutive(employeeId: string): Promise<void> {
    const user = await this.findByEmployeeId(employeeId);
    if (user) {
      await this.usersRepository.delete(user.id);
    }
  }
}
