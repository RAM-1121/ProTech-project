import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum ApprovalType {
  ATTENDANCE = 'ATTENDANCE',
  REWARD = 'REWARD',
}

export enum ApprovalStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

@Entity('approvals')
export class Approval {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'simple-enum',
    enum: ApprovalType,
  })
  type: ApprovalType;

  @Column()
  employeeId: string;

  @Column({ nullable: true })
  employeeName: string;

  // Store request details here. 
  // For attendance: { dates: ['2023-10-01'], markAs: 'PRESENT' | 'LEAVE' }
  // For rewards: { amount: 100 }
  @Column({ type: 'simple-json', nullable: true })
  details: any;

  @Column({
    type: 'simple-enum',
    enum: ApprovalStatus,
    default: ApprovalStatus.PENDING,
  })
  status: ApprovalStatus;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
