import { ApprovalType, ApprovalStatus } from '../entities/approval.entity';

export class CreateApprovalDto {
  type: ApprovalType;
  employeeId: string;
  employeeName?: string;
  details?: any;
}
