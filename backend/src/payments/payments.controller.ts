import { Controller, Post, Body, Get } from '@nestjs/common';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('calculate')
  calculateBill(@Body() dto: { basePrice: number, extraMaterials?: number }) {
    return this.paymentsService.calculateBill(dto.basePrice, dto.extraMaterials);
  }

  @Post('upi-link')
  generateUpiLink(@Body() dto: { amount: number, transactionRef: string }) {
    const upiLink = this.paymentsService.generateUpiLink(
      this.paymentsService.getCompanyUpiId(),
      'ProTech Cooling Services',
      dto.amount,
      dto.transactionRef
    );
    return { upiLink };
  }

  @Get('upi-id')
  getUpiId() {
    return { upiId: this.paymentsService.getCompanyUpiId() };
  }

  @Post('upi-id')
  updateUpiId(@Body() dto: { upiId: string }) {
    this.paymentsService.setCompanyUpiId(dto.upiId);
    return { message: 'UPI ID updated successfully', upiId: dto.upiId };
  }
}
