import { Controller, Get, Post, Body, Patch, Param } from '@nestjs/common';
import { ApprovalsService } from './approvals.service';
import { CreateApprovalDto } from './dto/create-approval.dto';
import { UpdateApprovalDto } from './dto/update-approval.dto';

@Controller('approvals')
export class ApprovalsController {
  constructor(private readonly approvalsService: ApprovalsService) {}

  @Post()
  create(@Body() createApprovalDto: CreateApprovalDto) {
    return this.approvalsService.create(createApprovalDto);
  }

  @Get()
  findAll() {
    return this.approvalsService.findAll();
  }

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body() updateApprovalDto: UpdateApprovalDto) {
    return this.approvalsService.updateStatus(id, updateApprovalDto);
  }
}
