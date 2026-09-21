import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Approval, ApprovalStatus, ApprovalType } from './entities/approval.entity';
import { CreateApprovalDto } from './dto/create-approval.dto';
import { UpdateApprovalDto } from './dto/update-approval.dto';
import { UsersService } from '../users/users.service';
import { NotificationsGateway } from '../notifications/notifications.gateway';

@Injectable()
export class ApprovalsService {
  constructor(
    @InjectRepository(Approval)
    private readonly approvalRepository: Repository<Approval>,
    private readonly usersService: UsersService,
    private readonly notificationsGateway: NotificationsGateway,
  ) {}

  async create(createApprovalDto: CreateApprovalDto): Promise<Approval> {
    const approval = this.approvalRepository.create(createApprovalDto);
    return this.approvalRepository.save(approval);
  }

  async findAll(): Promise<Approval[]> {
    return this.approvalRepository.find({
      order: { createdAt: 'DESC' },
    });
  }

  async updateStatus(id: string, updateApprovalDto: UpdateApprovalDto): Promise<Approval> {
    const approval = await this.approvalRepository.findOne({ where: { id } });
    if (!approval) {
      throw new NotFoundException(`Approval with ID ${id} not found`);
    }

    if (approval.status !== ApprovalStatus.PENDING) {
      throw new BadRequestException('Can only update status of pending approvals');
    }

    if (updateApprovalDto.status === ApprovalStatus.APPROVED) {
      // Process the approval based on type
      if (approval.type === ApprovalType.REWARD) {
        const amount = approval.details?.amount;
        if (!amount) {
          throw new BadRequestException('Invalid reward details');
        }
        await this.usersService.redeemPoints(approval.employeeId, amount);
        this.notificationsGateway.broadcast('update_received', { type: 'REWARD_APPROVED', data: { amount, employeeId: approval.employeeId } });
      } else if (approval.type === ApprovalType.ATTENDANCE) {
        const dates: string[] = approval.details?.dates || [];
        const markAs = approval.details?.markAs; // 'PRESENT' | 'LEAVE'
        
        if (dates.length > 0 && markAs) {
          const user = await this.usersService.findByEmployeeId(approval.employeeId);
          if (user) {
            const records = user.attendanceRecords || {};
            for (const d of dates) {
              records[d] = markAs;
            }
            await this.usersService.updateExecutive(approval.employeeId, {
              attendanceRecords: records
            });
          }
        }
      }
    } else if (updateApprovalDto.status === ApprovalStatus.REJECTED) {
      if (approval.type === ApprovalType.REWARD) {
        const amount = approval.details?.amount;
        if (amount) {
          await this.usersService.rejectRedemption(approval.employeeId, amount);
          this.notificationsGateway.broadcast('update_received', { type: 'REWARD_REJECTED', data: { amount, employeeId: approval.employeeId } });
        }
      }
    }

    approval.status = updateApprovalDto.status;
    return this.approvalRepository.save(approval);
  }
}
