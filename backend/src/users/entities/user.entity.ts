import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum UserRole {
  CUSTOMER = 'customer',
  EXECUTIVE = 'executive',
  ADMIN = 'admin',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: true })
  employeeId: string;

  @Column({ unique: true, nullable: true })
  email: string;

  @Column({ unique: true, nullable: true })
  phone: string;

  @Column({ type: 'simple-json', nullable: true })
  savedAddresses: string[];

  @Column({ nullable: true })
  passwordHash: string; // Made nullable since OTP login might not use passwords

  @Column({
    type: 'simple-enum',
    enum: UserRole,
    default: UserRole.CUSTOMER,
  })
  role: UserRole;

  @Column({ nullable: true })
  firstName: string;

  @Column({ nullable: true })
  lastName: string;

  @Column({
    type: 'simple-json',
    nullable: true,
  })
  currentLocation: { type: 'Point'; coordinates: [number, number] };

  // Executive specific fields
  @Column({ nullable: true })
  status: string;

  @Column({ nullable: true })
  color: string; // Stored as hex string, e.g., '#4CAF50'

  @Column({ nullable: true })
  bloodGroup: string;

  @Column({ type: 'date', nullable: true })
  doj: Date;

  @Column({ nullable: true })
  experience: string;

  @Column({ nullable: true })
  bankDetails: string;

  @Column({ type: 'simple-json', nullable: true })
  customFields: { title: string; value: string }[];

  @Column({ type: 'date', nullable: true })
  leaveStartDate: Date;

  @Column({ type: 'date', nullable: true })
  leaveEndDate: Date;

  @Column({ type: 'simple-json', nullable: true })
  attendanceRecords: { [dateString: string]: 'PRESENT' | 'LEAVE' | 'ABSENT' };

  @CreateDateColumn()
  createdAt: Date;

  @Column({ type: 'int', default: 0 })
  rewardPoints: number;

  @Column({ type: 'simple-json', nullable: true })
  rewardTransactions: any[];

  @UpdateDateColumn()
  updatedAt: Date;
}
